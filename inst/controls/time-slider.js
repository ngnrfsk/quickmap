(function() {
  // Time slider (item 10): replaces the roller dropdown. Same integration
  // contract: window.quickmapTimeController (lazy Canvas path) or
  // window.quickmapLayerCache (pre-built layers), plus
  // window.quickmapWindController for the wind overlay.
  var cachedMap = null;

  function getMapInstance() {
    if (cachedMap) return cachedMap;
    var mapDiv = document.querySelector(".leaflet-container");
    var widgetContainer = mapDiv.closest("[id^=htmlwidget-]");
    var widget = HTMLWidgets.find("#" + widgetContainer.id);
    cachedMap = widget;
    if (widget.getMap) cachedMap = widget.getMap();
    else if (widget.map) cachedMap = widget.map;
    else if (widget._map) cachedMap = widget._map;
    return cachedMap;
  }

  function switchToTime(selected, times, instant) {
    try {
      // Everything that must run on BOTH rendering paths goes above the
      // quickmapTimeController branch below, which returns early on the lazy
      // path. Placed after it, an overlay works on small maps and silently
      // freezes on maps over 50 time steps.
      if (window.quickmapWindController) {
        window.quickmapWindController.setTime(selected);
      }
      if (window.quickmapIndicatorController) {
        window.quickmapIndicatorController.setTime(selected);
      }
      if (window.quickmapTimeController) {
        // second argument: skip the colour crossfade during drag-scrubbing
        window.quickmapTimeController.setTime(selected, instant === true);
        return;
      }
      if (!window.quickmapLayerCache) {
        console.error("window.quickmapLayerCache not found");
        return;
      }
      var map = getMapInstance();
      var layerCache = window.quickmapLayerCache;
      times.forEach(function(t) {
        if (!layerCache[t]) return;
        layerCache[t].forEach(function(layer) {
          if (t === selected) {
            if (!map.hasLayer(layer)) map.addLayer(layer);
          } else if (map.hasLayer(layer)) {
            map.removeLayer(layer);
          }
        });
      });
    } catch (e) {
      console.error("Time slider error:", e);
    }
  }

  function initialize() {
    if (!window.quickmapLayerCache) {
      setTimeout(initialize, 100);
      return;
    }

    var control = document.getElementById("yearControl");
    var playPauseButton = document.getElementById("playPauseButton");
    var stepBack = document.getElementById("stepBack");
    var stepForward = document.getElementById("stepForward");
    var speedButton = document.getElementById("speedButton");
    var track = document.getElementById("sliderTrack");
    var fill = document.getElementById("sliderFill");
    var thumb = document.getElementById("sliderThumb");
    var currentLabel = document.getElementById("currentLabel");
    var startLabel = document.getElementById("startLabel");
    var endLabel = document.getElementById("endLabel");

    // anchor "bottom" to the map area, not the page
    var mapContainer = document.querySelector(".map-container");
    if (mapContainer && control.parentElement !== mapContainer) {
      mapContainer.appendChild(control);
    }

    // keep keyboard flow on the control, not the map internals
    function removeMapFocus() {
      document.querySelectorAll(
        ".leaflet-marker-icon, .leaflet-interactive, " +
        ".leaflet-control-zoom-in, .leaflet-control-zoom-out, " +
        ".leaflet-control a, .leaflet-control button"
      ).forEach(function(el) { el.setAttribute("tabindex", "-1"); });
    }
    setTimeout(removeMapFocus, 100);
    setTimeout(removeMapFocus, 500);

    var config = window.quickmapConfig || { autoplay: false, playSpeed: 500 };
    var times = Object.keys(window.quickmapLayerCache).sort();
    if (times.length === 0) return;

    var index = times.length - 1;
    var isPlaying = false;
    var playInterval = null;

    startLabel.textContent = times[0];
    endLabel.textContent = times[times.length - 1];
    track.setAttribute("aria-valuemax", String(times.length - 1));

    if (times.length <= 1) {
      control.classList.add("single-step");
      playPauseButton.classList.add("hidden");
    }

    function render() {
      var frac = times.length > 1 ? index / (times.length - 1) : 1;
      fill.style.width = (frac * 100) + "%";
      thumb.style.left = (frac * 100) + "%";
      currentLabel.textContent = times[index];
      track.setAttribute("aria-valuenow", String(index));
      track.setAttribute("aria-valuetext", times[index]);
    }

    function setIndex(i, instant) {
      index = Math.max(0, Math.min(times.length - 1, i));
      render();
      switchToTime(times[index], times, instant);
    }

    // Playback speed (2026-08-05). The button shows a multiplier applied to
    // the theme's playSpeed, cycling on each press and wrapping. The interval
    // has exactly one source of truth, currentInterval(), and exactly one
    // place that starts a timer, startTimer() — the timer is started from two
    // places (play, and resuming after the tab was hidden), and a speed that
    // reached one but not the other would be correct on play and wrong after
    // a return to the tab.
    var SPEEDS = [0.25, 0.5, 1, 2, 4, 8];
    var speedIndex = SPEEDS.indexOf(1);

    function currentInterval() {
      return Math.round(config.playSpeed / SPEEDS[speedIndex]);
    }

    function startTimer() {
      if (playInterval) clearInterval(playInterval);
      playInterval = setInterval(function() {
        setIndex((index + 1) % times.length);
      }, currentInterval());
    }

    function renderSpeed() {
      var label = SPEEDS[speedIndex] + "×";
      speedButton.textContent = label;
      speedButton.setAttribute(
        "aria-label", "Playback speed " + label + ", press to change"
      );
      // read by lazy-time-controller.js, which sizes the colour crossfade at
      // 40% of the interval — without this the fade would outlast the step
      window.quickmapPlayInterval = currentInterval();
      if (isPlaying) startTimer(); // take effect now, not at the next step
    }

    function cycleSpeed() {
      speedIndex = (speedIndex + 1) % SPEEDS.length;
      renderSpeed();
    }

    function pause() {
      if (!isPlaying) return;
      isPlaying = false;
      playPauseButton.textContent = "▶";
      playPauseButton.setAttribute("aria-label", "Play animation");
      playPauseButton.setAttribute("aria-pressed", "false");
      if (playInterval) { clearInterval(playInterval); playInterval = null; }
    }

    function togglePlayPause() {
      if (isPlaying) { pause(); return; }
      isPlaying = true;
      playPauseButton.textContent = "⏸";
      playPauseButton.setAttribute("aria-label", "Pause animation");
      playPauseButton.setAttribute("aria-pressed", "true");
      startTimer();
    }

    playPauseButton.addEventListener("click", function(e) {
      e.stopPropagation();
      togglePlayPause();
    });
    playPauseButton.addEventListener("keydown", function(e) {
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        e.stopPropagation();
        togglePlayPause();
      }
    });

    speedButton.addEventListener("click", function(e) {
      e.stopPropagation();
      cycleSpeed();
    });
    speedButton.addEventListener("keydown", function(e) {
      // matches the play button: handle the keys here and suppress the
      // default so Space cannot also scroll the page or reach the map
      if (e.key === " " || e.key === "Enter") {
        e.preventDefault();
        e.stopPropagation();
        cycleSpeed();
      }
    });

    stepBack.addEventListener("click", function() { pause(); setIndex(index - 1); });
    stepForward.addEventListener("click", function() { pause(); setIndex(index + 1); });

    // drag / tap scrubbing
    function fracToIndex(clientX) {
      var rect = track.getBoundingClientRect();
      var frac = (clientX - rect.left) / rect.width;
      return Math.round(frac * (times.length - 1));
    }
    var dragging = false;
    track.addEventListener("pointerdown", function(e) {
      pause();
      dragging = true;
      track.setPointerCapture(e.pointerId);
      setIndex(fracToIndex(e.clientX), true);
    });
    track.addEventListener("pointermove", function(e) {
      if (!dragging) return;
      var i = fracToIndex(e.clientX);
      if (i !== index) setIndex(i, true);
    });
    track.addEventListener("pointerup", function(e) {
      dragging = false;
      setIndex(fracToIndex(e.clientX)); // final position with normal transition
    });
    track.addEventListener("pointercancel", function() { dragging = false; });

    // keyboard: arrows step, Home/End jump, space toggles play
    function keyStep(e) {
      if (e.key === "ArrowLeft") { e.preventDefault(); pause(); setIndex(index - 1); }
      else if (e.key === "ArrowRight") { e.preventDefault(); pause(); setIndex(index + 1); }
      else if (e.key === "Home") { e.preventDefault(); pause(); setIndex(0); }
      else if (e.key === "End") { e.preventDefault(); pause(); setIndex(times.length - 1); }
      else if (e.key === " " && e.target === track) { e.preventDefault(); togglePlayPause(); }
    }
    track.addEventListener("keydown", keyStep);
    document.addEventListener("keydown", function(e) {
      // global arrows, unless typing somewhere
      if (e.target && /INPUT|TEXTAREA|SELECT/.test(e.target.tagName)) return;
      if (e.target === track) return; // already handled
      if (e.key === "ArrowLeft" || e.key === "ArrowRight") keyStep(e);
    });

    window.addEventListener("beforeunload", function() {
      if (playInterval) { clearInterval(playInterval); playInterval = null; }
    });

    // pause while the tab is hidden, resume on return
    if (typeof document.hidden !== "undefined") {
      document.addEventListener("visibilitychange", function() {
        if (document.hidden) {
          if (isPlaying && playInterval) { clearInterval(playInterval); playInterval = null; }
        } else if (isPlaying && !playInterval) {
          startTimer();
        }
      });
    }

    renderSpeed(); // publishes the interval even if the button is never pressed
    setIndex(times.length - 1);

    if (config.autoplay && times.length > 1) togglePlayPause();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialize);
  } else {
    initialize();
  }
})();

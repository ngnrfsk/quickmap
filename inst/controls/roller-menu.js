(function() {
  console.log('Roller menu script loaded');

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

  function switchToYear(selectedYear, years) {
    try {
      if (!window.quickmapLayerCache) {
        console.error("window.quickmapLayerCache not found");
        return;
      }

      var map = getMapInstance();
      var layerCache = window.quickmapLayerCache;

      var added = 0, removed = 0;
      years.forEach(function(yr) {
        if (!layerCache[yr]) return;

        layerCache[yr].forEach(function(layer) {
          if (yr === selectedYear) {
            if (!map.hasLayer(layer)) {
              map.addLayer(layer);
              added++;
            }
          } else {
            if (map.hasLayer(layer)) {
              map.removeLayer(layer);
              removed++;
            }
          }
        });
      });
      console.log("Year switched to", selectedYear, "- Added:", added, "Removed:", removed);

    } catch(e) {
      console.error("Year control error:", e);
    }
  }

  function initializeYearControl() {
    console.log('initializeYearControl called, checking for layer cache...');

    // Wait for layer cache to be available
    if (!window.quickmapLayerCache) {
      console.log('Layer cache not ready, polling again in 100ms...');
      setTimeout(initializeYearControl, 100);
      return;
    }

    console.log('Layer cache found!', window.quickmapLayerCache);

    var yearControl = document.getElementById('yearControl');
    var yearButton = document.getElementById('yearButton');
    var yearList = document.getElementById('yearList');
    var selectedYearSpan = document.getElementById('selectedYear');
    var playPauseButton = document.getElementById('playPauseButton');

    // Play/pause state
    var isPlaying = false;
    var playInterval = null;
    var currentIndex = 0;
    var playSpeed = 500; // milliseconds per year

    // Extract years from layer cache and sort
    var years = Object.keys(window.quickmapLayerCache).sort(function(a, b) {
      return parseInt(a) - parseInt(b);
    });

    console.log('DEBUG: Years found in layer cache:', years);
    console.log('DEBUG: Years count:', years.length);
    console.log('DEBUG: Play button element exists:', !!playPauseButton);

    if (years.length === 0) {
      console.warn('No years found in layer cache');
      return;
    }

    // Handle single year UI - hide play button and arrow, disable expansion
    if (years.length <= 1) {
      if (playPauseButton) {
        playPauseButton.classList.add('hidden');
      }
      // Hide arrow and mark as single-year mode
      yearControl.classList.add('single-year');
      console.log('Single year mode - play button and arrow hidden, expansion disabled');
    } else {
      console.log('DEBUG: Multiple years - full controls enabled, years.length =', years.length);
    }

    // Find latest year (last in sorted array)
    var latestYear = years[years.length - 1];

    // Populate year list
    years.forEach(function(year) {
      var yearItem = document.createElement('div');
      yearItem.className = 'year-item';
      yearItem.setAttribute('data-year', year);
      yearItem.textContent = year;

      // Mark latest year as selected initially
      if (year === latestYear) {
        yearItem.classList.add('selected');
      }

      // Add click handler for layer switching
      yearItem.addEventListener('click', function() {
        var clickedYear = this.getAttribute('data-year');

        // Pause animation if playing
        if (isPlaying) {
          isPlaying = false;
          playPauseButton.textContent = '▶';
          if (playInterval) {
            clearInterval(playInterval);
            playInterval = null;
          }
        }

        // Update current index to match clicked year
        currentIndex = years.indexOf(clickedYear);

        // Remove selected class from all items
        var allItems = yearList.querySelectorAll('.year-item');
        allItems.forEach(function(item) {
          item.classList.remove('selected');
        });

        // Add selected class to clicked item
        this.classList.add('selected');

        // Update selected year display
        selectedYearSpan.textContent = clickedYear;

        // Switch map layers
        switchToYear(clickedYear, years);

        // Close menu
        yearControl.classList.remove('expanded');
        yearList.classList.remove('show');
      });

      yearList.appendChild(yearItem);
    });

    // Set initial selected year to latest
    selectedYearSpan.textContent = latestYear;
    currentIndex = years.indexOf(latestYear);

    // Toggle menu on button click (disabled in single-year mode)
    yearButton.addEventListener('click', function(e) {
      e.stopPropagation();

      // Don't expand if single year
      if (yearControl.classList.contains('single-year')) {
        return;
      }

      yearControl.classList.toggle('expanded');
      yearList.classList.toggle('show');
    });

    // Close menu when clicking outside
    document.addEventListener('click', function(e) {
      if (!yearControl.contains(e.target)) {
        yearControl.classList.remove('expanded');
        yearList.classList.remove('show');
      }
    });

    // Advance to next year in sequence
    function advanceToNextYear() {
      // Increment index with loop wrapping
      currentIndex = (currentIndex + 1) % years.length;
      var nextYear = years[currentIndex];

      // Update selected year display
      selectedYearSpan.textContent = nextYear;

      // Update dropdown selection highlight
      var allItems = yearList.querySelectorAll('.year-item');
      allItems.forEach(function(item) {
        if (item.getAttribute('data-year') === nextYear) {
          item.classList.add('selected');
        } else {
          item.classList.remove('selected');
        }
      });

      // Switch map layers
      switchToYear(nextYear, years);
    }

    // Toggle play/pause
    function togglePlayPause() {
      isPlaying = !isPlaying;
      playPauseButton.textContent = isPlaying ? '⏸' : '▶';

      if (isPlaying) {
        // Start animation
        playInterval = setInterval(advanceToNextYear, playSpeed);
      } else {
        // Stop animation
        if (playInterval) {
          clearInterval(playInterval);
          playInterval = null;
        }
      }
    }

    // Play/pause button click handler
    playPauseButton.addEventListener('click', function(e) {
      e.stopPropagation();
      togglePlayPause();
    });

    // Cleanup interval on page unload to prevent memory leaks
    window.addEventListener('beforeunload', function() {
      if (playInterval) {
        clearInterval(playInterval);
        playInterval = null;
      }
    });

    // Pause animation when page becomes hidden (tab switch, minimize, etc.)
    // Resume when page becomes visible again
    // Cross-browser support with vendor prefixes
    var hidden, visibilityChange;
    if (typeof document.hidden !== "undefined") {
      hidden = "hidden";
      visibilityChange = "visibilitychange";
    } else if (typeof document.webkitHidden !== "undefined") {
      hidden = "webkitHidden";
      visibilityChange = "webkitvisibilitychange";
    } else if (typeof document.mozHidden !== "undefined") {
      hidden = "mozHidden";
      visibilityChange = "mozvisibilitychange";
    } else if (typeof document.msHidden !== "undefined") {
      hidden = "msHidden";
      visibilityChange = "msvisibilitychange";
    }

    if (typeof document[hidden] !== "undefined") {
      document.addEventListener(visibilityChange, function() {
        if (document[hidden]) {
          // Page hidden - pause if playing
          if (isPlaying && playInterval) {
            clearInterval(playInterval);
            playInterval = null;
            console.log('Animation paused - page hidden');
          }
        } else {
          // Page visible - resume if was playing
          if (isPlaying && !playInterval) {
            playInterval = setInterval(advanceToNextYear, playSpeed);
            console.log('Animation resumed - page visible');
          }
        }
      });
    }

    console.log('Year control initialized with years:', years);
  }

  // Start initialization when DOM is ready
  console.log('Setting up initialization, document.readyState =', document.readyState);
  if (document.readyState === 'loading') {
    console.log('Document still loading, adding DOMContentLoaded listener');
    document.addEventListener('DOMContentLoaded', initializeYearControl);
  } else {
    console.log('Document ready, initializing immediately');
    initializeYearControl();
  }
})();

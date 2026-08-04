(function() {
  // Aggregate indicator: moves the markers and rewrites the figures when the
  // time slider changes step. Registered as window.quickmapIndicatorController,
  // the same optional-global contract the wind overlay uses.
  //
  // Positions and colours are computed in R and shipped ready-made, so this
  // file never needs to know the colour scale. Positions are percentages of
  // the legend's colour ramp, worked out band by band because the ramp's
  // blocks are equal width whatever their span.
  var data = window.quickmapIndicatorData;
  if (!data || !data.times || !data.times.length) return;

  function set(id, fn) {
    var el = document.getElementById(id);
    if (el) fn(el);
  }

  // Do the two figures actually overlap, right now, at this window width?
  //
  // R decides this server-side from a percentage of the ramp, which is all it
  // can do for a static export. That is wrong on a narrow screen: the labels
  // are a fixed width in pixels while the ramp shrinks, so on a phone two
  // labels can collide while sitting further apart in percentage terms than
  // any desktop threshold would flag. So in the browser, measure.
  var GAP = 6; // px of daylight required between the two labels

  function measureOverlap() {
    var a = document.getElementById("qmIndicatorFigure");
    var b = document.getElementById("qmIndicatorMaxFigure");
    if (!a || !b) return false;

    // measure them level: the offsets we are deciding about would otherwise
    // separate them vertically and hide the very overlap being tested for
    var was = [a.className, b.className];
    a.classList.remove("qm-dropped");
    b.classList.remove("qm-lifted");
    var ra = a.getBoundingClientRect();
    var rb = b.getBoundingClientRect();
    a.className = was[0];
    b.className = was[1];

    return !(ra.right + GAP < rb.left || rb.right + GAP < ra.left);
  }

  function setTime(selected) {
    var i = data.times.indexOf(String(selected));
    if (i < 0) return;

    var figure = Number(data.values[i]).toFixed(1);
    var hasMax = !!data.maxW;
    // R's percentage is the starting guess; the measurement below corrects it
    var crowded = hasMax &&
      Math.abs(data.maxW[i] - data.w[i]) < (data.clearance || 9);

    // the roundel is a plain disc; its figure floats above it, like the
    // diamond's, and moves with it
    set("qmIndicatorBar", function(el) {
      el.style.left = data.w[i] + "%";
      el.style.background = data.colours[i];
      el.title = "Network mean, " + figure;
      el.classList.toggle("qm-dropped", crowded);
    });
    set("qmIndicatorFigure", function(el) {
      el.style.left = data.w[i] + "%";
      el.textContent = figure;
      el.classList.toggle("qm-dropped", crowded);
    });
    set("qmIndicatorChip", function(el) {
      el.style.background = data.colours[i];
    });
    set("qmIndicatorValue", function(el) { el.textContent = figure; });

    if (!hasMax) return;

    var maxFigure = Number(data.maxValues[i]).toFixed(1);
    set("qmIndicatorMax", function(el) {
      el.style.left = data.maxW[i] + "%";
      el.style.background = data.maxColours[i];
      el.title = "Highest site, " + maxFigure;
      el.classList.toggle("qm-lifted", crowded);
    });
    set("qmIndicatorMaxFigure", function(el) {
      el.style.left = data.maxW[i] + "%";
      el.textContent = maxFigure;
      el.classList.toggle("qm-lifted", crowded);
    });
    set("qmIndicatorMaxChip", function(el) {
      el.style.background = data.maxColours[i];
    });
    set("qmIndicatorMaxValue", function(el) { el.textContent = maxFigure; });
    // the maximum's caption is fixed ("max all sites") — it is over every
    // reporting site by definition, so there is no count to keep up to date

    applyOverlap();
  }

  // Positions are set, the labels carry their final text: now measure and
  // separate them only if they really do collide at this window width.
  function applyOverlap() {
    if (!data.maxW) return;
    var overlapping = measureOverlap();
    [["qmIndicatorFigure", "qm-dropped"], ["qmIndicatorBar", "qm-dropped"],
     ["qmIndicatorMaxFigure", "qm-lifted"], ["qmIndicatorMax", "qm-lifted"]]
      .forEach(function(pair) {
        set(pair[0], function(el) {
          el.classList.toggle(pair[1], overlapping);
        });
      });
  }

  // A phone rotated, or a window dragged narrower, changes the answer
  var resizeTimer;
  window.addEventListener("resize", function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(applyOverlap, 150);
  });

  window.quickmapIndicatorController = { setTime: setTime };
})();

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

  function setTime(selected) {
    var i = data.times.indexOf(String(selected));
    if (i < 0) return;

    var figure = Number(data.values[i]).toFixed(1);
    var hasMax = !!data.maxW;
    // markers within a marker's width of each other would overlap, so the
    // maximum lifts and the mean drops — the same rule R applies server-side
    var crowded = hasMax &&
      Math.abs(data.maxW[i] - data.w[i]) < (data.clearance || 9);

    set("qmIndicatorBar", function(el) {
      el.style.left = data.w[i] + "%";
      el.style.background = data.colours[i];
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
  }

  window.quickmapIndicatorController = { setTime: setTime };
})();

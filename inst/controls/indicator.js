(function() {
  // Aggregate indicator: moves the pointer and rewrites the figure when the
  // time slider changes step. Registered as window.quickmapIndicatorController,
  // the same optional-global contract the wind overlay uses.
  //
  // All positions and colours are computed in R and shipped ready-made, so
  // this file never needs to know the colour scale or the value range.
  var data = window.quickmapIndicatorData;
  if (!data || !data.times || !data.times.length) return;

  function setTime(selected) {
    var i = data.times.indexOf(String(selected));
    if (i < 0) return;

    var pointer = document.getElementById("qmIndicatorPointer");
    if (pointer) {
      pointer.setAttribute("transform", "translate(" + data.x[i] + " 0)");
      var head = pointer.querySelector("path");
      if (head) head.setAttribute("fill", data.colours[i]);
    }

    // "ramp" style: a bar above the legend ramp, running from zero to the
    // mean. Widths are percentages of the ramp, computed band by band in R
    // because the ramp's blocks are equal width whatever their span.
    var bar = document.getElementById("qmIndicatorBar");
    if (bar && data.w) {
      bar.style.width = data.w[i] + "%";
      bar.style.background = data.colours[i];
    }

    var value = document.getElementById("qmIndicatorValue");
    if (value) value.textContent = Number(data.values[i]).toFixed(1);
  }

  window.quickmapIndicatorController = { setTime: setTime };
})();

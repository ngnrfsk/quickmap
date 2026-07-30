(function() {
  // Aggregate indicator: moves the marker and rewrites the figure when the
  // time slider changes step. Registered as window.quickmapIndicatorController,
  // the same optional-global contract the wind overlay uses.
  //
  // Positions and colours are computed in R and shipped ready-made, so this
  // file never needs to know the colour scale. Positions are percentages of
  // the legend's colour ramp, worked out band by band because the ramp's
  // blocks are equal width whatever their span.
  var data = window.quickmapIndicatorData;
  if (!data || !data.times || !data.times.length) return;

  function setTime(selected) {
    var i = data.times.indexOf(String(selected));
    if (i < 0) return;

    var figure = Number(data.values[i]).toFixed(1);

    var marker = document.getElementById("qmIndicatorBar");
    if (marker) {
      if (marker.classList.contains("qm-roundel")) {
        // a disc sitting on the ramp at the value, carrying the figure
        marker.style.left = data.w[i] + "%";
        marker.textContent = figure;
      } else {
        // a bar from zero to the value
        marker.style.width = data.w[i] + "%";
      }
      marker.style.background = data.colours[i];
    }

    // the chip beside the caption keeps the marker's colour, which is what
    // ties the figure to the ramp
    var chip = document.getElementById("qmIndicatorChip");
    if (chip) chip.style.background = data.colours[i];

    var value = document.getElementById("qmIndicatorValue");
    if (value) value.textContent = figure;
  }

  window.quickmapIndicatorController = { setTime: setTime };
})();

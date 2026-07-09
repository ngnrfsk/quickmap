function(el, x, data) {
  // Wind overlay (roadmap item 7): leaflet-velocity particle layer fed by
  // per-time-step mean U/V frames from the embedded payload. Published as
  // window.quickmapWindController; the roller menu calls setTime alongside
  // the marker path (lazy controller or layer cache).
  var map = this;
  var layer = null;

  function setTime(timeLabel) {
    var idx = data.times.indexOf(String(timeLabel));
    var frame = idx === -1 ? null : data.frames[idx];
    if (!frame) {
      if (layer) { map.removeLayer(layer); layer = null; }
      return;
    }
    if (layer) {
      // patched plugin: swaps the wind field under the running particle
      // animation — no restart, so stepping stays smooth
      layer.updateData(frame);
      return;
    }
    // item 10: styling comes from the theme via the payload (speed-ramp
    // default); the literals below are only a fallback for old payloads
    var style = data.style || {};
    layer = L.velocityLayer({
      data: frame,
      maxVelocity: data.maxVelocity,
      velocityScale: style.velocityScale || 0.01,
      lineWidth: style.lineWidth || 1,
      particleMultiplier: style.particleMultiplier || 1 / 500,
      colorScale: style.colorScale || ['#3288bd', '#66c2a5', '#abdda4',
                                       '#fee08b', '#f46d43', '#d53e4f'],
      displayValues: false
    }).addTo(map);
  }

  window.quickmapWindController = { setTime: setTime, times: data.times };
  setTime(data.times[data.times.length - 1]);
}

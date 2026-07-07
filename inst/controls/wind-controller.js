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
    layer = L.velocityLayer({
      data: frame,
      maxVelocity: data.maxVelocity,
      velocityScale: 0.01,
      lineWidth: 1,
      particleMultiplier: 1 / 500,
      // muted slate ramp: speed stays readable without competing with markers
      colorScale: ['#b7c3cd', '#9fb0be', '#879cb0', '#7089a1', '#587693',
                   '#416384', '#295076'],
      displayValues: false
    }).addTo(map);
  }

  window.quickmapWindController = { setTime: setTime, times: data.times };
  setTime(data.times[data.times.length - 1]);
}

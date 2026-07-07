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
      layer.setData(frame);
      return;
    }
    layer = L.velocityLayer({
      data: frame,
      maxVelocity: data.maxVelocity,
      velocityScale: 0.01,
      lineWidth: 2,
      particleMultiplier: 1 / 250,
      displayValues: false
    }).addTo(map);
  }

  window.quickmapWindController = { setTime: setTime, times: data.times };
  setTime(data.times[data.times.length - 1]);
}

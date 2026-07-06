function(el, x, data) {
  // Lazy time controller (roadmap item 6, Option D): temporal markers are
  // rendered once as Canvas shapes and restyled per time step from the
  // compact embedded payload in `data`, instead of pre-building one hidden
  // Leaflet layer set per step. Drives (and is driven by) the existing
  // roller-menu UI via window.quickmapTimeController.
  var map = this;

  var style = document.createElement('style');
  style.textContent =
    '.qm-lazy-tooltip{background:rgba(255,255,255,0.5);padding:1px;' +
    'border-radius:3px;border:1px solid rgba(0,0,0,0.1);box-shadow:none;' +
    'color:#333;}' +
    '.qm-lazy-tooltip:before{display:none;}';
  document.head.appendChild(style);

  // markers on their own Canvas renderer; polygons stay on the default SVG
  // renderer (Canvas polygon clipping is buggy on Leaflet 1.3.1)
  var canvas = L.canvas({ padding: 0.5 });

  function drawSymbol(ctx, shape, p, r) {
    switch (shape) {
      case 'rect':
        ctx.rect(p.x - r, p.y - r, 2 * r, 2 * r);
        break;
      case 'diamond':
        ctx.moveTo(p.x, p.y - r);
        ctx.lineTo(p.x + r, p.y);
        ctx.lineTo(p.x, p.y + r);
        ctx.lineTo(p.x - r, p.y);
        ctx.closePath();
        break;
      case 'triangle':
        ctx.moveTo(p.x, p.y - r);
        ctx.lineTo(p.x + r, p.y + r);
        ctx.lineTo(p.x - r, p.y + r);
        ctx.closePath();
        break;
      case 'down-triangle':
        ctx.moveTo(p.x, p.y + r);
        ctx.lineTo(p.x + r, p.y - r);
        ctx.lineTo(p.x - r, p.y - r);
        ctx.closePath();
        break;
      case 'stadium':
        ctx.moveTo(p.x - r / 2, p.y - r / 2);
        ctx.lineTo(p.x + r / 2, p.y - r / 2);
        ctx.arc(p.x + r / 2, p.y, r / 2, -Math.PI / 2, Math.PI / 2);
        ctx.lineTo(p.x - r / 2, p.y + r / 2);
        ctx.arc(p.x - r / 2, p.y, r / 2, Math.PI / 2, -Math.PI / 2);
        ctx.closePath();
        break;
      case 'simple-plus':
      case 'plus':
      case 'plus-circle':
      case 'plus-rect':
        ctx.moveTo(p.x - r, p.y);
        ctx.lineTo(p.x + r, p.y);
        ctx.moveTo(p.x, p.y - r);
        ctx.lineTo(p.x, p.y + r);
        break;
      case 'simple-cross':
      case 'cross':
      case 'cross-rect':
      case 'cross-circle':
        var d = r * 0.7071;
        ctx.moveTo(p.x - d, p.y - d);
        ctx.lineTo(p.x + d, p.y + d);
        ctx.moveTo(p.x - d, p.y + d);
        ctx.lineTo(p.x + d, p.y - d);
        break;
      case 'simple-star':
      case 'star':
        ctx.moveTo(p.x - r, p.y);
        ctx.lineTo(p.x + r, p.y);
        ctx.moveTo(p.x, p.y - r);
        ctx.lineTo(p.x, p.y + r);
        var s = r * 0.7071;
        ctx.moveTo(p.x - s, p.y - s);
        ctx.lineTo(p.x + s, p.y + s);
        ctx.moveTo(p.x - s, p.y + s);
        ctx.lineTo(p.x + s, p.y - s);
        break;
      default: // circle, solid-circle-sm, solid-circle-md
        ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
    }
    // outline ring for the combined shapes
    if (shape === 'plus-circle' || shape === 'cross-circle') {
      ctx.moveTo(p.x + r, p.y);
      ctx.arc(p.x, p.y, r, 0, Math.PI * 2);
    }
    if (shape === 'plus-rect' || shape === 'cross-rect') {
      ctx.rect(p.x - r, p.y - r, 2 * r, 2 * r);
    }
  }

  var ShapeMarker = L.CircleMarker.extend({
    _updatePath: function () {
      if (!this._renderer._drawing || this._empty()) { return; }
      var ctx = this._renderer._ctx;
      ctx.beginPath();
      drawSymbol(ctx, this.options.qmShape, this._point, this._radius);
      this._renderer._fillStroke(ctx, this);
    }
  });

  var times = data.times;
  var thresholds = data.thresholds;
  var colours = data.colours;

  function colourFor(v) {
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (v >= thresholds[i]) { return colours[i]; }
    }
    return data.naColour;
  }

  // one marker per site, created once, restyled/toggled per step
  var all = []; // {marker, site, layer}
  data.layers.forEach(function (layer) {
    layer.sites.forEach(function (site) {
      var opts = {
        renderer: canvas,
        qmShape: layer.shape,
        radius: layer.radius,
        weight: 2,
        opacity: 1,
        fillOpacity: layer.nonsolid ? 0 : 0.75,
        color: '#ffffff',
        fillColor: '#ffffff',
        fill: !layer.nonsolid
      };
      var mk = new ShapeMarker([site.lat, site.lon], opts);
      if (layer.labelMode !== 'none') {
        mk.bindTooltip('', {
          permanent: !!layer.noHide,
          direction: 'bottom',
          offset: [0, 12],
          className: 'qm-lazy-tooltip',
          opacity: 1
        });
      }
      all.push({ marker: mk, site: site, layer: layer });
    });
  });

  function setTime(timeLabel) {
    var idx = times.indexOf(String(timeLabel));
    if (idx === -1) { return; }
    all.forEach(function (entry) {
      var v = entry.site.v[idx];
      if (v === null || v === undefined) {
        if (map.hasLayer(entry.marker)) { map.removeLayer(entry.marker); }
        return;
      }
      var c = colourFor(v);
      entry.marker.setStyle(
        entry.layer.nonsolid ? { color: c } : { fillColor: c }
      );
      if (entry.layer.labelMode === 'values') {
        entry.marker.setTooltipContent(Math.round(v) + ' ug/m3');
      } else if (entry.layer.labelMode === 'custom') {
        entry.marker.setTooltipContent(entry.site.label || '');
      }
      if (!map.hasLayer(entry.marker)) { entry.marker.addTo(map); }
    });
  }

  // roller-menu integration: switchToYear() delegates to this controller,
  // and the menu populates its year list from the (stub) layer cache keys
  window.quickmapTimeController = { setTime: setTime, times: times };
  var stub = {};
  times.forEach(function (t) { stub[t] = []; });
  window.quickmapLayerCache = stub;

  setTime(times[times.length - 1]);
}

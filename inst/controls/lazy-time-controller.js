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

  // Colour crossfade (M2, 2026-07-07): persisting markers tween from their
  // current colour to the new step's colour instead of snapping.
  //
  // Proportional since 2026-08-05 (speed control): 40% of the playback
  // interval, capped at 250ms. A flat 250ms is longer than the step itself
  // once the interval drops below ~600ms, so steps overlap and the animation
  // smears — which is exactly what the speed multiplier makes reachable.
  // The live interval is published by time-slider.js, which divides the
  // theme's playSpeed by the current multiplier.
  var FADE_MAX_MS = 250;
  var FADE_FRACTION = 0.4;
  var fadeToken = 0;

  function fadeMs() {
    var interval = window.quickmapPlayInterval ||
      (window.quickmapConfig && window.quickmapConfig.playSpeed) || 500;
    return Math.min(FADE_MAX_MS, interval * FADE_FRACTION);
  }

  function hexToRgb(hex) {
    return [parseInt(hex.slice(1, 3), 16), parseInt(hex.slice(3, 5), 16),
            parseInt(hex.slice(5, 7), 16)];
  }

  function mix(from, to, t) {
    return 'rgb(' + Math.round(from[0] + (to[0] - from[0]) * t) + ',' +
      Math.round(from[1] + (to[1] - from[1]) * t) + ',' +
      Math.round(from[2] + (to[2] - from[2]) * t) + ')';
  }

  function applyColour(entry, css) {
    entry.marker.setStyle(
      entry.layer.nonsolid ? { color: css } : { fillColor: css }
    );
  }

  function setTime(timeLabel, instant) {
    // instant=true (item 10): the slider suppresses the crossfade while
    // drag-scrubbing so colours track the thumb without lag
    var idx = times.indexOf(String(timeLabel));
    if (idx === -1) { return; }
    var token = ++fadeToken; // cancels any tween still running
    var fading = [];

    all.forEach(function (entry) {
      var v = entry.site.v[idx];
      if (v === null || v === undefined) {
        if (map.hasLayer(entry.marker)) { map.removeLayer(entry.marker); }
        entry.rgb = null;
        return;
      }
      var target = hexToRgb(colourFor(v));
      if (entry.layer.labelMode === 'values') {
        entry.marker.setTooltipContent(Math.round(v) + ' µg/m³');
      } else if (entry.layer.labelMode === 'custom') {
        entry.marker.setTooltipContent(entry.site.label || '');
      }
      if (!map.hasLayer(entry.marker) || !entry.rgb) {
        // appearing marker: no colour history to fade from
        entry.rgb = target;
        applyColour(entry, mix(target, target, 0));
        entry.marker.addTo(map);
        return;
      }
      if (entry.rgb[0] !== target[0] || entry.rgb[1] !== target[1] ||
          entry.rgb[2] !== target[2]) {
        fading.push({ entry: entry, from: entry.rgb, to: target });
        entry.rgb = target;
      }
    });

    if (fading.length === 0) { return; }
    if (instant === true) {
      fading.forEach(function (f) { applyColour(f.entry, mix(f.to, f.to, 0)); });
      return;
    }
    var t0 = performance.now();
    var duration = fadeMs(); // fixed for this tween, so a mid-fade speed
                             // change cannot stretch or truncate it

    function tick(now) {
      if (token !== fadeToken) { return; }
      var t = Math.min((now - t0) / duration, 1);
      fading.forEach(function (f) {
        applyColour(f.entry, mix(f.from, f.to, t));
      });
      if (t < 1) { requestAnimationFrame(tick); }
    }
    requestAnimationFrame(tick);
  }

  // roller-menu integration: switchToYear() delegates to this controller,
  // and the menu populates its year list from the (stub) layer cache keys
  window.quickmapTimeController = { setTime: setTime, times: times };
  var stub = {};
  times.forEach(function (t) { stub[t] = []; });
  window.quickmapLayerCache = stub;

  setTime(times[times.length - 1]);
}

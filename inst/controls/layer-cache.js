function(el, x) {
  var map = this;
  var layersByGroup = {};
  var latestYear = null;

  // STAGE 1: Cache all layers by group (all visible at this point)
  map.eachLayer(function(layer) {
    if (layer.options && layer.options.group) {
      var group = String(layer.options.group);
      if (!layersByGroup[group]) {
        layersByGroup[group] = [];
      }
      layersByGroup[group].push(layer);

      // Track latest year (string compare works for ISO dates)
      if (!latestYear || group > latestYear) {
        latestYear = group;
      }
    }
  });

  // Store globally for slider access
  window.quickmapLayerCache = layersByGroup;

  // STAGE 2: Hide all years except latest
  Object.keys(layersByGroup).forEach(function(yr) {
    if (yr !== latestYear) {
      layersByGroup[yr].forEach(function(layer) {
        map.removeLayer(layer);
      });
    }
  });

  console.log('Layer cache initialized:', Object.keys(layersByGroup).reduce(function(acc, k) {
    acc[k] = layersByGroup[k].length;
    return acc;
  }, {}));
  console.log('Default year visible:', latestYear);
}

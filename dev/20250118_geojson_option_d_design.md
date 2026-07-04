# Option D: GeoJSON Layer with JS Style Function

**Date:** 2025-01-18
**Status:** Design doc (not implemented)
**Context:** Investigation into reducing HTML file size from 27MB to ~2MB

---

## Problem Statement

Current leaflet approach serializes icon data per-marker:
- 180 `addMarkers()` calls (1 per time period × layer)
- Icons deduplicated within each call, but not across calls
- Same 11 icon SVGs repeated 180 times = ~2000 icon definitions
- Result: 27MB HTML files for 68k markers

---

## Proposed Solution

Instead of creating icon objects in R and serializing them, send raw data as GeoJSON and let JavaScript apply styles at render time.

### Current approach (bloated)

```
R: data → makeSymbolsSize() → 68k icon objects → JSON serialize → 27MB HTML
                                    ↓
Browser: parse JSON → create markers with embedded icons
```

### GeoJSON approach (lean)

```
R: data → GeoJSON points (coords + properties) → ~2MB HTML
                                    ↓
Browser: parse GeoJSON → JS style function → create styled markers
```

---

## Implementation Outline

### R side

```r
# 1. Convert data to GeoJSON (just coordinates + pollutant value)
geojson <- sf::st_as_sf(data, coords = c("Longitude", "Latitude"), crs = 4326)
geojson <- geojson[, c("pollutant_value", "year", "shape", "geometry")]

# 2. Add to map with onRender callback for styling
map %>%
  addGeoJSON(
    geojson = sf::st_as_text(geojson),
    group = "markers"
  ) %>%
  htmlwidgets::onRender("
    function(el, x) {
      // JS styling code - see below
    }
  ")
```

### JavaScript side

```javascript
function(el, x) {
  // Define icon SVGs once (11 colors × n shapes)
  var iconCache = {
    'circle-0': L.divIcon({html: '<svg>...</svg>', className: 'qm-icon'}),
    'circle-1': L.divIcon({html: '<svg>...</svg>', className: 'qm-icon'}),
    // ... all color indices
    'diamond-0': L.divIcon({html: '<svg>...</svg>', className: 'qm-icon'}),
    // ... etc
  };

  // Thresholds from colour scale
  var thresholds = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, Infinity];

  // Style function maps value → color index
  function getColorIndex(value) {
    for (var i = 0; i < thresholds.length - 1; i++) {
      if (value < thresholds[i + 1]) return i;
    }
    return thresholds.length - 1;
  }

  function getIcon(properties) {
    var shape = properties.shape || 'circle';
    var colorIdx = getColorIndex(properties.pollutant_value);
    return iconCache[shape + '-' + colorIdx];
  }

  // Apply to each feature
  this.eachLayer(function(layer) {
    if (layer.feature) {
      layer.setIcon(getIcon(layer.feature.properties));
    }
  });
}
```

---

## Size Comparison

| Metric | Current | GeoJSON approach |
|--------|---------|------------------|
| Per-marker data | ~400 bytes (icon SVG) | ~30 bytes (coords + value) |
| 68k markers | 27 MB | 2 MB |
| Icon definitions | Repeated per call | Once in JS (~5KB) |
| **Total** | **~27 MB** | **~2-3 MB** |

---

## Challenges

### 1. Time grouping
- Currently: leaflet groups handle show/hide by year
- GeoJSON: Need to filter features in JS or use multiple GeoJSON layers
- Solution: Add `year` property, filter in JS on year change

### 2. Multiple shapes
- Need `shape` property in GeoJSON
- Icon cache must include all shape × color combinations
- Estimate: 10 shapes × 11 colors = 110 cached icons (~50KB)

### 3. Labels and popups
- Currently handled by addMarkers labelOptions
- GeoJSON: Need to bind popups/tooltips separately
- Solution: Use `onEachFeature` callback

### 4. Static image export
- webshot2 captures rendered state, should still work
- May need delay for JS styling to complete

### 5. Integration effort
- Significant refactor of `create_generic_icons()` and `add_layer()`
- Need to pass colour scale thresholds to JS
- Need to generate icon cache SVGs

---

## Why This Is "MapLibre-like"

This approach follows the same patterns as MapLibre GL JS:

1. **Data/style separation** - GeoJSON holds data, style applied separately
2. **Client-side styling** - Browser applies styles, not pre-computed
3. **GeoJSON as interchange** - Standard format, no custom serialization
4. **Expression-based styling** - Value → style mapping via functions

Skills and code patterns transfer directly to a V2.0 MapLibre implementation.

---

## Recommendation

**Don't implement for V1.0** unless file size becomes a blocker for real users.

Reasons:
- Significant refactor effort (2-3 days)
- Adds complexity to codebase
- 68k markers is edge case; typical use is 100-500 markers
- Better to do clean MapLibre rewrite for V2.0

If needed for V1.x:
- Implement as optional backend: `create_pollution_map(..., backend = "geojson")`
- Keep current approach as default for compatibility

---

## Related Files

- `versions/quickmap_0_9_5_failed_svgicon_experiment.R` - Failed attempt using makeIcon with SVG data URIs
- Investigation notes in conversation transcript 2025-01-18

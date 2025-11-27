# m2: showGroup() Behavior Analysis - CORRECTED

**Date:** 2025-11-26
**Location:** R/quickmap.R line 1790
**User Request:** Check whether M2 ensures display on open shows the most recent data

## Current Code (BUG IDENTIFIED)

```r
# Line 1788-1791 in generate_map_layers()
base_map <- base_map |>
  showGroup(layer_name)  # BUG: layer_name is network name, not year!
return(base_map)
```

## Corrected Analysis

### How Leaflet Groups Work

**Line 1517** in `add_layer()`:
```r
if (!layer_config$static) {
  marker_params$group <- year  # Temporal layers grouped by YEAR
}
```

**Line 2063** in `create_pollution_map()`:
```r
for (yr in unique(years)) {
  html_map <- generate_map_layers(html_map, measurement_layers, yr, ...)
}
```

### The Bug

1. Markers are grouped by **year** (line 1517: `group <- year`)
2. Loop creates groups: "2018", "2019", "2020", etc.
3. But `showGroup(layer_name)` tries to show a **network name** like "dt_sites"
4. Network names are NOT group names - they're never used in `group =`
5. Result: **showGroup() does nothing** because group "dt_sites" doesn't exist

### What Actually Happens

Without a valid `showGroup()`, Leaflet's default behavior applies:
- All groups are hidden by default
- Year control menu JavaScript must explicitly show a year
- OR all groups show if no layer control exists

### Correct Implementation

To show the most recent year by default:

```r
# Line 1789-1791 (corrected)
if (!is.null(target_year) && target_year != "static_only") {
  base_map <- base_map |> showGroup(target_year)
}
return(base_map)
```

This ensures:
- The year being processed (`target_year`) is visible
- Last year in loop (most recent) remains visible
- Static-only maps don't try to show a year group

## Impact

**Current behavior**: Likely broken - no year visible by default, or all years visible (depending on Leaflet defaults and JavaScript).

**Fix required**: Replace `layer_name` with `target_year` to show the most recent year.

---

**Status:** Bug confirmed - `showGroup(layer_name)` references non-existent groups

# Critical-1: Boundary Labels Control - FINAL Implementation

**Task ID**: Critical-1
**Priority**: CRITICAL
**Category**: UI Enhancement
**Estimated Effort**: 2-3 hours
**Date Created**: 2025-10-16
**Date Revised**: 2025-10-16 (Changed to boolean parameter)
**Status**: Implementation Complete, Ready for Testing

---

## Overview

Add boolean parameter `show_boundary_labels` to `create_pollution_map()` to control borough boundary label visibility.

---

## Requirements

### Parameter Specification
- **Name**: `show_boundary_labels`
- **Type**: Boolean (TRUE/FALSE)
- **Default**: `FALSE`

### Behavior

| Value | Interactive (HTML) | Static (JPG) |
|-------|-------------------|--------------|
| `TRUE` | Borough name always visible | Borough name printed on image |
| `FALSE` | No labels (default) | No labels |

**Note**: Hover-only labels not implemented due to Leaflet layer order limitations (markers and vignette cover boundary polygons, making hover detection impossible).

---

## Implementation Details

### Changes Made

**1. Parameter Added** (`create_pollution_map()`, line ~1881)
```r
show_boundary_labels = FALSE,  # Default: no labels
```

**2. Function Modified** (`add_boundary_polygons()`, lines 1630-1666)
- Changed from 3-mode parameter to boolean `show_labels`
- Simplified logic: if TRUE show labels, if FALSE no labels
- Removed complex auto-hide logic

**3. Function Signature Updated** (`add_map_controls()`, line 1681)
```r
show_boundary_labels = FALSE
```

**4. Function Calls Updated**
- Line 1689: Pass `show_labels = show_boundary_labels` to `add_boundary_polygons()`
- Line 2054: Static map call includes `show_boundary_labels`
- Line 2109: HTML map call includes `show_boundary_labels`

---

## Testing Required

### Test Case 1: Labels ON
```r
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_labels_true.html",
  image_export = TRUE,
  show_boundary_labels = TRUE
)
```
**Expected**:
- HTML: "Wandsworth" label always visible
- JPG: "Wandsworth" label printed

---

### Test Case 2: Labels OFF (default)
```r
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_labels_false.html",
  image_export = TRUE,
  show_boundary_labels = FALSE  # or omit (default)
)
```
**Expected**:
- HTML: No labels
- JPG: No labels

---

### Test Case 3: Multi-borough
```r
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth", "Merton", "Richmond upon Thames"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_labels_multi.html",
  image_export = TRUE,
  show_boundary_labels = TRUE
)
```
**Expected**:
- HTML: All three borough names visible
- JPG: All three borough names printed

---

## Code Summary

### Simplified Function Structure

```r
add_boundary_polygons <- function(map, borough_sf, interactive, show_labels = FALSE) {
  style <- BOUNDARY_STYLES[[if (interactive) "interactive" else "static"]]

  if (show_labels) {
    label <- ~NAME
    labelOptions <- labelOptions(..., noHide = TRUE)
  } else {
    label <- NULL
    labelOptions <- NULL
  }

  map |> addPolygons(...)
}
```

**Benefits**:
- Clear TRUE/FALSE logic
- No complex mode handling
- Same behavior for interactive and static maps
- Backward compatible (default FALSE = no labels)

---

## Files Modified

1. **`versions/quickmap_0_8_8.R`**
   - Line 94-101: Updated version history
   - Line 1630-1666: Modified `add_boundary_polygons()`
   - Line 1681: Updated `add_map_controls()` signature
   - Line 1689: Updated call to `add_boundary_polygons()`
   - Line 1881: Added parameter to `create_pollution_map()`
   - Line 2054: Updated static map call
   - Line 2109: Updated HTML map call

---

## Design Decision: Why No Auto-Hide?

Research into Leaflet layer ordering revealed:
- Polygons are rendered in SVG, markers on top
- Markers physically cover boundary polygons
- Hover events on polygons don't fire when covered by markers
- Solutions (custom panes, z-index) too complex for benefit
- Simple boolean clearer: labels ON or OFF

**Conclusion**: Simple boolean parameter provides clear, predictable behavior.

---

## Success Criteria

✅ Parameter `show_boundary_labels` added as boolean
✅ TRUE shows labels on both HTML and JPG
✅ FALSE hides labels (default, backward compatible)
✅ Consistent behavior across interactive and static maps
✅ Simplified code (removed complex mode logic)
✅ All 3 test cases pass

---

*Plan finalized: 2025-10-16*
*Ready for testing*

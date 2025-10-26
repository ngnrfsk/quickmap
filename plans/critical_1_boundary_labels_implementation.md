# Critical-1: Boundary Labels Control - Implementation Plan

**Task ID**: Critical-1
**Priority**: CRITICAL
**Category**: UI Enhancement
**Estimated Effort**: 2-3 hours
**Date Created**: 2025-10-16
**Status**: Ready for Implementation

---

## Overview

Add parameter `show_boundary_labels` to `create_pollution_map()` to control borough boundary label visibility with three modes: `"on"`, `"off"`, and `"auto-hide"`.

---

## Requirements

### Parameter Specification
- **Name**: `show_boundary_labels`
- **Default**: `"auto-hide"`
- **Valid values**: `"on"` | `"off"` | `"auto-hide"`

### Behavior Matrix

| Mode | Interactive (HTML) | Static (JPG) |
|------|-------------------|--------------|
| `"on"` | Labels always visible | Labels printed on image |
| `"off"` | No labels | No labels |
| `"auto-hide"` | Hover to show (Leaflet API) | No labels (treated as `"off"`) |

---

## Current State

**File**: `quickmap.R`, lines 1612-1629

```r
add_boundary_polygons <- function(map, borough_sf, interactive) {
  style <- BOUNDARY_STYLES[[if (interactive) "interactive" else "static"]]
  label <- if (interactive) ~NAME else NULL
  labelOptions <- if (interactive) LABEL_OPTIONS else NULL

  map |>
    addPolygons(
      data = borough_sf,
      color = style$color,
      weight = style$weight,
      dashArray = style$dashArray,
      opacity = style$opacity,
      fillColor = style$fillColor,
      fillOpacity = style$fillOpacity,
      label = label,
      labelOptions = labelOptions
    )
}
```

**Current behavior**: Interactive maps show hover labels, static maps show no labels.

**LABEL_OPTIONS usage**: Defined once at line 447, used once at line 1615. Consistent throughout code.

---

## Implementation Steps

### Step 1: Add Parameter to `create_pollution_map()`

**File**: `quickmap.R` (line ~1833)

**Add after `show_banner` parameter**:

```r
create_pollution_map <- function(
  # ... existing parameters ...
  show_legend = TRUE,
  show_banner = FALSE,
  show_boundary_labels = "auto-hide",  # NEW PARAMETER
  banner_color = "#078141",
  # ... rest of parameters ...
)
```

---

### Step 2: Modify `add_boundary_polygons()` Function

**File**: `quickmap.R` (lines 1612-1629)

**Replace entire function**:

```r
# Helper to add boundary polygons
add_boundary_polygons <- function(map, borough_sf, interactive, label_mode = "auto-hide") {
  style <- BOUNDARY_STYLES[[if (interactive) "interactive" else "static"]]

  # Determine label and labelOptions based on mode
  # For static maps: auto-hide is treated as off
  if (!interactive && label_mode == "auto-hide") {
    label_mode <- "off"
  }

  # Set label and labelOptions
  if (label_mode == "off") {
    label <- NULL
    labelOptions <- NULL
  } else if (label_mode == "on") {
    label <- ~NAME
    # Always visible labels - copy LABEL_OPTIONS and add noHide
    labelOptions <- labelOptions(
      style = list(
        "font-weight" = "bold",
        padding = "3px 8px",
        "background-color" = "rgba(255,255,255,0.7)",
        "border-color" = "rgba(0,0,0,0.1)",
        "border-radius" = "4px"
      ),
      textsize = "12px",
      direction = "auto",
      noHide = TRUE  # Makes labels permanently visible
    )
  } else if (label_mode == "auto-hide") {
    label <- ~NAME
    labelOptions <- LABEL_OPTIONS  # Use existing constant
  }

  map |>
    addPolygons(
      data = borough_sf,
      color = style$color,
      weight = style$weight,
      dashArray = style$dashArray,
      opacity = style$opacity,
      fillColor = style$fillColor,
      fillOpacity = style$fillOpacity,
      label = label,
      labelOptions = labelOptions
    )
}
```

**Changes**:
- Add `label_mode` parameter with default `"auto-hide"`
- Convert `label_mode = "auto-hide"` to `"off"` for static maps
- Use if/else to set `label` and `labelOptions` based on mode
- For `"on"`: create labelOptions inline with `noHide = TRUE`
- For `"auto-hide"`: use existing `LABEL_OPTIONS` constant
- For `"off"`: set both to `NULL`

---

### Step 3: Add Parameter to `add_map_controls()`

**File**: `quickmap.R` (line ~1632)

**Add parameter to function signature**:

```r
add_map_controls <- function(
  map,
  legend_info = NULL,
  title_prefix = "",
  borough_sf = NULL,
  vignette_overlay = NULL,
  vignette_overlay_on = FALSE,
  bbox,
  show_title = TRUE,
  interactive = TRUE,
  years = NULL,
  show_boundary_labels = "auto-hide"  # NEW PARAMETER
) {
```

---

### Step 4: Update Call to `add_boundary_polygons()` in `add_map_controls()`

**File**: `quickmap.R` (line ~1651)

**Find**:
```r
if (!is.null(borough_sf)) {
  map <- add_boundary_polygons(map, borough_sf, interactive)
}
```

**Replace with**:
```r
if (!is.null(borough_sf)) {
  map <- add_boundary_polygons(map, borough_sf, interactive, label_mode = show_boundary_labels)
}
```

---

### Step 5: Update All Calls to `add_map_controls()`

**File**: `quickmap.R` (search for all instances of `add_map_controls(`)

**Expected locations**: Around lines 1950-2000

**Action**: Add `show_boundary_labels = show_boundary_labels` parameter to each call.

**Example**:
```r
map <- add_map_controls(
  map = map,
  legend_info = legend_info,
  title_prefix = title_prefix,
  borough_sf = borough_sf,
  vignette_overlay = vignette_overlay,
  vignette_overlay_on = vignette_overlay_on,
  bbox = bbox,
  show_title = show_title,
  interactive = TRUE,
  years = years,
  show_boundary_labels = show_boundary_labels  # NEW PARAMETER
)
```

---

## Testing Plan

**Important**: Tests should source the edited working version, not the stable main code.

### Test Case 1: "on" mode
```r
# Source the working development version with changes
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_on.html",
  image_export = TRUE,  # Tests both HTML and JPG
  show_boundary_labels = "on"
)
```
**Expected**:
- HTML: Borough name "Wandsworth" always visible
- JPG: Borough name printed on image

---

### Test Case 2: "off" mode
```r
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_off.html",
  image_export = TRUE,
  show_boundary_labels = "off"
)
```
**Expected**:
- HTML: No labels
- JPG: No labels

---

### Test Case 3: "auto-hide" mode (default)
```r
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_autohide.html",
  image_export = TRUE
  # show_boundary_labels defaults to "auto-hide"
)
```
**Expected**:
- HTML: Labels appear on hover only
- JPG: No labels (auto-hide treated as off)

---

### Test Case 4: Multi-borough scenario
```r
source("versions/quickmap_0_8_8.R")

create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth", "Merton", "Richmond upon Thames"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_multi.html",
  image_export = TRUE,
  show_boundary_labels = "on"
)
```
**Expected**:
- HTML: All three borough names visible
- JPG: All three borough names printed

---

## Implementation Checklist

### Setup
- [ ] Copy `versions/quickmap_0_8_7_3.R` to `versions/quickmap_0_8_8.R` as working version

### Code Changes (in `versions/quickmap_0_8_8.R`)
- [ ] Step 1: Add `show_boundary_labels` parameter to `create_pollution_map()` (line ~1833)
- [ ] Step 2: Modify `add_boundary_polygons()` function (lines 1612-1629)
- [ ] Step 3: Add parameter to `add_map_controls()` signature (line ~1632)
- [ ] Step 4: Update call to `add_boundary_polygons()` (line ~1651)
- [ ] Step 5: Update all calls to `add_map_controls()` with new parameter

### Testing (source `versions/quickmap_0_8_8.R`)
- [ ] Test Case 1: "on" mode (HTML + JPG)
- [ ] Test Case 2: "off" mode (HTML + JPG)
- [ ] Test Case 3: "auto-hide" mode (HTML + JPG)
- [ ] Test Case 4: Multi-borough scenario

### Documentation & Version Control
- [ ] Copy tested `versions/quickmap_0_8_8.R` to main `quickmap.R`
- [ ] Update `CLAUDE.md` with new parameter documentation
- [ ] Update `PROJECT_STATUS_SUMMARY.md`
- [ ] Move Critical-1 to completed in `tasks/all_tasks_log.md`
- [ ] Commit to git with descriptive message

---

## Files to Modify

### Development Phase
1. **`versions/quickmap_0_8_8.R`** (create from `quickmap_0_8_7_3.R`, 5 modification points)
   - Line ~1612: Modify `add_boundary_polygons()` function
   - Line ~1632: Add parameter to `add_map_controls()`
   - Line ~1651: Update call to `add_boundary_polygons()`
   - Line ~1833: Add parameter to `create_pollution_map()`
   - Lines ~1950-2000: Update calls to `add_map_controls()`

### After Testing
2. **`quickmap.R`** - Copy from tested `versions/quickmap_0_8_8.R`
3. **`CLAUDE.md`** - Add parameter documentation
4. **`PROJECT_STATUS_SUMMARY.md`** - Update status
5. **`tasks/all_tasks_log.md`** - Mark task complete

---

## Risk Assessment

**Risk Level**: Low

**Mitigation**:
- Backward compatible (default maintains current behavior)
- Simple inline logic (no helper function needed)
- Uses existing `LABEL_OPTIONS` constant for consistency
- Early testing will catch any Leaflet API issues

---

## Success Criteria

✅ Parameter `show_boundary_labels` added to `create_pollution_map()`
✅ "on" mode shows permanent labels (HTML and JPG)
✅ "off" mode hides all labels (HTML and JPG)
✅ "auto-hide" mode shows hover labels (HTML only)
✅ Static maps treat "auto-hide" as "off"
✅ All 4 test cases pass
✅ Backward compatible (existing code unchanged)
✅ Consistent label styling using existing constants

---

*Plan created: 2025-10-16*
*Ready for implementation*

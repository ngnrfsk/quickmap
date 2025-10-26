# Critical-1: Boundary Labels Control Implementation Plan

**Task ID**: Critical-1
**Priority**: CRITICAL
**Category**: UI Enhancement
**Estimated Effort**: 2-3 hours
**Date Created**: 2025-10-16

---

## Overview

Add a new parameter `show_boundary_labels` to `create_pollution_map()` that controls borough boundary label visibility with three modes: `"on"`, `"off"`, and `"auto-hide"`. Make behavior consistent between static and dynamic maps.

---

## Requirements Summary

### Parameter Specification
- **Parameter name**: `show_boundary_labels`
- **Default value**: `"auto-hide"`
- **Valid values**: `"on"`, `"off"`, `"auto-hide"`

### Behavior Matrix

| Mode | Interactive (HTML) Maps | Static (JPG) Maps |
|------|------------------------|-------------------|
| `"on"` | Labels always visible (permanent) | Labels always visible (printed) |
| `"off"` | No labels | No labels |
| `"auto-hide"` | Leaflet's built-in hover-to-show | No labels (treated as `"off"`) |

### Design Principle
Keep code adjustments as simple as possible. Use existing `LABEL_OPTIONS` styling for all visible labels.

---

## Current State Analysis

### Existing Code (lines 1612-1629)
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

**Current behavior**:
- Interactive: hover labels with `LABEL_OPTIONS` styling
- Static: no labels at all

**Problem**: Hard-coded behavior, no user control

---

## Implementation Plan

### Step 1: Add Parameter to `create_pollution_map()` Function
**File**: `quickmap.R` (around line 1808)

**Action**: Add new parameter in the styling parameters section:

```r
create_pollution_map <- function(
  # ... existing parameters ...
  vignette_overlay_on = TRUE,
  scale_to_use = "who_no2",
  use_data_labels = FALSE,
  show_legend = TRUE,
  show_banner = FALSE,
  show_boundary_labels = "auto-hide",  # NEW PARAMETER
  banner_color = "#078141",
  # ... rest of parameters ...
)
```

**Location**: After `show_banner` parameter (line ~1833)

---

### Step 2: Create Label Options Helper Function
**File**: `quickmap.R` (insert before `add_boundary_polygons()`, around line 1611)

**Action**: Create a new helper function to generate appropriate label options:

```r
# Helper to create label options based on mode
get_boundary_label_options <- function(mode, interactive) {
  # For static maps: auto-hide is treated as off
  if (!interactive && mode == "auto-hide") {
    mode <- "off"
  }

  # Determine label and labelOptions based on mode
  if (mode == "off") {
    list(label = NULL, labelOptions = NULL)
  } else if (mode == "on") {
    # Always visible labels
    label_opts_on <- labelOptions(
      style = list(
        "font-weight" = "bold",
        padding = "3px 8px",
        "background-color" = "rgba(255,255,255,0.7)",
        "border-color" = "rgba(0,0,0,0.1)",
        "border-radius" = "4px"
      ),
      textsize = "12px",
      direction = "auto",
      noHide = TRUE  # KEY: Makes labels permanently visible
    )
    list(label = ~NAME, labelOptions = label_opts_on)
  } else if (mode == "auto-hide") {
    # Hover-to-show labels (only works for interactive)
    list(label = ~NAME, labelOptions = LABEL_OPTIONS)
  }
}
```

**Rationale**:
- Centralizes label logic in one place
- Handles static/interactive differences automatically
- Uses existing `LABEL_OPTIONS` constant for auto-hide mode
- Creates new options with `noHide = TRUE` for "on" mode

---

### Step 3: Modify `add_boundary_polygons()` Function
**File**: `quickmap.R` (lines 1612-1629)

**Action**: Update function signature and implementation:

```r
# Helper to add boundary polygons
add_boundary_polygons <- function(map, borough_sf, interactive, label_mode = "auto-hide") {
  style <- BOUNDARY_STYLES[[if (interactive) "interactive" else "static"]]

  # Get appropriate label configuration
  label_config <- get_boundary_label_options(label_mode, interactive)

  map |>
    addPolygons(
      data = borough_sf,
      color = style$color,
      weight = style$weight,
      dashArray = style$dashArray,
      opacity = style$opacity,
      fillColor = style$fillColor,
      fillOpacity = style$fillOpacity,
      label = label_config$label,
      labelOptions = label_config$labelOptions
    )
}
```

**Changes**:
- Add `label_mode` parameter with default `"auto-hide"`
- Replace hard-coded label logic with call to `get_boundary_label_options()`
- Use returned `label_config$label` and `label_config$labelOptions`

---

### Step 4: Update Function Calls to `add_boundary_polygons()`
**File**: `quickmap.R` (line ~1651 in `add_map_controls()`)

**Action**: Pass the new parameter through:

**Current code**:
```r
if (!is.null(borough_sf)) {
  map <- add_boundary_polygons(map, borough_sf, interactive)
}
```

**Updated code**:
```r
if (!is.null(borough_sf)) {
  map <- add_boundary_polygons(map, borough_sf, interactive, label_mode = show_boundary_labels)
}
```

---

### Step 5: Thread Parameter Through Call Chain
**File**: `quickmap.R`

**Action**: Update `add_map_controls()` function signature to accept the parameter:

**Find** (around line 1632):
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
  years = NULL
) {
```

**Update to**:
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

**Then find all calls to `add_map_controls()`** in `create_pollution_map()` and add the parameter.

**Search pattern**: `add_map_controls(`

**Expected locations**: Around lines 1950-2000 (both HTML and static map generation)

**Update each call** to include:
```r
show_boundary_labels = show_boundary_labels
```

---

## Testing Plan

### Test Cases

#### Test 1: Interactive Map - "on" mode
```r
source("quickmap.R")
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_on.html",
  show_boundary_labels = "on"
)
```
**Expected**: Borough name "Wandsworth" always visible on map

---

#### Test 2: Interactive Map - "off" mode
```r
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_off.html",
  show_boundary_labels = "off"
)
```
**Expected**: No borough labels at all

---

#### Test 3: Interactive Map - "auto-hide" mode (default)
```r
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_autohide.html"
  # show_boundary_labels defaults to "auto-hide"
)
```
**Expected**: Borough name appears on hover only

---

#### Test 4: Static Map - "on" mode
```r
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_static_on.html",
  image_export = TRUE,
  show_boundary_labels = "on"
)
```
**Expected**: Borough name printed on JPG image

---

#### Test 5: Static Map - "off" mode
```r
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_static_off.html",
  image_export = TRUE,
  show_boundary_labels = "off"
)
```
**Expected**: No borough labels on JPG

---

#### Test 6: Static Map - "auto-hide" mode
```r
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_static_autohide.html",
  image_export = TRUE,
  show_boundary_labels = "auto-hide"
)
```
**Expected**: No borough labels on JPG (auto-hide treated as off)

---

#### Test 7: Multi-borough map
```r
map <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth", "Merton", "Richmond upon Thames"),
  years_to_plot = 2024,
  output_file = "aq_maps/test_boundary_multi.html",
  show_boundary_labels = "on"
)
```
**Expected**: All three borough names visible

---

## Implementation Checklist

- [ ] Step 1: Add `show_boundary_labels` parameter to `create_pollution_map()` signature
- [ ] Step 2: Create `get_boundary_label_options()` helper function
- [ ] Step 3: Modify `add_boundary_polygons()` to accept and use `label_mode` parameter
- [ ] Step 4: Update call to `add_boundary_polygons()` in `add_map_controls()`
- [ ] Step 5a: Add `show_boundary_labels` parameter to `add_map_controls()` signature
- [ ] Step 5b: Update all calls to `add_map_controls()` to pass `show_boundary_labels`
- [ ] Test Case 1: Interactive "on" mode
- [ ] Test Case 2: Interactive "off" mode
- [ ] Test Case 3: Interactive "auto-hide" mode
- [ ] Test Case 4: Static "on" mode
- [ ] Test Case 5: Static "off" mode
- [ ] Test Case 6: Static "auto-hide" mode
- [ ] Test Case 7: Multi-borough map
- [ ] Code review and cleanup
- [ ] Update CLAUDE.md documentation
- [ ] Create version 0.8.8 in versions/ directory
- [ ] Commit to git with descriptive message

---

## Files to Modify

1. **`quickmap.R`** (primary changes)
   - Line ~1611: Add `get_boundary_label_options()` function
   - Line ~1612: Modify `add_boundary_polygons()` function
   - Line ~1632: Add parameter to `add_map_controls()` function
   - Line ~1651: Update call to `add_boundary_polygons()`
   - Line ~1808: Add parameter to `create_pollution_map()` function
   - Lines ~1950-2000: Update calls to `add_map_controls()`

2. **`CLAUDE.md`** (documentation update)
   - Add `show_boundary_labels` to parameter documentation
   - Update examples to show new parameter usage

3. **`PROJECT_STATUS_SUMMARY.md`** (status update)
   - Mark Critical-1 as completed
   - Update current version number

4. **`tasks/all_tasks_log.md`** (task log update)
   - Move Critical-1 to COMPLETED section
   - Add completion date and version

---

## Risk Assessment

**Risk Level**: Low

**Potential Issues**:
1. **Leaflet API compatibility**: Ensure `noHide = TRUE` works as expected
   - Mitigation: Test thoroughly with interactive maps first

2. **Label overlap**: Multiple boroughs may have overlapping labels when "on"
   - Mitigation: Current `direction = "auto"` should handle this
   - Note for future: Consider label clustering/positioning enhancement

3. **Static map rendering**: Labels may not render correctly in webshot2
   - Mitigation: Test static exports early in implementation

4. **Performance**: Permanent labels may impact performance with many boroughs
   - Mitigation: Unlikely to be an issue with typical 1-5 borough maps

---

## Notes

- This implementation maintains backward compatibility (default "auto-hide" preserves current behavior)
- Simple parameter addition with minimal code changes
- Uses existing styling constants where possible
- Clear separation of concerns (helper function for label logic)
- Easy to extend in future (e.g., add custom label styling parameter)

---

## Success Criteria

✅ User can set `show_boundary_labels = "on"` to see permanent labels
✅ User can set `show_boundary_labels = "off"` to hide all labels
✅ User can set `show_boundary_labels = "auto-hide"` for hover labels (interactive only)
✅ Static maps correctly interpret "auto-hide" as "off"
✅ Static maps with "on" display labels on exported JPG
✅ Labels use consistent styling across all modes
✅ Backward compatible (existing code works without changes)
✅ All test cases pass

---

*Plan created: 2025-10-16*
*Ready for implementation*

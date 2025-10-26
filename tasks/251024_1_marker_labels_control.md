# 251024_1_Marker Labels Control Implementation Plan

## Overview
Replace `use_data_labels` parameter with `show_marker_labels` to provide consistent label control across all data sources (OA files, CSV files, Schools).

## Problem Identified
- **OA data** (bl_nodes): Always shows pollution values - no control
- **CSV data** (dt_sites): Controlled by `use_data_labels` but limited (TRUE = custom labels, FALSE = blank)
- **All labels**: Set to `noHide = TRUE` (always visible, never hide)
- **Inconsistency**: Different data sources behave differently

## Solution: New Parameter `show_marker_labels`

### Parameter Values
1. **`FALSE`** (default) - No labels shown
2. **`TRUE`** - Show pollution values with auto-hide (hover only, `noHide = FALSE`)
3. **`"values_on"`** - Show pollution values always visible (`noHide = TRUE`)
4. **`"labels"`** - Use Label/School column with auto-hide; warn if column missing
5. **`"labels_on"`** - Use Label/School column always visible; warn if column missing

### Backward Compatibility
- Default `FALSE` maintains current behavior for most users
- Existing code with `use_data_labels = TRUE` will need updating (breaking change)
- Document migration path in version notes

## Implementation Steps

### 1. Update Function Signatures
**Files to modify:** `quickmap.R`, `versions/quickmap_0_8_8.R`

#### `create_pollution_map()` (line ~1864)
```r
# OLD:
use_data_labels = FALSE,

# NEW:
show_marker_labels = FALSE,  # FALSE | TRUE | "values_on" | "labels" | "labels_on"
```

#### `get_measurement_layers()` (line ~1398)
```r
# OLD:
get_measurement_layers <- function(csv_data_file, oa_data_file, school_file, use_data_labels)

# NEW:
get_measurement_layers <- function(csv_data_file, oa_data_file, school_file, show_marker_labels)
```

#### `prepare_dt_layer_data()` (line ~1447)
```r
# OLD:
prepare_dt_layer_data <- function(subset_data, pollutant, scale_to_use, use_data_labels)

# NEW:
prepare_dt_layer_data <- function(subset_data, pollutant, scale_to_use, show_marker_labels)
```

#### `prepare_bl_layer_data()` (line ~1432)
```r
# OLD:
prepare_bl_layer_data <- function(oa_subset, pollutant, scale_to_use)

# NEW:
prepare_bl_layer_data <- function(oa_subset, pollutant, scale_to_use, show_marker_labels)
```

### 2. Create Label Generation Helper Function
**Location:** After `prepare_static_layer_data()` (around line 1596)

```r
#' Generate labels based on show_marker_labels parameter
#'
#' @param data Data frame with spatial data
#' @param pollutant Pollutant column name (e.g., "no2", "pm25")
#' @param show_marker_labels Control parameter: FALSE | TRUE | "values_on" | "labels" | "labels_on"
#' @param layer_type Layer type: "bl_nodes", "dt_sites", or "schools"
#' @return Character vector of labels
generate_marker_labels <- function(data, pollutant, show_marker_labels, layer_type) {
  # Determine what labels to generate
  show_values <- show_marker_labels %in% c(TRUE, "values_on")
  show_custom <- show_marker_labels %in% c("labels", "labels_on")
  
  if (!show_values && !show_custom) {
    # No labels
    return(rep("", nrow(data)))
  }
  
  if (show_custom) {
    # Try to use Label column (CSV) or School column (schools)
    label_col <- if (layer_type == "schools") "School" else "Label"
    if (label_col %in% names(data)) {
      return(as.character(data[[label_col]]))
    } else {
      warning(
        "show_marker_labels set to '", show_marker_labels, 
        "' but no ", label_col, " column found in ", layer_type, 
        " data. No labels will be shown.",
        call. = FALSE
      )
      return(rep("", nrow(data)))
    }
  }
  
  # Show pollution values
  if (show_values) {
    value_str <- ifelse(
      is.na(data[[pollutant]]),
      "",
      paste(round(data[[pollutant]], 0), "ug/m3")
    )
    return(value_str)
  }
  
  return(rep("", nrow(data)))
}
```

### 3. Update `prepare_bl_layer_data()` (line 1432)
```r
prepare_bl_layer_data <- function(oa_subset, pollutant, scale_to_use, show_marker_labels) {
  if (nrow(oa_subset) == 0) return(NULL)
  
  # Generate labels using unified function
  labels <- generate_marker_labels(oa_subset, pollutant, show_marker_labels, "bl_nodes")
  
  list(
    data = oa_subset,
    labels = labels
  )
}
```

### 4. Update `prepare_dt_layer_data()` (line 1447)
```r
prepare_dt_layer_data <- function(subset_data, pollutant, scale_to_use, show_marker_labels) {
  # Pre-compute colors for all points
  colors <- sapply(subset_data[[pollutant]], assign_colour, scale = scale_to_use)
  
  # Generate labels using unified function
  labels <- generate_marker_labels(subset_data, pollutant, show_marker_labels, "dt_sites")
  
  list(
    data = subset_data,
    colors = colors,
    labels = labels
  )
}
```

### 5. Update `add_layer()` - Label Visibility Control (line 1520)
```r
add_layer <- function(
  map,
  layer_data,
  layer_config,
  year = NULL,
  pollutant = NULL,
  scale_to_use = NULL,
  label_sizing = 1.0,
  image_scale_factor = 1.0,
  show_marker_labels = FALSE  # NEW: Pass through from layer config
) {
  if (is.null(layer_data)) return(map)
  
  layer_type <- layer_config$layer_type
  
  icons <- create_generic_icons(
    layer_data$data,
    layer_type,
    pollutant,
    scale_to_use,
    image_scale_factor
  )
  
  label_text_size <- as.character(12 * label_sizing)
  
  # Determine noHide based on show_marker_labels value
  no_hide <- show_marker_labels %in% c("values_on", "labels_on")
  
  label_opts <- labelOptions(
    noHide = no_hide,  # CHANGED: Now controlled by parameter
    direction = "bottom",
    offset = c(0, 12),
    textOnly = TRUE,
    textsize = label_text_size,
    style = list(
      "background-color" = "rgba(255,255,255,0.5)",
      "padding" = "1px",
      "border-radius" = "3px",
      "border" = "1px solid rgba(0,0,0,0.1)"
    )
  )
  
  marker_params <- list(
    data = layer_data$data,
    lng = ~Longitude,
    lat = ~Latitude,
    icon = icons,
    label = layer_data$labels,
    labelOptions = label_opts
  )
  
  if (layer_type != "schools") {
    marker_params$group <- year
  }
  
  do.call(addMarkers, c(list(map = map), marker_params))
}
```

### 6. Thread Parameter Through Layer System

#### Update `get_measurement_layers()` (line 1398)
```r
get_measurement_layers <- function(csv_data_file, oa_data_file, school_file, show_marker_labels) {
  list(
    bl_nodes = list(
      enabled = (oa_data_file != "none"),
      data_source = "bl_annual_means_sf",
      layer_type = "bl_nodes",
      temporal = TRUE,
      prepare_function = "prepare_bl_layer_data",
      options = list(show_marker_labels = show_marker_labels)  # ADD
    ),
    dt_sites = list(
      enabled = (csv_data_file != "none"),
      data_source = "sf_data_wgs84",
      layer_type = "dt_sites",
      temporal = TRUE,
      prepare_function = "prepare_dt_layer_data",
      options = list(show_marker_labels = show_marker_labels)  # UPDATE
    ),
    schools = list(
      enabled = (school_file != "none"),
      data_source = "sf_schools_wgs84",
      layer_type = "schools",
      temporal = FALSE,
      prepare_function = "prepare_static_layer_data",
      options = list(show_marker_labels = show_marker_labels)  # ADD
    )
  )
}
```

#### Update `prepare_generic_layer_data()` (line 1484)
```r
prepare_generic_layer_data <- function(
  layer_config,
  year_data,
  pollutant = NULL,
  scale_to_use = NULL
) {
  # Extract show_marker_labels from options
  show_labels <- if (!is.null(layer_config$options))
    layer_config$options$show_marker_labels else FALSE
  
  switch(
    layer_config$layer_type,
    "bl_nodes" = {
      prepare_bl_layer_data(year_data, pollutant, scale_to_use, show_labels)
    },
    "dt_sites" = {
      prepare_dt_layer_data(year_data, pollutant, scale_to_use, show_labels)
    },
    "schools" = {
      prepare_static_layer_data(year_data)
    },
    stop("Unknown layer type: ", layer_config$layer_type)
  )
}
```

#### Update `generate_map_layers()` to pass parameter (line 1764)
```r
# In both calls to add_layer within generate_map_layers:
show_labels <- if (!is.null(layer_config$options))
  layer_config$options$show_marker_labels else FALSE

base_map <- add_layer(
  base_map,
  layer_data,
  layer_config,
  target_year,
  pollutant,
  scale_to_use,
  label_sizing = 1.0,
  image_scale_factor,
  show_marker_labels = show_labels  # ADD
)
```

### 7. Update `create_pollution_map()` Call Sites (line 1988, 1992)
```r
# Line 1988 - Thread parameter through
measurement_layers <- get_measurement_layers(
  csv_data_file,
  oa_data_file,
  school_file,
  show_marker_labels  # UPDATE from use_data_labels
)
```

### 8. Update LABEL_OPTIONS Constant (line 465)
**Remove or comment out** - no longer used as default
```r
# DEPRECATED: Label options now controlled by show_marker_labels parameter
# LABEL_OPTIONS <- labelOptions(...)
```

### 9. Update Version History
Add to version history at top of file:
```r
#   v0.8.9 - Marker Labels Control (Issue #6, 2025-10-24):
#             - Renamed use_data_labels to show_marker_labels with 5-state control
#             - Added generate_marker_labels() helper function for unified label generation
#             - All data sources (OA, CSV, Schools) now have consistent label behavior
#             - Breaking change: use_data_labels parameter removed
```

### 10. Testing Strategy
Create test file: `tests/test_marker_labels_control.R`

Test cases:
1. `show_marker_labels = FALSE` - No labels on any layer
2. `show_marker_labels = TRUE` - Pollution values on hover for OA and CSV
3. `show_marker_labels = "values_on"` - Pollution values always visible
4. `show_marker_labels = "labels"` - Custom labels on hover (CSV only)
5. `show_marker_labels = "labels_on"` - Custom labels always visible (CSV only)
6. Warning when `"labels"` used with OA data (no Label column)
7. Verify schools layer not affected (has own label logic)

## Files to Modify
1. `quickmap.R` - Main implementation
2. `versions/quickmap_0_8_8.R` - Copy to `quickmap_0_8_9.R` for new version
3. `tests/test_marker_labels_control.R` - New test file
4. `tasks/251024_1_marker_labels_control.md` - This plan document
5. `PROJECT_STATUS_SUMMARY.md` - Update status when complete

## Migration Notes for Users
```r
# OLD CODE (v0.8.8 and earlier):
create_pollution_map(
  csv_data_file = "data.csv",
  use_data_labels = TRUE  # Show custom labels from CSV
)

# NEW CODE (v0.8.9+):
create_pollution_map(
  csv_data_file = "data.csv",
  show_marker_labels = "labels"  # Show custom labels on hover
  # OR
  show_marker_labels = "labels_on"  # Show custom labels always
)
```

# tryCatch Usage Analysis

## Summary
7 tryCatch blocks found. 3 are useful, 4 are redundant wrapper patterns.

## Useful tryCatch (Keep)

### 1. **Line 99-114: get_openair_metadata()**
```r
tryCatch(
  {
    metadata <- openair::importMeta(source = source)
    if (is.null(metadata) || nrow(metadata) == 0) {
      stop("No metadata returned for source: ", source)
    }
    # Cache and return
  },
  error = function(e) {
    stop("Failed to fetch OpenAir metadata for '", source, "': ", e$message)
  }
)
```
**Verdict:** KEEP - Adds context to external API error, transforms error message to be more informative

### 2. **Line 774-779: load_yaml_config()**
```r
tryCatch(
  yaml::read_yaml(yaml_file),
  error = function(e) {
    stop("Failed to load '", yaml_file, "': ", e$message)
  }
)
```
**Verdict:** KEEP - Adds file path context to YAML parsing errors

### 3. **Line 832-842: load_theme()**
```r
theme <- tryCatch(
  {
    yaml::read_yaml(theme_file)
  },
  error = function(e) {
    warning("Failed to load theme from '", theme_file, "': ", e$message,
            ". Using default theme.")
    return(get_default_theme())
  }
)
```
**Verdict:** KEEP - Graceful degradation, continues with defaults on theme load failure

---

## Redundant tryCatch (Remove)

### 4. **Line 421-432: load_data_file()**
```r
tryCatch(
  {
    switch(
      file_type,
      "csv" = import_csv_data(file_path, required_cols),
      "rdata" = load_rdata_file(file_path, pollutant),
      stop("Unknown file type: ", file_type)
    )
  },
  error = function(e) {
    stop("Error loading file '", file_path, "': ", e$message)
  }
)
```
**Verdict:** REMOVE
- Just prepends "Error loading file" to message
- Hides which function failed (import_csv_data vs load_rdata_file)
- Stack trace more useful without wrapper
- Better: Let switch() fail naturally with clear function name in trace

**Replacement:**
```r
switch(
  file_type,
  "csv" = import_csv_data(file_path, required_cols),
  "rdata" = load_rdata_file(file_path, pollutant),
  stop("Unknown file type: ", file_type)
)
```

### 5. **Line 610-631: transform_to_wgs84()**
```r
tryCatch(
  {
    sf_obj <- sf::st_as_sf(df, coords = c(easting, northing), crs = crs_from) |>
      sf::st_transform(crs = 4326)
    coords <- sf::st_coordinates(sf_obj)
    sf_obj$Longitude <- coords[, 1]
    sf_obj$Latitude <- coords[, 2]
    if ("year" %in% names(df)) {
      sf_obj$year_str <- format(sf_obj$year, "%Y")
    }
    sf_obj
  },
  error = function(e) {
    stop("Coordinate transformation failed: ", e$message)
  }
)
```
**Verdict:** REMOVE
- Just says "Coordinate transformation failed"
- Doesn't say which step failed (st_as_sf? st_transform? st_coordinates?)
- sf package errors are already clear
- Stack trace more useful without wrapper

**Replacement:**
```r
sf_obj <- sf::st_as_sf(df, coords = c(easting, northing), crs = crs_from) |>
  sf::st_transform(crs = 4326)
coords <- sf::st_coordinates(sf_obj)
sf_obj$Longitude <- coords[, 1]
sf_obj$Latitude <- coords[, 2]
if ("year" %in% names(df)) {
  sf_obj$year_str <- format(sf_obj$year, "%Y")
}
sf_obj
```

### 6. **Line 635-655: create_vignette_overlay()**
```r
tryCatch(
  {
    original_bbox <- st_bbox(spatial_feature)
    width <- original_bbox["xmax"] - original_bbox["xmin"]
    height <- original_bbox["ymax"] - original_bbox["ymin"]
    extended_bbox <- c(
      xmin = original_bbox["xmin"] - (width * 0.5),
      ymin = original_bbox["ymin"] - (height * 0.5),
      xmax = original_bbox["xmax"] + (width * 0.5),
      ymax = original_bbox["ymax"] + (height * 0.5)
    )
    vignette_sf <- st_as_sfc(st_bbox(extended_bbox, crs = st_crs(spatial_feature)))
    st_sf(
      geometry = vignette_sf,
      fillColor = "black",
      fillOpacity = 0.4,
      stroke = FALSE
    )
  },
  error = function(e) {
    warning("Failed to create vignette overlay: ", e$message)
    return(NULL)
  }
)
```
**Verdict:** BORDERLINE - Keep for graceful degradation
- Returns NULL on failure instead of stopping execution
- Vignette is optional cosmetic feature
- Map still works without it
- **KEEP** but only because failure recovery is intentional

### 7. **Line 886-897: convert_colors_to_hex() inner tryCatch**
```r
sapply(color_vector, function(color) {
  if (grepl("^#[0-9A-Fa-f]{6}$", color)) {
    return(toupper(color))
  } else {
    tryCatch(
      {
        rgb_vals <- col2rgb(color)
        return(toupper(sprintf("#%02X%02X%02X", rgb_vals[1], rgb_vals[2], rgb_vals[3])))
      },
      error = function(e) {
        warning("Invalid color '", color, "' - using fallback gray")
        return("#808080")
      }
    )
  }
})
```
**Verdict:** BORDERLINE - Keep for color fallback
- Graceful degradation to gray for invalid colors
- Prevents entire map failure from bad color value
- **KEEP** - reasonable fallback behavior

### 8. **Line 1240-1261: save_html_and_style()**
```r
tryCatch(
  {
    inject_banner_legend_controls(
      html_file = html_file,
      title = if (show_banner) title else NULL,
      banner_colour = banner_colour,
      legend_info = legend_info,
      measurement_layers = measurement_layers,
      show_legend = show_legend,
      roller_menu_html = roller_menu_html,
      layer_cache_js = layer_cache_js,
      image_mode = image_mode
    )
  },
  error = function(e) {
    warning(
      "Failed to inject banner/legend/controls: ", e$message,
      "\nSaved basic map without custom styling."
    )
  }
)
```
**Verdict:** REMOVE
- Just prints warning and continues
- Map already saved before this (line 1228-1237)
- If injection fails, user gets broken HTML with no indication why
- Better to fail fast so user knows there's a problem

**Replacement:**
```r
inject_banner_legend_controls(
  html_file = html_file,
  title = if (show_banner) title else NULL,
  banner_colour = banner_colour,
  legend_info = legend_info,
  measurement_layers = measurement_layers,
  show_legend = show_legend,
  roller_menu_html = roller_menu_html,
  layer_cache_js = layer_cache_js,
  image_mode = image_mode
)
```

---

## Recommendations

### Remove (4 instances):
1. **load_data_file:421-432** - Hides which loader failed
2. **transform_to_wgs84:610-631** - Obscures sf errors
3. **save_html_and_style:1240-1261** - Continues with broken HTML
4. **Possibly load_rdata_file** - Check if it has similar pattern

### Keep (3 instances):
1. **get_openair_metadata:99-114** - Adds API context
2. **load_yaml_config:774-779** - Adds file path context
3. **load_theme:832-842** - Graceful fallback to defaults
4. **create_vignette_overlay:635-655** - Optional feature, graceful degradation
5. **convert_colors_to_hex:886-897** - Color fallback

## Code Quality Impact

Removing redundant tryCatch:
- **Better debugging:** Full stack traces visible
- **Clearer errors:** Library errors are already descriptive
- **Fewer lines:** -15 to -20 lines total
- **Faster failures:** No double error handling

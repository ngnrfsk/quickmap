# Single-Use Function Abstraction Review

**Date:** 2025-11-26
**Version:** QuickMap v0.9.2
**Request:** Review functions called only once to identify unnecessary abstraction levels

## Summary

Analyzed 9 single-use functions in R/quickmap.R. **Recommendation: Keep all 9 functions as-is.** None should be inlined despite single use.

## Analysis by Function

### 1. `save_styled_map()` - Line 1040

**Called from:** `finalize_and_save_map()` (line 1023)

**Current code:**
```r
save_styled_map(
  map, html_file, title, styling_type, show_banner,
  banner_colour, colour_scale, !interactive, !interactive,
  image_dimensions, autoplay, play_speed, data_max, years
)
```

**Function does:**
- Saves leaflet widget to HTML file (5 lines)
- Conditionally applies custom layout with error handling (20 lines)
- Cleans up temporary _files folders (4 lines)

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Clear logical unit: "save and style a map"
- Complex error handling with tryCatch block
- 29 lines of code - too large to inline
- Inlining would make `finalize_and_save_map()` harder to read
- Well-named function that's self-documenting

---

### 2. `build_static_map_for_year()` - Line 1003

**Called from:** Loop in `create_pollution_map()` (line 2070)

**Current code:**
```r
static_map <- build_static_map_for_year(
  static_map_template, yr, measurement_layers,
  pollutant, colour_scale, spatial_data, marker_scale_factor
)
```

**Function does:**
```r
template |>
  generate_map_layers(measurement_layers, year, pollutant,
                     colour_scale, spatial_data, scale_factor) |>
  generate_map_layers(measurement_layers, "static_only", pollutant,
                     colour_scale, spatial_data, scale_factor)
```

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Encapsulates two-step process: temporal layer + static overlay
- Pipeline is clear and readable as named function
- Only 6 lines, but represents a complete logical concept
- Function name documents the intent: "build map for this year"
- Used in loop context - function makes loop body cleaner

---

### 3. `parse_export_params()` - Line 1796

**Called from:** `create_pollution_map()` (line 2014)

**Current code:**
```r
c(image_export, map_width_px, map_height_px) %<-% parse_export_params(export_image)
```

**Function does:**
- Handles 3 input cases: NULL, TRUE, or numeric vector
- Returns standardized list with enabled/width/height
- 8 lines with clear structure

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Parameter normalization pattern - common R idiom
- Input validation and default handling
- Self-documenting: function name says "parse these parameters"
- Would clutter main function with conditional logic
- Testable in isolation

---

### 4. `apply_custom_layout_in_html()` - Line 1203

**Called from:** `save_styled_map()` (line 1054)

**Current code:**
```r
apply_custom_layout_in_html(
  html_file = html_file,
  title = if (show_banner) title else NULL,
  banner_colour = banner_colour,
  scale_name = colour_scale,
  collapsed_mobile = collapsed_mobile,
  image_mode = image_mode,
  image_dimensions = image_dimensions,
  autoplay = autoplay,
  play_speed = play_speed,
  data_max = data_max,
  years = years
)
```

**Function does:**
- Reads HTML file (4 lines)
- Loads banner/legend CSS (4 lines)
- Handles image mode dimensions (20 lines)
- Injects banner HTML (8 lines)
- Conditionally adds year control (10 lines)
- Generates and injects legend (3 lines)
- Writes modified HTML (2 lines)
- **Total: ~106 lines**

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- MASSIVE function - 106 lines
- Complex HTML post-processing with multiple steps
- Well-documented with roxygen2
- Clear separation of concerns: "modify saved HTML"
- Would bloat caller enormously if inlined

---

### 5. `load_roller_menu_control()` - Line 1081

**Called from:** `apply_custom_layout_in_html()` (line 1291)

**Current code:**
```r
roller_menu_html <- load_roller_menu_control(
  banner_colour,
  autoplay,
  play_speed,
  image_mode,
  years
)
```

**Function does:**
- Loads 3 template files (HTML/CSS/JS) from inst/controls/
- Handles image mode modifications (removes play button, arrow)
- Applies color theming with 16 sprintf parameters
- Injects config JavaScript
- Combines into single HTML block
- **Total: ~90 lines**

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Large complex function (90 lines)
- Template loading + color theming + mode handling
- Self-contained logical unit: "load roller menu control"
- Separation allows testing in isolation
- Would make caller unreadable if inlined

---

### 6. `load_layer_cache_js()` - Line 1174

**Called from:** `apply_custom_layout_in_html()` (line 1686)

**Current code:**
```r
controls_dir <- get_package_dir("controls")
js_file <- file.path(controls_dir, "layer-cache.js")
return(read_template_file(js_file))
```

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Named abstraction over file loading
- Parallel structure with other `load_*` functions
- Function name documents what file is loaded
- 5 lines - trivial, but clear
- Consistency with codebase patterns

---

### 7. `load_banner_css()` - Line 961

**Called from:** `apply_custom_layout_in_html()` (line 1225)

**Current code:**
```r
banner_css <- load_banner_css(banner_colour, image_mode)
```

**Function does:**
- Loads CSS template from inst/banner/
- Handles mobile CSS conditionally
- Applies color replacements
- Returns styled CSS block
- **Total: 15 lines**

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Template loading pattern
- Conditional logic (image mode vs interactive)
- Parallel structure with `load_legend_css()`
- Function name clearly documents purpose
- Consistent with other loader functions

---

### 8. `load_legend_css()` - Line 979

**Called from:** `apply_custom_layout_in_html()` (line 1227)

**Current code:**
```r
legend_css <- load_legend_css(banner_colour, image_mode)
```

**Function does:**
- Loads CSS template from inst/legend/
- Calculates derived colors (lighten_color)
- Conditionally loads mobile CSS
- Applies template replacements
- Returns styled CSS block
- **Total: 21 lines**

**Recommendation: KEEP SEPARATE**

**Reasoning:**
- Template loading with color calculations
- Conditional mobile CSS handling
- Parallel structure with `load_banner_css()`
- Clear separation: banner CSS vs legend CSS
- Color derivation logic (lighten_color calls)

---

### 9. `finalize_and_save_map()` - Line 1013

**Called from:**
- Line 2078: Static image export in loop
- Line 2090: Final interactive HTML map

**Status: Called TWICE - not single-use**

**Function does:**
- Adds map controls (boundaries, vignette, zoom)
- Saves and styles the map
- Optionally creates JPG screenshot
- Returns map object

**Note:** This function was initially listed as single-use but is actually called twice in different contexts (static export loop + final interactive map).

---

## Function Call Summary

| Function | Lines | Called From | Complexity | Keep? |
|----------|-------|-------------|------------|-------|
| `save_styled_map()` | 29 | `finalize_and_save_map()` | Medium | ✓ |
| `build_static_map_for_year()` | 6 | `create_pollution_map()` loop | Low | ✓ |
| `parse_export_params()` | 8 | `create_pollution_map()` | Low | ✓ |
| `apply_custom_layout_in_html()` | 106 | `save_styled_map()` | High | ✓ |
| `load_roller_menu_control()` | 90 | `apply_custom_layout_in_html()` | High | ✓ |
| `load_layer_cache_js()` | 5 | `apply_custom_layout_in_html()` | Trivial | ✓ |
| `load_banner_css()` | 15 | `apply_custom_layout_in_html()` | Low | ✓ |
| `load_legend_css()` | 21 | `apply_custom_layout_in_html()` | Medium | ✓ |

**Total lines in single-use functions: ~280 lines**

---

## Overall Recommendation

**KEEP ALL FUNCTIONS SEPARATE**

### Why not inline?

1. **Code size**: Many functions are 15-100+ lines - inlining would create unreadable monster functions

2. **Logical cohesion**: Each function represents a clear conceptual unit:
   - `save_styled_map()` → "save and style"
   - `build_static_map_for_year()` → "build year map"
   - `parse_export_params()` → "normalize parameters"
   - `apply_custom_layout_in_html()` → "post-process HTML"
   - `load_*_css()` → "load and style CSS"
   - `load_roller_menu_control()` → "load year control"

3. **Testability**: Separate functions can be tested in isolation

4. **Readability**: Function names document intent better than inline comments

5. **Error handling**: Functions encapsulate tryCatch blocks cleanly

6. **Template loading pattern**: The `load_*` functions follow a consistent pattern that would be lost if inlined

7. **Maintainability**: Changes to banner/legend/control loading are localized

### User's specific concern: `save_styled_map()`

User noted: "seems like an unneeded level of abstraction - the code could be in line and do exactly the same thing, with just a single in-line explanatory comment."

**Counterargument:**
- Function is 29 lines with error handling
- Encapsulates: save → style → cleanup
- Has clear input/output contract
- Called from `finalize_and_save_map()` which is already 25 lines
- Inlining would create 50+ line function with nested error handling
- Function name is more informative than comment

### Alternative: Keep all, but consider future extractions

If anything, the code could benefit from MORE extraction rather than less:
- `apply_custom_layout_in_html()` at 106 lines could be broken into smaller pieces
- CSS/JS loading pattern could be formalized into a loader framework

---

## Conclusion

**All 9 single-use functions provide value through:**
- Clear naming and intent
- Logical separation of concerns
- Consistent patterns (template loaders)
- Reduced complexity in callers
- Improved testability

**Recommendation: No changes needed.** The current abstraction levels are appropriate for a production R package.

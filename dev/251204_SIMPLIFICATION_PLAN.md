# Code Simplification Plan

- Present each simplification to the user with the code in context
- Request approval then Execute each change that is agreed
- At each replacement, add a very concise inline comment explaining the command, e.g. 
- Present the next simplification to the user, and repeat until the end.

## 1. Single-Use Wrapper Functions (-60 lines)

### `get_package_dir()` (lines 39-43) - 5 lines
Called 4 times, just wraps `system.file()` with fallback
```r
# Replace:
dir <- get_package_dir("controls")
# With:
dir <- system.file("controls", package = "quickmap")
if (dir == "") dir <- file.path("inst", "controls")
```
**Savings:** -5 lines (function def) + inline 2 lines each call = net -1 line

### `read_template_file()` (lines 45-47) - 3 lines
Called 3 times, just wraps `readLines()` + `paste()`
```r
# Inline it:
html_content <- paste(readLines(html_file, warn = FALSE), collapse = "\n")
```
**Savings:** -3 lines

### `parse_export_params()` (lines 1968-1983) - 16 lines
Called once, just validates export_image parameter
```r
# Inline directly in create_pollution_map() where used
```
**Savings:** -16 lines

### `load_rdata_file()` (lines 429-441) - 13 lines
Called once from load_data_file(), could inline
```r
# Merge into load_data_file() as the "rdata" case
```
**Savings:** -13 lines

### `apply_template_replacements()` (lines 49-56) - 8 lines
Just loops gsub(), called 3 times
```r
# Replace:
result <- apply_template_replacements(template, list(key = val))
# With:
result <- gsub("{{key}}", val, template, fixed = TRUE)
```
**Savings:** -8 lines

**Total: -45 lines**

## 2. Over-Abstracted Helper Functions (-80 lines)

### `get_symbol_for_index()` (lines 911-946) - 36 lines
Complex logic to map data source index to symbol
Now obsolete with type-aware defaults (v0.9.3)
Only used in legend generation for backward compat
```r
# Remove entirely, use layer_config$icon_shape directly
```
**Savings:** -36 lines

### `get_layer_year_data()` (lines 1751-1771) - 21 lines
Just filters spatial_data by layer_id and year
```r
# Replace:
layer_data <- get_layer_year_data(layer_id, year, spatial_data)
# With:
layer_data <- spatial_data$all_data[[layer_id]] |>
  filter(year_str == year)
```
**Savings:** -21 lines

### `prepare_generic_layer_data()` (lines 1618-1638) - 21 lines
Only calls generate_marker_labels(), wraps nothing else
```r
# Inline generate_marker_labels() call at usage site
```
**Savings:** -21 lines

**Total: -78 lines**

## 3. Redundant Conditional Logic (-40 lines)

### Double NULL checks in theme loading (lines 2223-2235)
```r
# Current:
title %||% theme$banner$title
# Multiple lines like this checking same thing

# Simplify: theme already has defaults from get_default_theme()
# Just use theme values directly
```
**Savings:** -12 lines

### `show_banner` derived from styling_type (line 2219)
```r
# Remove show_banner variable entirely
# Use styling_type == "html" directly (2 occurrences)
```
**Savings:** -3 lines

### Legacy data source compatibility (lines 2210-2216)
```r
# Convert old API params to data_sources
# If users still using old API after v1.0, that's their problem
# Remove diffusion_tube_file, sensor_file, school_file parameters
```
**Savings:** -25 lines (parameter handling + backward compat logic)

**Total: -40 lines**

## 4. Verbose Color/Theme Functions (-50 lines)

### `lighten_color()` (lines 1084-1104) - 21 lines
Could use colorspace package or inline HSL adjustment
```r
# Replace with one-liner using colorspace::lighten()
# Or remove if only used for banner/legend backgrounds (minor feature)
```
**Savings:** -21 lines

### `get_contrast_text_color()` (lines 1106-1124) - 19 lines
Calculates if text should be black or white on background
Only used once for legend
```r
# Simplify to: luminance > 0.5 ? "black" : "white"
```
**Savings:** -10 lines (simplified version)

### `convert_colors_to_hex()` (lines 863-895) - 33 lines
Converts R color names to hex
Called once, has tryCatch wrapper for fallback
```r
# Use grDevices::col2rgb() directly where needed
# Remove fallback - if color invalid, should fail
```
**Savings:** -20 lines (remove function, inline at call site)

**Total: -51 lines**

## 5. Overly Generic Abstraction (-30 lines)

### `load_data_file()` switch statement (lines 413-426)
Just dispatches to import_csv_data() or load_rdata_file()
```r
# Replace:
load_data_file(file, "csv", cols)
# With:
if (grepl("\\.Rdata$", file, ignore.case = TRUE)) {
  load_rdata_file(file, pollutant)
} else {
  import_csv_data(file, cols)
}
```
**Savings:** -14 lines

### `add_year_and_static_layers()` (lines 1165-1177) - 13 lines
Just wraps two gsub() calls
```r
# Inline at call site
```
**Savings:** -13 lines

**Total: -27 lines**

## 6. Unused/Debug Functions (-15 lines)

### `clear_openair_metadata_cache()` (lines 148-160) - 13 lines
Exported but never used in codebase
Only useful for debugging
```r
# Keep but mark as internal with @keywords internal
# Or remove if not in public API
```
**Savings:** 0 lines (keep for utility)

### `show_borough_colours()` (lines 641-694) - 54 lines
Helper to display available color palettes
Useful for users, keep

**Total: 0 lines (keep utilities)**

## Summary

| Category | Lines Removed |
|----------|---------------|
| Single-use wrappers | -45 |
| Over-abstracted helpers | -78 |
| Redundant conditionals | -40 |
| Verbose color functions | -51 |
| Generic abstraction | -27 |
| Unused functions | 0 |
| **Total** | **-241 lines** |

**Result:** 2278 → ~2037 lines (10.6% reduction)

## Implementation Priority

### High Priority (Easy wins)
1. Remove single-use wrappers (-45 lines, low risk)
2. Remove legacy parameter compatibility (-25 lines, breaking change but justified)
3. Inline prepare_generic_layer_data (-21 lines, straightforward)

**Quick savings: -91 lines**

### Medium Priority (Some refactoring)
4. Simplify color functions (-51 lines)
5. Remove get_symbol_for_index() (-36 lines)
6. Inline get_layer_year_data() (-21 lines)

**Additional: -108 lines**

### Low Priority (Code quality)
7. Simplify conditionals (-40 lines)
8. Remove generic abstractions (-27 lines)

**Remaining: -67 lines**

## Risk Assessment

**Low Risk:**
- Single-use wrappers (just inline the code)
- Unused functions (no callers)

**Medium Risk:**
- Over-abstracted helpers (need to verify all call sites)
- Legacy parameters (breaking change, but v0.9.3 already did this)

**High Risk:**
- Color functions (if users depend on these)
- Theme logic (lots of interconnected code)

## Testing Strategy

After each simplification:
1. Run existing test suite
2. Generate test maps (symbols, colors, themes)
3. Check HTML output structure
4. Verify image export still works

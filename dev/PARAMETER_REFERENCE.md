# create_pollution_map() Parameter Reference

## Parameter Definitions and Usage

### Data Source Parameters

#### `diffusion_tube_file`

-   **Type:** String
-   **Default:** `"none"`
-   **Accepted Values:**
    -   `"none"` - No diffusion tube data
    -   Path to CSV file with Easting/Northing columns
-   **Usage:** Line 2227 - Converted to `data_sources[1]` for backward compatibility
-   **Deprecated:** Use `data_sources` instead

#### `sensor_file`

-   **Type:** String
-   **Default:** `"none"`
-   **Accepted Values:**
    -   `"none"` - No sensor data
    -   Path to RData file with `dataOAformat` object
-   **Usage:** Line 2228 - Converted to `data_sources[2]` for backward compatibility
-   **Deprecated:** Use `data_sources` instead

#### `school_file`

-   **Type:** String
-   **Default:** `"none"`
-   **Accepted Values:**
    -   `"none"` - No school data
    -   Path to CSV file with Easting/Northing/Level columns
-   **Usage:** Line 2229 - Converted to `data_sources[3]` for backward compatibility
-   **Deprecated:** Use `data_sources` instead

#### `data_sources`

-   **Type:** List
-   **Default:** `NULL`
-   **Accepted Values:**
    -   List of file paths (CSV or RData)
    -   List of sf objects
    -   Mixed list
-   **Usage:**
    -   Line 2225-2230: Built from legacy parameters if NULL
    -   Line 2256: Passed to `load_spatial_data_sources()`
-   **Example:** `list("dt.csv", "sensors.Rdata", "schools.csv")`

#### `data_ids`

-   **Type:** Character vector
-   **Default:** `NULL` (auto-generated from filenames)
-   **Accepted Values:**
    -   Character vector matching length of `data_sources`
    -   Auto-generated: `tools::file_path_sans_ext(basename(file))`
-   **Usage:**
    -   Line 2256: Passed to `load_spatial_data_sources()`
    -   load_spatial_data_sources:2028-2036: Auto-generation logic
-   **Example:** `c("laqn", "aurn", "schools")`

#### `data_symbols`

-   **Type:** Character vector
-   **Default:** `NULL` (auto-cycle by type)
-   **Accepted Values:**
    -   Valid shape names: circle, rect, square, triangle, diamond, stadium, down-triangle, solid-circle-sm, solid-circle-md, simple-plus, simple-cross, cross-rect, simple-star, plus-circle, plus-rect, cross-circle, cross, star, plus
    -   Vector matching length of `data_sources`
-   **Usage:**
    -   Line 2273: Passed to `get_measurement_layers()`
    -   get_measurement_layers:1644-1652: Symbol assignment logic
    -   Auto-cycles solid symbols for temporal, non-solid for static
-   **Example:** `c("circle", "triangle", "simple-plus")`

#### `data_dynamic`

-   **Type:** Logical vector
-   **Default:** `NULL` (auto-detect from columns)
-   **Accepted Values:**
    -   Logical vector (TRUE/FALSE) matching length of `data_sources`
    -   Auto-detected: TRUE if year columns or pollutant columns present
-   **Usage:**
    -   Line 2256: Passed to `load_spatial_data_sources()`
    -   load_spatial_data_sources:2059-2064: Auto-detection logic
-   **Example:** `c(TRUE, TRUE, FALSE)` \# DT, sensors temporal; schools static

### Output Parameters

#### `output_file`

-   **Type:** String
-   **Default:** `"pollution_map.html"`
-   **Accepted Values:** Any valid filename (extension optional)
-   **Usage:**
    -   Line 2289-2326: Passed to `generate_map_layers()` and `finalize_and_save_map()`
    -   Prepended with "aq_maps/" directory
-   **Example:** `"merton_no2_2024.html"`

#### `export_image`

-   **Type:** NULL, logical, or numeric vector
-   **Default:** `NULL`
-   **Accepted Values:**
    -   `NULL` or `FALSE` - No image export
    -   `TRUE` - Export at 1920x1080
    -   `c(width, height)` - Custom dimensions
-   **Usage:**
    -   Line 2232: Parsed by `parse_export_params()`
    -   Line 2266-2268: Creates static map template
    -   Line 2278-2281: Calculates marker scale factor
    -   finalize_and_save_map:1230-1256: webshot2 export
-   **Example:** `c(2400, 2400)` \# 2400x2400px image

### Geographic Parameters

#### `boroughs`

-   **Type:** Character vector
-   **Default:** No default (required)
-   **Accepted Values:**
    -   London borough names (e.g., "Wandsworth", "Merton")
    -   `"all"` - All London boroughs
    -   Multiple boroughs: `c("Wandsworth", "Merton")`
-   **Usage:**
    -   Line 2247-2253: Passed to `get_boundary_sf()`
    -   get_boundary_sf:563-601: Loads sf data from ukboundaries package
-   **Example:** `c("Wandsworth", "Merton", "Richmond upon Thames")`

#### `vignette`

-   **Type:** Logical
-   **Default:** `NULL` (from theme, defaults to FALSE)
-   **Accepted Values:** `TRUE`, `FALSE`
-   **Usage:**
    -   Line 2238: Theme override
    -   Line 2259: Passed to `determine_years_and_viewport()`
    -   determine_years_and_viewport:2101: Creates darkened overlay outside borough boundaries
-   **Example:** `TRUE` \# Darken areas outside boroughs

### Data Selection Parameters

#### `pollutant`

-   **Type:** String
-   **Default:** `"no2"`
-   **Accepted Values:**
    -   `"no2"` - Nitrogen Dioxide
    -   `"pm25"` - PM2.5
    -   `"pm10"` - PM10
    -   `"o3"` - Ozone
-   **Usage:**
    -   Line 2256: Passed to `load_spatial_data_sources()` for RData loading
    -   Line 2276: Passed to `get_data_maximum()`
    -   Line 2289+: Passed through layer generation pipeline
    -   prepare_generic_layer_data:1671: NULL for static layers
    -   create_generic_icons:1591-1592: Used for color scale lookup
-   **Example:** `"pm25"`

#### `years`

-   **Type:** Numeric vector or NULL
-   **Default:** `NULL` (all available years)
-   **Accepted Values:**
    -   `NULL` - Use all years in data
    -   Single year: `2024`
    -   Multiple years: `c(2022, 2023, 2024)`
    -   Range: `2020:2024`
-   **Usage:**
    -   Line 2259: Passed to `determine_years_and_viewport()`
    -   determine_years_and_viewport:2106-2122: Filters to available years
    -   Line 2289: Passed to `generate_map_layers()` for year loop
-   **Example:** `2022:2024`

#### `colour_scale`

-   **Type:** String
-   **Default:** `"who_no2"`
-   **Accepted Values:**
    -   WHO-based: `"who_no2"`, `"stripes_no2"`, `"gla_pm25"`
    -   Borough-specific: `"lbw_no2"`, `"lbrut_no2"`, `"lbm_no2"`
    -   Special: `"deltas"` (year-on-year change), `"schools"` (categorical)
-   **Usage:**
    -   Line 2260: Passed to `get_colour_legend()`
    -   Line 2289+: Passed through to `assign_colour()` in icon generation
    -   assign_colour:864-877: Maps values to colors via scale thresholds
-   **Example:** `"lbw_no2"`

### UI/Display Parameters

#### `title`

-   **Type:** String
-   **Default:** `NULL` (from theme, or auto-generated)
-   **Accepted Values:** Any string
-   **Usage:**
    -   Line 2237: Theme override
    -   Line 2304-2305: Passed to `save_html_and_style()`
    -   inject_banner_legend_controls:1413: Injected into banner HTML
-   **Example:** `"Merton NO2 Levels 2022-2024"`

#### `styling_type`

-   **Type:** String
-   **Default:** `"html"`
-   **Accepted Values:**
    -   `"html"` - Full styling with banner/legend/controls
    -   `"minimal"` - Basic map only
-   **Usage:**
    -   Line 2233: Determines `show_banner`
    -   Line 2304: Passed to `save_html_and_style()`
    -   save_html_and_style:1230-1266: Controls UI injection
-   **Example:** `"minimal"` \# No banner/legend

#### `marker_labels`

-   **Type:** Logical or string
-   **Default:** `NULL` (from theme, defaults to FALSE)
-   **Accepted Values:**
    -   `FALSE` - No labels
    -   `TRUE` - Show labels on hover
    -   `"values_on"` - Always show pollutant values
    -   `"labels_on"` - Always show site IDs
    -   `"all_on"` - Always show both
-   **Usage:**
    -   Line 2241: Theme override
    -   Line 2272: Passed to `get_measurement_layers()`
    -   Line 2289+: Passed through layer pipeline
    -   add_layer:1710: Controls labelOptions(noHide)
    -   generate_marker_labels:1752-1794: Label text generation
-   **Example:** `"values_on"` \# Always-visible values

#### `banner_colour`

-   **Type:** String (hex color)
-   **Default:** `NULL` (from theme, defaults to "#2c3e50")
-   **Accepted Values:** Any valid CSS hex color
-   **Usage:**
    -   Line 2239: Theme override
    -   Line 2304: Passed to `save_html_and_style()`
    -   build_banner_css:1149-1165: Banner background color
    -   load_roller_menu_control:1271-1362: Year control theming
-   **Example:** `"#5F3E94"` \# Merton purple

#### `boundary_labels`

-   **Type:** Logical
-   **Default:** `NULL` (from theme, defaults to FALSE)
-   **Accepted Values:** `TRUE`, `FALSE`
-   **Usage:**
    -   Line 2240: Theme override
    -   Line 2289: Passed to `generate_map_layers()`
    -   generate_map_layers:1976-1987: Labels on borough polygons
-   **Example:** `TRUE` \# Show borough names

### Animation Parameters

#### `autoplay`

-   **Type:** Logical
-   **Default:** `NULL` (from theme, defaults to FALSE)
-   **Accepted Values:** `TRUE`, `FALSE`
-   **Usage:**
    -   Line 2242: Theme override
    -   Line 2304: Passed to `save_html_and_style()`
    -   load_roller_menu_control:1310-1312: Sets initial play state
-   **Example:** `TRUE` \# Auto-start animation

#### `play_speed`

-   **Type:** Numeric (milliseconds)
-   **Default:** `NULL` (from theme, defaults to 500)
-   **Accepted Values:** 50-5000 (clamped by JS validation)
-   **Usage:**
    -   Line 2243: Theme override
    -   Line 2304: Passed to `save_html_and_style()`
    -   load_roller_menu_control:1313-1315: Animation interval
-   **Example:** `1000` \# 1 second per year

### Theme Parameter

#### `theme_file`

-   **Type:** String (file path)
-   **Default:** `NULL` (use defaults)
-   **Accepted Values:**
    -   Path to YAML theme file in `inst/themes/`
    -   `NULL` - Use default theme
-   **Usage:**
    -   Line 2234: Passed to `load_theme()`
    -   load_theme:814-851: Loads YAML config with fallback to defaults
    -   Line 2237-2244: Theme values override explicit parameters
-   **Example:** `"inst/themes/merton_purple.yaml"`

## Parameter Override Hierarchy

Parameters follow this precedence (highest to lowest): 1. Explicit function parameter (non-NULL) 2. Theme file value 3. Default value

Example:

``` r
create_pollution_map(
  boroughs = "Merton",
  theme_file = "inst/themes/merton_purple.yaml",  # Sets banner_colour = "#5F3E94"
  banner_colour = "#FF0000"  # Overrides theme
)
# Result: banner_colour = "#FF0000" (explicit param wins)
```

## Code Trace Examples

### Example 1: Data Source Flow

```         
data_sources = list("dt.csv", "sensors.Rdata")
  ↓ (Line 2256)
load_spatial_data_sources(data_sources, data_ids=NULL, ...)
  ↓ (Lines 2028-2036)
data_ids auto-generated: c("dt", "sensors")
  ↓ (Lines 2039-2073)
CSV loaded → get_temporal_data() → transform_to_wgs84()
RData loaded → load_rdata_file() → process_oa_data()
  ↓ (Line 2083)
Returns: list(all_data = list(dt=..., sensors=...), ids=c("dt","sensors"))
```

### Example 2: Symbol Assignment Flow

```         
data_sources = list("laqn.Rdata", "aurn.Rdata", "schools.csv")
data_symbols = NULL  # Auto-assign
  ↓ (Line 2256)
load_spatial_data_sources() detects:
  - laqn.Rdata: temporal (has year_str after processing)
  - aurn.Rdata: temporal (has year_str)
  - schools.csv: static (no year columns, no year_str)
  ↓ (Line 2270)
get_measurement_layers(spatial_data, marker_labels, data_symbols=NULL)
  ↓ (Lines 1640-1652)
Symbol assignment:
  - laqn: is_static=FALSE → circle (solid, dynamic_counter=1)
  - aurn: is_static=FALSE → rect (solid, dynamic_counter=2)
  - schools: is_static=TRUE → simple-plus (non-solid, static_counter=1)
```

### Example 3: Color Assignment Flow

```         
pollutant = "no2"
colour_scale = "who_no2"
data: schools.csv with Level column (Primary/Secondary)
  ↓ (Line 2260)
get_colour_legend("who_no2") loads thresholds/colors
  ↓ (Line 2289+)
generate_map_layers() loops through years
  ↓ (add_layer)
Static layer detected (layer_config$static = TRUE)
  ↓ (Line 1699)
use_pollutant = NULL  # Override for static layers
  ↓ (Line 1701-1707)
create_generic_icons(data, pollutant=NULL, ...)
  ↓ (Lines 1587-1595)
has_level = TRUE, pollutant = NULL
  → Categorical colors: colorFactor(c("#1E90FF", "#32CD32"))
  ↓ (Lines 1597-1610)
Non-solid symbol (simple-plus):
  color = categorical colors (stroke visible)
  fillColor = categorical colors (not visible)
```

## Validation Rules

### Required Parameters

-   `boroughs` - Must be provided, no default

### Parameter Combinations

-   If `data_sources` is NULL, at least one of `diffusion_tube_file`, `sensor_file`, or `school_file` must not be "none"
-   `data_ids`, `data_symbols`, `data_dynamic` must match length of `data_sources` if provided
-   `export_image` as vector must be length 2: `c(width, height)`

### Validation Points

-   Line 2247-2253: Borough validation (get_boundary_sf returns NULL on error)
-   load_colour_scale:712-732: Scale name validation
-   validate_and_fix_icon_shape:1502-1527: Symbol name validation
-   parse_export_params:2018-2026: Image dimensions validation
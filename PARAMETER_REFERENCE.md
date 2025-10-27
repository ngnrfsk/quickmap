# Parameter Reference for `create_pollution_map()`

This document describes each parameter in the `create_pollution_map()` function based on tracing their actual usage throughout the code.

## Data Input Parameters

### `csv_data_file`
**Type:** Character string
**Default:** `"none"`
**Usage:**
- Lines 2197-2204: Loads diffusion tube (DT) data from CSV file
- If not "none", calls `load_data_file()` which reads CSV with Easting/Northing columns and year columns
- Lines 2238-2240: Falls back to OA data if CSV data unavailable
- Line 2261: If "none", uses BL data for map initialization
- Lines 2265, 2308: Used to determine if DT sites layer should be enabled
- **Purpose:** Provides annual NO2 measurements from diffusion tube monitoring sites

### `oa_data_file`
**Type:** Character string
**Default:** `"none"`
**Usage:**
- Lines 2226-2235: Loads Breathe London sensor data from RData file
- Must contain `dataOAformat` object with columns: siteCode, year, pollutant, lat, lon
- Lines 2246-2249: If vignette overlay is on, filters points inside borough boundary for performance
- Lines 2309: Used to determine if bl_nodes layer should be enabled
- **Purpose:** Provides continuous air quality sensor data from Breathe London network

### `school_file`
**Type:** Character string
**Default:** `"none"`
**Usage:**
- Lines 2208-2222: Loads school locations from CSV file
- Must contain: Easting, Northing, Level (Primary/Secondary), School (name)
- Line 2310: Used to determine if schools layer should be enabled
- **Purpose:** Provides school locations as overlay markers on the map

## Output Parameters

### `output_file`
**Type:** Character string
**Default:** `"pollution_map.html"`
**Usage:**
- Line 2376: Extracts base filename for static image exports (adds year suffix)
- Lines 2431-2432: Used as the HTML file path in `aq_maps/` directory
- **Purpose:** Base name for output files (HTML and JPG)

### `image_export`
**Type:** Logical
**Default:** `FALSE`
**Usage:**
- Line 2293: Determines if static map template should be created
- Lines 2328-2411: Entire block that generates static JPG images per year
- When TRUE: Creates separate HTML files per year, applies layout, exports JPG via webshot2
- **Purpose:** Enables generation of static JPG images alongside interactive HTML map

### `map_width_px`
**Type:** Numeric
**Default:** `1920`
**Usage:**
- Line 2331: Used in scale factor calculation: `sqrt((width × height) / (1200 × 1200))`
- Line 2397: Passed as image width to `apply_custom_layout_in_html()`
- Line 2408: Used as `vwidth` parameter for webshot2 screenshot
- **Purpose:** Width in pixels for static image exports (affects marker scaling)

### `map_height_px`
**Type:** Numeric
**Default:** `1080`
**Usage:**
- Line 2331: Used in scale factor calculation with width
- Line 2397: Passed as image height to `apply_custom_layout_in_html()`
- Line 2409: Used as `vheight` parameter for webshot2 screenshot
- **Purpose:** Height in pixels for static image exports (affects marker scaling)

### `html_page_title`
**Type:** Character string
**Default:** `"Air pollution map"`
**Usage:**
- Lines 2384, 2439: Passed to `saveWidget()` as the HTML `<title>` tag
- **Purpose:** Sets the browser tab title for the HTML output

## Location & Data Parameters

### `boroughs`
**Type:** Character vector
**Required:** Yes
**Usage:**
- Line 2184: Passed to `get_boundary_sf()` to load boundary polygons
- Used for: boundary display, data filtering, map bounds
- **Purpose:** Specifies which borough(s) to display (affects zoom and filtering)

### `pollutant`
**Type:** Character string
**Default:** `"no2"`
**Usage:**
- Used throughout for data extraction and coloring:
  - Line 2230: Loads OA data with specific pollutant column
  - Lines 1290, 1418-1420: Colors DT and BL markers based on pollutant values
  - Lines 1900, 1907: Filters temporal data for specific pollutant
  - Lines 1657-1666: Generates labels showing pollutant values
- **Purpose:** Selects which pollutant to display ("no2" or "pm25")

### `years_to_plot`
**Type:** Character vector or NULL
**Default:** `NULL`
**Usage:**
- Lines 2266-2278: Determines which years to process
  - If NULL and no temporal data: set to "static_only"
  - If NULL with data: uses all available years
  - If specified: intersects with available years
- Lines 2315-2426: Loops through each year to build HTML map
- Line 2426: Passed to `add_map_controls()` for layer groups
- **Purpose:** Controls which years are included in the map (creates year selector)

## Styling Parameters

### `vignette_overlay_on`
**Type:** Logical
**Default:** `TRUE`
**Usage:**
- Lines 2246-2249: Filters BL points inside borough boundary (performance optimization)
- Lines 2252-2253: Creates vignette overlay polygon if TRUE
- Lines 2366, 2421: Passed to `add_map_controls()` to conditionally add overlay
- **Purpose:** Adds grey semi-transparent overlay outside borough boundary for visual focus

### `scale_to_use`
**Type:** Character string
**Default:** `"who_no2"`
**Usage:**
- Line 2255: Generates legend info from color scale definition
- Lines 1290, 1294, 1420: Colors pollution markers based on thresholds
- Lines 2322, 2343, 2354: Passed to layer generation for marker coloring
- Lines 2394, 2449: Used by HTML legend generation
- Options: "who_no2", "stripes_no2", "gla_pm25", "lbw_no2", "lbrut_no2", "lbm_no2", "deltas"
- **Purpose:** Selects color scale for pollution value visualization

### `title_prefix`
**Type:** Character string
**Default:** `""`
**Usage:**
- Lines 2363, 2418: Passed to `add_map_controls()`
- Lines 1841-1844: Combined with year to create title text
  - Interactive maps: just shows prefix
  - Static maps: shows "prefix year"
- **Purpose:** Adds custom text before year in map title overlay

### `show_marker_labels`
**Type:** Boolean or character
**Default:** `FALSE`
**Options:** `FALSE`, `TRUE`, `"values_on"`, `"labels"`, `"labels_on"`
**Usage:**
- Lines 1362, 1370, 1378: Stored in each layer's options
- Lines 1601-1602: Determines label behavior (values vs custom labels, hover vs always-visible)
- Lines 1508, 1512: Controls `noHide` property in labelOptions
- Lines 1628-1666: Generate appropriate label text based on data and mode
- **Purpose:** Controls marker label visibility and content
  - FALSE: No labels
  - TRUE: Show values on hover (interactive only)
  - "values_on": Show values always visible
  - "labels": Show custom labels on hover
  - "labels_on": Show custom labels always visible

### `show_banner`
**Type:** Logical
**Default:** `FALSE`
**Usage:**
- Lines 2392, 2447: Conditionally passes `banner_text` to `apply_custom_layout_in_html()`
- If TRUE: Creates HTML banner above newspapers
- **Purpose:** Toggles display of custom banner with title above map

### `show_legend`
**Type:** Logical
**Default:** `FALSE`
**Usage:**
- Lines 1812-1838: Adds Leaflet legend control to interactive maps (if TRUE)
- Line 2369: Set to FALSE for static images (HTML legend used instead)
- Line 2424: Controls legend display for HTML maps
- **Purpose:** Toggles Leaflet's native legend control on interactive maps

### `show_title`
**Type:** Logical
**Default:** `FALSE`
**Usage:**
- Lines 1841-1845: Adds title overlay to map if TRUE and title_prefix non-empty
- Line 2368: Set to FALSE for static images (HTML banner used instead)
- Line 2423: Controls title display for HTML maps
- **Purpose:** Toggles display of title overlay on the map itself

### `banner_color`
**Type:** Character string (hex or color name)
**Default:** `borough_palettes$merton$purple`
**Usage:**
- Line 1218: Injected into CSS styling for HTML banner background
- Line 2393: For static images, actually uses `border_color` instead
- Line 2448: For HTML maps, uses `border_color` as banner color
- **Purpose:** Sets background color of HTML banner (above newspapers)
- **Note:** Despite being a parameter, it's effectively overridden by `border_color` in the implementation

### `border_color`
**Type:** Character string (hex or color name)
**Default:** `borough_palettes$merton$green`
**Usage:**
- Lines 2393, 2448: Used as both banner and border color in HTML layout
- **Purpose:** Sets color for banner background and any border styling
- **Note:** This actually controls the banner appearance despite separate banner_color parameter

### `border_width`
**Type:** Character string
**Default:** `"5px"`
**Usage:**
- Currently defined but **not actually used** in the code
- Referenced in commented-out code (lines 2480, 2508)
- **Purpose:** Was intended to set border width around map (currently unused)

### `show_boundary_labels`
**Type:** Logical
**Default:** `FALSE`
**Usage:**
- Lines 1720-1738: In `add_boundary_polygons()`, controls borough name labels
- If TRUE: Adds always-visible labels with "NAME" field on borough polygons
- Lines 2372, 2427: Passed to `add_map_controls()` for both static and HTML maps
- **Purpose:** Toggles display of borough/ward name labels on boundary polygons

### `banner_text`
**Type:** Character string
**Default:** `"Air Quality Map"`
**Usage:**
- Lines 2392, 2447: Conditionally passed to HTML layout function (if `show_banner` is TRUE)
- Lines 1228-1232: In `apply_custom_layout_in_html()`, creates banner div if not NULL
- **Purpose:** Text content displayed in HTML banner above map

## Usage Flow Summary

```
Data Loading Phase:
├─ csv_data_file → DT sites (circles)
├─ oa_data_file → BL nodes (diamonds)
└─ school_file → Schools (crosses)

Map Generation Phase:
├─ boroughs → Load boundaries, set bounds
├─ years_to_plot → Create year layers/groups
├─ pollutant → Filter and color markers
├─ scale_to_use → Color scheme for pollution values
└─ show_marker_labels → Label text and visibility

Styling Phase:
├─ vignette_overlay_on → Grey outside overlay
├─ show_boundary_labels → Borough name labels
├─ title_prefix → Map title text
├─ show_title → Toggle title overlay
└─ show_legend → Toggle Leaflet legend

HTML Layout Phase (show_banner, banner_text, border_color):
├─ show_banner → Enable/disable banner
├─ banner_text → Banner content
└─ border_color → Banner and border colors

Export Phase:
├─ output_file → Base filename
├─ image_export → Generate JPG files
├─ map_width_px → Image width (affects scaling)
├─ map_height_px → Image height (affects scaling)
└─ html_page_title → Browser tab title
```

## Important Notes

1. **Image Scaling:** Marker sizes scale with `map_width_px` × `map_height_px` using geometric mean
2. **Color Scales:** Each scale defines thresholds, colors, and labels for pollution ranges
3. **Layer Priority:** CSV data takes precedence over OA data if both provided
4. **Static Maps:** When `image_export=TRUE`, HTML legends are used instead of Leaflet controls
5. **Label Modes:** Schools always show school names; other layers show values or custom labels
6. **Unused Parameter:** `border_width` is defined but not implemented in current version


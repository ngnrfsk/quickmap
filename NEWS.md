# quickmap 0.9.0

## Breaking Changes

Major parameter refactoring following OpenAir design patterns.

### Parameter Reduction
- **21 → 14 parameters** (33% reduction)
- Clearer intent-based naming
- Merged related parameters into multi-value options

### Renamed Parameters (6)
- `years_to_plot` → `years`
- `vignette_overlay_on` → `vignette`
- `csv_data_file` → `diffusion_tube_file`
- `oa_data_file` → `sensor_file`
- `show_marker_labels` → `marker_labels`
- `show_boundary_labels` → `boundary_labels`

### Merged Parameters (7 → 3)

**Image Export (3 → 1):**
- OLD: `image_export = TRUE, map_width_px = 1920, map_height_px = 1080`
- NEW: `export_image = c(1920, 1080)` or `export_image = NULL`

**Title (2 → 1):**
- OLD: `html_page_title = "...", banner_text = "..."`
- NEW: `title = "..."` (used for both browser tab and banner)

**Styling (4 → 1):**
- OLD: `show_banner = TRUE, show_title = FALSE, show_legend = FALSE, title_prefix = ""`
- NEW: `styling_type = "html"` or `styling_type = "none"`

### Removed Features
- Leaflet legend controls (28 lines)
- Leaflet title controls (6 lines)
- Removed 58 lines total (2.3% code reduction)

### Migration
See `vignettes/MIGRATION_EXAMPLE_v0.9.0.md` for complete migration guide with examples.

---

# quickmap 0.8.11

## New Features
- Borough colour palettes restructured as nested named lists
- Added `show_borough_colours()` helper function
- Usage: `borough_palettes$merton$purple`

---

# quickmap 0.8.10

## Bug Fixes
- Fixed schools label behavior to respect `show_marker_labels` parameter
- Fixed OA data label fallback when Label column missing
- All data sources now have consistent label behavior

---

# quickmap 0.8.9

## New Features
- Added `show_marker_labels` parameter with 5-state control
- Unified label behavior across OA, CSV, and Schools data sources
- Added `generate_marker_labels()` helper function

## Breaking Changes
- **Removed** `use_data_labels` parameter
- OLD: `use_data_labels = TRUE`
- NEW: `show_marker_labels = TRUE` (or "values_on", "labels", "labels_on")

---

# quickmap 0.8.8

## New Features
- Added `show_boundary_labels` parameter (TRUE/FALSE)
- Modified `add_boundary_polygons()` for label visibility control

---

# quickmap 0.8.7.3

## Bug Fixes
- Fixed CSV file path handling to be consistent with RData files
- Added DATA_PATH environment variable support for relative CSV paths
- Reduced legend marker sizes relative to map markers
- Improved gaps and padding in legend layout

---

# quickmap 0.8.7.1

## Bug Fixes
- Fixed scaling problems where legend text and marker sizes didn't scale appropriately
- Improved scale factor calculation using geometric mean
- Added layout dimension scaling for padding, gaps, and legend height
- Implemented marker size scaling based on image dimensions
- All elements now scale consistently with image size
- Fixed legend symbol proportions (1.3:1 ratio)

---

# quickmap 0.8.7

## New Features
- Unified banner/legend system between HTML and static maps
- Extended `apply_custom_layout_in_html()` with `image_mode` parameter
- Single code path for both interactive and static outputs

---

# quickmap 0.8.6

## New Features
- External legend system (mobile responsive, collapsible)
- Enhanced banner system (customizable text, color, positioning)
- Flexbox layout for banner/map/legend components

---

# quickmap 0.8.5

## Improvements
- Code cleanup and simplification
- Simplified data loading
- Improved error handling
- Enhanced data validation

---

# quickmap 0.8.0

## Major Refactor
- Unified architecture with single-loop processing
- Generic layer system
- Single marker-based architecture (circles=DT, diamonds=BL, crosses=schools)
- Configuration-driven layer system
- Integrated image export

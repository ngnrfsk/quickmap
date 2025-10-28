# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**QuickMap** is an R project for generating interactive air quality maps showing pollution data (NO2, PM2.5) overlaid with school locations and borough boundaries. It creates both interactive Leaflet HTML maps and static JPG exports for local government air quality reporting.

### Current Version: 0.8.11
- **Production code**: `quickmap.R` (stable, 2,462 lines)
- **Archived versions**: `versions/quickmap_0_8_5.R` through `versions/quickmap_0_8_11.R` (15 versions)
- **Test scripts**: 14 test scripts in `tests/` directory
- **Utility scripts**: 6 scripts in `scripts/` directory

## Core Architecture

### Unified Layer Processing Pipeline
The codebase uses a single-loop architecture that processes all map layers through a unified pipeline:

```
Data Loading → Layer Configuration → Generic Processing → Icon Generation → Map Rendering
```

1. **Data Loading System** (`load_data_file()`)
   - Supports CSV files (diffusion tubes) and RData files (Breathe London sensors)
   - Handles coordinate transformation from British National Grid to WGS84
   - Unified error handling and validation

2. **Layer Configuration** (`get_measurement_layers()`)
   - Configuration-driven system defining which layers to render
   - Supports temporal layers (pollution data with years) and static layers (schools)
   - Each layer type has specific preparation functions

3. **Generic Icon System** (`create_generic_icons()`)
   - **Circles**: Diffusion tube sites (`dt_sites`)
   - **Diamonds**: Breathe London nodes (`bl_nodes`)
   - **Crosses**: Schools (`schools`)
   - Colors determined by pollution thresholds or categorical data

4. **Single Loop Processing** (`generate_map_layers()`)
   - One loop generates both interactive HTML and static image exports
   - Eliminates code duplication between output formats
   - Processes all years and layer types systematically

### Key Design Patterns
- **Configuration Objects**: All styling, colors, and layer definitions stored in config objects
- **Generic Layer Functions**: `prepare_generic_layer_data()` → `create_generic_icons()` → `add_layer()`
- **Temporal Support**: Year-based filtering with interactive controls for time series data
- **Environment Variables**: `DATA_PATH` and `SCRIPTS_PATH` for file locations

## Development Workflow

### Running the Code
```r
# Interactive development in R/RStudio
source("quickmap.R")

# Run example scripts
source("test_quickmap.R")
source("do_maps_with_v0.8.3_LBM_PM25.R")
```

### Creating Maps
```r
map_object <- create_pollution_map(
  csv_data_file = "path/to/diffusion_tubes.csv",
  oa_data_file = "path/to/breathe_london.Rdata",
  boroughs = c("Wandsworth", "Merton"),
  output_file = "map_output.html",
  image_export = TRUE,  # Also creates JPG files
  scale_to_use = "who_no2",
  show_banner = TRUE,
  banner_text = "Air Quality Dashboard"
)
```

### Environment Setup
Required environment variables:
```r
Sys.setenv(DATA_PATH = "path/to/data/files")
Sys.setenv(SCRIPTS_PATH = "path/to/scripts")
```

## Data Formats

### CSV Files (Diffusion Tubes)
- **Required columns**: `Easting`, `Northing`, year columns (`2017`, `2018`, etc.)
- **Optional**: `Label` for custom site names
- **Coordinate system**: British National Grid (EPSG:27700)

### RData Files (Breathe London)
- **Must contain**: `dataOAformat` object
- **Required columns**: `siteCode`, `year`, pollutant, `lat`, `lon`
- **Format**: OpenAir-compatible long format

### School Data
- **Required columns**: `Easting`, `Northing`, `Level` (Primary/Secondary), `School`

## Color Scale System

Pre-configured scales in `colour_scales` list:
- **WHO-based**: `who_no2`, `stripes_no2`, `gla_pm25`
- **Borough-specific**: `lbw_no2`, `lbrut_no2`, `lbm_no2`
- **Special**: `deltas` (year-on-year change), `schools` (categorical)

Each scale defines:
- `colours`: Color palette (R names or hex)
- `thresholds`: Breakpoints for continuous data
- `labels`: Legend text
- `title`: Scale description

## UI Enhancement System

### External Legend System
- **Mobile responsive**: Auto-collapses on screens <480px
- **Collapsible**: Click header to toggle visibility
- **Generated from color scales**: Uses existing `colour_scales` configuration
- **Post-processing**: Modifies saved HTML files with `apply_custom_layout()`

### Banner System
- **Customizable**: Text, color, positioning
- **Flexbox layout**: Banner/map/legend components
- **Mobile optimized**: Responsive font sizes and padding

## File Structure & Outputs

### Input Files
Scripts expect data files via environment variables or absolute paths.

### Output Directory
- **`aq_maps/`**: Auto-created output directory
- **HTML files**: Interactive maps with year controls
- **JPG files**: Static exports (when `image_export = TRUE`)
- **Cleanup**: Automatically removes temporary `_files` folders

## Dependencies

Core R packages (auto-installed):
- `leaflet`: Interactive mapping
- `sf`: Spatial data handling
- `dplyr`: Data manipulation
- `leaflegend`: Custom legend controls
- `webshot2`: Static image export
- `htmlwidgets`: Widget saving and manipulation

## Version History Context

- **v0.8.0**: Major refactor to unified architecture
- **v0.8.5**: Code cleanup and simplification
- **v0.8.6**: Enhanced UI with external legends and banners
- **v0.8.7-v0.8.7.3**: Unified banner/legend system with proportional scaling, missing data filtering
- **v0.8.8**: Boundary labels control (`show_boundary_labels` parameter)
- **v0.8.9**: Marker labels control (5-state `show_marker_labels` parameter, removed `use_data_labels`)
- **v0.8.10**: Fixed schools label behavior and OA data label fallback
- **v0.8.11**: Borough colour palettes (nested named lists) and `show_borough_colours()` helper

All archived versions are stored in `versions/` directory. Current stable version is always `quickmap.R`.
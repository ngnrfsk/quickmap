# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**QuickMap** is an R project for generating interactive air quality maps showing pollution data (NO2, PM2.5) overlaid with school locations and borough boundaries. It creates both interactive Leaflet HTML maps and static JPG exports for local government air quality reporting.

### Current Version: 0.9.4

-   **Production code**: `R/quickmap.R` (stable, ~2,200 lines)
-   **Archived versions**: `versions/quickmap_0_8_5.R` through `versions/quickmap_0_9_3.R`
-   **Test scripts**: Multiple test scripts in `tests/` directory, testthat files
-   **Utility scripts**: Scripts in `scripts/` directory

## Core Architecture

### Unified Layer Processing Pipeline

The codebase uses a single-loop architecture that processes all map layers through a unified pipeline:

```         
Data Loading → Layer Configuration → Generic Processing → Icon Generation → Map Rendering
```

1.  **Data Loading System** (`load_data_file()`)
    -   Supports CSV files (diffusion tubes) and RData files (Breathe London sensors)
    -   Handles coordinate transformation from British National Grid to WGS84
    -   Unified error handling and validation
2.  **Layer Configuration** (`get_measurement_layers()`)
    -   Configuration-driven system defining which layers to render
    -   Supports temporal layers (pollution data with years) and static layers (schools)
    -   Each layer type has specific preparation functions
3.  **Generic Icon System** (`create_generic_icons()`)
    -   **Circles**: Diffusion tube sites (`dt_sites`)
    -   **Diamonds**: Breathe London nodes (`bl_nodes`)
    -   **Crosses**: Schools (`schools`)
    -   Colors determined by pollution thresholds or categorical data
4.  **Single Loop Processing** (`generate_map_layers()`)
    -   One loop generates both interactive HTML and static image exports
    -   Eliminates code duplication between output formats
    -   Processes all years and layer types systematically

### Key Design Patterns

-   **Configuration Objects**: All styling, colors, and layer definitions stored in config objects
-   **Generic Layer Functions**: `prepare_generic_layer_data()` → `create_generic_icons()` → `add_layer()`
-   **Temporal Support**: Year-based filtering with interactive controls for time series data
-   **Environment Variables**: `DATA_PATH` and `SCRIPTS_PATH` for file locations

## Development Workflow

### Planning

-   Plans to be stored in the dev/ folder with filename following the format YYYYMMDD_project_name_plan_HHMM.md.

### Starting and ending execution of a new plan

**Starting**

-   Ask user to confirm the plan

-   check out a branch of the project for the plan

**Ending**

-   Ask user to finish testing code

-   Draft documentation

    -   **in outline** for this document and

    -   in **detail** for dev/PROJECT_STATUS.md

    -   then update both documents.

-   Ask user whether to commit source and documentation or not.

-   Commit or no, copy versions with a new version number to versions/ subfolder.

### Running the Code

``` r
# Interactive development in R/RStudio
source("R/quickmap.R")

# Run example scripts
source("tests/test_quickmap.R")
source("inst/examples/create_all_borough_maps.R")
```

### Creating Maps

Current API (v0.9.2+) uses `data_sources` list:

``` r
map_object <- create_pollution_map(
  data_sources = list(
    "wandsworth_2017_2024.csv",
    "bl_imperial_annualised_2021_2025.Rdata",
    "schools_wandsworth.csv"
  ),
  data_ids = NULL,  # Optional - auto-generates from filenames
  boroughs = "Wandsworth",
  pollutant = "no2",
  display_times = NULL,  # All available time periods (year/month/day/hour)
  colour_scale = "who_no2",
  output_file = "wandsworth_no2.html",
  title = "Wandsworth NO2 Annual Mean",
  styling_type = "html",
  export_image = TRUE,  # Also creates JPG files
  marker_labels = "labels",  # Show school names and custom labels
  vignette = TRUE
)
```

### Environment Setup

Required environment variables:

``` r
Sys.setenv(DATA_PATH = "~/Coding/Library/data")
Sys.setenv(SCRIPTS_PATH = "path/to/scripts")
```

**Note:** DATA_PATH points to `~/Coding/Library/data` where all test data files are stored.

## Data Formats

### CSV Files (Diffusion Tubes)

-   **Required columns**: `Easting`, `Northing`, year columns (`2017`, `2018`, etc.)
-   **Optional**: `Label` for custom site names
-   **Coordinate system**: British National Grid (EPSG:27700)

### RData Files (Breathe London)

-   **Duck typing**: Checks standard names (dataOAformat/data/oa_data/sensor_data), then any compatible data.frame
-   **Required columns**: `siteCode`, `year`, pollutant, `lat`, `lon`
-   **Format**: OpenAir-compatible long format
-   **Multiple objects**: Automatically selects largest compatible data.frame

### School Data

-   **Required columns**: `Easting`, `Northing`, `Level`, `School`
-   **Detection**: Automatic via `School` column (duck typing)

## Configuration System (v0.10.0+)

### Directory Structure

External configuration files in `inst/` directory:
- **`inst/banner/`**: Banner CSS template with {{placeholder}} substitution
- **`inst/legend/`**: Legend CSS template with {{placeholder}} substitution
- **`inst/controls/`**: Year control HTML/CSS/JS (roller menu)
- **`inst/config/scales/`**: YAML colour scale definitions
- **`inst/themes/`**: YAML theme configuration files

### Colour Scale System

YAML-based scales in `inst/config/scales/`:
- **WHO-based**: `who_no2.yaml`, `stripes_no2.yaml`, `gla_pm25.yaml`
- **Borough-specific**: `lbw_no2.yaml`, `lbrut_no2.yaml`, `lbm_no2.yaml`
- **Special**: `deltas.yaml` (year-on-year change), `schools.yaml` (categorical)

Each YAML scale defines:
```yaml
name: who_no2
title: "NO2, µg/m³"
pollutant: NO2
shape: circle
thresholds: [0, 10, 20, 40, .Inf]
colours: ["green", "yellow", "orange", "red", "white"]
labels: ["< 10: Good", "10-20: Fair", "20-40: Poor", "> 40: Bad", "Insufficient data"]
```

Loading: `load_colour_scale("who_no2")` returns R list with validation

### Theme System

Reusable theme files in `inst/themes/` for consistent borough styling:

Example `merton_purple.yaml`:
```yaml
banner:
  background: "#5F3E94"
  text_color: "white"
  title: "Merton Air Quality"
legend:
  show: true
  background: "#DED4E9"
map:
  vignette: true
  base_tiles: null  # null = default OSM, or "CartoDB.Positron"
  zoom_level: null  # null = auto-fit
  boundary_labels: false
  marker_labels: false
controls:
  autoplay: false
  play_speed: 500
  background: "#5F3E94"
  text_color: "white"
```

Usage in `create_pollution_map()`:
```r
create_pollution_map(
  diffusion_tube_file = "data.csv",
  boroughs = "Merton",
  theme_file = "inst/themes/merton_purple.yaml",
  # Explicit params override theme:
  vignette = FALSE  # overrides theme's vignette: true
)
```

Functions: `get_default_theme()`, `load_theme(theme_file)` with graceful fallback

### Named Placeholder Pattern

CSS/JS templates use `{{placeholder_name}}` replaced by `gsub()`:
- Better readability than sprintf positional parameters
- Self-documenting template structure
- No parameter counting errors
- Used in: `load_banner_css()`, `load_legend_css()`, `load_roller_menu_control()`

## UI Enhancement System

### External Legend System

-   **Mobile responsive**: Auto-collapses on screens \<480px
-   **Collapsible**: Click header to toggle visibility
-   **Generated from color scales**: Uses existing `colour_scales` configuration
-   **Post-processing**: Modifies saved HTML files with `apply_custom_layout()`

### Banner System

-   **Customizable**: Text, color, positioning
-   **Flexbox layout**: Banner/map/legend components
-   **Mobile optimized**: Responsive font sizes and padding

### Year Control Menu

-   **Touch-friendly**: Collapsible dropdown menu for year selection
-   **Dynamic years**: Automatically populated from available data
-   **Banner theming**: Colors derived from `banner_colour` parameter
-   **Mobile responsive**: rem-based sizing for all screen sizes
-   **Files**: `inst/controls/roller-menu.html`, `.css`, `.js`

## File Structure & Outputs

### Input Files

Scripts expect data files via environment variables or absolute paths.

### Output Directory

-   **`aq_maps/`**: Auto-created output directory
-   **HTML files**: Interactive maps with year controls
-   **JPG files**: Static exports (when `image_export = TRUE`)
-   **Cleanup**: Automatically removes temporary `_files` folders

## Dependencies

Core R packages (auto-installed): - `leaflet`: Interactive mapping - `sf`: Spatial data handling - `dplyr`: Data manipulation - `leaflegend`: Custom legend controls - `webshot2`: Static image export - `htmlwidgets`: Widget saving and manipulation

## Marker Labels

**Options:** `FALSE` | `TRUE` (hover) | `"values_on"` (always) | `"labels"` (custom/hover) | `"labels_on"` (custom/always)

**Content (duck typing):** School column → school names | Label column → custom labels | pollutant → values

School data detected by School column presence. Any filename works (schools.csv, schools_wandsworth.csv, etc.).

## Design Philosophy

**Duck typing:** Data types detected by column presence (School/Label/year_str), not filenames or IDs.
**Optional IDs:** `data_ids` auto-generates from filenames when NULL.
**OpenAir consistency:** Follows OpenAir API patterns.

## Version History

-   **v0.9.0**: Parameter simplification (breaking changes)
-   **v0.9.1**: Function extraction, zeallot assignment (-40% main function size)
-   **v0.9.2**: Consolidated API (data_sources replaces individual file params)
-   **v0.9.3**: OpenAir converter functions (importUKAQ, importAURN, importKCL)
-   **v0.9.3.20**: School label duck typing fix
-   **v0.9.3.21**: RData duck typing (standard names → any compatible data.frame)
-   **v0.9.4**: Sub-annual temporal resolution (month/day/hour), renamed `years` → `display_times`

Archived versions in `versions/`. Current: `R/quickmap.R`.

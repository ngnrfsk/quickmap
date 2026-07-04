# CLAUDE.md (Consolidated)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview & Strategy

**QuickMap** is an R project for generating interactive air quality maps showing pollution data (NO2, PM2.5, PM10, ozone) overlaid with static locations (schools, medical facilities) and borough and ward boundaries. It creates both interactive Leaflet HTML maps and static JPG exports for local government air quality reporting.

Its unique capability is the **production-ready temporal animation of monitoring network data with self-contained HTML/JPG output.** It is not intended to compete with general-purpose mapping tools like `mapview` or `tmap`, but to serve as a production tool for air quality reporting and research visualization.

### Current Version: 0.9.4

-   **Production code**: `R/quickmap.R` (stable, ~2,200 lines)
-   **Archived versions**: `versions/quickmap_0_8_5.R` through `versions/quickmap_0_9_3.R`
-   **Test scripts**: Multiple test scripts in `tests/` directory, testthat files

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
    -   **Circles**: Diffusion tubes (`dt_sites`)
    -   **Diamonds**: Breathe London nodes (`bl_nodes`)
    -   **Crosses**: Schools (`schools`)
    -   Colors determined by pollution thresholds or categorical data
4.  **Single Loop Processing** (`generate_map_layers()`)
    -    

## API Design Philosophy & Style Guide

This section is guided by conventions from the `openair` R package to ensure future compatibility.

### Guiding Principles

1.  **User Intent over Implementation**: Parameters should describe what the user wants, not how it's done.
2.  **Progressive Disclosure**: Common parameters are top-level; advanced or obscure ones are secondary.
3.  **Context-Aware Defaults**: Defaults should be intelligent and work for 90% of use cases.
4.  **Multi-Value over Boolean**: Prefer categorical state parameters (e.g., `marker_labels = "values_on"`) over many boolean flags (e.g., `show_values = TRUE`).
5.  **OpenAir Compatibility**: Design with `openair` integration in mind. Use compatible parameter names and data structures where feasible.
6.  **Evolution over Revolution**: Maintain backward compatibility. Add aliases for new parameters and deprecate old ones gracefully.

### Parameter Naming Conventions

- **Existing (v0.9.x)**: Use `snake_case` for multi-word parameters (e.g., `marker_labels`, `colour_scale`).
- **New (v0.10.0+)**: New parameters should adopt the `openair` convention of using `dot.case` (e.g., `avg.time`, `data.thresh`).
- **Aliases**: To maintain compatibility, new `dot.case` parameters can serve as aliases for old `snake_case` ones.

### Code Minimalism Rules
- **Do:**
    - Trust R's errors and let functions fail naturally.
    - Write self-evident code.
- **Avoid:**
    - `cat()` in user scripts.
    - Redundant validation (if checked downstream).
    - Obvious comments.
    - `try-catch` around operations that are expected to fail.
    - Single-use helper functions or wrappers.
    - Unnecessary success messages.

## `create_pollution_map()` Parameter Reference

### Data Source Parameters
- `data_sources` (List): A list of file paths (CSV/RData) or sf objects. This is the primary way to provide data.
- `data_ids` (Character Vector): Optional IDs for each data source. Auto-generated from filenames if `NULL`.
- `data_symbols` (Character Vector): Optional symbols for each data source (e.g., "circle", "triangle"). Auto-cycles if `NULL`.
- `data_dynamic` (Logical Vector): Optional flags indicating if a layer is temporal. Auto-detected if `NULL`.
- `diffusion_tube_file`, `sensor_file`, `school_file` (String): **Deprecated**. Legacy parameters for single file inputs. Use `data_sources`.

### Output Parameters
- `output_file` (String): Path for the output HTML file. Defaults to `"pollution_map.html"`.
- `export_image` (NULL, Logical, or Numeric Vector): Exports a static image. `NULL` or `FALSE` for no export, `TRUE` for a default 1920x1080px image, or `c(width, height)` for custom dimensions.

### Geographic Parameters
- `boroughs` (Character Vector): **Required**. One or more London borough names, or `"all"`.
- `vignette` (Logical): If `TRUE`, darkens the area outside of the selected borough boundaries.

### Data Selection Parameters
- `pollutant` (String): The pollutant to map (e.g., `"no2"`, `"pm25"`). Defaults to `"no2"`.
- `years` (Numeric Vector): The year(s) to display. `NULL` for all available years.
- `colour_scale` (String): The name of the color scale to use (e.g., `"who_no2"`).

### UI/Display Parameters
- `title` (String): The main title for the map banner. Auto-generated if `NULL`.
- `styling_type` (String): `"html"` for full banner/legend/controls, or `"minimal"` for a basic map. Defaults to `"html"`.
- `marker_labels` (Logical or String): Controls marker label visibility. `FALSE` (none), `TRUE` (hover), `"values_on"` (always show values), `"labels_on"` (always show IDs).
- `banner_colour` (String): Hex color for the banner background.
- `boundary_labels` (Logical): If `TRUE`, shows borough name labels on the map.

### Animation Parameters
- `autoplay` (Logical): If `TRUE`, the year-by-year animation starts automatically.
- `play_speed` (Numeric): The time in milliseconds between animation frames (years). Defaults to 500.

### Theme Parameter
- `theme_file` (String): Path to a YAML theme file to apply consistent styling.

### Parameter Override Hierarchy
Parameters are applied in this order of precedence (highest to lowest):
1.  Explicit function parameter (e.g., `title = "My Map"`)
2.  Value from `theme_file` YAML
3.  Default value

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

External configuration files in `inst/` directory:
- **`inst/config/scales/`**: YAML colour scale definitions
- **`inst/themes/`**: YAML theme configuration files
- **`inst/banner/`**, **`inst/legend/`**, **`inst/controls/`**: CSS/JS templates for UI components.

## UI Enhancement System

-   **External Legend System**: A mobile-responsive, collapsible legend generated from the color scale configuration.
-   **Banner System**: A customizable banner with title and branding.
-   **Year Control Menu**: A touch-friendly, animated dropdown menu for selecting the year to display.

## Version History
-   **v0.9.0**: Parameter simplification (breaking changes)
-   **v0.9.1**: Function extraction, `zeallot` assignment (-40% main function size)
-   **v0.9.2**: Consolidated API (`data_sources` replaces individual file params)
-   **v0.9.3**: OpenAir converter functions (`importUKAQ`, `importAURN`, `importKCL`)
-   **v0.9.3.20**: School label duck typing fix
-   **v0.9.3.21**: RData duck typing (standard names → any compatible data.frame)
-   **v0.9.4**: Sub-annual temporal resolution (month/day/hour), renamed `years` → `display_times`

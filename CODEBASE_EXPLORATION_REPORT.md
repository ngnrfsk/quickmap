# QuickMap Codebase Comprehensive Overview

## 1. Project Context

**QuickMap** is an R project for generating interactive air quality maps showing pollution data (NO2, PM2.5) overlaid with school locations and borough boundaries. It creates both interactive Leaflet HTML maps and static JPG exports for local government air quality reporting.

**Current Version**: 0.9.0.2  
**Main File**: `/home/user/quickmap/R/quickmap.R` (2,679 lines)  
**Architecture**: Unified single-loop processing generates both HTML and static images  
**Key Functions**: 32 total functions  
**Documentation Files**: 39 markdown files  

---

## 2. Overall Directory Structure

```
/home/user/quickmap/
├── R/
│   └── quickmap.R (2,679 lines - production code)
├── versions/ (15+ archived versions)
│   ├── quickmap_0_8_5.R through quickmap_0_9_0_2.R
│   └── [version history from 0.8.0 onwards]
├── inst/
│   ├── controls/ (Year/timeline controls)
│   │   ├── roller-menu.html (456 bytes)
│   │   ├── roller-menu.css (2,691 bytes)
│   │   └── roller-menu.js (17,810 bytes)
│   └── examples/ (Usage examples and scripts)
├── tests/
│   ├── testthat/ (4 test files with actual map outputs)
│   │   ├── test-styling.R
│   │   ├── test-parameters.R
│   │   └── test-export.R
│   ├── v0.9.1_test_*.R
│   └── testthat.R
├── dev/ (Development documentation & planning)
│   ├── PROJECT_STATUS.md (comprehensive project status)
│   ├── 20251116_legend_refactor_plan_1930.md (8-step detailed plan)
│   ├── NOTE_config_refactor.md (future improvements noted)
│   ├── archive/ (completed plans & legacy scripts)
│   ├── reference/ (technical guides)
│   └── utilities/
├── vignettes/ (Migration guides and parameter documentation)
│   ├── MIGRATION_EXAMPLE_v0.9.0.md
│   └── v0.9.0_parameter_changes.md
├── CLAUDE.md (Project instructions for Claude)
├── README.md (User-facing documentation)
├── REORGANIZATION_PROPOSAL.md
└── [git, package metadata, etc.]
```

---

## 3. Core Architecture: Unified Layer Processing Pipeline

The codebase uses a **single-loop architecture** that processes all map layers through a unified pipeline:

```
Data Loading → Layer Configuration → Generic Processing → Icon Generation → Map Rendering
```

### 3.1 Pipeline Components

#### **Stage 1: Data Loading** (`load_data_file()`)
- Unified loader supporting multiple formats
- **CSV files**: Diffusion tubes with Easting/Northing coordinates
- **RData files**: Breathe London sensors with lat/lon
- **School data**: Location and level information
- Coordinate transformation from British National Grid (EPSG:27700) to WGS84

```r
# Key functions:
- load_data_file()          # Main unified loader
- load_rdata_file()         # Specialized RData loader
- import_csv_data()         # CSV import with path handling
- process_oa_data()         # OpenAir data processing
- transform_to_wgs84()      # Coordinate transformation
```

#### **Stage 2: Layer Configuration** (`get_measurement_layers()`)
- Configuration-driven system defining which layers to render
- Supports temporal layers (pollution data with years) and static layers (schools)
- Each layer type has specific preparation functions

```r
# Returns structure:
measurement_layers <- list(
  bl_nodes = list(
    enabled = TRUE,
    temporal = TRUE,
    layer_type = "bl_nodes",
    data_source = "bl_annual_means_sf",
    icon_type = "diamond",
    options = list(marker_labels = marker_labels)
  ),
  dt_sites = list(...),
  schools = list(...)
)
```

#### **Stage 3: Data Preparation** (`prepare_generic_layer_data()`)
- Unified preparation for all layer types
- Handles temporal vs static data
- Applies color scaling based on pollution thresholds

#### **Stage 4: Icon Generation** (`create_generic_icons()`)
- **Circles**: Diffusion tube sites (dt_sites)
- **Diamonds**: Breathe London nodes (bl_nodes)
- **Crosses**: Schools (schools)
- Colors determined by:
  - Pollution thresholds (for temporal data)
  - Categorical data (for schools - Primary/Secondary)

#### **Stage 5: Layer Addition** (`add_layer()`)
- Single function adds markers to map
- Label visibility control
- Marker size scaling for different image dimensions
- Layer grouping for year-based visibility

#### **Stage 6: Map Rendering & Export**
- Interactive HTML maps (leaflet)
- Static JPG exports (webshot2)
- HTML post-processing for banner/legend (custom CSS/JS)

### 3.2 Key Design Patterns

**Configuration Objects**
- All styling, colors, and layer definitions stored in configuration objects
- Easy to modify without changing core logic

**Generic Functions**
- `prepare_generic_layer_data()` → `create_generic_icons()` → `add_layer()` pipeline
- Eliminates code duplication across layer types

**Temporal Support**
- Year-based filtering with layer grouping
- Interactive controls for time series data
- Year menu in bottom-right corner (roller-menu control)

**Environment Variables**
- `DATA_PATH`: File location configuration
- `SCRIPTS_PATH`: Script location configuration

---

## 4. Main Function Analysis: `create_pollution_map()`

### Location and Signature
**Lines 2347-2680** (334 lines)

```r
create_pollution_map <- function(
  # File handling
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",
  output_file = "pollution_map.html",
  export_image = NULL,  # c(width, height) or NULL
  
  # Location
  boroughs,
  
  # Data processing
  pollutant = "no2",
  years = NULL,
  
  # Titles & styling
  title = "Air Quality Map",
  vignette = TRUE,
  colour_scale = "who_no2",
  styling_type = "html",  # "none" or "html"
  marker_labels = FALSE,
  banner_colour = borough_palettes$merton$purple,
  boundary_labels = FALSE,
  
  # Animation parameters
  autoplay = FALSE,
  play_speed = 500
) { ... }
```

### Major Sections

1. **Setup & Parameter Unpacking** (lines 2374-2388)
   - Converts `export_image = c(w, h)` to internal variables
   - Unpacks `styling_type` to `show_banner` boolean

2. **Data Loading** (lines 2403-2448)
   - Loads CSV data (diffusion tubes)
   - Loads RData (Breathe London sensors)
   - Loads school data
   - Handles file-not-found with graceful fallback

3. **Data Filtering** (lines 2455-2466)
   - Vignette filtering (points outside borough boundary)
   - Quality threshold filtering (>20% missing data)

4. **Data Preparation** (lines 2475-2491)
   - Extract available years
   - Handle static-only scenarios (no temporal data)
   - Set up spatial bounding box

5. **Single Loop Layer Generation** (lines 2527-2669)
   - **HTML map**: Cumulative loop adds all layers with year controls
   - **Static images**: Fresh map per year with scaling
   - One loop generates both output types
   - Calls `generate_map_layers()` for each year

6. **HTML Post-Processing** (lines 2659-2675)
   - Applies banner, legend, year controls
   - Modifies saved HTML with custom CSS/JS
   - Only when `styling_type = "html"`

### Complexity Metrics
- **Nesting depth**: Medium (3-4 levels)
- **Code organization**: Well-commented sections
- **Lines per section**: 30-100 lines typical
- **Function calls per line**: ~1.5 (moderate density)

---

## 5. Color Scale System

### Definition Location
**Lines 524-774** (250 lines)

### Current Color Scales

```r
colour_scales <- list(
  # WHO-based scales (pollution)
  who_no2        # Blue-green-yellow-orange-red WHO guideline scale
  stripes_no2    # WHO + striped pattern
  stripes_pm25_  # PM2.5 variant
  
  # Borough-specific scales
  lbrut_no2      # Richmond-specific NO2 thresholds
  lbw_no2        # Wandsworth-specific NO2 thresholds
  lbm_no2        # Merton-specific NO2 thresholds
  
  # PM2.5 scale
  gla_pm25       # GLA PM2.5 levels
  
  # Special scales
  deltas         # Year-on-year change (inverted: blue=improvement)
  schools        # Categorical (Primary/Secondary)
)
```

### Each Scale Structure
```r
scale_name = list(
  colours = c("#hex1", "#hex2", ..., "white"),      # 8-12 colors
  thresholds = c(0, 10, 20, 30, ..., Inf),          # 8-12 thresholds
  labels = c("< 10: WHO guideline", "10-19: ...", ..., "Insufficient data"),
  title = "NO2 annual mean, µg/m3",
  shape = "circle"  # optional
)
```

### Color Assignment Function
```r
assign_colour <- function(value, scale = "lbrut_no2")
  # Uses findInterval() to map value to color based on thresholds
```

### Key Characteristics
- **Thresholds are inclusive** (findInterval with left.open = FALSE)
- **Missing data always maps to white**
- **Colors from R color names OR hex codes**
- **Borough-specific thresholds** for local government reporting
- **Consistent structure** enables generic processing

---

## 6. CSS/JS Code Generation Patterns

### 6.1 Inline CSS Generation in R Functions

**Location**: Lines 1076-1349 within `apply_custom_layout_in_html()`

**Pattern**: Heavy use of `sprintf()` with embedded CSS

```r
# Example pattern (lines 1078-1151)
custom_css <- "\n<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { height: 100%%; font-family: Arial, sans-serif; overflow: hidden; }
  
  .banner {
    background: %s;           # sprintf placeholder for banner_colour
    color: white;
    padding: 2rem;
    text-align: center;
    font-size: 1.8rem;        # Larger for image_mode
    line-height: 1.3em;
    flex-shrink: 0;
    font-weight: bold;
  }
  ...
</style>"

# Injection via sprintf
custom_css <- sprintf(custom_css, 
  banner_colour,            # %s #1 - banner bg
  legend_header_bg,         # %s #2 - legend header bg
  legend_header_hover_bg,   # %s #3 - legend header hover
  ...
)
```

**Issues with Current Approach**:
- 14+ positional `%s` placeholders (fragile)
- Easy to introduce "too few arguments" errors
- Hard to document which placeholder maps to which element
- No separation of concerns (styling embedded in R)

### 6.2 External File-Based Controls (Roller Menu)

**Pattern**: Modular external files with dynamic injection

**Files**: `inst/controls/roller-menu.{html,css,js}`

**Generation Function**: `load_roller_menu_control()` (lines 973-1031)

```r
load_roller_menu_control <- function(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500
) {
  # Read external files
  html_content <- readLines("inst/controls/roller-menu.html")
  css_content <- readLines("inst/controls/roller-menu.css")
  js_content <- readLines("inst/controls/roller-menu.js")
  
  # Calculate accent colors from banner_colour
  accent_light <- lighten_color(banner_colour, 15)
  hover_tint <- lighten_color(banner_colour, 85)
  
  # Inject colors via sprintf (8 color parameters)
  css_content <- sprintf(css_content,
    banner_colour, banner_colour, accent_light, accent_light, "#ffffff",  # Play
    banner_colour, banner_colour, accent_light, accent_light, "#ffffff",  # Year
    banner_colour, hover_tint, accent_light, hover_tint,                  # Menu
    hover_tint, banner_colour)                                            # Keyboard
  
  # Create config script for JavaScript
  config_script <- sprintf(
    'window.quickmapConfig = {autoplay: %s, playSpeed: %d};',
    tolower(as.character(autoplay)),
    as.integer(play_speed)
  )
  
  # Combine HTML + CSS + JS + config
  combined <- sprintf('...', html_content, css_content, js_content, config_script)
}
```

### 6.3 Legend HTML Generation

**Location**: Lines 868-933 (`generate_legend_html()`)

**Pattern**: Dynamic HTML generation with `sprintf()`

```r
generate_legend_html <- function(scale_name, collapsed_mobile = TRUE) {
  # Get scale configuration
  legend_scale <- colour_scales[[scale_name]]
  
  # Convert colors to hex
  hex_colors <- convert_colors_to_hex(legend_scale$colours)
  
  # Generate each legend item with sprintf
  legend_items <- sapply(seq_along(hex_colors), function(i) {
    sprintf(
      '<div class="legend-item"><div class="legend-symbol" style="background: %s;"></div><span>%s</span></div>',
      hex_colors[i],
      legend_scale$labels[i]
    )
  })
  
  # Combine into template
  sprintf('</div><div class="legend" id="mapLegend">...', 
    legend_scale$title, 
    paste(legend_items, collapse = "\n"),
    mobile_script)
}
```

### 6.4 Color Utility Functions

**Lines 826-962**

```r
convert_colors_to_hex()    # R names → hex codes
lighten_color()            # Adjust brightness for button theming
```

---

## 7. Layer Generation Loop

### Primary Loop: `generate_map_layers()`

**Lines 2078-2159** (82 lines)

```r
generate_map_layers <- function(
  base_map,
  measurement_layers,
  target_year,           # Specific year or "static_only"
  pollutant,
  colour_scale,
  data_env,
  image_scale_factor = 1.0
) {
  for (layer_name in names(measurement_layers)) {
    layer_config <- measurement_layers[[layer_name]]
    if (!layer_config$enabled) next
    
    # Branch 1: Temporal layers (DT, BL)
    if (layer_config$temporal) {
      if (target_year != "static_only") {
        # Get year data
        year_data <- get_layer_year_data(...)
        
        # Prepare layer data
        layer_data <- prepare_generic_layer_data(...)
        
        # Add to map
        base_map <- add_layer(...)
      }
    }
    
    # Branch 2: Static layers (Schools)
    else {
      static_data <- get(layer_config$data_source, envir = data_env)
      layer_data <- prepare_generic_layer_data(layer_config, static_data)
      base_map <- add_layer(...)
    }
  }
  return(base_map)
}
```

### Single Loop in Main Function (Lines 2527-2669)

```r
for (yr in unique(years)) {
  # HTML map gets cumulative layers (all years overlaid)
  html_map <- generate_map_layers(
    html_map, measurement_layers, yr, 
    pollutant, colour_scale, environment(), 1.0)
  
  # Static image: Fresh map per year
  if (image_export) {
    static_map <- static_map_template  # Fresh start
    
    # Add temporal layers (this year)
    static_map <- generate_map_layers(..., yr, ..., scale_factor)
    
    # Add static layers (schools)
    static_map <- generate_map_layers(..., "static_only", ..., scale_factor)
    
    # Add controls and export
    static_map <- add_map_controls(...)
    saveWidget(static_map, file = html_file)
    
    # Post-process HTML
    apply_custom_layout_in_html(html_file, ...)
    
    # Convert to JPG
    webshot2::webshot(html_file, img_file, ...)
  }
}
```

### Key Characteristics
- **No code duplication** - single path for HTML and static
- **Proper layer grouping** - each year gets a named group
- **Clean separation** - temporal vs static layer logic
- **Efficient scaling** - geometric mean for image dimensions

---

## 8. Configuration Patterns

### 8.1 Current Configuration Management

**Borough Palettes**: Lines 489-774

```r
# Nested named list structure (added v0.8.11)
borough_palettes <- list(
  merton = list(
    purple = "#8b4789",
    blue = "#003d82",
    ...
  ),
  wandsworth = list(
    blue = "#003d82",
    ...
  ),
  richmond = list(...)
)

# Usage: borough_palettes$merton$purple
# Helper: show_borough_colours()
```

**Color Scales**: Lines 524-774 (250 lines)
- Hardcoded in R file
- Consistent structure but verbose
- Easy to modify for specific use cases

**Global Constants**: Line 128
```r
MISSING_DATA_THRESHOLD <- 20  # Percent
```

### 8.2 Parameter Design Philosophy (v0.9.0)

**Principle**: Intent-based naming following OpenAir patterns

```r
# OLD (v0.8.11) - Implementation-based
years_to_plot = 2024
show_marker_labels = TRUE
show_boundary_labels = FALSE
use_data_labels = TRUE  # Removed - confusing

# NEW (v0.9.0) - Intent-based
years = 2024           # WHAT user wants, not HOW
marker_labels = TRUE   # WHAT to show, not internal mechanism
boundary_labels = FALSE
```

**Parameter Reduction**: 21 → 14 parameters (v0.9.0)
- Renamed 6 parameters for clarity
- Merged 7 into 3 (image export, title, styling)
- Removed confusing parameters

---

## 9. External Dependencies

**Core R Packages** (auto-installed):
```r
leaflet           # Interactive mapping
sf                # Spatial data handling
dplyr             # Data manipulation
leaflegend        # Legend controls
tidyr             # Data reshaping
lubridate         # Date handling
stringr           # String operations
webshot2          # Static image export
htmlwidgets       # Widget saving
htmltools         # HTML generation
leaflet.extras    # Extended leaflet features
```

**No external databases required** (current v0.9.0.2)

---

## 10. Key Functions Overview (32 Total)

### Data Loading & Validation (7 functions)
- `load_data_file()` - Unified loader
- `load_rdata_file()` - RData specialist
- `import_csv_data()` - CSV import
- `validate_oa_data()` - Data validation
- `process_oa_data()` - OpenAir processing
- `get_temporal_data()` - Temporal extraction
- `get_boundary_sf()` - Boundary loading

### Spatial Operations (3 functions)
- `transform_to_wgs84()` - Coordinate transformation
- `create_vignette_overlay()` - Boundary overlay
- `add_map_border()` - Border addition

### Color & Styling (6 functions)
- `assign_colour()` - Value-to-color mapping
- `get_colour_legend()` - Legend retrieval
- `convert_colors_to_hex()` - Color conversion
- `lighten_color()` - Color adjustment
- `generate_legend_html()` - Legend generation
- `show_borough_colours()` - Color helper

### Control Loading (2 functions)
- `load_roller_menu_control()` - Year control
- `load_banner_css()` - [Planned] Banner CSS loading

### Layer Management (4 functions)
- `get_measurement_layers()` - Layer configuration
- `prepare_generic_layer_data()` - Data preparation
- `prepare_bl_layer_data()` - BL-specific prep
- `prepare_dt_layer_data()` - DT-specific prep

### Icon & Marker Creation (3 functions)
- `create_generic_icons()` - Universal icon system
- `generate_marker_labels()` - Label generation
- `prepare_static_layer_data()` - Static data prep

### Map Operations (5 functions)
- `add_layer()` - Add markers to map
- `add_title()` - Title addition
- `add_boundary_polygons()` - Boundary addition
- `add_map_controls()` - Control addition
- `apply_custom_layout_in_html()` - HTML post-processing

### Core Function (1 function)
- `create_pollution_map()` - Main entry point

### Map Generation & Export (2 functions)
- `generate_map_layers()` - Unified layer generation
- `get_layer_year_data()` - Year-specific data retrieval

---

## 11. Existing Planning & Modernization Efforts

### Completed Work (v0.9.0 released)
- ✓ Parameter simplification (21 → 14)
- ✓ OpenAir-style design patterns
- ✓ Unified banner/legend system
- ✓ Touch-friendly year controls (roller menu)
- ✓ Migration guide for users
- ✓ Comprehensive testing

### In-Progress Work (v0.9.1+)
**Legend Refactoring Plan** (8-step detailed plan in `dev/20251116_legend_refactor_plan_1930.md`)
- Step 0: Current state (inline CSS/HTML)
- Step 1: Extract banner CSS to `inst/banner/`
- Step 2: Extract legend CSS to `inst/legend/`
- Step 3: Extract legend HTML template to `inst/legend/`
- Step 4: Dynamic legend trimming based on data max
- Step 5: Redesign legend layout (horizontal)
- Step 6: Implement dropdown behavior
- Step 7: Text-on-colored-background format
- Step 8: Testing & cleanup

### Planned Refactoring (Future Versions)

**Refactor-4: Configuration System** (v0.9.1+, 4-6 hours)
- YAML/JSON config files for scales & defaults
- Named placeholder system (vs positional sprintf)
- Parameter validation system
- OpenAir compatibility layer

**Refactor-5: Modular Architecture** (v0.9.x, 8-12 hours)
- Split monolithic quickmap.R into modules:
  - `R/data_io.R`
  - `R/data_processing.R`
  - `R/layer_generation.R`
  - `R/styling_rendering.R`
  - `R/html_export.R`
  - `R/config.R`
  - `R/utils.R`

**Refactor-6: Modern R Practices** (v1.0, 12-16 hours)
- Tidyverse consistency
- Error handling & logging
- Testing infrastructure (testthat)
- Code quality tools (styler, lintr)
- CRAN submission preparation

### Outstanding Issues (from PROJECT_STATUS.md)

**Essential for LCA site**:
1. Collapsible radio buttons (bottom-left corner)
2. Zoom level optimization on map open
3. Select start layer (initial visibility)

**High Priority**:
- Subfolder cleanup (leaflet JS generation)
- Unified marker/text/legend sizing logic
- Ward and marker label consistency

**Low Priority**:
- Split import and map creation functions
- Automate label placement/clustering
- R package preparation

---

## 12. Areas for Modernization

### 1. Code Organization (HIGH IMPACT)
- **Current**: Single 2,679-line file
- **Concern**: Difficult to navigate, maintain, test
- **Solution**: Modular architecture with separate files per responsibility
- **Effort**: 8-12 hours

### 2. Configuration Management (HIGH IMPACT)
- **Current**: 14 positional sprintf placeholders (fragile)
- **Current**: Hardcoded color scales (250 lines)
- **Concern**: Easy to introduce bugs, hard to document
- **Solution**: Named config system, possibly YAML/JSON
- **Effort**: 4-6 hours

### 3. CSS/JS Generation (MEDIUM IMPACT)
- **Current**: Inline sprintf with 14+ color parameters
- **Current**: Roller menu properly extracted (good pattern)
- **Concern**: Inconsistent approach - legend still embedded
- **Solution**: Extract all styling to `inst/` (banner, legend, controls)
- **Effort**: 3-4 hours (already planned in legend refactor)

### 4. Function Naming & API Clarity (MEDIUM IMPACT)
- **Current**: Names are descriptive but verbose
- **Solution**: Consistent naming patterns, clearer documentation
- **Effort**: 2-3 hours

### 5. Testing Infrastructure (MEDIUM IMPACT)
- **Current**: 3 basic test files creating actual map outputs
- **Solution**: Full testthat suite with unit tests
- **Effort**: 4-6 hours

### 6. Error Handling & Validation (LOW-MEDIUM IMPACT)
- **Current**: Basic error handling in data loading
- **Solution**: Comprehensive input validation, graceful failures
- **Effort**: 3-4 hours

### 7. Documentation (LOW IMPACT)
- **Current**: Excellent (CLAUDE.md, 39 markdown files)
- **Solution**: Already strong, just update as refactoring occurs
- **Effort**: 1-2 hours per refactor

---

## 13. Dependencies for Modernization Success

### Must Understand Before Starting
1. **Unified layer pipeline** - Core strength, must preserve
2. **Temporal vs static layer handling** - Two different code paths needed
3. **Image scaling logic** - Geometric mean calculation for proportional sizing
4. **Color assignment** - Threshold-based with inclusive boundaries
5. **HTML post-processing** - Critical for interactive vs static map differences

### Architecture Decisions to Make
1. **Module boundaries** - Where to split the 2,679 lines
2. **Configuration format** - YAML, JSON, R list, or hybrid?
3. **Function visibility** - What should be internal vs exported?
4. **Package structure** - Is CRAN submission a goal?

### Testing Strategy
1. Preserve existing test outputs for regression testing
2. Add unit tests for individual functions
3. Add integration tests for complete workflows
4. Test across different screen sizes and dimensions

---

## 14. Strengths of Current Codebase

1. **Well-commented** - Every major section has clear explanations
2. **Functional architecture** - Pure functions, no hidden state
3. **Consistent patterns** - Data loading, layer prep, icon creation follow same structure
4. **Flexible configuration** - Easy to add new color scales, borough palettes
5. **Extensible design** - New layer types easily added
6. **Good documentation** - CLAUDE.md, migration guides, planning docs
7. **Version control** - Archived versions from 0.8.0 onwards
8. **Modular controls** - Roller menu already properly extracted (good example)
9. **Geographic flexibility** - Works with any borough/region
10. **Export versatility** - Both interactive HTML and static JPG in one function

---

## 15. Technical Debt & Refactoring Priorities

### Quick Wins (< 2 hours each)
- Extract banner CSS to `inst/banner/` 
- Extract legend CSS to `inst/legend/`
- Add dynamic legend trimming (skip unused color ranges)
- Better function naming for consistency

### Medium Tasks (2-6 hours)
- Named config system for color parameters
- Legend HTML to external template
- Comprehensive input validation
- Enhanced error messages

### Large Tasks (6-12 hours)
- Split into modular files (data_io, data_processing, etc.)
- Full testthat test suite
- Modern R practices (tidyverse, logging)
- Package restructuring for CRAN

---

## Summary

QuickMap is a **well-designed, functional codebase** with solid architecture. The unified layer pipeline is elegant and extensible. The main modernization opportunities are:

1. **Code organization** - Modules for easier navigation
2. **Configuration clarity** - Named params vs positional sprintf
3. **Consistency** - Legend extraction to match roller menu pattern
4. **Testing** - Full test coverage beyond current 3 files
5. **Documentation** - Already excellent, just update during refactoring

The existing planning documentation (especially the 8-step legend refactor plan) provides a good template for how to approach modernization incrementally without disrupting functionality.


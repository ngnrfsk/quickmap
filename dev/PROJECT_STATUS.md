---
editor_options: 
  markdown: 
    wrap: 80
---

# QuickMap Project Status Summary

**Last Updated**: 2025-11-25 **Current Working Version**: v0.9.1 **In Progress**: v0.9.2 Layer Generalization

--------------------------------------------------------------------------------

## v0.9.2 Layer Generalization (In Progress)

**Status**: Planning complete, ready for implementation
**Branch**: `feature/v092-layer-generalization` (from commit 90c0b83)
**Implementation Plan**: `dev/Implementation_v092_Layer_Generalization.md`
**High-Level Roadmap**: `dev/Plan_v091_to_v095.md`

**Key Changes**:
- New API: `data_sources` (files/sf objects) + `data_configs` (YAML config names) as parallel vectors
- YAML-based network configs in `inst/config/networks/` (dt_sites.yaml, bl_nodes.yaml, schools.yaml)
- Removed hardcoded layer_type switches, generic config iteration
- Icon shapes data-driven (circle, diamond, cross, square, triangle)
- Icon colors remain dynamic (from colour_scale parameter, not configs)
- Backward compatible: old 3-file API still works

**Success Criteria**:
- 4th network (mock AURN) added via YAML config only
- All 14 existing test scripts pass unchanged
- Visual regression: v0.9.1 vs v0.9.2 identical

**Lessons from Planning Session (2025-11-25)**:
1. **Avoid prescriptive plans**: Describe outcomes, not implementation (no function signatures in plans)
2. **Color logic clarity**: Icon colors are dynamic (colour_scale), not fixed in configs—must be explicit
3. **Parallel vectors pattern**: Cleaner than nested lists for data+config association
4. **Problem-oriented beats step-by-step for early planning**: Let engineer discover solutions
5. **Test API realism**: Step 6 tests production API, not throwaway test code
6. **Parameter naming**: `years` → defer to v0.9.4 (temporal resolution change)

--------------------------------------------------------------------------------

### FUTURE REFACTORING TASKS

#### Refactor-2: Database Import and Modular Architecture (Deferred)

**Category**: Architecture **Description**: Add database import using duckdb. Note: Layer generalization (v0.9.2) addresses generic layer system without full modular rewrite. **Expected Effort**: 12-16 hours **Complexity**: High

#### Minor Bugs to Fix and Features to Consider

**Category**: Code Quality **Description**: Various improvements and
optimizations - Replace tick box control with slider for many years - Add data
caching to avoid repeated data loading - Develop uniform text sizing approach
across codebase (coordinate with map size) - Remove stray temporary HTML files
on image generation (eliminate \_files folders) - Simplify and clarify all
function names for consistency - Rename parameters and restructure using
ggplot-type approach - Add animations capability - Performance and scalability
(lazy loading, batch processing) - User experience enhancements (clustering,
custom popups, export formats) - Error handling and robustness (validation,
logging, graceful failures) **Expected Effort**: 8-12 hours total

### Completed Fixes

#### RData Duck Typing (v0.9.3.21) - 2026-01-13

**Problem**: RData loading required exact object name "dataOAformat"
**Fix**: Three-strategy loader - (1) standard names (dataOAformat/data/oa_data/sensor_data), (2) any compatible data.frame (largest), (3) optional explicit data_object_name parameter
**Impact**: Works with any RData file containing compatible sensor data (siteCode, year, pollutant, lat, lon columns)
**Testing**: Comprehensive test suite in tests/test_rdata_duck_typing.R validates all strategies

#### School Label Duck Typing (v0.9.3.20) - 2026-01-13

**Problem**: School labels failed with auto-generated layer IDs (e.g., "schools_wandsworth")
**Fix**: Removed hardcoded `layer_id == "schools"` check; now detects via School column
**Impact**: Works with any filename; data_ids truly optional

#### Issue 1: Boundary Labels Control (v0.8.8)

-   Added `show_boundary_labels` parameter (TRUE/FALSE)
-   Modified `add_boundary_polygons()` for label visibility

#### Issue 2: Banner and Legend System Unification (v0.8.7)

-   Unified banner/legend system between HTML and static maps
-   Extended `apply_custom_layout_in_html()` with `image_mode` parameter

#### Issue 3: Banner and Legend Scaling (v0.8.7.1)

-   Fixed scale factor calculation using geometric mean
-   Added marker size scaling throughout layer generation

#### Issue 4: Legend Size Issues (v0.8.7.3)

-   Reduced legend marker sizes relative to map markers
-   Improved gaps and padding in legend layout

#### Issue 6: Marker Labels Control (v0.8.9)

-   Added `show_marker_labels` parameter with 5-state control
-   Unified label behavior across OA, CSV, and Schools data sources
-   Added `generate_marker_labels()` helper function
-   Breaking change: `use_data_labels` parameter removed

#### Issue 5: File Organization (2025-10-15)

-   Moved version files to `versions/` directory
-   Moved test files to `tests/` directory
-   Moved utility scripts to `scripts/` directory

#### Issue 7: Marker Labels Fix (v0.8.10)

-   Fixed schools label behavior to respect show_marker_labels parameter
-   Fixed OA data label fallback when Label column missing

#### Issue 8: Borough Colour Palettes (v0.8.11)

-   Added borough-specific colour palettes in nested named lists
-   Created show_borough_colours() helper function
-   Enables consistent borough branding across maps

#### Issue 9: Parameter Simplification (v0.9.0) - 2025-10-28

**BREAKING CHANGES** - Major parameter refactoring following OpenAir design patterns

-   **Reduced parameters**: 21 → 14 (33% reduction)
-   **Reduced code**: 2485 → 2427 lines (58 lines, 2.3% reduction)
-   **Renamed 6 parameters** for clarity (removed "show_" prefixes):
    -   `years_to_plot` → `years`
    -   `vignette_overlay_on` → `vignette`
    -   `csv_data_file` → `diffusion_tube_file`
    -   `oa_data_file` → `sensor_file`
    -   `show_marker_labels` → `marker_labels`
    -   `show_boundary_labels` → `boundary_labels`
-   **Merged 7 parameters into 3**:
    -   Image Export (3→1): `export_image = NULL` or `c(width, height)`
    -   Title (2→1): Single `title` for browser tab and banner
    -   Styling (4→1): `styling_type = "none"` or `"html"`
-   **Removed leaflet controls**: Deleted leaflet legend/title code (28+6 lines)
-   **Fixed HTML legend**: Now only appears when `styling_type = "html"`
-   **Improved API**: Parameters describe WHAT user wants, not HOW implemented
-   **Complete migration guide** in quickmap.R header (lines 39-68)
-   **All tests passing**: 4 test files with actual map outputs for verification

### Historical Completed Tasks

#### Task 1E.1: Fix Legend Text and Marker Scaling Issues (2025-10-15, v0.8.7.1, commit: aa56fc2)

-   Fixed scaling problems where legend text and marker sizes didn't scale
    appropriately
-   Improved scale factor calculation using geometric mean
-   Added layout dimension scaling for padding, gaps, and legend height
-   Implemented marker size scaling based on image dimensions
-   Added image_scale_factor parameter throughout layer generation chain
-   All elements now scale consistently with image size
-   Fixed legend symbol proportions (1.3:1 ratio)

#### Bug 0: Markers too small in static maps (COMPLETED)

-   Increased base marker sizes (schools: 8→12, dt_sites/bl_nodes: 15→20)
-   Markers now scale consistently across HTML and static exports

#### Bug 1: CSV File Path Handling (2025-10-15, v0.8.7.3)

-   Fixed CSV file path handling to be consistent with RData files
-   Added DATA_PATH environment variable support for relative CSV paths
-   Resolves inconsistency where CSV files required full paths

#### Bug 2: Missing Data Filter Integration

-   Sites with \>20% missing data display as white disks
-   Added MISSING_DATA_THRESHOLD constant (20%)
-   Implemented in process_oa_data() function
-   Requires enriched data file with missing_no2 and missing_pm25 columns

#### Bug 3: Legends too big in standard size maps (2025-10-15, v0.8.7.1)

-   Reduced legend marker sizes relative to map markers
-   Improved gaps and padding in legend layout

#### Touch-Friendly Year Menu Control (2025-11-15, v0.9.0.2)

**Implementation Details:**
-   **Architecture**: Modular control system with external files (`inst/controls/`)
    -   `roller-menu.html`: Collapsible button and year list structure
    -   `roller-menu.css`: rem-based responsive styling with color placeholders
    -   `roller-menu.js`: Dynamic year population and layer switching logic
-   **Dynamic Color System**: Added `lighten_color()` utility function
    -   Calculates lighter/darker shades from `banner_colour` parameter
    -   Menu colors: Button/border/selected use banner color + 15% lighter shade
    -   Hover effects: Very light tint (85% lighter) for subtle feedback
    -   Legend header: Tinted with banner color for cohesive theming
-   **Features**:
    -   Touch/mobile friendly with large click targets and smooth animations
    -   Years dynamically populated from `window.quickmapLayerCache`
    -   Slide-in fade animation when opening menu
    -   Selected year highlighted with accent color and white text
    -   Scrollable list when >6 years (max-height: 15rem)
    -   Click outside to close functionality
-   **Integration**: Modified `apply_custom_layout_in_html()` and `load_roller_menu_control()`
    -   Passes `banner_colour` through to control styling
    -   8-color sprintf injection for complete theming
    -   Positioned 2rem from bottom to clear Leaflet attribution

**Files Modified:**
-   `R/quickmap.R`: Added color utility, modified control loading
-   `inst/controls/roller-menu.{html,css,js}`: New control files
-   Version archived to `versions/quickmap_0_9_0_2.R`

#### Legend Refactor with Symbol Keys (2025-11-18, v0.9.0.3)

**Complete legend system refactor for improved readability:**
-   **Symbol Key System**: Traditional footnote symbols (†‡§¶*) for explanations
    -   Fixed-width colored blocks using monospace font
    -   Separate collapsible key section for descriptions
    -   Labels without descriptions (e.g., "50-60") render without symbols
-   **Label Shortening**: 30-50% reduction focusing on key regulatory thresholds
    -   "Interim" → "Int", "Under" → "<", "Over" → ">"
    -   Removed multiplier references for extreme values (5x-10x WHO)
    -   Borough-specific labels: "< LB Richmond", "< LB Wandsworth"
-   **Flexbox Alignment**: Nested containers for perfect alignment
    -   Eliminated fixed padding calculations
    -   Symbol key naturally aligns with first numeric block
    -   Works across all title lengths (NO2, PM<sub>2.5</sub>)
-   **Visual Hierarchy**: Larger text for ranges (1rem), smaller for keys (0.85rem)
-   **Mobile Responsive**: Collapsed default on ≤480px, vertical centering fix
-   **External Templates**: Modular CSS/HTML in `inst/legend/` directory

**New Functions:**
-   `parse_legend_label()`: Extracts range and description from labels
-   `get_symbol_for_index()`: Maps index to footnote symbols
-   `calculate_max_range_width()`: Determines uniform block width
-   `get_contrast_text_color()`: WCAG luminance-based text color selection

**Files Modified:**
-   `R/quickmap.R`: Added 4 utility functions, modified `generate_legend_html()`
-   `inst/legend/legend.{html,css}`: New modular template system
-   All 7 colour scales: Shortened labels across NO2 and PM2.5 scales
-   Version archived to `versions/quickmap_0_9_0_3.R`

**Detailed Documentation:** `dev/20251118_v0.9.0.3_legend_refactor_complete.md`

#### Unified Architecture

-   **Interactive maps**: Use HTML post-processing for banners/legends
-   **Static maps**: Use same HTML post-processing before JPG conversion
-   **Marker scaling**: Different sizes for different image dimensions
-   **Single code path**: No more duplicate legend systems

## Current State Summary

### What Works

-   Simplified parameter interface (14 parameters, down from 21)
-   Clear intent-based parameter design following OpenAir patterns
-   Unified HTML banner/legend system across interactive and static maps
-   Conditional HTML processing (only when `styling_type = "html"`)
-   Proportional scaling for all image dimensions
-   Marker size scaling based on image dimensions
-   Complete migration guide for v0.8.x → v0.9.0
-   Git version control with comprehensive documentation
-   Organized file structure

### Testing Status (v0.9.0)

-   `tests/test_step1_renames.R` ✓ - All 6 renamed parameters work
-   `tests/test_step2_export_image.R` ✓ - Merged image export parameter
-   `tests/test_step3_title.R` ✓ - Merged title parameter (browser + banner)
-   `tests/test_step4_styling_type.R` ✓ - HTML banner/legend conditional display
-   All tests create actual map outputs for visual verification
-   Validated dimensions: 800x600, 1200x1200, 1920x1080
-   Uses `years = 2024` parameter correctly (renamed from years_to_plot)

## Outstanding Issues

### Essential visual site fixes for LCA site

12. Collapsible Radio Buttons - Make radio buttons collapse and move to bottom
    left corner
13. Zoom Level on Map Open - Ensure markers fill screen with no empty borders
14. Select Start Layer - Allow users to specify which layer is visible on
    initial map load 4: Recheck the Legend Size Issues (v0.8.7.3) for different
    screen sizes

### High Priority Issues

8.  Subfolder Generation - Static image generation creates unwanted subfolders
    with leaflet JS libraries
9.  Marker/Text/Legend Size Logic - Create unified scaling system for markers,
    text, and legends
10. Ward and Marker Labeling Consistency - Make ward and marker labels
    consistent between static and interactive maps

### Medium Priority Issues

### Low Priority Issues

15. Split Import and Map Create - Separate data loading from map generation
    (version 1)
16. Automate Label Location - Automate label location, clustering, and spread
17. Prepare for R Library Packaging - Structure code and documentation for R
    library packaging

### Code Quality and Refactoring Tasks

#### Refactor-4: Configuration System Enhancement = version 0.9.1+

**Category**: Architecture **Description**: Further configuration enhancements
**Status**: Phase 1 COMPLETED in v0.9.0 (parameter simplification)
**Remaining Phases**:
-   Phase 2: Config file system (YAML/JSON) for color scales and defaults
-   Phase 3: Parameter validation system with clear error messages
-   Phase 4: OpenAir compatibility layer for seamless integration

**Completed in v0.9.0**:
-   ✓ Simplified parameter controls (21 → 14 parameters)
-   ✓ Unified legend system (removed duplicate leaflet/HTML controls)
-   ✓ Merged title parameters (single `title` for all contexts)
-   ✓ OpenAir-style parameter design (intent-based, not implementation-based)

**Expected Effort**: 4-6 hours remaining **Complexity**: Medium

#### Refactor-5: Modular Architecture = Version 0.9.x Series

**Category**: Architecture
**Description**: Split monolithic quickmap.R into focused, maintainable modules
**Goal**: By v1.0, `create_pollution_map()` becomes a thin wrapper calling modular functions

**Proposed Modules**:
- `R/data_io.R` - Data loading and transformation
- `R/data_processing.R` - Filtering and spatial operations
- `R/layer_generation.R` - Icon and layer creation
- `R/styling_rendering.R` - Map styling and controls
- `R/html_export.R` - HTML processing and export
- `R/config.R` - Configuration and color scales
- `R/utils.R` - Utilities and helpers

**Evolution Path**:
- **v0.9.1-v0.9.5**: Extract modules while maintaining single-file compatibility
- **v0.9.6-v0.9.9**: Refactor `create_pollution_map()` to call modular functions
- **v1.0**: `create_pollution_map()` as thin wrapper over clean modular architecture

**Expected Effort**: 8-12 hours **Complexity**: High

#### Refactor-6: Modern R Practices and Library Setup = Version 1.0

**Category**: Code Quality
**Description**: Modernize codebase with contemporary R development practices and prepare for CRAN submission

**Architectural Goal**: `create_pollution_map()` as user-facing wrapper function:
```r
# v1.0 architecture
create_pollution_map <- function(...) {
  # Thin wrapper that calls:
  data <- load_pollution_data(...)      # R/data_io.R
  processed <- process_spatial_data(...) # R/data_processing.R
  map <- create_base_map(...)           # R/map_creation.R
  map <- add_pollution_layers(...)      # R/layer_generation.R
  map <- apply_styling(...)             # R/styling_rendering.R
  export_map(...)                       # R/html_export.R
  return(map)
}
```

**Key Areas**:
- Tidyverse consistency
- Comprehensive error handling
- Structured logging system
- Testing infrastructure (testthat)
- Code quality tools (styler, lintr)
- Performance monitoring
- CRAN submission preparation

**Expected Effort**: 12-16 hours **Complexity**: High

#### Version 1.1-1.9

**Category**: New Features - Add slider control for timeline - Add
animated/auto-start time steps for timeslices - Add animation export

### Quick Start

1.  Load latest version: `source("quickmap.R")` (v0.9.0)
2.  Test with: `source("tests/test_step4_styling_type.R")` (validates v0.9.0)
3.  Review documentation: Read `CLAUDE.md` for full system understanding
4.  Check migration guide: See quickmap.R header lines 39-68 for v0.8.x → v0.9.0
5.  Check task status: Review `PROJECT_STATUS_SUMMARY.md` (this document) for
    current priorities

### Development Workflow

1.  **Create new version**: Copy `quickmap.R` to `versions/quickmap_0_8_X.R`
2.  **Implement changes**: Follow patterns established in Task 1E/1E.1
3.  **Test thoroughly**: Use test scripts in `tests/` directory
4.  **Document changes**: Update version history in file header
5.  **Commit to git**: Use descriptive commit messages with Claude attribution
6.  **Update main**: Copy working version back to `quickmap.R` when stable

### Key Functions to Understand

-   `create_pollution_map()` - Main entry point
-   `apply_custom_layout_in_html()` - Banner/legend processing
-   `generate_map_layers()` - Unified layer generation
-   `create_generic_icons()` - Marker creation with scaling
-   `add_layer()` - Universal layer addition

### Testing Approach (v0.9.0)

-   Use `tests/test_step4_styling_type.R` for v0.9.0 validation
-   Test parameter renames: `tests/test_step1_renames.R`
-   Test merged parameters: `tests/test_step2_export_image.R`, `tests/test_step3_title.R`
-   Test with actual data file:
    `~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv`
-   Verify scaling across small (800x600), standard (1200x1200), and large
    (1920x1080) dimensions
-   Check both interactive HTML and static JPG outputs
-   All tests create actual map outputs for visual verification

### Important Notes (v0.9.0)

-   **BREAKING CHANGES**: v0.8.x scripts require migration (see quickmap.R lines 39-68)
-   Parameter name: Use `years = 2024` (renamed from `years_to_plot`)
-   Image export: Use `export_image = c(1920, 1080)` (merged 3 parameters)
-   Styling: Use `styling_type = "html"` or `"none"` (merged 4 parameters)
-   Scaling calculation: Uses geometric mean for balanced scaling across aspect
    ratios
-   Symbol proportions: 1.3:1 ratio with text for optimal visual balance
-   Parameter count: 14 (reduced from 21, 33% reduction)

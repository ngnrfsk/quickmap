---
editor_options: 
  markdown: 
    wrap: 72
---

# ⚠️ DEPRECATED - DO NOT USE ⚠️

**This file is deprecated as of 2025-10-24.**  
**All issue tracking has been consolidated into `PROJECT_STATUS_SUMMARY.md`**  
**Please use that file as the authoritative source for project status.**

------------------------------------------------------------------------

# QuickMap Project - All Tasks Log (DEPRECATED)

**Last Updated**: 2025-10-24 **Current Working Version**: v0.8.10

⚠️ **Note**: This file is superseded by PROJECT_STATUS_SUMMARY.md. See that file for current status.

------------------------------------------------------------------------

### FUTURE REFACTORING TASKS

#### Refactor-2: Database Import and Modular Architecture
**Category**: Architecture **Description**: Enhance codebase with modern R practices
- Add database import using duckdb
- Divide code into standalone modules: IO, data processing, map layer generation, map rendering, utility functions
- Replace existing hardcoded layer creation with new generic layer system
- Rebuild create_pollution_map() function as a wrapper using new system
**Expected Effort**: 12-16 hours **Complexity**: High

#### Minor Bugs to Fix and Features to Consider
**Category**: Code Quality **Description**: Various improvements and optimizations
- Replace tick box control with slider for many years
- Add data caching to avoid repeated data loading
- Develop uniform text sizing approach across codebase (coordinate with map size)
- Remove stray temporary HTML files on image generation (eliminate _files folders)
- Simplify and clarify all function names for consistency
- Rename parameters and restructure using ggplot-type approach
- Add animations capability
- Performance and scalability (lazy loading, batch processing)
- User experience enhancements (clustering, custom popups, export formats)
- Error handling and robustness (validation, logging, graceful failures)
**Expected Effort**: 8-12 hours total

------------------------------------------------------------------------

### CRITICAL TASKS

#### Critical-1: Boundary Labels Control

**Completed Date**: 2025-10-16 
**Code Version**: v0.8.8 
**Git Status**: Checked into Git and GitHub (commit: be80921) 
**Description**: Added
configurable boundary labels to allow users to show or hide borough
names on maps 
**Key Changes**: 
- Added show_boundary_labels boolean parameter (TRUE/FALSE) 
  - TRUE shows borough boundary labels on both HTML and static maps 
  - FALSE hides labels (default, maintains backward compatibility) 
- Modified add_boundary_polygons() to support label
visibility 
- Labels use consistent styling with noHide=TRUE 
- Note:
Hover-only labels not viable due to layer order (markers cover polygons)
**Files Modified**: `quickmap.R`, `versions/quickmap_0_8_8.R`
**Estimated Effort**: 3 hours (actual)

#### Critical-1: Task UX: Marker Labels Control

**Category**: UI Enhancement 
**Description**: Show marker labels to depend on new create_pollution_map parameter show_measurement_labels
choice of {on, off or auto-hide}. This could done passing into add_layer
function. Make behaviour for static and dynamic maps the same.
**Impact**: Essential to suppress unwanted labels in current maps.
**Expected Effort**: unknown 
**Dependencies**: None

#### Critical-2: Bug 4: Duplicate Legend on screen created inside leaflet map 🔴

**Status**: NOT STARTED **Priority**: CRITICAL **Category**: Bug Fix +
UX **Description**: Duplicate Legend sometimes appears on screen inside
leaflet map as the Leaflet legend is still sometimes being added via
addLegendImage in add_map_control **Blocks** Map creation for online
users and LCA website launch

------------------------------------------------------------------------

### PRE-LCA LAUNCH ESSENTIAL TASKS (High Priority)

#### High-1: Correct issues with subfolder generation in aqmaps

**Category**: leaflet temporary files not removed

**Description:** static image generation creates unwanted subfolders
containing leaflet related JS libraries and files. This should not be
happening and may be due to a leaflet bug. **Impact:** Means code is not
release-ready for packaging

#### High-2: Simplify marker, text and legend size logic

**Category**: UX Enhancement **Description**: Create a simple, unified
scaling system for markers, text, and legends based on image dimensions.
**Impact**: Addressed bugs such as legend markers being tiny when width
ro height ratio on image export is 1.4. Resolves inconsistent sizing
across different map types and sizes **Expected Effort**: unknown
**Blocks**: launch of the code package

#### High-3: Task UX-1: Fix Zoom Level on Map Open 🟡

**Category**: UX Enhancement **Description**: Ensure markers fill screen
with no wide or tall empty borders when map opens **Impact**: Poor
initial user experience with wasted screen space **Expected Effort**:
2-3 hours **Blocks**: Website launch

#### High-4: Task UX-4: Harmonize Ward and Marker Labeling 🟡

**Category**: UX Enhancement **Description**: Make ward and marker
labels consistent between static and interactive maps **Impact**:
Inconsistent user experience between output types **Expected Effort**:
2-3 hours **Blocks**: Website launch

#### High-5: Task UX-5: Collapsible Radio Buttons 🟡

**Category**: UI Enhancement **Description**: Make radio buttons
collapse and move to bottom left corner **Impact**: Screen space
optimization, improved mobile experience **Expected Effort**: 2-3 hours
**Blocks**: Website launch

#### Other tasks

-   Review the note “Breakdown of the mapping problem” #mapping
-   Why do the points not show sometimes if there’s no label?
-   Why do BL points show value despite values being switched off?
-   Investigate if Plotly, Mapbox or others are the best choice for
    aninating the maps
-   Later new functionality
    -   Add animations
    -   Add slider controls
    -   Add pollutant selectors

------------------------------------------------------------------------

### IMPORTANT PRE-LAUNCH TASKS (Medium Priority)

#### Medium-1: Task UX-7: Tooltip Labels from Data 🟢

**Category**: UI Enhancement **Description**: Use label value in data as
tooltips for markers if parameter set with auto-hide **Impact**:
Enhanced interactivity and information display **Expected Effort**: 2-3
hours **Dependencies**: None

------------------------------------------------------------------------

### PRE-LCA RELEASE TASKS (Lower Priority)

#### Low-1: Task Feature-1: Select Start Layer 🟢

**Category**: Feature Enhancement **Description**: Allow users to
specify which layer is visible on initial map load **Expected Effort**:
2-3 hours

#### Low-2: Task Arch-1: Split Data Import and Map Creation 🟢

**Category**: Architecture **Description**: Consider separating data
loading from map generation for better code organization **Expected
Effort**: 3-4 hours **Note**: Only if it simplifies other tasks

#### Low-3: Task Feature-2: Automate Label Location 🟢

**Category**: Feature Enhancement **Description**: Automate label
location, clustering, and spread for optimal readability **Expected
Effort**: 6-8 hours **Complexity**: High

#### Low-4: Task Package-1: Prepare for R Library Packaging 🟢

**Category**: Packaging **Description**: Structure code and
documentation for packaging as an R library **Expected Effort**: 12-16
hours **Dependencies**: Task 3A (Modular Architecture)

------------------------------------------------------------------------

### CODE QUALITY AND REFACTORING TASKS

#### Refactor-1: Task 1A: Complete Code Cleanup and TODO Resolution

**Category**: Code Quality **Description**: Remove technical debt,
resolve TODOs, clean up commented code **Key Actions**: - Remove 150+
lines of dead code (8% of file) - Fix critical TODOs causing crashes
(boroughs parameter, error trapping) - Remove debug print statements -
Move version history to CHANGELOG.md - Standardize documentation
**Expected Effort**: 4-5 hours **Risk Level**: Low-Medium **Files**:
`quickmap.R`

#### Refactor-2: Task 2ABC: Comprehensive Configuration System Enhancement

**Category**: Architecture **Description**: Create robust, multi-layered
configuration system **Phases**: - Phase 1: Parameterize hardcoded
values - Phase 2: Config file system (YAML/JSON) - Phase 3: Parameter
validation system **Expected Effort**: 6-8 hours **Complexity**: Medium

#### Refactor-3: Task 3A: Modular Architecture Enhancement

**Category**: Architecture **Description**: Split monolithic quickmap.R
into focused, maintainable modules **Proposed Modules**: -
`R/data_io.R` - Data loading and transformation -
`R/data_processing.R` - Filtering and spatial operations -
`R/layer_generation.R` - Icon and layer creation -
`R/styling_rendering.R` - Map styling and controls - `R/html_export.R` -
HTML processing and export - `R/config.R` - Configuration and color
scales - `R/utils.R` - Utilities and helpers **Expected Effort**: 8-12
hours **Complexity**: High

#### Refactor-4: Task 4B: Modern R Practices Implementation

**Category**: Code Quality **Description**: Modernize codebase with
contemporary R development practices **Key Areas**: - Tidyverse
consistency - Comprehensive error handling - Structured logging system -
Testing infrastructure (testthat) - Code quality tools (styler, lintr) -
Performance monitoring **Expected Effort**: 12-16 hours **Complexity**:
High

------------------------------------------------------------------------

## COMPLETED Issues

#### Task 1E.1: Fix Legend Text and Marker Scaling Issues

**Completed Date**: 2025-10-15 **Code Version**: v0.8.7.1 **Git
Status**: Checked into Git and GitHub (commit: aa56fc2) **Description**:
Fixed scaling problems where legend text and marker sizes didn't scale
appropriately across different image dimensions **Key Changes**: -
Improved scale factor calculation using geometric mean - Added layout
dimension scaling for padding, gaps, and legend height - Implemented
marker size scaling based on image dimensions - Fixed legend data text
scaling issues **Files Modified**: `quickmap_0_8_7.R` **Estimated
Effort**: 2.5-3 hours (actual)

#### Bug 2: Missing Data Filter Integration (includes NO2 and PM2.5)

**Category**: Bug Fix + Data Preparation **Description**: Sites with
\>20% missing data should display as white disks with no value. Requires
calculating missing data percentages for BOTH NO2 and PM2.5 from hourly
data and adding `missing_no2` and `missing_pm25` columns to
`dataOAformat`. Implements pollutant-specific filtering. **Impact**:
Misleading data displayed on maps without proper quality indicators
**Expected Effort**: 3-4 hours (includes data preparation for both
pollutants) **Blocks**: Website launch preparation **Files to Create**:
`prepare_bl_data_with_missing.R` (calculates both NO2 and PM2.5 missing
%) **Files to Modify**: `quickmap.R` (add filtering logic) **Files to
Reference**: `missing_data_stats.R` (PM2.5 example),
`tasks/bug_2_missing_data_filter_implementation_plan.md` **Output
File**: `bl_imperial_annualised_2021_2025_with_missing.Rdata` (with both
missing_no2 and missing_pm25 columns)

#### Bug 0: Markers are too small in static maps compared to HTML maps

**Status**: COMPLETED **Priority**: CRITICAL **Category**: Bug Fix + UX
**Description**: Markers in static maps exported as images are too
small, significantly smaller than the dynamic maps. Correct so that they
scale using the same approach. **Solution**: Increased base marker sizes
in `create_generic_icons()` function (schools: 8→12, dt_sites/bl_nodes:
15→20). **Future Enhancement**: See
`tasks/bug_0_marker_scaling_fix_plan.md` for comprehensive unified
scaling approach.

#### Bug 3: Legends are too big in standard size maps on screen

**Completed Date**: 2025-10-15 **Code Version**: v0.8.7.1 **Category**:
Bug Fix + UX **Description**: The legend object it taking up too much
vertical space on screen as the markers in the legend are larger than
the markers on the map and the gaps and padding are too big.

#### Bug 1: CSV File Path Handling Issue

**Completed Date**: 2025-10-15 **Code Version**: v0.8.7.3 **Category**:
Bug Fix **Description**: CSV files require full paths while RData files
work correctly with `DATA_PATH` environment variable **Impact**: Manual
work required, inconsistent file handling between CSV and RData
**Expected Effort**: 1-2 hours **Blocks**: Website launch preparatiom

#### Task UX-2: Extend Vignette Overlay 🟡

**Category**: Visual Enhancement **Description**: Prevent gaps between
vignette overlay and map edge on very wide or tall maps **Impact**:
Visual consistency issues on different screen sizes **Expected Effort**:
1-2 hours **Blocks**: Website launch

# Uncategorise (may already be in list above)

-   check why the paths don't work correctly for CSV files

-   fix zoom level so that on open the map is zoomed in such that
    markers fill the screen and there are no wide or tall empty borders

-   Ensure that the addControl legend is removed unless it can be used
    to show the year on static images

-   Revise the code approch so choice is dynamic XOR static map
    generation

-   harmonise approach to ward and marker labelling between the static
    and interactive/dynamic maps

-   Use value labels as tooltips with auto-hide

-   Make radio buttons collapse and move to other corner

-   Maps finalisation

    -   Do an up-to-date schools maps for Patrick

    -   Generate the trial maps using the stable Diffusion Tube dataset

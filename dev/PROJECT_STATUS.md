---
editor_options: 
  markdown: 
    wrap: 80
---

# QuickMap Project Status Summary

**Last Updated**: 2026-07-05 **Current Working Version**: v0.9.4 **Branch**: feature/v093-openair-converter

--------------------------------------------------------------------------------

### Bug (fold into UI defect #9, roadmap item 10): image-mode CSS text scaling silently inert — 2026-07-05
The `image_mode` branch of `inject_banner_legend_controls()` passes regex-escaped
patterns (e.g. `"1\\.8rem"`) to `apply_template_replacements()`, which matches with
`fixed = TRUE` — the escaped backslash never matches, so none of the static-export
banner/legend font-scaling substitutions apply. Even unescaped, the list is
order-broken: the bare `"1rem"` pattern would consume `"padding: 1rem"` and
`"gap: 1rem"` before their own patterns run, and some patterns don't exist in the
image CSS variants at all (e.g. `1.3rem` is only in banner-interactive.css).
Static exports have been rendering at baseline text sizes regardless of image
dimensions. Repair belongs to the unified scaling work (UI defect #9, roadmap
item 10) — do not patch piecemeal. Found 2026-07-05 while adding fail-loud anchor
checks (dev/260705_risk_handlers_plan.md, handler 3.1).

### Autonomous permissions hardened — 2026-07-05
Branch `chore/autonomous-permissions`. The 2026-07-04 (~21:00) trial autonomous
run — the roadmap item 1 packaging agent, transcript recovered — died on
permission prompts (tilde-in-assignment heuristic, cd-compounds, loops with
command substitution; allowlist living only in settings.local.json). Added committed `.claude/settings.json` (DATA_PATH env,
72-rule allowlist, deny rules guarding main, acceptEdits) and a verified
PreToolUse hook that turns commits on main into a human-approval prompt.
CLAUDE.md gained a "Permissions and command style" section; the pre-test idea
was adopted and upgraded to dev/260705_permissions_pretest.md (human runs it
interactively before the next autonomous session). Full investigation:
dev/260705_autonomous_permissions_plan.md.

### Housekeeping: _gem docs archived, repo root cleaned — 2026-07-05
Branch `chore/risk-handlers`. CLAUDE_gem.md / PROJECT_STATUS_gem.md archived to
dev/archive/ after harvesting unique content into CLAUDE.md (positioning
statement, API principles). MapLibre experiment files moved to dev/ as evidence
for roadmap item 5 (backend decision). Root YAML duplicates of inst/ copies
deleted; root airstat_no2.yaml actually held a deltas scale — archived as
mislabelled_deltas_scale.yaml. Fail-loud checks added to HTML injection anchors
and {{placeholder}} substitution (risk handler 3.1).

### Added: quickmap_reference vignette — 2026-07-04
`vignettes/quickmap_reference.md` — plain markdown quick-reference for `create_pollution_map()`.
Covers: all parameters with defaults and descriptions, `display_times` format table, colour
scale catalogue, and full column-by-column tables for both CSV and RData input formats (traced
from source). Includes `Label` silent-drop gotcha. Committed on `feature/v093-openair-converter`.

### Bug (priority): Sourced-script path resolution — 2026-03-13
quickmap is sourced as a script so system.file() returns "" and all inst/ paths fall back to
fragile relative paths anchored to the working directory. Cascading effects: working directory
must be quickmap root; theme_file requires full paths and fails silently; colour_scale = NULL
hardcoded for static layers in add_layer. Fix: install as a proper R package via
devtools::install() — directory structure already matches conventions, DESCRIPTION and NAMESPACE
are the main additions needed.

### Bug: import_csv_data does not accept ... so na.strings from load_data_file errors — 2026-03-13
Fix: remove na.strings from load_data_file call; consolidate the two near-identical defaults
directly into import_csv_data.

### Added: geocode_uk_postcodes() — 2026-03-13
Bulk postcode geocoder added to quickmap.R. Uses postcodes.io bulk POST API (100 per request).
Falls back to terminated postcodes endpoint for retired postcodes, converting WGS84 → OSGB36
via sf. Flags terminated postcodes with a NOTE message.

### Fixed — 2026-03-13
- import_csv_data rejects static label-only CSVs: skip value columns check when static = TRUE
- create_generic_icons hardcodes two colours: load from load_yaml_config(colour_scale, subdirectory = "scales")
- na.strings ... threading error: resolved

## v0.9.3 OpenAir Converter (Current)

**Status**: Active development
**Branch**: `feature/v093-openair-converter`
**Implementation Plan**: `dev/archive/251126_Implementation_v093_OpenAir_Converter.md`

**Key Features (v0.9.3.x)**:
- OpenAir converter functions (importUKAQ, importAURN, importKCL)
- Duck typing for data loading (columns, not filenames)
- RData flexible loading (standard names → any compatible data.frame)
- Type-aware symbol defaults (solid for temporal, non-solid for static)
- Categorical color fixes for schools layer

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

**Detailed Documentation:** Archived

#### Unified Architecture

-   **Interactive maps**: Use HTML post-processing for banners/legends
-   **Static maps**: Use same HTML post-processing before JPG conversion
-   **Marker scaling**: Different sizes for different image dimensions
-   **Single code path**: No more duplicate legend systems

## Current State Summary

### What Works (v0.9.3.21)

-   OpenAir converter functions for UK air quality networks
-   Duck typing: data detected by columns (School, Label, year), not filenames
-   RData loading: standard names first, then any compatible data.frame
-   Simplified API: `data_sources` list replaces individual file params
-   Unified HTML banner/legend system across interactive and static maps
-   Type-aware symbols: solid shapes for temporal, non-solid for static
-   18 test scripts in `tests/` directory

## Outstanding Issues

### CRITICAL: HTML File Size Bloat (Scalability Blocker)

**Design Doc:** `dev/20250118_geojson_option_d_design.md`

**Problem:** HTML files grow to 27MB+ with many markers × time slices, causing slow load times and browser memory issues.

**Root Cause:** Leaflet's R bindings serialize icon SVGs per-marker per-call:
- 180 `addMarkers()` calls (time slices × layers)
- Icons deduplicated within call, but **repeated across calls**
- Same 11 icon SVGs × 180 calls = ~2000 redundant icon definitions
- Per-marker: ~400 bytes (embedded SVG) vs ~30 bytes (coordinates only)

**Scale Impact:**
| Markers | Time Slices | Current Size | With Fix |
|---------|-------------|--------------|----------|
| 100 | 10 | ~1 MB | ~100 KB |
| 500 | 50 | ~10 MB | ~750 KB |
| 500 | 200 | ~27 MB | ~2 MB |

**Proposed Fix (Option D):** GeoJSON + client-side JS styling
- R sends raw coordinates + values as GeoJSON (~30 bytes/marker)
- JavaScript applies icons at render time using cached SVG templates
- Estimated reduction: **90%** (27MB → 2-3MB)

**Implementation Impact:**
- Significant refactor of `create_generic_icons()` and `add_layer()`
- Estimated effort: 2-3 days
- Could implement as optional backend: `create_pollution_map(..., backend = "geojson")`

**Status:** Design complete, not implemented. Blocking for production use with sub-annual data.

--------------------------------------------------------------------------------

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

#### Technical Debt: Prioritized Action List

**Analysis Date**: 2026-01-23

##### Priority 1: Quick Wins (1-2 hours, immediate value)

| Task | Location | Impact |
|------|----------|--------|
| Extract constants | Top of quickmap.R | `BASELINE_IMAGE_SIZE=1200`, `MOBILE_BREAKPOINT=480`, `DEFAULT_BANNER_COLOR="#2c3e50"` appear 5+ times each |
| Remove commented code | Lines 471-575 | Delete 104 lines of old `load_rdata_file()` implementation |
| Consolidate symbol lists | `get_measurement_layers()` + `validate_and_fix_icon_shape()` | Two separate lists of valid symbols; single source of truth needed |
| Standardize NULL pattern | Throughout | Use `%||%` operator consistently; currently 4 different patterns |

##### Priority 2: Error Handling (2-3 hours)

| Task | Current State | Target |
|------|---------------|--------|
| Consistent error style | Mix of `stop()`, `warning()+return`, `tryCatch`, silent NULL | Standardize: `stop(msg, call.=FALSE)` for fatal, `warning()` for recoverable |
| Entry-point validation | Errors caught late in pipeline | Validate data structure in `create_pollution_map()` before calling pipeline |
| Document failure modes | Silent failures possible | Each public function documents what happens on invalid input |

##### Priority 3: Parameter Threading (4-6 hours, prep for Refactor-5)

| Issue | Example | Solution |
|-------|---------|----------|
| 15-18 params through chain | `create_pollution_map → finalize_and_save_map → save_html_and_style` | Group into config objects: `styling_config`, `export_config` |
| Naming inconsistency | `export_image` vs `image_export` vs `image_mode` | Standardize: `export_*` for output params |
| Scale factor variants | `image_scale_factor`, `marker_scale_factor`, `label_sizing` | Single `scale_config` object |

##### Priority 4: Dead Code Removal (1 hour)

| Function | Status |
|----------|--------|
| `validate_oa_data()` | Defined but never called; logic in `convert_openair_to_spatial()` |
| `process_oa_data()` | Only called from commented code |
| `import_csv_data()` | Single caller; consider inlining |
| Unreachable branches | `year=="static"` check when value is `"static_only"` |

##### Priority 5: Long Functions (feeds into Refactor-5)

| Function | Lines | Issue |
|----------|-------|-------|
| `convert_openair_to_spatial()` | 187 | Split: validation, aggregation, sf conversion |
| `create_pollution_map()` | 184 | Split: setup, data loading, map generation, export |
| `load_rdata_file()` | 155 | Split: file loading, duck typing, processing |
| `inject_banner_legend_controls()` | 107 | Split: CSS scaling, HTML injection |

##### Debt Summary

| Category | Items | Est. Hours |
|----------|-------|------------|
| Quick wins | 4 | 1-2 |
| Error handling | 3 | 2-3 |
| Parameter cleanup | 3 | 4-6 |
| Dead code | 4 | 1 |
| Long functions | 4 | (Refactor-5) |
| **Total pre-refactor** | **14** | **8-12** |

--------------------------------------------------------------------------------

#### Version 1.1-1.9

**Category**: New Features - Add slider control for timeline - Add
animated/auto-start time steps for timeslices - Add animation export

### Quick Start

1.  Load latest version: `source("R/quickmap.R")` (v0.9.3.21)
2.  Test with: `source("tests/test_quickmap.R")`
3.  Review documentation: `CLAUDE.md` for system overview
4.  Check dev docs: `dev/` folder for plans and implementation details

### Development Workflow

1.  **Create branch**: Feature branches like `feature/v09X-feature-name`
2.  **Implement changes**: Follow patterns in existing code
3.  **Test thoroughly**: Use test scripts in `tests/` directory
4.  **Document changes**: Update version in `CLAUDE.md` and commit messages
5.  **Archive version**: Copy to `versions/quickmap_X_X_X.R` when stable

### Key Functions to Understand

-   `create_pollution_map()` - Main entry point
-   `apply_custom_layout_in_html()` - Banner/legend processing
-   `generate_map_layers()` - Unified layer generation
-   `create_generic_icons()` - Marker creation with scaling
-   `add_layer()` - Universal layer addition

### Testing Approach (v0.9.3)

-   Core tests: `tests/test_quickmap.R`, `tests/test_comprehensive_5network.R`
-   Converter tests: `tests/test_aurn_converter.R`, `tests/test_laqn_converter.R`
-   Duck typing tests: `tests/test_rdata_duck_typing.R`, `tests/test_school_labels_fix.R`
-   All tests create actual map outputs for visual verification

### Important Notes (v0.9.3)

-   **API**: Use `data_sources` list for all data files
-   **Duck typing**: Data types detected by columns, not filenames
-   **RData**: Loads from standard names or any compatible data.frame
-   See `CLAUDE.md` for current API examples

# QuickMap Project Status Summary
**Last Updated**: 2025-10-24 **Current Working Version**: v0.8.10

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




### Completed Fixes

#### Issue 1: Boundary Labels Control (v0.8.8)
- Added `show_boundary_labels` parameter (TRUE/FALSE)
- Modified `add_boundary_polygons()` for label visibility

#### Issue 2: Banner and Legend System Unification (v0.8.7)
- Unified banner/legend system between HTML and static maps
- Extended `apply_custom_layout_in_html()` with `image_mode` parameter

#### Issue 3: Banner and Legend Scaling (v0.8.7.1)
- Fixed scale factor calculation using geometric mean
- Added marker size scaling throughout layer generation

#### Issue 4: Legend Size Issues (v0.8.7.3)
- Reduced legend marker sizes relative to map markers
- Improved gaps and padding in legend layout

#### Issue 6: Marker Labels Control (v0.8.9)
- Added `show_marker_labels` parameter with 5-state control
- Unified label behavior across OA, CSV, and Schools data sources
- Added `generate_marker_labels()` helper function
- Breaking change: `use_data_labels` parameter removed

#### Issue 5: File Organization (2025-10-15)
- Moved version files to `versions/` directory
- Moved test files to `tests/` directory
- Moved utility scripts to `scripts/` directory

#### Issue 7: Marker Labels Fix (v0.8.10)
- Fixed schools label behavior to respect show_marker_labels parameter
- Fixed OA data label fallback when Label column missing
- All data sources now have consistent label behavior

### Historical Completed Tasks

#### Task 1E.1: Fix Legend Text and Marker Scaling Issues (2025-10-15, v0.8.7.1, commit: aa56fc2)
- Fixed scaling problems where legend text and marker sizes didn't scale appropriately
- Improved scale factor calculation using geometric mean
- Added layout dimension scaling for padding, gaps, and legend height
- Implemented marker size scaling based on image dimensions
- Added image_scale_factor parameter throughout layer generation chain
- All elements now scale consistently with image size
- Fixed legend symbol proportions (1.3:1 ratio)

#### Bug 0: Markers too small in static maps (COMPLETED)
- Increased base marker sizes (schools: 8→12, dt_sites/bl_nodes: 15→20)
- Markers now scale consistently across HTML and static exports

#### Bug 1: CSV File Path Handling (2025-10-15, v0.8.7.3)
- Fixed CSV file path handling to be consistent with RData files
- Added DATA_PATH environment variable support for relative CSV paths
- Resolves inconsistency where CSV files required full paths

#### Bug 2: Missing Data Filter Integration
- Sites with >20% missing data display as white disks
- Added MISSING_DATA_THRESHOLD constant (20%)
- Implemented in process_oa_data() function
- Requires enriched data file with missing_no2 and missing_pm25 columns

#### Bug 3: Legends too big in standard size maps (2025-10-15, v0.8.7.1)
- Reduced legend marker sizes relative to map markers
- Improved gaps and padding in legend layout

#### Unified Architecture
- **Interactive maps**: Use HTML post-processing for banners/legends
- **Static maps**: Use same HTML post-processing before JPG conversion
- **Marker scaling**: Different sizes for different image dimensions
- **Single code path**: No more duplicate legend systems


## Current State Summary

### What Works
- Unified banner/legend system across interactive and static maps
- Proportional scaling for all image dimensions
- Marker size scaling based on image dimensions
- Backwards compatibility with existing function calls
- Git version control with documentation
- Organized file structure

### Testing Status
- `tests/test_scaling_simple.R` works correctly
- Validated dimensions: 800x600, 1200x1200, 1920x1080
- Uses `years_to_plot = 2024` parameter correctly
- All test files updated for new directory structure

## Outstanding Issues

### Essential

7. Duplicate Legend - Leaflet legend still added via `addLegendImage` in `add_map_control`

### High Priority Issues
8. Subfolder Generation - Static image generation creates unwanted subfolders with leaflet JS libraries
9. Marker/Text/Legend Size Logic - Create unified scaling system for markers, text, and legends
10. Zoom Level on Map Open - Ensure markers fill screen with no empty borders
11. Ward and Marker Labeling Consistency - Make ward and marker labels consistent between static and interactive maps
12. Collapsible Radio Buttons - Make radio buttons collapse and move to bottom left corner

### Medium Priority Issues
14. Select Start Layer - Allow users to specify which layer is visible on initial map load
4: Legend Size Issues (v0.8.7.3) this needs looking at again 

### Low Priority Issues
15. Split Import and Map Create - Separate data loading from map generation
16. Automate Label Location - Automate label location, clustering, and spread
17. Prepare for R Library Packaging - Structure code and documentation for R library packaging

### Code Quality and Refactoring Tasks

#### Refactor-1: Complete Code Cleanup and TODO Resolution
**Category**: Code Quality **Description**: Remove technical debt, resolve TODOs, clean up commented code
- Remove 150+ lines of dead code (8% of file)
- Fix critical TODOs causing crashes (boroughs parameter, error trapping)
- Remove debug print statements
- Standardize documentation
**Expected Effort**: 4-5 hours **Risk Level**: Low-Medium

#### Refactor-2: Comprehensive Configuration System Enhancement
**Category**: Architecture **Description**: Create robust, multi-layered configuration system
**Phases**: 
- Phase 1: Parameterize hardcoded values
- Phase 2: Config file system (YAML/JSON)
- Phase 3: Parameter validation system
**Expected Effort**: 6-8 hours **Complexity**: Medium

#### Refactor-3: Modular Architecture Enhancement
**Category**: Architecture **Description**: Split monolithic quickmap.R into focused, maintainable modules
**Proposed Modules**: 
- `R/data_io.R` - Data loading and transformation
- `R/data_processing.R` - Filtering and spatial operations
- `R/layer_generation.R` - Icon and layer creation
- `R/styling_rendering.R` - Map styling and controls
- `R/html_export.R` - HTML processing and export
- `R/config.R` - Configuration and color scales
- `R/utils.R` - Utilities and helpers
**Expected Effort**: 8-12 hours **Complexity**: High

#### Refactor-4: Modern R Practices Implementation
**Category**: Code Quality **Description**: Modernize codebase with contemporary R development practices
**Key Areas**: 
- Tidyverse consistency
- Comprehensive error handling
- Structured logging system
- Testing infrastructure (testthat)
- Code quality tools (styler, lintr)
- Performance monitoring
**Expected Effort**: 12-16 hours **Complexity**: High


### Quick Start
1. Load latest version: `source("quickmap.R")`
2. Test with: `source("tests/test_scaling_simple.R")`
3. Review documentation: Read `CLAUDE.md` for full system understanding
4. Check task status: Review `PROJECT_STATUS_SUMMARY.md` (this document) for current priorities

### Development Workflow
1. **Create new version**: Copy `quickmap.R` to `versions/quickmap_0_8_X.R`
2. **Implement changes**: Follow patterns established in Task 1E/1E.1
3. **Test thoroughly**: Use test scripts in `tests/` directory
4. **Document changes**: Update version history in file header
5. **Commit to git**: Use descriptive commit messages with Claude attribution
6. **Update main**: Copy working version back to `quickmap.R` when stable

### Key Functions to Understand
- `create_pollution_map()` - Main entry point
- `apply_custom_layout_in_html()` - Banner/legend processing
- `generate_map_layers()` - Unified layer generation
- `create_generic_icons()` - Marker creation with scaling
- `add_layer()` - Universal layer addition

### Testing Approach
- Use `tests/test_scaling_simple.R` for basic validation
- Test with actual data file: `~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv`
- Verify scaling across small (800x600), standard (1200x1200), and large (1920x1080) dimensions
- Check both interactive HTML and static JPG outputs
- Run comprehensive tests: `tests/test_task_1e_1_scaling_fixes.R`

### Important Notes
- Parameter name: Use `years_to_plot = 2024`, not `years = 2024`
- Scaling calculation: Uses geometric mean for balanced scaling across aspect ratios
- Symbol proportions: 1.3:1 ratio with text for optimal visual balance
- Backwards compatibility: All existing function calls continue to work
# QuickMap Modernization Outline Plan
**Date**: 2025-11-18
**Current Version**: 0.9.0.2
**Status**: Planning Phase - No Coding

---

## Executive Summary

QuickMap has a solid architectural foundation with a unified layer processing pipeline. The main modernization opportunities focus on:
1. **CSS/JS extraction** and configuration management
2. **Code organization** through modular architecture
3. **Documentation streamlining** for v0.9.1+ development

This plan builds on existing refactoring work (legend refactor plan, v0.9.0 parameter simplification) and provides a roadmap for evolving toward v1.0.

---

## I. CSS/JS MODERNIZATION

### Current State Analysis

**Strengths:**
- Roller menu control properly extracted to `inst/controls/` (good pattern)
- Dynamic color system with `lighten_color()` utility
- Responsive design with mobile-first approach

**Issues:**
- Banner/legend CSS still inline (lines 1076-1349)
- 14+ positional `sprintf()` placeholders (fragile, error-prone)
- Color scales hardcoded in R (250 lines, lines 524-774)
- Inconsistent approach: roller menu external, banner/legend embedded

### Proposed Solutions

#### 1.1 Complete CSS/JS Extraction (HIGH PRIORITY)
**Status**: Partially covered in existing legend refactor plan
**Effort**: 3-4 hours
**Impact**: HIGH

**Actions:**
- ✓ **STEP 1-3 of legend refactor plan** already addresses this
  - Extract banner CSS → `inst/banner/banner.css`
  - Extract legend CSS → `inst/legend/legend.css`
  - Extract legend HTML → `inst/legend/legend.html`
- Follow roller menu pattern: external files + loader functions
- Migrate from positional to **named placeholders** in sprintf

**Example Pattern:**
```r
# Current (fragile):
sprintf(css, color1, color2, color3, ...)  # Which is which?

# Proposed (clear):
css_content <- readLines("inst/banner/banner.css")
css_content <- gsub("{{banner_bg}}", banner_colour, css_content)
css_content <- gsub("{{header_bg}}", header_bg, css_content)
# Named placeholders self-document
```

#### 1.2 Configuration File System (MEDIUM PRIORITY)
**Target Version**: v0.9.2-0.9.3
**Effort**: 4-6 hours
**Impact**: MEDIUM

**Option A: YAML Color Scales** (Recommended)
```yaml
# inst/config/scales/who_no2.yaml
name: "who_no2"
title: "NO2 annual mean, µg/m³"
pollutant: "no2"
shape: "circle"
thresholds: [0, 10, 20, 30, 40, 50, 100, 200]
colours: ["#0066cc", "#00cc66", "#ffff00", "#ff9900", "#ff0000", "#990000", "#660000"]
labels:
  - "< 10: WHO guideline (excellent)"
  - "10-19: Good"
  # ... etc
```

**Benefits:**
- Non-programmers can create/modify scales
- Version control friendly (one file per scale)
- Easy to share between projects
- Validation via schema

**Option B: JSON Color Scales** (Alternative)
- More universal format
- Better for web integration
- Requires JSON schema for validation

**Option C: Keep R Lists** (Status Quo)
- No migration needed
- R-native approach
- Already works well
- Consider this if YAML/JSON adds complexity without clear benefit

**Implementation:**
```r
# New function in R/config.R
load_colour_scale <- function(scale_name) {
  yaml_file <- system.file("config/scales",
                          paste0(scale_name, ".yaml"),
                          package = "quickmap")
  if (file.exists(yaml_file)) {
    return(yaml::read_yaml(yaml_file))
  }
  # Fallback to hardcoded scales
  return(colour_scales[[scale_name]])
}
```

#### 1.3 External Theme System (LOW PRIORITY)
**Target Version**: v0.9.4+
**Effort**: 3-4 hours
**Impact**: LOW-MEDIUM

**Concept**: Users can provide custom theme files

```yaml
# user_theme.yaml
banner:
  background: "#8b4789"  # Merton purple
  font_size: "1.3rem"
  padding: "1.25rem"

legend:
  background: "#f8f9fa"
  border_color: "#dee2e6"
  font_size: "0.875rem"

map:
  base_tiles: "CartoDB.Positron"
  zoom_level: 11
```

**Usage:**
```r
create_pollution_map(
  ...,
  theme_file = "user_theme.yaml"  # Optional parameter
)
```

**Benefits:**
- Corporate branding consistency
- Reusable themes across projects
- User customization without code changes

**Risks:**
- Increases API complexity
- Validation/error handling required
- May not be widely used

**Decision Point**: Implement only if user demand exists

#### 1.4 CSS Preprocessor Approach (LOW PRIORITY)
**Target Version**: v1.0+
**Effort**: 2-3 hours
**Impact**: LOW

**Current Pattern:**
```r
# R generates CSS dynamically via sprintf
custom_css <- "\n<style>
.banner {
  background: %s;
  font-size: 1.3rem;
}
</style>\n"
```

**Alternative: SCSS-like Template** (Not recommended for R package)
```scss
/* inst/styles/banner.scss.template */
.banner {
  background: {{banner_colour}};
  font-size: $font-size-base * 1.3;
  padding: $spacing-unit;
}
```

**Assessment:**
- **Not recommended** - Adds build complexity
- R's sprintf/gsub approach is adequate
- SCSS compilation requires external dependencies
- **Keep current approach** but use named placeholders

---

## II. CODE SIMPLIFICATION

### Current State Analysis

**Metrics:**
- Total lines: 2,679
- Main function (`create_pollution_map`): 334 lines (lines 2347-2680)
- Functions: 32 total, well-organized
- Color scale definitions: 250 lines
- Inline CSS generation: 273 lines

**Strengths:**
- Well-commented with clear sections
- Functional architecture (no hidden state)
- Consistent naming patterns
- Generic layer processing pipeline

**Opportunities:**
- `create_pollution_map()` does too much (setup, loading, filtering, generation, export)
- Layer iteration could use functional patterns (purrr)
- Inline comments could move to roxygen2 docs
- Some functions have high nesting depth (3-4 levels)

### Proposed Solutions

#### 2.1 Split `create_pollution_map()` (HIGH PRIORITY)
**Target Version**: v0.9.5-0.9.6
**Effort**: 6-8 hours
**Impact**: HIGH

**Current Structure (334 lines):**
```r
create_pollution_map <- function(...) {
  # Section 1: Setup & parameter unpacking (15 lines)
  # Section 2: Data loading (46 lines)
  # Section 3: Data filtering (12 lines)
  # Section 4: Data preparation (17 lines)
  # Section 5: Layer generation loop (143 lines)
  # Section 6: HTML post-processing (17 lines)
}
```

**Proposed Modular Structure:**
```r
# Main function becomes orchestrator (50-75 lines)
create_pollution_map <- function(...) {
  # Validate parameters
  params <- validate_map_parameters(...)

  # Load data
  data_list <- load_pollution_data(
    params$diffusion_tube_file,
    params$sensor_file,
    params$school_file,
    params$boroughs
  )

  # Process data
  processed_data <- process_pollution_data(
    data_list,
    vignette = params$vignette,
    pollutant = params$pollutant,
    years = params$years
  )

  # Create map
  map <- create_base_map(processed_data$boundary_sf)
  map <- add_pollution_layers(map, processed_data, params)

  # Export
  export_map(map, params)

  return(map)
}
```

**New Functions to Create:**
```r
# R/data_io.R (or keep in quickmap.R initially)
load_pollution_data()       # 40-60 lines
process_pollution_data()    # 30-50 lines

# R/map_creation.R (or keep in quickmap.R initially)
validate_map_parameters()   # 20-30 lines
create_base_map()           # 15-25 lines
add_pollution_layers()      # 60-80 lines (refactored from loop)
export_map()                # 40-60 lines

# R/config.R
get_default_parameters()    # 15-20 lines
```

**Benefits:**
- Each function has single responsibility
- Easier to test individual components
- Clearer error messages (know which stage failed)
- More maintainable long-term

**Approach:**
- Start with extraction (keep all in quickmap.R)
- Test thoroughly after each extraction
- Move to separate files in later version (v1.0)

#### 2.2 Functional Programming for Layer Iteration (MEDIUM PRIORITY)
**Target Version**: v0.9.6
**Effort**: 2-3 hours
**Impact**: MEDIUM

**Current Pattern:**
```r
# Lines 2527-2669: Imperative loop
for (yr in unique(years)) {
  html_map <- generate_map_layers(html_map, ...)

  if (image_export) {
    static_map <- static_map_template
    static_map <- generate_map_layers(static_map, ...)
    # ... export logic
  }
}
```

**Proposed Pattern (purrr-based):**
```r
library(purrr)

# Functional approach with reduce
html_map <- years %>%
  reduce(
    .init = base_map,
    .f = ~ generate_map_layers(.x, measurement_layers, .y, ...)
  )

# Static images with walk (side effects)
if (!is.null(export_image)) {
  years %>%
    walk(~ export_static_map(
      year = .x,
      layers = measurement_layers,
      params = export_params
    ))
}
```

**Benefits:**
- More declarative (what, not how)
- Easier to parallelize later (future_map)
- Clearer data flow
- Less mutable state

**Considerations:**
- Adds tidyverse dependency (already present)
- Team must be comfortable with functional patterns
- May be less intuitive for some R users

**Decision**: Implement if team embraces tidyverse style

#### 2.3 Move Comments to roxygen2 Documentation (MEDIUM PRIORITY)
**Target Version**: v0.9.7
**Effort**: 4-6 hours
**Impact**: MEDIUM

**Current State:**
- Inline comments throughout (good!)
- No roxygen2 function documentation
- No package-level docs

**Proposed:**
```r
#' Create Interactive Pollution Map
#'
#' Generates interactive Leaflet maps showing air quality data (NO2, PM2.5)
#' overlaid with school locations and borough boundaries. Creates both
#' interactive HTML maps and static JPG exports.
#'
#' @param diffusion_tube_file Path to CSV file with diffusion tube data.
#'   Requires columns: Easting, Northing, year columns (2017, 2018, ...).
#'   Use "none" to skip.
#' @param sensor_file Path to RData file with Breathe London sensor data.
#'   Must contain `dataOAformat` object. Use "none" to skip.
#' @param boroughs Character vector of borough names to map.
#' @param pollutant Pollutant to map. Options: "no2" (default), "pm25".
#' @param years Numeric vector of years to include. NULL = all available.
#' @param colour_scale Name of color scale to use. Options: "who_no2" (default),
#'   "lbw_no2", "gla_pm25", etc. See `names(colour_scales)` for full list.
#' @param export_image Image export dimensions as c(width, height).
#'   NULL (default) = no image export. Example: c(1920, 1080).
#' @param styling_type Layout style. Options: "html" (default) = banner/legend,
#'   "none" = map only.
#' @param marker_labels Show marker labels? Default: FALSE.
#' @param banner_colour Banner background color (hex or R color name).
#'   Default: borough_palettes$merton$purple.
#'
#' @return Leaflet map object. Side effects: Saves HTML file and optional JPG.
#'
#' @examples
#' \dontrun{
#' # Basic map
#' map <- create_pollution_map(
#'   diffusion_tube_file = "data/wandsworth_2024.csv",
#'   boroughs = "Wandsworth",
#'   years = 2024
#' )
#'
#' # With image export
#' map <- create_pollution_map(
#'   diffusion_tube_file = "data/wandsworth_2024.csv",
#'   sensor_file = "data/breathe_london.Rdata",
#'   boroughs = c("Wandsworth", "Merton"),
#'   export_image = c(1920, 1080),
#'   colour_scale = "who_no2"
#' )
#' }
#'
#' @seealso [colour_scales], [borough_palettes]
#' @export
create_pollution_map <- function(...) {
  # Function body
}
```

**Benefits:**
- Auto-generated help files (`?create_pollution_map`)
- Better IDE integration (autocomplete, inline help)
- Professional package appearance
- Required for CRAN submission

**Effort Breakdown:**
- Main function: 1 hour
- 31 other functions: 3-5 hours (many are simple)
- Package-level docs: 30 minutes

#### 2.4 Extract "Legend Engine" as Standalone Module (LOW PRIORITY)
**Target Version**: v1.0+
**Effort**: 6-8 hours
**Impact**: MEDIUM

**Concept:**
Legend system is sophisticated enough to be its own module/package

**Current Functions:**
- `generate_legend_html()`
- `convert_colors_to_hex()`
- `lighten_color()`
- `get_contrast_text_color()` (planned in legend refactor)
- `assign_colour()`
- `get_colour_legend()`

**Proposed Module:**
```r
# R/legend_engine.R (or separate package: quicklegend)

create_legend(
  scale,              # Color scale definition
  data_max = NULL,    # For trimming
  format = "vertical", # "vertical" | "horizontal"
  style = "disk",     # "disk" | "pill" (text on color)
  collapsed = FALSE   # Initial state
) -> legend_html
```

**Benefits:**
- Reusable in other mapping projects
- Testable in isolation
- Could be contributed to broader R ecosystem
- Cleaner quickmap.R

**Decision:**
Consider for v1.0+ if legend system continues to grow in complexity

---

## III. PREP FOR v0.9.1+

### Current Documentation State

**Strengths:**
- Excellent project documentation (CLAUDE.md, README.md)
- Comprehensive PROJECT_STATUS.md
- 39 markdown files in dev/ and vignettes/
- Detailed migration guides
- Well-commented code

**Issues:**
- 39 dev/ documentation files may be excessive
- Multiple overlapping planning documents
- Historical context scattered across files
- No GitHub Issues integration for tracking
- Version history embedded in source code

### Proposed Solutions

#### 3.1 Eliminate Redundant Documentation (HIGH PRIORITY)
**Target Version**: v0.9.1
**Effort**: 2-3 hours
**Impact**: MEDIUM

**Audit Current Documentation:**
```
dev/
├── PROJECT_STATUS.md           [KEEP] - Single source of truth
├── 20251116_legend_refactor_plan_1930.md  [KEEP] - Active plan
├── NOTE_config_refactor.md     [ARCHIVE?] - Covered in PROJECT_STATUS
├── archive/                    [KEEP] - Historical reference
├── reference/                  [KEEP] - Technical guides
└── utilities/                  [KEEP] - Helper scripts
```

**Action Plan:**
1. **Consolidate:**
   - Merge redundant status files into PROJECT_STATUS.md
   - Move completed planning docs to archive/
   - Keep only active plans in dev/ root

2. **Standardize Format:**
   - Use consistent template for planning docs
   - Follow format: `YYYYMMDD_topic_plan_HHMM.md`
   - Include status indicator in filename or frontmatter

3. **Create Documentation Index:**
   - `dev/README.md` with purpose of each file
   - Clear indication of what's current vs historical
   - Link to GitHub Issues for active work

**Proposed Structure:**
```
dev/
├── README.md                   [NEW] - Documentation index
├── PROJECT_STATUS.md           [KEEP] - Current state
├── active/                     [NEW] - Current planning docs
│   └── 20251116_legend_refactor_plan_1930.md
├── archive/                    [KEEP] - Completed work
├── reference/                  [KEEP] - Technical guides
├── templates/                  [NEW] - Planning templates
│   ├── planning_template.md
│   └── refactoring_template.md
└── utilities/                  [KEEP] - Helper scripts
```

#### 3.2 GitHub Issues Integration (HIGH PRIORITY)
**Target Version**: v0.9.1
**Effort**: 2-3 hours
**Impact**: HIGH

**Current State:**
- Issues tracked in PROJECT_STATUS.md (flat list)
- No prioritization system
- No assignment/tracking
- Hard to reference in commits

**Proposed Approach:**

**Issue Labels:**
```
Type:
- enhancement
- bug
- refactoring
- documentation

Priority:
- P0: Critical
- P1: High
- P2: Medium
- P3: Low

Component:
- css-js
- data-loading
- layer-generation
- export
- configuration

Version:
- v0.9.1
- v0.9.2
- v1.0
- future
```

**Issue Templates:**
```markdown
# Feature Request Template
## Description
[Clear description of feature]

## Motivation
[Why is this needed?]

## Proposed Solution
[High-level approach]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Effort Estimate
[Hours/complexity]
```

**Migration Plan:**
1. Create issues for all items in PROJECT_STATUS.md "Outstanding Issues"
2. Tag with appropriate labels
3. Add to project board (optional)
4. Link from PROJECT_STATUS.md: "See issue #123"
5. Keep high-level roadmap in PROJECT_STATUS.md

**Benefits:**
- Better tracking and prioritization
- Community can contribute
- Links in commits (`Closes #123`)
- Discussion history preserved

#### 3.3 Streamline Version History (MEDIUM PRIORITY)
**Target Version**: v0.9.1
**Effort**: 1-2 hours
**Impact**: LOW-MEDIUM

**Current State:**
- Version history in source code header (lines 39-135)
- 96 lines of historical context
- Growing with each version
- Duplicates git commit history

**Proposed:**
- **Short version history** in source code (10-15 lines)
- **Full changelog** in CHANGELOG.md (standard format)
- **Git tags** for releases

**Source Code Header (Streamlined):**
```r
#' QuickMap: Interactive Air Quality Mapping
#'
#' Version: 0.9.1
#' Last Updated: 2025-11-18
#' License: MIT
#'
#' See CHANGELOG.md for version history.
#' See CLAUDE.md for development guidelines.
#' See README.md for usage instructions.
```

**CHANGELOG.md (Standard Format):**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Issues integration for tracking

### Changed
- Documentation structure reorganization

## [0.9.0.2] - 2025-11-15

### Added
- Touch-friendly collapsible year menu with dynamic theming
- `lighten_color()` utility function for color manipulation

### Changed
- Year control moved to bottom-right for better mobile UX
- Dynamic color system derives all menu colors from banner_colour

### Fixed
- Year control positioning conflicts with attribution

## [0.9.0] - 2025-10-28

### Changed
- **BREAKING**: Parameter simplification (21 → 14 parameters)
- Renamed 6 parameters for clarity
- Merged 7 parameters into 3

### Removed
- Leaflet legend/title controls (replaced with HTML banner/legend)

See full history at: https://github.com/ngnrfsk/quickmap/releases
```

#### 3.4 Functional Programming Patterns (MEDIUM PRIORITY)
**Target Version**: v0.9.6-0.9.7
**Effort**: 4-6 hours
**Impact**: MEDIUM

**Current State:**
- Functional architecture (good foundation)
- Some imperative loops
- Mix of base R and tidyverse patterns

**Proposed Enhancements:**

**A. Use purrr for Layer Iteration** (covered in 2.2)

**B. Pipeline Data Processing:**
```r
# Current (procedural)
data <- load_data_file(file)
data <- filter_data(data, threshold)
data <- transform_coords(data)
data <- prepare_layer(data, config)

# Proposed (pipeline)
data <- file %>%
  load_data_file() %>%
  filter_data(threshold = threshold) %>%
  transform_coords() %>%
  prepare_layer(config = config)
```

**C. Consistent Error Handling:**
```r
# Use purrr::safely() for graceful failures
safe_load <- safely(load_data_file)

result <- safe_load(file)
if (is.null(result$error)) {
  data <- result$result
} else {
  message("Failed to load data: ", result$error$message)
  # Fallback or skip
}
```

**D. Validation with assertthat:**
```r
library(assertthat)

validate_map_parameters <- function(params) {
  assert_that(
    is.character(params$boroughs),
    length(params$boroughs) > 0,
    msg = "boroughs must be a non-empty character vector"
  )

  assert_that(
    is.null(params$years) || is.numeric(params$years),
    msg = "years must be NULL or numeric vector"
  )

  # ... more validations

  params  # Return if all pass
}
```

**Benefits:**
- Clearer data flow
- Better error messages
- Easier to test
- More maintainable

#### 3.5 Database Integration Prep (LOW PRIORITY)
**Target Version**: v1.0+
**Effort**: 8-12 hours
**Impact**: MEDIUM-HIGH (if implemented)

**Context:** PROJECT_STATUS mentions duckdb integration

**Current Data Flow:**
```
CSV files + RData files → Load into R → Process → Map
```

**Proposed with Database:**
```
CSV/RData → Import to DuckDB → Query → R sf objects → Map
```

**Benefits:**
- Faster queries on large datasets
- SQL-based filtering (more efficient)
- Single data source (no CSV + RData juggling)
- Better multi-user scenarios
- Caching of processed data

**Implementation Outline:**
```r
# New function: import_to_duckdb()
import_to_duckdb <- function(csv_files, rdata_files, db_path = ":memory:") {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)

  # Import CSV files
  for (csv in csv_files) {
    data <- read.csv(csv)
    DBI::dbWriteTable(con, "diffusion_tubes", data, append = TRUE)
  }

  # Import RData files
  for (rdata in rdata_files) {
    load(rdata)
    DBI::dbWriteTable(con, "sensors", dataOAformat, append = TRUE)
  }

  return(con)
}

# Modified load_pollution_data()
load_pollution_data <- function(..., use_database = FALSE, db_path = NULL) {
  if (use_database && !is.null(db_path)) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)

    # Query instead of file loading
    query <- "
      SELECT * FROM diffusion_tubes
      WHERE year IN (?) AND borough IN (?)
    "
    data <- DBI::dbGetQuery(con, query, params = list(years, boroughs))

    DBI::dbDisconnect(con)
    return(data)
  } else {
    # Current file-based loading
    ...
  }
}
```

**Considerations:**
- Adds dependency (duckdb)
- Requires data migration/import step
- May be overkill for current use cases
- Better for web applications or large deployments

**Decision:**
- **Don't implement immediately**
- Design API to support it later (abstraction layer)
- Revisit when dataset size or multi-user needs justify it

---

## IV. IMPLEMENTATION ROADMAP

### Version 0.9.1 - Documentation & Quick Wins (2-4 hours)
**Timeline:** Immediate

1. Eliminate redundant documentation (Section 3.1)
2. Set up GitHub Issues integration (Section 3.2)
3. Streamline version history → CHANGELOG.md (Section 3.3)
4. Update CLAUDE.md with new structure

**Deliverables:**
- Cleaner dev/ structure
- GitHub Issues for tracking
- CHANGELOG.md following standard format
- Updated project documentation

### Version 0.9.2-0.9.3 - CSS/JS Modernization (6-10 hours)
**Timeline:** After legend refactor completes

1. **Complete legend refactor** (existing 8-step plan)
   - Extract banner/legend to inst/ folders
   - Dynamic legend trimming
   - Horizontal layout
   - Text-on-colored-background format

2. **Configuration system** (Section 1.2)
   - Evaluate YAML vs JSON vs R lists
   - Implement color scale loader
   - Migrate 2-3 scales as proof of concept
   - Document new format

3. **Named placeholder system** (Section 1.1)
   - Replace positional sprintf with gsub/glue
   - Self-documenting CSS injection
   - Better error messages

**Deliverables:**
- All styling in inst/ subfolders
- Optional YAML color scale system
- Clearer CSS generation patterns

### Version 0.9.4-0.9.6 - Code Simplification (8-12 hours)
**Timeline:** Mid-term

1. **Split create_pollution_map()** (Section 2.1)
   - Extract validation, loading, processing, export
   - Keep all functions in quickmap.R initially
   - Comprehensive testing after each extraction

2. **Functional patterns** (Section 2.2)
   - purrr-based layer iteration
   - Pipeline operators for data processing
   - Consistent error handling with safely()

3. **Parameter validation** (Section 3.4)
   - assertthat for clear validation
   - Helpful error messages
   - Type checking and bounds checking

**Deliverables:**
- Modular function structure
- Functional programming patterns
- Robust validation system

### Version 0.9.7-0.9.9 - Documentation & Testing (6-10 hours)
**Timeline:** Before v1.0

1. **roxygen2 documentation** (Section 2.3)
   - Document all 32 functions
   - Package-level documentation
   - Usage examples

2. **Comprehensive testing**
   - Unit tests for utilities
   - Integration tests for workflows
   - Regression tests using existing outputs

3. **Code quality**
   - Run styler for consistent formatting
   - Run lintr for code quality
   - Address all warnings

**Deliverables:**
- Full roxygen2 docs
- Comprehensive test suite
- Clean lintr report

### Version 1.0 - Modular Architecture (12-16 hours)
**Timeline:** Long-term

1. **Split into modules** (Section 2.1, Refactor-5)
   - R/data_io.R
   - R/data_processing.R
   - R/layer_generation.R
   - R/styling_rendering.R
   - R/html_export.R
   - R/config.R
   - R/utils.R

2. **Package structure**
   - DESCRIPTION file
   - Namespace management
   - CRAN checks passing

3. **create_pollution_map() as thin wrapper**
   - Orchestration only
   - Delegates to modular functions
   - Clear separation of concerns

**Deliverables:**
- Modular package structure
- CRAN-ready (if desired)
- Professional R package

### Version 1.1+ - Advanced Features (Future)
**Timeline:** TBD based on user needs

**Potential Features:**
- External theme system (Section 1.3)
- Database integration (Section 3.5)
- Legend engine as separate package (Section 2.4)
- Animation controls
- Advanced clustering/labeling
- Performance optimization

**Decision Criteria:**
- User demand
- Maintenance burden
- Clear use cases

---

## V. DECISION POINTS & RECOMMENDATIONS

### A. Configuration Format (Section 1.2)

**Options:**
1. YAML color scales (external files)
2. JSON color scales (external files)
3. Keep R lists (status quo)

**Recommendation:** **Start with Option 3 (status quo), add Option 1 (YAML) if clear need emerges**

**Rationale:**
- Current R list system works well
- Easy to extend with new scales
- No migration burden
- YAML can be added later without breaking changes
- Consider YAML only if:
  - Non-programmers need to create scales
  - Sharing scales between projects becomes common
  - User community requests it

### B. Modularization Timing

**Options:**
1. Modularize now (v0.9.1)
2. Extract functions first, keep in single file (v0.9.x)
3. Delay until v1.0

**Recommendation:** **Option 2 - Extract functions in v0.9.x, split files in v1.0**

**Rationale:**
- Less risk (single file easier to test)
- Incremental progress
- Time to refine module boundaries
- v1.0 is natural breaking point for major reorganization

### C. Functional Programming Patterns

**Options:**
1. Full tidyverse/purrr approach
2. Selective use where it adds clarity
3. Keep base R patterns

**Recommendation:** **Option 2 - Selective use where beneficial**

**Rationale:**
- Already using some tidyverse (dplyr, tidyr)
- purrr for layer iteration improves clarity
- Don't force functional patterns everywhere
- Maintain readability for R users not deep in tidyverse

### D. Database Integration

**Options:**
1. Implement now with duckdb
2. Design API to support later
3. Skip entirely

**Recommendation:** **Option 2 - Design for future, don't implement yet**

**Rationale:**
- Current file-based approach sufficient
- Database adds complexity
- Premature optimization
- Abstract data loading enough that database could be added later
- Revisit when dataset size or multi-user needs justify it

### E. Documentation Approach

**Options:**
1. Keep extensive dev/ docs
2. Streamline to GitHub Issues + core docs
3. Hybrid approach

**Recommendation:** **Option 3 - Hybrid approach**

**Rationale:**
- Keep PROJECT_STATUS.md as high-level roadmap
- Use GitHub Issues for specific tasks/bugs
- Maintain detailed planning docs for major refactors
- Archive completed work
- Clear index (dev/README.md) explains structure

---

## VI. RISKS & MITIGATION

### Risk 1: Breaking Changes During Refactoring
**Probability:** Medium
**Impact:** High

**Mitigation:**
- Comprehensive testing after each change
- Maintain versions/ archive of working code
- Use git branches for major refactors
- Document breaking changes in CHANGELOG
- Provide migration guides

### Risk 2: Increased Complexity from External Config Files
**Probability:** Medium
**Impact:** Medium

**Mitigation:**
- Only add if clear benefit
- Provide sensible defaults
- Fallback to hardcoded values
- Clear documentation and examples
- Schema validation for config files

### Risk 3: Over-engineering for Current Needs
**Probability:** Medium
**Impact:** Low-Medium

**Mitigation:**
- Follow YAGNI principle (You Aren't Gonna Need It)
- Implement features only when needed
- Start simple, add complexity incrementally
- Get user feedback before major investments
- Measure actual pain points, not theoretical ones

### Risk 4: Loss of Development Momentum
**Probability:** Low
**Impact:** Medium

**Mitigation:**
- Break work into small, achievable chunks
- Celebrate incremental progress
- Maintain working version at all times
- Clear roadmap with milestones
- Regular progress updates

### Risk 5: Divergence from OpenAir Design Philosophy
**Probability:** Low
**Impact:** Medium

**Mitigation:**
- Review OpenAir API decisions before changes
- Maintain "what not how" parameter design
- Consult with OpenAir community if applicable
- Document design decisions and rationale

---

## VII. SUCCESS METRICS

### Code Quality Metrics

**v0.9.1 Targets:**
- [ ] Documentation files reduced by 30%
- [ ] All outstanding issues tracked in GitHub
- [ ] CHANGELOG.md established

**v0.9.6 Targets:**
- [ ] `create_pollution_map()` under 100 lines
- [ ] All functions under 50 lines (except generated code)
- [ ] No functions with nesting depth > 3

**v1.0 Targets:**
- [ ] 100% roxygen2 documentation coverage
- [ ] Test coverage > 80%
- [ ] All lintr warnings addressed
- [ ] Modular architecture (7 files, not 1)

### User Experience Metrics

**v0.9.3 Targets:**
- [ ] CSS generation uses named placeholders (no positional sprintf)
- [ ] Legend system fully external (inst/ folders)
- [ ] Color scales loadable from YAML (optional)

**v0.9.6 Targets:**
- [ ] Clear validation error messages
- [ ] No silent failures
- [ ] Graceful degradation (missing data, invalid params)

### Maintainability Metrics

**v0.9.1 Targets:**
- [ ] New contributor can find relevant docs in < 5 minutes
- [ ] GitHub Issues used for all new work

**v1.0 Targets:**
- [ ] CRAN checks pass (if pursuing CRAN)
- [ ] Modular architecture supports independent testing
- [ ] New features can be added without touching core files

---

## VIII. CONCLUSION

QuickMap has a **solid foundation** with good architectural decisions (unified pipeline, generic layer processing, configuration-driven design). The modernization plan focuses on:

1. **CSS/JS extraction** - Complete what legend refactor started, consider YAML config
2. **Code organization** - Split large functions, use functional patterns selectively
3. **Documentation streamlining** - GitHub Issues, CHANGELOG.md, cleaner dev/ structure

**Key Principles:**
- Incremental progress (small, testable steps)
- Preserve working functionality (no big-bang rewrites)
- Add complexity only when justified (YAGNI principle)
- User needs drive priorities (not theoretical perfection)

**Immediate Next Steps:**
1. Review this plan with team/stakeholders
2. Complete existing legend refactor (already planned)
3. Set up GitHub Issues (2-3 hours)
4. Begin v0.9.1 documentation cleanup

**Long-term Vision:**
By v1.0, QuickMap will be a well-organized, professionally documented R package with modular architecture, comprehensive testing, and clear separation of concerns - while maintaining the elegant unified pipeline that makes it work well today.

---

## IX. APPENDICES

### Appendix A: File Size Estimates (Post-Refactoring)

**Current:** quickmap.R (2,679 lines)

**v0.9.6 (extracted functions, single file):**
- quickmap.R: ~2,400 lines (mostly unchanged, better organized)

**v1.0 (modular):**
- R/data_io.R: ~400 lines (loading, transformation)
- R/data_processing.R: ~300 lines (filtering, spatial ops)
- R/layer_generation.R: ~500 lines (icons, layers)
- R/map_creation.R: ~200 lines (base map, controls)
- R/styling_rendering.R: ~400 lines (CSS/JS loading, post-processing)
- R/html_export.R: ~200 lines (export logic)
- R/config.R: ~300 lines (color scales, palettes, validation)
- R/utils.R: ~200 lines (color utilities, helpers)
- R/quickmap.R: ~150 lines (main wrapper + package setup)
- **Total:** ~2,650 lines (slightly less due to removed duplication)

**External Files (v0.9.3):**
- inst/banner/banner.css: ~50 lines
- inst/legend/legend.css: ~100 lines
- inst/legend/legend.html: ~30 lines
- inst/controls/roller-menu.{html,css,js}: ~500 lines (existing)
- inst/config/scales/*.yaml: ~40 lines each (optional, multiple files)

### Appendix B: Testing Strategy

**Unit Tests (v0.9.7+):**
```
tests/testthat/
├── test-data-io.R          # Data loading functions
├── test-data-processing.R  # Filtering, transformation
├── test-color-utils.R      # Color utilities
├── test-layer-generation.R # Icon and layer creation
├── test-validation.R       # Parameter validation
└── test-config.R           # Configuration loading
```

**Integration Tests (existing + expanded):**
```
tests/
├── test-styling.R          # Existing - styling variations
├── test-parameters.R       # Existing - parameter combinations
├── test-export.R           # Existing - export functionality
├── test-complete-workflow.R  # New - end-to-end
└── test-regression.R       # New - output comparison
```

**Regression Testing:**
- Save outputs from v0.9.0.2
- Compare outputs after each refactor
- Ensure visual consistency (HTML + JPG)

### Appendix C: Useful Resources

**R Package Development:**
- [R Packages (2e)](https://r-pkgs.org/) - Hadley Wickham
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
- [testthat documentation](https://testthat.r-lib.org/)

**Functional Programming in R:**
- [purrr tutorial](https://purrr.tidyverse.org/)
- [Advanced R - Functional Programming](https://adv-r.hadley.nz/fp.html)

**Color Theory for Data Viz:**
- [ColorBrewer](https://colorbrewer2.org/)
- [Viridis color scales](https://cran.r-project.org/web/packages/viridis/)

**Leaflet & Web Mapping:**
- [Leaflet for R](https://rstudio.github.io/leaflet/)
- [sf package](https://r-spatial.github.io/sf/)

---

**Document Status:** Draft for Review
**Next Review:** After legend refactor completion
**Owner:** QuickMap Development Team

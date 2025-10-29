---
editor_options:
  markdown:
    wrap: 72
---

# Style Guide for quickmap Parameter Design

Based on analysis of OpenAir R package and R graphics conventions

---

## Overview

This guide provides patterns for designing quickmap parameters that are:
1. **Consistent** with OpenAir R package conventions
2. **Compatible** with OpenAir functions and workflows
3. **User-friendly** following R package best practices
4. **Evolution-ready** for future modularization and package release

quickmap aims to integrate with OpenAir workflows while maintaining its
unique spatial mapping capabilities.

---

## OpenAir Compatibility Patterns

### Color Generation: Functional vs Bundled

**OpenAir Approach** - Functional color generation:
```r
# OpenAir separates concerns
openColours(scheme = "jet", n = 100)  # Returns hex vector
# Then user provides breaks and labels separately
breaks = c(0, 10, 20, 30, 40)
labels = c("Low", "Moderate", "High", "Very High")
```

**quickmap Current** - Bundled configuration:
```r
# quickmap bundles colors, thresholds, labels, titles
colour_scales <- list(
  who_no2 = list(
    colours = c("blue", "green", "yellow", "orange", "red"),
    thresholds = c(0, 10, 20, 30, 40),
    labels = c("< 10: WHO guideline", "10-20: ...", ...),
    title = "NO2 levels"
  )
)
```

**Recommendation** - Support both approaches (v0.10.0+):
```r
# Create OpenAir-compatible function
quickmapColours <- function(scheme = "who_no2", n = 100) {
  if (scheme %in% names(colour_scales)) {
    cols <- colour_scales[[scheme]]$colours
    grDevices::colorRampPalette(cols)(n)
  } else {
    # Pass through user-defined colors
    grDevices::colorRampPalette(scheme)(n)
  }
}

# Allow both parameter styles
create_pollution_map(
  ...,
  cols = "who_no2",        # OpenAir style (NEW)
  # OR
  colour_scale = "who_no2"  # quickmap style (EXISTING)
)
```

**When to use bundled configs**:
- ✅ Domain-specific scales (WHO guidelines, UK air quality indices)
- ✅ Pre-defined categorizations with labels
- ✅ Internal quickmap functions

**When to use functional approach**:
- ✅ User-facing API compatibility with OpenAir
- ✅ Flexible color generation
- ✅ Functions exported for use in other packages

### Parameter Naming: Dots vs Underscores

**OpenAir Convention** - Dots for multi-word parameters:
```r
# OpenAir uses dots
avg.time = "day"
data.thresh = 75
key.header = "NO2"
min.bin = 3
ws_spread = 1.5  # Exception: some use underscores
```

**quickmap v0.9.0** - Underscores for multi-word parameters:
```r
# quickmap uses underscores
marker_labels = TRUE
boundary_labels = FALSE
diffusion_tube_file = "data.csv"
```

**Recommendation** - Evolution strategy:
```r
# KEEP v0.9.0 parameters (avoid breaking changes)
marker_labels = TRUE
boundary_labels = FALSE

# NEW parameters in v0.10.0+ should use DOTS
avg.time = "day"           # Future parameter
data.thresh = 75           # Future parameter
key.header = "NO2"         # Future parameter

# Provide ALIASES for OpenAir compatibility
create_pollution_map <- function(
  ...,
  cols = NULL,              # OpenAir alias (v0.10.0+)
  colour_scale = NULL,      # quickmap (v0.9.0)
  ...
) {
  # Handle both, with cols taking precedence
  if (!is.null(cols)) {
    scale <- cols
  } else if (!is.null(colour_scale)) {
    scale <- colour_scale
  } else {
    scale <- "who_no2"
  }
}
```

### Data Structure Compatibility

**OpenAir Requirements**:
```r
# Mandatory columns
data.frame(
  date = POSIXct,      # REQUIRED - temporal index
  pollutant = numeric  # At least one pollutant column
)

# Standard names (recommended)
ws = numeric         # Wind speed (m/s)
wd = numeric         # Wind direction (degrees, 0-360)
site = character     # Site identifier
code = character     # Site code
```

**quickmap Requirements**:
```r
# CSV diffusion tube data
data.frame(
  Easting = numeric,   # British National Grid
  Northing = numeric,  # British National Grid
  `2021` = numeric,    # Year columns
  `2022` = numeric,
  Label = character    # Optional site labels
)

# RData sensor data (OpenAir-compatible format)
data.frame(
  date = POSIXct,      # Temporal index
  siteCode = character,
  year = numeric,
  lat = numeric,
  lon = numeric,
  no2 = numeric,       # Pollutant columns
  pm25 = numeric
)
```

**Compatibility Note**: quickmap sensor data (RData format) already
follows OpenAir conventions. CSV data uses spatial coordinates instead
of temporal indexing.

---

## Code Types Common to Both Packages

### 1. Color Generation

**Shared capability**: Hex code colors, color ramps, interpolation

**OpenAir implementation**:
```r
openColours(scheme = "jet", n = 100)
# Returns: c("#00007F", "#0000FF", ..., "#7F0000")
```

**quickmap implementation**:
```r
assign_colour(value = 25, scale = "who_no2")
# Returns: "yellow"  # Based on thresholds
```

**Compatibility path**: Create `quickmapColours()` wrapper

### 2. Data Validation

**Shared need**: Check required columns, data types, valid ranges

**OpenAir implementation**:
```r
checkPrep(mydata, vars = c("date", "nox"), type = "default")
```

**quickmap implementation**:
```r
load_data_file(file_path, file_type, required_cols)
# Internal validation in loading functions
```

**Compatibility path**: Use `checkPrep()` in quickmap functions that
accept OpenAir-format data

### 3. Temporal Data Processing

**Shared need**: Date filtering, aggregation, time series handling

**OpenAir implementation**:
```r
selectByDate(mydata, year = 2020:2023)
timeAverage(mydata, avg.time = "day", statistic = "mean")
```

**quickmap implementation**:
```r
# Currently: year filtering in generate_map_layers()
# Filter to specific years
filter(mydata, year %in% years)
```

**Compatibility path**: Accept pre-filtered data from `selectByDate()`

### 4. Configuration Objects

**OpenAir approach**: Separate parameters, no pre-bundled configs
```r
# User provides all elements separately
calendarPlot(
  mydata,
  pollutant = "no2",
  breaks = c(0, 50, 100, 150, 1000),
  labels = c("Low", "Moderate", "High", "Very High"),
  cols = c("green", "yellow", "orange", "red")
)
```

**quickmap approach**: Pre-bundled domain configurations
```r
# quickmap bundles air quality thresholds
colour_scales$who_no2  # Contains colours, thresholds, labels, title

# quickmap bundles borough brand colors
borough_palettes$merton  # Contains purple, blue, green, etc.

# quickmap bundles layer configurations
get_measurement_layers()  # Returns structured config objects
```

**When to bundle** (quickmap patterns):
- ✅ Domain-specific standards (WHO guidelines, DAQI bands)
- ✅ Brand/style guides (borough colors)
- ✅ Complex multi-layer map configurations
- ✅ Pre-validated, tested combinations

**When to separate** (OpenAir patterns):
- ✅ User-facing APIs for flexibility
- ✅ Generic plotting functions
- ✅ When users need custom categorization
- ✅ Statistical analysis functions

### 5. Helper Functions

**Shared need**: Utility functions for common operations

**OpenAir utilities**:
```r
cutData(mydata, type = "season")    # Split data by conditioning variable
date.pad(mydata)                     # Fill missing dates
breaksToLabels(breaks, labels)       # Generate category labels
```

**quickmap utilities**:
```r
transform_to_wgs84(sf_data)              # Coordinate transformation
generate_marker_labels(data, pollutant)  # Create label text
assign_colour(value, scale)              # Categorize to color
```

**Compatibility path**: Name quickmap utilities following OpenAir
patterns for future export

---

## OpenAir Parameter Design Patterns

### Multi-Value Categorical Parameters

**Pattern**: Use categorical parameters instead of multiple boolean
flags

**Example from OpenAir**:
- `type = "site" | "season" | "weekday"` instead of `show_type`, `is_seasonal`, etc.
- `data_type = "hourly" | "daily" | "monthly"` for data granularity

**Best Practice**: Parameter describes WHAT the user wants, not HOW it's
implemented

**Applied to quickmap**:
- Current success: `marker_labels = FALSE | TRUE | "values_on" | "labels" | "labels_on"`
- Proposed: `styling_type = "none" | "html"` (v0.9.0 ✓)

### Flat Parameter Structure

**Pattern**: Keep parameters at top level, avoid deep nesting

**OpenAir Approach**:
- Main parameters at function level
- Group related advanced parameters in simple lists when needed
- Don't create complex nested hierarchies

**Applied to quickmap**:
- Avoid: `options = list(display = list(title = list(text = "...")))`
- Prefer: flat parameters or simple one-level lists

### Sensible Defaults

**Pattern**: Most parameters optional with intelligent defaults

**OpenAir Approach**:
- Provide reasonable defaults for common use cases
- Allow users to override when needed
- Defaults should work for 90% of use cases

**quickmap v0.9.0 defaults**:
```r
create_pollution_map(
  diffusion_tube_file = "none",     # No data by default
  pollutant = "no2",                # Common pollutant
  years = NULL,                     # All available years
  styling_type = "none",            # Clean map by default
  vignette = TRUE,                  # Visual enhancement
  marker_labels = FALSE             # Clean markers
)
```

### Clear Naming Conventions

**Pattern**: Self-documenting parameter names

**OpenAir Approach**:
- Descriptive names: `data.thresh` not `dt`, `pollutant` not `poll`
- Common patterns: `*_file`, `*.position`, `*.type`
- Dots for multi-word: `avg.time`, `key.header`, `data.thresh`

**quickmap v0.9.0**:
- File parameters: `diffusion_tube_file`, `sensor_file`, `school_file`
- Type parameters: `styling_type`
- Short clear names: `pollutant`, `boroughs`, `years`, `title`

---

## Parameter Naming Evolution

### v0.9.0 → v0.10.0+ Naming Strategy

**Principle**: Evolve toward OpenAir compatibility without breaking changes

### Stage 1: Aliases (v0.10.0)

Add OpenAir-compatible aliases alongside existing parameters:

```r
create_pollution_map <- function(
  ...,
  # NEW: OpenAir-compatible aliases
  cols = NULL,              # Alias for colour_scale
  avg.time = NULL,          # Future: time aggregation

  # EXISTING: quickmap v0.9.0 parameters (keep for compatibility)
  colour_scale = NULL,
  marker_labels = FALSE,
  boundary_labels = FALSE,

  ...
) {
  # Handle aliases - NEW parameter takes precedence
  if (!is.null(cols)) {
    colour_scale <- cols
  }

  # Existing logic uses colour_scale internally
  ...
}
```

### Stage 2: Dots for New Parameters (v0.10.0+)

All NEW parameters should use dot notation:

```r
# Future quickmap functions
analyzeExceedances <- function(
  mydata,                   # OpenAir-compatible data frame
  pollutant = "no2",       # Single word: no dots
  threshold = 40,          # Single word: no dots
  avg.time = "day",        # Multi-word: use dots
  data.thresh = 75,        # Multi-word: use dots
  key.header = "NO2",      # Multi-word: use dots
  ...
)
```

### Stage 3: Deprecation Path (v0.11.0+)

Soft deprecation with warnings:

```r
if (!missing(colour_scale) & missing(cols)) {
  warning(
    "Parameter 'colour_scale' is deprecated. ",
    "Use 'cols' for OpenAir compatibility.",
    call. = FALSE
  )
  cols <- colour_scale
}
```

### Parameter Name Translation Table

| quickmap v0.9.0 | OpenAir-compatible (v0.10.0+) | Status |
|-----------------|-------------------------------|--------|
| `colour_scale` | `cols` | Add alias |
| `marker_labels` | `marker_labels` | Keep (no OpenAir equivalent) |
| `boundary_labels` | `boundary_labels` | Keep (no OpenAir equivalent) |
| `diffusion_tube_file` | `diffusion_tube_file` | Keep (domain-specific) |
| `sensor_file` | `sensor_file` | Keep (domain-specific) |
| `styling_type` | `styling_type` | Keep (no OpenAir equivalent) |
| N/A | `avg.time` | NEW for aggregation |
| N/A | `data.thresh` | NEW for data coverage |
| N/A | `key.header` | NEW for legend titles |

---

## Migration Strategy: quickmap → OpenAir-Compatible

### Goal

Enable quickmap functions to work seamlessly in OpenAir workflows while
maintaining backward compatibility.

### Approach 1: Wrapper Functions

Create OpenAir-compatible wrappers around quickmap core:

```r
#' OpenAir-compatible time series plot
#' @param mydata Data frame with 'date' column (OpenAir format)
#' @param pollutant Pollutant column name
#' @param cols Color scheme (OpenAir parameter name)
#' @export
quickmapTimePlot <- function(
  mydata,
  pollutant = "no2",
  type = "default",
  avg.time = "day",
  cols = "default",
  plot = TRUE,
  ...
) {
  # Validate OpenAir format
  if (!"date" %in% names(mydata)) {
    stop("Data must contain 'date' column (POSIXct)")
  }

  # Convert to quickmap internal format if needed
  # ... transformation logic ...

  # Call quickmap core function
  result <- create_pollution_map(
    ...,
    colour_scale = cols,  # Translate parameter name
    ...
  )

  if (plot) print(result)
  invisible(result)
}
```

### Approach 2: Accept Pre-Processed OpenAir Data

Allow OpenAir preprocessing in quickmap workflows:

```r
# User workflow combining OpenAir + quickmap
library(openair)
library(quickmap)

# 1. Load data in OpenAir format
data(mydata, package = "openair")

# 2. Pre-process with OpenAir functions
filtered <- selectByDate(mydata, year = 2020:2023, month = 6:9)
daily <- timeAverage(filtered, avg.time = "day")

# 3. Convert to quickmap spatial format
spatial_data <- convertOpenAirToSpatial(
  daily,
  coords_from = "site",  # Join to site locations
  site_data = site_locations
)

# 4. Create quickmap visualization
create_pollution_map(
  sensor_file = spatial_data,
  pollutant = "no2",
  cols = "jet"  # OpenAir-compatible parameter
)
```

### Approach 3: Helper Functions for Compatibility

Create utilities to bridge the two packages:

```r
#' Convert OpenAir data to quickmap spatial format
#' @export
convertOpenAirToSpatial <- function(
  openair_data,
  coords_from = "site",
  site_data = NULL
) {
  # Join temporal OpenAir data with spatial coordinates
  # Return sf object ready for quickmap
  ...
}

#' Prepare quickmap data for OpenAir analysis
#' @export
convertSpatialToOpenAir <- function(
  quickmap_spatial,
  pollutant = "no2"
) {
  # Extract temporal data from spatial layers
  # Return data frame with 'date' column
  ...
}
```

---

## R Graphics Conventions

### Position Parameters

**Pattern**: Use position strings like leaflet conventions

**Leaflet positions**: "topright", "bottomleft", "bottomright",
"topleft"

**Applied to quickmap**:
- Legend positioning (if added): `legend.position = "topright"`

### UK English Preference

- Use "colour" not "color" for UK context
- `colour_scale`, `banner_colour` (quickmap)
- BUT: `cols` for OpenAir compatibility (abbreviated form acceptable)
- Add US aliases in future versions if needed

---

## Quickmap-Specific Patterns

### Title/Banner Distinction

- **HTML banner**: Appears above the map (wrapper div, static visible)
- **Browser title**: `<title>` tag in HTML head
- Use single `title` parameter for both (v0.9.0)

### Auto-Generation Helpers

- Generate descriptive titles from components (borough + pollutant +
  year)
- User provides base title, system appends context
- Empty title triggers full auto-generation

### Borough Brand Colors

**Current pattern** - Nested named lists:
```r
borough_palettes$merton$purple
borough_palettes$wandsworth$blue
borough_palettes$richmond$green
```

**OpenAir-compatible helper** (future):
```r
boroughColours <- function(borough = "merton", colour = "purple") {
  if (!borough %in% names(borough_palettes)) {
    stop("Borough not found: ", borough)
  }
  if (!colour %in% names(borough_palettes[[borough]])) {
    stop("Colour not found for ", borough, ": ", colour)
  }
  borough_palettes[[borough]][[colour]]
}

# Usage
banner_colour = boroughColours("merton", "purple")
```

---

## Anti-Patterns to Avoid

1. **Boolean explosion**: Don't create many `show_*` boolean parameters
   - ❌ `show_banner`, `show_legend`, `show_title`, `show_markers`
   - ✅ `styling_type = "none" | "html"`

2. **Deep nesting**: Don't create `options$display$title$text`
   hierarchies
   - ❌ `options = list(display = list(title = list(text = "...")))`
   - ✅ Flat parameters: `title = "..."`

3. **Implementation details in names**: Don't expose internal tech in
   parameter values
   - ❌ `export_format = "webshot2_chromote"`
   - ✅ `export_image = c(1920, 1080)` (what user wants)

4. **Over-engineering**: Keep it simple, don't add complexity before
   it's needed
   - ❌ Pre-build all possible configurations
   - ✅ Provide functions to generate on demand

5. **Bundling everything** (NEW): Don't bundle when separation is better
   - ❌ Bundling in user-facing APIs when users need flexibility
   - ✅ Bundling for domain standards (WHO, DAQI)
   - ❌ Bundling colors + breaks + labels in generic functions
   - ✅ Functional generation (`openColours()`, `quickmapColours()`)

6. **Inconsistent naming** (NEW): Don't mix conventions within same API
   - ❌ `avg.time` and `marker_labels` in same function
   - ✅ All dots OR all underscores within one function version
   - ✅ Evolution via aliases (support both temporarily)

---

## Principles

1. **User intent over implementation**: Parameters should describe what
   user wants

2. **Progressive disclosure**: Common parameters at top level, advanced
   in options

3. **Context-aware defaults**: Smart defaults that work in different
   contexts

4. **Multi-value over boolean**: Prefer categorical states over binary
   toggles

5. **OpenAir compatibility** (NEW): Design with OpenAir integration in mind
   - Use compatible parameter names where possible
   - Accept OpenAir data structures
   - Follow OpenAir naming conventions for new parameters
   - Provide functional interfaces alongside configurations

6. **Evolution over revolution** (NEW): Maintain backward compatibility
   - Add aliases, don't rename existing parameters
   - Deprecate gracefully with clear warnings
   - Document migration paths for each version
   - Keep v0.9.0 working indefinitely

7. **Separation of concerns** (NEW): Know when to bundle, when to separate
   - Bundle domain standards and validated combinations
   - Separate for user flexibility and OpenAir compatibility
   - Provide both functional and configured approaches
   - Document the rationale for each choice

---

## Code Examples: OpenAir-Compatible Functions

### Example 1: Color Generation Function

```r
#' Generate colors for quickmap (OpenAir-compatible)
#'
#' @param scheme Color scheme name or vector of colors
#' @param n Number of colors to generate
#' @return Character vector of hex color codes
#' @export
#' @examples
#' quickmapColours("who_no2", 10)
#' quickmapColours(c("blue", "red"), 5)
quickmapColours <- function(scheme = "who_no2", n = 100) {
  # Check if scheme is a quickmap predefined scale
  if (length(scheme) == 1 && scheme %in% names(colour_scales)) {
    cols <- colour_scales[[scheme]]$colours
  } else {
    # Assume user-provided color vector
    cols <- scheme
  }

  # Interpolate to requested number of colors
  grDevices::colorRampPalette(cols)(n)
}
```

### Example 2: Data Conversion Function

```r
#' Convert OpenAir temporal data to quickmap spatial format
#'
#' @param mydata OpenAir-format data frame with 'date' column
#' @param site.data Data frame with site coordinates
#' @param coords Coordinate column names (default: c("lon", "lat"))
#' @return sf object ready for quickmap
#' @export
convertOpenAirToSpatial <- function(
  mydata,
  site.data,
  coords = c("lon", "lat")
) {
  # Validate OpenAir format
  if (!"date" %in% names(mydata)) {
    stop("mydata must contain 'date' column")
  }

  if (!"site" %in% names(mydata)) {
    stop("mydata must contain 'site' column for spatial join")
  }

  # Join with site coordinates
  spatial <- mydata %>%
    dplyr::left_join(site.data, by = "site") %>%
    dplyr::filter(!is.na(.data[[coords[1]]]), !is.na(.data[[coords[2]]]))

  # Convert to sf object
  sf::st_as_sf(
    spatial,
    coords = coords,
    crs = 4326  # WGS84
  )
}
```

### Example 3: Wrapper Function

```r
#' Create pollution map from OpenAir-preprocessed data
#'
#' @param mydata OpenAir-compatible spatial data
#' @param pollutant Pollutant column name
#' @param cols Color scheme (OpenAir parameter)
#' @param avg.time Time averaging (OpenAir parameter)
#' @param plot Should plot be displayed?
#' @param ... Additional arguments passed to create_pollution_map()
#' @return Leaflet map object
#' @export
quickmapFromOpenAir <- function(
  mydata,
  pollutant = "no2",
  cols = "default",
  avg.time = NULL,
  plot = TRUE,
  ...
) {
  # Time averaging if requested
  if (!is.null(avg.time)) {
    mydata <- openair::timeAverage(
      mydata,
      avg.time = avg.time,
      statistic = "mean"
    )
  }

  # Convert to quickmap format
  # (assumes mydata already has spatial coordinates)

  # Create map using quickmap core
  result <- create_pollution_map(
    sensor_file = mydata,  # Pass sf object directly
    pollutant = pollutant,
    cols = cols,           # OpenAir-compatible parameter
    ...
  )

  if (plot) print(result)
  invisible(result)
}
```

### Example 4: Integrated Workflow

```r
# Complete example combining OpenAir preprocessing with quickmap visualization

library(openair)
library(quickmap)

# 1. Load OpenAir data
data(mydata, package = "openair")

# 2. Select time period (OpenAir function)
filtered <- selectByDate(mydata, year = 2020:2023, month = 6:9)

# 3. Calculate daily means (OpenAir function)
daily <- timeAverage(filtered, avg.time = "day", data.thresh = 75)

# 4. Load site coordinates
site_coords <- read.csv("site_locations.csv")  # site, lon, lat

# 5. Convert to spatial format
spatial_data <- convertOpenAirToSpatial(
  daily,
  site.data = site_coords
)

# 6. Create quickmap with OpenAir-compatible parameters
map <- quickmapFromOpenAir(
  spatial_data,
  pollutant = "nox",
  cols = "jet",              # OpenAir color scheme name
  styling_type = "html",     # quickmap-specific
  boroughs = "Wandsworth"    # quickmap-specific
)
```

---

**Document Version:** 2.0
**Last Updated:** 2025-10-29 (OpenAir compatibility added)
**Previous Version:** 1.0 (2025-10-28)

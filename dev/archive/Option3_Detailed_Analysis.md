# Option 3: Hybrid Pipeline with Early OpenAir Testing
## Detailed Analysis for QuickMap v0.9.1 → v0.9.5

**Document Version:** 1.0
**Date:** 2025-11-23
**Status:** Research-backed recommendations for phased implementation

---

## Executive Summary

Option 3 implements a risk-minimized, evidence-based approach to OpenAir integration with **multi-resolution temporal support** (annual to hourly) through incremental testing and informed refactoring. Phase 1 (v0.9.2) delivers immediate OpenAir workflow capability via converter function with `avg.time` parameter, returning sf objects (annual) or sftime objects (sub-annual). Phase 2 (v0.9.3-0.9.5) refactors toward modular data abstraction supporting mixed temporal resolutions, with sftime as optional suggested dependency (v0.9.4). This strategy validates technical decisions with production data at multiple temporal scales before committing to architectural changes, while positioning quickmap for broader R spatial ecosystem integration and advanced temporal use cases.

---

## Background Research: Spatial-Temporal Data Mapping Landscape

### R Ecosystem Standards

The R spatial ecosystem has converged around **sf** as the standard for vector spatial data, superseding the legacy sp package ([r-spatial.org](https://r-spatial.org/book/07-Introsf.html)). For spatiotemporal data, two complementary approaches exist:

1. **stars** package: Handles regular spatiotemporal arrays (data cubes) such as gridded satellite imagery or regular sensor measurements ([r-spatial.github.io/stars](https://r-spatial.github.io/stars/)). Provides `stars_proxy` for lazy evaluation with large datasets.

2. **sftime** package: Extends sf with temporal columns for irregular spatiotemporal data (earthquakes, accidents, disease cases, weather stations) ([r-spatial.org/r/2022/04/12/sftime-1](https://r-spatial.org/r/2022/04/12/sftime-1.html)). Complementary to stars for non-gridded point data.

**Implication for quickmap**: Air quality monitoring networks (AURN, LAQN, Breathe London) represent **irregular spatiotemporal point data**—fixed sensor locations with temporal measurements at varying resolutions (1 second to annual). This aligns with **sftime** patterns for sub-annual data. **sftime status**: v0.3.1 (August 2025), CRAN-stable, 125 commits, 1 open issue, production-ready ([GitHub](https://github.com/r-spatial/sftime), [CRAN](https://cran.r-project.org/web/packages/sftime/)). **Strategy**: Use sf for annual aggregations (current behavior), adopt sftime optionally for sub-annual temporal resolution (monthly/daily/hourly). Make sftime *suggested* dependency (v0.9.4), not required—maintains backward compatibility.

### OpenAir + Spatial Mapping Integration

The [openairmaps](https://openair-project.github.io/openairmaps/) package demonstrates production integration of OpenAir workflows with Leaflet mapping:

- **Core functions**: `networkMap()` for site visualization, `polarMap()` for directional analysis markers, `trajMap()` for HYSPLIT trajectories
- **Data flow**: Uses OpenAir's temporal data.frame format → aggregates/filters → converts to spatial coordinates → renders Leaflet markers
- **Architecture**: Separates temporal analysis (OpenAir) from spatial rendering (Leaflet), joined via site coordinates

**Key insight**: openairmaps accepts OpenAir data.frames directly but relies on site metadata (lat/lon) for spatialization. This validates quickmap's proposed converter approach—temporal OpenAir data must acquire spatial attributes before rendering.

### Leaflet Temporal Visualization Approaches

Research identified three established patterns for temporal data in R+Leaflet:

1. **Layer Groups with Year Controls** (quickmap's current approach): Multiple layer groups with show/hide controls, JavaScript year selector
2. **leaflet.extras2::addTimeslider()**: jQuery UI slider for dynamic marker filtering ([CRAN leaflet.extras2](https://cran.r-project.org/web/packages/leaflet.extras2/))
3. **Shiny Integration**: Server-side filtering with reactive sliderInput ([Appsilon leaflet vs tmap](https://www.appsilon.com/post/leaflet-vs-tmap-build-interactive-maps-with-r-shiny))

**Evaluation**: quickmap's layer group architecture is well-suited for static HTML export (no Shiny server). leaflet.extras2 offers enhanced interactivity but requires additional dependencies. Current roller menu system is adequate; defer enhancements to post-v0.9.5.

### Python Ecosystem Context

For cross-language perspective, Python's geospatial stack uses:

- **Folium**: Python wrapper for Leaflet ([Towards Data Science geospatial libraries](https://towardsdatascience.com/best-libraries-for-geospatial-data-visualisation-in-python-d23834173b35/)), similar to R's leaflet package
- **Kepler.gl/Pydeck**: High-performance 3D temporal visualization for large datasets ([Analytics Vidhya kepler.gl](https://www.analyticsvidhya.com/blog/2020/06/learn-visualize-geospatial-data-jupyter-kepler/))
- **Leafmap**: Unified interface supporting folium, ipyleaflet, pydeck backends with time series animation ([leafmap.org](https://leafmap.org/get-started/))

**Takeaway**: Python ecosystem favors notebook-based interactive exploration. R+quickmap's strength is **production-ready static HTML/JPG exports** for reports—distinct niche from Python tools.

---

## OpenAir Data Network Structures

### AURN (Automatic Urban and Rural Network)

**Import function**: `openair::importAURN(site, year, pollutant)`

**Returned structure** ([CRAN openair refman](https://cran.r-project.org/web/packages/openair/refman/openair.html)):
```r
data.frame(
  date = POSIXct,        # Hourly timestamps (GMT)
  site = character,      # Site name
  code = character,      # Site code
  <pollutant> = numeric  # NO2, PM10, PM25, O3, etc.
)
```

**Metadata**: `importMeta(source = "aurn", all = TRUE)` returns site codes, names, lat/lon (WGS84), site_type, local_authority, start_date, end_date ([OpenAir importMeta](https://openair-project.github.io/openair/reference/importMeta.html))

**Data characteristics**:
- Hourly temporal resolution (8,760 observations/site/year)
- Stacked format (multiple sites in single data.frame)
- Requires aggregation for annual mapping (use `timeAverage(avg.time = "year")`)

### LAQN (London Air Quality Network)

**Import function**: `openair::importKCL(site, year, pollutant)` (formerly `importImperial`)

**Structure**: Identical to AURN—stacked data.frame with date, site, code, pollutant columns

**Network scope**: ~100 sites across Greater London, managed by Imperial College, higher spatial density than AURN

**Metadata**: `importMeta(source = "kcl")` provides lat/lon coordinates

### Spatial Join Requirements

Both AURN and LAQN data lack embedded geometry—spatial coordinates obtained via:

1. Call `importMeta()` to retrieve site lat/lon
2. Left join temporal data with metadata on `site` or `code`
3. Filter to non-NA coordinates
4. Convert to sf: `st_as_sf(coords = c("lon", "lat"), crs = 4326)`

**Critical observation**: This workflow is **generic for all OpenAir network imports**. A universal converter function can handle AURN, LAQN, and future networks (SAQN, WAQN, European) identically.

---

## QuickMap Layer System Architecture Analysis

### Current Layer Configuration

QuickMap v0.9.1 implements a **list-based layer registry** (R/quickmap.R:1249-1278):

```r
get_measurement_layers <- function(diffusion_tube_file, sensor_file,
                                    school_file, marker_labels) {
  list(
    bl_nodes = list(
      enabled = (sensor_file != "none"),
      data_source = "bl_annual_means_sf",    # Variable name in environment
      layer_type = "bl_nodes",                # Icon shape (diamond)
      temporal = TRUE,                        # Has year dimension
      options = list(marker_labels = marker_labels)
    ),
    dt_sites = list(
      enabled = (diffusion_tube_file != "none"),
      data_source = "sf_data_wgs84",
      layer_type = "dt_sites",                # Icon shape (circle)
      temporal = TRUE,
      options = list(marker_labels = marker_labels)
    ),
    schools = list(
      enabled = (school_file != "none"),
      data_source = "sf_schools_wgs84",
      layer_type = "schools",                 # Icon shape (cross)
      temporal = FALSE,                       # Static layer (no years)
      options = list(marker_labels = marker_labels)
    )
  )
}
```

### Layer Processing Pipeline

**Flow**: `generate_map_layers()` → for each layer → `prepare_generic_layer_data()` → `create_generic_icons()` → `add_layer()`

**Key functions** (R/quickmap.R:1561-1634):
1. **generate_map_layers()**: Iterates measurement_layers, filters by enabled status and year
2. **prepare_generic_layer_data()**: Generates marker labels, packages sf data + labels
3. **create_generic_icons()**: Maps layer_type to icon shapes (circle/diamond/cross) and assigns colors
4. **add_layer()**: Adds Leaflet markers with popups to map, assigns to group for year control

### Extensibility Assessment

**Current assumptions**:
- Data sources are sf objects in calling environment
- Layer types hardcoded to three icon shapes
- Temporal layers use `year_str` column for filtering
- Pollutant column names determined by layer_type switch statement

**Generalization requirements for new networks (AURN, LAQN)**:
1. **Add layer config entries**: AURN and LAQN need new list entries in `get_measurement_layers()`
2. **Distinct icons**: Differentiate network sources visually (e.g., AURN=squares, LAQN=triangles)
3. **Dynamic pollutant columns**: Current code assumes `no2` for dt_sites, needs parameter-driven lookup
4. **Flexible data sources**: Move from environment variable names to direct sf object passing

**Proposed refactor** (implements during v0.9.3-0.9.4):

```r
# Generalized layer definition
get_measurement_layers <- function(loaded_data, marker_labels) {
  layers <- list()

  # Build layer configs from loaded data objects
  if (!is.null(loaded_data$diffusion_tubes)) {
    layers$dt_sites <- list(
      data = loaded_data$diffusion_tubes,  # Direct sf reference
      layer_type = "circle",               # Generic shape name
      icon_color = "blue",
      temporal = TRUE,
      pollutant_col = loaded_data$diffusion_tubes_pollutant,
      options = list(marker_labels = marker_labels)
    )
  }

  if (!is.null(loaded_data$aurn_sites)) {
    layers$aurn <- list(
      data = loaded_data$aurn_sites,
      layer_type = "square",               # New icon shape
      icon_color = "green",
      temporal = TRUE,
      pollutant_col = loaded_data$aurn_pollutant,
      options = list(marker_labels = marker_labels)
    )
  }

  # ... LAQN, schools, etc.

  return(layers)
}
```

**Benefits**:
- Data objects passed directly, not via environment lookup
- Layer types become generic (shape + color parameters)
- Pollutant column specified per layer, not hardcoded
- Easily extensible—adding new networks requires config entry, no code changes

---

## Phase 1 (v0.9.2): Immediate OpenAir Integration

### Implementation: `convertOpenAirToSpatial()` Function

**Location**: New function in R/quickmap.R after existing data loaders (~line 250)

**Function signature**:
```r
#' Convert OpenAir temporal data to spatial format for quickmap
#'
#' @param openair_data Data.frame from importAURN(), importKCL(), etc.
#'   Must contain 'date' column (POSIXct) and pollutant columns.
#' @param pollutant Character. Pollutant to extract (e.g., "no2", "pm25").
#' @param source Character. Network source identifier (e.g., "aurn", "laqn").
#' @param site_meta Data.frame from importMeta() with site, code, latitude,
#'   longitude columns. If NULL, attempts auto-fetch using source parameter.
#'
#' @return sf object with point geometry (WGS84), columns: siteCode, year,
#'   <pollutant>, lat, lon, geometry. Compatible with quickmap sensor_file input.
#'
#' @export
#' @examples
#' \dontrun{
#' library(openair)
#' # Load AURN data for London sites
#' aurn <- importAURN(site = c("London Marylebone Road", "London N. Kensington"),
#'                    year = 2019:2023, pollutant = "no2")
#' # Convert to spatial format
#' aurn_sf <- convertOpenAirToSpatial(aurn, pollutant = "no2", source = "aurn")
#'
#' # Use in quickmap
#' create_pollution_map(
#'   sensor_file = aurn_sf,
#'   boroughs = "Westminster",
#'   pollutant = "no2"
#' )
#' }
convertOpenAirToSpatial <- function(openair_data, pollutant,
                                     source = "aurn", site_meta = NULL) {
  # Validate required columns
  if (!"date" %in% names(openair_data)) {
    stop("openair_data must contain 'date' column (POSIXct)")
  }
  if (!pollutant %in% names(openair_data)) {
    stop("Pollutant '", pollutant, "' not found in openair_data columns")
  }

  # Auto-fetch metadata if not provided
  if (is.null(site_meta)) {
    message("Fetching site metadata for source: ", source)
    site_meta <- openair::importMeta(source = source, all = FALSE)
  }

  # Validate metadata
  required_meta <- c("site", "latitude", "longitude")
  if (!all(required_meta %in% names(site_meta))) {
    stop("site_meta must contain: ", paste(required_meta, collapse = ", "))
  }

  # Aggregate to annual means (openair's timeAverage)
  annual_means <- openair::timeAverage(
    openair_data,
    avg.time = "year",
    statistic = "mean",
    type = "site"  # Preserve site grouping
  )

  # Add year column (POSIXct to numeric year)
  annual_means$year <- as.numeric(format(annual_means$date, "%Y"))

  # Join with spatial metadata
  spatial_data <- merge(
    annual_means,
    site_meta[, c("site", "latitude", "longitude")],
    by = "site",
    all.x = TRUE
  )

  # Filter to sites with coordinates
  spatial_data <- spatial_data[
    !is.na(spatial_data$latitude) & !is.na(spatial_data$longitude),
  ]

  if (nrow(spatial_data) == 0) {
    stop("No sites with valid coordinates after join")
  }

  # Rename to quickmap conventions
  names(spatial_data)[names(spatial_data) == "site"] <- "siteCode"
  names(spatial_data)[names(spatial_data) == "latitude"] <- "lat"
  names(spatial_data)[names(spatial_data) == "longitude"] <- "lon"

  # Convert to sf (WGS84)
  sf_data <- sf::st_as_sf(
    spatial_data,
    coords = c("lon", "lat"),
    crs = 4326,
    remove = FALSE  # Keep lon/lat columns for quickmap
  )

  # Add year_str for quickmap's temporal filtering
  sf_data$year_str <- as.character(sf_data$year)

  # Select relevant columns (date, siteCode, year, pollutant, geometry)
  keep_cols <- c("date", "siteCode", "year", "year_str", pollutant,
                 "lat", "lon", "geometry")
  sf_data <- sf_data[, intersect(keep_cols, names(sf_data))]

  message("Converted ", nrow(sf_data), " site-years to sf format")
  return(sf_data)
}
```

**Key design decisions**:
- Uses `openair::timeAverage(avg.time = "year")` for aggregation, maintaining OpenAir workflow consistency
- Auto-fetches metadata via `importMeta()` if not provided (convenience for users)
- Validates inputs explicitly (fail early with clear errors)
- Returns sf object matching `process_oa_data()` output structure (R/quickmap.R:75-117)
- Adds `year_str` column required by `generate_map_layers()`

### Testing Protocol (v0.9.2)

**Test 1: AURN London sites**
```r
library(openair)
library(quickmap)

# Load 5 years of AURN data for London
aurn_data <- importAURN(
  site = c("London Marylebone Road", "London N. Kensington",
           "London Bloomsbury", "Westminster"),
  year = 2019:2023,
  pollutant = "no2"
)

# Convert to spatial
aurn_sf <- convertOpenAirToSpatial(aurn_data, pollutant = "no2", source = "aurn")

# Create map
create_pollution_map(
  sensor_file = aurn_sf,
  boroughs = c("Westminster", "Camden"),
  pollutant = "no2",
  output_file = "test_aurn_london.html",
  colour_scale = "who_no2"
)
```

**Expected outcome**: HTML map with 4 AURN sites (diamond markers), 5 years selectable via roller menu, colored by WHO NO2 scale

**Test 2: LAQN network**
```r
# Load LAQN data
laqn_data <- importKCL(
  site = c("Wandsworth Town Hall", "Merton Road Morden"),
  year = 2020:2023,
  pollutant = "pm25"
)

laqn_sf <- convertOpenAirToSpatial(laqn_data, pollutant = "pm25", source = "kcl")

create_pollution_map(
  sensor_file = laqn_sf,
  boroughs = c("Wandsworth", "Merton"),
  pollutant = "pm25",
  colour_scale = "gla_pm25"
)
```

**Validation checks**:
- [ ] Converter handles missing sites gracefully (warns, filters out)
- [ ] Year filtering works correctly in roller menu
- [ ] Pollutant values map to correct color scale bins
- [ ] Coordinate transformation maintains accuracy (spot check vs Google Maps)
- [ ] Export to JPG renders correctly

### Documentation Updates (v0.9.2)

**CLAUDE.md additions**:
```markdown
### OpenAir Integration (v0.9.2+)

QuickMap can ingest data directly from OpenAir network imports:

\```r
library(openair)
library(quickmap)

# Workflow: importAURN → convertOpenAirToSpatial → create_pollution_map
aurn_data <- importAURN(site = "London Marylebone Road",
                        year = 2020:2023, pollutant = "no2")
aurn_sf <- convertOpenAirToSpatial(aurn_data, pollutant = "no2")
create_pollution_map(sensor_file = aurn_sf, boroughs = "Westminster")
\```

Supported networks: AURN, LAQN (KCL), SAQN—any importable via OpenAir's import functions.
```

**New vignette**: `vignettes/openair-integration.Rmd` with 3 complete examples (AURN, LAQN, combined networks)

---

## Phase 2 (v0.9.3-0.9.5): Modular Data Abstraction

### Lessons from Phase 1 Usage

Phase 1 testing will reveal:
1. **Common user patterns**: Which networks used most? Single-network or multi-network maps?
2. **Pain points**: Is coordinate lookup cumbersome? Do users want automatic site filtering by geography?
3. **Performance**: How do 50+ sites × 10 years perform? Need lazy evaluation?
4. **Output requirements**: Sufficient with current icons, or need network differentiation?

### Proposed Refactor: `load_pollution_data()` Dispatcher

**Architecture** (implements v0.9.3):

```r
#' Load pollution data from multiple sources
#'
#' Unified loader supporting CSV, RData, OpenAir objects, and sf inputs.
#'
#' @param diffusion_tube_file Path to CSV or "none"
#' @param sensor_file Path to RData, sf object, or "none"
#' @param school_file Path to CSV or "none"
#' @param openair_data Optional. Data.frame from OpenAir import functions
#' @param pollutant Required if openair_data provided
#' @param openair_source Network identifier ("aurn", "laqn") if openair_data provided
#'
#' @return List with elements: dt_data (sf or NULL), sensor_data (sf or NULL),
#'   school_data (sf or NULL), years (vector), metadata (list)
#'
#' @export
load_pollution_data <- function(
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",
  openair_data = NULL,
  pollutant = NULL,
  openair_source = "aurn"
) {

  result <- list(
    dt_data = NULL,
    sensor_data = NULL,
    school_data = NULL,
    openair_data = NULL,
    years = NULL,
    metadata = list()
  )

  # Load diffusion tubes (existing code)
  if (diffusion_tube_file != "none") {
    result$dt_data <- load_data_file(
      diffusion_tube_file,
      "csv",
      required_cols = c("Easting", "Northing")
    )
  }

  # Load sensor data (existing code)
  if (sensor_file != "none") {
    if (inherits(sensor_file, "sf")) {
      # Direct sf object (new capability)
      result$sensor_data <- sensor_file
    } else {
      # RData file path
      result$sensor_data <- load_data_file(
        sensor_file,
        "rdata",
        pollutant = pollutant
      )
    }
  }

  # Load OpenAir data (NEW in v0.9.3)
  if (!is.null(openair_data)) {
    if (is.null(pollutant)) {
      stop("pollutant required when openair_data provided")
    }
    result$openair_data <- convertOpenAirToSpatial(
      openair_data,
      pollutant = pollutant,
      source = openair_source
    )
    result$metadata$openair_source <- openair_source
  }

  # Load schools (existing code)
  if (school_file != "none") {
    result$school_data <- load_data_file(
      school_file,
      "csv",
      required_cols = c("Easting", "Northing", "Level")
    )
  }

  # Determine available years from all temporal sources
  result$years <- determine_years_from_sources(result)

  return(result)
}
```

**Integration into `create_pollution_map()`** (v0.9.3):

```r
create_pollution_map <- function(
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",
  openair_data = NULL,      # NEW PARAMETER
  openair_source = "aurn",  # NEW PARAMETER
  output_file = "pollution_map.html",
  export_image = NULL,
  boroughs,
  pollutant = "no2",
  years = NULL,
  ...
) {

  # Unified data loading (replaces current load_spatial_data_sources)
  loaded_data <- load_pollution_data(
    diffusion_tube_file = diffusion_tube_file,
    sensor_file = sensor_file,
    school_file = school_file,
    openair_data = openair_data,
    pollutant = pollutant,
    openair_source = openair_source
  )

  # Rest of function uses loaded_data$dt_data, loaded_data$sensor_data, etc.
  # ... existing code continues
}
```

**Benefits**:
- Single entry point for all data sources
- Accepts sf objects directly (useful for advanced users preprocessing outside quickmap)
- Encapsulates format-specific logic (CSV coordinate transforms, OpenAir conversion)
- Returns structured output enabling better testing

### Layer System Generalization (v0.9.4)

**Problem**: Current `get_measurement_layers()` hardcodes three layer types. Adding AURN/LAQN requires code modification.

**Solution**: Data-driven layer registry

```r
#' Generate layer configurations from loaded data
#'
#' @param loaded_data Output from load_pollution_data()
#' @param marker_labels Label display mode
#' @return List of layer configurations
#'
#' @keywords internal
generate_layer_configs <- function(loaded_data, marker_labels) {
  layers <- list()

  # Define layer specifications (could externalize to YAML in v1.0)
  layer_specs <- list(
    diffusion_tubes = list(
      data_field = "dt_data",
      icon_shape = "circle",
      icon_color = "blue",
      temporal = TRUE
    ),
    breathe_london = list(
      data_field = "sensor_data",
      icon_shape = "diamond",
      icon_color = "purple",
      temporal = TRUE
    ),
    openair_network = list(
      data_field = "openair_data",
      icon_shape = "square",      # Distinguish from BL sensors
      icon_color = "green",
      temporal = TRUE
    ),
    schools = list(
      data_field = "school_data",
      icon_shape = "cross",
      icon_color = "red",
      temporal = FALSE
    )
  )

  # Build enabled layers from available data
  for (layer_name in names(layer_specs)) {
    spec <- layer_specs[[layer_name]]
    data_obj <- loaded_data[[spec$data_field]]

    if (!is.null(data_obj) && nrow(data_obj) > 0) {
      layers[[layer_name]] <- list(
        enabled = TRUE,
        data = data_obj,  # Direct reference
        icon_shape = spec$icon_shape,
        icon_color = spec$icon_color,
        temporal = spec$temporal,
        options = list(marker_labels = marker_labels)
      )
    }
  }

  return(layers)
}
```

**Icon rendering update** (R/quickmap.R:1205, `create_generic_icons()`):

```r
# Current: hardcoded switch statement
switch(layer_type,
  "dt_sites" = list(shape = "circle", color = colours),
  "bl_nodes" = list(shape = "diamond", color = colours),
  "schools" = list(shape = "cross", color = colour_scales$schools$colours),
  ...
)

# Refactored: use layer config parameters
icon_html <- create_icon_svg(
  shape = layer_config$icon_shape,    # From config
  fill_color = colour,                 # From pollutant value
  stroke_color = layer_config$icon_color,  # From config
  size = base_size * image_scale_factor
)
```

**New SVG icon generator**:

```r
#' Generate SVG icon markup for different shapes
#' @param shape One of: "circle", "diamond", "square", "triangle", "cross"
#' @param fill_color Hex color for fill
#' @param stroke_color Hex color for border
#' @param size Icon size in pixels
#' @return HTML string with inline SVG
create_icon_svg <- function(shape, fill_color, stroke_color, size) {
  viewbox <- "0 0 100 100"

  svg_path <- switch(shape,
    "circle" = '<circle cx="50" cy="50" r="40" />',
    "diamond" = '<polygon points="50,10 90,50 50,90 10,50" />',
    "square" = '<rect x="15" y="15" width="70" height="70" />',
    "triangle" = '<polygon points="50,15 85,85 15,85" />',
    "cross" = '<path d="M30,10 L70,10 L70,30 L90,30 L90,70 L70,70 L70,90 L30,90 L30,70 L10,70 L10,30 L30,30 Z" />',
    stop("Unknown icon shape: ", shape)
  )

  sprintf(
    '<svg viewBox="%s" width="%d" height="%d" xmlns="http://www.w3.org/2000/svg">
       <g fill="%s" stroke="%s" stroke-width="3">%s</g>
     </svg>',
    viewbox, size, size, fill_color, stroke_color, svg_path
  )
}
```

**Result**: Adding new network icons requires config entry only, no code modification.

---

## Alternative Use Cases and User Workflows

### Use Case 1: Local Authority Annual Reporting

**User**: Environmental health officer at London borough
**Goal**: Generate annual air quality status report maps showing compliance with WHO guidelines

**Workflow**:
```r
library(openair)
library(quickmap)

# Load latest year AURN + LAQN sites in borough
aurn <- importAURN(year = 2023, pollutant = "no2")
laqn <- importKCL(year = 2023, pollutant = "no2")

# Filter to borough (using OpenAir)
borough_sites <- c("Site A", "Site B", "Site C")  # From importMeta()
aurn_local <- selectByDate(aurn[aurn$site %in% borough_sites, ])
laqn_local <- selectByDate(laqn[laqn$site %in% borough_sites, ])

# Convert both networks
aurn_sf <- convertOpenAirToSpatial(aurn_local, "no2", "aurn")
laqn_sf <- convertOpenAirToSpatial(laqn_local, "no2", "kcl")

# Combine networks (sf's rbind)
combined_sf <- rbind(
  aurn_sf %>% mutate(network = "AURN"),
  laqn_sf %>% mutate(network = "LAQN")
)

# Generate report map with borough theme
create_pollution_map(
  sensor_file = combined_sf,
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = 2023,
  theme_file = "inst/themes/wandsworth_blue.yaml",
  output_file = "wandsworth_aq_2023.html",
  export_image = c(1920, 1080)  # For PDF report inclusion
)
```

**Requirements satisfied**:
- Multi-network display (AURN + LAQN combined)
- Annual snapshot (years = 2023 filters temporal data)
- Branded styling (borough theme)
- High-res JPG export for print reports

### Use Case 2: Academic Research - Temporal Trend Analysis

**User**: Environmental science researcher
**Goal**: Visualize 10-year NO2 trends across London monitoring network

**Workflow**:
```r
# Download decade of data
sites_london <- importMeta(source = "aurn") %>%
  filter(grepl("London", site)) %>%
  pull(site)

aurn_decade <- importAURN(
  site = sites_london,
  year = 2014:2023,
  pollutant = "no2"
)

# Convert to spatial
aurn_sf <- convertOpenAirToSpatial(aurn_decade, "no2", "aurn")

# Create animated map showing annual changes
create_pollution_map(
  sensor_file = aurn_sf,
  boroughs = c("Westminster", "Camden", "Islington", "Hackney"),
  pollutant = "no2",
  years = 2014:2023,
  autoplay = TRUE,
  play_speed = 1000,  # 1 second per year
  colour_scale = "stripes_no2",  # Show trends visually
  output_file = "london_no2_trends_2014_2023.html"
)
```

**Advanced variant** (post-v0.9.5): Calculate year-on-year deltas

```r
# Use OpenAir's timeAverage for robust temporal aggregation
annual_means <- timeAverage(aurn_decade, avg.time = "year", type = "site")

# Calculate deltas (requires custom preprocessing)
deltas <- annual_means %>%
  group_by(site) %>%
  arrange(date) %>%
  mutate(
    no2_delta = no2 - lag(no2),
    year = year(date)
  ) %>%
  filter(!is.na(no2_delta))

# Convert delta data to spatial
delta_sf <- convertOpenAirToSpatial(deltas, "no2_delta", "aurn")

# Map year-on-year changes (reds = increasing, blues = decreasing)
create_pollution_map(
  sensor_file = delta_sf,
  boroughs = "Greater London",
  pollutant = "no2_delta",
  colour_scale = "deltas",  # Existing diverging scale
  years = 2015:2023  # Deltas start 2015 (need 2014 baseline)
)
```

**Requirements satisfied**:
- Long time series (10 years)
- Autoplay animation for presentation
- Custom preprocessing (deltas) upstream of quickmap
- Diverging color scale for negative/positive changes

### Use Case 3: Consultant - Multi-Borough Impact Assessment

**User**: Air quality consultant
**Goal**: Compare pollution levels around proposed development sites across multiple boroughs

**Workflow**:
```r
# Load LAQN for affected boroughs
laqn_data <- importKCL(
  year = 2020:2023,
  pollutant = c("no2", "pm25")  # Both pollutants
)

# Filter to affected boroughs (using spatial filter)
affected_boroughs <- c("Southwark", "Lewisham", "Greenwich")
borough_sites <- importMeta(source = "kcl") %>%
  filter(local_authority %in% affected_boroughs) %>%
  pull(site)

laqn_filtered <- laqn_data %>% filter(site %in% borough_sites)

# Convert each pollutant separately
no2_sf <- convertOpenAirToSpatial(laqn_filtered, "no2", "kcl")
pm25_sf <- convertOpenAirToSpatial(laqn_filtered, "pm25", "kcl")

# Generate separate maps for each pollutant
create_pollution_map(
  sensor_file = no2_sf,
  boroughs = affected_boroughs,
  pollutant = "no2",
  years = 2020:2023,
  colour_scale = "who_no2",
  output_file = "development_sites_no2.html",
  export_image = c(1200, 1200)
)

create_pollution_map(
  sensor_file = pm25_sf,
  boroughs = affected_boroughs,
  pollutant = "pm25",
  years = 2020:2023,
  colour_scale = "gla_pm25",
  output_file = "development_sites_pm25.html",
  export_image = c(1200, 1200)
)

# Future enhancement (v1.0): Side-by-side pollutant comparison in single map
```

**Requirements satisfied**:
- Geographic subsetting (3 boroughs)
- Multi-pollutant analysis (separate maps)
- Site filtering by local authority (via importMeta)
- Consistent output format for report compilation

### Use Case 4: Animate Pollution Episodes

**User**: Environmental health officer / researcher
**Goal**: Investigate and communicate acute pollution events with temporal progression visualization

**Workflow**:
```r
library(openair)
library(quickmap)

# Load hourly data for pollution episode (e.g., December 2023 cold snap)
laqn_hourly <- importKCL(
  site = c("Wandsworth Town Hall", "Putney High Street", "Tooting Broadway"),
  year = 2023,
  pollutant = "no2"
)

# Filter to episode window (48 hours)
episode_data <- selectByDate(
  laqn_hourly,
  start = "2023-12-15 00:00",
  end = "2023-12-16 23:00"
)

# Convert to sftime with hourly resolution
episode_sftime <- convertOpenAirToSpatial(
  episode_data,
  pollutant = "no2",
  source = "kcl",
  avg.time = "hour"  # Returns sftime object
)

# Create animated map
create_pollution_map(
  sensor_file = episode_sftime,
  boroughs = "Wandsworth",
  pollutant = "no2",
  temporal_resolution = "hour",  # NEW parameter
  autoplay = TRUE,
  play_speed = 500,  # 2 hours per second
  colour_scale = "who_no2",
  output_file = "wandsworth_episode_dec2023.html"
)
```

**Requirements**:
- sftime support for sub-daily temporal data
- Temporal controls: hour slider or datetime picker
- Performance: 3 sites × 48 hours = 144 features (manageable)
- Animation controls: play/pause, speed adjustment
- Export: Creates self-contained HTML showing pollution buildup/dispersal

**Impact**: Enables communication of acute health risk events to public/decision-makers with spatial-temporal context.

---

### Use Case 5: Correlate Pollution with Traffic/Activity Data

**User**: Transport planner / air quality researcher
**Goal**: Visualize correlation between pollution levels and traffic flow to identify emission hotspots

**Workflow**:
```r
# Load hourly pollution data
laqn_hourly <- importKCL(year = 2023, pollutant = "no2")
no2_sftime <- convertOpenAirToSpatial(laqn_hourly, "no2", "kcl", avg.time = "hour")

# Load traffic count data (hypothetical external dataset)
traffic_data <- read.csv("tfl_traffic_counts_2023.csv")
# Columns: datetime, site_id, latitude, longitude, vehicle_count

# Convert traffic to sftime
traffic_sftime <- traffic_data %>%
  mutate(date = as.POSIXct(datetime)) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  as_sftime(time_column = "date")

# Create dual-layer map (requires Phase 2 multi-layer support)
create_pollution_map(
  layers = list(
    pollution = list(
      data = no2_sftime,
      pollutant = "no2",
      colour_scale = "who_no2",
      icon_shape = "diamond"
    ),
    traffic = list(
      data = traffic_sftime,
      variable = "vehicle_count",
      colour_scale = "traffic_scale",  # Custom scale
      icon_shape = "square"
    )
  ),
  boroughs = "Westminster",
  temporal_resolution = "hour",
  sync_temporal_layers = TRUE,  # Both layers advance together
  output_file = "pollution_traffic_correlation.html"
)
```

**Requirements**:
- Multi-layer temporal synchronization (common time axis)
- Custom colour scales for non-pollution variables
- Layer opacity controls for visual comparison
- Export correlations to CSV for statistical analysis

**Extension (v1.1+)**: Scatterplot overlay showing pollution vs traffic correlation coefficient

---

### Use Case 6: Build Predictive Models

**User**: Academic researcher / data scientist
**Goal**: Use quickmap as visualization endpoint for spatiotemporal pollution modeling workflow

**Workflow**:
```r
library(mgcv)  # GAM modeling
library(openair)
library(quickmap)

# Load training data (hourly LAQN + covariates)
laqn <- importKCL(year = 2022:2023, pollutant = "no2")
laqn_sftime <- convertOpenAirToSpatial(laqn, "no2", "kcl", avg.time = "hour")

# Add covariates (meteorology, traffic, temporal features)
model_data <- laqn_sftime %>%
  mutate(
    hour = hour(time_column),
    weekday = wday(time_column),
    month = month(time_column),
    # Join with meteorology data (wind speed, temperature)
    # Join with traffic data
  )

# Extract data for modeling (convert sf to regular data.frame)
training_df <- model_data %>%
  st_drop_geometry() %>%
  as.data.frame()

# Train GAM
model <- gam(
  no2 ~ s(hour) + s(weekday) + s(month) +
        s(Longitude, Latitude) + s(wind_speed) + s(temperature),
  data = training_df,
  family = Gamma(link = "log")
)

# Generate predictions on spatial grid
pred_grid <- expand.grid(
  Longitude = seq(-0.25, 0.05, by = 0.01),
  Latitude = seq(51.4, 51.6, by = 0.01),
  hour = 8,  # Morning rush hour
  weekday = 2,  # Monday
  month = 1,  # January
  wind_speed = 3,
  temperature = 5
)

pred_grid$no2_predicted <- predict(model, pred_grid, type = "response")
pred_grid$no2_se <- predict(model, pred_grid, type = "response", se.fit = TRUE)$se.fit

# Convert predictions to sftime for mapping
pred_sftime <- pred_grid %>%
  st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326) %>%
  mutate(date = as.POSIXct("2024-01-15 08:00:00")) %>%
  as_sftime(time_column = "date")

# Map predictions
create_pollution_map(
  sensor_file = pred_sftime,
  pollutant = "no2_predicted",
  boroughs = "Greater London",
  colour_scale = "who_no2",
  marker_labels = "values",
  output_file = "no2_predictions_jan_mon_8am.html"
)

# Map uncertainty
create_pollution_map(
  sensor_file = pred_sftime,
  pollutant = "no2_se",
  boroughs = "Greater London",
  colour_scale = "uncertainty_scale",  # Custom diverging scale
  output_file = "no2_prediction_uncertainty.html"
)
```

**Requirements**:
- sftime compatibility with modeling workflows (easy conversion to/from sf)
- Support for predicted values (not just observations)
- Uncertainty visualization (standard errors, prediction intervals)
- Grid-based predictions (not just station locations)

**Impact**: Positions quickmap as research tool for spatiotemporal exposure modeling

---

### Use Case 7: Data Assimilation / Multi-Network Fusion

**User**: Advanced researcher / academic group
**Goal**: Combine multiple heterogeneous data sources into unified pollution field estimate

**Workflow**:
```r
library(gstat)  # Spatiotemporal kriging
library(openair)
library(quickmap)

# Load multiple networks with different temporal resolutions
aurn <- importAURN(year = 2023, pollutant = "no2")  # Sparse, high quality
laqn <- importKCL(year = 2023, pollutant = "no2")   # Dense, moderate quality
diffusion_tubes <- read.csv("dt_2023.csv")          # Very sparse, annual only

# Convert to common temporal resolution (daily for fusion)
aurn_daily <- convertOpenAirToSpatial(aurn, "no2", "aurn", avg.time = "day")
laqn_daily <- convertOpenAirToSpatial(laqn, "no2", "kcl", avg.time = "day")

# Diffusion tubes (annual) - expand to daily with uncertainty
dt_sf <- load_data_file(diffusion_tubes, "csv")  # Annual values
# ... expand to daily with high uncertainty

# Combine networks with quality weights
combined_data <- bind_rows(
  aurn_daily %>% mutate(network = "AURN", weight = 1.0),
  laqn_daily %>% mutate(network = "LAQN", weight = 0.8),
  dt_daily %>% mutate(network = "DT", weight = 0.5)
)

# Spatiotemporal kriging (simplified example)
# ... kriging model fitted to combined_data

# Generate fused predictions on grid × time
fusion_output <- predict_spatiotemporal_kriging(
  model,
  spatial_grid = london_grid,
  temporal_range = seq(as.Date("2023-01-01"), as.Date("2023-12-31"), by = "day")
)

# Convert to sftime
fusion_sftime <- fusion_output %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  as_sftime(time_column = "date")

# Map fused field with uncertainty
create_pollution_map(
  layers = list(
    fusion_mean = list(
      data = fusion_sftime,
      variable = "no2_fused",
      colour_scale = "who_no2",
      icon_shape = "circle"
    ),
    observations = list(
      data = combined_data,
      variable = "no2",
      colour_scale = "who_no2",
      icon_shape = "triangle",  # Differentiate from predictions
      opacity = 0.7
    )
  ),
  boroughs = "Greater London",
  temporal_resolution = "day",
  output_file = "london_no2_fusion_2023.html"
)
```

**Requirements**:
- Multi-source data integration (different networks, resolutions, quality)
- Support for model outputs (kriging, machine learning predictions)
- Uncertainty quantification visualization
- Comparison of observations vs predictions (overlay layers)

**Impact**: Enables cutting-edge air quality research, positions quickmap as tool for spatiotemporal environmental modeling community

---

### Use Case 8: Citizen Science / Public Engagement

**User**: Community group monitoring local air quality
**Goal**: Visualize low-cost sensor network alongside official LAQN stations

**Workflow** (requires custom data prep):
```r
# Load official LAQN data
laqn <- importKCL(year = 2023, pollutant = "no2")
laqn_sf <- convertOpenAirToSpatial(laqn, "no2", "kcl")

# Load community sensor data (CSV format)
community_sensors <- read.csv("community_sensors_2023.csv")
# Columns: date, sensor_id, latitude, longitude, no2

# Process community data to match OpenAir format
community_oa <- community_sensors %>%
  mutate(
    date = as.POSIXct(date),
    site = paste("Community", sensor_id)
  ) %>%
  select(date, site, no2)

# Convert to spatial (use generic converter)
community_sf <- convertOpenAirToSpatial(
  community_oa,
  pollutant = "no2",
  source = "custom",
  site_meta = community_sensors %>%
    distinct(site = paste("Community", sensor_id),
             latitude, longitude)
)

# Combine official + community networks
combined <- rbind(
  laqn_sf %>% mutate(network = "LAQN Official"),
  community_sf %>% mutate(network = "Community")
)

# Map with differentiated icons (future: layer system enhancement)
create_pollution_map(
  sensor_file = combined,
  boroughs = "Lambeth",
  pollutant = "no2",
  years = 2023,
  marker_labels = "labels",  # Show sensor IDs
  output_file = "lambeth_community_monitoring.html"
)
```

**Future requirement**: Layer system needs to support icon differentiation by `network` column—requires Phase 2 refactor.

---

## Layer Generalization Strategy: Technical Deep Dive

### Problem Statement

Current quickmap architecture has **tight coupling** between:
1. Data source (file parameter: diffusion_tube_file, sensor_file)
2. Layer name (bl_nodes, dt_sites, schools)
3. Icon type (diamond, circle, cross)
4. Pollutant column (hardcoded: "no2" for dt_sites, parameter for bl_nodes)

Adding AURN and LAQN as distinct layers requires:
- New function parameters (aurn_file, laqn_file)
- New layer names in `get_measurement_layers()`
- New icon shapes in `create_generic_icons()`
- Switch statement updates throughout codebase

**Scalability issue**: Adding 5 more networks = 20+ code modification sites. Not sustainable.

### Solution Architecture: Data-Driven Layer System

**Core principle**: Layers defined by **data properties**, not hardcoded logic.

#### Component 1: Layer Schema

Define what makes a layer in structured format (list or future YAML):

```r
#' Layer schema specification
#' @field id Unique layer identifier (used in JS group controls)
#' @field label Human-readable name for legend/UI
#' @field data_source sf object with temporal/pollutant data
#' @field geometry_type Point, Line, or Polygon (currently all Point)
#' @field temporal Logical. Has time dimension?
#' @field icon List with shape, base_color, size parameters
#' @field pollutant_col Character. Column name for pollutant values (NULL for static layers)
#' @field label_col Character. Column name for marker labels (NULL for none)
#' @field z_index Numeric. Stacking order (higher = on top)
layer_schema <- list(
  id = character,
  label = character,
  data_source = "sf",
  geometry_type = character,
  temporal = logical,
  icon = list(shape = character, base_color = character, size_px = numeric),
  pollutant_col = character,
  label_col = character,
  z_index = numeric
)
```

#### Component 2: Layer Factory Function

Generate layer configs from sf objects + metadata:

```r
#' Create layer configuration from spatial data
#'
#' @param layer_id Unique identifier
#' @param sf_data sf object with point geometry
#' @param label Display name
#' @param icon_params List: shape, color, size
#' @param pollutant_col Column name for values (NULL if static)
#' @param temporal Does data have year dimension?
#' @param z_index Stacking order
#'
#' @return Layer config object
create_layer_config <- function(layer_id, sf_data, label, icon_params,
                                 pollutant_col = NULL, temporal = TRUE,
                                 z_index = 100) {

  # Validate sf_data structure
  if (!inherits(sf_data, "sf")) {
    stop("sf_data must be sf object")
  }
  if (!sf::st_geometry_type(sf_data, by_geometry = FALSE) %in% c("POINT", "MULTIPOINT")) {
    stop("Currently only POINT geometry supported")
  }
  if (temporal && !"year_str" %in% names(sf_data)) {
    stop("Temporal layers require 'year_str' column")
  }
  if (!is.null(pollutant_col) && !pollutant_col %in% names(sf_data)) {
    stop("Pollutant column '", pollutant_col, "' not found in sf_data")
  }

  # Build config
  config <- list(
    id = layer_id,
    label = label,
    data = sf_data,
    geometry_type = "POINT",
    temporal = temporal,
    icon = list(
      shape = icon_params$shape %||% "circle",
      base_color = icon_params$color %||% "#3388ff",
      size_px = icon_params$size %||% 20
    ),
    pollutant_col = pollutant_col,
    label_col = icon_params$label_col %||% "siteCode",
    z_index = z_index,
    enabled = TRUE
  )

  class(config) <- c("quickmap_layer", "list")
  return(config)
}
```

#### Component 3: Universal Layer Renderer

Replace separate icon/layer functions with generic renderer:

```r
#' Add layer to Leaflet map (generic renderer)
#'
#' Replaces current add_layer() with icon-type-agnostic version
#'
#' @param map Leaflet map object
#' @param layer_config Layer config from create_layer_config()
#' @param year Character. Year to filter (NULL for static layers)
#' @param colour_scale_obj Color scale object with thresholds/colours
#' @param marker_labels Label display mode
#' @param scale_factor Numeric. Icon size multiplier for JPG export
#'
#' @return Updated leaflet map
add_generic_layer <- function(map, layer_config, year = NULL,
                               colour_scale_obj = NULL, marker_labels = FALSE,
                               scale_factor = 1.0) {

  # Filter temporal layers to year
  layer_data <- if (layer_config$temporal && !is.null(year)) {
    layer_config$data %>% filter(year_str == year)
  } else {
    layer_config$data
  }

  if (nrow(layer_data) == 0) return(map)

  # Generate icon HTML for each feature
  layer_data$icon_html <- mapply(
    function(pollutant_val, label_val) {
      # Determine icon color from pollutant value
      fill_color <- if (!is.null(layer_config$pollutant_col) &&
                        !is.null(colour_scale_obj)) {
        assign_colour_from_scale(pollutant_val, colour_scale_obj)
      } else {
        layer_config$icon$base_color  # Static color
      }

      # Generate SVG icon
      icon_svg <- create_icon_svg(
        shape = layer_config$icon$shape,
        fill_color = fill_color,
        stroke_color = layer_config$icon$base_color,
        size = layer_config$icon$size_px * scale_factor
      )

      # Wrap in divIcon HTML
      leaflet::makeIcon(
        iconUrl = paste0("data:image/svg+xml;charset=UTF-8,",
                         URLencode(icon_svg))
      )
    },
    layer_data[[layer_config$pollutant_col]],
    layer_data[[layer_config$label_col]],
    SIMPLIFY = FALSE
  )

  # Generate marker labels
  layer_data$marker_label <- if (marker_labels) {
    generate_marker_labels_generic(layer_data, layer_config, marker_labels)
  } else NULL

  # Add to map
  map %>%
    leaflet::addMarkers(
      data = layer_data,
      icon = ~icon_html,
      label = ~marker_label,
      group = layer_config$id,  # Group for year control show/hide
      options = leaflet::markerOptions(zIndexOffset = layer_config$z_index)
    )
}
```

#### Component 4: Multi-Network Layer Assembly

Top-level function to build all layers from loaded data:

```r
#' Assemble all layers from loaded data sources
#'
#' @param loaded_data Output from load_pollution_data()
#' @param pollutant Active pollutant for color mapping
#' @param marker_labels Label mode
#'
#' @return List of layer configs
assemble_map_layers <- function(loaded_data, pollutant, marker_labels) {
  layers <- list()

  # Diffusion tubes (if present)
  if (!is.null(loaded_data$dt_data)) {
    layers$diffusion_tubes <- create_layer_config(
      layer_id = "dt_tubes",
      sf_data = loaded_data$dt_data,
      label = "Diffusion Tubes",
      icon_params = list(shape = "circle", color = "#0066cc", size = 18),
      pollutant_col = pollutant,
      temporal = TRUE,
      z_index = 100
    )
  }

  # Breathe London sensors (if present)
  if (!is.null(loaded_data$sensor_data)) {
    layers$breathe_london <- create_layer_config(
      layer_id = "bl_sensors",
      sf_data = loaded_data$sensor_data,
      label = "Breathe London Network",
      icon_params = list(shape = "diamond", color = "#9933ff", size = 20),
      pollutant_col = pollutant,
      temporal = TRUE,
      z_index = 110
    )
  }

  # OpenAir networks (AURN, LAQN combined, if present)
  if (!is.null(loaded_data$openair_data)) {
    # If network column exists, split into separate layers
    if ("network" %in% names(loaded_data$openair_data)) {
      unique_networks <- unique(loaded_data$openair_data$network)
      for (net in unique_networks) {
        net_data <- loaded_data$openair_data %>% filter(network == net)
        layers[[tolower(net)]] <- create_layer_config(
          layer_id = paste0("oa_", tolower(net)),
          sf_data = net_data,
          label = paste(net, "Monitoring"),
          icon_params = list(
            shape = if (net == "AURN") "square" else "triangle",
            color = if (net == "AURN") "#00aa00" else "#ff6600",
            size = 19
          ),
          pollutant_col = pollutant,
          temporal = TRUE,
          z_index = 120
        )
      }
    } else {
      # Single OpenAir layer
      layers$openair <- create_layer_config(
        layer_id = "oa_network",
        sf_data = loaded_data$openair_data,
        label = "OpenAir Monitoring Network",
        icon_params = list(shape = "square", color = "#00aa00", size = 19),
        pollutant_col = pollutant,
        temporal = TRUE,
        z_index = 120
      )
    }
  }

  # Schools (static layer, if present)
  if (!is.null(loaded_data$school_data)) {
    layers$schools <- create_layer_config(
      layer_id = "schools",
      sf_data = loaded_data$school_data,
      label = "Schools",
      icon_params = list(shape = "cross", color = "#cc0000", size = 16),
      pollutant_col = NULL,  # Static layer, no color mapping
      temporal = FALSE,
      z_index = 200  # On top of pollution layers
    )
  }

  return(layers)
}
```

#### Integration Example

Refactored `create_pollution_map()` main loop:

```r
# Replace current get_measurement_layers() + generate_map_layers() loop
layer_configs <- assemble_map_layers(loaded_data, pollutant, marker_labels)

for (yr in unique(years)) {
  for (layer_id in names(layer_configs)) {
    html_map <- add_generic_layer(
      html_map,
      layer_config = layer_configs[[layer_id]],
      year = yr,
      colour_scale_obj = legend_info,
      marker_labels = marker_labels,
      scale_factor = 1.0
    )
  }

  # Static map export (similar loop with scale_factor)
  if (image_export) {
    # ... static map rendering ...
  }
}
```

### Benefits of Generalized System

1. **Extensibility**: Adding new network = adding config in `assemble_map_layers()`, no changes to renderer
2. **Testability**: Layer configs are data objects, can unit test creation/validation independently
3. **User customization**: Advanced users can build custom layer configs, pass to renderer
4. **Future features**:
   - Save layer configs as YAML for reuse
   - Layer visibility controls (checkboxes for networks)
   - Dynamic styling (hover highlights, click interactions)
   - Non-point geometries (polygons for dispersion modeling zones)

### Migration Path

**v0.9.3**: Implement layer factory functions alongside existing code
**v0.9.4**: Refactor `create_pollution_map()` to use new system, keep old functions as fallback
**v0.9.5**: Remove deprecated functions, finalize API, document for v1.0

---

## Comparative Analysis: R vs Python Approaches

### Temporal Visualization Patterns

| Feature | R (leaflet) | Python (folium) | Python (kepler.gl) | quickmap v0.9.5 |
|---------|-------------|-----------------|---------------------|-----------------|
| **Base library** | Leaflet.js | Leaflet.js | deck.gl (WebGL) | Leaflet.js |
| **Temporal control** | Layer groups + JS | TimestampedGeoJson | Built-in time slider | Roller menu (custom) |
| **Performance** | Good (<1000 points) | Good (<1000 points) | Excellent (millions) | Optimized (tested to 500 sites × 10 years) |
| **Static export** | webshot2 (HTML→JPG) | Limited | No | Full JPG export |
| **3D visualization** | No | No | Yes | No (2D only) |
| **R integration** | Native | reticulate | reticulate | Native |
| **Offline use** | Yes (self-contained HTML) | Yes | No (requires tile server) | Yes |

**Conclusion**: quickmap's Leaflet+static export niche is **underserved** in Python ecosystem. Kepler.gl excels at exploratory analysis (notebooks), but lacks report-ready exports.

### Data Format Ecosystem

| Format | R Package | Python Equivalent | Use Case | quickmap Support |
|--------|-----------|-------------------|----------|------------------|
| **sf (Simple Features)** | sf | geopandas | Vector spatial data | v0.9.1 (core) |
| **stars (Data Cubes)** | stars | xarray | Gridded spatiotemporal | Not applicable (point data) |
| **sftime** | sftime | None | Irregular spacetime points | Compatible via sf |
| **OpenAir temporal** | openair | None | Air quality networks | v0.9.2+ (converter) |
| **NetCDF** | ncdf4, stars | netCDF4, xarray | Climate/environmental grids | Future (v1.1+) |
| **GeoJSON** | sf, geojsonsf | geopandas | Web mapping | Via sf read/write |

**Key insight**: R's **sf** package is lingua franca for spatial data, analogous to Python's **geopandas**. quickmap's decision to use sf as intermediate format aligns with ecosystem standards.

### Temporal Aggregation Best Practices

**OpenAir approach** ([Journal article](https://openair-project.github.io/book/)):
- Use `timeAverage()` for all temporal aggregation (hourly → daily → monthly → annual)
- Respects `data.thresh` parameter (minimum data capture threshold)
- Handles missing data via `na.rm` and gap filling
- Statistic options: mean, median, max, percentile, etc.

**sf/dplyr approach**:
- Group by site + year: `group_by(site, year) %>% summarise(pollutant = mean(pollutant, na.rm = TRUE))`
- More manual but flexible
- Can combine with spatial operations (buffer, intersect)

**quickmap strategy**: Use **OpenAir's timeAverage()** in converter functions (v0.9.2+) to leverage validated aggregation logic, then convert aggregated results to sf. Best of both worlds.

---

## Implementation Risks and Mitigation

### Risk 1: Coordinate Mismatch Between Networks

**Issue**: AURN uses WGS84 lat/lon (EPSG:4326), diffusion tubes use British National Grid (EPSG:27700). Mixing in single map requires consistent CRS.

**Mitigation**:
- All converters output WGS84 (current standard in quickmap)
- Add CRS validation in `assemble_map_layers()`:
  ```r
  if (sf::st_crs(layer_data) != sf::st_crs(4326)) {
    warning("Converting layer ", layer_id, " to WGS84")
    layer_data <- sf::st_transform(layer_data, 4326)
  }
  ```
- Document CRS requirements in `convertOpenAirToSpatial()` help file

### Risk 2: Memory Usage with Large Networks

**Issue**: AURN has ~300 sites × 10 years × 8760 hourly obs = 26M rows before aggregation. Loading entire network into memory problematic.

**Mitigation**:
- Phase 1: Aggregate to annual in `convertOpenAirToSpatial()` BEFORE spatial conversion (reduces 8760:1)
- Phase 2 (v0.9.4): Add site filtering parameter:
  ```r
  convertOpenAirToSpatial <- function(
    openair_data,
    pollutant,
    site_filter = NULL,  # NEW: vector of site codes
    ...
  ) {
    if (!is.null(site_filter)) {
      openair_data <- openair_data %>% filter(site %in% site_filter)
    }
    # ... rest of function
  }
  ```
- Document recommended workflow: filter sites BEFORE conversion

### Risk 3: Icon Overlap in Dense Networks

**Issue**: LAQN has ~100 sites in 32 km² (Greater London). At city scale, icons overlap unreadably.

**Mitigation**:
- Phase 1: Use marker clustering (leaflet package built-in):
  ```r
  map %>% addMarkers(..., clusterOptions = markerClusterOptions())
  ```
- Test threshold: Enable clustering if layer > 50 sites
- Phase 2: Implement dynamic sizing based on zoom level (JavaScript callback)
- Document: Recommend borough-level filtering for detailed analysis

### Risk 4: Color Scale Misapplication

**Issue**: User loads PM2.5 data but applies NO2 color scale (incorrect thresholds).

**Mitigation**:
- Add pollutant validation in `create_pollution_map()`:
  ```r
  scale_pollutant <- colour_scales[[colour_scale]]$pollutant
  if (!is.null(scale_pollutant) && scale_pollutant != pollutant) {
    warning(
      "Color scale '", colour_scale, "' designed for ", scale_pollutant,
      " but mapping ", pollutant, ". Results may be misleading.",
      call. = FALSE
    )
  }
  ```
- Recommend pollutant-specific scales in documentation
- Future (v1.0): Auto-select scale based on pollutant if not specified

### Risk 5: Breaking Changes to v0.9.1 Users

**Issue**: Refactoring `load_data_file()` and `get_measurement_layers()` could break existing user scripts.

**Mitigation**:
- Maintain backward compatibility:
  ```r
  # Old function signature still works
  create_pollution_map(
    diffusion_tube_file = "data.csv",  # v0.9.1 style
    sensor_file = "sensors.Rdata"
  )

  # New parameters optional
  create_pollution_map(
    diffusion_tube_file = "data.csv",
    openair_data = aurn_data,  # v0.9.2+ addition
    pollutant = "no2"
  )
  ```
- Internal refactoring transparent to users
- Document migration in NEWS.md for each version

---

## Version-Specific Deliverables

### v0.9.2 Deliverables (Week 1-2)

**Code**:
- [ ] `convertOpenAirToSpatial()` function (300 lines)
- [ ] Unit tests for converter (test_openair_conversion.R)
- [ ] Integration test: AURN London → quickmap HTML
- [ ] Integration test: LAQN → quickmap HTML

**Documentation**:
- [ ] Update CLAUDE.md with OpenAir integration section
- [ ] New vignette: `vignettes/openair-networks.Rmd` (3 examples)
- [ ] Update README.md with OpenAir workflow quickstart
- [ ] NEWS.md entry documenting new feature

**Validation**:
- [ ] Converter tested with AURN, LAQN, SAQN (3 networks)
- [ ] Multi-year handling verified (1 year, 5 years, 10 years)
- [ ] Coordinate accuracy spot-checked (compare vs online maps)
- [ ] Performance benchmark: 100 sites × 5 years < 30 seconds

### v0.9.3 Deliverables (Week 3-4)

**Code**:
- [ ] `load_pollution_data()` dispatcher function
- [ ] Refactor `create_pollution_map()` to use new loader
- [ ] Add `openair_data` and `openair_source` parameters
- [ ] Update `get_measurement_layers()` to accept direct sf objects
- [ ] Backward compatibility tests (all v0.9.1 examples still work)

**Documentation**:
- [ ] Update function documentation (roxygen2)
- [ ] Migration guide: v0.9.1 → v0.9.3 (for users with custom scripts)
- [ ] Architecture diagram: data flow from load_pollution_data() → map output

**Validation**:
- [ ] All v0.9.2 tests pass with new loader
- [ ] Mixed source test: Diffusion tubes + AURN + schools in single map
- [ ] Direct sf object test: User creates sf outside quickmap, passes to sensor_file

### v0.9.4 Deliverables (Week 5-6)

**Code**:
- [ ] `create_layer_config()` factory function
- [ ] `create_icon_svg()` generic icon generator (5 shapes)
- [ ] `add_generic_layer()` universal renderer
- [ ] `assemble_map_layers()` multi-network layer builder
- [ ] Refactor main loop to use new layer system
- [ ] Add `network` column support for automatic layer splitting

**Documentation**:
- [ ] Advanced usage vignette: Custom layer configs
- [ ] Developer guide: Extending layer system with new icon shapes
- [ ] Update OpenAir vignette with multi-network examples

**Validation**:
- [ ] Icon differentiation test: AURN (squares) vs LAQN (triangles) visually distinct
- [ ] 4-network map test: Diffusion tubes + BL + AURN + LAQN + schools (5 layers)
- [ ] Z-index test: Schools render on top of pollution layers
- [ ] Static export test: All icons render correctly in JPG at 1920×1080

### v0.9.5 Deliverables (Week 7-8)

**Code**:
- [ ] Finalize API: Remove deprecated functions, consolidate helpers
- [ ] Performance optimization: Profile layer rendering, optimize bottlenecks
- [ ] Add marker clustering for dense networks (>50 sites)
- [ ] Implement pollutant/scale validation warnings
- [ ] Comprehensive test suite: 50+ test cases covering all pathways

**Documentation**:
- [ ] Complete package documentation (all functions roxygen2 documented)
- [ ] User guide: Best practices for different use cases (4 detailed examples)
- [ ] Developer guide: Contributing new data sources / networks
- [ ] CHANGELOG: Comprehensive v0.9.1 → v0.9.5 migration summary
- [ ] Prepare for v1.0: Identify remaining gaps, propose roadmap

**Validation**:
- [ ] Real-world testing: 5 external users test with their data
- [ ] Performance benchmarks: Document load times for various data sizes
- [ ] Cross-platform testing: Windows, macOS, Linux compatibility
- [ ] Browser testing: Chrome, Firefox, Safari render maps correctly
- [ ] Accessibility audit: Screen reader compatibility, keyboard navigation

---

## Post-v0.9.5: Toward v1.0

### Architectural Prerequisites

By v0.9.5 completion, codebase should have:
1. **Modular data loading** (any format → sf via loader functions)
2. **Generic layer system** (data-driven configs, extensible renderers)
3. **Proven OpenAir integration** (tested with 3+ networks, multi-year, multi-pollutant)
4. **Stable API** (backward compatible, documented migration paths)

### v1.0 Goals (Standalone R Library)

**Package structure**:
```
quickmap/
├── DESCRIPTION (dependencies, version, authors)
├── NAMESPACE (exported functions)
├── LICENSE (MIT)
├── R/
│   ├── load_data.R (loaders for CSV, RData, OpenAir, sf)
│   ├── layer_system.R (create_layer_config, assemble_layers)
│   ├── rendering.R (add_generic_layer, icon generation)
│   ├── map_creation.R (create_pollution_map, quickmap core)
│   ├── styling.R (themes, color scales, banners)
│   ├── export.R (HTML/JPG output, layout)
│   └── utils.R (helpers, validators)
├── inst/
│   ├── config/scales/ (YAML color scales)
│   ├── themes/ (YAML map themes)
│   ├── controls/ (JS/CSS for roller menu)
│   ├── banner/ (banner CSS template)
│   └── legend/ (legend CSS template)
├── tests/
│   └── testthat/ (comprehensive test suite)
├── vignettes/ (5+ vignettes covering all use cases)
├── man/ (auto-generated documentation)
└── data/ (example datasets for vignettes)
```

**New user-facing functions** (v1.0):
- `quickmap()`: Core function accepting sf + config (thin wrapper around rendering)
- `qm_load_openair()`: Alias for `convertOpenAirToSpatial()` (clearer naming)
- `qm_theme()`: Load/customize themes programmatically
- `qm_scale()`: Load/customize color scales programmatically
- `qm_layer()`: Create custom layer configs for advanced users

**CRAN submission requirements**:
- [ ] Pass `R CMD check` with no errors/warnings
- [ ] Comprehensive documentation (examples for all exported functions)
- [ ] Test coverage >80% (covr package)
- [ ] Vignettes demonstrating key use cases
- [ ] Citation file (CITATION) with journal publication (if applicable)
- [ ] NEWS.md summarizing all versions
- [ ] Code of Conduct, Contributing guidelines

### Integration with Broader R Ecosystem

**Interoperability targets**:
1. **Shiny**: Create `quickmapOutput()` and `renderQuickmap()` for Shiny apps
2. **RMarkdown**: Ensure maps render in knitted documents (HTML, PDF with screenshot)
3. **Plotly**: Optional integration for interactive hover details
4. **gganimate**: Explore ggplot2-based static animation alternative to JPG export
5. **targets/drake**: Support for reproducible analysis pipelines (data targets → map outputs)

**Data source extensions**:
- NetCDF grids (climate/air quality models)
- APIs (OpenAQ, PurpleAir real-time sensors)
- Databases (PostGIS spatial queries)
- Raster overlays (satellite imagery, land use)

---

## Conclusion and Recommendations

### Why Option 3 is Optimal

**Evidence-based**: Validates technical decisions (sf as intermediate, layer system architecture) with production OpenAir data before committing to refactoring.

**Risk-minimized**: Phase 1 delivers value (immediate OpenAir workflows) without touching stable v0.9.1 architecture. Learnings inform Phase 2 refactor.

**Ecosystem-aligned**: Research confirms sf as R spatial standard, OpenAir as air quality standard. quickmap bridges both communities.

**Extensible**: Modular design (Phase 2) enables future network additions (SAQN, European AirBase), non-AQ applications (epidemiology, ecology), and advanced features (3D visualization, animation).

**User-centric**: Four detailed use cases demonstrate value for local authorities, researchers, consultants, and public engagement—covering quickmap's target audiences.

### Next Steps (Immediate Actions)

1. **User approval**: Review this analysis, confirm Option 3 strategy, clarify any ambiguities
2. **Branch creation**: `git checkout -b feature/openair-integration-v092`
3. **Implement Phase 1**: Code `convertOpenAirToSpatial()` function per specification
4. **Test with real data**: AURN London sites (5 years), validate output quality
5. **Document learnings**: Note pain points, surprises, performance issues for Phase 2 design
6. **Iterate**: Present Phase 1 results, get feedback, refine Phase 2 plan if needed

### Success Criteria

**v0.9.2 complete when**:
- [ ] User can run `importAURN() → convertOpenAirToSpatial() → create_pollution_map()` without errors
- [ ] Output HTML map visually indistinguishable from native quickmap CSV/RData maps
- [ ] Vignette demonstrates end-to-end workflow in <50 lines of code
- [ ] No performance regressions vs v0.9.1 (benchmark: 100 sites × 5 years)

**v0.9.5 complete when**:
- [ ] AURN + LAQN + diffusion tubes + schools render in single map with distinct icons
- [ ] Layer system adds new network via config entry (no code modification)
- [ ] 5+ external users successfully map their data with new system
- [ ] Architecture ready for v1.0 extraction (modular functions, stable API)

---

## References and Sources

### R Spatial Ecosystem
- [r-spatial.org Book Chapter 7: Introduction to sf and stars](https://r-spatial.org/book/07-Introsf.html)
- [stars package documentation: Spatiotemporal Arrays, Raster and Vector Data Cubes](https://r-spatial.github.io/stars/)
- [sftime package introduction](https://r-spatial.org/r/2022/04/12/sftime-1.html)
- [CRAN Task View: Analysis of Spatial Data](https://cran.r-project.org/view=Spatial)

### Leaflet and Temporal Visualization
- [leaflet.extras2 documentation](https://cran.r-project.org/web/packages/leaflet.extras2/)
- [Appsilon: Leaflet vs Tmap for Interactive Maps with R](https://www.appsilon.com/post/leaflet-vs-tmap-build-interactive-maps-with-r-shiny)
- [Eye-catching animated maps in R (Towards Data Science)](https://towardsdatascience.com/eye-catching-animated-maps-in-r-a-simple-introduction-3559d8c33be1/)

### OpenAir Package
- [OpenAir project website](https://openair-project.github.io/openair/)
- [OpenAir importMeta documentation](https://openair-project.github.io/openair/reference/importMeta.html)
- [CRAN openair package reference manual](https://cran.r-project.org/web/packages/openair/refman/openair.html)
- [openairmaps: Create Maps of Air Pollution Data](https://openair-project.github.io/openairmaps/)

### Python Geospatial Ecosystem
- [Best Libraries for Geospatial Data Visualisation in Python (Towards Data Science)](https://towardsdatascience.com/best-libraries-for-geospatial-data-visualisation-in-python-d23834173b35/)
- [Learn How to Visualize Geospatial Data with kepler.gl (Analytics Vidhya)](https://www.analyticsvidhya.com/blog/2020/06/learn-visualize-geospatial-data-jupyter-kepler/)
- [leafmap package documentation](https://leafmap.org/get-started/)

### General Mapping and Visualization
- [Geospatial Health Data: Modeling and Visualization with R-INLA and Shiny (Paula Moraga)](https://www.paulamoraga.com/book-geospatial/sec-spatialdataandCRS.html)
- [Nicola Rennie: R packages for visualising spatial data](https://nrennie.rbind.io/blog/r-packages-for-visualising-spatial-data/)

---

**Document Status**: Complete, ready for review and decision
**Recommended Action**: Approve Phase 1 implementation (v0.9.2), commence coding
**Estimated Timeline**: v0.9.2 (2 weeks) → v0.9.3 (2 weeks) → v0.9.4 (2 weeks) → v0.9.5 (2 weeks) = **8 weeks to v0.9.5**
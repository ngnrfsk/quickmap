# OpenAir Converter Essentials

**For:** v0.9.3 converter implementation

## OpenAir Ecosystem

### Packages

-   **openair** v2.18.2: Core air quality data import and analysis
-   **openairmaps** v0.9.1: Spatial mapping functions (leaflet-based)
-   **worldmet** v0.9.8: Meteorological data companion
-   **deweather** v0.7.2: Weather normalization

### Key Functions for v0.9.3

-   **`importUKAQ()`**: **PRIMARY** - Unified UK air quality data import (supersedes importAURN/importKCL)
-   **`importMeta()`**: Site metadata with coordinates
-   **`timeAverage()`**: Temporal aggregation
-   **`selectByDate()`**: Date range filtering
-   **`cutData()`**: Temporal categorization (seasons, etc.)
-   **`searchNetwork()`** (openairmaps): Spatial site search by lat/lng

## Key Functions

**Primary:** - `importUKAQ(site, year, source, meta=TRUE)` - Unified UK data import - `meta=TRUE` embeds `latitude`, `longitude`, `site_type` in data (no separate join needed) - Sources: "aurn", "kcl", "aqe", "saqn", "waqn", "ni"

**Fallback:** - `importMeta(source)` - Returns metadata tibble with `code`, `latitude`, `longitude`, `site_type` - Join key: `code` column - Coordinates: WGS84 (EPSG:4326), no transformation needed - Cache in session (avoid repeated API calls)

**Consider:** - `timeAverage()` - Drops `code` column unless type used to keep site or code, consider dplyr `group_by()` instead

## Data Structures

**importMeta() output:** - Columns: `source`, `site`, `code`, `latitude`, `longitude`, `site_type` - One row per site (not temporal) - WGS84 coordinates (decimal degrees)

**OpenAir data (hourly tibble):** - Columns: `date`, `code`, pollutants (`no2`, `pm2.5`, etc.) - KCL special: uses `v2.5` instead of `pm2.5`

**Quickmap sf output (must match process_oa_data()):** - `siteCode` (not `code`), `year`, `year_str`, `pollutant`, `lat`, `lon`, `Longitude`, `Latitude`, `geometry` - Duplicate coords required: `lat`=`Latitude`, `lon`=`Longitude` - CRS: EPSG:4326

## Existing Quickmap Functions to Reuse

-   `process_oa_data()` (lines 101-110): dplyr aggregation pattern that preserves grouping
-   `st_as_sf()` + `st_coordinates()` pattern for creating sf objects
-   `validate_oa_data()`: validation pattern for required columns

## Metadata Cache

**Implementation (environment-based):**

``` r
.openair_metadata_cache <- new.env(parent = emptyenv())
get_openair_metadata(source)  # Check cache, fetch if missing
clear_openair_metadata_cache(source)  # Manual invalidation
```

**Behavior:** - Session-persistent, not saved across sessions - Error if importMeta() fails (don't cache NULL) - Informative messages on cache hit/miss
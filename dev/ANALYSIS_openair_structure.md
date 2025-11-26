# OpenAir Data Structure Analysis for v0.9.3 Converter

**Date:** 2025-11-26
**Purpose:** Document OpenAir API, data structures, and integration requirements for spatial converter

## OpenAir Ecosystem

### Packages
- **openair** v2.18.2: Core air quality data import and analysis
- **openairmaps** v0.9.1: Spatial mapping functions (leaflet-based)
- **worldmet** v0.9.8: Meteorological data companion
- **deweather** v0.7.2: Weather normalization

### Key Functions for v0.9.3
- **`importUKAQ()`**: **PRIMARY** - Unified UK air quality data import (supersedes importAURN/importKCL)
- **`importMeta()`**: Site metadata with coordinates
- **`timeAverage()`**: Temporal aggregation
- **`selectByDate()`**: Date range filtering
- **`cutData()`**: Temporal categorization (seasons, etc.)
- **`searchNetwork()`** (openairmaps): Spatial site search by lat/lng

## 1. OpenAir Import Functions

### Available Import Functions
```r
importUKAQ()   # UK Air Quality archive (UNIFIED - recommended)
importAURN()   # Automatic Urban and Rural Network (legacy)
importKCL()    # King's College London LAQN (legacy)
importAQE()    # Air Quality England
importSAQN()   # Scottish Air Quality Network
importWAQN()   # Welsh Air Quality Network
importNI()     # Northern Ireland
importEurope() # European monitoring
```

### Network Coverage via importMeta()
- **AURN**: 318 sites
- **AQE**: 411 sites
- **SAQN**: 152 sites
- **WAQN**: 88 sites
- **KCL (LAQN)**: 1068 sites

### Recommended Approach: importUKAQ()
**importUKAQ() is a unified interface that supersedes network-specific functions:**
- Single function supports all UK networks via `source` parameter
- Sources: `"aurn"`, `"kcl"`, `"aqe"`, `"saqn"`, `"waqn"`, `"ni"`, `"local"`
- Optional `meta=TRUE` embeds coordinates directly in data (eliminates separate join)
- Consistent output format across all networks
- Additional parameters: `data_type`, `pollutant`, `ratified`, `meteo`

## 2. Data Structure: importAURN()

### Output Format
- **Class:** `tbl_df`, `tbl`, `data.frame` (tibble)
- **Temporal resolution:** Hourly by default
- **Columns:**
  - `source`: Character ("aurn")
  - `site`: Character (full site name, e.g., "London Marylebone Road")
  - `code`: Character (site code, e.g., "MY1")
  - `date`: POSIXct datetime
  - **Pollutants:** `co`, `nox`, `no2`, `no`, `o3`, `so2`, `pm10`, `pm2.5`
  - **Meteorology:** `ws`, `wd`, `air_temp`

### Key Characteristics
- **No coordinates in data:** Coordinates must be fetched from `importMeta()`
- **Long format:** One row per site-datetime
- **Site identifier:** `code` column joins to metadata
- **Missing data:** `NA` values for missing measurements

### Example
```r
# A tibble: 3 × 15
  source site          code  date                   co   nox   no2
  <chr>  <chr>         <chr> <dttm>              <dbl> <dbl> <dbl>
1 aurn   London M...   MY1   2023-01-01 00:00:00 0.198  41.5  22.6
2 aurn   London M...   MY1   2023-01-01 01:00:00 0.314  50.5  27.5
3 aurn   London M...   MY1   2023-01-01 02:00:00 0.279  40.0  23.5
```

## 2b. Data Structure: importUKAQ() - RECOMMENDED

### Function Signature
```r
importUKAQ(
  site = "my1",
  year = 2022,
  source = "aurn",          # "aurn", "kcl", "aqe", "saqn", "waqn", "ni", "local"
  data_type = "hourly",     # "hourly", "daily", "monthly", "annual"
  pollutant = "all",        # "all" or specific pollutant
  hc = FALSE,               # hydrocarbons
  meta = FALSE,             # **KEY**: embed metadata in data
  meteo = TRUE,             # meteorological variables
  ratified = FALSE,         # ratified data only
  to_narrow = FALSE,        # long format
  verbose = FALSE,
  progress = TRUE
)
```

### Key Advantage: meta = TRUE
**When `meta = TRUE`, coordinates are embedded directly in data:**

```r
# Without meta parameter:
data <- importUKAQ(site = "my1", year = 2023, source = "aurn")
# Columns: source, site, code, date, pollutants...
# Need separate: metadata <- importMeta(source = "aurn")

# With meta=TRUE:
data <- importUKAQ(site = "my1", year = 2023, source = "aurn", meta = TRUE)
# Columns: source, site, code, date, pollutants..., latitude, longitude, site_type
# NO separate metadata fetch needed!
```

### Output Format with meta=TRUE
- **Class:** `tbl_df`, `tbl`, `data.frame` (tibble)
- **Additional columns:**
  - `latitude`: Numeric (decimal degrees, WGS84)
  - `longitude`: Numeric (decimal degrees, WGS84)
  - `site_type`: Character ("Urban Traffic", "Urban Background", etc.)
- **All other columns:** Same as network-specific functions

### Benefits for Converter
1. **Eliminates metadata cache:** No need to cache/fetch `importMeta()` separately
2. **Simplified processing:** Coordinates already in data frame
3. **Consistent across networks:** Same structure whether AURN, KCL, AQE, etc.
4. **Single source of truth:** Coordinates guaranteed to match data rows

### Recommendation for v0.9.3
**Use `importUKAQ(meta = TRUE)` as primary data source:**
- Simplifies converter implementation (no metadata join required)
- Eliminates metadata caching complexity
- Future-proof: works with all UK networks
- Keep `importMeta()` cache as fallback for legacy code or non-UKAQ sources

## 3. Data Structure: importKCL()

### Output Format
- **Class:** `tbl_df`, `tbl`, `data.frame` (tibble)
- **Temporal resolution:** Hourly by default
- **Columns:**
  - `date`: POSIXct datetime
  - **Pollutants:** `nox`, `no2`, `o3`, `so2`, `co`, `pm10_raw`, `pm10`, `v2.5`, `nv10`, `nv2.5`
  - `site`: Factor (full site name)
  - `code`: Character (site code)

### Key Differences from AURN
- **No `source` column:** Must add "kcl" manually if needed
- **Site as factor:** `site` column is factor, not character
- **PM naming:** Uses `v2.5` instead of `pm2.5`, includes `pm10_raw`
- **No coordinates in data:** Must fetch from `importMeta(source = "kcl")`

### Example
```r
# A tibble: 3 × 13
  date                  nox   no2    o3   so2    co pm10_raw  pm10
  <dttm>              <dbl> <dbl> <dbl> <dbl> <dbl>    <dbl> <dbl>
1 2023-01-01 00:00:00  41.3  22.5  49    1.86 0.197       NA    NA
2 2023-01-01 01:00:00  50.4  27.5  46.6  2.13 0.313       NA    NA
```

## 4. Metadata Structure: importMeta()

### Output Format
- **Class:** `tbl_df`, `tbl`, `data.frame` (tibble)
- **Columns:**
  - `source`: Character ("aurn", "kcl", etc.)
  - `site`: Character (full site name)
  - `code`: Character (site code) - **JOIN KEY**
  - `latitude`: Numeric (decimal degrees, WGS84)
  - `longitude`: Numeric (decimal degrees, WGS84)
  - `site_type`: Character ("Urban Background", "Urban Traffic", "Roadside", etc.)

### Key Characteristics
- **Coordinates are WGS84 (EPSG:4326):** No transformation needed
- **One row per site:** Not temporal
- **Join key:** `code` column matches `code` in data
- **Must specify source:** `importMeta(source = "aurn")` or `source = "kcl"`

### Example
```r
# A tibble: 3 × 6
  source site                    code  latitude longitude site_type
  <chr>  <chr>                   <chr>    <dbl>     <dbl> <chr>
1 aurn   Aberdeen                ABD       57.2     -2.09 Urban Background
2 aurn   Aberdeen Erroll Park    ABD9      57.2     -2.09 Urban Background
3 aurn   Aberdeen Union Street   ABD7      57.1     -2.11 Urban Traffic
```

## 5. Temporal Aggregation: timeAverage()

### Function Behavior
- **Input:** OpenAir data.frame with `date` column
- **Output:** Aggregated data.frame with same pollutant columns
- **Aggregation periods:** `"year"`, `"month"`, `"day"`, `"hour"`, `"week"`, etc.

### Key Characteristics
- **Drops non-numeric columns:** `source`, `site`, `code` are removed during aggregation
- **Retains `date` column:** Date represents start of period
- **Averaging:** Means calculated with `na.rm = TRUE`
- **Date format:**
  - Annual: `"2023-01-01 00:00:00"` (first day of year)
  - Monthly: `"2023-02-01 00:00:00"` (first day of month)

### Example Output
```r
# Annual aggregation
# A tibble: 1 × 12
  date                   co   nox   no2    no    o3
  <dttm>              <dbl> <dbl> <dbl> <dbl> <dbl>
1 2023-01-01 00:00:00 0.302  85.4  41.6  28.5  29.1

# Monthly aggregation (12 rows)
# A tibble: 3 × 12
  date                   co   nox   no2    no    o3
  <dttm>              <dbl> <dbl> <dbl> <dbl> <dbl>
1 2023-01-01 00:00:00 0.469 106.   46.1  39.0  23.8
2 2023-02-01 00:00:00 0.419 111.   44.9  42.9  22.7
3 2023-03-01 00:00:00 0.266  70.2  36.5  21.9  35.3
```

## 6. Existing Quickmap Data Structures

### process_oa_data() Output (quickmap.R:75-117)
**Required output format for converter to match:**

```r
# sf object with:
- siteCode: Character (site identifier)
- year: Integer (year as number)
- year_str: Character (year as string)
- pollutant: Numeric (e.g., no2 column with values)
- lat: Numeric (latitude, WGS84)
- lon: Numeric (longitude, WGS84)
- Longitude: Numeric (from st_coordinates, duplicate of lon)
- Latitude: Numeric (from st_coordinates, duplicate of lat)
- geometry: POINT geometry (WGS84, EPSG:4326)
```

### Coordinate Transformation Pattern (quickmap.R:308-336)
**For CSV data with British National Grid coordinates:**

```r
transform_to_wgs84(df, easting = "Easting", northing = "Northing", crs_from = 27700)
# Converts from EPSG:27700 (British National Grid) to EPSG:4326 (WGS84)
# Adds Longitude/Latitude columns from st_coordinates()
```

**OpenAir metadata already in WGS84:** No transformation needed, coordinates are already decimal degrees.

## 7. Converter Requirements

### Input-Output Mapping

**Input (OpenAir):**
```r
importAURN(site = "my1", year = 2023)
# → tibble with date, code, no2, pm2.5, etc. (NO coordinates)

importMeta(source = "aurn")
# → tibble with code, latitude, longitude
```

**Output (quickmap sf):**
```r
# sf object matching process_oa_data() format:
sf with columns: siteCode, year, year_str, no2, lat, lon, Longitude, Latitude, geometry
```

### Required Processing Steps
1. **Aggregate temporally:** `timeAverage(data, avg.time)` → annual/monthly/etc.
2. **Fetch coordinates:** `importMeta(source)` → cache in session
3. **Join data + metadata:** by `code` (data) = `code` (metadata)
4. **Handle missing site identifiers:** `timeAverage()` drops `code`, must preserve before aggregation
5. **Create sf object:** `st_as_sf(coords = c("longitude", "latitude"), crs = 4326)`
6. **Add duplicate coordinate columns:** Extract from geometry for compatibility
7. **Add year columns:** Extract year from `date`, create `year_str`

### Critical Design Decision: Site Code Preservation

**Problem:** `timeAverage()` drops non-numeric columns including `code`

**Solutions:**
1. **Aggregate per site:** Split by `code`, aggregate each, recombine (preferred for multi-site)
2. **Extract year first:** Convert `date` to year, use `group_by(code, year)` with dplyr instead of `timeAverage()`
3. **Restore after aggregation:** Re-join original data to restore `code` (fragile)

**Recommendation:** Use dplyr aggregation pattern from `process_oa_data()` (lines 101-110) which preserves grouping variables.

## 8. Metadata Caching Strategy

### Why Cache?
- **API efficiency:** Avoid repeated `importMeta()` calls for same source
- **Session consistency:** Metadata rarely changes during analysis session
- **Performance:** Local lookup vs network fetch

### Cache Structure Options

**Option 1: Named list (simple)**
```r
metadata_cache <- list()
metadata_cache[["aurn"]] <- importMeta(source = "aurn")
```

**Option 2: Environment (R standard pattern)**
```r
.metadata_cache <- new.env(parent = emptyenv())
.metadata_cache[["aurn"]] <- importMeta(source = "aurn")
```

**Option 3: data.table (fast joins)**
```r
metadata_cache <- data.table::data.table(
  source = character(),
  metadata = list()
)
```

**Recommendation:** Let agent choose between environment (simple) or data.table (performance) based on implementation assessment.

### Cache Behavior
- **Scope:** Package-level environment (session-persistent, not across sessions)
- **Invalidation:** Manual clear function for cache refresh
- **Error handling:** If `importMeta()` fails, return error (don't cache NULL)

## 9. YAML Configuration Requirement

### Data Source Config Pattern
Based on existing layer system, OpenAir sources need YAML configs:

**Example: `inst/config/data_sources/aurn.yaml`**
```yaml
id: aurn_nodes
type: openair
source: aurn
icon_shape: square
pollutant: no2
temporal: true
enabled: true
```

**Example: `inst/config/data_sources/laqn.yaml`**
```yaml
id: laqn_nodes
type: openair
source: kcl
icon_shape: triangle
pollutant: no2
temporal: true
enabled: true
```

**Evaluation:** This duplicates OpenAir functionality (metadata already has source info).
**Recommendation:** Minimal config for styling only, don't store metadata in YAML.

## 10. Compatibility Assessment

### Matches Existing Pattern: process_oa_data()
✅ **Yes** - OpenAir data can be transformed to match `process_oa_data()` output exactly:
- Both use WGS84 coordinates (no transformation needed)
- Both require `siteCode`, `year`, `pollutant`, coordinates
- Both create sf objects with `st_as_sf()`
- Both add duplicate coordinate columns for compatibility

### Integration Point
**New function:** `convert_openair_to_spatial(data, source, pollutant, avg.time)`
- Parallel to `process_oa_data()` (for RData) and `transform_to_wgs84()` (for CSV)
- Returns sf object with identical structure
- Can be used in existing layer system without modifications

### No Breaking Changes Required
- Existing `load_data_file()` handles CSV/RData
- New converter is separate pathway for OpenAir
- Layer system already supports generic data sources
- Test scripts will use converter directly, not integrated into `create_pollution_map()` (future work)

## 11. Implementation Notes

### Pollutant Name Handling
- **AURN:** lowercase column names (`no2`, `pm2.5`)
- **KCL:** lowercase column names (`no2`, `v2.5` for PM2.5)
- **Quickmap convention:** lowercase pollutant names in sf objects
- **Action:** Check pollutant column exists, handle `v2.5` → `pm2.5` rename for KCL

### Year Extraction
```r
# From date column:
year <- as.integer(format(date, "%Y"))
year_str <- format(date, "%Y")

# For sub-annual:
year_str <- format(date, "%Y-%m")     # monthly
year_str <- format(date, "%Y-%m-%d")  # daily
```

### Missing Data
- OpenAir uses `NA` for missing values
- Quickmap filters sites with >20% missing data (MISSING_DATA_THRESHOLD)
- OpenAir's `timeAverage()` automatically uses `na.rm = TRUE`
- **Decision:** Let OpenAir handle missing data during aggregation, no additional filtering needed

## 12. Recommended Converter Architecture

### Function Signature
```r
convert_openair_to_spatial <- function(
  data,                    # OpenAir data.frame from importAURN/importKCL
  source,                  # "aurn", "kcl", etc.
  pollutant,               # "no2", "pm2.5", etc.
  avg.time = "year"        # temporal aggregation period
)
```

### Processing Pipeline
1. **Validate inputs:** Check data has required columns, pollutant exists
2. **Preserve site codes:** Extract `code` before aggregation
3. **Aggregate temporally:** Group by code, use dplyr pattern (not raw `timeAverage()`)
4. **Fetch metadata:** Call cached `importMeta(source)`
5. **Join data + coordinates:** by `code`
6. **Filter missing coordinates:** Warn about sites without coordinates
7. **Create sf object:** `st_as_sf(coords = c("longitude", "latitude"), crs = 4326)`
8. **Add compatibility columns:** Extract coordinates, create year_str
9. **Validate output:** Check matches `process_oa_data()` structure
10. **Return sf object**

### Helper Functions
```r
get_openair_metadata(source)      # Cached metadata fetch
clear_metadata_cache()            # Manual cache invalidation
validate_openair_data(data, ...)  # Input validation
```

## 13. Testing Strategy

### Unit Tests (Step 2)
- Mock OpenAir data (3 sites, 2 years)
- Verify output structure matches `process_oa_data()`
- Check coordinate columns, geometry, year_str

### Integration Tests (Steps 5-6)
- Real AURN data download and conversion
- Real LAQN data download and conversion
- Multi-network overlay (AURN + LAQN + dt_sites + schools)

### Performance Tests (Step 7)
- 50 sites × 5 years = 250 features
- Conversion time < 5 seconds
- No rendering regression

## 14. OpenAir Utility Functions

### selectByDate() - Date Range Filtering
```r
selectByDate(mydata, start = "1/1/2023", end = "31/3/2023")
# Filters data to date range
# Useful for: Creating seasonal subsets, testing with smaller datasets
```

**Use case for converter:** Pre-filter data before aggregation for performance

### cutData() - Temporal Categorization
```r
cutData(data, type = "season")  # Adds 'season' column
cutData(data, type = "month")   # Adds 'month' column
cutData(data, type = "daylight") # Day/night categorization
```

**Use case for converter:** Not needed for basic annual/monthly aggregation, but useful for future seasonal analysis features

## 15. openairmaps Package Integration

### searchNetwork() - Spatial Site Discovery
```r
searchNetwork(
  lat = 51.5,
  lng = -0.1,
  source = "aurn",
  n = 5,              # number of nearest sites
  max_dist = NULL,    # max distance in km
  map = FALSE         # return data.frame only
)
# Returns: tibble with site, code, latitude, longitude, dist (distance in km)
```

**Use case for converter:**
- Future feature: "Find sites within X km of location"
- Borough-based auto-site selection
- Not needed for v0.9.3 core converter

### networkMap() - Interactive Network Visualization
```r
networkMap(source = "aurn", control = "nox", year = 2023)
# Creates leaflet map of entire network
```

**Note:** openairmaps uses leaflet (same as quickmap). Potential for integration but:
- openairmaps focuses on network-wide visualization with polar plots
- quickmap focuses on multi-network overlay with custom icons/legends
- Different use cases, both valid

**Recommendation:** Keep separate for now, no integration needed in v0.9.3

## 16. Revised Architecture Based on importUKAQ()

### Simplified Converter Design

**Original plan (with metadata cache):**
```r
1. Aggregate data with timeAverage()
2. Fetch cached metadata via importMeta()
3. Join data + metadata by code
4. Create sf object
```

**Revised plan (with importUKAQ meta=TRUE):**
```r
1. Data already has coordinates (importUKAQ meta=TRUE)
2. Aggregate with dplyr (preserves lat/lon columns)
3. Create sf object directly
```

### Impact on Implementation Steps

**Step 1 (Metadata Cache):**
- **OPTIONAL now** - only needed for:
  - Legacy importAURN/importKCL code
  - Non-UK networks (importEurope, etc.)
  - Edge case: if user provides pre-fetched data without coordinates

**Recommendation:** Implement minimal cache as fallback, but design converter to use `importUKAQ(meta=TRUE)` as primary pathway

**Step 2 (Core Converter):**
- **Simplified** - Check if coordinates already in data
- If yes: aggregate directly
- If no: fetch from cache/importMeta()

### Updated Function Signature
```r
convert_openair_to_spatial <- function(
  data,                    # OpenAir data.frame (preferably from importUKAQ meta=TRUE)
  source = NULL,           # Required only if data lacks coordinates ("aurn", "kcl", etc.)
  pollutant,               # "no2", "pm2.5", etc.
  avg.time = "year"        # temporal aggregation period
)
# If data has latitude/longitude: use them
# If not: fetch from importMeta(source) cache
```

## 17. Updated Conclusion

**OpenAir → Quickmap conversion is feasible and significantly simplified by importUKAQ():**

### Key Findings from Extended Research
1. **importUKAQ() supersedes importAURN/importKCL:** Unified interface for all UK networks
2. **meta=TRUE parameter eliminates metadata cache need:** Coordinates embedded directly in data
3. **5 UK networks accessible:** AURN (318 sites), KCL/LAQN (1068 sites), AQE (411), SAQN (152), WAQN (88)
4. **openairmaps provides spatial utilities:** searchNetwork() for site discovery, but not needed for core converter
5. **Coordinates already WGS84:** No transformation needed
6. **Utility functions available:** selectByDate(), cutData() for advanced filtering (optional)

### Architectural Simplification
- **Original design:** Metadata cache + join required
- **New design:** `importUKAQ(meta=TRUE)` provides coordinates directly
- **Metadata cache:** Now optional fallback for edge cases

### Updated Recommendations for Implementation
1. **Step 1:** Implement minimal metadata cache as fallback (simplified from original plan)
2. **Step 2:** Design converter to accept data with or without coordinates
   - Primary path: data with coordinates (from `importUKAQ meta=TRUE`)
   - Fallback path: fetch from cache if coordinates missing
3. **Test scripts:** Use `importUKAQ(meta=TRUE)` in Steps 5-6 to demonstrate simplified workflow

**No reinvention of OpenAir functionality:** Converter uses OpenAir's own functions and transforms output to quickmap's sf format.

**Ready to proceed to Step 1: Metadata Cache System (simplified version)**

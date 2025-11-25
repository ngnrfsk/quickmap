# Quickmap v0.9.1 → v0.9.5 Roadmap

**Date:** 2025-11-23
**Status:** Planning Phase
**Goal:** Modularize quickmap architecture while maintaining full operational stability and introducing OpenAir integration capability

---

## Current State Assessment

Quickmap v0.9.1 has a well-structured monolithic architecture: `create_pollution_map()` orchestrates data loading (CSV/RData), spatial processing (BNG→WGS84), unified layer generation, and dual-output rendering (HTML+JPG). The 111-line main function delegates to helpers but remains the sole entry point. OpenAir compatibility exists only at data format level—sensor RData files follow OpenAir's date+pollutant convention—but no functional integration exists for preprocessing or network access.

---

## Options for v0.9.5 Architecture

### Option A: Backend-First Modularization

Extracts five discrete modules (`load_pollution_data()`, `process_spatial_data()`, `create_pollution_layers()`, `apply_map_styling()`, `export_pollution_map()`), introduces thin `quickmap()` core accepting pre-processed spatial tibbles, makes `create_pollution_map()` a wrapper over quickmap. This enables OpenAir workflows where users call `importAURN() → timeAverage() → process_spatial_data() → quickmap()`.

**Risk:** Extensive refactoring could introduce regressions
**Mitigation:** Requires comprehensive test coverage before extraction begins

### Option B: Incremental Adapter Pattern

Keeps `create_pollution_map()` intact, adds new `openair_to_quickmap()` adapter accepting OpenAir data frames, creates `quickmap_simple()` as future core (initially just calls existing code).

**Advantages:** Zero risk to current workflows, adapters prove OpenAir integration value early, modularization happens gradually in v0.9.6+
**Limitation:** Defers full separation but validates approach with real AURN data quickly

### Option C: Parallel Development Track

Builds new `R/openair_integration.R` with `quickmapFromOpenAir()` wrapper calling existing internals, extracts data loading as first module, adds `convertOpenAirToSpatial()` helper. This creates working OpenAir examples immediately while planning full modularization. Current code stays untouched in v0.9.5; extraction roadmap targets v0.9.6-v0.9.8.

**Trade-off:** Balances innovation with stability but creates temporary code duplication

---

## Recommended Approach: Option B with Early AURN Test

### Strategy

Adopt **Option B with early AURN test** for v0.9.5. This approach prioritizes maintaining quickmap functionality while proving OpenAir integration value.

### Implementation Plan

1. **Freeze stable interface:** `create_pollution_map()` remains untouched as primary user interface
2. **Extract data loading only:** `load_spatial_data_sources()` becomes independent module with OpenAir-compatible signature
3. **Create adapter:** `prepare_openair_data()` converts AURN imports to quickmap's expected spatial format
4. **Deliver working example:** AURN demonstration combining `importAURN() → selectByDate() → prepare_openair_data() → create_pollution_map()`
5. **Document future plan:** Full modularization roadmap for v0.9.6+

### Rationale

This validates technical feasibility with minimal risk, proves value to users immediately, and establishes pattern for subsequent extractions.

---

## Version 0.9.5 Deliverables

### 1. Extract Data Loading Module

**File:** `R/data_loading.R`

Create module with dual interface:
- **Existing interface:** Accept file paths (CSV, RData) as currently used
- **New interface:** Accept OpenAir tibbles/data frames directly

**Functions to extract:**
- `load_spatial_data_sources()` - main orchestrator
- `load_data_file()` - file path handling
- `load_rdata_file()` - RData loading
- `import_csv_data()` - CSV import
- `process_oa_data()` - OpenAir format processing

### 2. Create OpenAir Adapter

**File:** `R/openair_adapter.R`

**Primary function:** `prepare_openair_data(mydata, coords_source)`

**Signature:**
```r
prepare_openair_data <- function(
  mydata,              # OpenAir-format data frame with 'date' column
  coords.source,       # Site coordinates data frame or "builtin"
  coords = c("lon", "lat"),
  pollutant = "no2",
  site.col = "site"
)
```

**Behavior:**
- Accepts OpenAir format (date + pollutant columns)
- Joins with site coordinate data
- Returns sf object compatible with quickmap pipeline
- Handles coordinate transformation if needed

### 3. Working AURN Example

**File:** `examples/aurn_wandsworth_example.R`

Demonstrate complete workflow:
```r
library(openair)
library(quickmap)

# 1. Import AURN data for London sites
aurn_data <- importAURN(site = c("WAH1", "WAH2"),
                        year = 2020:2023,
                        pollutant = "no2")

# 2. Filter to summer months
filtered <- selectByDate(aurn_data, month = 6:9)

# 3. Calculate daily means
daily <- timeAverage(filtered, avg.time = "day")

# 4. Convert to spatial format (using built-in AURN coordinates)
spatial_data <- prepare_openair_data(daily, coords.source = "builtin")

# 5. Create map using existing quickmap interface
create_pollution_map(
  sensor_file = spatial_data,  # Pass spatial data directly
  boroughs = "Wandsworth",
  pollutant = "no2",
  styling_type = "html"
)
```

### 4. Test Coverage

**File:** `tests/testthat/test-openair-integration.R`

Verify:
- Existing workflows unchanged (all current tests pass)
- New adapter handles OpenAir format correctly
- AURN example executes without errors
- Data format conversions preserve values

### 5. Future Modularization Plan

**File:** `dev/v0.9.6_modularization_plan.md`

Document extraction roadmap for v0.9.6-v0.9.8:

**Phase 1 (v0.9.6):** Extract processing pipeline
- `process_spatial_data()` - spatial transformations, filtering
- `get_measurement_layers()` - layer configuration
- Function signatures using OpenAir conventions (lowercase.with.dots)

**Phase 2 (v0.9.7):** Extract layer creation
- `create_pollution_layers()` - generic layer generation
- `create_generic_icons()` - icon system
- `add_layer()` - layer addition to maps

**Phase 3 (v0.9.8):** Extract styling and export
- `apply_map_styling()` - banner, legend, vignette
- `export_pollution_map()` - HTML/JPG output
- Complete wrapper transformation

**Phase 4 (v0.9.9):** Introduce core `quickmap()`
- `quickmap()` as thin orchestrator of modules
- `create_pollution_map()` becomes wrapper over `quickmap()`
- Full compatibility with OpenAir workflows

---

## Success Criteria for v0.9.5

1. ✅ All existing quickmap workflows continue to work unchanged
2. ✅ AURN data can be imported, processed, and mapped successfully
3. ✅ Example script demonstrates complete OpenAir → quickmap pipeline
4. ✅ Test suite confirms no regressions
5. ✅ Clear documentation for next modularization phases
6. ✅ Code remains in single `R/quickmap.R` file OR begins migration to `R/` directory structure

---

## Technical Considerations

### Naming Conventions

Following OpenAir patterns for new functions:
- **Exported functions:** `lowerCamelCase` (e.g., `prepareOpenAirData`)
- **Parameters:** `lowercase.with.dots` for multi-word (e.g., `coords.source`, `site.col`)
- **Internal helpers:** `lowercase.with.dots` (e.g., `quickmap.validate.coords`)

### Data Structure Compatibility

**OpenAir format (input):**
```r
data.frame(
  date = POSIXct,      # REQUIRED
  site = character,    # Site identifier
  no2 = numeric,       # Pollutant values
  ws = numeric,        # Wind speed (optional)
  wd = numeric         # Wind direction (optional)
)
```

**Quickmap spatial format (output):**
```r
sf object with:
  geometry = POINT,    # WGS84 coordinates
  siteCode = character,
  year = numeric,
  pollutant = numeric,
  Latitude = numeric,
  Longitude = numeric
```

### Backward Compatibility

- All current function signatures remain unchanged
- Existing test suite must pass 100%
- CSV/RData file loading continues to work identically
- Theme system, colour scales, configuration remain operational

---

## Risk Assessment

### Low Risk Items
- Creating new adapter functions (no impact on existing code)
- Adding example scripts
- Writing documentation

### Medium Risk Items
- Extracting `load_spatial_data_sources()` to separate file
- Modifying data loading logic to accept sf objects directly

### Mitigation Strategies
- Comprehensive test suite before any extraction
- Extract functions by copy initially, verify behavior, then integrate
- Keep v0.9.1 tagged and available for rollback
- Test with real AURN data early and often

---

## Timeline Estimate

**v0.9.5 Development:**
- Module extraction: 1 unit
- Adapter creation: 1 unit
- Example script: 0.5 units
- Testing: 1 unit
- Documentation: 0.5 units

**Total:** 4 units of work (no time estimates per user preference)

**Dependencies:**
- Access to AURN network data for testing
- OpenAir package functionality verification
- Site coordinate data for AURN locations

---

## Post-v0.9.5 Vision

By v1.0, quickmap becomes:
- **Modular architecture:** Clean separation of concerns
- **OpenAir native:** Seamless integration with OpenAir workflows
- **CRAN ready:** Full documentation, tests, examples
- **Flexible:** Users can combine modules for custom workflows

**Example v1.0 workflow:**
```r
# Advanced user workflow
library(openair)
library(quickmap)

# OpenAir preprocessing
data <- importAURN(site = "MY1", year = 2023) %>%
  selectByDate(month = 6:9) %>%
  timeAverage(avg.time = "day")

# Quickmap modular approach
spatial <- processSpatialData(data, boroughs = "Merton")
map <- createBaseMap(spatial$boundary)
map <- addPollutionLayers(map, spatial$layers, cols = "jet")
map <- applyMapStyling(map, styling.type = "html")
exportPollutionMap(map, "output.html", image.dims = c(1920, 1080))
```

---

## References

- `dev/OA_vs_QM_style_guide.md` - Parameter design patterns
- `dev/OpenAir_Integration_Style_Guide.md` - Functional integration guidelines
- `CLAUDE.md` - Current project architecture documentation
- OpenAir package: https://openair-project.github.io/openair/

---

**Document Version:** 1.0
**Last Updated:** 2025-11-23
**Next Review:** Upon completion of v0.9.5 implementation

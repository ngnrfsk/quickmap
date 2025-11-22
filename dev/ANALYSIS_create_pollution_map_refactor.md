# Analysis: create_pollution_map() Refactoring Opportunities

**Current State:** 185 lines (1706-1890), single monolithic function
**Goal:** Simplify, clarify, shorten, make tidyverse-compliant, extract reusable functions

---

## Structure Analysis

### Current Flow (7 sections)

1. **Parameter Processing** (13 lines, 1726-1738)
   - Parse export_image parameter
   - **Issue:** 3 branches doing similar things, verbose

2. **Theme & Defaults** (13 lines, 1740-1752)
   - Load theme, apply defaults with `%||%`
   - **Status:** ✓ Good, concise

3. **Setup** (3 lines, 1754-1762)
   - Load boundaries, create output dir
   - **Status:** ✓ Good

4. **Data Loading** (67 lines, 1764-1830)
   - Load 3 file types (DT, schools, sensors)
   - Spatial filtering
   - Data fallback logic
   - Years determination
   - **Issues:**
     - Repetitive pattern (3x similar blocks)
     - Confusing fallback logic (lines 1803, 1817 duplicate)
     - Years logic mixed with data loading

5. **Map Initialization** (14 lines, 1832-1849)
   - Create base maps
   - Get layers and data_max
   - **Status:** ✓ Good

6. **Year Loop** (21 lines, 1851-1871)
   - Generate layers for each year
   - Export static images
   - **Status:** ✓ Good after our helpers

7. **Finalization** (19 lines, 1873-1890)
   - Save/finalize HTML map
   - **Status:** ✓ Good

---

## Problems Identified

### 1. Data Loading Repetition (DRY Violation)

**Lines 1764-1789:** Three nearly identical blocks

```r
# Pattern repeated 3x:
if (XXX_file != "none") {
  result <- load_data_file(XXX_file, "csv", ...)
  if (!is.null(result)) {
    sf_XXX_wgs84 <- result$data |> transform_to_wgs84()
  } else {
    XXX_file <- "none"
  }
}
```

**Opportunity:** Extract to `load_spatial_data_sources()`

### 2. Confusing Data Fallback Logic

**Lines 1803-1830:** Hard to follow, duplicated conditions

```r
1803: if (diffusion_tube_file == "none" && !is.null(bl_annual_means_sf)) {
1804:   sf_data_wgs84 <- bl_annual_means_sf
1805: }
...
1817: if (diffusion_tube_file == "none") sf_data_wgs84 <- bl_annual_means_sf  # DUPLICATE!
```

**Issues:**
- Duplicate condition (1803 vs 1817)
- `sf_data_wgs84` assigned in 3 places (1771, 1804, 1817, 1823)
- Years logic intertwined

**Opportunity:** Extract to `determine_primary_data_and_years()`

### 3. Export Image Parameter Parsing

**Lines 1726-1738:** Verbose for simple logic

```r
if (is.null(export_image)) {
  image_export <- FALSE
  map_width_px <- IMAGE_X
  map_height_px <- IMAGE_Y
} else if (export_image == TRUE) {
  image_export <- TRUE
  map_width_px <- IMAGE_X
  map_height_px <- IMAGE_Y
} else {
  image_export <- TRUE
  map_width_px <- export_image[1]
  map_height_px <- export_image[2]
}
```

**Opportunity:** Simplify to 4-5 lines with consistent defaults

### 4. Not Tidyverse-Compliant

**Missing opportunities:**
- No use of `purrr::map()` for repetitive data loading
- Could use `list()` to organize related data
- No use of tidyselect or tidyr patterns

---

## Proposed Refactoring

### Option A: Conservative (Extract Helpers)

**Extract 3 helper functions:**

1. **`parse_export_params(export_image)`** (5 lines)
   - Returns: `list(enabled, width, height)`
   - Simplifies lines 1726-1738

2. **`load_spatial_data_sources(dt_file, sensor_file, school_file, pollutant)`** (30 lines)
   - Returns: `list(dt_data, sensor_data, school_data, files_loaded)`
   - Replaces lines 1764-1801
   - Uses purrr pattern for tidyverse compliance

3. **`determine_primary_data_and_years(dt_data, sensor_data, school_data, ...)`** (25 lines)
   - Returns: `list(primary_data, years, vignette_overlay, bbox)`
   - Replaces lines 1803-1830
   - Clarifies fallback logic

**Result:**
- Main function: 185 → ~110 lines (40% reduction)
- 3 new focused, testable functions
- Each helper can work independently

### Option B: Aggressive (Full Restructure)

**Extract 5+ functions and use builder pattern:**

1. `parse_export_params()` - as above
2. `load_spatial_data_sources()` - as above
3. `prepare_map_context()` - boundaries, theme, output dir
4. `determine_rendering_strategy()` - years, primary data, layers
5. `render_maps()` - the loop logic

**Result:**
- Main function: 185 → ~60 lines (67% reduction)
- 5 new functions
- Full tidyverse compliance with purrr
- More testable, but more abstraction

---

## Recommendations

### Immediate (This Session)

**Go with Option A - Conservative extraction:**

1. ✅ Extract `parse_export_params()` - simple win
2. ✅ Extract `load_spatial_data_sources()` - biggest complexity reduction
3. ✅ Extract `determine_primary_data_and_years()` - clarifies confusing logic

**Benefits:**
- ~75 line reduction in main function
- Much clearer flow in `create_pollution_map()`
- Each helper testable independently
- Tidyverse-compliant data loading with purrr

**Estimated time:** 1-2 hours
**Risk:** Low (pure extraction, no logic changes)

### Future (v0.9.2)

**Consider Option B when:**
- Building comprehensive test suite
- Adding new map types
- Need to expose rendering pipeline as API

---

## Code Simplification Details

### Before (Data Loading - 67 lines)

```r
if (diffusion_tube_file != "none") {
  csv_result <- load_data_file(diffusion_tube_file, "csv", c("Easting", "Northing"))
  if (!is.null(csv_result)) {
    sf_data_wgs84 <- get_temporal_data(csv_result$data) |> transform_to_wgs84()
  } else {
    diffusion_tube_file <- "none"
  }
}
# ... repeat 2 more times
# ... confusing fallback logic (20 lines)
# ... years determination (10 lines)
```

### After (2 function calls)

```r
# Load all data sources (tidyverse pattern)
spatial_data <- load_spatial_data_sources(
  diffusion_tube_file, sensor_file, school_file, pollutant
)

# Determine primary data source and years
map_data <- determine_primary_data_and_years(
  spatial_data, boroughs, vignette, borough_sf, years
)
```

**Result:** 67 lines → 8 lines in main function

---

## Implementation Priority

1. **HIGH**: Extract data loading (biggest win, clarifies most complexity)
2. **MEDIUM**: Extract parameter parsing (small but helps readability)
3. **MEDIUM**: Extract years determination (clarifies confusing logic)
4. **LOW**: Full restructure (wait for v0.9.2)

---

## Testing Strategy

For each extracted function:
1. Unit test with mock data
2. Integration test with real data files
3. Edge cases (missing files, empty data, schools-only)

---

## Next Steps

1. Review this analysis with user
2. Get approval for Option A
3. Implement in small incremental steps:
   - Step 1: Extract `parse_export_params()`
   - Step 2: Extract `load_spatial_data_sources()`
   - Step 3: Extract `determine_primary_data_and_years()`
   - Step 4: Update tests
4. Test thoroughly after each step
5. Commit with clear messages

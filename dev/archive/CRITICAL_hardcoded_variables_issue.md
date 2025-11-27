# CRITICAL: Hardcoded Variable Names Break Config System

**Date:** 2025-11-25
**Context:** User identified fundamental architectural flaw in v0.9.2 refactoring

## The Problem

Steps 1-6 created YAML-driven config system, but **core variable handling is still hardcoded for 3 data sources only**.

## Evidence

### 1. Hardcoded Variable Creation (create_pollution_map, lines 1967-1969)
```r
c(sf_data_wgs84, bl_annual_means_sf, years, vignette_overlay, bbox) %<-%
  determine_primary_data_and_years(spatial_data, borough_sf, vignette, years)
sf_schools_wgs84 <- spatial_data$school
```

**Problem:**
- Creates exactly 3 variables with hardcoded names
- 4th network (AURN) data never gets assigned to a variable
- YAML says `data_source_var: mock_aurn_sf` but that variable is never created here
- Only works because test script creates variable BEFORE calling create_pollution_map()

### 2. Hardcoded Data Source Priority (determine_primary_data_and_years, lines 1799-1802)
```r
dt_data <- spatial_data$dt        # Hardcoded
sensor_data <- spatial_data$sensor  # Hardcoded
primary_data <- dt_data %||% sensor_data  # Hardcoded priority: DT > BL
```

**Problem:**
- Only looks at `spatial_data$dt` and `spatial_data$sensor`
- Ignores 4th network data completely
- "Primary data" concept assumes exactly DT + BL structure

### 3. Hardcoded Variable Name Lookups (get_layer_year_data, line 1524)
```r
data_source <- get(data_source_name, envir = data_environment)
```

**Problem:**
- `get("bl_annual_means_sf", envir=...)` looks up variable by name
- Variable must exist in create_pollution_map() scope
- 4th network: `get("mock_aurn_sf")` fails because variable was never created

## Why Test Passes Despite Broken Logic

**test_4network_mock.R works because:**
```r
# Test script creates variable BEFORE calling function
mock_aurn_sf <- ...  # Created in test script scope

# Then passes it as data_source
create_pollution_map(
  data_sources = list(..., mock_aurn_sf),  # Passes sf object directly
  ...
)
```

**But internally:**
1. Step 1's `load_spatial_data_sources()` stores in `spatial_data$all_data[["aurn"]]` ✓
2. Lines 1967-1969 create variables for DT/BL/Schools only ✗
3. AURN data exists in `spatial_data$all_data` but NO variable created
4. `get_layer_year_data()` tries `get("mock_aurn_sf")` and **finds it in test script scope** ✓
5. Works by accident - if test didn't create variable first, would fail

## User's Observations Are Correct

### Issue 1: `pollutant_col` redundant
> "isn't pollution data decided by flag 'temporal'?"

**YES!** Current logic:
```r
# Line 1692: Filter only if pollutant_col exists
if (!is.null(layer_config$pollutant_col)) {
  year_data <- filter(year_data, !is.na(.data[[pollutant]]))
}
```

**Could be:**
```r
# Temporal layers have pollution data, static don't
if (layer_config$temporal) {
  year_data <- filter(year_data, !is.na(.data[[pollutant]]))
}
```

**Redundancy:**
- Schools: `temporal=FALSE`, `pollutant_col=NULL` → same information twice
- DT/BL: `temporal=TRUE`, `pollutant_col="no2"` → `pollutant_col` unused anyway
- Field exists but provides no value - can be eliminated

### Issue 2: Hardcoded variable names
> "these data layer sfs should be tracked automatically by the code"

**YES!** Current broken flow:
1. `load_spatial_data_sources()` → `spatial_data$all_data[[config_name]]` ✓ (Step 1 - good!)
2. `create_pollution_map()` → Creates 3 hardcoded variables ✗ (Pre-Step 1 - bad!)
3. `get_layer_year_data()` → Uses `get(variable_name)` ✗ (Pre-Step 1 - bad!)

**Should be:**
1. `load_spatial_data_sources()` → `spatial_data$all_data[[config_name]]` ✓
2. `get_layer_year_data()` → Uses `spatial_data$all_data[[config_name]]` directly ✓
3. No hardcoded variables needed ✓

## Root Cause

**Steps 1-6 added NEW code (data_sources API, YAML configs) but didn't refactor OLD code paths:**
- `determine_primary_data_and_years()` - Pre-Step 1 code, assumes 3 sources
- Variable creation in `create_pollution_map()` - Pre-Step 1 code, hardcoded names
- `get_layer_year_data()` using `get()` - Pre-Step 1 code, expects variables in scope

**The config system is a facade** - underneath, old hardcoded logic remains.

## Impact on v0.9.2

### What Works
✅ Old API (diffusion_tube_file, sensor_file, school_file)
✅ New API with 3 original networks
✅ 4th network test (by accident - test creates variable first)

### What's Broken
❌ 4th network if user doesn't manually create variables
❌ Config system doesn't actually drive data handling
❌ Can't add 5th network without code changes
❌ YAML `data_source_var` field is a lie - variables not auto-created

## Fix Required

Must refactor 3 functions to use `spatial_data$all_data` directly:

### 1. Eliminate hardcoded variable creation
**Before (lines 1967-1969):**
```r
c(sf_data_wgs84, bl_annual_means_sf, years, vignette_overlay, bbox) %<-%
  determine_primary_data_and_years(spatial_data, borough_sf, vignette, years)
sf_schools_wgs84 <- spatial_data$school
```

**After:**
```r
c(years, vignette_overlay, bbox) %<-%
  determine_years_and_viewport(spatial_data, borough_sf, vignette, years)
# Data accessed via spatial_data$all_data throughout, no variables
```

### 2. Refactor determine_primary_data_and_years()
**Before (lines 1799-1802):**
```r
dt_data <- spatial_data$dt
sensor_data <- spatial_data$sensor
primary_data <- dt_data %||% sensor_data
```

**After:**
```r
# Find first temporal layer to determine years
temporal_layers <- Filter(function(x) !is.null(x) && "year_str" %in% names(x),
                          spatial_data$all_data)
primary_data <- if (length(temporal_layers) > 0) temporal_layers[[1]] else NULL
```

### 3. Refactor get_layer_year_data()
**Before (line 1524):**
```r
data_source <- get(data_source_name, envir = data_environment)
```

**After:**
```r
# Pass spatial_data directly, use config name to lookup
data_source <- spatial_data$all_data[[layer_config$id]]
```

### 4. Eliminate pollutant_col from configs
**Before:**
```yaml
pollutant_col: no2  # Unused
temporal: true
```

**After:**
```yaml
temporal: true  # Sufficient - temporal layers have pollution data
```

## Recommendation

**Option A: Fix in Step 7 (Cleanup)**
- Add to Step 7 scope: refactor 3 functions above
- Remove `pollutant_col` from YAMLs
- Test 4th network works WITHOUT manual variable creation

**Option B: Document and Defer**
- Note limitation in docs: "4th network requires manual variable creation"
- Flag for v0.9.3 as breaking change
- Current system functional but not truly config-driven

**User's intuition is correct** - current design has muddled logic and unnecessary complexity.

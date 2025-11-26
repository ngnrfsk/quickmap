# Analysis: YAML Config System Issues

**Date:** 2025-11-25 **Context:** Step 6 testing revealed two design issues in the YAML config system

## Issue 1: Single Pollutant Limitation

### Current State

YAML configs only allow reference to ONE pollutant via `pollutant_col` field:

``` yaml
# bl_nodes.yaml
pollutant_col: no2  # Can only specify ONE pollutant
```

### Problem

-   BL sensors measure BOTH NO2 and PM2.5
-   AURN network measures multiple pollutants
-   Current design forces one config per pollutant OR ignores some data

### How It's Used

1.  **Missing data filtering** (line 1692-1695):
    -   `if (!is.null(layer_config$pollutant_col))` checks if layer has pollution data
    -   Filters rows where `pollutant` column has NA values
    -   **Note:** Uses the function parameter `pollutant` (from `create_pollution_map()`), NOT `pollutant_col` from config
2.  **Legend calculation** (line 218-219 in `get_data_maximum()`):
    -   Uses hardcoded function `get_pollutant_col(layer_type)` that ignores YAML
    -   Falls back to function parameter `pollutant`

### Current Workaround

-   `pollutant_col` in YAML is actually **ignored** at render time
-   Real pollutant comes from `create_pollution_map(pollutant = "no2")` parameter
-   Config's `pollutant_col` only acts as a flag: "does this layer have pollution data?"

### Implications

✅ **Good News:** Multi-pollutant networks work NOW because `pollutant` param drives rendering

❌ **Bad News:** - YAML field `pollutant_col` is misleading (suggests it controls which column to use) - Can't validate if data source supports requested pollutant - Can't document which pollutants a network provides

### Recommendation

**Option A (Quick Fix):** Rename field to clarify intent

``` yaml
has_pollution_data: true  # Boolean flag, not column name
```

**Option B (Full Fix):** Support multiple pollutants

``` yaml
supported_pollutants: [no2, pm25]  # List of available pollutants
```

Then validate: `if pollutant not in config$supported_pollutants: warn("BL sensors don't measure O3")`

------------------------------------------------------------------------

## Issue 2: data_source_var - Variable Name String

### Current State

YAML configs store R variable names as strings:

``` yaml
# bl_nodes.yaml
data_source_var: bl_annual_means_sf  # String containing variable name
```

### How It Works

1.  **In `get_measurement_layers()`** (line 1374):

    -   Reads `yaml_config$data_source_var` → `"bl_annual_means_sf"`
    -   Stores in `layer_config$data_source`

2.  **In `get_layer_year_data()`** (line 1524):

    -   Receives `data_source_name` = `"bl_annual_means_sf"` (string)
    -   Uses `get(data_source_name, envir = data_environment)` to fetch actual data
    -   `data_environment` = environment of `create_pollution_map()` function

3.  **Variable must exist in scope:**

    ``` r
    # Inside create_pollution_map():
    sf_data_wgs84 <- ...           # DT data
    bl_annual_means_sf <- ...      # BL data
    sf_schools_wgs84 <- ...        # Schools data

    # These variable names MUST match YAML data_source_var values
    ```

### Why This Design?

-   **Backward compatibility:** Existing code uses `get()` to look up variables by name
-   **Environment passing:** Data loaded in `create_pollution_map()`, accessed in `generate_map_layers()`
-   **Avoids data copying:** Passes variable names, not data frames (memory efficient)

### Problem

**Tight coupling between YAML and code:** - YAML says `data_source_var: bl_annual_means_sf` - Code MUST create variable named exactly `bl_annual_means_sf` - If variable name changes in code → YAML breaks - If YAML typo → runtime error from `get()`

### Current Impact on Step 6

``` r
# test_4network_mock.R creates:
mock_aurn_sf <- ...  # Variable name

# aurn.yaml must say:
data_source_var: mock_aurn_sf  # Exact match required
```

**This works because:** 1. Step 1 added `load_spatial_data_sources()` which stores data in `spatial_data$all_data` keyed by config name 2. BUT the mapping back to variable names still happens via hardcoded lookup in old code paths

### Implications

✅ **Works for now:** New API passes data objects directly, variable names used internally

❌ **Fragile:** - Adding 4th network requires knowing internal variable naming convention - Mock test creates variable, writes YAML referencing it - tight coupling - Can't rename variables without updating YAMLs

### Recommendation

**Option A (Quick Doc):** Document the convention clearly

``` yaml
data_source_var: mock_aurn_sf  # MUST match R variable name in create_pollution_map() scope
```

**Option B (Refactor - Future):** Eliminate `data_source_var` entirely - Step 1 already loads data into `spatial_data$all_data[[config_name]]` - Could pass data objects through instead of variable name strings - Would require refactoring `get_layer_year_data()` and related functions

------------------------------------------------------------------------

## Summary

### Issue 1: pollutant_col

-   **Current:** Single pollutant per config, but actually ignored at runtime
-   **Impact:** Low - works but misleading
-   **Fix:** Rename to `has_pollution_data` boolean OR support list of pollutants

### Issue 2: data_source_var

-   **Current:** Variable name strings with tight coupling
-   **Impact:** Medium - works but fragile for new networks
-   **Fix:** Document convention OR refactor to eliminate variable names (larger change)

### Recommendation for Step 6

**Ship current design with documentation:** 1. Note in YAML comments that `pollutant_col` is validation only 2. Note in YAML comments that `data_source_var` must match variable name 3. Add to Step 7 cleanup: improve field naming for clarity 4. Flag for future refactoring: eliminate variable name strings

Both issues are **design quirks**, not bugs. System works but could be clearer.
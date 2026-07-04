# Issue: BL Nodes Config Mismatch

## Problem

`bl_nodes.yaml` has `openair_import_function: null` but load logic treats null as "CSV with year columns", not "local RData".

## Current Behavior

**bl_nodes.yaml line 13:** `openair_import_function: null`

**Load logic (R/quickmap.R:2121-2128):**
```r
if (!is.null(config$openair_import_function)) {
  # RData with OpenAir format
  loaded_data[[config_name]] <- load_data_file(data_src, "rdata", pollutant = pollutant)
} else {
  # CSV with year columns  <-- BL falls here incorrectly
  result <- load_data_file(data_src, "csv", c("Easting", "Northing"))
```

## Root Cause

Logic conflates:
- OpenAir API RData (importKCL, importUKAQ)
- Local RData files (BL sensors, stored in DATA_PATH)

Both use same `dataOAformat` structure but different sources.

## Fix Options

**Option A:** Sentinel value in YAML
```yaml
openair_import_function: local  # Not null, not API function
```

Update logic:
```r
if (!is.null(config$openair_import_function) && config$openair_import_function != "local") {
  # OpenAir API
} else {
  # Local RData or CSV
  if (grepl("\\.Rdata$", data_src, ignore.case = TRUE)) {
    # Local RData
  } else {
    # CSV
  }
}
```

**Option B:** Check file extension first
```r
if (grepl("\\.Rdata$", data_src, ignore.case = TRUE)) {
  # All RData files
  loaded_data[[config_name]] <- load_data_file(data_src, "rdata", pollutant = pollutant)
} else {
  # CSV files
  result <- load_data_file(data_src, "csv", c("Easting", "Northing"))
}
```

## Recommendation

**Option B** - File extension is source of truth. Simpler logic, no YAML changes needed.

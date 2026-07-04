# Remove YAML Data Source Configs - Implementation Plan

## Files to Delete
- ✓ `inst/config/data_sources/*.yaml` (5 files)

## Functions to Remove (R/quickmap.R)
- `load_data_source_config()` (lines 729-758)
- `write_data_source_config()` (lines 774-836)

## Parameters to Change (create_pollution_map)

### Remove:
- `data_configs` parameter

### Add:
- `data_ids = NULL` (auto-generate from filenames if NULL)
- `data_symbols = NULL` (auto-cycle if NULL: circle, square, triangle, diamond, cross, star, plus)
- `data_dynamic = NULL` (auto-detect if NULL, else boolean vector)

## Logic Changes

### 1. Auto-generate layer IDs (load_spatial_data_sources)
```r
# Old: config_name <- data_configs[i]
# New:
layer_id <- if (!is.null(data_ids)) {
  data_ids[i]
} else {
  tools::file_path_sans_ext(basename(data_src))
}
```

### 2. Auto-detect temporal/static
```r
detect_data_type <- function(data) {
  cols <- names(data)
  has_years <- any(grepl("^\\d{4}$", cols))
  has_pollutants <- any(c("no2", "pm25", "pm10", "o3") %in% tolower(cols))
  if (has_years || has_pollutants) "temporal" else "static"
}
```

### 3. Auto-cycle symbols (get_measurement_layers)
```r
default_symbols <- c("circle", "square", "triangle", "diamond", "cross", "star", "plus")
symbol <- if (!is.null(data_symbols)) {
  data_symbols[i]
} else {
  default_symbols[((i - 1) %% 7) + 1]
}
```

### 4. Remove YAML loading
- Delete `yaml_config <- load_data_source_config(config_name)`
- Remove all `yaml_config$` references

## Testing Strategy
- Update all test scripts to remove data_configs
- Verify auto-detection with: DT CSV, BL RData, Schools CSV
- Test data_ids override
- Test data_symbols override
- Test data_dynamic override

## Estimated Lines Changed
- Removed: ~110 lines (2 functions)
- Modified: ~50 lines (parameter handling, detection logic)
- Net: -60 lines

## Breaking Changes
- `data_configs` parameter removed (breaking)
- YAML configs no longer used (breaking)
- Migration: remove data_configs, optionally add data_ids for custom layer names

# Migration Example: create_all_borough_maps.R v0.8.x → v0.9.0

## Parameter Mapping Summary

| v0.8.x Parameter | v0.9.0 Parameter | Change Type | Notes |
|------------------|------------------|-------------|-------|
| `csv_data_file` | `diffusion_tube_file` | Renamed | More descriptive |
| `oa_data_file` | `sensor_file` | Renamed | More descriptive |
| `years_to_plot` | `years` | Renamed | Shorter |
| `vignette_overlay_on` | `vignette` | Renamed | Removed "_on" |
| `show_marker_labels` | `marker_labels` | Renamed | Removed "show_" |
| `show_boundary_labels` | `boundary_labels` | Renamed | Removed "show_" |
| `html_page_title` | `title` | Merged | Combined with banner_text |
| `banner_text` | `title` | Merged | Use banner_text value as title |
| `show_banner` | `styling_type` | Merged | "html" if TRUE |
| `show_legend` | `styling_type` | Merged | Removed (always HTML) |
| `show_title` | `styling_type` | Merged | Removed (always FALSE) |
| `scale_to_use` | `colour_scale` | Already renamed | Was done in v0.8.x |
| `banner_color` | `banner_colour` | Fixed spelling | UK English |
| `border_color` | (removed) | Removed | Was duplicate of banner_colour |

## Before (v0.8.x)

```r
map1_merton_no2 <- create_pollution_map(
  csv_data_file = "merton_dt_2018_2024.csv",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  years_to_plot = NULL,
  scale_to_use = "who_no2",
  output_file = "merton_no2_2018_2024_dt_bl.html",
  html_page_title = "LB Merton Annual Mean NO2, 2018-2024",
  banner_text = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  show_banner = TRUE,
  show_legend = FALSE,
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE,
  banner_color = borough_palettes$merton$purple,
  border_color = borough_palettes$merton$purple,
  show_boundary_labels = FALSE
)
```

**Parameter count:** 17 parameters used

## After (v0.9.0)

```r
map1_merton_no2 <- create_pollution_map(
  diffusion_tube_file = "merton_dt_2018_2024.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  years = NULL,
  colour_scale = "who_no2",
  output_file = "merton_no2_2018_2024_dt_bl.html",
  title = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  banner_colour = borough_palettes$merton$purple,
  boundary_labels = FALSE
)
```

**Parameter count:** 14 parameters used (18% reduction)

## Key Simplifications

### 1. Title Consolidation
**Before:** Two separate parameters
```r
html_page_title = "LB Merton Annual Mean NO2, 2018-2024",
banner_text = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
```

**After:** Single parameter (use the more descriptive banner_text value)
```r
title = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
```

### 2. Styling Consolidation
**Before:** Three separate boolean flags
```r
show_banner = TRUE,
show_legend = FALSE,
show_title = FALSE,
```

**After:** Single multi-value parameter
```r
styling_type = "html",  # HTML banner + legend
```

**Styling options:**
- `"none"` → No banner or legend (plain map)
- `"html"` → HTML banner above map + external HTML legend

### 3. Clearer Data Source Names
**Before:**
```r
csv_data_file = "merton_dt_2018_2024.csv",
oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
```

**After:**
```r
diffusion_tube_file = "merton_dt_2018_2024.csv",
sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
```

### 4. Consistent Naming (removed "show_" prefixes)
**Before:**
```r
show_marker_labels = TRUE,
show_boundary_labels = FALSE,
```

**After:**
```r
marker_labels = TRUE,
boundary_labels = FALSE,
```

## Benefits

1. **Fewer parameters:** 17 → 14 in typical usage (18% reduction)
2. **Clearer intent:** `styling_type = "html"` vs 3 separate flags
3. **Self-documenting:** `diffusion_tube_file` vs `csv_data_file`
4. **Consistent naming:** No more "show_" prefix inconsistency
5. **Single title:** One place to set title text for all contexts

## See Also

- Full migration guide: `quickmap.R` header lines 39-68
- Complete changelog: `plans_reference_documents/v0.9.0_parameter_changes.md`
- Updated script: `scripts/create_all_borough_maps.R`

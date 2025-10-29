# Parameter Simplification → v0.9.0

**Goal:** 21 parameters → 15 parameters (29% reduction)

---

## Changes Summary

### STEP 1: Renames [LLM - find/replace]
- `years_to_plot` → `years`
- `vignette_overlay_on` → `vignette`
- `csv_data_file` → `diffusion_tube_file`
- `oa_data_file` → `sensor_file`
- `show_marker_labels` → `marker_labels`
- `show_boundary_labels` → `boundary_labels`

### STEP 2: Merge Image Export [LLM]
- `image_export` + `map_width_px` + `map_height_px` → `export_image`
- Usage: `export_image = NULL` (no export) or `export_image = c(1920, 1080)` (export at dimensions)

### STEP 3: Merge Title Content [LLM]
- `html_page_title` + `banner_text` → `title`
- Single text used for both browser tab and banner

### STEP 4: Merge Styling System [LLM]
- `show_banner` + `show_title` + `title_prefix` + `show_legend` → `styling_type`
- Values: `"none"` | `"html"` | `"leaflet"`
- Controls whether title/legend displayed as HTML wrapper or Leaflet overlay

### STEP 5: Documentation [LLM]
- Add v0.9.0 header to quickmap.R with migration guide
- Update PARAMETER_REFERENCE.md

### STEP 6: Backup & Commit [USER]
- Copy to `versions/quickmap_0_9_0.R`
- Git commit

---

## Final Parameter List (15 Total)

### Location & Data (3)
- `boroughs`
- `pollutant`
- `years`

### Data Input (3)
- `diffusion_tube_file`
- `sensor_file`
- `school_file`

### Output (2)
- `output_file`
- `export_image`

### Styling (7)
- `title`
- `vignette`
- `colour_scale`
- `styling_type`
- `marker_labels`
- `banner_colour`
- `boundary_labels`

---

## Testing after each step
- Draft a simple one shot test file for each step, minimal cat statements, no trycatch
- User sources file after each step
- User runs test file
- Test styling_type: "none", "html", "leaflet"
- Test export_image: NULL vs c(1920, 1080)

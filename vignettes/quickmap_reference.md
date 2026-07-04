# QuickMap Parameter Reference

Quick reference for `create_pollution_map()`. For full documentation see the Roxygen help
(`?create_pollution_map` after loading the package).

## Setup

```r
library(quickmap)
Sys.setenv(DATA_PATH = "~/Coding/Library/data")
```

## Minimal Example

```r
create_pollution_map(
  data_sources  = list("wandsworth_2017_2024.csv", "schools_Wandsworth.csv"),
  boroughs      = "Wandsworth",
  output_file   = "wandsworth_2024"
)
```

## Full Example

```r
create_pollution_map(
  data_sources   = list(
    "wandsworth_2017_2024.csv",
    "bl_imperial_annualised_2021_2025.Rdata",
    "schools_wandsworth.csv"
  ),
  boroughs       = "Wandsworth",
  pollutant      = "no2",
  display_times  = NULL,          # all available years
  colour_scale   = "who_no2",
  output_file    = "wandsworth_no2",
  export_image   = TRUE,
  styling_type   = "html",
  title          = "Wandsworth NO2 Annual Mean",
  marker_labels  = "labels",
  vignette       = TRUE
)
```


## Parameters

### Data

| Parameter | Default | Description |
|-----------|---------|-------------|
| `data_sources` | `NULL` | List of file paths (CSV / RData) or `sf` objects. `DATA_PATH` is prepended when set |
| `data_ids` | `NULL` | Layer IDs — auto-generated from filenames if `NULL` |
| `data_symbols` | `NULL` | Marker shape per layer — auto-assigned by data type if `NULL` |
| `data_dynamic` | `NULL` | Logical vector: `TRUE` = temporal, `FALSE` = static — auto-detected if `NULL` |

Valid `data_symbols` values: `"circle"`, `"diamond"`, `"cross"`, `"square"`, `"triangle"`, `"star"`, `"plus"`

Default assignments by data type: diffusion tubes → circle, Breathe London sensors → diamond, schools → cross.

### Output

| Parameter | Default | Description |
|-----------|---------|-------------|
| `output_file` | `"pollution_map.html"` | Filename without extension — saved to `aq_maps/` |
| `export_image` | `NULL` | `NULL` = HTML only, `TRUE` = 1200×1200 JPG, `c(w, h)` = custom dimensions |

### Map Content

| Parameter | Default | Description |
|-----------|---------|-------------|
| `boroughs` | *(required)* | Borough name(s) for boundary display and data filtering |
| `pollutant` | `"no2"` | `"no2"` or `"pm25"` |
| `display_times` | `NULL` | Time periods to show — `NULL` uses all periods found in data |
| `colour_scale` | `"who_no2"` | Colour scale name (see [Colour Scales](#colour-scales) below) |

`display_times` format depends on temporal resolution:

| Resolution | Format | Example |
|------------|--------|---------|
| Annual | `"YYYY"` | `"2023"` |
| Monthly | `"YYYY-MM"` | `"2023-01"` |
| Daily | `"YYYY-MM-DD"` | `"2023-01-15"` |
| Hourly | `"YYYY-MM-DD HH:MM"` | `"2023-01-15 10:00"` |

### Styling

| Parameter | Default | Description |
|-----------|---------|-------------|
| `styling_type` | `"html"` | `"html"` = banner + legend, `"none"` = plain map |
| `title` | `NULL` | Banner text (falls back to theme) |
| `banner_colour` | `NULL` | Hex colour for banner and vignette overlay (falls back to theme) |
| `vignette` | `NULL` | `TRUE` darkens area outside the borough(s) (falls back to theme) |
| `boundary_labels` | `NULL` | `TRUE` shows borough name labels on boundary (falls back to theme) |
| `theme_file` | `NULL` | Path to a YAML theme file — see `inst/themes/` for examples |

### Labels

| Parameter | Default | Description |
|-----------|---------|-------------|
| `marker_labels` | `NULL` | Label mode (falls back to theme) — see options below |

| Value | Behaviour |
|-------|-----------|
| `FALSE` | No labels |
| `TRUE` | Labels on hover |
| `"values_on"` | Pollution values always visible |
| `"labels"` | Custom labels (School name / Label column) on hover |
| `"labels_on"` | Custom labels always visible |

Label content is duck-typed from the data: `School` column → school names; `Label` column → custom labels; otherwise pollutant values.

### Animation

| Parameter | Default | Description |
|-----------|---------|-------------|
| `autoplay` | `NULL` | `TRUE` auto-starts time animation on load (falls back to theme) |
| `play_speed` | `NULL` | Milliseconds per frame during animation (falls back to theme) |

## Colour Scales

Defined in `inst/config/scales/`. Pass the name (without `.yaml`) to `colour_scale`.

| Name | Pollutant | Description |
|------|-----------|-------------|
| `who_no2` | NO2 | WHO guideline bands (default) |
| `stripes_no2` | NO2 | Stripe-style NO2 scale |
| `gla_pm25` | PM2.5 | GLA PM2.5 bands |
| `lbw_no2` | NO2 | London Borough of Wandsworth |
| `lbrut_no2` | NO2 | London Borough of Richmond upon Thames |
| `lbm_no2` | NO2 | London Borough of Merton |
| `deltas` | Any | Year-on-year change |
| `schools` | — | Categorical (school type) |

## Data File Formats

### CSV (diffusion tubes or schools)

Input coordinates must be British National Grid (EPSG:27700) — transformed to WGS84 on load.

| Column | Required? | Effect |
|--------|-----------|--------|
| `Easting` | **Required** | BNG X coordinate |
| `Northing` | **Required** | BNG Y coordinate |
| `YYYY` (e.g. `2017`) | At least one | Pollutant value for that year — matched by pattern `^\d{4}`, pivoted to long format |
| `Label` | Optional | Marker label text. Rows with an empty `Label` are **silently dropped**. Used when `marker_labels = "labels"` or `"labels_on"` |
| `School` | Optional | School layer detection trigger (duck typing). Its value becomes the marker label. Takes priority over `Label` |
| `Level` | Optional | School type for categorical colouring — used with the `schools` colour scale |
| Any other column | — | Passed through silently; not plotted, not filtered |

> **Watch out:** if `Label` is present and a row has an empty label cell, that site is dropped from the map entirely.

### RData (Breathe London / sensor networks)

Object duck-typed in order: `dataOAformat` → `data` → `oa_data` → `sensor_data` → largest compatible `data.frame`.

| Column | Required? | Effect |
|--------|-----------|--------|
| `siteCode` | **Required** | Site identifier. `code` is accepted and auto-renamed |
| `lat` | **Required** | Latitude WGS84. `latitude` is accepted and auto-renamed |
| `lon` | **Required** | Longitude WGS84. `longitude` is accepted and auto-renamed |
| `no2` / `pm25` / `pm10` | **Required** | Pollutant column — must match the `pollutant` parameter |
| `year_str` | Temporal (one required) | Highest-priority time column — data used as-is if present |
| `date` / `date_time` / `time` / `datetime` / `timestamp` | Temporal (one required) | Datetime column — temporal resolution (hour/day/month/year) inferred from median gap between values |
| `year` | Temporal (one required) | Fallback integer year — used if no datetime column found |


---

**Version**: QuickMap v0.9.4  
**Last updated**: 2026-07-02

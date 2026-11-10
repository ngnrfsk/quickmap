# quickmap

R package that turns air quality monitoring data into a self-contained interactive
HTML map (Leaflet), with optional JPG and animated GIF exports. Built for UK local
government officers and air quality consultants: a two-line call gives a usable map;
each further argument adds one feature.

Version and dependencies: `DESCRIPTION`. History: `NEWS.md`. Roadmap and open
defects: `dev/PROJECT_STATUS.md`.

```r
library(quickmap)
quickmap("wandsworth_2017_2024.csv", boroughs = "Wandsworth",
         output_file = "wandsworth_no2.html")
```

## What it does

- Plots NO2, PM2.5 and PM10 sites as coloured symbols (circles for diffusion tubes,
  diamonds for sensors, crosses for schools) over borough or ward boundaries.
- Animates multi-year or sub-annual data with a time slider (15-minute to monthly
  steps, capped at 200), all in one file that works offline as an email attachment.
- Shows the network mean and maximum per year on the legend (annual maps only).
- Overlays animated wind from a worldmet station.

## Data sources

Input type is detected from the columns present, never from the file name.
Relative paths resolve against the `DATA_PATH` environment variable.

| Source | Wrapper | Required columns |
|---|---|---|
| Diffusion-tube CSV | `from_csv()` | `Easting`, `Northing` (British National Grid), one column per year |
| Schools CSV | `from_csv()` | `Easting`, `Northing`, `Level`, `School` |
| Sensor / monitor RData | `from_rdata()` | `siteCode` or `code`, `year`, pollutant, `lat`, `lon` |
| openair networks (AURN, KCL, AQE, SAQN, WAQN, NI) | `from_openair()`, `get_openair_metadata()` | openair output |
| Wind | `from_worldmet()` | worldmet station data |

Boundaries: `ward_boundaries.Rdata` under `DATA_PATH`, names mapped by
`inst/config/boundaries.yaml`.

## Methods

Every layer becomes a `qm_layer()`: an sf object, one row per site per time step,
metadata stored as attributes. One pipeline renders all layers:

```
load_data_file() → get_measurement_layers() → prepare_generic_layer_data() →
create_generic_icons() → add_layer() → generate_map_layers()
```

- Coordinates: EPSG:27700 converted to WGS84 by `transform_to_wgs84()`.
- Colours: YAML scales in `inst/config/scales/` (e.g. `who_no2`, `gla_pm25`,
  council AQAP scales), threshold or categorical.
- Styling: YAML themes in `inst/themes/` for banner, legend, base tiles and controls;
  explicit `quickmap()` arguments override the theme.
- Rendering: Leaflet canvas markers restyled from one embedded JSON payload; above
  50 steps or about 5 MB, steps are drawn on demand.
- Templates: CSS/JS in `inst/banner/`, `inst/legend/`, `inst/controls/`, filled by
  `{{placeholder}}` substitution.

## Public functions

| Function | Purpose |
|---|---|
| `quickmap()` | Build a map from file paths, `qm_layer`s or data frames |
| `create_pollution_map()` | Older `data_sources` interface; calls `quickmap()` |
| `qm_layer()`, `qm_meta()` | Build or inspect a layer |
| `from_csv()`, `from_rdata()`, `from_openair()`, `from_worldmet()` | Input wrappers |
| `load_colour_scale()`, `load_theme()` | Read styling YAML |
| `get_openair_metadata()`, `convert_openair_to_spatial()`, `clear_openair_metadata_cache()` | openair site metadata |
| `show_borough_colours()` | Preview boundary colours |

## Related tools

- **quickplot**: seed of a separate package, planned for its own repository after
  1.0. Charts and tables that reuse quickmap's banner, legend and colour scales so
  figures match the maps: site-by-year heatmap table, trend chart over threshold
  bands, exceedance counts. Prototypes and README are in
  `~/Coding/quickmap-work/260814 Merton AQAP maps and figures refresh/scripts/`
  (`quickplot_README.md`).
- **quickmap-work** (`~/Coding/quickmap-work/`): maps made for councils and
  websites, one folder per job, using the installed package. Not in this repository.
- **openair / worldmet**: optional dependencies for pulling monitoring and wind data.

## Building companion tools

Tools that reuse quickmap's styling (banner, legend, colour scales) so their
output matches the maps. Entries marked `internal` are not exported: call them
with `quickmap:::` and expect them to change without notice. Arguments as of
the version in `DESCRIPTION`.

```yaml
quickmap_interface:
  depends: library(quickmap)                  # installed package, never source("R/...")
  data_root: Sys.getenv("DATA_PATH")          # relative input paths resolve here
  scales_dir: system.file("config/scales", package = "quickmap")   # <name>.yaml
  themes_dir: system.file("themes", package = "quickmap")
  functions:
    load_colour_scale(name):                  {status: exported, returns: "list: thresholds, colours, labels, domain"}
    load_theme(theme_file = NULL):            {status: exported, returns: "theme list merged over defaults"}
    assign_colour(value, scale):              {status: internal, returns: "colour for one value"}
    convert_colors_to_hex(color_vector):      {status: internal, returns: "hex strings (R colour names differ from CSS)"}
    get_contrast_text_color(color):           {status: internal, returns: "black or white text for a background"}
    build_banner_css(banner_colour, image_mode = FALSE, banner_style = "strip", text_colour = "white"): {status: internal}
    build_legend_css(banner_colour, image_mode = FALSE, legend_background = "white"):                   {status: internal}
    generate_legend_html(scale_name, collapsed_mobile = TRUE):      {status: internal}
    resolve_output_path(output_file, output_dir = NULL):            {status: internal, rule: "caller names every output"}
    take_screenshots(html_file, image_files, image_dimensions):     {status: internal, rule: "use for JPG export; retries"}
  image_mode: TRUE for static (JPG) export CSS, FALSE for interactive HTML
  dependency_direction: companion tools use quickmap; quickmap never uses them
```

## Repository layout

| Path | Contents |
|---|---|
| `R/` | Package code: `quickmap.R` (pipeline), `quickmap_api.R`, `qm_layer.R`, `wind.R` |
| `inst/` | Scales, themes, boundaries config, HTML/CSS/JS templates, vendored leaflet-velocity |
| `vignettes/` | User manual chapters (data, layers, labels, boundaries, styling, time, wind, sharing, recipes) |
| `tests/` | `testthat/` suite and the `test_quickmap.R` smoke test |
| `scripts/` | Demo, manual-build and maintenance scripts; not shipped |
| `dev/` | Status, plans, design notes |
| `versions/` | Superseded copies of the production code |
| `aq_maps/` | Generated demo maps (gitignored) |

## Install and test

```r
devtools::install()
testthat::test_dir("tests/testthat")
source("tests/test_quickmap.R")    # needs DATA_PATH set
pkgdown::build_site()              # user manual into docs/
```

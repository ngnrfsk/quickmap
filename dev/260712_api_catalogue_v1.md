# QuickMap API catalogue — traced from the code (v0.9.9.7)

**Date:** 2026-07-12 · **Method:** every exported function and every argument traced to its consumption point in R/ source; behaviour stated is what the code does, not what older docs claim. Organised per R help-file conventions (Description / Usage / Arguments / Details / Value / See also), grouped as the pkgdown reference index groups them. This is the groundwork document for the item-9 roxygen audit — discrepancies between this and the current .Rd text are the audit's worklist.

------------------------------------------------------------------------

## Group 1 — Making maps

### quickmap()

**Description.** The core entry point: renders one or more layers as a self-contained interactive HTML map (optionally plus JPG stills).

**Usage.**

``` r
quickmap(layers, boroughs = NULL, pollutant = NULL, display_times = NULL,
         colour_scale = "who_no2", output_file = "quickmap.html",
         title = NULL, styling_type = "html", export_image = NULL,
         marker_labels = NULL, vignette = NULL, banner_colour = NULL,
         boundary_labels = NULL, autoplay = NULL, play_speed = NULL,
         theme_file = NULL, data_symbols = NULL, wind = NULL)
```

**Arguments (traced).**

| Argument | Default | Traced behaviour |
|------------------------|------------------------|------------------------|
| `layers` | — (required) | One item or a list. Character path ending `.rdata` (case-insensitive) → `from_rdata()`; other character → `from_csv()`; data.frame/sf → `qm_layer()`; `qm_layer` passed through. Layer names deduplicated with `make.unique`. |
| `boroughs` | `NULL` | NULL: no boundary, vignette forced off, viewport = union of layer bounding boxes. Name(s) or `"All"`: boundary drawn; case-insensitive, common misspellings corrected (`name_corrections` in inst/config/boundaries.yaml); an unrecognised name is a hard `stop()` listing every accepted name. |
| `pollutant` | `NULL` | NULL: inferred as the `value_col` of the first time-varying layer, else `"no2"`. Also passed to path-built RData/CSV layers as their value column. |
| `display_times` | `NULL` | NULL = all steps found in the first temporal layer. Otherwise intersected with available steps (formats: YYYY / YYYY-MM / YYYY-MM-DD / "YYYY-MM-DD HH:MM"); numeric years coerce fine. Result then passes the 200-step cap (warn + keep most recent; option `quickmap.time_step_cap`). Empty intersection → empty map layers (no error) — **audit note: could warn**. |
| `colour_scale` | `"who_no2"` | Name of a YAML file in inst/config/scales/. Drives symbol colours, the legend, and lazy-payload thresholds. Legend rows above the data maximum are trimmed (min 2 rows kept). |
| `output_file` | `"quickmap.html"` | Written verbatim to `aq_maps/<output_file>` (extension NOT appended). `NULL` = return the widget without writing (also skips banner/legend/slider injection). |
| `title` | `NULL` | Banner text + browser tab title. NULL → theme's `banner.title` ("Air Quality Map" default). |
| `styling_type` | `"html"` | `"html"`: banner, ramp legend and time slider are injected into the saved file. Any other value (conventionally `"none"`): bare Leaflet widget. |
| `export_image` | `NULL` | NULL: no stills. TRUE: 1200×1200. `c(w, h)`: custom. One JPG **per selected time step**, named `<base>_<step>.jpg`; chrome text scales by `sqrt(w*h)/1200` via root font-size; wind omitted; slider replaced by a static step label. |
| `marker_labels` | `NULL` | NULL → theme (`map.marker_labels`, default FALSE). FALSE / TRUE (values on hover) / `"values_on"` / `"labels"` / `"labels_on"`. Name content per layer: `School` col → school name; `Label` col → label text; else values with a warning. |
| `vignette` | `NULL` | NULL → theme (`map.vignette`, default TRUE). Only effective when a boundary exists. |
| `banner_colour` | `NULL` | NULL → theme `banner.background` (#5F3E94). Feeds the strip rule / bar fill, slider accents, legend hover tint, vignette fill. |
| `boundary_labels` | `NULL` | NULL → theme (`map.boundary_labels`, default FALSE). TRUE writes area names on the map. |
| `autoplay` | `NULL` | NULL → theme (`controls.autoplay`, default FALSE). Starts the slider playing on load (multi-step maps only). |
| `play_speed` | `NULL` | NULL → theme (`controls.play_speed`, 500). Milliseconds per step. |
| `theme_file` | `NULL` | Path to YAML; merged over `get_default_theme()` with `modifyList` (missing keys inherit; `key: null` in YAML deletes the key → default applies). Bad path/parse = warning + defaults. |
| `data_symbols` | `NULL` | Map-level override, one renderer symbol name per layer, in order. Precedence: `data_symbols` \> layer `shape` metadata \> automatic cycle (temporal: circle, rect, triangle, diamond…; static: simple-plus, simple-cross…). |
| `wind` | `NULL` | A `from_worldmet()` object or any data frame with `date`/`ws`/`wd`. Period-mean U/V per displayed step on a padded 2×2 grid; leaflet-velocity overlay advancing with the slider; styling from theme `wind:`; interactive HTML only. |

**Value.** The Leaflet widget, invisibly. Side effects: files in `aq_maps/`.

**Details — the lazy rendering switch.** Above 50 time steps or \~5 MB estimated (options `quickmap.lazy_step_threshold`, `quickmap.lazy_size_threshold`) temporal symbols are Canvas-rendered from one embedded JSON payload and restyled per step (1–3 ms); below, per-step layers are pre-built. Static export always uses pre-built rendering.

### create_pollution_map()

**Description.** Compatibility wrapper with the historic signature; converts `data_sources` to `qm_layer`s and delegates to `quickmap()`.

**Extra/renamed arguments (traced).**

| Argument | Traced behaviour |
|------------------------------------|------------------------------------|
| `data_sources` | as `layers` |
| `data_ids` | overrides each layer's `name` metadata (legend/controls text) |
| `data_dynamic` | logical per layer → `from_csv(temporal =)` force flag |
| `output_file` | default `"pollution_map.html"` |
| everything else | identical to `quickmap()` |

------------------------------------------------------------------------

## Group 2 — Layers (the atomic unit)

### qm_layer()

**Description.** Constructs the internal currency: an sf object, long format (one row per site per time step), metadata as attributes.

**Arguments (traced).**

| Argument | Default | Traced behaviour |
|------------------------|------------------------|------------------------|
| `data` | — | sf, or data.frame with `lat`/`lon` (WGS84). Aliases normalised: `siteCode`→`code`, `year_str`→`time_label`, `Latitude`/`Longitude`→`lat`/`lon`. `code` required (plain-English error if absent). |
| `value_col` | `NULL` | Inferred: first known pollutant column (no2, pm25, pm10, nox, no, o3, so2, co, case-insensitive), else the single remaining candidate; two candidates = error naming them. |
| `time_col` | `NULL` | Inferred: any Date/POSIXct column by class, else a column named date/time/datetime/time_label/year_str parsed against the grammar (YYYY · YYYY-MM · YYYY-MM-DD · YYYY-MM-DD HH:MM(:SS)); a gate-named column failing the grammar is a hard error. Explicit `time_col` with unparseable values = custom ordering honoured (e.g. diurnal hours). |
| `label_col` | `NULL` | Inferred from `Label` then `School`. |
| `shape` | `NULL` | NULL = map assigns (cycle). Friendly names square/cross/star/plus normalise to rect/simple-cross/simple-star/simple-plus; any exact renderer name accepted; unknown = error listing all 18. |
| `name` | `"layer"` | Legend/controls/error text. |

**Value.** The data as class `c("qm_layer", "sf", ...)`; metadata via `qm_meta()` (value_col, time_col, label_col, shape, name, resolution).

### from_csv(file, pollutant = "no2", name = NULL, temporal = NULL)

Diffusion-tube CSVs (Easting/Northing/year columns, BNG) pivot to long and become circle layers; a `School` column makes a static cross layer (`Level` = categorical value); other static CSVs get no explicit shape (cycle assigns). `temporal` forces the choice. `name` defaults to the file name. Rows with an empty `Label` cell are dropped (gotcha). Paths resolve against `DATA_PATH`.

### from_rdata(file, pollutant, name = NULL, data_object_name = NULL)

Duck-typed load: object named dataOAformat/data/oa_data/sensor_data, else the largest compatible data frame (siteCode + coordinates + time + pollutant); `data_object_name` overrides. Diamond shape. Datetime columns set resolution by median gap (≤1h hour, ≤24h day, ≤744h month, else year).

### from_openair(data, pollutant, source = NULL, avg.time = "year", name = "openair")

Wraps `convert_openair_to_spatial()`: requires `date` + `code`/`siteCode`; aggregates to `avg.time` (openair vocabulary); fetches coordinates from network metadata when the frame lacks lat/lon — **`source` is then required** ("aurn", "kcl", …). Diamond shape.

### from_worldmet(data = NULL, station = NULL, year = NULL)

Either a `worldmet` station id + year(s) (NOAA fetch; worldmet is Suggests) or any data frame with `date`/`ws`/`wd`. Returns a `qm_wind` frame (U/V by meteorological decomposition) for `quickmap(wind =)`.

### qm_meta(x)

Returns the metadata list of a `qm_layer`. Errors on anything else.

------------------------------------------------------------------------

## Group 3 — Styling

### load_theme(theme_file = NULL)

YAML over defaults via `modifyList`. Key surface (all optional): `banner.style` ("strip"/"bar"), `banner.background`, `banner.text_color`, `banner.title`; `legend.show`, `legend.background`; `map.vignette`, `map.base_tiles` (any Leaflet provider; NULL = OSM), `map.zoom_level` (fixed zoom instead of fit), `map.boundary_labels`, `map.marker_labels`; `controls.autoplay`, `controls.play_speed`; `wind.colour_ramp`, `wind.particle_density`, `wind.line_width`, `wind.velocity_scale`; `palette.*` (free-form named colours for reuse). Precedence everywhere: explicit argument \> theme \> default.

### load_colour_scale(scale_name)

Reads inst/config/scales/<name>.yaml → list(name, title, pollutant, thresholds, colours, labels) with validation. Label text after a range ("10-19 ‡ WHO Int 3" pattern) becomes the legend's footnote key.

### show_borough_colours(borough = NULL)

Lists bundled themes; with a name, prints that theme's palette.

------------------------------------------------------------------------

## Group 4 — OpenAir interoperability

### convert_openair_to_spatial(data, source = NULL, pollutant, avg.time = "year")

The engine under `from_openair()`: validates `date` + site id, aggregates with openair's `timeAverage`, joins coordinates from `get_openair_metadata(source)` when absent, returns long-format sf with `year_str` labels.

### get_openair_metadata(source) / clear_openair_metadata_cache(source = NULL)

Cached network metadata (site coordinates) per source; clear to force a re-fetch.

------------------------------------------------------------------------

## Group 5 — Non-function API surfaces (document per R conventions in a package-options topic)

| Surface | Traced behaviour |
|------------------------------------|------------------------------------|
| `DATA_PATH` env var | Prepended to relative data file paths in `from_csv`/`from_rdata`. |
| `options(quickmap.time_step_cap)` | Default 200; warn + keep most recent. |
| `options(quickmap.lazy_step_threshold)` | Default 50 steps. |
| `options(quickmap.lazy_size_threshold)` | Default \~5 MB estimated. |
| Colour-scale YAML | thresholds/colours/labels contract (Group 3). |
| Theme YAML | full key table (Group 3). |
| Output contract | `aq_maps/` auto-created in the working directory; `_files` folders cleaned up. |

------------------------------------------------------------------------

## Audit worklist extracted (for item 9)

1.  `render_pollution_map()`'s roxygen still says "Output filename (without extension)" — false (verbatim).
2.  Empty `display_times` intersection renders an empty map silently — consider a warning.
3.  `marker_labels`/`data_symbols` naming inconsistency — pending user decision on `symbol_labels` alias.
4.  `styling_type` accepts any string as "none" — consider `match.arg`.
5.  `from_csv(pollutant =)` names the value column of *temporal* CSVs only — roxygen should say so.
6.  `qm_layer()` roxygen `@param shape` updated at v0.9.9.x but `create_pollution_map()`'s data_symbols text still lists only 7 symbol names — the renderer accepts 18.
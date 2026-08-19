# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

**The code is the source of truth.** Full internal consistency is a v1.0 goal and has never been reached. Verify any documented claim against the source before acting on it; when a doc contradicts the code, fix the doc in the same change.

## Project Overview

**QuickMap** builds interactive HTML/JS air quality maps for distribution and print quality maps for publication, with minimal programming overhead. It is not intended to create interactive live R session maps.

- **Accessibility is the point.** Users bring a diffusion-tube CSV, an Excel export, a sensor RData object or an OpenAir pull, and get a professional map without deep R knowledge. A two-line call produces a usable map; each further parameter unlocks more.
- **v1.0 scope: air quality.** NO2 and PM2.5 over contextual layers such as schools and borough boundaries. Output is a self-contained Leaflet HTML map, optionally a static JPG. Users are local government officers and air quality consultants.
- **The distinctive capability** is production-ready temporal animation of monitoring-network data in a self-contained file. It does not compete with `mapview` or `tmap`.
- **Beyond v1.0** the architecture generalises to any time-varying, located data — a spatial companion to OpenAir.

### Current version

DESCRIPTION's `Version:` field is authoritative; dev/PROJECT_STATUS.md states it in prose. Production code is R/quickmap.R with R/qm_layer.R, R/quickmap_api.R and R/wind.R; superseded copies are in versions/. Version history is NEWS.md; the roadmap and open defects are in dev/PROJECT_STATUS.md, whose history to 2026-08-16 is in dev/archive/PROJECT_STATUS_history_to_260816.md.

## Core Architecture

One pipeline processes every layer:

```         
load_data_file() → get_measurement_layers() → prepare_generic_layer_data() →
create_generic_icons() → add_layer() → generate_map_layers()
```

- `generate_map_layers()` emits interactive HTML and static exports from one loop, so the two formats stay identical.
- Symbol convention: circles for diffusion tubes, diamonds for sensors, crosses for schools. Colours come from thresholds or categories.
- British National Grid input is converted by `transform_to_wgs84()` (EPSG:27700 → 4326), which returns both sf geometry and plain `Longitude`/`Latitude` columns; the renderer reads the plain columns.
- Styling, colours and layer definitions live in configuration objects, not in the render code.

## Development Workflow

Interactive sessions follow this section. Autonomous sessions follow "Autonomous Agent Instructions" below, which overrides it.

- Plans live in dev/ as `YYMMDD_project_name_plan.md`.
- **Starting**: confirm the plan with the user, then branch.
- **Ending**: ask the user to finish testing; draft documentation in outline here and in detail in dev/PROJECT_STATUS.md; ask whether to commit; copy the version to versions/ either way.

### Running the code

``` r
library(quickmap)          # devtools::install() first, and after editing R/
source("tests/test_quickmap.R")
```

### Creating maps

`quickmap()` is the core API (v0.9.6+). Layers may be file paths, `qm_layer()` objects or data frames.

``` r
quickmap("wandsworth_2017_2024.csv", boroughs = "Wandsworth")

quickmap(
  list("merton_dt_2018_2024.csv", "bl_sensors.Rdata", "schools_Merton.csv"),
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "Merton NO2",
  output_file = "merton_no2.html"
)
```

`create_pollution_map()` is a compatibility wrapper keeping the historic `data_sources` signature; it converts to `qm_layer`s and delegates to `quickmap()`. Worked examples: vignettes/quickmap.Rmd.

### Environment setup

`DATA_PATH` points to `~/Coding/Library/data`. Claude Code sessions get it from `.claude/settings.json`; verify with `Sys.getenv("DATA_PATH")` and never set it inline in a bash command (see "Permissions and command style").

## Data Formats

Types are duck-typed by column, never by filename. Full column tables: vignettes/your-data.Rmd.

- **CSV**: `Easting` + `Northing` (EPSG:27700) plus year columns. `Label` is optional custom site names. More than one year column makes the layer temporal.
- **RData**: OpenAir long format needing `siteCode` (or `code`), `year`, the pollutant, `lat`, `lon`. The loader checks standard object names (dataOAformat/data/oa_data/sensor_data), then any compatible data.frame, taking the largest.
- **Schools**: `Easting`, `Northing`, `Level`, `School`. The `School` column is the detection gate.

## Configuration System

`inst/` holds every external template and config:

- `banner/`, `legend/`: CSS templates with `{{placeholder}}` substitution.
- `controls/`: `time-slider.*`, `indicator.js`, `wind-controller.js`, `lazy-time-controller.js`, `layer-cache.js`, and the vendored `leaflet-velocity/`.
- `config/scales/`: YAML colour scales. `themes/`: YAML themes.

### Colour scales

`load_colour_scale("who_no2")` reads the YAML and coerces `thresholds` to numeric. It does not validate; the colours/labels length check is in `generate_legend_html()`.

``` yaml
name: who_no2
title: "NO2, µg/m³"
pollutant: NO2
shape: circle
thresholds: [0, 10, 20, 40, .Inf]
colours: ["green", "yellow", "orange", "red", "white"]
labels: ["< 10: Good", "10-20: Fair", "20-40: Poor", "> 40: Bad", "No data"]
footnote_symbols: true   # optional, default true
```

Categorical scales use `domain` for the values matched against the data, and `labels` for what is displayed. A label `"range: description"` puts `range` under its ramp block and `description` in a band-coloured pill; no colon, no pill. `footnote_symbols: false` drops the `†`/`‡`/`§` cross-references and keeps the pills.

### Themes

`get_default_theme()` defines the keys; `load_theme()` merges a file over them and falls back gracefully. Explicit `quickmap()` arguments override the theme. Worked example: vignettes/styling.Rmd.

- `banner`: background, text_color, title, style (`strip` default, or `bar`)
- `legend`: show, background
- `indicator`: show, label, show_max, placement
- `map`: vignette, base_tiles (NULL = OSM), zoom_level, boundary_labels, marker_labels, label_scale, label_background
- `controls`: autoplay, play_speed (NULL = step-count pacing), background, text_color
- `wind`: colour_ramp, particle_density, line_width, velocity_scale

### Named placeholders

CSS/JS templates use `{{placeholder_name}}`, substituted by `apply_template_replacements()`. A missing placeholder is a hard error. Used by `build_banner_css()`, `build_legend_css()`, `load_time_slider_control()`.

## UI

### Legend and banner

- `inject_banner_legend_controls()` post-processes the saved HTML. A missing injection anchor is a hard error.
- The legend is generated from the colour scale, collapses on click and auto-collapses below 480px.
- `build_banner_key()` renders a static layer's `Level` categories as an inline SVG key at the end of the banner. Sized in `em`, so it scales with a static export.

### Time slider (v0.9.9.5+)

- Bottom-centre card: play, ‹ › fine steps, draggable track (drag seeks coarsely with crossfade suppressed), current step labelled above the thumb. Keyboard: arrows step, Home/End jump, Space plays.
- Speed multipliers come from `speed_multipliers()` and reach JS as `speeds` in `window.quickmapConfig`. Default pace is `default_play_speed()`: 1200ms for ≤12 steps, 800ms to 60, 450ms above. An explicit `play_speed` wins.
- **Constraint**: `time-slider.js` has two places that start a timer, play and resume-after-hidden. Both must read the JS `currentInterval` helper, or speed is right on play and wrong after a return to the tab.
- Files: `inst/controls/time-slider.html`, `.css`, `.js`.

### Legend indicator (v0.9.9.9+)

- Shows the network mean for the displayed step on the legend's own ramp, as a roundel, with the maximum as a diamond when `indicator.show_max` is on.
- **Two bases, both stated in the captions.** The mean uses a fixed panel of sites reporting in *every* displayed step, so it changes only with concentrations, not with which sites report. The maximum is the worst site actually reporting, so its count moves between steps.
- **Annual maps only**: `build_indicator_data()` returns NULL unless every step is a bare four-digit year, because the thresholds are annual-mean limits.
- **Never on a scale of its own.** The ramp gives every band equal width, so a second linear scale would put one threshold in two places. `ramp_position()` maps a value band by band.
- **Placement** (`indicator.placement`): `title_row` (default), `under_title`, or `right` of the ramp. Phones use the wrapping row layout whichever is set.
- Marker collision is resolved in the browser by measuring the labels; `QM_MARKER_CLEARANCE` is R's fallback for static exports, which have no JS.
- `inst/controls/indicator.js` registers `window.quickmapIndicatorController`, called from `switchToTime` in `time-slider.js` **above** the lazy-path early return. Server-side drawing for exports is `generate_indicator_html()`.

## Outputs

Maps are written to an auto-created `aq_maps/` directory: HTML always, JPG when `export_image` is set, with temporary `_files` folders removed. **This changes at roadmap item 9** — a package may not write to the working directory.

## Dependencies

DESCRIPTION is authoritative. Do not maintain a second list here.

## Marker Labels

Options, duck-typed content and sizing are documented for users in vignettes/labels.Rmd. Two facts constrain code and are easy to break: `textsize` reaches leaflet as a raw CSS font-size, so it MUST carry a unit (`label_font_size()` owns this, and a test asserts it); and labels are `rem` on `MARKER_LABEL_REM`, so they scale with a static export.

## Design Philosophy

Duck typing over filenames and IDs. `data_ids` auto-generates when NULL. OpenAir's API patterns are followed where they fit.

### API principles

1.  **User intent over implementation**: parameters say what the user wants.
2.  **Progressive disclosure**: common parameters top-level, advanced ones secondary.
3.  **Context-aware defaults**: unmodified defaults should serve 90% of uses.
4.  **Multi-value over boolean**: `marker_labels = "values_on"` beats a stack of flags.
5.  **Parameters live where they belong** (user-approved 2026-07-06): layer properties on the layer, map properties on `quickmap()`. No per-layer parallel-vector arguments at map level.

### Code minimalism

**Avoid**: `cat()` in scripts, redundant validation, obvious comments, try-catch around operations that should fail, single-use wrappers, success messages. **Do**: trust R's errors, let functions fail, write self-evident code.

## Autonomous Agent Instructions

Read in full before starting. This section overrides general coding instincts and, in autonomous sessions, the Development Workflow above. The roadmap in dev/PROJECT_STATUS.md **is** the approved plan: work within it needs no plan confirmation, and commits on feature branches need no confirmation. Work outside it needs user approval. The only stops are the ones stated here: the DATA_PATH abort, human visual sign-off, and PR review. Never push to `main`.

### Final goal

A CRAN-publishable v1.0: stable public API, full roxygen, `R CMD CHECK` clean, installable with `devtools::install()`.

### Automated gate — run after every change

1.  `testthat::test_dir("tests/testthat")` — no failures. The suite has been green since v0.9.5; there is no red baseline to work around.
2.  `source("tests/test_quickmap.R")` — completes and writes an HTML map.
3.  `DATA_PATH` must resolve. If the data is absent, STOP and report; do not refactor unverified.

The other `tests/test_*.R` scripts are historical one-offs, not a gate. `tests/testthat/test-consistency.R` checks this file against the project — version sync, referenced files, cited functions, YAML configs. Run it whenever you edit CLAUDE.md.

### Human visual testing

Automated tests verify HTML structure, not appearance. The deliverable is a self-contained interactive file, so a human checks it:

- Every roadmap item produces fresh demonstration maps in `aq_maps/`: at least one annual multi-year, one sub-annual, one with schools and labels. They are gitignored, so the PR must list the generating script, the output paths and what to look at.
- **Naming, mandatory for new artefacts**: `[item]_[description]_[version]` — `speed_merton-annual_v3.html`, `speed_demo-maps_v3.R`, and testthat files keep the prefix, `test-item4-quickmap-api-v1.R`. Bump the version on material revision rather than overwriting what the human inspected.
- Keep the previously signed-off outputs for comparison; copy them to a dated folder before regenerating. **There is no baseline folder today** — both were cleared on 2026-08-05/06, so the next item creates its own.
- Merging requires the human's formal approval, given at the permission prompt.
  The agent may run `gh pr merge <N>` only when the user has named that PR
  number for merging in the current conversation; the
  `.claude/hooks/confirm-merge.sh` hook then raises a prompt naming the exact
  command, and the human's answer there is the approval. Never treat earlier
  or general approval as covering a merge, and approval for one PR covers
  that one merge only. In unattended runs the prompt is a stall, which is
  correct: merging never happens unattended. PRs touching rendering, UI or
  HTML post-processing block on visual sign-off; pure internal refactors merge
  on green tests plus an unchanged smoke-test output; ambiguous cases count as
  rendering-touching.
- Never stack more than one unreviewed roadmap item.

### The atomic data unit — settled

Every layer is a `qm_layer()`: an sf object in long format, one row per marker per time step, carrying its metadata as attributes. New code produces one; nothing downstream re-infers. Survey, and why tmap's grammar and a bare data.frame were rejected: dev/260706_atomic_unit_recommendation.md.

### Input wrappers — implemented

`from_csv()` (tubes or schools), `from_rdata()`, `from_openair()`, `from_worldmet()` (wind). Each returns a `qm_layer`; `quickmap()` takes a list of them. Themes and colour scales are styling inputs, not part of the unit. A YAML-config wrapper is designed but not written.

### Wind animation — implemented

A uniform city-scale field from one worldmet station, decomposed to U/V on a 2×2 grid per display time by `build_wind_payload()`, rendered by vendored leaflet-velocity. Interactive HTML only. Sourcing, payload budget and the post-1.0 non-uniform plan: dev/260707_v2_integration_candidates.md.

### Rendering backend — decided, do not change without approval

Leaflet, with Canvas markers restyled from one embedded JSON payload ("Option D"), user-approved 2026-07-06. MapLibre/mapgl is the post-1.0 path. Benchmarks and rejected candidates: dev/item5_backend-comparison_v1.md.

### Time steps and file size

- `apply_time_step_cap()` caps at 200 steps (option `quickmap.time_step_cap`), warning and keeping the most recent. Resolution runs 15-minute to monthly; the cap ignores resolution.
- `use_lazy_rendering()` switches to the embedded-payload path above 50 steps (`quickmap.lazy_step_threshold`) or \~5 MB estimated (`quickmap.lazy_size_threshold`). Design and measurements: dev/20250118_geojson_option_d_design.md.

### Sharing constraint — file OR link

The map must be shareable in at least one mode (user decision 2026-07-06):

- **(a) self-contained file**: all JS/CSS inlined, including any new dependency such as leaflet-velocity — never CDN-loaded. Works offline as an attachment.
- **(b) shareable link**: a hosted page sent instead of the file.

Leaflet output satisfies (a), which remains the operative constraint.

### What NOT to change without flagging

- The public API may change for ease of use, but examples, docs, vignettes and tests must stay consistent within the same change.
- The YAML colour scale format — other scripts depend on it.
- The `{{placeholder}}` template pattern.

### Permissions and command style — autonomous safety

Permission config lives in `.claude/settings.json` (committed): the DATA_PATH env var, the command allowlist, deny rules guarding `main`, and three PreToolUse hooks. `protect-main.sh` turns a commit on `main` into an approval prompt; `confirm-merge.sh` turns any `gh pr merge` (allowlisted under `gh pr:*`) into a human-approval prompt naming the exact command — the formal merge approval described under "Human visual testing" above; `gatekeeper.py` denies any Bash/WebFetch call that could raise a prompt, reading the allowlist live. A denial names the offending segment — rewrite as it suggests, usually by putting the work in a script run via `Rscript`/`python3`. After changing the hook or allowlist, run `python3 .claude/hooks/test_gatekeeper.py`. Rationale: dev/260705_autonomous_permissions_plan.md.

Claude Code's parse-safety heuristics force a prompt **regardless of the allowlist**, and in an unattended run a prompt is a stall. Never write:

- **Inline env assignments** (`VAR=~/path cmd`). Use an absolute path if ever unavoidable.
- **`cd`** — use absolute paths, or `git -C /Users/iarla/Coding/quickmap`.
- **`$(...)`, backticks or shell variables** — the matcher cannot resolve them.
- **`for`/`while` loops, heredocs or output redirects** — script it instead.
- **Exec wrappers** (`find -exec`, `xargs`, `watch`); quote globs in write and delete commands.
- **Compound commands** are matched per segment; every segment must be allowlisted. Prefer the Read/Edit/Write/Grep tools over cat/sed/echo.
- **Uncommitted work on `main`** — branch first; commits there stall on the hook.

After any change to settings, the hook or these rules, a human runs dev/260705_permissions_pretest.md before the next autonomous session. Deny rules are a local guard; definitive `main` protection is a GitHub branch protection rule.

### Committing and branching

- A branch per roadmap item (`feature/atomic-unit`, `feature/wind-layer`).
- Commit frequently with descriptive messages.
- Update dev/PROJECT_STATUS.md at the end of each session.
- Archive the previous R/quickmap.R to versions/ before a significant refactor.
- Do not push to `main`; leave PRs for the human.
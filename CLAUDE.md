# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Internal consistency warning.** The project has never been fully internally consistent; full consistency across code, instructions, documentation, tests, and configs is a v1.0 goal. Stale artifacts may exist in this file and in all documentation — renamed functions, removed parameters, files that no longer exist. The code is the source of truth: verify any documented claim against the source before acting on it, and when a doc contradicts the code, fix the doc in the same change.

## Project Overview

**QuickMap** is an R package for building clean, interactive air quality maps that people can email or publish on a website with minimal programming overhead.

### Philosophy

The prime motivation is accessibility. Users bring their existing data — a basic CSV from a diffusion tube survey, an Excel export, a sophisticated RData object from a sensor network, or a live OpenAir data pull — and QuickMap turns it into a professional map, including options for time animation, without requiring deep R knowledge.

The goal for QuickMap 1.0 (which will need reform of the current API) is to defy the typical R approach of making things arcane and obscure. The API is designed with a gentle, progressive learning curve: a two-line call produces a usable map; each additional parameter unlocks more sophistication. The goal is that someone picking up QuickMap for the first time should not encounter the horror show that is the typical introduction to R.

### Scope

**v1.0 scope: air quality.** Maps show pollution data (NO2, PM2.5) overlaid with contextual layers such as school locations and borough boundaries. Output is an interactive Leaflet HTML map (self-contained, email-safe) and optionally a static JPG export. The primary users are local government officers and air quality consultants producing reports and public-facing communications.

QuickMap's distinctive capability is production-ready temporal animation of monitoring-network data with self-contained HTML/JPG output. It does not aim to compete with general-purpose mapping packages such as `mapview` or `tmap`; it is a production tool for air quality reporting and research visualisation.

**Beyond v1.0:** The architecture is designed to generalise to any time-varying, location-based data, with QuickMap acting as a spatial companion to the OpenAir package — OpenAir analyses and fetches data from UK measurement networks; QuickMap maps it.

### Current version

DESCRIPTION's `Version:` field is authoritative; dev/PROJECT_STATUS.md states it in prose. Production code is R/quickmap.R with R/qm_layer.R, R/quickmap_api.R and R/wind.R; superseded copies are in versions/. Version history is NEWS.md; the roadmap and known bugs are in dev/PROJECT_STATUS.md.

## Core Architecture

### Unified Layer Processing Pipeline

The codebase uses a single-loop architecture that processes all map layers through a unified pipeline:

```         
Data Loading → Layer Configuration → Generic Processing → Icon Generation → Map Rendering
```

1.  **Data Loading System** (`load_data_file()`)
    - Supports CSV files (diffusion tubes) and RData files (Breathe London sensors)
    - Handles coordinate transformation from British National Grid to WGS84
    - Unified error handling and validation
2.  **Layer Configuration** (`get_measurement_layers()`)
    - Configuration-driven system defining which layers to render
    - Supports temporal layers (pollution data with years) and static layers (schools)
    - Each layer type has specific preparation functions
3.  **Generic Icon System** (`create_generic_icons()`)
    - **Circles**: Diffusion tube sites (`dt_sites`)
    - **Diamonds**: Breathe London nodes (`bl_nodes`)
    - **Crosses**: Schools (`schools`)
    - Colors determined by pollution thresholds or categorical data
4.  **Single Loop Processing** (`generate_map_layers()`)
    - One loop generates both interactive HTML and static image exports
    - Eliminates code duplication between output formats
    - Processes all years and layer types systematically

### Key Design Patterns

- **Configuration Objects**: All styling, colors, and layer definitions stored in config objects
- **Generic Layer Functions**: `prepare_generic_layer_data()` → `create_generic_icons()` → `add_layer()`
- **Temporal Support**: Year-based filtering with interactive controls for time series data
- **Environment Variables**: `DATA_PATH` for data file locations

## Development Workflow

### Planning

- Plans to be stored in the dev/ folder with filename following the format YYMMDD_project_name_plan.md.

### Starting and ending execution of a new plan

**Starting**

- Ask user to confirm the plan

- check out a branch of the project for the plan

**Ending**

- Ask user to finish testing code

- Draft documentation

  - **in outline** for this document and

  - in **detail** for dev/PROJECT_STATUS.md

  - then update both documents.

- Ask user whether to commit source and documentation or not.

- Commit or no, copy versions with a new version number to versions/ subfolder.

### Running the Code

``` r
# Interactive development in R/RStudio
# (install once with devtools::install(), reinstall after editing R/quickmap.R)
library(quickmap)

# Run example scripts
source("tests/test_quickmap.R")
source("inst/examples/quickmap_create_RSP_maps.R")
```

### Creating Maps

Core API (v0.9.6+) is `quickmap()`, which takes file paths, `qm_layer()` atomic units, or data frames:

``` r
# two lines: a usable map
quickmap("wandsworth_2017_2024.csv", boroughs = "Wandsworth")

# several layers plus styling
quickmap(
  list("merton_dt_2018_2024.csv", "bl_sensors.Rdata", "schools_Merton.csv"),
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "Merton NO2",
  output_file = "merton_no2.html"
)
```

`create_pollution_map()` remains as a compatibility wrapper with its historic signature (it converts `data_sources` to `qm_layer`s and delegates to `quickmap()`):

``` r
map_object <- create_pollution_map(
  data_sources = list(
    "wandsworth_2017_2024.csv",
    "bl_imperial_annualised_2021_2025.Rdata",
    "schools_wandsworth.csv"
  ),
  data_ids = NULL,  # Optional - auto-generates from filenames
  boroughs = "Wandsworth",
  pollutant = "no2",
  display_times = NULL,  # All available time periods (year/month/day/hour)
  colour_scale = "who_no2",
  output_file = "wandsworth_no2.html",
  title = "Wandsworth NO2 Annual Mean",
  styling_type = "html",
  export_image = TRUE,  # Also creates JPG files
  marker_labels = "labels",  # Show school names and custom labels
  vignette = TRUE
)
```

### Environment Setup

Required environment variables:

``` r
Sys.setenv(DATA_PATH = "~/Coding/Library/data")
```

**Note:** DATA_PATH points to `~/Coding/Library/data` where all test data files are stored. In Claude Code sessions DATA_PATH is already provided by `.claude/settings.json` (`env`) — verify with `Sys.getenv("DATA_PATH")`; do not set it inline in bash commands (see "Permissions and command style" below).

## Data Formats

### CSV Files (Diffusion Tubes)

- **Required columns**: `Easting`, `Northing`, year columns (`2017`, `2018`, etc.)
- **Optional**: `Label` for custom site names
- **Coordinate system**: British National Grid (EPSG:27700)

### RData Files (Breathe London)

- **Duck typing**: Checks standard names (dataOAformat/data/oa_data/sensor_data), then any compatible data.frame
- **Required columns**: `siteCode`, `year`, pollutant, `lat`, `lon`
- **Format**: OpenAir-compatible long format
- **Multiple objects**: Automatically selects largest compatible data.frame

### School Data

- **Required columns**: `Easting`, `Northing`, `Level`, `School`
- **Detection**: Automatic via `School` column (duck typing)

## Configuration System

### Directory Structure

External configuration files in `inst/` directory: - **`inst/banner/`**: Banner CSS template with {{placeholder}} substitution - **`inst/legend/`**: Legend CSS template with {{placeholder}} substitution - **`inst/controls/`**: Time control HTML/CSS/JS (bottom slider, v0.9.9.5+), the wind and lazy-loading controllers, and `indicator.js` (legend indicator, v0.9.9.9+) - **`inst/config/scales/`**: YAML colour scale definitions - **`inst/themes/`**: YAML theme configuration files

### Colour Scale System

YAML-based scales in `inst/config/scales/`:

\- **WHO-based**: `who_no2.yaml`, `stripes_no2.yaml`, `gla_pm25.yaml`

\- **Borough-specific**: `lbw_no2.yaml`, `lbrut_no2.yaml`, `lbm_no2.yaml`

\- **Publication**: `lbm_aqap_no2.yaml` (LB Merton Air Quality Action Plan print set — lbm_no2's colours and thresholds unchanged, but the 20 µg/m³ target is named on both sides of the boundary and `footnote_symbols` is off)

\- **Special**: `deltas.yaml` (year-on-year change), `schools.yaml` (categorical)

Each YAML scale defines:

``` yaml
name: who_no2
title: "NO2, µg/m³"
pollutant: NO2
shape: circle
thresholds: [0, 10, 20, 40, .Inf]
colours: ["green", "yellow", "orange", "red", "white"]
labels: ["< 10: Good", "10-20: Fair", "20-40: Poor", "> 40: Bad", "Insufficient data"]
footnote_symbols: true   # optional, default true
```

**Label anatomy.** A label of the form `"range: description"` puts `range` under its ramp block and `description` in a pill coloured to match the band; a label with no colon gets no pill. `footnote_symbols: false` (v0.9.9.11+) drops the `†`/`‡`/`§` markers that otherwise cross-refer the two, leaving the band colour as the link — the pills stay. Use it where the bands are distinct and the output is print, since the markers are the first thing to become illegible.

Loading: `load_colour_scale("who_no2")` returns R list with validation

### Theme System

Reusable theme files in `inst/themes/` for consistent borough styling:

Example `merton.yaml`:

``` yaml
banner:
  background: "#5F3E94"
  text_color: "white"
  title: "Merton Air Quality"
legend:
  show: true
  background: "#DED4E9"
map:
  vignette: true
  base_tiles: null  # null = default OSM, or "CartoDB.Positron"
  zoom_level: null  # null = auto-fit
  boundary_labels: false
  marker_labels: false
  label_scale: 1            # marker-label size, 1 = the smallest legend text
  label_background: true    # translucent plate behind each marker label
controls:
  autoplay: false
  play_speed: 500
  background: "#5F3E94"
  text_color: "white"
```

Usage in `create_pollution_map()`:

``` r
create_pollution_map(
  data_sources = list("data.csv"),
  boroughs = "Merton",
  theme_file = "inst/themes/merton.yaml",
  # Explicit params override theme:
  vignette = FALSE  # overrides theme's vignette: true
)
```

Functions: `get_default_theme()`, `load_theme(theme_file)` with graceful fallback

### Named Placeholder Pattern

CSS/JS templates use `{{placeholder_name}}` replaced by `gsub()`: - Better readability than sprintf positional parameters - Self-documenting template structure - No parameter counting errors - Used in: `build_banner_css()`, `build_legend_css()`, `load_time_slider_control()` - A missing `{{placeholder}}` in a template is a hard error (`apply_template_replacements()`)

## UI Enhancement System

### External Legend System

- **Mobile responsive**: Auto-collapses on screens \<480px
- **Collapsible**: Click header to toggle visibility
- **Generated from color scales**: Uses existing `colour_scales` configuration
- **Post-processing**: Modifies saved HTML files with `inject_banner_legend_controls()`; missing injection anchors are hard errors

### Banner System

- **Reference-layer key** (v0.9.9.11+): a static layer carries no value, so it gets no place on the colour ramp and its symbol would go unexplained. Where such a layer has a `Level` column, `build_banner_key()` turns its categories and the `schools.yaml` colours into a small inline-SVG key at the end of the banner ("✕ Primary ✕ Secondary"). Only categories actually present are listed. Sized in `em`, so it follows the banner and therefore scales with a static export. It is also what lets map labels drop the words "Primary School" and stay readable at print size
- **Customizable**: Text, color, positioning
- **Flexbox layout**: Banner/map/legend components
- **Mobile optimized**: Responsive font sizes and padding

### Time Slider Control (v0.9.9.5+)

- **Bottom-centre slider card**: play button, ‹ › fine-step buttons, draggable track (drag = coarse seek with crossfade suppressed, arrows = exact), current step labelled above the thumb
- **Dynamic time steps**: populated from the layer cache / lazy payload
- **Neutral chrome**: brand colour as accent only (play button, fill)
- **Speed button** (v0.9.9.10+): multiplier on the theme's `play_speed`, cycling and wrapping, default 1×, hidden below 480px. The set is chosen in R by step count (`speed_multipliers()`) and passed as `speeds` in `window.quickmapConfig`: 0.5/1/2/4 for 12 steps or fewer, the full 0.25 → 0.5 → 1 → 2 → 4 → 8 above — 8× on a seven-step map is 150ms a step, a press you pass through rather than one you want. In `time-slider.js` the interval has one source of truth (the `currentInterval` function) and one place that starts a timer (`startTimer`) — there are two timer sites (play, and resuming after the tab was hidden) and a speed reaching only one of them is correct on play and wrong after a return to the tab
- **Default pace** follows the step count (`default_play_speed()`), not a constant: 1200ms for ≤12 steps, 800ms for 13–60, 450ms above. An explicit `play_speed` argument or theme value still wins
- **Keyboard**: arrows step, Home/End jump, Space play/pause
- **Files**: `inst/controls/time-slider.html`, `.css`, `.js` (replaced the pre-v0.9.9.5 roller dropdown)

### Legend Indicator (v0.9.9.9+)

- **What it shows**: the network mean for the displayed time step, on a track with tick marks at the colour scale's thresholds and a pointer in the value's band colour, captioned "Network mean, N sites"
- **Fixed panel** (user decision 2026-07-29): only sites reporting in *every* displayed step are counted, so the figure moves with the air and not with the network. The surviving count is shown in the caption. The panel is defined over the steps actually displayed, so narrowing `display_times` can admit more sites
- **One combined figure** across all measurement layers (user decision) — on a mixed tube/sensor map this averages two measurement methods
- **Annual maps only**: `build_indicator_data()` returns NULL for sub-annual steps, because the thresholds behind it are annual-mean limits. Sub-annual target sets are backlog issue 13
- **Both rendering paths**: `inst/controls/indicator.js` registers `window.quickmapIndicatorController`, called from the `switchToTime` handler in `time-slider.js` **above** the lazy-path early return
- **Static exports**: drawn server-side for that image's step, no script; rem/viewBox units only, so it scales with the export
- **Marked on the legend's own ramp**, never on a scale of its own: the ramp gives every band equal width whatever its span (`.ramp-block { flex: 1 }`), so a separate linear scale would put the same threshold in two places. `ramp_position()` maps a value band by band; the open-ended top band resolves to its midpoint
- **The mean is a roundel**, a plain disc at its position on the ramp, with its figure floating above it. The maximum joins it as a **diamond** (`indicator.show_max`, on by default since 2026-08-05), distinguished by shape because colour already carries the concentration band. When the two would overlap the maximum and its figure lift, and the mean and its figure drop — a collision rule, not a layout: they move only to avoid each other. The browser decides by **measuring** the two labels (`getBoundingClientRect`, re-run on resize), because a percentage of the ramp is wrong on a narrow screen where labels keep their pixel width while the ramp shrinks; `QM_MARKER_CLEARANCE` is R's fallback estimate, used for static exports, which have no JavaScript
- **Mobile**: below 480px the figures lay out in a row rather than stacked (`inst/legend/mobile.css`) — vertical space is what a phone is short of, and the legend competes with the map for it
- **Two different bases, each stated**: the mean is over the fixed panel; the **maximum is the worst site actually reporting** at that step (user decision 2026-07-31), so it can jump when a site opens. The captions read "Network mean, N sites" and "Highest of N sites", and the maximum's count changes between steps
- **Position of the figures** (`indicator.placement`): `"right"` of the ramp (default) or `"under_title"`, beneath the legend's title pill. Both are real slots in `inst/legend/legend.html`, filled one at a time. Phones ignore the setting — `.legend-lead { display: contents }` dissolves the column so the wrapping row layout applies either way. The figures collapse with the legend in both placements
- **Chips** beside each figure repeat that marker's shape and colour — the visual link between the words and the ramp
- **Theme keys**: `indicator.show` (default TRUE), `indicator.label`, `indicator.show_max` (default TRUE since 2026-08-05, user decision reversing 07-31: a mean alone is read as though it described everywhere, and the worst site is what an air quality report is usually about; set it FALSE for the quieter one-figure legend)
- **Archived alternatives**, coded and retired, wakeable with instructions: the standalone track (`dev/concepts/indicator/code/260730_indicator_track-style_v1.R`) and the zero-to-value bar (`dev/concepts/indicator/code/260731_indicator_bar-style_v1.R`)
- **Files**: `build_indicator_data()` and `generate_indicator_html()` in `R/quickmap.R`, `inst/controls/indicator.js`, styles in both `inst/legend/legend-interactive.css` and `legend-image.css`

## File Structure & Outputs

### Input Files

Scripts expect data files via environment variables or absolute paths.

### Output Directory

- **`aq_maps/`**: Auto-created output directory
- **HTML files**: Interactive maps with year controls
- **JPG files**: Static exports (when `image_export = TRUE`)
- **Cleanup**: Automatically removes temporary `_files` folders

## Dependencies

DESCRIPTION is authoritative. Do not maintain a second list here.

## Marker Labels

Options, duck-typed content and sizing are documented for users in vignettes/labels.Rmd. Two facts constrain code and are easy to break: `textsize` reaches leaflet as a raw CSS font-size, so it MUST carry a unit (`label_font_size()` owns this, and a test asserts it); and labels are `rem` on MARKER_LABEL_REM so they scale with a static export.

## Design Philosophy

**Duck typing:** Data types detected by column presence (School/Label/year_str), not filenames or IDs. **Optional IDs:** `data_ids` auto-generates from filenames when NULL. **OpenAir consistency:** Follows OpenAir API patterns.

### API Principles

1.  **User intent over implementation**: parameters describe what the user wants, not how it is done.
2.  **Progressive disclosure**: common parameters are top-level; advanced or obscure ones are secondary.
3.  **Context-aware defaults**: defaults should work unmodified for 90% of use cases.
4.  **Multi-value over boolean**: prefer categorical state parameters (e.g. `marker_labels = "values_on"`) over stacks of boolean flags.
5.  **Parameters live where they belong** (user-approved 2026-07-06): properties of a *layer* (value/time/label columns, symbol shape, name) are set on the layer via `qm_layer()`/`from_*()` wrappers; properties of the *map* (boroughs, scale, title, theme, output) are `quickmap()` arguments. No per-layer parallel-vector arguments at the map level — to customise one layer of several, customise that layer.

### Code Minimalism

**Avoid:** cat() in scripts, redundant validation, obvious comments, try-catch around operations that should fail, single-use helpers/wrappers, success messages.

**Do:** Trust R's errors, let functions fail naturally, write self-evident code.

## Autonomous Agent Instructions

This section is for Claude agents working on the project autonomously. Read it in full before starting. It overrides general coding instincts where they conflict, and in autonomous sessions it supersedes the "Development Workflow" section above. The roadmap in dev/PROJECT_STATUS.md **is** the approved plan: work within it needs no further plan confirmation, and commits on feature branches need no confirmation. The only stops are the ones this section states explicitly (the DATA_PATH abort, the atomic-unit design approval, the rendering-backend decision approval, human visual sign-off, and PR review — never push to `main`). Work outside the roadmap requires user approval first. In interactive sessions, the Development Workflow section governs.

### Final goal

A CRAN-publishable R package (v1.0). The package must: - Have a clean, stable public API with full Roxygen documentation - Pass `R CMD CHECK` with no errors or warnings - Be installable via `devtools::install()` (DESCRIPTION + NAMESPACE already needed)

### Verification and human testing

**Automated gate — run after every change:**

1.  Unit tests: `testthat::test_dir("tests/testthat")` — must pass with no failures.
2.  Smoke test: `source("tests/test_quickmap.R")` — must complete without error and write an HTML map to `aq_maps/`. (The script loads the installed package via `library(quickmap)`; reinstall with `devtools::install()` after editing `R/quickmap.R`.)
3.  Prerequisite: `DATA_PATH` must point to `~/Coding/Library/data`. If the data is absent, STOP and report — do not refactor unverified.

**Known-red baseline: cleared.** As of v0.9.5 (roadmap item 1) the testthat suite is green — stale tests were fixed or deleted (`test-export.R`, `test-parameters.R`, `test-styling.R` targeted the pre-v0.9.2 API and were removed; roadmap item 2's characterization net replaces their coverage). The gate for every change is now: no failures.

The other `tests/test_*.R` scripts are historical one-off checks; do not treat them as a gate.

`tests/testthat/test-consistency.R` mechanically checks CLAUDE.md against the project (version sync, referenced files exist, cited functions defined, YAML configs present). It is dependency-free and **not** part of the known-red baseline — it must always be green. When editing CLAUDE.md, run it.

**Human visual testing — automated tests verify HTML structure (roadmap item 2), not appearance or behaviour.** The core deliverable is a self-contained interactive HTML file; its appearance and behaviour must be checked by a human at defined points:

- Every roadmap item must produce freshly generated demonstration maps in the local `aq_maps/` directory (at minimum: one annual multi-year map, one sub-annual map, one with schools and labels). Note `aq_maps/` and `*.html` are gitignored, so the maps cannot be committed: the PR description must instead list the generating script, the output file paths, and what the human should visually check.
- **Naming convention (mandatory for new artefacts):** every new test file, demo script, and demonstration output is named `[item]_[short description]_[version]` — e.g. `speed_merton-annual_v3.html` (aq_maps/), `speed_demo-maps_v3.R` (scripts/) — and testthat files keep the required `test-` prefix: `test-item4-quickmap-api-v1.R`. The short description says what the artefact shows or tests (location/data/period where that is the point, behaviour name for tests). Existing files keep their names until touched; when a script or test is materially revised, bump the version rather than overwriting the history of what the human previously inspected.
- Keep the previously signed-off outputs for before/after comparison — never leave the human with only the new set. Before regenerating, copy the last approved maps to a dated folder (e.g. `aq_maps/baseline_YYMMDD_signed_off/`) or use dated output filenames. **There is currently no baseline folder** — both were cleared on 2026-08-05/06 at the user's request, so the next roadmap item must create its own before regenerating anything.
- All merging is done by the human; the agent never merges its own PRs. The rules below define the approval bar a PR must state it has met, not permission to merge.
- PRs touching rendering, UI, or HTML post-processing (wind layer, lazy loading, legend/banner/controls) **block on human visual sign-off** before merge.
- Pure internal refactors (packaging, data plumbing) qualify for merge on green automated tests plus a visually unchanged smoke-test output.
- When the classification is ambiguous, treat the PR as rendering-touching and block on human visual sign-off.
- Never stack more than one unreviewed roadmap item — each builds on the last, so an undetected rendering regression compounds.

### The atomic data unit — settled

Every layer is a `qm_layer`: an sf object in long format, one row per marker per time step, carrying its layer metadata as attributes. New code produces one; nothing downstream re-infers. The survey behind the choice, including why tmap's grammar and a bare data.frame were rejected: dev/260706_atomic_unit_recommendation.md.

### The wrapper API — design goal

Once the atomic unit is settled, implement lightweight wrappers that convert each input format into it:

| Wrapper | Input | Notes |
|----------------------------|----------------------|----------------------|
| `from_csv(file)` | CSV file path | Diffusion tubes or schools |
| `from_rdata(file, pollutant)` | RData file path | Duck typing already implemented |
| `from_openair(data, source, pollutant)` | OpenAir tibble | `convert_openair_to_spatial()` is the basis |
| `from_worldmet(data, pollutant)` | worldmet tibble | Wind layer; see Wind section below |
| `from_yaml(file)` | YAML config path | Reads config, fetches/loads data, returns atomic unit |

`quickmap(layers, boroughs, ...)` takes a list of atomic units. `create_pollution_map()` becomes a thin wrapper that calls `from_csv`/`from_rdata` duck typing then `quickmap()`. YAML-based themes and colour scales (already implemented) remain as styling inputs to `quickmap()`, not as part of the atomic unit.

### Wind animation — implemented

Uniform city-scale field from one worldmet station, decomposed to U/V on a 2x2 grid per display time, rendered by vendored leaflet-velocity. Interactive HTML only. Sourcing, payload budget and the post-1.0 non-uniform-field plan: dev/260707_v2_integration_candidates.md and the Wind chapter of the manual.

### Rendering backend — decided, do not change without approval

Leaflet, with Canvas markers restyled from one embedded JSON payload ("Option D"), approved by the user 2026-07-06. MapLibre/mapgl is the migration path beyond v1.0. Comparison, benchmarks, feature scoring and the rejected candidates: dev/item5_backend-comparison_v1.md.

### Time steps and file size

- **Default cap**: 200 time steps. Warn if data exceeds this; subset to most recent by default.
- **Lazy loading threshold**: above \~5 MB estimated file size or 50 time steps, render markers from one embedded JSON payload restyled in JS rather than pre-building every hidden Leaflet layer. Measurements, the rejected alternatives and the original design: `dev/20250118_geojson_option_d_design.md` and `dev/item5_backend-comparison_v1.md`.
- Time resolution ranges from 15-minute to monthly. The cap applies regardless of resolution.

### Sharing constraint — file OR link (relaxed 2026-07-06)

The product must be easily shareable in at least one of two modes (user decision, 2026-07-06; previously "self-contained file" was the sole hard constraint):

- **(a) Compact self-contained file**: all JS/CSS inlined (`htmlwidgets::saveWidget(selfcontained = TRUE)` for Leaflet; any new JS dependencies such as leaflet-velocity or a custom lazy loader must also be inlined, not CDN-loaded); works offline as an email attachment.
- **(b) Shareable link**: the map can be shared by emailing/WhatsApping a link (e.g. a hosted static page) without sending the file itself.

For the current Leaflet output, mode (a) remains the operative constraint and nothing changes in practice. Which mode(s) future backends must satisfy is scored per candidate in the item-5 comparison.

### What NOT to change without flagging

- The public API may change in service of ease of use, but any change must keep examples, docs, vignettes, and test files consistent within the same change
- YAML colour scale format in `inst/config/scales/` — other scripts depend on it
- The `{{placeholder}}` CSS/JS template pattern — it works and is readable

### Permissions and command style — autonomous safety

Permission config lives in `.claude/settings.json` (committed): the DATA_PATH env var, the command allowlist, deny rules protecting `main`, and two PreToolUse hooks — `protect-main.sh` turns any `git commit` on `main` into a human-approval prompt, and `gatekeeper.py` denies any Bash/WebFetch call that could raise a permission prompt (unlisted command segment, shell metacharacters, inline assignments, redirects), reading the allowlist live from settings.json. A gatekeeper denial is not an obstacle to work around: the reason names the offending segment — rewrite as it suggests (usually: put the work in a script file run via `Rscript`/`python3`). After any change to gatekeeper.py or the allowlist, run its mechanical test: `python3 .claude/hooks/test_gatekeeper.py`. Rationale and investigation: dev/260705_autonomous_permissions_plan.md.

Claude Code's permission system has parse-safety heuristics that force a manual prompt **regardless of the allowlist**; in an unattended run a prompt is a stall. Never write commands that trigger them:

- **No inline env assignments** (`VAR=~/path cmd`). DATA_PATH is already set; if an inline assignment is ever unavoidable, use an absolute path.
- **No `cd`** — use absolute paths or `git -C /Users/iarla/Coding/quickmap`.
- **No `$(...)`, backticks, or shell variables** (`f=x; cmd "$f"`) — the matcher cannot resolve them.
- **No `for`/`while` loops, heredocs, or output redirects** — for anything multi-step, write a script file and run it with `Rscript`/`python3`.
- **No exec wrappers** (`find -exec`, `xargs`, `watch`); quote globs in write/delete commands.
- **Compound commands** (`&&`, `|`, `;`) are matched segment-by-segment — every segment must be allowlisted. Prefer single-command calls, and the dedicated Read/Edit/Write/Grep tools over cat/sed/echo.
- **Branch before modifying anything** — commits on `main` stall on the hook's human prompt.

After any change to `.claude/settings.json`, the hook, or these rules, a human runs dev/260705_permissions_pretest.md interactively before the next autonomous session. Deny rules are a local guard only; definitive `main` protection is a GitHub branch protection rule (repo owner action).

### Committing and branching

- Work on a new branch per roadmap item (e.g. `feature/atomic-unit`, `feature/wind-layer`)
- Commit frequently with descriptive messages
- Update `dev/PROJECT_STATUS.md` at the end of each session
- Archive the previous `R/quickmap.R` to `versions/` before significant refactors
- Do not push to `main` — leave PRs for the human to review
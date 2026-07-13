# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Internal consistency warning.** The project has never been fully internally
consistent; full consistency across code, instructions, documentation, tests,
and configs is a v1.0 goal. Stale artifacts may exist in this file and in all
documentation — renamed functions, removed parameters, files that no longer
exist. The code is the source of truth: verify any documented claim against the
source before acting on it, and when a doc contradicts the code, fix the doc in
the same change.

## Project Overview

**QuickMap** is an R package for building clean, interactive air quality maps that
people can email or publish on a website with minimal programming overhead.

### Philosophy

The prime motivation is accessibility. Users bring their existing data — a basic CSV
from a diffusion tube survey, an Excel export, a sophisticated RData object from a
sensor network, or a live OpenAir data pull — and QuickMap turns it into a
professional map, including options for time animation, without requiring deep R knowledge.

The goal for QuickMap 1.0 (which will need reform of the current API) is to defy
the typical R approach of making things arcane and obscure. The API is designed
with a gentle, progressive learning curve: a two-line
call produces a usable map; each additional parameter unlocks more sophistication.
The goal is that someone picking up QuickMap for the first time should not encounter
the horror show that is the typical introduction to R.

### Scope

**v1.0 scope: air quality.** Maps show pollution data (NO2, PM2.5) overlaid with
contextual layers such as school locations and borough boundaries. Output is an
interactive Leaflet HTML map (self-contained, email-safe) and optionally a static
JPG export. The primary users are local government officers and air quality
consultants producing reports and public-facing communications.

QuickMap's distinctive capability is production-ready temporal animation of
monitoring-network data with self-contained HTML/JPG output. It does not aim to
compete with general-purpose mapping packages such as `mapview` or `tmap`; it is
a production tool for air quality reporting and research visualisation.

**Beyond v1.0:** The architecture is designed to generalise to any time-varying,
location-based data, with QuickMap acting as a spatial companion to the OpenAir
package — OpenAir analyses and fetches data from UK measurement networks; QuickMap
maps it.

### Current Version: 0.9.9.8

-   **Production code**: `R/quickmap.R` (stable, ~2,900 lines)
-   **Archived versions**: `versions/`
-   **Test scripts**: Multiple test scripts in `tests/` directory, testthat files

## Core Architecture

### Unified Layer Processing Pipeline

The codebase uses a single-loop architecture that processes all map layers through a unified pipeline:

```         
Data Loading → Layer Configuration → Generic Processing → Icon Generation → Map Rendering
```

1.  **Data Loading System** (`load_data_file()`)
    -   Supports CSV files (diffusion tubes) and RData files (Breathe London sensors)
    -   Handles coordinate transformation from British National Grid to WGS84
    -   Unified error handling and validation
2.  **Layer Configuration** (`get_measurement_layers()`)
    -   Configuration-driven system defining which layers to render
    -   Supports temporal layers (pollution data with years) and static layers (schools)
    -   Each layer type has specific preparation functions
3.  **Generic Icon System** (`create_generic_icons()`)
    -   **Circles**: Diffusion tube sites (`dt_sites`)
    -   **Diamonds**: Breathe London nodes (`bl_nodes`)
    -   **Crosses**: Schools (`schools`)
    -   Colors determined by pollution thresholds or categorical data
4.  **Single Loop Processing** (`generate_map_layers()`)
    -   One loop generates both interactive HTML and static image exports
    -   Eliminates code duplication between output formats
    -   Processes all years and layer types systematically

### Key Design Patterns

-   **Configuration Objects**: All styling, colors, and layer definitions stored in config objects
-   **Generic Layer Functions**: `prepare_generic_layer_data()` → `create_generic_icons()` → `add_layer()`
-   **Temporal Support**: Year-based filtering with interactive controls for time series data
-   **Environment Variables**: `DATA_PATH` for data file locations

## Development Workflow

### Planning

-   Plans to be stored in the dev/ folder with filename following the format YYMMDD_project_name_plan.md.

### Starting and ending execution of a new plan

**Starting**

-   Ask user to confirm the plan

-   check out a branch of the project for the plan

**Ending**

-   Ask user to finish testing code

-   Draft documentation

    -   **in outline** for this document and

    -   in **detail** for dev/PROJECT_STATUS.md

    -   then update both documents.

-   Ask user whether to commit source and documentation or not.

-   Commit or no, copy versions with a new version number to versions/ subfolder.

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

Core API (v0.9.6+) is `quickmap()`, which takes file paths, `qm_layer()`
atomic units, or data frames:

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

`create_pollution_map()` remains as a compatibility wrapper with its historic
signature (it converts `data_sources` to `qm_layer`s and delegates to
`quickmap()`):

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

**Note:** DATA_PATH points to `~/Coding/Library/data` where all test data files are stored.
In Claude Code sessions DATA_PATH is already provided by `.claude/settings.json`
(`env`) — verify with `Sys.getenv("DATA_PATH")`; do not set it inline in bash
commands (see "Permissions and command style" below).

## Data Formats

### CSV Files (Diffusion Tubes)

-   **Required columns**: `Easting`, `Northing`, year columns (`2017`, `2018`, etc.)
-   **Optional**: `Label` for custom site names
-   **Coordinate system**: British National Grid (EPSG:27700)

### RData Files (Breathe London)

-   **Duck typing**: Checks standard names (dataOAformat/data/oa_data/sensor_data), then any compatible data.frame
-   **Required columns**: `siteCode`, `year`, pollutant, `lat`, `lon`
-   **Format**: OpenAir-compatible long format
-   **Multiple objects**: Automatically selects largest compatible data.frame

### School Data

-   **Required columns**: `Easting`, `Northing`, `Level`, `School`
-   **Detection**: Automatic via `School` column (duck typing)

## Configuration System

### Directory Structure

External configuration files in `inst/` directory:
- **`inst/banner/`**: Banner CSS template with {{placeholder}} substitution
- **`inst/legend/`**: Legend CSS template with {{placeholder}} substitution
- **`inst/controls/`**: Time control HTML/CSS/JS (bottom slider, v0.9.9.5+)
- **`inst/config/scales/`**: YAML colour scale definitions
- **`inst/themes/`**: YAML theme configuration files

### Colour Scale System

YAML-based scales in `inst/config/scales/`:
- **WHO-based**: `who_no2.yaml`, `stripes_no2.yaml`, `gla_pm25.yaml`
- **Borough-specific**: `lbw_no2.yaml`, `lbrut_no2.yaml`, `lbm_no2.yaml`
- **Special**: `deltas.yaml` (year-on-year change), `schools.yaml` (categorical)

Each YAML scale defines:
```yaml
name: who_no2
title: "NO2, µg/m³"
pollutant: NO2
shape: circle
thresholds: [0, 10, 20, 40, .Inf]
colours: ["green", "yellow", "orange", "red", "white"]
labels: ["< 10: Good", "10-20: Fair", "20-40: Poor", "> 40: Bad", "Insufficient data"]
```

Loading: `load_colour_scale("who_no2")` returns R list with validation

### Theme System

Reusable theme files in `inst/themes/` for consistent borough styling:

Example `merton.yaml`:
```yaml
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
controls:
  autoplay: false
  play_speed: 500
  background: "#5F3E94"
  text_color: "white"
```

Usage in `create_pollution_map()`:
```r
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

CSS/JS templates use `{{placeholder_name}}` replaced by `gsub()`:
- Better readability than sprintf positional parameters
- Self-documenting template structure
- No parameter counting errors
- Used in: `build_banner_css()`, `build_legend_css()`, `load_time_slider_control()`
- A missing `{{placeholder}}` in a template is a hard error (`apply_template_replacements()`)

## UI Enhancement System

### External Legend System

-   **Mobile responsive**: Auto-collapses on screens \<480px
-   **Collapsible**: Click header to toggle visibility
-   **Generated from color scales**: Uses existing `colour_scales` configuration
-   **Post-processing**: Modifies saved HTML files with `inject_banner_legend_controls()`; missing injection anchors are hard errors

### Banner System

-   **Customizable**: Text, color, positioning
-   **Flexbox layout**: Banner/map/legend components
-   **Mobile optimized**: Responsive font sizes and padding

### Time Slider Control (v0.9.9.5+)

-   **Bottom-centre slider card**: play button, ‹ › fine-step buttons,
    draggable track (drag = coarse seek with crossfade suppressed,
    arrows = exact), current step labelled above the thumb
-   **Dynamic time steps**: populated from the layer cache / lazy payload
-   **Neutral chrome**: brand colour as accent only (play button, fill)
-   **Keyboard**: arrows step, Home/End jump, Space play/pause
-   **Files**: `inst/controls/time-slider.html`, `.css`, `.js`
    (replaced the pre-v0.9.9.5 roller dropdown)

## File Structure & Outputs

### Input Files

Scripts expect data files via environment variables or absolute paths.

### Output Directory

-   **`aq_maps/`**: Auto-created output directory
-   **HTML files**: Interactive maps with year controls
-   **JPG files**: Static exports (when `image_export = TRUE`)
-   **Cleanup**: Automatically removes temporary `_files` folders

## Dependencies

Core R packages (auto-installed): - `leaflet`: Interactive mapping - `sf`: Spatial data handling - `dplyr`: Data manipulation - `leaflegend`: Custom legend controls - `webshot2`: Static image export - `htmlwidgets`: Widget saving and manipulation

## Marker Labels

**Options:** `FALSE` | `TRUE` (hover) | `"values_on"` (always) | `"labels"` (custom/hover) | `"labels_on"` (custom/always)

**Content (duck typing):** School column → school names | Label column → custom labels | pollutant → values

School data detected by School column presence. Any filename works (schools.csv, schools_wandsworth.csv, etc.).

## Design Philosophy

**Duck typing:** Data types detected by column presence (School/Label/year_str), not filenames or IDs.
**Optional IDs:** `data_ids` auto-generates from filenames when NULL.
**OpenAir consistency:** Follows OpenAir API patterns.

### API Principles

1. **User intent over implementation**: parameters describe what the user wants, not how it is done.
2. **Progressive disclosure**: common parameters are top-level; advanced or obscure ones are secondary.
3. **Context-aware defaults**: defaults should work unmodified for 90% of use cases.
4. **Multi-value over boolean**: prefer categorical state parameters (e.g. `marker_labels = "values_on"`) over stacks of boolean flags.
5. **Parameters live where they belong** (user-approved 2026-07-06): properties of a *layer* (value/time/label columns, symbol shape, name) are set on the layer via `qm_layer()`/`from_*()` wrappers; properties of the *map* (boroughs, scale, title, theme, output) are `quickmap()` arguments. No per-layer parallel-vector arguments at the map level — to customise one layer of several, customise that layer.

### Code Minimalism

**Avoid:** cat() in scripts, redundant validation, obvious comments, try-catch around operations that should fail, single-use helpers/wrappers, success messages.

**Do:** Trust R's errors, let functions fail naturally, write self-evident code.

## Version History

-   **v0.9.0**: Parameter simplification (breaking changes)
-   **v0.9.1**: Function extraction, zeallot assignment (-40% main function size)
-   **v0.9.2**: Consolidated API (data_sources replaces individual file params)
-   **v0.9.3**: OpenAir converter functions (importUKAQ, importAURN, importKCL)
-   **v0.9.3.20**: School label duck typing fix
-   **v0.9.3.21**: RData duck typing (standard names → any compatible data.frame)
-   **v0.9.4**: Sub-annual temporal resolution (month/day/hour), renamed `years` → `display_times`
-   **v0.9.5**: Proper R package installation — roxygen2 NAMESPACE/man, `devtools::install()` + `library(quickmap)` replaces `source()`; `system.file()` path resolution fixed
-   **v0.9.6**: `quickmap()` core API consuming `qm_layer` atomic units (items 3+4); `create_pollution_map()` becomes a thin compatibility wrapper; rendered output unchanged (characterization-verified)
-   **v0.9.7**: Time step cap + lazy loading (item 6, Option D): above 50 time steps (or ~5 MB estimated) temporal markers render as Canvas shapes restyled per step from one embedded JSON payload (`inst/controls/lazy-time-controller.js`); 200-step default cap with warn+subset; episode fixture 3.46 MB → 0.91 MB; below-threshold maps keep the pre-built-layers path unchanged
-   **v0.9.8**: Wind layer (item 7): `wind` parameter on `quickmap()`/`create_pollution_map()` takes a `from_worldmet()` object or date/ws/wd data frame; period-mean U/V on a 2×2 grid per display time, rendered by vendored leaflet-velocity (`R/wind.R`, `inst/controls/wind-controller.js` + `leaflet-velocity/`), advancing with the roller menu; interactive HTML only
-   **v0.9.8.1**: Layer shape wiring (item 9, partial): `qm_layer(shape=)` and the `from_*()` shape conventions (tubes circle, sensors diamond, schools cross) now reach the renderer; precedence is map-level `data_symbols` > layer shape metadata > automatic cycle; `qm_layer()` shape default is NULL (auto-assign); qm "cross" renders as the outline simple-cross symbol
-   **v0.9.9.5**: UI visual polish (item 10, user-approved design): slim "strip" banner default (`banner.style: strip|bar` theme key), thin colour-ramp legend with labels outside the colours and the footnote key as pills, neutral chrome with brand-colour accents, system font stack, `CartoDB.Positron` default tiles, bottom time-slider control with fine-step arrows/drag scrubbing/keyboard (`inst/controls/time-slider.*`, replacing the roller menu), wind-particle styling exposed through theme YAML (`wind:` section, speed-ramp default), and the static-export chrome-scaling repair (root font-size scaling)
-   **v0.9.9.6**: `boroughs` is optional (user decision 2026-07-10, reversing the 07-10 morning decision): NULL (now the default) draws no boundary, disables the vignette and fits the viewport to the data — a one-argument `quickmap("data.csv")` call works
-   **v0.9.9.7**: default base tiles reverted to OSM (user decision 2026-07-11): the vignette dimming is too faint on the pale CartoDB.Positron tiles that v0.9.9.5 made the default; Positron remains a one-line theme option (`map.base_tiles`)
-   **v0.9.9.8**: small fixes from the traced API catalogue (dev/260712_api_catalogue_v1.md): non-matching `display_times` now warns naming the available steps; `styling_type` validated against "html"/"none"; roxygen corrected (output_file used verbatim; data_symbols accepts all 18 renderer names)

Archived versions in `versions/`. Current: `R/quickmap.R`.

**Canonical version**: the list above (and the "Current Version" heading) is the
source of truth. Keep DESCRIPTION's `Version:` field in sync with it on every bump.

## Autonomous Agent Instructions

This section is for Claude agents working on the project autonomously. Read it in
full before starting. It overrides general coding instincts where they conflict,
and in autonomous sessions it supersedes the "Development Workflow" section above.
The roadmap below **is** the approved plan: work within it needs no further plan
confirmation, and commits on feature branches need no confirmation. The only stops
are the ones this section states explicitly (the DATA_PATH abort, the atomic-unit
design approval, the rendering-backend decision approval, human visual sign-off,
and PR review — never push to `main`).
Work outside the roadmap requires user approval first. In interactive sessions,
the Development Workflow section governs.

### Final goal

A CRAN-publishable R package (v1.0). The package must:
- Have a clean, stable public API with full Roxygen documentation
- Pass `R CMD CHECK` with no errors or warnings
- Be installable via `devtools::install()` (DESCRIPTION + NAMESPACE already needed)

### Known bugs — fix these first

(Former bug #1 — path resolution via `system.file()` — was fixed in v0.9.5
(roadmap item 1): quickmap is now a proper installed package loaded with
`library(quickmap)`.)

(A former bug #2 — `na.strings` passed via `...` to `import_csv_data` — was fixed in
v0.9.3.x; `import_csv_data` now sets `na.strings` internally.)

### Roadmap priorities (in order)

1. Fix the path-resolution bug above
2. Characterization test net — before any API or rendering change, write testthat
   tests that assert on the rendered HTML output of the smoke-test maps: marker
   counts per layer and time step, layer group names, embedded JSON payload
   structure, and presence of the injected banner/legend/year-control blocks.
   These assert output, not function signatures, so they survive the item-4 API
   refactor and act as the regression net for items 4 and 6. They live in
   `tests/testthat/` and join the automated gate once written
3. Formalise the atomic data unit and wrapper API (see below)
4. Refactor `create_pollution_map()` as a thin wrapper around `quickmap()` — ease of
   use takes priority over retaining the existing API; when the API changes, all
   examples, docs, vignettes, and test files must be updated in the same change.
   Plan API development with care to minimise revisions of these key files — settle
   the design before implementing rather than rewriting everything repeatedly
5. Rendering backend decision — **DONE, decision approved 2026-07-06: Option D**
   (keep Leaflet; Canvas markers + embedded JSON + minimal custom JS time
   controller). Comparison and evidence: dev/item5_backend-comparison_v1.md
   (PR #22). MapLibre/mapgl recorded as the V2 migration path; item 6 is
   unblocked and implements Option D
6. Implement time step cap and lazy loading — addresses the CRITICAL HTML
   file-size blocker recorded in dev/PROJECT_STATUS.md
7. Add wind layer support via worldmet + leaflet-velocity — its JS payload rides
   on the lazy-loading architecture, so it must follow item 6
8. Migrate and validate all examples
9. CRAN compliance (R CMD CHECK clean) + full internal-consistency audit:
   verify all documentation (CLAUDE.md, dev docs, vignettes, roxygen) against
   the stabilised code, mark dev docs current vs historical, and restructure
   dev/PROJECT_STATUS.md into a maintained current-state section plus archived
   history
10. UI polish pass (**delivers v0.9.9.5 — the last version before v1.0**) —
    modernise the visual design of the HTML output (banner, legend, controls,
    typography, spacing, colour) to the standard of modern web / infographic
    design. **Starts with an analysis of design-template options** — e.g.
    established design systems and news-graphics conventions
    (FT/Economist/BBC-style chart chrome, GOV.UK design system), lightweight
    CSS approaches compatible with self-contained output (no framework
    runtime) — ending in a recommended direction with mock-ups for **user
    approval before implementation**. Implementation lands through the
    existing `{{placeholder}}` template/theme system; themes must remain
    user-configurable. (Inserted 2026-07-06 after the item-5 React
    comparison: app-framework polish is reproducible as CSS/design effort.)
    **Includes wind-particle styling configuration** (added 2026-07-07):
    expose the constants currently hardcoded in
    `inst/controls/wind-controller.js` (particle density, line width,
    colour ramp, velocity scale) through the theme YAML system alongside
    the other visual controls.
11. Fix the outstanding UI defects listed in dev/PROJECT_STATUS.md
    (including the background CPU/memory defect added 2026-07-12: HTML
    maps must pause ALL animation work — wind particles, marker
    crossfades, autoplay — when the page, tab or embedding iframe is
    hidden or off-viewport, via visibilitychange + IntersectionObserver;
    today's maps are a CPU and memory hog in the background) (LCA visual
    fixes, static-export subfolder generation, unified marker/text/legend scaling,
    ward/marker label consistency) — so v1.0 releases without known user-facing
    defects. Do not work on these earlier or piecemeal; they are the final
    item before the v1.0 release, not background tasks.

(Items 2 and 5 were inserted 2026-07-05; item 10 (UI polish) was inserted
2026-07-06, renumbering the UI-defects item to 11. Dev docs written before
those dates use the older numbering — in particular the item-5 comparison doc
says "item 10" for what is now item 11.)

**Post-1.0: wind styling presets (optional)** (added 2026-07-09, user
decision at item 10). Item 10 ships the speed-ramp colour scale as the
wind default with the constants theme-exposed; recorded as optional future
development: a preset library (muted slate, high-contrast dark, custom
ramps), speed-scaled line width/opacity, and per-theme ramp selection —
all ride the same theme-YAML surface, no renderer work.

**Post-1.0: ecosystem integrations** (added 2026-07-07; full survey with
integration shapes, risks and suggested ordering:
dev/260707_v2_integration_candidates.md). Five well-maintained, large-user-base
suites to link into after v1.0, each landing as a `from_*()` wrapper or layer
type, never as a map-API change — in suggested pickup order: ERA5 reanalysis
wind via ecmwfr (completes the non-uniform wind thread below), saqgetr
(European AQ observations, openair-compatible), OpenAQ (global AQ platform),
the Mazama AirMonitor/AirSensor suite (US regulatory + PurpleAir), and
stars/terra raster underlays (modelled surfaces beneath measured markers).

### Verification and human testing

**Automated gate — run after every change:**

1. Unit tests: `testthat::test_dir("tests/testthat")` — must pass with no failures.
2. Smoke test: `source("tests/test_quickmap.R")` — must complete without error and
   write an HTML map to `aq_maps/`. (The script loads the installed package via
   `library(quickmap)`; reinstall with `devtools::install()` after editing
   `R/quickmap.R`.)
3. Prerequisite: `DATA_PATH` must point to `~/Coding/Library/data`. If the data is
   absent, STOP and report — do not refactor unverified.

**Known-red baseline: cleared.** As of v0.9.5 (roadmap item 1) the testthat
suite is green — stale tests were fixed or deleted (`test-export.R`,
`test-parameters.R`, `test-styling.R` targeted the pre-v0.9.2 API and were
removed; roadmap item 2's characterization net replaces their coverage). The
gate for every change is now: no failures.

The other `tests/test_*.R` scripts are historical one-off checks; do not treat them
as a gate.

`tests/testthat/test-consistency.R` mechanically checks CLAUDE.md against the
project (version sync, referenced files exist, cited functions defined, YAML
configs present). It is dependency-free and **not** part of the known-red
baseline — it must always be green. When editing CLAUDE.md, run it.

**Human visual testing — automated tests verify HTML structure (roadmap item 2),
not appearance or behaviour.** The core deliverable is a self-contained interactive
HTML file; its appearance and behaviour must be checked by a human at defined points:

- Every roadmap item must produce freshly generated demonstration maps in the local
  `aq_maps/` directory (at minimum: one annual multi-year map, one sub-annual map,
  one with schools and labels). Note `aq_maps/` and `*.html` are gitignored, so the
  maps cannot be committed: the PR description must instead list the generating
  script, the output file paths, and what the human should visually check.
- **Naming convention (mandatory for new artefacts):** every new test file, demo
  script, and demonstration output is named
  `[item]_[short description]_[version]`
  — e.g. `item4_merton-annual_v1.html` (aq_maps/), `item4_demo-maps_v1.R`
  (scripts/) — and testthat files keep the required `test-` prefix:
  `test-item4-quickmap-api-v1.R`. The short description says what the artefact
  shows or tests (location/data/period where that is the point, behaviour name
  for tests). Existing files keep their names until touched; when a script or
  test is materially revised, bump the version rather than overwriting the
  history of what the human previously inspected.
- Keep the previously signed-off outputs for before/after comparison — never leave
  the human with only the new set. Before regenerating, copy the last approved maps
  to a dated folder (e.g. `aq_maps/baseline_YYMMDD_signed_off/`) or use dated output
  filenames. The most recent baseline: `aq_maps/baseline_260705_signed_off/`.
- All merging is done by the human; the agent never merges its own PRs. The rules
  below define the approval bar a PR must state it has met, not permission to merge.
- PRs touching rendering, UI, or HTML post-processing (wind layer, lazy loading,
  legend/banner/controls) **block on human visual sign-off** before merge.
- Pure internal refactors (packaging, data plumbing) qualify for merge on green
  automated tests plus a visually unchanged smoke-test output.
- When the classification is ambiguous, treat the PR as rendering-touching and
  block on human visual sign-off.
- Never stack more than one unreviewed roadmap item — each builds on the last, so
  an undetected rendering regression compounds.

### The atomic data unit — research task before implementing

The internal currency of the current code is already close to the right thing: an `sf`
object in long format, one row per site per time step, produced by
`convert_openair_to_spatial()`. Columns: `siteCode`, `year_str`, pollutant value,
`lat`, `lon`, geometry.

**Before implementing**, survey the APIs of:
- OpenAir (`openair` package) — how it structures its layer/data arguments
- tmap v4 — how it defines its layer grammar (it changed significantly in v4)
- Find 1–2 examples of R packages that wrap Leaflet with a layered API (not ggplot2-based)

Then recommend — with justification — what the formalised atomic object should be.
This might be a named S3 class, a plain list with a required structure, or the sf
object as-is. The overriding criterion is the package philosophy: a gentle,
progressive learning curve where a two-line call works and each added parameter
unlocks more sophistication. Treat ggplot2 / Grammar of Graphics as a **last
resort**, not a forbidden model — the existing approach is more flexible and
directly supports animations, and ggplot2's `aes()` abstraction fits time-varying
spatial layers poorly, but adopt it if the survey shows it genuinely serves
incremental learning better than the alternatives.

Write the recommendation to dev/ with justification, then STOP and wait for the user
to approve the design before implementing. Implementation (on a feature branch)
begins only after explicit design approval — do not fold design and implementation
into a single PR.

### The wrapper API — design goal

Once the atomic unit is settled, implement lightweight wrappers that convert each
input format into it:

| Wrapper | Input | Notes |
|---------|-------|-------|
| `from_csv(file)` | CSV file path | Diffusion tubes or schools |
| `from_rdata(file, pollutant)` | RData file path | Duck typing already implemented |
| `from_openair(data, source, pollutant)` | OpenAir tibble | `convert_openair_to_spatial()` is the basis |
| `from_worldmet(data, pollutant)` | worldmet tibble | Wind layer; see Wind section below |
| `from_yaml(file)` | YAML config path | Reads config, fetches/loads data, returns atomic unit |

`quickmap(layers, boroughs, ...)` takes a list of atomic units. `create_pollution_map()`
becomes a thin wrapper that calls `from_csv`/`from_rdata` duck typing then `quickmap()`.
YAML-based themes and colour scales (already implemented) remain as styling inputs to
`quickmap()`, not as part of the atomic unit.

### Wind animation

**Data source**: OpenAir's `worldmet` package fetches hourly met data (wind speed,
wind direction) from NOAA's Integrated Surface Database. For most UK urban areas,
a single nearby station is representative. Convert speed + direction to U/V components
(standard meteorological decomposition) to get a uniform wind field.

**Rendering**: `leaflet-velocity` plugin renders particle flow animations on a Canvas
layer using a U/V wind grid. A uniform city-scale field is a minimal 2×2 grid — file
size is negligible. The plugin JS must be inlined (see Self-contained constraint below).

**Data pipeline at map generation time**:
1. User specifies a worldmet station code (or nearest is auto-selected)
2. `from_worldmet()` fetches and aggregates wind data to match `display_times` resolution
3. U/V components embedded as JSON in the output HTML alongside pollution layers

**Wind data does not need to match exactly** at sub-hourly resolution — hourly or daily
averages aligned to the displayed time steps are sufficient. For monthly/annual maps,
use period-mean wind.

**Post-1.0 roadmap: non-uniform wind fields and station auto-selection**
(added 2026-07-07). v1.0 ships a uniform city-scale field (one
user-specified station, 2×2 grid). The renderer already supports arbitrary
grids — the geometry-cached fast path in the vendored leaflet-velocity
computes per-step cost independent of grid resolution — so the post-1.0 work
is data sourcing and payload budget, not rendering:

- **Nearest-station auto-selection**: `from_worldmet()` with no station code
  picks the nearest ISD station to the map boundary centroid (via
  `worldmet::getMeta()`), extending naturally to nearest station**s**
  (plural) feeding a **variable grid** — multi-station interpolation onto a
  finer field. Gridded reanalysis (e.g. ERA5) via a `from_*` wrapper is the
  alternative source.
- **Payload budget**: grid cells × time steps grows the embedded JSON,
  traded against the item-6 file-size wins.

### Rendering backend decision — RESOLVED (roadmap item 5)

**Decision (user-approved 2026-07-06): Option D** — keep Leaflet; replace the
per-marker icon serialization with Canvas-rendered markers restyled from one
compact embedded JSON payload by a minimal custom JS time controller. Full
comparison, benchmarks and feature scoring: dev/item5_backend-comparison_v1.md
(brief: dev/260705_rendering_backend_candidates.md; prototypes:
dev/item5_prototypes/). Key recorded facts for later items: MapLibre/mapgl is
the V2 migration path (compact payload + controller pattern transfer);
plotly's kaleido static export is a borrowable fix if webshot2 misbehaves at
item 11 (UI defects; the comparison doc's "item 10" refers to this item under
the pre-2026-07-06 numbering); Windy API assessed and rejected for item 7
(forecast-only,
online-only, paid) — worldmet + leaflet-velocity stands. The item-5 prototype
build scripts are comparison scaffolding (some Python); the item-6
implementation is R-only plus the mandated JS controller.
Kick-off prompt for the item-6 session: dev/item6_start-prompt_v1.md.

### Time steps and file size

- **Default cap**: 200 time steps. Warn if data exceeds this; subset to most recent by default.
- **Lazy loading threshold**: if estimated file size exceeds ~5 MB or time steps exceed 50,
  render layers from embedded JSON on demand in JS rather than pre-building all hidden
  Leaflet layers. An existing design covers this ground:
  `dev/20250118_geojson_option_d_design.md` ("Option D": GeoJSON + client-side JS
  styling, ~90% size reduction). Roadmap item 5 settled this: **Option D, executed
  with Canvas markers** (see "Rendering backend decision" above); measured at
  0.44 MB on the 3.46 MB episode fixture and 0.70 MB at 500×200. The
  implementation is a minimal custom JS controller, not a large framework.
- Time resolution ranges from 15-minute to monthly. The cap applies regardless of resolution.

### Sharing constraint — file OR link (relaxed 2026-07-06)

The product must be easily shareable in at least one of two modes (user
decision, 2026-07-06; previously "self-contained file" was the sole hard
constraint):

- **(a) Compact self-contained file**: all JS/CSS inlined
  (`htmlwidgets::saveWidget(selfcontained = TRUE)` for Leaflet; any new JS
  dependencies such as leaflet-velocity or a custom lazy loader must also be
  inlined, not CDN-loaded); works offline as an email attachment.
- **(b) Shareable link**: the map can be shared by emailing/WhatsApping a
  link (e.g. a hosted static page) without sending the file itself.

For the current Leaflet output, mode (a) remains the operative constraint and
nothing changes in practice. Which mode(s) future backends must satisfy is
scored per candidate in the item-5 comparison.

### What NOT to change without flagging

- The public API may change in service of ease of use, but any change must keep
  examples, docs, vignettes, and test files consistent within the same change
- YAML colour scale format in `inst/config/scales/` — other scripts depend on it
- The `{{placeholder}}` CSS/JS template pattern — it works and is readable

### Permissions and command style — autonomous safety

Permission config lives in `.claude/settings.json` (committed): the DATA_PATH
env var, the command allowlist, deny rules protecting `main`, and two
PreToolUse hooks — `protect-main.sh` turns any `git commit` on `main` into a
human-approval prompt, and `gatekeeper.py` denies any Bash/WebFetch call that
could raise a permission prompt (unlisted command segment, shell
metacharacters, inline assignments, redirects), reading the allowlist live
from settings.json. A gatekeeper denial is not an obstacle to work around: the
reason names the offending segment — rewrite as it suggests (usually: put the
work in a script file run via `Rscript`/`python3`). After any change to
gatekeeper.py or the allowlist, run its mechanical test:
`python3 .claude/hooks/test_gatekeeper.py`.
Rationale and investigation: dev/260705_autonomous_permissions_plan.md.

Claude Code's permission system has parse-safety heuristics that force a manual
prompt **regardless of the allowlist**; in an unattended run a prompt is a
stall. Never write commands that trigger them:

- **No inline env assignments** (`VAR=~/path cmd`). DATA_PATH is already set;
  if an inline assignment is ever unavoidable, use an absolute path.
- **No `cd`** — use absolute paths or `git -C /Users/iarla/Coding/quickmap`.
- **No `$(...)`, backticks, or shell variables** (`f=x; cmd "$f"`) — the
  matcher cannot resolve them.
- **No `for`/`while` loops, heredocs, or output redirects** — for anything
  multi-step, write a script file and run it with `Rscript`/`python3`.
- **No exec wrappers** (`find -exec`, `xargs`, `watch`); quote globs in
  write/delete commands.
- **Compound commands** (`&&`, `|`, `;`) are matched segment-by-segment — every
  segment must be allowlisted. Prefer single-command calls, and the dedicated
  Read/Edit/Write/Grep tools over cat/sed/echo.
- **Branch before modifying anything** — commits on `main` stall on the hook's
  human prompt.

After any change to `.claude/settings.json`, the hook, or these rules, a human
runs dev/260705_permissions_pretest.md interactively before the next autonomous
session. Deny rules are a local guard only; definitive `main` protection is a
GitHub branch protection rule (repo owner action).

### Committing and branching

- Work on a new branch per roadmap item (e.g. `feature/atomic-unit`, `feature/wind-layer`)
- Commit frequently with descriptive messages
- Update `dev/PROJECT_STATUS.md` at the end of each session
- Archive the previous `R/quickmap.R` to `versions/` before significant refactors
- Do not push to `main` — leave PRs for the human to review

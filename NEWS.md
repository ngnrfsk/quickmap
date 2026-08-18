# quickmap

Version history. Each entry states what changed and why.
Moved from CLAUDE.md on 2026-08-16: a changelog is for users, and
CRAN and pkgdown both render this file.

- **v0.9.0**: Parameter simplification (breaking changes)

- **v0.9.1**: Function extraction, zeallot assignment (-40% main function size)

- **v0.9.2**: Consolidated API (data_sources replaces individual file params)

- **v0.9.3**: OpenAir converter functions (importUKAQ, importAURN, importKCL)

- **v0.9.3.20**: School label duck typing fix

- **v0.9.3.21**: RData duck typing (standard names → any compatible data.frame)

- **v0.9.4**: Sub-annual temporal resolution (month/day/hour), renamed `years` → `display_times`

- **v0.9.5**: Proper R package installation — roxygen2 NAMESPACE/man, `devtools::install()` + `library(quickmap)` replaces `source()`; `system.file()` path resolution fixed

- **v0.9.6**: `quickmap()` core API consuming `qm_layer` atomic units (items 3+4); `create_pollution_map()` becomes a thin compatibility wrapper; rendered output unchanged (characterization-verified)

- **v0.9.7**: Time step cap + lazy loading (item 6, Option D): above 50 time steps (or \~5 MB estimated) temporal markers render as Canvas shapes restyled per step from one embedded JSON payload (`inst/controls/lazy-time-controller.js`); 200-step default cap with warn+subset; episode fixture 3.46 MB → 0.91 MB; below-threshold maps keep the pre-built-layers path unchanged

- **v0.9.8**: Wind layer (item 7): `wind` parameter on `quickmap()`/`create_pollution_map()` takes a `from_worldmet()` object or date/ws/wd data frame; period-mean U/V on a 2×2 grid per display time, rendered by vendored leaflet-velocity (`R/wind.R`, `inst/controls/wind-controller.js` + `leaflet-velocity/`), advancing with the roller menu; interactive HTML only

- **v0.9.8.1**: Layer shape wiring (item 9, partial): `qm_layer(shape=)` and the `from_*()` shape conventions (tubes circle, sensors diamond, schools cross) now reach the renderer; precedence is map-level `data_symbols` \> layer shape metadata \> automatic cycle; `qm_layer()` shape default is NULL (auto-assign); qm "cross" renders as the outline simple-cross symbol

- **v0.9.9.5**: UI visual polish (item 10, user-approved design): slim "strip" banner default (`banner.style: strip|bar` theme key), thin colour-ramp legend with labels outside the colours and the footnote key as pills, neutral chrome with brand-colour accents, system font stack, `CartoDB.Positron` default tiles, bottom time-slider control with fine-step arrows/drag scrubbing/keyboard (`inst/controls/time-slider.*`, replacing the roller menu), wind-particle styling exposed through theme YAML (`wind:` section, speed-ramp default), and the static-export chrome-scaling repair (root font-size scaling)

- **v0.9.9.6**: `boroughs` is optional (user decision 2026-07-10, reversing the 07-10 morning decision): NULL (now the default) draws no boundary, disables the vignette and fits the viewport to the data — a one-argument `quickmap("data.csv")` call works

- **v0.9.9.7**: default base tiles reverted to OSM (user decision 2026-07-11): the vignette dimming is too faint on the pale CartoDB.Positron tiles that v0.9.9.5 made the default; Positron remains a one-line theme option (`map.base_tiles`)

- **v0.9.9.8**: small fixes from the traced API catalogue (dev/260712_api_catalogue_v1.md): non-matching `display_times` now warns naming the available steps; `styling_type` validated against "html"/"none"; roxygen corrected (output_file used verbatim; data_symbols accepts all 18 renderer names)

- **v0.9.9.9**: legend indicator (user-approved 2026-07-29, feasibility study dev/concepts/indicator/260729_overlays_feasibility.md): the network mean for the displayed step, drawn in the legend as an inline-SVG track with tick marks at the colour scale's thresholds and a pointer in the value's band colour; `build_indicator_data()` aggregates a **fixed panel** (sites reporting in every displayed step) into a single combined mean across layers, returning NULL for anything but an annual map; moves with the time slider via `window.quickmapIndicatorController` (`inst/controls/indicator.js`), hooked above the lazy-path branch so it works on both rendering paths; static exports draw their own step server-side with no script; theme keys `indicator.show` / `indicator.label`; `inst/legend/legend.html` converted from positional `sprintf` to `{{placeholder}}` substitution

- **v0.9.9.10**: animation speed control (agreed 2026-08-05, dev/concepts/animation-speed-control/260805_animation-speed-control.md, plan dev/260805_speed_control_plan.md): a multiplier button in the time-slider card cycling and wrapping, default 1×, hidden below 480px, its set chosen by step count in R (`speed_multipliers()`: 0.5/1/2/4 for ≤12 steps, the full 0.25–8× above, user decision 2026-08-05 — 8× on a seven-step map is a press you pass through rather than one you want); the default pace becomes step-count based (`default_play_speed()`: 1200ms for ≤12 steps, 800ms for 13–60, 450ms above) instead of a flat 500ms, so the four shipped themes that merely repeated the old 500ms constant now leave `play_speed` unset; the colour crossfade in `inst/controls/lazy-time-controller.js` becomes 40% of the interval capped at 250ms, sized from `window.quickmapPlayInterval` published by the slider, so it cannot outlast the step at high multipliers. Also fixes a `.gitignore` defect found on the way: `*.html` had been swallowing `inst/controls/time-slider.html`, which had therefore never been committed — a fresh clone could not build a map. Also flips `indicator.show_max` to TRUE by default (user decision 2026-08-05, reversing 07-31), so the legend shows the network maximum's diamond beside the mean's roundel unless a theme turns it off

- **v0.9.9.11**: LB Merton AQAP print set (user brief 2026-08-05, decisions taken by MCQ): `footnote_symbols: false` on a colour scale drops the `†`/`‡`/`§` cross-reference markers while keeping the pills, whose band colour is the link back to the ramp; new `lbm_aqap_no2.yaml` carrying lbm_no2's colours and thresholds unchanged but naming the 20 µg/m³ Merton target from **both** sides ("meets" on green 10-19, "above" on yellow 20-29) — naming one side only lets a band label be read as the target itself; the print-set script (v5, later v6 — moved out of the repo on 2026-08-15 to `~/Coding/260814 Merton AQAP maps and figures refresh/`) renders 2019-2025 at 4000×3000 with a solid `#2a75d4` banner bar matching the AQAP's own, schools drawn as crosses and labelled by name, and every site carrying its value. Two general fixes came with it: marker labels now **scale with the static export** instead of sitting at a flat 12px (part of the item 11 "unified marker/text/legend scaling" defect), with `map.label_scale` as the extra push a page-sized print needs; **symbol stroke width** scales with the export too (a cross is nothing but its stroke, and a flat 2px came out hairline on a 4000px print); value labels read `µg/m³` rather than the ASCII `ug/m3`, on both rendering paths; and `build_banner_key()` names a static layer's categories in the banner, which is what lets the school labels drop their type and stay readable. Marker labels are now `rem`, sitting on `MARKER_LABEL_REM` (the smallest legend text) at every export size, which is roadmap item 11's "unified marker/text/legend scaling" done early; `map.label_background` turns the plate behind them off

- **v0.9.9.12**: banner key reads the schools scale's `labels` (user request 2026-08-14): `build_banner_key()` displayed `domain` — the values matched against the data — so editing `labels` in `schools.yaml` changed nothing. It now displays `labels`, falling back to `domain` when a scale defines none, and `schools.yaml` names the categories "Primary School" / "Secondary School". Colour matching still runs on `domain`, which must equal the data's `Level` values.

- **v0.9.9.13**: the caller names every write, and `marker_labels` becomes `symbol_labels` (roadmap items 9.1 and 9.3, decision dev/260816_output_paths_decision.md). **Breaking, and deliberately without a deprecation cycle for the first:** `output_file` is now required and has no default, because CRAN policy forbids a package writing anywhere the user did not name and the invented `aq_maps/` directory was the violation. A bare name writes to the working directory; a path writes where it says; the new `output_dir` argument, or `options(quickmap.output_dir = ...)`, prepends a directory and governs the JPG set too. A directory named in either is created, nothing else is. `resolve_output_path()` owns the resolution. The unsaved-widget mode goes with it: the banner, legend, time slider and indicator are injected into the *saved file*, so a call that wrote nothing never produced a QuickMap. Two filename defects fell out with the old prefix — the per-step JPG loop called `basename()`, so any directory the caller gave was honoured for the HTML but dropped for the images, and the step went into the filename raw, so a sub-annual step such as `"2024-01-15 10:00"` put a space and two colons in a path; steps are now reduced to `[A-Za-z0-9_-]`. The rename is softer: `marker_labels` still works at `quickmap()`, `create_pollution_map()` and `render_pollution_map()` with a warning, and a theme file's `map.marker_labels` is still read, also with a warning, so existing themes keep working. Anything else passed under an unknown name is an error, so the `...` that carries the old name cannot swallow a typo. The internals and the five bundled themes use the new name throughout; the accepted values (`"values_on"`, `"labels"`, `"labels_on"`) are unchanged.

Archived versions in `versions/`. Current: `R/quickmap.R`.

**Canonical version**: DESCRIPTION's `Version:` field. Add an entry here on every bump, and keep the version dev/PROJECT_STATUS.md states in prose in sync with DESCRIPTION.

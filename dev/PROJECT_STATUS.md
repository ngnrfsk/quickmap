---
editor_options: 
  markdown: 
    wrap: 80
---

# QuickMap Project Status Summary

**Last Updated**: 2026-07-10 **Current Working Version**: v0.9.9.5 **Branch**: feature/manual-phase1-v3

--------------------------------------------------------------------------------

### Manual phase 1 v3 (PR replaces #33): pages rebuilt to P8–P15 on post-item-10 main — 2026-07-10 (PR pending)

Branch `feature/manual-phase1-v3` (off main after PR #35; the v2 branch
predated items 9/10 and `git merge` is not allowlisted, so files were
re-carried — same manoeuvre as v1→v2). Carries all phase-1 content plus:

- **Template principles P8–P15** (user-approved 2026-07-10, inferred from
  the user's sub-edit of Get started — dev/260709_page_template_review_v3.md):
  inline `#` comments on every code line, no product pitch, no
  silently-rotting statements, sections ordered by necessity (DATA_PATH
  after the first map), goal-named headings, motivate-then-show, input
  shown as a table with a minimums caption, one vocabulary ("symbols").
  P3′–P7 folded in too (P7 bundled data deferred to phase 2).
  **F1 decided: `boroughs` stays required.** F2: tiles-need-internet
  caveat stated.
- **Get started rebuilt** from the user's sub-edited text: Install →
  first map (full path, CSV shown as table) → DATA_PATH shortcut →
  reading the map → add title/filename → **§6 sophisticated animation**
  (user request: the page builds from the most basic map to the 108-step
  hourly episode with autoplay; new figure getstarted-episode.png).
- **Layers reworked** to the same principles (comments, goal headings,
  motivations, "symbols" vocabulary).
- All three screenshots regenerated with the v0.9.9.5 look
  (scripts/manual_screenshots_v2.R).

Verification: chunk harness ALL OK (12 chunks incl. the animation and the
live AURN fetch); pkgdown build clean; gate green on this branch (main's
post-item-10 tests). iCloud pack refreshed. PR #33 closed as superseded.

### Roadmap item 10 (v0.9.9.5): UI visual polish implemented — 2026-07-09 (visually SIGNED OFF 2026-07-09 after two review rounds: vignette restored in demos, episode demo on OSM tiles; PR #35 awaiting merge)

Branch `feature/item10-ui-polish` (stacked on chore/item10-ui-review, which
holds the element review, MCQ decisions and approved mock-ups). Design was
user-approved 2026-07-09 against real-data mocks
(aq_maps/item10_assembled-*.html); implementation plan
dev/260709_item10_implementation_plan_v1.md. Pre-change quickmap.R archived
as versions/quickmap_0_9_8_1.R.

**Stage 1 — CSS/theme surface:** "strip" banner default (white,
left-aligned, brand rule; `banner.style: strip|bar` theme key, both modes),
system font stack, thin colour-ramp legend (labels outside colours,
footnote key as pills; generate_legend_html rewritten), neutral chrome
(legend header white, brand tint on hover), default tiles CartoDB.Positron
(OSM via theme), wind styling exposed through theme YAML (`wind:`
colour_ramp/particle_density/line_width/velocity_scale →
wind_style_options() → payload.style; speed-ramp default;
wind-controller.js reads payload.style with fallbacks).

**Stage 2 — time slider:** inst/controls/time-slider.{html,css,js} replaces
roller-menu.* (deleted): bottom-centre card, play + ‹ › fine-step buttons,
pointer-capture drag scrubbing (passes instant=true so
lazy-time-controller.js skips its 250 ms crossfade — new optional param),
current-step label above thumb, Home/End/arrow keys, autoplay/play_speed,
tab-hidden pause, single-step mode, image-mode static label pill;
load_roller_menu_control() → load_time_slider_control() ({{placeholder}}
CSS). Same integration contract (quickmapTimeController / layer cache /
wind controller).

**Stage 3 — static export scaling repaired** (bug logged 2026-07-05):
the inert regex substitutions replaced by root font-size scaling
(`html { font-size: 16*sf px }`) — all chrome is rem-based so banner,
legend and time label scale together; legend-image.css rewritten for the
ramp (700px vs 2000px exports verified proportionate).

**Verified in Chrome** (localhost, episode map): drag scrubbing updates
markers live with the step label, play/pause animates and icon toggles,
speed-ramp wind advances with the slider, zero console errors on load or
interaction.

**Deliberate characterization changes (flagged in tests):** default tiles
addTiles→addProviderTiles (annual + item4 tests); yearList→sliderTrack
(control block test). New tests: tests/testthat/test-item10-ui-polish-v1.R
(banner styles, ramp structure incl. symbols, theme defaults, wind style
merge). Gate: **278 pass / 0 fail / 0 skip**; smoke OK; consistency green.

**Demo maps** (scripts/item10_demo-maps_v1.R): item10_final-annual_v1.html
(all defaults), item10_final-episode-wind_v1.html (108-step slider +
speed-ramp Heathrow wind, autoplay), item10_final-bar-osm_v1.html (the
XOR theme options: bar banner + OSM tiles). Static exports:
item10_stage3-export-{700,2000}_2022.jpg. Compare with approved mocks
item10_assembled-*.html and baseline_260707_item8_signed_off/.
**PR blocks on human visual sign-off** (rendering-touching).

### Item 9 partial fix (v0.9.8.1): qm_layer shape metadata wired to renderer — 2026-07-08 (visually signed off 2026-07-08; PR #32 awaiting merge)

Branch `feature/item9-layer-shapes`. Resolves the gap found during manual
phase 1 (user approved option (a), 2026-07-08): `qm_layer(shape=)` was
recorded but never consumed — shapes came only from
`get_measurement_layers()`'s auto-cycle or map-level `data_symbols`.

**What changed (R/ code; v0.9.7-era quickmap.R archived as
versions/quickmap_0_9_8.R):**

- `quickmap()` now derives per-layer symbols from `qm_meta(layer)$shape`
  when `data_symbols` is not given (qm "cross" maps to the outline
  "simple-cross" renderer symbol). Precedence: **data_symbols > layer
  shape metadata > auto-cycle**.
- `qm_layer(shape=)` default changed from "circle" to **NULL = auto** (so
  hand-built layers keep cycling unless the user chooses); explicit
  shapes validated against circle/diamond/cross. `from_csv()` static
  non-school layers now leave shape NULL (previously a misleading
  "circle" that was never used); tubes stay explicit circle, schools
  cross, `from_rdata()`/`from_openair()` diamond.
- `get_measurement_layers()` treats NA entries in data_symbols as unset
  (falls to the cycle).

**Deliberate rendering change (needs human sign-off):** default multi-layer
maps now follow the long-documented convention — tubes circles, sensor
networks **diamonds** (previously squares/rect from the cycle), schools
**simple-cross ✖** (previously simple-plus). The episode map's BL sensors
change circles → diamonds. Demo maps (scripts/item9_demo-maps_v1.R):
aq_maps/item9_merton-shapes_v1.html and item9_episode-diamonds_v1.html,
compared against baseline_260707_item8_signed_off/. Agent-side webshot
check confirms circles/diamonds/crosses render.

**Widened 2026-07-08 (same PR, user request):** `qm_layer(shape=)` accepts
the full renderer vocabulary, not just circle/diamond/cross — friendly
names (square, star, plus, cross, triangle…) normalise via
`QM_SHAPE_ALIASES`/`qm_normalise_shape()` to renderer-canonical names
(square→rect, cross→simple-cross, star→simple-star, plus→simple-plus);
any exact renderer name passes through; unknown names error with the full
list. Shapes are stored canonical, so quickmap() passes them straight
through. Demo: aq_maps/item9_custom-shapes_v1.html (star/square/triangle/
plus, webshot-verified; script bumped to scripts/item9_demo-maps_v2.R).

**Tests:** new tests/testthat/test-item9-layer-shapes-v1.R (meta shapes
honoured, data_symbols precedence, cross→simple-cross + nonsolid, NULL
default, invalid shape rejected, alias normalisation, full-vocabulary
payload). Updated expectations flagged as
deliberate: test-item6 forced-lazy shapes c("circle","rect") →
c("circle","diamond"); test-qm-layer default shape NULL + print "(auto
shape)". Gate: **250 pass / 0 fail / 0 skip**; smoke OK. Version
0.9.8.1 in DESCRIPTION + CLAUDE.md (consistency test green).

**Follow-ups:** PR #31's Layers page documents the old behaviour — update
its "Full detail" shape bullet and regenerate the multi-layer screenshot
after both PRs merge (manual phase 2 will do this if not sooner). The
remaining item-9 work (R CMD CHECK, @keywords internal sweep, full docs
audit) is untouched.

### Roadmap item 8 complete: examples migrated and validated — 2026-07-07 (accepted by user; PR #29 awaiting merge)

Branch `feature/item8-examples`. Docs/examples only — **no R/ code changed, so
the version stays at v0.9.8** (no archive to versions/ needed). Classified
**non-rendering**: the merge bar is green automated tests + visually unchanged
output, proven mechanically — the migrated canonical episode call
(`quickmap()` + `from_rdata(name = "bl_sensors")`) renders **byte-identically**
to the historic `create_pollution_map()` form (915,422 bytes, identical after
normalising the random htmlwidgets element id, which differs between any two
runs of any form).

**inst/examples/ migrated and RUN against DATA_PATH fixtures:**

- `episode_example.R` (canonical animation example) — `library(quickmap)` +
  `quickmap()`; fixture-prep block now guarded by `file.exists()` (fixtures
  exist, so runs skip it; prep borrows internal `quickmap:::get_boundary_sf`).
  map1 now uses the script's own Jan-15-20 Richmond fixture (the old call
  pointed at the differently-windowed `episodeJan2024_sf_Richmond.Rdata` —
  an inconsistency, now fixed). Commented-out wind variant added (Heathrow
  037720-99999, requireNamespace-guarded). Ran clean.
- `test_episode_example.R` (Jan 12-20 variant) — same treatment; ran clean
  (180 steps → lazy path).
- `quickmap_create_RSP_maps.R` — 6 maps migrated to `quickmap()` with plain
  file-path layers (auto names/shapes). Fixed two latent breakages: map1
  passed nonexistent parameter `theme = "airstat"` (would error — script was
  unrunnable as committed) and map4 referenced placeholder file
  `your_schools_Merton.csv`. All 6 maps ran clean ("no Label column" warnings
  are pre-existing data-driven behaviour).
- `quickmap_create_wandsworth_new_sensors.R` — migrated, ran clean.
- `missing_data_stats.R`, `prepare_bl_data_with_missing.R` — data-prep, no
  QuickMap API calls: header annotation only (noting their stale hardcoded
  paths), not migrated, not run.

**Vignettes:** `quickmap_reference.md` refreshed to v0.9.8 (wind section,
lazy-loading/200-step-cap note, stripes_pm25 + airstat_no2 scales,
output_file extension fact corrected against code, schools filename case).
`251123_theme_system_guide.md` — examples moved off the pre-v0.9.2
`diffusion_tube_file` parameter to `quickmap()`; dead references fixed.
`251126_CONFIGS.md` — the documented `inst/config/data_sources/` YAML system,
`data_configs`/`icon_shapes` parameters and `write_data_source_config()` do
not exist in the code; marked HISTORICAL with a status note, code section
rewritten to the current per-layer API, network reference material kept.
`251029_MIGRATION_EXAMPLE_v0.9.0.md` — marked HISTORICAL. CLAUDE.md: fixed
stale `source("inst/examples/create_all_borough_maps.R")` pointer
(file does not exist) → `quickmap_create_RSP_maps.R`; test-consistency green.

**New demo script** `scripts/item8_worked-examples_v1.R` (the runnable
documentation of record) → aq_maps/: `item8_wandsworth-twoline_v1.html`
(two-line call), `item8_merton-theme_v1.html` (multi-layer + merton theme),
`item8_episode-lazy_v1.html` (108-step lazy animation),
`item8_episode-wind_v1.html` (real Heathrow NOAA wind, 107/108 steps).
Signed-off item6/item7 outputs preserved in
`aq_maps/baseline_260707_item8_signed_off/` for comparison.

**Gate:** 244 pass / 0 fail / 0 skip; smoke test OK (HTML + 3 JPGs);
characterization suite untouched and green (helper deliberately keeps
pinning `create_pollution_map()`). tests/test_*.R one-off scripts left as
historical per CLAUDE.md.

### Roadmap item 7 complete (v0.9.8): wind layer — 2026-07-07 (visually signed off, PR #26 merged)

Sign-off followed one feedback round: (a) wind grid widened to ±3° (particles
cover the viewport at any zoom); (b) particle density 1/500 (user-tuned),
lineWidth 1, muted slate colour ramp; (c) smoothness — patched the vendored
(now unminified) leaflet-velocity so wind frames swap under the running
particle animation without reseeding, with a geometry cache (per-cell
lat/lng + distortion matrix recorded during the full pass) making per-step
field rebuilds ~20–30 ms instead of 358 ms, resolution-independent; and the
lazy-time-controller markers crossfade colour over 250 ms instead of
snapping. Roadmap notes added: nearest-station auto-selection + variable
grid (multi-station) post-1.0; wind-particle styling configuration folded
into item 10.

Branch `feature/item7-wind-layer`. Implements the worldmet + leaflet-velocity
plan (Windy API was assessed and rejected at item 5).

**What changed:**

- **`from_worldmet(data | station, year)`** (R/wind.R) returns a `qm_wind`
  data frame: fetches via `worldmet::importNOAA()` when given a station code,
  or accepts any data frame with `date`/`ws`/`wd`; converts to U/V by the
  standard meteorological decomposition (u = −ws·sin(wd·π/180), v = −ws·cos).
- **`wind` parameter** on `quickmap()`, `create_pollution_map()` and
  `render_pollution_map()`. `build_wind_payload()` averages U/V per displayed
  time step (format inferred from the year_str grammar via
  `wind_time_format()`) onto a uniform 2×2 grid over the padded map bbox,
  GRIB-style headers as leaflet-velocity expects (north→south scan); steps
  with no observations get null frames (overlay empties rather than showing
  stale wind); coverage messaged, zero coverage warned.
- **leaflet-velocity 2.1.4 vendored** in inst/controls/leaflet-velocity/
  (js+css+CSIRO licence) and attached as an htmlDependency, so
  `saveWidget(selfcontained = TRUE)` inlines it — sharing mode (a) holds
  (verified: no external script/css in output).
  **inst/controls/wind-controller.js** renders/updates one
  `L.velocityLayer`, publishes `window.quickmapWindController`;
  roller-menu.js calls it on every time switch alongside the item-6 marker
  controller (both lazy and legacy marker paths work with wind).
- **Interactive HTML only** — the overlay is skipped for static_only maps
  and never enters the JPG export path (a particle animation has no meaning
  in a still frame). New Imports: htmltools; Suggests: worldmet.

**Verified in Chrome:** particles render and animate over the episode map,
advance with roller menu and 500 ms autoplay, no console errors. One
transient investigated: a background-tab load can show a blank particle
canvas until the tab is foregrounded (rAF throttling — browser behaviour,
not a defect; particles seed within ~2 s once visible). Payload cost is
small: episode 913,686 → 976,747 B with 108 hourly wind frames.

**Demo maps** (scripts/item7_demo-maps_v1.R, real Heathrow 037720-99999
NOAA data): aq_maps/item7_episode-wind_v1.html (lazy path + hourly wind,
107/108 steps covered), aq_maps/item7_merton-annual-wind_v1.html (legacy
path + annual-mean wind). Also .claude job tmp item7_episode_wind.html
(synthetic wind, used for browser debugging).

**Tests:** tests/testthat/test-item7-wind-layer-v1.R (U/V decomposition,
input validation, time-format grammar, payload aggregation with null gaps
and north→south headers, full map embed: velocity dep inlined + controller
hook + self-contained). Gate: **244 pass / 0 fail / 0 skip**; smoke OK.
Characterization tests untouched (wind is additive; no baseline changed).

Also this session: `.claude/settings.json` gained `mcp__claude-in-chrome`
in permissions.allow (user request — browser tools no longer prompt);
gatekeeper tests still pass; permissions pretest due before next
unattended run. v0.9.7 archived to versions/quickmap_0_9_7.R.
**PR blocks on human visual sign-off** (rendering-touching).

### Roadmap item 6 complete (v0.9.7): time step cap + lazy loading — 2026-07-06 (visually signed off, PR #24 merged)

Branch `feature/item6-lazy-loading`. Implements the approved Option D inside
the package (R-only + the mandated JS controller; the item-5 Python builders
remain comparison scaffolding).

**What changed:**

- **Lazy rendering path** — when a map has > 50 time steps or an estimated
  pre-built size > ~5 MB (`use_lazy_rendering()`; both thresholds
  options-overridable: `quickmap.lazy_step_threshold`,
  `quickmap.lazy_size_threshold`), temporal markers are no longer pre-built
  as one hidden `addMarkers()` layer set per step. Instead
  `build_lazy_payload()` embeds one compact JSON payload
  (`{times, thresholds, colours, naColour, layers:[{id, shape, radius,
  nonsolid, labelMode, noHide, sites:[{code, lat, lon, label?, v:[…null]}]}]}`)
  attached via `htmlwidgets::onRender(load_lazy_controller_js(), data=…)` in
  `add_map_controls()`, and the new
  **inst/controls/lazy-time-controller.js** renders one Canvas marker per
  site (`ShapeMarker` subclass of `L.CircleMarker` drawing all QuickMap
  symbol shapes; markers on `L.canvas()`, polygons stay on SVG per the
  Leaflet 1.3.1 clipping bug) and restyles them per step via `setStyle`.
  Missing values remove the marker (parity with the legacy NA filter).
  Tooltips reproduce the legacy label modes (values/custom, hover/permanent).
- **Roller-menu integration** — the existing menu UI is untouched;
  `roller-menu.js` `switchToYear()` now delegates to
  `window.quickmapTimeController` when present, and the controller publishes
  a key-only `quickmapLayerCache` stub so menu initialisation (year list,
  autoplay, keyboard nav) works unchanged.
- **200-step cap** — `apply_time_step_cap()` (option
  `quickmap.time_step_cap`) warns and subsets to the most recent steps,
  applied to all paths.
- **Serialization fix** — `attr(map$x, "TOJSON_ARGS") <- list(digits = 7)`
  on lazy widgets only (htmlwidgets' default 16 digits serialized 22.8 as
  22.800000000000001; 586 KB → 389 KB payload).
- **Below-threshold maps unchanged** — the annual fixture still renders via
  the pre-built path; its characterization tests pass unmodified. Static
  JPG export always uses the legacy per-step non-interactive path, so
  webshot2 never sees JS-restyled markers (no settle-delay issue).

**Measured (episode fixture, 395 sensors × 108 hourly steps):**
3,456,970 → 913,686 bytes (−74%); widget JSON 389 KB; step switch 0.9 ms
(annual forced-lazy 2.8 ms); no console errors; tooltips/menu/autoplay
verified in Chrome. The item-5 prototype's ~0.44 MB was a bare hand-built
page; ~520 KB of the package output is the fixed leaflet/htmlwidgets/legend
stack that every quickmap HTML (even a 2-step map) carries — payload cost is
now ~0.4 MB for 43k site-steps vs ~2.5 MB before.

**Deliberate characterization change (flagged):** the episode tests now
assert 0 addMarkers/showGroup calls and pin the payload instead — 108 times,
395 sites, **40,876 non-null site-step values (exact parity with the v0.9.5
addMarkers baseline)**, threshold/colour contract; size band lowered to
0.6–1.1 MB. Annual tests untouched. New tests:
tests/testthat/test-item6-lazy-loading-v1.R (cap warn+subset, decision
thresholds, payload contract incl. NA→null and Label fallback, forced-lazy
annual: schools stay a static pre-built layer added once, dt+bl layers with
circle/rect shapes).

**Gate:** 213 pass / 0 fail / 0 skip; smoke test OK (HTML + 3 JPGs).
Demo script scripts/item6_demo-maps_v1.R → aq_maps/item6_episode-lazy_v1.html
(lazy, headline), item6_merton-annual_v1.html (legacy path, must match
baseline), item6_merton-annual-forced-lazy_v1.html (same map forced lazy for
side-by-side marker comparison). Signed-off baseline preserved untouched in
aq_maps/baseline_260705_signed_off/; episode reference:
aq_maps/item5_leaflet-episode-reference_v1.html. v0.9.6 archived to
versions/quickmap_0_9_6.R. **Human visual sign-off given and PR #24 merged
2026-07-06.** The item6_* demo outputs are the new comparison set for item 7.

### Roadmap item 5 complete: rendering backend DECIDED — Option D (user-approved) — 2026-07-06

Branch `feature/item5-backend-comparison`, PR #22. Four-way comparison per the
approved brief (dev/260705_rendering_backend_candidates.md) on identical
datasets: the pinned episode fixture (399 sensors × 108 hourly steps; Leaflet
reference reproduced byte-exact at 3,456,970 B) and a synthetic 500×200 case.
Full doc: **dev/item5_backend-comparison_v1.md**; prototypes and build scripts
in dev/item5_prototypes/ (demo HTML in local aq_maps/item5_*.html, gitignored).

Results: **Option D (Leaflet Canvas + embedded JSON) 0.44 MB / 0.70 MB,
0.5 ms/step, mode (a) pass — recommended and approved.** MapLibre 1.37/1.63 MB,
0.1 ms/step, mode (a) pass with inline raster style — recorded V2 path.
mapdeck disqualified (token-gated basemap, bugsnag telemetry, no time control
in saved widgets). plotly, redone to best practice after review
(partial_bundle + partial colour-only frames; v2 script), reaches
3.33/4.78 MB but with zero headroom and a mandatory ~53 ms full redraw per
step (verified: redraw:false silently skips mapbox repaints).

Also recorded for later items: plotly's kaleido static export is a borrowable
fix if webshot2 flakiness persists at item 10; MapLibre persistent labels need
glyph PBFs (offline cost); **Windy API rejected for item 7** (forecast-only,
online-only, paid, owns the Leaflet instance) — worldmet + leaflet-velocity
stands. Item-6 kick-off prompt: dev/item6_start-prompt_v1.md.
Testthat suite green throughout (173 pass); no package code touched.

### Roadmap item 4 complete (v0.9.6): quickmap() core API — 2026-07-06
Branch `feature/quickmap-wrapper`. New R/quickmap_api.R: `quickmap(layers,
boroughs, ...)` is the core entry point — layers may be file paths, qm_layer
objects, or data frames; pollutant inferred from the first temporal layer;
two-line call works (`quickmap("tubes.csv", boroughs = "Merton")`). The
historic `create_pollution_map()` body was renamed to internal
`render_pollution_map()` (unchanged); `create_pollution_map()` is now a thin
wrapper converting data_sources to qm_layers and delegating to `quickmap()`.
from_csv() gained a `temporal` override matching legacy data_dynamic and the
legacy >1-year-columns auto-detect plus numeric coercion. Faithfulness proof:
the full characterization suite passes unchanged, and the episode demo
generated through the new chain is byte-identical to the published map
(3,456,970 bytes). Docs updated in the same change: CLAUDE.md (Creating Maps,
version 0.9.6, history), vignettes/quickmap_reference.md, roxygen/man. New
tests: tests/testthat/test-quickmap-api-item4-v1.R (two-line call, mixed
inputs, wrapper/direct payload equivalence, pollutant inference). Gate: 173
pass / 0 fail / 0 skip; smoke OK. Demo script:
scripts/merton-richmond_dt-bl-schools_2018-2024_item4_v1.R →
aq_maps/*_item4_v1.html.

### Roadmap item 3 implementation: qm_layer atomic unit — 2026-07-06
Branch `feature/atomic-unit` (stacked on characterization tests). Implements
the user-approved rev-3 design (dev/260706_atomic_unit_recommendation.md):
new R/qm_layer.R with `qm_layer()` constructor (contract validation with
plain-English errors, alias normalisation siteCode→code / year_str→time_label
/ Latitude+Longitude→lat+lon from the QM_ALIASES constant, time-column
inference per the class→name-gate→grammar contract, time_sort POSIXct key —
decided: stored column — and value/label/shape/name/resolution metadata as
attributes), `qm_meta()`, `print.qm_layer()`, and wrappers `from_csv()`
(wide-year pivot, BNG transform, school duck typing), `from_rdata()` (wraps
the existing duck-typed loader), `from_openair()` (wraps
convert_openair_to_spatial). Render pipeline untouched — rewiring
create_pollution_map()/quickmap() around these is item 4. 29 new tests in
tests/testthat/test-qm-layer.R (synthetic + DATA_PATH fixtures incl. the
episode file: 108 hourly steps at "hour" resolution). Gate: 165 pass / 0 fail
/ 0 skip; smoke test OK.

### Item-5 brief v2 ready for approval — 2026-07-06
Branch `chore/item5-brief` (PR #18). dev/260705_rendering_backend_candidates.md
rewritten as the approvable comparison brief per user comments: sharing
constraint relaxed to file-OR-link, ten user feature criteria adopted as the
scoring checklist, plotly screened in (4th candidate), mapview/RBokeh/
Highcharter screened out with reasons. Approving PR #18 starts the comparison;
the final recommendation retains its own STOP.

### Roadmap item 2 complete: characterization test net — 2026-07-06
Branch `feature/characterization-tests` (stacked on approved feature/packaging-2).
New `tests/testthat/test-characterization.R` + `helper-characterization.R` pin
the rendered HTML of two reference maps: (a) annual Merton dt+BL+schools
2020–2022; (b) the **canonical animation example** (inst/examples/
episode_example.R map2 — hourly PM2.5, Jan 15–20 2024, all BL sensors,
Wandsworth+Richmond), which reproduces the published
parhillresearch.github.io/maps/episode.html **byte-for-byte at 3,456,970
bytes** — the slow-loading product motivating items 5/6. Pinned: payload
method counts, marker counts per layer and time step (annual: 59/1, 59/276,
61/363 dt/BL per year, 53 schools ×3; episode: 108 hourly groups, 369–385
sites/step, 40,876 site-steps), group names, injected banner/legend/
year-control/autoplay blocks, no unreplaced `{{placeholders}}`, no external
script/css loads (self-contained constraint), and the **3.2–3.7 MB file-size
baseline window** that item 6 must cut (bounds to be lowered in the same
change). Fixtures generate once per run into tempdir (suite ~41 s); tests skip
if DATA_PATH fixture files are absent. jsonlite added to Suggests. This is the
regression net for items 4 and 6.
Demo script: scripts/260706_item2_demo_maps.R → aq_maps/260706_item2_*.html.

### Roadmap item 1 complete (v0.9.5): quickmap is an installed R package — 2026-07-05
Branch `feature/packaging-2` (PR pending human review). Salvaged the uncommitted
work from the stale `feature/packaging` worktree, reviewed critically, and
ported onto current main; stale worktree and branch deleted. Changes:
DESCRIPTION 0.9.5 with corrected dependencies (yaml added; unused
stringr/htmltools/leaflet.extras dropped; openair/httr/testthat in Suggests with
requireNamespace guards); install.packages preamble removed from R/quickmap.R;
@export tags + R/quickmap-package.R; NAMESPACE and man/ regenerated with
roxygen2; LICENSE added; R/symbols_chart.R moved to scripts/; smoke test loads
`library(quickmap)`. `system.file()` now resolves, so `get_package_dir()` no
longer falls back to relative inst/ paths. Test gate made fully green
(72 pass / 0 fail / 0 skip): fixed stale assumptions in test-config /
test-css-extraction / test-themes; deleted pre-v0.9.2-API test-export /
test-parameters / test-styling (roadmap item 2's characterization net replaces
their coverage). Pre-change quickmap.R archived as versions/quickmap_0_9_4.R.

### Bug (fold into UI defect #9, roadmap item 10): image-mode CSS text scaling silently inert — 2026-07-05
The `image_mode` branch of `inject_banner_legend_controls()` passes regex-escaped
patterns (e.g. `"1\\.8rem"`) to `apply_template_replacements()`, which matches with
`fixed = TRUE` — the escaped backslash never matches, so none of the static-export
banner/legend font-scaling substitutions apply. Even unescaped, the list is
order-broken: the bare `"1rem"` pattern would consume `"padding: 1rem"` and
`"gap: 1rem"` before their own patterns run, and some patterns don't exist in the
image CSS variants at all (e.g. `1.3rem` is only in banner-interactive.css).
Static exports have been rendering at baseline text sizes regardless of image
dimensions. Repair belongs to the unified scaling work (UI defect #9, roadmap
item 10) — do not patch piecemeal. Found 2026-07-05 while adding fail-loud anchor
checks (dev/260705_risk_handlers_plan.md, handler 3.1).

### Internal-consistency strategy adopted — 2026-07-05
Full internal consistency (never yet achieved) is confirmed as a v1.0 goal.
User-approved staged strategy: (1) CLAUDE.md now carries a stale-artifact
warning — code is the source of truth, docs contradicting code get fixed in the
same change; (2) `tests/testthat/test-consistency.R` (new, dependency-free,
always-green) mechanically checks CLAUDE.md against the project — version sync,
referenced files, cited functions, YAML configs — and caught two live issues on
first run (nonexistent `scripts/` directory claim; ggplot2 `aes()` needing an
external-functions allowlist); (3) the full cross-component audit and this
file's current-vs-history restructure are folded into roadmap item 9, after the
API stabilises. Branch `chore/autonomous-permissions`.

### Autonomous permissions hardened — 2026-07-05
Branch `chore/autonomous-permissions`. The 2026-07-04 (~21:00) trial autonomous
run — the roadmap item 1 packaging agent, transcript recovered — died on
permission prompts (tilde-in-assignment heuristic, cd-compounds, loops with
command substitution; allowlist living only in settings.local.json). Added committed `.claude/settings.json` (DATA_PATH env,
72-rule allowlist, deny rules guarding main, acceptEdits) and a verified
PreToolUse hook that turns commits on main into a human-approval prompt.
CLAUDE.md gained a "Permissions and command style" section; the pre-test idea
was adopted and upgraded to dev/260705_permissions_pretest.md (human runs it
interactively before the next autonomous session). Full investigation:
dev/260705_autonomous_permissions_plan.md.

### Housekeeping: _gem docs archived, repo root cleaned — 2026-07-05
Branch `chore/risk-handlers`. CLAUDE_gem.md / PROJECT_STATUS_gem.md archived to
dev/archive/ after harvesting unique content into CLAUDE.md (positioning
statement, API principles). MapLibre experiment files moved to dev/ as evidence
for roadmap item 5 (backend decision). Root YAML duplicates of inst/ copies
deleted; root airstat_no2.yaml actually held a deltas scale — archived as
mislabelled_deltas_scale.yaml. Fail-loud checks added to HTML injection anchors
and {{placeholder}} substitution (risk handler 3.1).

### Added: quickmap_reference vignette — 2026-07-04
`vignettes/quickmap_reference.md` — plain markdown quick-reference for `create_pollution_map()`.
Covers: all parameters with defaults and descriptions, `display_times` format table, colour
scale catalogue, and full column-by-column tables for both CSV and RData input formats (traced
from source). Includes `Label` silent-drop gotcha. Committed on `feature/v093-openair-converter`.

### Bug (priority): Sourced-script path resolution — 2026-03-13
quickmap is sourced as a script so system.file() returns "" and all inst/ paths fall back to
fragile relative paths anchored to the working directory. Cascading effects: working directory
must be quickmap root; theme_file requires full paths and fails silently; colour_scale = NULL
hardcoded for static layers in add_layer. Fix: install as a proper R package via
devtools::install() — directory structure already matches conventions, DESCRIPTION and NAMESPACE
are the main additions needed.

### Bug: import_csv_data does not accept ... so na.strings from load_data_file errors — 2026-03-13
Fix: remove na.strings from load_data_file call; consolidate the two near-identical defaults
directly into import_csv_data.

### Added: geocode_uk_postcodes() — 2026-03-13
Bulk postcode geocoder added to quickmap.R. Uses postcodes.io bulk POST API (100 per request).
Falls back to terminated postcodes endpoint for retired postcodes, converting WGS84 → OSGB36
via sf. Flags terminated postcodes with a NOTE message.

### Fixed — 2026-03-13
- import_csv_data rejects static label-only CSVs: skip value columns check when static = TRUE
- create_generic_icons hardcodes two colours: load from load_yaml_config(colour_scale, subdirectory = "scales")
- na.strings ... threading error: resolved

## v0.9.3 OpenAir Converter (Current)

**Status**: Active development
**Branch**: `feature/v093-openair-converter`
**Implementation Plan**: `dev/archive/251126_Implementation_v093_OpenAir_Converter.md`

**Key Features (v0.9.3.x)**:
- OpenAir converter functions (importUKAQ, importAURN, importKCL)
- Duck typing for data loading (columns, not filenames)
- RData flexible loading (standard names → any compatible data.frame)
- Type-aware symbol defaults (solid for temporal, non-solid for static)
- Categorical color fixes for schools layer

--------------------------------------------------------------------------------

### FUTURE REFACTORING TASKS

#### Refactor-2: Database Import and Modular Architecture (Deferred)

**Category**: Architecture **Description**: Add database import using duckdb. Note: Layer generalization (v0.9.2) addresses generic layer system without full modular rewrite. **Expected Effort**: 12-16 hours **Complexity**: High

#### Minor Bugs to Fix and Features to Consider

**Category**: Code Quality **Description**: Various improvements and
optimizations - Replace tick box control with slider for many years - Add data
caching to avoid repeated data loading - Develop uniform text sizing approach
across codebase (coordinate with map size) - Remove stray temporary HTML files
on image generation (eliminate \_files folders) - Simplify and clarify all
function names for consistency - Rename parameters and restructure using
ggplot-type approach - Add animations capability - Performance and scalability
(lazy loading, batch processing) - User experience enhancements (clustering,
custom popups, export formats) - Error handling and robustness (validation,
logging, graceful failures) **Expected Effort**: 8-12 hours total

### Completed Fixes

#### RData Duck Typing (v0.9.3.21) - 2026-01-13

**Problem**: RData loading required exact object name "dataOAformat"
**Fix**: Three-strategy loader - (1) standard names (dataOAformat/data/oa_data/sensor_data), (2) any compatible data.frame (largest), (3) optional explicit data_object_name parameter
**Impact**: Works with any RData file containing compatible sensor data (siteCode, year, pollutant, lat, lon columns)
**Testing**: Comprehensive test suite in tests/test_rdata_duck_typing.R validates all strategies

#### School Label Duck Typing (v0.9.3.20) - 2026-01-13

**Problem**: School labels failed with auto-generated layer IDs (e.g., "schools_wandsworth")
**Fix**: Removed hardcoded `layer_id == "schools"` check; now detects via School column
**Impact**: Works with any filename; data_ids truly optional

#### Issue 1: Boundary Labels Control (v0.8.8)

-   Added `show_boundary_labels` parameter (TRUE/FALSE)
-   Modified `add_boundary_polygons()` for label visibility

#### Issue 2: Banner and Legend System Unification (v0.8.7)

-   Unified banner/legend system between HTML and static maps
-   Extended `apply_custom_layout_in_html()` with `image_mode` parameter

#### Issue 3: Banner and Legend Scaling (v0.8.7.1)

-   Fixed scale factor calculation using geometric mean
-   Added marker size scaling throughout layer generation

#### Issue 4: Legend Size Issues (v0.8.7.3)

-   Reduced legend marker sizes relative to map markers
-   Improved gaps and padding in legend layout

#### Issue 6: Marker Labels Control (v0.8.9)

-   Added `show_marker_labels` parameter with 5-state control
-   Unified label behavior across OA, CSV, and Schools data sources
-   Added `generate_marker_labels()` helper function
-   Breaking change: `use_data_labels` parameter removed

#### Issue 5: File Organization (2025-10-15)

-   Moved version files to `versions/` directory
-   Moved test files to `tests/` directory
-   Moved utility scripts to `scripts/` directory

#### Issue 7: Marker Labels Fix (v0.8.10)

-   Fixed schools label behavior to respect show_marker_labels parameter
-   Fixed OA data label fallback when Label column missing

#### Issue 8: Borough Colour Palettes (v0.8.11)

-   Added borough-specific colour palettes in nested named lists
-   Created show_borough_colours() helper function
-   Enables consistent borough branding across maps

#### Issue 9: Parameter Simplification (v0.9.0) - 2025-10-28

**BREAKING CHANGES** - Major parameter refactoring following OpenAir design patterns

-   **Reduced parameters**: 21 → 14 (33% reduction)
-   **Reduced code**: 2485 → 2427 lines (58 lines, 2.3% reduction)
-   **Renamed 6 parameters** for clarity (removed "show_" prefixes):
    -   `years_to_plot` → `years`
    -   `vignette_overlay_on` → `vignette`
    -   `csv_data_file` → `diffusion_tube_file`
    -   `oa_data_file` → `sensor_file`
    -   `show_marker_labels` → `marker_labels`
    -   `show_boundary_labels` → `boundary_labels`
-   **Merged 7 parameters into 3**:
    -   Image Export (3→1): `export_image = NULL` or `c(width, height)`
    -   Title (2→1): Single `title` for browser tab and banner
    -   Styling (4→1): `styling_type = "none"` or `"html"`
-   **Removed leaflet controls**: Deleted leaflet legend/title code (28+6 lines)
-   **Fixed HTML legend**: Now only appears when `styling_type = "html"`
-   **Improved API**: Parameters describe WHAT user wants, not HOW implemented
-   **Complete migration guide** in quickmap.R header (lines 39-68)
-   **All tests passing**: 4 test files with actual map outputs for verification

### Historical Completed Tasks

#### Task 1E.1: Fix Legend Text and Marker Scaling Issues (2025-10-15, v0.8.7.1, commit: aa56fc2)

-   Fixed scaling problems where legend text and marker sizes didn't scale
    appropriately
-   Improved scale factor calculation using geometric mean
-   Added layout dimension scaling for padding, gaps, and legend height
-   Implemented marker size scaling based on image dimensions
-   Added image_scale_factor parameter throughout layer generation chain
-   All elements now scale consistently with image size
-   Fixed legend symbol proportions (1.3:1 ratio)

#### Bug 0: Markers too small in static maps (COMPLETED)

-   Increased base marker sizes (schools: 8→12, dt_sites/bl_nodes: 15→20)
-   Markers now scale consistently across HTML and static exports

#### Bug 1: CSV File Path Handling (2025-10-15, v0.8.7.3)

-   Fixed CSV file path handling to be consistent with RData files
-   Added DATA_PATH environment variable support for relative CSV paths
-   Resolves inconsistency where CSV files required full paths

#### Bug 2: Missing Data Filter Integration

-   Sites with \>20% missing data display as white disks
-   Added MISSING_DATA_THRESHOLD constant (20%)
-   Implemented in process_oa_data() function
-   Requires enriched data file with missing_no2 and missing_pm25 columns

#### Bug 3: Legends too big in standard size maps (2025-10-15, v0.8.7.1)

-   Reduced legend marker sizes relative to map markers
-   Improved gaps and padding in legend layout

#### Touch-Friendly Year Menu Control (2025-11-15, v0.9.0.2)

**Implementation Details:**
-   **Architecture**: Modular control system with external files (`inst/controls/`)
    -   `roller-menu.html`: Collapsible button and year list structure
    -   `roller-menu.css`: rem-based responsive styling with color placeholders
    -   `roller-menu.js`: Dynamic year population and layer switching logic
-   **Dynamic Color System**: Added `lighten_color()` utility function
    -   Calculates lighter/darker shades from `banner_colour` parameter
    -   Menu colors: Button/border/selected use banner color + 15% lighter shade
    -   Hover effects: Very light tint (85% lighter) for subtle feedback
    -   Legend header: Tinted with banner color for cohesive theming
-   **Features**:
    -   Touch/mobile friendly with large click targets and smooth animations
    -   Years dynamically populated from `window.quickmapLayerCache`
    -   Slide-in fade animation when opening menu
    -   Selected year highlighted with accent color and white text
    -   Scrollable list when >6 years (max-height: 15rem)
    -   Click outside to close functionality
-   **Integration**: Modified `apply_custom_layout_in_html()` and `load_roller_menu_control()`
    -   Passes `banner_colour` through to control styling
    -   8-color sprintf injection for complete theming
    -   Positioned 2rem from bottom to clear Leaflet attribution

**Files Modified:**
-   `R/quickmap.R`: Added color utility, modified control loading
-   `inst/controls/roller-menu.{html,css,js}`: New control files
-   Version archived to `versions/quickmap_0_9_0_2.R`

#### Legend Refactor with Symbol Keys (2025-11-18, v0.9.0.3)

**Complete legend system refactor for improved readability:**
-   **Symbol Key System**: Traditional footnote symbols (†‡§¶*) for explanations
    -   Fixed-width colored blocks using monospace font
    -   Separate collapsible key section for descriptions
    -   Labels without descriptions (e.g., "50-60") render without symbols
-   **Label Shortening**: 30-50% reduction focusing on key regulatory thresholds
    -   "Interim" → "Int", "Under" → "<", "Over" → ">"
    -   Removed multiplier references for extreme values (5x-10x WHO)
    -   Borough-specific labels: "< LB Richmond", "< LB Wandsworth"
-   **Flexbox Alignment**: Nested containers for perfect alignment
    -   Eliminated fixed padding calculations
    -   Symbol key naturally aligns with first numeric block
    -   Works across all title lengths (NO2, PM<sub>2.5</sub>)
-   **Visual Hierarchy**: Larger text for ranges (1rem), smaller for keys (0.85rem)
-   **Mobile Responsive**: Collapsed default on ≤480px, vertical centering fix
-   **External Templates**: Modular CSS/HTML in `inst/legend/` directory

**New Functions:**
-   `parse_legend_label()`: Extracts range and description from labels
-   `get_symbol_for_index()`: Maps index to footnote symbols
-   `calculate_max_range_width()`: Determines uniform block width
-   `get_contrast_text_color()`: WCAG luminance-based text color selection

**Files Modified:**
-   `R/quickmap.R`: Added 4 utility functions, modified `generate_legend_html()`
-   `inst/legend/legend.{html,css}`: New modular template system
-   All 7 colour scales: Shortened labels across NO2 and PM2.5 scales
-   Version archived to `versions/quickmap_0_9_0_3.R`

**Detailed Documentation:** Archived

#### Unified Architecture

-   **Interactive maps**: Use HTML post-processing for banners/legends
-   **Static maps**: Use same HTML post-processing before JPG conversion
-   **Marker scaling**: Different sizes for different image dimensions
-   **Single code path**: No more duplicate legend systems

## Current State Summary

### What Works (v0.9.3.21)

-   OpenAir converter functions for UK air quality networks
-   Duck typing: data detected by columns (School, Label, year), not filenames
-   RData loading: standard names first, then any compatible data.frame
-   Simplified API: `data_sources` list replaces individual file params
-   Unified HTML banner/legend system across interactive and static maps
-   Type-aware symbols: solid shapes for temporal, non-solid for static
-   18 test scripts in `tests/` directory

## Outstanding Issues

### CRITICAL: HTML File Size Bloat (Scalability Blocker)

**Design Doc:** `dev/20250118_geojson_option_d_design.md`

**Problem:** HTML files grow to 27MB+ with many markers × time slices, causing slow load times and browser memory issues.

**Root Cause:** Leaflet's R bindings serialize icon SVGs per-marker per-call:
- 180 `addMarkers()` calls (time slices × layers)
- Icons deduplicated within call, but **repeated across calls**
- Same 11 icon SVGs × 180 calls = ~2000 redundant icon definitions
- Per-marker: ~400 bytes (embedded SVG) vs ~30 bytes (coordinates only)

**Scale Impact:**
| Markers | Time Slices | Current Size | With Fix |
|---------|-------------|--------------|----------|
| 100 | 10 | ~1 MB | ~100 KB |
| 500 | 50 | ~10 MB | ~750 KB |
| 500 | 200 | ~27 MB | ~2 MB |

**Proposed Fix (Option D):** GeoJSON + client-side JS styling
- R sends raw coordinates + values as GeoJSON (~30 bytes/marker)
- JavaScript applies icons at render time using cached SVG templates
- Estimated reduction: **90%** (27MB → 2-3MB)

**Implementation Impact:**
- Significant refactor of `create_generic_icons()` and `add_layer()`
- Estimated effort: 2-3 days
- Could implement as optional backend: `create_pollution_map(..., backend = "geojson")`

**Status:** Design complete, not implemented. Blocking for production use with sub-annual data.

--------------------------------------------------------------------------------

### Essential visual site fixes for LCA site

12. Collapsible Radio Buttons - Make radio buttons collapse and move to bottom
    left corner
13. Zoom Level on Map Open - Ensure markers fill screen with no empty borders
14. Select Start Layer - Allow users to specify which layer is visible on
    initial map load 4: Recheck the Legend Size Issues (v0.8.7.3) for different
    screen sizes

### High Priority Issues

8.  Subfolder Generation - Static image generation creates unwanted subfolders
    with leaflet JS libraries
9.  Marker/Text/Legend Size Logic - Create unified scaling system for markers,
    text, and legends
10. Ward and Marker Labeling Consistency - Make ward and marker labels
    consistent between static and interactive maps

### Medium Priority Issues

### Low Priority Issues

15. Split Import and Map Create - Separate data loading from map generation
    (version 1)
16. Automate Label Location - Automate label location, clustering, and spread
17. Prepare for R Library Packaging - Structure code and documentation for R
    library packaging

### Code Quality and Refactoring Tasks

#### Refactor-4: Configuration System Enhancement = version 0.9.1+

**Category**: Architecture **Description**: Further configuration enhancements
**Status**: Phase 1 COMPLETED in v0.9.0 (parameter simplification)
**Remaining Phases**:
-   Phase 2: Config file system (YAML/JSON) for color scales and defaults
-   Phase 3: Parameter validation system with clear error messages
-   Phase 4: OpenAir compatibility layer for seamless integration

**Completed in v0.9.0**:
-   ✓ Simplified parameter controls (21 → 14 parameters)
-   ✓ Unified legend system (removed duplicate leaflet/HTML controls)
-   ✓ Merged title parameters (single `title` for all contexts)
-   ✓ OpenAir-style parameter design (intent-based, not implementation-based)

**Expected Effort**: 4-6 hours remaining **Complexity**: Medium

#### Refactor-5: Modular Architecture = Version 0.9.x Series

**Category**: Architecture
**Description**: Split monolithic quickmap.R into focused, maintainable modules
**Goal**: By v1.0, `create_pollution_map()` becomes a thin wrapper calling modular functions

**Proposed Modules**:
- `R/data_io.R` - Data loading and transformation
- `R/data_processing.R` - Filtering and spatial operations
- `R/layer_generation.R` - Icon and layer creation
- `R/styling_rendering.R` - Map styling and controls
- `R/html_export.R` - HTML processing and export
- `R/config.R` - Configuration and color scales
- `R/utils.R` - Utilities and helpers

**Evolution Path**:
- **v0.9.1-v0.9.5**: Extract modules while maintaining single-file compatibility
- **v0.9.6-v0.9.9**: Refactor `create_pollution_map()` to call modular functions
- **v1.0**: `create_pollution_map()` as thin wrapper over clean modular architecture

**Expected Effort**: 8-12 hours **Complexity**: High

#### Refactor-6: Modern R Practices and Library Setup = Version 1.0

**Category**: Code Quality
**Description**: Modernize codebase with contemporary R development practices and prepare for CRAN submission

**Architectural Goal**: `create_pollution_map()` as user-facing wrapper function:
```r
# v1.0 architecture
create_pollution_map <- function(...) {
  # Thin wrapper that calls:
  data <- load_pollution_data(...)      # R/data_io.R
  processed <- process_spatial_data(...) # R/data_processing.R
  map <- create_base_map(...)           # R/map_creation.R
  map <- add_pollution_layers(...)      # R/layer_generation.R
  map <- apply_styling(...)             # R/styling_rendering.R
  export_map(...)                       # R/html_export.R
  return(map)
}
```

**Key Areas**:
- Tidyverse consistency
- Comprehensive error handling
- Structured logging system
- Testing infrastructure (testthat)
- Code quality tools (styler, lintr)
- Performance monitoring
- CRAN submission preparation

**Expected Effort**: 12-16 hours **Complexity**: High

#### Technical Debt: Prioritized Action List

**Analysis Date**: 2026-01-23

##### Priority 1: Quick Wins (1-2 hours, immediate value)

| Task | Location | Impact |
|------|----------|--------|
| Extract constants | Top of quickmap.R | `BASELINE_IMAGE_SIZE=1200`, `MOBILE_BREAKPOINT=480`, `DEFAULT_BANNER_COLOR="#2c3e50"` appear 5+ times each |
| Remove commented code | Lines 471-575 | Delete 104 lines of old `load_rdata_file()` implementation |
| Consolidate symbol lists | `get_measurement_layers()` + `validate_and_fix_icon_shape()` | Two separate lists of valid symbols; single source of truth needed |
| Standardize NULL pattern | Throughout | Use `%||%` operator consistently; currently 4 different patterns |

##### Priority 2: Error Handling (2-3 hours)

| Task | Current State | Target |
|------|---------------|--------|
| Consistent error style | Mix of `stop()`, `warning()+return`, `tryCatch`, silent NULL | Standardize: `stop(msg, call.=FALSE)` for fatal, `warning()` for recoverable |
| Entry-point validation | Errors caught late in pipeline | Validate data structure in `create_pollution_map()` before calling pipeline |
| Document failure modes | Silent failures possible | Each public function documents what happens on invalid input |

##### Priority 3: Parameter Threading (4-6 hours, prep for Refactor-5)

| Issue | Example | Solution |
|-------|---------|----------|
| 15-18 params through chain | `create_pollution_map → finalize_and_save_map → save_html_and_style` | Group into config objects: `styling_config`, `export_config` |
| Naming inconsistency | `export_image` vs `image_export` vs `image_mode` | Standardize: `export_*` for output params |
| Scale factor variants | `image_scale_factor`, `marker_scale_factor`, `label_sizing` | Single `scale_config` object |

##### Priority 4: Dead Code Removal (1 hour)

| Function | Status |
|----------|--------|
| `validate_oa_data()` | Defined but never called; logic in `convert_openair_to_spatial()` |
| `process_oa_data()` | Only called from commented code |
| `import_csv_data()` | Single caller; consider inlining |
| Unreachable branches | `year=="static"` check when value is `"static_only"` |

##### Priority 5: Long Functions (feeds into Refactor-5)

| Function | Lines | Issue |
|----------|-------|-------|
| `convert_openair_to_spatial()` | 187 | Split: validation, aggregation, sf conversion |
| `create_pollution_map()` | 184 | Split: setup, data loading, map generation, export |
| `load_rdata_file()` | 155 | Split: file loading, duck typing, processing |
| `inject_banner_legend_controls()` | 107 | Split: CSS scaling, HTML injection |

##### Debt Summary

| Category | Items | Est. Hours |
|----------|-------|------------|
| Quick wins | 4 | 1-2 |
| Error handling | 3 | 2-3 |
| Parameter cleanup | 3 | 4-6 |
| Dead code | 4 | 1 |
| Long functions | 4 | (Refactor-5) |
| **Total pre-refactor** | **14** | **8-12** |

--------------------------------------------------------------------------------

#### Version 1.1-1.9

**Category**: New Features - Add slider control for timeline - Add
animated/auto-start time steps for timeslices - Add animation export

### Quick Start

1.  Load latest version: `source("R/quickmap.R")` (v0.9.3.21)
2.  Test with: `source("tests/test_quickmap.R")`
3.  Review documentation: `CLAUDE.md` for system overview
4.  Check dev docs: `dev/` folder for plans and implementation details

### Development Workflow

1.  **Create branch**: Feature branches like `feature/v09X-feature-name`
2.  **Implement changes**: Follow patterns in existing code
3.  **Test thoroughly**: Use test scripts in `tests/` directory
4.  **Document changes**: Update version in `CLAUDE.md` and commit messages
5.  **Archive version**: Copy to `versions/quickmap_X_X_X.R` when stable

### Key Functions to Understand

-   `create_pollution_map()` - Main entry point
-   `apply_custom_layout_in_html()` - Banner/legend processing
-   `generate_map_layers()` - Unified layer generation
-   `create_generic_icons()` - Marker creation with scaling
-   `add_layer()` - Universal layer addition

### Testing Approach (v0.9.3)

-   Core tests: `tests/test_quickmap.R`, `tests/test_comprehensive_5network.R`
-   Converter tests: `tests/test_aurn_converter.R`, `tests/test_laqn_converter.R`
-   Duck typing tests: `tests/test_rdata_duck_typing.R`, `tests/test_school_labels_fix.R`
-   All tests create actual map outputs for visual verification

### Important Notes (v0.9.3)

-   **API**: Use `data_sources` list for all data files
-   **Duck typing**: Data types detected by columns, not filenames
-   **RData**: Loads from standard names or any compatible data.frame
-   See `CLAUDE.md` for current API examples

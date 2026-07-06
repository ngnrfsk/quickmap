# Rendering backend candidates — item-5 comparison brief (v2)

**Date:** 2026-07-05 · **v2:** 2026-07-06 — folded in user comments: sharing
constraint relaxed to file-OR-link, user feature criteria adopted as the
scoring checklist, plotly screened in, RBokeh/Highcharter/mapview screened out
with reasons.
**Status:** awaiting user approval as the item-5 comparison brief (STOP point).
CLAUDE.md's item-5 section still names the original two candidates and the
"self-contained HTML — hard constraint" section still states the strict form;
both get amended when this brief is approved.

## Purpose (user's formulation)

Plot *time-varying point data on maps*, *coloured by value/level*, and make
the result *shareable* with *professional-quality results* — interactive maps
of multidimensional data.

## Sharing constraint (v2 — relaxed)

Either of the following satisfies the requirement; candidates are scored on
whichever mode(s) they support:

- **(a) Compact self-contained file** — no client–server relationship; works
  as an email attachment offline (the current constraint).
- **(b) Shareable link** — the product can be shared by emailing/WhatsApping a
  link, without sending the file itself (e.g. a hosted static page).

The emailable self-contained file is therefore **no longer the sole hard
constraint** — but a candidate must deliver at least one of the two modes
cleanly. For mode (a), WebGL libraries sometimes fetch glyphs, sprites or
basemap styles at runtime; that silent failure is still the first thing to
test. For mode (b), the hosting workflow (what the user must do to publish,
and any cost) is part of the score.

## Feature-parity checklist (v2 — user criteria; Leaflet currently delivers all)

1. Recolour objects by time slice (current mechanism: hide/reveal a layer per
   slice — candidates may do this natively, e.g. GPU filtering).
2. Interactive time controller (or the ability to attach our own).
3. Multiple symbol types in different colours on one map, plus static layers
   overlaid on all time slices.
4. Control of tooltips/labels attached to symbols.
5. Polygon overlays/underlays with controllable transparency.
6. Basemap underlays using open-licence data suitable for public use.
7. Free or low-cost tier (free preferred).
8. Sharing mode (a) and/or (b) above.
9. Maintained and live, or part of the wider non-R ecosystem.
10. Production-standard visual results.

## Engineering criteria (from CLAUDE.md, unchanged)

- Scale target: 500 markers × 200 time steps under ~5 MB (mode (a)) with
  smooth temporal switching. Benchmark on the pinned characterization episode
  fixture (108 steps × ~380 sensors, currently 3.5 MB) plus a synthetic
  500 × 200 case.
- CRAN-readiness of any wrapper package.
- Migration cost of the banner/legend/roller-menu HTML post-processing.
- Read `versions/quickmap_0_9_5_failed_svgicon_experiment.R` first (prior
  failed size-fix attempt and why it failed).

## Candidates (four-way comparison)

### 1. Leaflet + Option D (no framework): Canvas renderer + embedded JSON

- Plain Leaflet with a Canvas marker path plus the embedded-JSON temporal
  controller — `dev/20250118_geojson_option_d_design.md` executed with Canvas
  rather than SVG/DOM markers (~90% size reduction claimed).
- Zero new dependency risk, zero post-processing migration, known
  self-contained behaviour (mode (a) proven).
- Cost: the custom JS controller is ours to write and maintain — accepted
  under any option (CLAUDE.md mandates a minimal custom controller, not a
  framework).

### 2. MapLibre GL via CRAN `mapgl`

- Native large-point-set rendering could make Option D unnecessary.
- Existing local experiment: `dev/maplibre.R`, `dev/maplibre_template.html`,
  sample input `dev/data.csv`, tarball `dev/mapgl_0.4.4.tgz`.
- Research questions: mode (a) self-contained output (unverified); mode (b)
  hosting workflow; porting cost of banner/legend/controls post-processing.

### 3. deck.gl via CRAN wrapper (`rdeck` or `mapdeck`)

- WebGL point rendering: 100k+ points trivial; 500 × 200 well within reach.
- First-class temporal filtering: `DataFilterExtension` time-scrubs on the
  GPU with zero layer rebuilding — arguably the best architectural fit for
  the core problem (feature-checklist item 1 done natively).
- Research questions: which wrapper is CRAN-current and maintained; mode (a)
  offline survival (glyph/sprite/basemap fetches); inlined bundle size;
  multi-symbol + static-overlay support (checklist item 3 — a known WebGL
  weak spot).

### 4. plotly (v2 — screened in from user list)

- Native animation frames + slider (checklist items 1–2 built in);
  self-contained htmlwidget output (mode (a)); huge, maintained ecosystem
  (item 9).
- Research questions: per-frame data duplication may *inflate* rather than
  shrink the file — measure on the episode fixture first; map-trace basemap
  licensing/offline path (scattermap/MapLibre vs Mapbox token); layered
  static overlays + mixed symbol shapes (item 3); label control granularity
  (item 4).

## Screened out (v2 — recorded so it isn't relitigated)

- **mapview** (user list): wraps the *same* Leaflet backend with no temporal
  animation — cannot change the file-size economics; it is a convenience API,
  not an alternative renderer.
- **RBokeh** (user list): fails criterion 9 — effectively unmaintained
  (dormant upstream, dropped from active CRAN maintenance).
- **Highcharter/Highmaps** (user list): fails criterion 7 for commercial use —
  Highcharts requires a paid licence for consultancy work; also chart-first
  rather than layered-map-first (weak on items 3/5).
- **React / Vue / other UI frameworks**: renderers are what's needed, not
  component state management; the UI chrome is already solved by the
  `{{placeholder}}` template system.
- **CesiumJS, kepler.gl**: far too heavy to inline for mode (a); mode (b)
  hosting of kepler.gl is a data-exploration tool, not a report product.

## Method

1. Sharing-mode test first for each candidate (cheap disqualifier per mode):
   mode (a) fully-offline open of a generated file; mode (b) minimal hosting
   workflow.
2. Benchmark: regenerate the pinned episode fixture and a synthetic 500 × 200
   dataset in each backend; record file size, load time, switching smoothness.
3. Score the feature-parity checklist (1–10) per candidate.
4. Assess post-processing migration cost and CRAN-readiness.
5. Write comparison + recommendation to `dev/`, then **STOP for user approval
   of the recommendation** before any item-6 implementation.

## Sources consulted for candidate discovery

- https://r-spatial.org/projects/ · https://cran.r-project.org/web/views/Spatial.html
- https://r-spatial.github.io/mapview/ · https://github.com/r-spatial/mapview
- https://plotly.com
- CRAN pages for mapgl, mapdeck, rdeck, leafgl

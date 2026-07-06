# Item 5 — rendering backend comparison and recommendation (v1)

**Date:** 2026-07-06 · **Revised same day:** plotly prototype re-done to best
practice after review (see "plotly v2" notes inline) — v1 had under-sold it.
**Branch:** `feature/item5-backend-comparison`
**Mandate:** dev/260705_rendering_backend_candidates.md (user-approved 2026-07-06)
**Status: recommendation APPROVED by user 2026-07-06 — Option D.** Item 6 is
unblocked; kick-off prompt: dev/item6_start-prompt_v1.md.

## What was built

Four candidates, identical datasets (per the brief): the pinned episode fixture
(399 sites × 108 hourly steps; Leaflet reference output regenerated at exactly
the characterization baseline, 3,456,970 bytes) and a synthetic 500 markers ×
200 steps stress case. Prototype scope was checklist items 1–3 plus a boundary
polygon: threshold-coloured markers, a working time slider + autoplay, a static
schools overlay in a second symbol shape, and the Wandsworth+Richmond boundary.
All artefacts are in `dev/item5_prototypes/` (build scripts + templates) and
`aq_maps/item5_*.html` (generated, gitignored — regenerate with the build
scripts listed at the end).

- **Leaflet + Option D Canvas** (`optiond/`): hand-built self-contained HTML.
  Leaflet 1.3.1 (the copy the R leaflet package ships) inlined; one
  `L.circleMarker` per site on a Canvas renderer, recoloured per step via
  `setStyle`; second Canvas shape proven by subclassing `CircleMarker`
  (`_updatePath` override drawing a square); data as one compact JSON payload
  ({times, thresholds, colours, sites:[{code,lon,lat,v:[…]}]}).
- **MapLibre GL** (`maplibre/`): maplibre-gl.js/css taken from the local
  mapgl 0.4.4 tarball and inlined; **inline style object with raster OSM
  tiles** — no style.json / glyph / sprite fetches at all; one scalar property
  per time step per feature, recoloured via `setPaintProperty` with a
  `coalesce`+`step` expression; second symbol type via a runtime
  canvas-generated icon (`map.addImage`) — no sprite needed.
- **deck.gl via CRAN mapdeck 0.3.5** (`deckgl/`): honest use of the CRAN
  wrapper — `add_scatterplot` (points, per-point hex colours) +
  `add_polygon`, saved self-contained. Single time step only: see findings.
- **plotly** (`plotly/`): v1 used the naive idiom (`plot_ly(frame = ~t)`,
  full bundle). A best-practice review found two real defects in that
  prototype, fixed in **v2** (`item5_plotly-episode_v2.R`):
  `partial_bundle()` (ship only the scattermapbox module, not the full
  3.67 MB plotly.js), and hand-built **partial frames** carrying only
  marker.color + hover text instead of duplicating lon/lat per frame.
  v2 also surfaced a plotly.js caveat verified in Chrome: `redraw: false`
  silently skips repainting mapbox/GL traces (the data updates, the canvas
  does not) — `redraw: true` is mandatory, at ~53 ms per step.

## Step 1 — sharing-mode results

Mode (a) baseline note: the current Leaflet product also fetches basemap tiles
from the network; "self-contained" has always meant *all JS/CSS inlined,
markers/controls work offline, basemap goes grey without network*. Candidates
were held to that same bar, verified by inspecting every network request in
Chrome.

| Candidate | Mode (a) | Mode (b) | Evidence |
|---|---|---|---|
| Leaflet + Option D | **Pass** | Pass (any static host) | Only `tile.openstreetmap.org` requests; all JS/CSS inline |
| MapLibre GL | **Pass** | Pass (any static host) | Only OSM tile requests — the feared style/glyph/sprite fetches are fully avoidable with an inline raster style |
| mapdeck (deck.gl) | **Fail as shipped** | Poor | No basemap at all without a Mapbox token (blank white page behind markers); widget silently POSTs telemetry to `sessions.bugsnag.com` — an undisclosed external call in a "self-contained" file |
| plotly (v2) | Pass | Pass | OSM raster style works token-free; all JS inline |

## Step 2 — benchmarks (same machine, Chrome, local HTTP serve)

| Metric | Leaflet (current) | Option D | MapLibre | mapdeck | plotly v1 (naive) | plotly v2 (best practice) |
|---|---|---|---|---|---|---|
| Episode file size | **3,456,970 B** | **439,545 B (−87%)** | 1,372,055 B (−60%) | 2,596,701 B (one step only) | 6,999,037 B | 3,325,745 B (−4%) |
| 500×200 file size | not built (≈10× episode payload) | **702,352 B** | 1,634,862 B | not built | 10,860,747 B | 4,779,557 B |
| Load → interactive, episode | **9.6 s** (256 MB heap) | 0.6 s | 0.5 s | ~1 s | 0.6 s | ~0.6 s |
| Step switch | n/a (autoplay visibly heavy) | 0.5 ms | 0.1–0.2 ms | n/a | broken with redraw:false | **53 ms** (mandatory full redraw) |
| Heap after sweep | — | 57 MB / 90 MB (500×200) | 66 MB / 92 MB | — | — | — |

Both finalists hold the 500×200 target under 5 MB with an order-of-magnitude
margin and switch steps at effectively zero cost. mapdeck cannot time-step a
saved widget at all. plotly, done properly (v2: `partial_bundle()` + partial
colour-only frames + `redraw: true`), improves from 7.0→3.33 MB on the episode
and from 10.9→**4.78 MB** at 500×200 — technically under the cap, but with no
headroom: ~2.1 MB is the trace-module bundle and the frame payload still grows
linearly, so any additional layer or longer series breaches it. Its step
switch costs ~53 ms (a full mapbox replot per frame — ~100× the finalists),
which is usable for 250 ms autoplay but visibly heavier when scrubbing.

## Step 3 — feature checklist (criteria 1–10)

✔ demonstrated in prototype · ◐ possible per current docs, not demonstrated · ✗ fails

| # | Criterion | Option D | MapLibre | mapdeck | plotly |
|---|---|---|---|---|---|
| 1 | Recolour by time slice | ✔ setStyle | ✔ paint expression | ✗ (static widget; Shiny-only updates) | ✔ frames (data duplicated per frame) |
| 2 | Time controller / attach our own | ✔ ours | ✔ ours | ✗ | ✔ built-in slider (limited styling) |
| 3 | Multi-symbol + static layers | ✔ Canvas subclass + schools layer | ✔ runtime addImage icons + symbol layer | ◐ separate layers; icon shapes need sprites | ◐ marker symbols on map traces are restricted |
| 4 | Tooltip/label control | ✔ bindTooltip (full HTML) | ✔ DOM popups (full HTML) | ◐ tooltip column only | ◐ hovertext only, no persistent labels |
| 5 | Polygon over/underlays + transparency | ✔ | ✔ fill+line opacity | ✔ | ◐ (choropleth traces / layout shapes) |
| 6 | Open-licence basemap | ✔ OSM | ✔ OSM raster; vector styles optional | ✗ Mapbox token as shipped | ✔ OSM |
| 7 | Free/low-cost | ✔ | ✔ | ◐ needs Mapbox account for basemap | ✔ |
| 8 | Sharing mode (a)/(b) | ✔ both | ✔ both | ✗/◐ | ✔ both but over cap |
| 9 | Maintained / wider ecosystem | ✔ Leaflet (stable; 1.3.1 copy is old but ours to bump) | ✔ MapLibre very active; mapgl 0.5.0 (Jun 2026), tmap now builds on it | ◐ mapdeck 0.3.6 maintained but wraps Mapbox GL v1 (2019) | ✔ huge |
| 10 | Production visual quality | ✔ matches current product | ✔ (raster OSM identical; vector styles a future upgrade) | ◐ | ◐ v2 marker rendering matches the other backends; chart-first chrome (in-plot title/slider) still reads as a chart, not a map product |

## Step 4 — migration cost and CRAN-readiness

**Option D:** zero new dependencies (leaflet is already imported); the
banner/legend/roller-menu `{{placeholder}}` injection continues to work on the
same htmlwidgets output — the change is confined to the marker path
(`create_generic_icons()`/`add_layer()` replaced by a JSON payload + ~150
lines of controller JS, which CLAUDE.md already mandates as "ours to write").
The roller menu already exists; it re-binds to the new controller. CRAN
impact: none.

**MapLibre/mapgl:** mapgl is CRAN-current (0.5.0, June 2026, active
maintainer, tmap.mapgl depends on it) — a sound dependency. But the whole
HTML post-processing layer must be ported to a different widget skeleton
(different anchors, different save pipeline), the time controller must be
rewritten against MapLibre APIs, and two rendering quirks found in this half
day (array properties silently stringified; nulls silently painted with the
error colour unless coalesced) suggest a longer tail of behavioural
differences from the current product. Real cost, real benefit only at data
volumes QuickMap does not target (10k+ points, vector styling).

**mapdeck:** wraps the discontinued Mapbox GL JS v1 line, needs a token for
any basemap, cannot time-step a saved widget, and phones home via bugsnag.
Not CRAN-risky, but architecturally wrong for this product.

**plotly:** CRAN-healthy, huge community, and — done to best practice — a
legitimate pass on the sharing test. Its migration cost is the highest of the
passing candidates though: the whole banner/legend/roller-menu system would be
rebuilt against plotly's chart chrome (its own title/slider/buttons live
inside the plot layout, competing with ours), partial frames require
`plotly_build()` surgery rather than the public R API, hover text is the only
label mechanism (no persistent marker labels), and mixed symbol shapes on map
traces are limited. The 53 ms mandatory redraw per step and the near-cap file
size at the 500×200 target leave no headroom for the wind layer (item 7) or
any growth.

## Recommendation

**Adopt Option D: keep Leaflet, implement the embedded-JSON + Canvas marker
path with our own minimal JS time controller (roadmap item 6 as designed in
dev/20250118_geojson_option_d_design.md, executed with Canvas markers).**

Justification:

1. **It meets the engineering target with the widest margin where it counts
   for this product's sharing model**: 0.44 MB for the map that today ships at
   3.46 MB, 0.70 MB at the 500×200 cap — comfortably emailable; loads in
   0.6 s versus 9.6 s today.
2. **Lowest risk by a wide margin**: no new runtime dependency, no
   post-processing migration, mode (a) already proven, rendered output can be
   pinned against the existing characterization tests.
3. The one thing MapLibre does better — per-step switching (0.1 ms vs
   0.5 ms) — is imperceptible at both test scales; both are "instant".
   MapLibre's real advantages (vector basemaps, 10k+ points) sit outside the
   v1.0 scope, and the file cost of carrying its 1 MB runtime is 2–3× the
   Option D total.
4. mapdeck fails the sharing constraint and the time-control requirement
   outright. plotly, after the best-practice rework (v2), passes the sharing
   test but sits at the 5 MB cap with zero headroom, pays a mandatory ~53 ms
   full redraw per step, and has the largest chrome-migration cost — a
   credible general-purpose tool, but the wrong economics for this product's
   specific target (compact emailable animation with our own UI chrome).

**Second place / future path:** MapLibre via mapgl is a genuinely viable
backend (both sharing modes pass; the glyph/sprite offline fear is resolved
by an inline raster style) and remains the natural V2 migration if QuickMap
later needs vector basemaps or much larger point sets. Nothing in Option D
forecloses it: the compact JSON payload and the JS controller pattern
transfer directly (the Option D design doc already noted this equivalence).

## Downstream benefits considered (added post-review, user request)

A sweep of roadmap items 6–10 and the integration angle for real advantages
the losing candidates would have delivered:

**Genuine plotly benefits.** (1) *Controls for free*: the v2 prototype has
zero custom controller JS — slider, labels and autoplay are declared in R.
Option D and MapLibre both require the ~100-line controller (which the roller
menu partially is already). Offset: plotly's controls are only styleable
within its chart-layout options, not to the themed roller-menu spec.
(2) *Native static export*: `plotly::save_image()` (kaleido) is structurally
more reliable than the webshot2 screenshot path the current export uses — if
item 10's static-export defects trace to webshot2 flakiness, kaleido is the
class of fix. **This is borrowable without adopting plotly as renderer** and
is worth remembering at item 10. (3) *Linking ecosystem* (crosstalk,
subplot, flexdashboard): a map linked to a time-series chart in one file is
a plausible post-1.0 feature plotly does natively.

**Genuine MapLibre benefits.** (1) *Unified marker scaling* (first defect on
the item-10 list): zoom-interpolated paint expressions solve marker scaling
declaratively; under Option D we own a few lines of `zoomend` handling
instead. (2) *Headroom*: vector basemaps, 10k+ points, tmap-v4 ecosystem
momentum — the recorded V2 path.

**Downstream costs found in the same sweep.** (1) plotly's mandatory ~53 ms
full redraw per step starts item 6 (lazy loading, whose point is instant
stepping) 100× behind. (2) Persistent marker labels (`marker_labels =
"labels_on"`, item 10 label-consistency work) are free DOM tooltips in
Leaflet but require glyph PBFs in MapLibre — a network fetch that breaks the
mode-(a) story the prototype preserved, or inlined font ranges at real size
cost. (3) Item 7 (below) penalises both. Net: no change to the
recommendation.

## React / app-framework comparison (added post-review, user request)

A colleague's ground-up Python+React build of a similar product prompted the
question. React is not a fifth renderer — it is a UI-state layer that still
needs one of the compared renderers underneath (react-leaflet, react-map-gl,
deck.gl). The comparison is therefore "should QuickMap's chrome be a React
app?", and the answer stays no for this product:

- **QuickMap's UI surface is tiny** — banner, legend, slider, play button
  (~200 lines of vanilla JS/CSS; the roller menu already exists). React's
  value is managing complex interacting state, which we don't have.
- **Toolchain mismatch**: React means npm/bundler/JSX in the release
  pipeline of a CRAN package maintained by R users, forever. The runtime
  bundle (~45 KB gzipped core) is affordable; the build machinery is the
  real, permanent cost.
- **Different product shape**: a Python+React build is an *application*
  (served, stateful); QuickMap's defining constraint is a standalone
  emailable artifact from a two-line R call. With a server it's mode (b)
  only, plus hosting and maintenance.
- **"Looks great" is design, not framework**: the polish in such apps is
  CSS/typography/spacing effort, all reproducible in the `{{placeholder}}`
  template system. That observation motivated the UI-polish roadmap item
  added 2026-07-06 (see CLAUDE.md).

**Where React would be right**: a post-1.0 hosted "map builder" companion
(upload CSV in a browser, get a map). The Option D JSON payload would serve
it unchanged as the data contract.

## Wind-layer note (item 7 dependency)

leaflet-velocity rides on Leaflet unchanged under Option D — another argument
against switching renderers before item 7. plotly has no wind-particle
concept at all (item 7 as specified is impossible on it); MapLibre has no
maintained free particle layer (the capable option, WeatherLayers GL, is
commercial; the rest are demos), so item 7 there means porting or writing a
particle renderer.

### Windy API assessed as an alternative wind source (user request)

The Windy **Map Forecast API** is a Leaflet-based JS library that overlays
Windy.com's animated weather layers (including wind particles) on a map.
Assessed against the roadmap's worldmet + leaflet-velocity plan:

- **Architecture conflict:** it is not a layer plugin — `windyInit()` owns
  the Leaflet map instance and pins **Leaflet 1.4.x**, so QuickMap's map,
  markers and controls would live inside Windy's map rather than the
  reverse. leaflet-velocity is the opposite: a plain overlay on our map.
- **Online-only:** layers stream from Windy's servers with an API key at
  runtime — fails sharing mode (a) outright (an emailed file shows no wind
  offline); acceptable only for mode (b) hosted pages, and adds a
  third-party availability dependency to every published map.
- **Forecast vs archive mismatch (decisive):** QuickMap animates
  *historical measured* episodes; the API serves *current/forecast* fields.
  There is no supported way to request the wind field for, e.g., Jan 15–20
  2024 at hourly steps to sync with `display_times`. worldmet (NOAA ISD
  observations) is exactly that historical record.
- **Licensing:** free tier is limited and professional/commercial use is a
  paid annual subscription; QuickMap's users are consultancies and local
  government (criterion 7: free preferred). ToS also prohibits intensive
  machine-reading of the data.
- Sources: api.windy.com/map-forecast/docs, github.com/windycom/API,
  account.windy.com/agreements (terms), api.windy.com pricing pages.

**Verdict:** unsuitable as the item-7 mechanism (wrong temporal direction,
online-only, paid, owns the map). It *is* a reasonable inspiration for what
the particle layer should look like, and its existence reinforces the Option
D choice: the one ecosystem where a free, offline, historical wind overlay
already exists (leaflet-velocity) is Leaflet. The **Point Forecast API**
(data, not maps) is likewise forecast-oriented and adds nothing over
worldmet for historical episodes.

## Regenerating the demonstration maps

1. `Rscript dev/item5_prototypes/shared/item5_prepare-data_v1.R` (datasets +
   Leaflet reference; needs DATA_PATH)
2. `Rscript dev/item5_prototypes/shared/item5_simplify-boundary_v1.R`
3. `python3 dev/item5_prototypes/optiond/item5_optiond-build_v1.py`
4. `python3 dev/item5_prototypes/maplibre/item5_maplibre-build_v1.py`
5. `Rscript dev/item5_prototypes/deckgl/item5_deckgl-episode_v1.R` (installs mapdeck)
6. `Rscript dev/item5_prototypes/plotly/item5_plotly-episode_v1.R` (naive v1,
   kept for the record)
7. `Rscript dev/item5_prototypes/plotly/item5_plotly-episode_v2.R`
   (best-practice revision — the version plotly is scored on)

Outputs in `aq_maps/`: `item5_leaflet-episode-reference_v1.html`,
`item5_optiond-{episode,synthetic}_v1.html`,
`item5_maplibre-{episode,synthetic}_v1.html`, `item5_deckgl-episode_v1.html`,
`item5_plotly-{episode,synthetic}_v1.html`,
`item5_plotly-{episode,synthetic}_v2.html`.

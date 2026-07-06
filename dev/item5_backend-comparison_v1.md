# Item 5 — rendering backend comparison and recommendation (v1)

**Date:** 2026-07-06 · **Branch:** `feature/item5-backend-comparison`
**Mandate:** dev/260705_rendering_backend_candidates.md (user-approved 2026-07-06)
**Status:** awaiting user approval of the recommendation (STOP point). Item 6
does not start until that approval.

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
- **plotly** (`plotly/`): native animation `frame=` + slider on a
  `scattermapbox` trace with the token-free `open-street-map` style.

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
| plotly | Pass | Pass | OSM raster style works token-free; all JS inline (but see size) |

## Step 2 — benchmarks (same machine, Chrome, local HTTP serve)

| Metric | Leaflet (current) | Option D | MapLibre | mapdeck | plotly |
|---|---|---|---|---|---|
| Episode file size | **3,456,970 B** | **439,545 B (−87%)** | 1,372,055 B (−60%) | 2,596,701 B (one step only) | 6,999,037 B (+102%) |
| 500×200 file size | not built (≈10× episode payload) | **702,352 B** | 1,634,862 B | not built | 10,860,747 B |
| Load → interactive, episode | **9.6 s** (256 MB heap) | 0.6 s | 0.5 s | ~1 s | 0.6 s (109 MB heap) |
| Full 108-step sweep | n/a (autoplay visibly heavy) | 55 ms (0.5 ms/step) | 19 ms (0.2 ms/step) | n/a | not measured (per-frame redraw) |
| Full 200-step sweep (500 sites) | — | 103 ms (0.5 ms/step) | 22 ms (0.1 ms/step) | — | — |
| Heap after sweep | — | 57 MB / 90 MB (500×200) | 66 MB / 92 MB | — | — |

Both finalists hold the 500×200 target under 5 MB with an order-of-magnitude
margin and switch steps at effectively zero cost. mapdeck and plotly were not
taken to the stress case: mapdeck cannot time-step a saved widget at all, and
plotly already exceeds the 5 MB cap on the smaller episode fixture (10.9 MB at
500×200, worse than the problem it would replace).

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
| 10 | Production visual quality | ✔ matches current product | ✔ (raster OSM identical; vector styles a future upgrade) | ◐ | ✗ chart-first chrome, washed-out map traces |

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

**plotly:** CRAN-healthy but the per-frame data duplication is structural —
it *is* the current Leaflet problem in a different wrapper, at larger sizes.

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
   outright; plotly fails the size target in the wrong direction.

**Second place / future path:** MapLibre via mapgl is a genuinely viable
backend (both sharing modes pass; the glyph/sprite offline fear is resolved
by an inline raster style) and remains the natural V2 migration if QuickMap
later needs vector basemaps or much larger point sets. Nothing in Option D
forecloses it: the compact JSON payload and the JS controller pattern
transfer directly (the Option D design doc already noted this equivalence).

## Wind-layer note (item 7 dependency)

leaflet-velocity rides on Leaflet unchanged under Option D — another argument
against switching renderers before item 7.

## Regenerating the demonstration maps

1. `Rscript dev/item5_prototypes/shared/item5_prepare-data_v1.R` (datasets +
   Leaflet reference; needs DATA_PATH)
2. `Rscript dev/item5_prototypes/shared/item5_simplify-boundary_v1.R`
3. `python3 dev/item5_prototypes/optiond/item5_optiond-build_v1.py`
4. `python3 dev/item5_prototypes/maplibre/item5_maplibre-build_v1.py`
5. `Rscript dev/item5_prototypes/deckgl/item5_deckgl-episode_v1.R` (installs mapdeck)
6. `Rscript dev/item5_prototypes/plotly/item5_plotly-episode_v1.R`

Outputs in `aq_maps/`: `item5_leaflet-episode-reference_v1.html`,
`item5_optiond-{episode,synthetic}_v1.html`,
`item5_maplibre-{episode,synthetic}_v1.html`, `item5_deckgl-episode_v1.html`,
`item5_plotly-{episode,synthetic}_v1.html`.

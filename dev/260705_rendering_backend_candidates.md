# Rendering backend candidates — expanded list for roadmap item 5

**Date:** 2026-07-05
**Status:** For user review and background research. Not yet part of the item-5
comparison mandate in CLAUDE.md; that section still names the original two
candidates. This document widens the field in light of technology developments
since the original tests.

## The filter every candidate must survive

1. **Self-contained offline HTML** (hard constraint, disqualifying) — all JS/CSS
   inlined; the file must work as an email attachment with no network access.
   WebGL libraries sometimes fetch glyphs, sprites, or basemap styles at
   runtime — this is the silent failure mode to test *first* for each candidate.
2. **CRAN-readiness** — an existing CRAN package wraps the JS, or the JS is
   small enough to vendor into `inst/` and drive directly.
3. **Scale target** — 500 markers × 200 time steps under ~5 MB, with smooth
   temporal layer switching.
4. **Migration cost** — the banner/legend/roller-menu HTML post-processing
   system must port or be re-implementable at reasonable cost.

## Candidates where the field has genuinely moved

### 1. deck.gl (via CRAN wrappers `rdeck` or `mapdeck`)

- WebGL point rendering: 100k+ points is trivial; 500 × 200 well within reach.
- First-class temporal filtering: `DataFilterExtension` performs time scrubbing
  **on the GPU with zero layer rebuilding** — arguably a better architectural
  fit for QuickMap's core problem (temporal animation of point data) than
  either original candidate.
- Research questions: does `rdeck`/`mapdeck` output survive
  `selfcontained = TRUE` fully offline (glyph/sprite/basemap fetches)? Which
  wrapper is CRAN-current and maintained? Bundle size when inlined?

### 2. MapLibre GL (via CRAN `mapgl`)

- Already the second candidate in CLAUDE.md; retained here for completeness.
- Native large-point-set rendering could make Option D unnecessary.
- Existing local experiment: `dev/maplibre.R`, `dev/maplibre_template.html`,
  sample input `dev/data.csv`, tarball `dev/mapgl_0.4.4.tgz`.
- Research questions: self-contained offline output (unverified — disqualifying
  if unmet); porting cost of the banner/legend/controls post-processing.

## The dark horse

### 3. No framework at all — Leaflet Canvas renderer + embedded JSON

- Plain Leaflet with `preferCanvas`/a Canvas renderer (or raw Canvas over a
  tile layer) plus the embedded-JSON temporal controller. This is essentially
  Option D (`dev/20250118_geojson_option_d_design.md`), executed with a
  Canvas rather than SVG/DOM marker path.
- Zero new dependency risk, zero HTML post-processing migration, known
  self-contained behaviour via `htmlwidgets::saveWidget(selfcontained = TRUE)`.
- Cost: the custom JS controller is hand-written and maintained by us — but
  the roadmap already mandates "a minimal custom JS controller, not a large
  framework", so this cost is accepted under any option.
- Prior art warning: read
  `versions/quickmap_0_9_5_failed_svgicon_experiment.R` first — it records a
  prior failed attempt at the file-size problem and why it failed (the failure
  was in the SVG-icon approach, not Canvas, but the lesson transfers).

## Explicitly ruled out (recorded so it isn't relitigated)

- **React / Vue / other UI frameworks**: UI frameworks, not renderers. They buy
  component state management QuickMap doesn't need (one map + a time slider) at
  the cost of a build toolchain and ~45 KB+ of inlined framework. The UI chrome
  is already solved by the `{{placeholder}}` template system.
- **CesiumJS, kepler.gl**: capable but far too heavy to inline into
  email-attachable HTML.

## Suggested shape of the item-5 comparison

A **three-way comparison** — Leaflet + Option D (Canvas), MapLibre/mapgl, and
deck.gl via a CRAN wrapper — running the self-contained-offline test *first*
for each candidate, since it is the cheap disqualifier. Remaining criteria as
already specified in CLAUDE.md: file size at 500 × 200, temporal switching,
post-processing migration cost, CRAN-readiness.

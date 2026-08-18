---
editor_options:
  markdown:
    wrap: 80
---

# QuickMap Project Status

**Last Updated**: 2026-08-16 **Current Version**: v0.9.9.12

Version history: NEWS.md. History before 2026-08-16:
dev/archive/PROJECT_STATUS_history_to_260816.md.

--------------------------------------------------------------------------------

## Where the project stands

- Close to v1.0. Roadmap items 9, 11, 12, 13 and 14 remain. Item 9 is next.
- Nothing in progress on main. Four PRs open, three waiting on Iarla.

## Waiting on Iarla

1. **Review PR #52** — vignettes were missing from the built package; adds the
   first README.
2. **Review PR #50** — merging now asks for approval at a prompt.
3. **Switch on GitHub Pages**: settings → Pages → main branch, `/docs`. The
   manual's example-map links stay broken until it is on.
4. **Get a Breathe London API key** at breathelondon.org/developers. Put it in
   `~/.Renviron` as `BREATHE_LONDON_KEY`. Unblocks PR #51.
5. **Upload three maps** to swlonrsp.github.io from
   `/Users/iarla/Coding/260814 Merton AQAP maps and figures refresh/animations/`.

PR #48, the manual, is held until item 9 changes output paths and renames
`marker_labels`. Reviewing it now would mean reviewing it twice.

--------------------------------------------------------------------------------

## Roadmap

Items are never renumbered; other documents cite these numbers.

**Done:** 1 packaging (v0.9.5), 2 characterization tests, 3 qm_layer, 4
`quickmap()` API (v0.9.6), 5 backend decision, 6 lazy loading (v0.9.7), 7 wind
(v0.9.8), 8 examples, 10 UI polish (v0.9.9.5).

### 9. CRAN compliance and internal consistency — next

- `R CMD CHECK` clean: dev/260708_item9_check-baseline_v1.md.
- Output paths: no auto `aq_maps/`; the user names the file.
  dev/260816_output_paths_decision.md.
- Rename `marker_labels` to `symbol_labels`, old name kept working.
- Defects and roadmap to GitHub Issues, plus DESCRIPTION `URL:`/`BugReports:`.
  Steps 2 and 3 of dev/260816_item9_status_restructure_plan.md.
- Client scripts move to a workspace repo; `inst/examples/` keeps generic ones.
  May finish post-1.0 if the package no longer depends on them.
- Four `sapply()` calls to `vapply()`; the live one is in
  `create_generic_icons()`, around R/quickmap.R:3092.
- Audit docs against code; mark dev docs current or historical.

### 11. Clear the open defects — last item before release

- The list is "Open defects" below. Not to be picked off piecemeal.
- Marker/text scaling was done early on 2026-08-05.

### 12. Breathe London fetch for the 2025 API — after 9, before 11

- `bl_sensors()`, `bl_data()`, `from_breathelondon()` built and fixture-tested
  on PR #51 (draft). Blocked on the API key.
- The 75% capture rule voids 117 of 345 Merton site-years, including every raw
  mean above 60 µg/m³. Survivors differ from published values by up to 16.5
  µg/m³, unexplained.
- Remaining: live probes, and licence attribution in the chrome (needs visual
  sign-off). dev/260815_bl_fetch_plan.md.

### 13. Retest the alternative stacks

- README and the "For R users" vignette state July 2026 conclusions publicly.
  tmap v4 now builds on mapgl.
- Re-test three load-bearing grounds: self-contained animated HTML; per-layer
  symbols on one scale in both outputs; one emailable file.
- dev/260706_atomic_unit_recommendation.md, dev/item5_backend-comparison_v1.md.

### 14. Rename the dev/ documents by date

- Three naming conventions coexist, so the folder cannot be read in order.
- Rename to `YYMMDD_name_vN.md`, update references, grep for old names.
- Known stale reference: dev/260816_output_paths_decision.md:67.

### Numbering history

Items 2 and 5 inserted 2026-07-05; item 10 on 07-06, renumbering UI defects to
11; items 12–14 on 08-15/16. Earlier dev docs use the old numbering.

--------------------------------------------------------------------------------

## Post-1.0

- **quickplot**: Heatmap, Trend, Exceedance figures on QuickMap's chrome. Own
  repo after 1.0. `quickplot/README.md`.
- **Ecosystem integrations**: ERA5 via ecmwfr, saqgetr, OpenAQ, Mazama
  AirMonitor, stars/terra underlays. Each a `from_*()` wrapper.
  dev/260707_v2_integration_candidates.md.
- **Fetch-code reconciliation**: superseded BL copies outside this repo marked
  historical; hardcoded keys in `250120_RSP_BL_download` move to `.Renviron`.
- **Wind styling presets**: preset ramps, speed-scaled width and opacity, per
  theme. Theme YAML only.
- **Tile-dependent particle density**: 1/300 suits OSM; CartoDB.Positron needs
  about 0.00125. Default should follow the tiles.

--------------------------------------------------------------------------------

## Open defects

Cleared at item 11. Ids provisional until migrated to GitHub Issues.

- **8. Subfolder generation.** Static export leaves leaflet JS subfolders.
- **9. Marker, text and legend sizing.** No unified scaling system; marker
  labels fixed 2026-08-05.
- **10. Label consistency.** Ward and marker labels differ between static and
  interactive.
- **11. Background CPU and memory.** Maps animate when hidden. Pause particles,
  crossfades and autoplay on `visibilitychange` and off-viewport.
- **12. Image export unreliable.** chromote startup times out mid-batch; retry
  each webshot call.
- **13. Sub-annual limit values.** The indicator hides below annual resolution;
  needs resolution-aware targets in the YAML. Post-1.0.
- **14. Fixed panel unexplained.** "Network mean, N sites" counts fewer sites
  than are on screen; add a tooltip.
- **15. Split import from map creation.**
- **16. Automate label placement**, clustering and spread.
- **LCA-1/2/3.** Collapsible radio buttons bottom-left; open at a zoom filling
  the screen; choose the layer visible on load.

--------------------------------------------------------------------------------

## Concepts — recorded, not scheduled

Index, documents, code and demonstration maps: dev/concepts/README.md.

- **Limit-centred indicator**: distance above or below a target, not position on
  the scale. Needs a decision on which target centres it.
- **Change-over-time graph**: sparkline of the network mean. Overlaps
  quickplot's Trend; settle ownership. 1.5–2 days.
- **Thermometer on the map**: vertical indicator over the map. Only if it
  restates the legend's bands.
- **Context polygon layer**: deprivation under the vignette, labelled 1–10. ~2
  days.
- **Retired indicator styles**, wakeable with instructions in the files:
  zero-to-value bar (`260731_indicator_bar-style_v1.R`), standalone track
  (`260730_indicator_track-style_v1.R`).

--------------------------------------------------------------------------------

## Recent work

- **16 August**: project record split by content type — history to NEWS.md and
  the archive, roadmap and defects here, decisions to dev/ citations. Output
  paths decided (dev/260816_output_paths_decision.md), which holds PR #48.
- **15 August**: v0.9.9.12 merged (PR #49, banner key reads `labels`). Item 12
  fetch code built on PR #51. Items 13 and 14 added. Merton AQAP work moved out
  of the repo.
- **5 August**: speed control (PR #42) and legend indicator (PR #38) merged,
  both signed off. `.gitignore` was excluding
  `inst/controls/time-slider.html`, so a fresh clone could not build a map.

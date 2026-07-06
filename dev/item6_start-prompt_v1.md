# Item-6 kick-off prompt (fresh autonomous session)

Copy-paste the block below as the starting prompt for the item-6 session.
Precondition: PR #22 (item-5 comparison) merged to main by the human.

---

Begin autonomous work on QuickMap roadmap item 6 (time step cap + lazy
loading via Option D) per the "Autonomous Agent Instructions" section of
CLAUDE.md. Read that section in full first — it is the approved plan.

**The backend decision is made and user-approved (2026-07-06): Option D —
keep Leaflet, replace the per-marker icon path with Canvas-rendered markers
restyled from one compact embedded JSON payload by a minimal custom JS time
controller.** Do not relitigate the choice. Evidence and working reference
code: dev/item5_backend-comparison_v1.md and dev/item5_prototypes/optiond/
(the prototype template is a proven implementation of the marker+controller
pattern: Canvas circleMarker restyle via setStyle, second shape via a
CircleMarker subclass, boundary on an SVG renderer — reuse its lessons, e.g.
fitBounds before adding layers on Leaflet 1.3.1).

Mandatory pre-reading, in order:
1. dev/item5_backend-comparison_v1.md (what was decided and why; measured
   targets the implementation must hit)
2. dev/20250118_geojson_option_d_design.md (the original Option D design —
   execute with Canvas markers, not divIcons)
3. dev/item5_prototypes/optiond/item5_optiond-template_v1.html +
   item5_optiond-build_v1.py (prototype; the Python builder is scaffolding —
   the package implementation is R-only via jsonlite + the existing
   {{placeholder}} template system)
4. tests/testthat/test-characterization.R + helper-characterization.R (the
   regression net; marker-count/group assertions target the old payload
   format and will need deliberate, flagged updates)
5. R/quickmap.R: create_generic_icons(), add_layer(),
   generate_map_layers(), inject_banner_legend_controls(), and the roller
   menu in inst/controls/ (the controller must drive the existing roller
   menu UI, not replace it)

Scope (CLAUDE.md "Time steps and file size" governs):
- 200-step default cap with warn+subset behaviour
- Lazy/JSON rendering when estimated size > ~5 MB or steps > 50; below the
  threshold, keep the current pre-built-layers path unless the payload path
  proves strictly better on the characterization fixtures
- Marker labels/tooltips, legend, banner, roller menu, autoplay, vignette,
  boundary polygons and static layers (schools) must all survive unchanged
  visually; JPG export must still work (webshot2 needs a settle delay for
  JS-styled markers)
- Targets from item 5 to verify against: episode fixture ≤ ~0.5 MB (from
  3.46 MB), 500×200 ≤ ~1 MB, load ≪ 1 s, step switch ≪ 5 ms

Ground rules:
- Verify Sys.getenv("DATA_PATH") and the fixtures exist; STOP if not
- Branch feature/item6-lazy-loading off main (after PR #22 is merged);
  archive R/quickmap.R to versions/ before the refactor
- Characterization tests: update expected values only for deliberate format
  changes, in the same commit, flagged in the PR for human visual sign-off —
  this PR is rendering-touching and **blocks on human visual sign-off**
- Naming convention for all new artefacts: item6_[desc]_[version]
- Produce fresh demo maps (annual multi-year, sub-annual episode, schools +
  labels) in aq_maps/ and copy the current signed-off set to a dated
  baseline folder first; PR must list generating scripts, outputs, and what
  the human should check (side-by-side vs item5_leaflet-episode-reference_v1)
- Permission-safe command style per CLAUDE.md (no cd, no $(), no inline env
  assignments, no loops/redirects; multi-step work in Rscript/python3 files)
- Automated gate before the PR: full testthat suite + smoke test
  (reinstall with devtools::install() after editing R/quickmap.R)
- STOP at PR: never merge; never push to main

---

## Handover notes (context the prompt above compresses)

- Item-5 session artefacts: branch feature/item5-backend-comparison (PR #22),
  comparison doc, prototypes, shared JSON datasets
  (dev/item5_prototypes/shared/ — episode.json format {times, thresholds,
  colours, sites:[{code,lon,lat,v:[…null for missing]}]} is a ready-made
  starting point for the item-6 payload format).
- Leaflet 1.3.1 gotchas found in prototyping: layers added before the map
  has a view throw in _clipPoints (fitBounds/setView first); Canvas polygon
  clipping on 1.3.1 is buggy — render polygons on L.svg(), markers on Canvas.
- The characterization episode test pins file size in a band; the item-6
  change will deliberately break that band downward — update the expectation
  and flag it.
- webshot2 timing: JS-restyled markers need the render to settle before
  capture; the old delay parameter in the export path may need increasing.

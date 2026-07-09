# Item 10 implementation plan (UI polish → v0.9.9.5)

**Date:** 2026-07-09 · **Design:** APPROVED by user 2026-07-09
("approve final design") — the assembled mocks
aq_maps/item10_assembled-annual_v1.html and
item10_assembled-episode-wind_v1.html are the visual specification.
Decisions record: dev/260708_item10_ui-review-mcqs_v1.md §3/§3a.
**Branch:** feature/item10-ui-polish (stacked on chore/item10-ui-review).

## The approved design, as build requirements

1. **Typography:** system font stack everywhere (banner, controls,
   legend); monospace dropped from legend chips.
2. **Banner:** new default "strip" (white, left-aligned title, 3px brand
   rule below); "bar" (refined brand-colour block) selectable via theme —
   new theme key `banner.style: strip | bar`.
3. **Legend:** thin colour-ramp (blocks row + labels row below, labels
   outside colours), footnote-symbol key kept as restyled pills;
   collapsible behaviour retained.
4. **Chrome colour:** neutral (white/grey) chrome; brand colour as
   accents only (title rule, play button, slider fill, selected states).
5. **Time control:** bottom-centre slider card — play button, ‹ ›
   fine-step buttons, draggable track with current-step label above the
   thumb, first/last labels below; crossfade suppressed during drag;
   replaces the roller dropdown (keyboard accessibility preserved).
6. **Tiles:** default `CartoDB.Positron`; any provider via theme
   `map.base_tiles` (OSM = explicit option).
7. **Wind:** speed-ramp colour scale default; density, line width,
   colour ramp, velocity scale exposed through theme YAML
   (`wind:` section), per the roadmap mandate.
8. **Image-mode scaling bug** (logged 2026-07-05): the static-export
   text-scaling substitutions are inert — repair as part of the unified
   scaling work this item owns.

## Stages (gate + commit after each; sign-off at the end on demo maps)

**Stage 1 — CSS/theme surface (no JS):** banner strip/bar + theme key,
legend ramp HTML/CSS generation (generate_legend_html), neutral chrome,
system fonts, Positron default, wind ramp default + `wind:` theme keys
threaded to wind-controller.js. Characterization updates flagged.

**Stage 2 — slider controller (JS):** new inst/controls/time-slider.*
replacing roller-menu for temporal maps; integrates with
window.quickmapTimeController (lazy path) and quickmapLayerCache
(pre-built path); keyboard support (arrows = fine step, space =
play/pause); autoplay + play_speed honoured; mobile width via
min(26rem, 90vw).

**Stage 3 — static export:** image-mode scaling repair; slider hidden in
JPG exports (single-step renders unchanged).

**Stage 4 — verification pack:** characterization expectations updated
(banner/legend/control blocks change deliberately — flagged), demo maps
item10_final-*_v2.html vs the approved mocks, full gate, PROJECT_STATUS,
version bump to v0.9.9.5, iCloud review pack, PR blocking on visual
sign-off.

## Out of scope (recorded)

- Wind preset library / per-theme ramps: post-1.0 optional (CLAUDE.md).
- Item 11 UI defects (LCA fixes, subfolder generation, label
  consistency) stay item 11.

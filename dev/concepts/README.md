# Concepts

Ideas that were designed, costed or built and then set aside — kept so they can
be picked up deliberately rather than reinvented. Each has a document; where a
version was actually built, its demonstration maps are in `examples/`.

This folder is in the repository. `aq_maps/` is not, so anything left there is
one tidy-up away from being lost; a concept's examples are the only evidence it
worked.

## Agreed, waiting to be built

| Concept | Document | Notes |
|---|---|---|
| Animation speed control | `260805_animation-speed-control.md` | Settings agreed 5 Aug 2026. Also changes the default step timing and makes the crossfade proportional. ~half a day |

## Proposed, undecided

| Concept | Document | Notes |
|---|---|---|
| Change-over-time graph | `260729_trend-graph.md` | The open half of the 29 July overlays decision. 1.5–2 days now the indicator has shipped |
| Limit-centred indicator | `260730_limit-centred-indicator.md` | Distance above or below a chosen target, instead of position on the scale. Needs a decision on which target sits at the centre |
| Thermometer on the map | `260801_thermometer-overlay.md` | A vertical indicator overlaid on the map rather than in the legend. Feasible, but must not draw a second scale — see the document |

## Built, then retired

Both were working code. The reason each went, and instructions to bring it
back, are in the archived source files.

| Concept | Archived code | Examples in `examples/` |
|---|---|---|
| Zero-to-value bar | `../archive/260731_indicator_bar-style_v1.R` | `indicator_bar-animated_v2.html`, `indicator_bar-annual_v2.html`, `indicator_bar-print_v2*.{html,jpg}` |
| Standalone track (its own scale beside the legend) | `../archive/260730_indicator_track-style_v1.R` | `indicator_uneven-track_v1.html` and `indicator_uneven-ramp_v1.html` — the pair that shows why it went; `indicator_print-4000_v1.html`, `indicator_print-900_v1.html`, `indicator_merton-annual_v1.html` |

The track's lesson is worth repeating before any future indicator work: the
legend's colour ramp draws every band the same width whatever its span, so it
is not a linear scale. Anything drawn linearly beside it puts the same
threshold in two different places.

## Also recorded elsewhere

- Sub-annual target sets for the indicator — backlog issue 13 in
  `../PROJECT_STATUS.md`
- Post-1.0 wind styling presets and ecosystem integrations — the roadmap in
  `../../CLAUDE.md`

# Concepts

Ideas that were designed, costed or built and then set aside — kept so they can
be picked up deliberately rather than reinvented.

**One folder per concept** (restructured 7 August 2026). Each holds its
document, and where a version was actually built, its `code/` and `examples/`
alongside, so the idea, the thing that made it and the thing it produced stay
together. Folders with code carry a README saying which paths inside those
scripts no longer resolve.

This folder is in the repository. `aq_maps/` is not, so anything left there is
one tidy-up away from being lost; a concept's examples are the only evidence it
worked.

The roadmap list that points here is **"Tested ideas, but need more work"** in
`CLAUDE.md`.

## Built and shipped

| Concept | Folder | Notes |
|---|---|---|
| Legend indicator | `indicator/` | Shipped v0.9.9.9. Folder also holds the four styles tested and rejected on the way, with their renders |
| Animation speed control | `animation-speed-control/` | Shipped v0.9.9.10 |

## Tested ideas, but need more work

| Concept | Folder | What is left to do |
|---|---|---|
| Limit-centred indicator | `indicator/260730_limit-centred-indicator.md` | Distance above or below a chosen target rather than position on the scale. Needs a decision on which target sits at the centre |
| Change-over-time graph | `trend-graph/` | The open half of the 29 July overlays decision. 1.5–2 days now the indicator has shipped. Overlaps with quickplot's **Trend** figure |
| Thermometer on the map | `thermometer-overlay/` | A vertical indicator overlaid on the map rather than in the legend. Feasible, but must not draw a second scale |
| Context polygon layer | `context-polygon-layer/` | Deprivation or similar, drawn under the vignette and labelled 1–10 instead of carrying a second legend ramp. ~2 days |

## What is not here

`dev/archive/` is a different store: 60-odd planning, analysis and review
documents from 2025 and early 2026, plus the throwaway test scripts of that
period. They are project history, not tested ideas, and were left where they
are. The two indicator style prototypes that were in `dev/archive/` moved into
`indicator/code/` on 7 August, because they are tested ideas.

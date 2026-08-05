# Concept: a change-over-time graph in the legend

Status: **deferred, not built.** This was feature B of the overlays study
(`/Users/iarla/Coding/quickmap/dev/260729_overlays_feasibility.md`); Iarla chose
on 29 July to build the indicator first and decide on this separately. The
indicator shipped on 5 August, so this is the open half of that decision.

## What it is

A small chart in the legend showing how the network mean has moved across all
the displayed steps, with the current step marked — a sparkline, in effect. The
indicator answers "where are we now"; this answers "which way have we come".

## Why it is cheap now

Everything it needs exists. `build_indicator_data()` in
`/Users/iarla/Coding/quickmap/R/quickmap.R` already returns one figure per step
(and a maximum per step), the controller already updates on every time change,
and the drawing is an inline SVG polyline with a moving dot. Estimated 1.5–2
days — against 3–4 if it had been built first, because it inherits the
indicator's data plumbing.

## The three risks, unchanged from the study

- **Space.** The legend row already holds the title, two figures, the ramp,
  its labels and the footnote pills. A chart is a fifth element, and the row
  wraps at 900px as it is.
- **Axis honesty.** An unlabelled sparkline with an auto-scaled y axis makes a
  1 µg/m³ drift look like a collapse. It needs a zero baseline or explicit end
  labels, which costs more space again.
- **Many steps.** At 200 steps a sparkline in a 20rem box gives 0.1rem per
  point: legible as a shape, useless as a reading. Probably show it only below
  a step count — 20 or so, which is the annual case anyway.

## Note on Merton's data

The seven-year series is not a clean decline — 2021 rebounds to 35.8 from
2020's 34.5, the post-lockdown traffic return. That rebound is exactly the kind
of thing a trend graph shows well and a single figure hides, which is the
argument for building it.

## Related

- The study that proposed it: `/Users/iarla/Coding/quickmap/dev/260729_overlays_feasibility.md`
- The indicator it would sit beside: CLAUDE.md, "Legend Indicator"

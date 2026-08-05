# Concept: an indicator centred on the limit, not on zero

Status: **concept only — not built, not scheduled.** Recorded 2026-07-30 at the user's request while building the legend indicator.

## The idea

Every indicator built so far answers "where are we on the scale?" — the bar runs from zero up to the network mean, or the roundel sits at the mean's place along the colour ramp.

An air quality action plan usually asks a different question: **"how far above or below the limit are we, and which way are we moving?"** That is a different graphic. The scale would be centred on a chosen target — the UK annual limit of 40 µg/m³, or the WHO guideline of 10 — with the marker sitting to the left or right of it, and the distance from the centre being the message.

Sketch, for a network mean of 23.2 against a UK limit of 40:

```         
    under the limit          UK limit 40          over
    ───────────────────────────────┼───────────────────────
                      ◄── 16.8 ──● │
```

Against the WHO guideline of 10 the same figure would sit well to the right, and the graphic would say something quite different about the same air. **Which target is chosen changes the story**, which is exactly why this needs a deliberate decision rather than a default.

## Why it is worth keeping

- It answers the question a statutory report actually asks.
- "13.2 above the WHO guideline" is a sentence an officer can put in a report; "position on a scale" is not.
- Direction of travel becomes readable at a glance across a series of years, because the marker crosses the centre line rather than merely shortening.

## Why it was not built now

- It needs a decision about *which* target sits at the centre, and that decision changes the meaning of every map that carries it.
- Multiple targets (WHO 10, interims 20/30, UK 40) on one centred scale gets crowded quickly — the thing being marked is a distance, and several simultaneous distances is a table, not a graphic.
- The current indicator ships first and gets used; this is a better question to ask once someone has lived with the simple version.

## What it would take

Small, and mostly a drawing change. The data is already there.

- The aggregate already exists: `build_indicator_data()` in `/Users/iarla/Coding/quickmap/R/quickmap.R` returns one figure per step.
- The positioning would NOT reuse `ramp_position()`, because that maps onto the legend's ramp; a limit-centred scale is a different geometry and would need its own mapping — and, unlike the ramp marker, its own axis drawn beneath it, which brings back the two-scales-on-one-page problem that retired the track style (see `/Users/iarla/Coding/quickmap/dev/archive/260730_indicator_track-style_v1.R`). That is the main design risk.
- New theme keys, roughly: `indicator.mode: "scale" | "distance"` and `indicator.target: 40`.
- Estimated 1-2 days including a human eyeball round.

## Related

- Built instead: the ramp marker — `/Users/iarla/Coding/quickmap/dev/260730_indicator_ramp_variant.md`
- Retired sibling: the standalone track — `/Users/iarla/Coding/quickmap/dev/archive/260730_indicator_track-style_v1.R`
- The sub-annual gap that would also affect this: issue 13 in `/Users/iarla/Coding/quickmap/dev/PROJECT_STATUS.md`
# Indicator style: bar-on-the-legend-ramp versus standalone track

Date: 2026-07-30. Status: both styles built and rendered; awaiting your choice.
This is a feasibility test with working output, not a paper study.

## What I found

Your proposal is not only feasible, it is **better than what I built**, and for
a reason that only showed up when I looked at the code: **the legend ramp is not
a linear scale.** Every band is drawn the same width whatever its span
(`.ramp-block { flex: 1 }`). In `gla_pm25` the bands are 5, 2.5, 2.5, 2.5, 2.5,
5, 5 units wide and all seven draw identically.

So the v1 track, which *is* linear, puts the same threshold in a different place
from the legend directly beneath it. Two scales, same numbers, different
geometry, six centimetres apart on the page.

Your bar cannot have that problem, because it does not have a scale of its own —
it borrows the legend's. It was also slightly *easier* to build: it is two divs
and a percentage, no SVG, no tick marks.

## Recommendation

**Adopt the ramp style as the default.** Keep the track as an option for maps
with no legend showing. Drop the "colour-code v1" fallback — see below.

## The three options, compared

| | Effort | Risk | Verdict |
|---|---|---|---|
| **A. Bar on the legend ramp** (your proposal) | Built, 2 hours | Low | **Recommended** |
| **B. Standalone track** (v1, already built) | Built | Low, but scales disagree | Keep as a fallback option |
| **C. Colour-code v1 with legend colours** | ~1 hour | **Makes the problem worse** | Do not build |

### Why C is the one to drop

C sounds like the cheap middle route, and it is the trap. Colouring the linear
track with the legend's colours means the same colour appears at two different
positions on the page — the legend's orange block and the track's orange
section would sit at visibly different places, while looking like they should
match. Uncoloured, the track is merely a separate scale; coloured, it actively
invites a false comparison. If the ramp style is rejected, v1 is better left
grey.

## See for yourself

All in `/Users/iarla/Coding/quickmap/aq_maps/`:

**Your proposal, print maps** — the bar sits directly above the ramp and ends
inside the band it belongs to:
- `indicator_ramp-print-4000_v1_2019.jpg` — 44.1, a long orange-red bar ending
  in the 40-49 block
- `indicator_ramp-print-4000_v1_2025.jpg` — 23.2, a short yellow bar ending in
  20-29

Set those two side by side and the six-year improvement reads instantly. The
equivalent pair under v1 (`indicator_print-4000_v1_*.jpg`) needs you to find a
small pointer on a small track.

**The proof that the scales disagree** — same data, same map, uneven-band scale:
- `indicator_uneven-track_v1_2025.jpg` — the legend's thresholds are evenly
  spaced; the track's tick labels below right are bunched to the left and
  overlapping. The same numbers, in two different places
- `indicator_uneven-ramp_v1_2025.jpg` — one scale, bar ends in the 20-25 block

**Interactive:** `indicator_ramp-annual_v1.html` — drag the slider; the bar
grows and shrinks and changes colour with the band.

**Height cost:** you predicted "taller, but not by much". It is 0.45 rem of bar
plus 0.2 rem of gap — about 10 pixels on screen. The legend still collapses,
and the bar collapses with it.

## How it works, briefly

- `/Users/iarla/Coding/quickmap/R/quickmap.R`, `ramp_position()` converts a
  concentration to a percentage of the ramp: find the band, interpolate inside
  it, divide by the number of blocks drawn. Never value ÷ maximum.
- `generate_indicator_bar()` emits the bar; it goes inside the legend's own
  items block, so it is exactly the ramp's width by construction rather than by
  a matching number that could drift.
- `trim_colour_scale()` was extracted from `generate_legend_html()` so the bar
  and the legend trim identically. Previously the trimming logic lived inside
  the legend builder; if the bar had recomputed it, a legend cut to six blocks
  with a bar assuming eleven would point at the wrong band.
- The open-ended top band (`.Inf`) has no width to interpolate within, so a
  value inside it sits at that band's midpoint. Anything else would invent
  precision.
- `indicator.js` sets a width and a colour per step — simpler than moving the
  SVG pointer.
- Theme key: `indicator.style: "ramp"` or `"track"` (currently defaulting to
  `"track"`, pending your choice).

## What this does not solve

- **Static exports still cannot show a moving bar**, only the step being drawn.
  That is inherent to a still image, not a limitation of either style.
- **Sub-annual maps still get no indicator** at all, under either style
  (backlog issue 13).
- **The bar starts at zero**, so it reads as "how far up the scale we are", not
  "how far above or below the target". If what the Action Plan wants is distance
  from the 40 µg/m³ limit specifically, that is a third design — a bar centred
  on the limit — and worth saying now rather than after this one is signed off.

## Decisions

1. **Which style becomes the default?** (a) ramp — recommended; (b) track;
   (c) ramp for maps with a legend, track for maps without, chosen
   automatically.
2. **Do I drop the track style entirely** rather than keeping two code paths?
   Keeping it costs a little complexity; removing it means maps with the legend
   switched off lose the indicator.
3. **Is "distance from the UK limit" the more useful reading** for the Action
   Plan than "position on the scale"? If so, say now — it is a different bar.

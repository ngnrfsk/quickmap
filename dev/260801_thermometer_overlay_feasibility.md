# Feasibility: a thermometer indicator on the map, not in the legend

Date: 2026-08-01. **Feasibility review only — nothing built, nothing changed.**
Claims below were checked against the code today.

## What I found

Mechanically this is easy — easier than the legend marker was. There is a
proven pattern for putting a floating card on the map (the time slider does
exactly this), the positioning maths already exists, and the static export
already scales this kind of chrome correctly.

The difficulty is not mechanical. **A thermometer standing away from the legend
has to carry its own scale, and the legend is still on the page carrying
another one.** That is precisely what retired the standalone track style eight
days ago: two scales, same numbers, different geometry, a few centimetres
apart. Unless the two are made to agree — or one of them is removed — this
rebuilds a problem already solved.

There is a clean way through it, and it is worth considering seriously: make
the thermometer a **vertical restatement of the legend ramp** (same bands, same
order, equal heights), rather than a linear scale of its own. Then there is
still only one geometry on the page, just shown twice.

## The two things "up one side" could mean

They have very different costs.

### (a) Floating card overlaid on the map — cheap

An absolutely positioned card inside `.map-container`, exactly as the time
slider does it (`/Users/iarla/Coding/quickmap/inst/controls/time-slider.js`
line 76 moves the control into the map container so "bottom" means the map, not
the page). `.map-container` is `position: relative`
(`/Users/iarla/Coding/quickmap/inst/banner/banner-interactive.css` line 19), so
a child positions against the map area.

**One trap, already known:** line 20 of that file is
`.map-container > div:not(#yearControl) { height: 100% !important; }`. Any new
direct child is stretched to full height unless it is added to that exception
or nested one level deeper. For a *vertical* thermometer full height is
almost what you want, so this bites less than it would have for a horizontal
card — but it must be handled deliberately, not discovered.

### (b) A true side rail beside the map — expensive

The page is a vertical flex column: banner, map, legend
(`body { display: flex; flex-direction: column; }`). A genuine rail *beside*
the map means making the middle row a horizontal flex, which changes the
layout every other piece of chrome sits in, and changes how the map's aspect
ratio comes out in the JPG export at a given pixel size. I would not do this
for an indicator.

**Recommendation if this goes ahead: (a), overlaid, not (b).**

## Where it would sit

The map's edges are already busy:

| Position | Occupant |
|---|---|
| top-left | Leaflet zoom control |
| top-right | year pill in static exports (`load_time_slider_control()`, image mode) |
| bottom-centre | time slider card |
| bottom-right | OpenStreetMap attribution |

A vertical thermometer therefore wants the **left edge, below the zoom
control**, or the right edge below the year pill. On Merton's wide borough
shape either is mostly over empty basemap — but that is luck of this borough,
not a general property. A tall borough (Wandsworth, say) would have the
thermometer over data.

## Will it be viewable?

Honest answers:

- **On screen, yes.** A 2-3 rem wide, 40-60% height strip is legible and does
  not crowd a desktop map.
- **In print at 4000x3000, yes**, provided it is rem-based like the rest of the
  chrome. `inject_banner_legend_controls()` scales the root font size for
  exports, so rem-based overlays scale with the image — the same property that
  let the legend markers escape defect 9.
- **On mobile, doubtful.** A vertical strip eats width on the axis a phone can
  least spare, and the legend already auto-collapses below 480px. It would need
  its own hiding rule.
- **Over data, sometimes.** Unlike the legend, this sits on the map. On a
  borough whose shape fills the frame it will cover markers. A translucent
  background helps but does not solve it.

## The scale problem, stated plainly

This is the decision the whole idea turns on.

The legend ramp draws every band the same width regardless of its span
(`.ramp-block { flex: 1 }`). A thermometer that is a normal linear scale would
put 40 µg/m³ at a different fraction of its length than the legend puts it
along its width. Both would be on screen at once. Readers would be entitled to
believe the two agree.

Three ways out:

1. **Vertical restatement** — the thermometer is the legend's bands stacked
   vertically, equal heights, same colours. Geometry matches by construction.
   The marker uses `ramp_position()` unchanged. My recommendation.
2. **Thermometer replaces the legend's ramp** — the map gets a vertical scale
   and the horizontal ramp goes. Coherent, but it is a redesign of the legend
   that was signed off at v0.9.9.5, and it would need the footnote key
   rehousing.
3. **Linear thermometer alongside the ramp** — the option that recreates the
   retired track problem. Not recommended.

## What it would cost

Assuming option 1, overlaid:

- New builder alongside `generate_indicator_bar()` in
  `/Users/iarla/Coding/quickmap/R/quickmap.R`, emitting a vertical stack of
  band blocks plus the existing markers rotated to a vertical axis.
  `ramp_position()` is reused as-is — it returns a percentage, which is as
  valid down an axis as along one.
- New template + CSS in `/Users/iarla/Coding/quickmap/inst/controls/`
  (it is map chrome now, not legend chrome).
- `indicator.js` needs a second positioning branch (`top` instead of `left`).
  The controller contract does not change.
- Static export: R draws the step server-side, as now.
- Theme keys: `indicator.placement: "legend" | "map"`, plus a corner.
- **Roughly 1.5-2 days**, plus a visual round. Cheaper than the legend marker
  was, because the data, the positioning and the controller all exist.

## Risks, in the order I would worry about them

1. **Two scales on one page** if option 3 is taken by accident. This is the
   whole ballgame.
2. **Covering data** on boroughs whose shape fills the frame. Merton flatters
   this idea; test on a tall borough before committing.
3. **Mobile**, which needs a hiding rule the legend indicator did not.
4. **The `height: 100% !important` rule** silently stretching the card.
5. **Export aspect ratios**: a strip sized as a percentage of height behaves
   differently at 4000x3000 (4:3) than at 1200x1200 (1:1). Both need checking;
   neither is hard.

## What I would advise

The legend marker now works and is not yet signed off. Two indicators of the
same figure, in two places, is not a thing to build in parallel — it is a
choice between them. So: **sign off or reject the legend marker first**, and
treat this as its possible successor rather than its companion.

If it does go ahead, option 1 (vertical restatement of the legend bands,
overlaid on the map, left edge below the zoom control) is the version I would
build, and I would test it on a tall borough on day one rather than on Merton.

## Related

- The retired standalone track, and why:
  `/Users/iarla/Coding/quickmap/dev/archive/260730_indicator_track-style_v1.R`
- The ramp-versus-track comparison with evidence images:
  `/Users/iarla/Coding/quickmap/dev/260730_indicator_ramp_variant.md`
- The original overlay study, which covered the map-card placement:
  `/Users/iarla/Coding/quickmap/dev/260729_overlays_feasibility.md`

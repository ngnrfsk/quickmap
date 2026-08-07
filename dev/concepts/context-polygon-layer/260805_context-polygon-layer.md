# Concept: a context polygon layer (deprivation and similar)

Status: **concept, not built.** Proposed by Iarla on 5 August 2026. About two
days.

## What it is

A shapefile of areas — indices of multiple deprivation being the case in mind —
drawn beneath the pollution markers so a reader can see the two together:
whether the worst air sits over the most deprived areas.

Placement, as specified: above the basemap, below the vignette, clipped to the
boundary, at partial transparency.

## The stacking is free

The vignette is already the last polygon drawn
(`/Users/iarla/Coding/quickmap/R/quickmap.R`, `add_map_controls()`), and
Leaflet keeps markers in a pane above all polygons. A layer added just before
the boundary therefore lands exactly where it should, with no new machinery.
Clipping is an intersection with the boundary; transparency is an existing
parameter; reading the file is `sf::st_read` plus a coordinate transform.

It is **not** a `qm_layer`: the atomic unit assumes points carrying a value per
time step, and a deprivation surface has neither. It belongs as a map-level
argument alongside `boroughs` and `wind`.

## Three hatched grades (Iarla, 5 August — the current preference)

Rather than ten deciles labelled with numbers, three classes — worst, average,
best — distinguished by hatching rather than by colour.

This is better than the labelling idea on every count that mattered:

- **Density stops being a problem.** Three classes need no per-area labels at
  all, so nothing competes with the pollution markers.
- **It survives print, including photocopying and greyscale**, which numeric
  labels at 12px do not. For a statutory document that will be reproduced badly
  this is a real advantage.
- **The key is tiny** — three small swatches and three words fit in the
  legend's existing row, so the second-ramp problem disappears rather than
  being worked around.
- **It cannot be confused with the pollutant scale**, because it is not a
  colour scale. That was the risk that worried me most about a coloured
  surface beneath coloured markers.

**How hatching would be done.** Leaflet draws polygons as SVG paths, and this
map does not switch on Canvas rendering for them (`create_base_map()` sets only
zoom options), so an SVG `<pattern>` can be defined once and referenced as the
fill. The mechanism is a small script injected the same way the existing
controllers are. Worth prototyping early: it is the one part of this concept
with no precedent in the codebase.

**Fallback if patterns prove awkward:** three levels of a single hue at
different opacities. Simpler, no new mechanism, but it loses the greyscale and
photocopy robustness, which is much of the appeal.

**Still needed:** one line saying which end is which, since "worst" and "best"
must be attached to the swatches. Three words in the legend row.

**Open question:** what defines the three classes — deciles 1–3 / 4–7 / 8–10,
or tertiles of the areas actually shown? The first is comparable between
boroughs, the second describes the borough on screen. Decide before building.

## Labels instead of a legend (Iarla, 5 August — superseded by the above)

A second colour ramp would double the height of a legend that is already the
tightest part of the design. Instead, each area carries its value 1–10 on the
map itself.

**Mechanically this is easy and has precedent.** `add_boundary_polygons()`
already draws permanent labels on polygons — that is how ward names appear. The
same call takes the decile instead of the name.

**Three things it does not solve:**

1. **Density.** A borough holds roughly 120 LSOAs. 120 numbers scattered across
   the map compete with the pollution markers for the reader's attention, and
   the markers are the point of the map. Options: label on hover only
   (interactive), label only the extremes (deciles 1–2 and 9–10), or label only
   above a zoom level.
2. **Print.** Hover labels do not exist in a static export, so a printed map
   gets all 120 numbers or none. The extremes-only option is the one that
   survives print.
3. **Direction.** A bare "7" does not say whether 1 is most or least deprived.
   Avoiding a ramp does not avoid needing one line of text — a caption such as
   "IMD decile, 1 = most deprived" is the minimum, and it can live in the
   legend's existing row rather than as a second ramp.

**A known defect it would inherit:** polygon label text is fixed at 12px
(`add_boundary_polygons()`), so it does not scale with export size — the
surviving half of issue 9. At 4000×3000 the numbers would be nearly invisible.
Fixing that for this layer is the same fix the marker labels need, so the two
should be done together.

## Colour, which matters more than it sounds

The markers are already coloured across a full spectrum by concentration. Any
saturated surface beneath them makes both harder to read. The context layer
needs a single-hue, low-saturation ramp — greys or muted purples — chosen so it
cannot be mistaken for the pollutant scale. This is a design decision before it
is a coding one, and it should be settled with a mock-up rather than in code.

## Sizing

A borough's ~120 LSOAs is nothing. London-wide is 4,835, which would need the
geometry simplified before embedding or the self-contained file grows — the
same constraint that drove the lazy-loading work at roadmap item 6.

## Recommended shape, if it goes ahead

1. Three hatched classes, no per-area labels.
2. Prototype the SVG pattern fill first — it is the only part with no
   precedent here, and everything else is routine.
3. Three swatches and three words in the legend's existing row.
4. Settle the class boundaries (fixed decile bands, or tertiles of what is
   shown) before building.

The label-scaling fix that the earlier labelling idea would have needed is no
longer part of this work — with no labels, it is not affected by issue 9.

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

## Labels instead of a legend (Iarla, 5 August)

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

1. Hover labels in the interactive map, extremes-only labels in exports.
2. A single-hue ramp, agreed from a mock-up first.
3. One caption line stating the direction, in the legend's existing row.
4. The label-scaling fix shared with the marker-label half of issue 9.

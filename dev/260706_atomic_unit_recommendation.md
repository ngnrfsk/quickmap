# Atomic data unit — survey and recommendation (roadmap item 3)

**Date**: 2026-07-06 · **Status**: awaiting user design approval (STOP point)
**Author**: autonomous session, per CLAUDE.md "The atomic data unit — research
task before implementing"

User comments:

* considering atomic data unit recommendation - do we need to distinguish between static and temporal data at all? if a time/date  column is present, doesn't this auto







## The question

Formalise the internal currency that all input wrappers (`from_csv`,
`from_rdata`, `from_openair`, `from_worldmet`, `from_yaml`) produce and that
`quickmap(layers, ...)` consumes. Candidates: a named S3 class, a plain list
with required structure, or the current sf object as-is. Overriding criterion:
the gentle, progressive learning curve — a two-line call works; each added
parameter unlocks more sophistication.

## Current state

The de-facto atomic unit already exists: `convert_openair_to_spatial()` returns
an **sf object in long format, one row per site per time step**, with columns
`siteCode`, `year_str` (time label), one pollutant value column, `lat`, `lon`,
`Longitude`, `Latitude`, `geometry`. CSV and RData loaders produce the same
shape internally. Layer *kind* (temporal vs static, circle vs diamond vs cross)
is inferred downstream by duck typing (School column, Label column, year
columns) plus per-layer config objects assembled in `get_measurement_layers()`.

What is missing is not the data shape — it is that the shape's **contract is
enforced nowhere and its metadata lives nowhere**. Pollutant name, layer kind,
symbol shape, and label source are re-derived by scattered duck typing each
time they are needed, and a malformed input fails deep inside the pipeline with
an unhelpful error.

## Survey

### openair

No grammar and no layer objects. Every function takes a plain data.frame with
**canonical column names** (`date`, `ws`, `wd`, `nox`, `no2`, …) plus
progressive parameters (`pollutant = "no2"`, `type = "season"`). The learning
curve is exactly the one QuickMap wants: `polarPlot(mydata)` works; each added
argument refines. The cost is that every function must internally re-validate
the frame. openair can afford this because its unit is a *single* data.frame;
QuickMap composes *multiple heterogeneous layers*, so the "just a data.frame
with known columns" approach leaves layer-kind metadata homeless — which is
precisely today's duck-typing sprawl.

### tmap v4

Full grammar of graphics over sf: `tm_shape(sf_obj) + tm_polygons(fill = "HPI",
fill.scale = tm_scale_continuous())`. The atomic unit is a plain sf object; all
semantics (which column, which scale, which legend) are carried by the layer
grammar, not the data. Powerful and composable, but the *entry* cost is high:
even the simplest map requires understanding shape/layer separation, `+`
composition, and (in v4) the visual-variable/scale system — three concepts
before first output. tmap v4's animation story (`tm_facets()` +
`tmap_animation()`) produces GIF/video, not self-contained interactive HTML
with a time control, so the grammar would still not buy us the core temporal
feature. Confirms CLAUDE.md's "last resort" stance: the survey does **not**
show grammar serving incremental learning better; it front-loads concepts.

### Leaflet wrappers (non-ggplot layered APIs)

- **mapview**: "a data-driven API for the leaflet package". Atomic unit is any
  standard spatial object (sf first); `mapview(x)` renders immediately,
  `zcol = "col"` colours by attribute, layers combine with `+`. The gentlest
  curve in the R spatial ecosystem, achieved by (a) accepting a *standard*
  class rather than inventing one and (b) inferring rendering from the object.
  No temporal animation. Lesson: **keep the unit an sf object users can make
  and inspect themselves**.
- **leafgl / leaflet.extras**: thin capability add-ons to leaflet; unit is again
  sf / leaflet's own frames. They add functions, not data abstractions. Lesson:
  wrappers that invent no new data class compose best with the ecosystem.

## Recommendation: a minimal S3 subclass of sf — `qm_layer`

An sf object **that additionally carries its layer metadata as attributes and a
class tag**: `class = c("qm_layer", "sf", "data.frame")`.

Required columns (the current shape, unchanged): `siteCode`, `year_str`, one
value column, `geometry` (+ `lat`/`lon` kept for compatibility). Static layers
(schools) use the same shape with a categorical value column and no time
variation.

Attributes (set once by the wrappers, never re-inferred):

| attribute | values | today's source |
|---|---|---|
| `value_col` | e.g. `"no2"` | duck typing per call site |
| `kind` | `"temporal"` / `"static"` | year-column duck typing |
| `shape` | `"circle"` / `"diamond"` / `"cross"` | filename/config guessing |
| `label_col` | `"Label"` / `"School"` / NULL | column duck typing |
| `id` | layer id string | filename auto-generation |

Constructor `qm_layer(data, value_col, kind = "temporal", ...)` validates the
contract and fails with a plain-English error naming the missing column. A
`print.qm_layer()` method summarises: `qm_layer 'merton_dt': 61 sites x 3 time
steps of no2 (circle)`.

### Why this beats the alternatives

- **vs sf as-is**: identical user-facing behaviour (a `qm_layer` *is* an sf
  object — dplyr, sf ops, printing all still work), but the contract gets one
  enforcement point with friendly errors, and metadata gets a home. The
  duck-typing that users like (School column ⇒ schools layer) moves *into the
  wrappers*, where it runs once, instead of being sprinkled through the render
  pipeline.
- **vs plain list**: a list `list(data = sf, pollutant = ...)` hides the data
  one level down, breaks piping and `head()`/`View()` inspection, and is
  exactly the kind of opaque intermediate object that makes R feel arcane.
  Rejected on the package philosophy directly.
- **vs grammar (ggplot2 / tmap style)**: front-loads three concepts before the
  first map; animation still needs our own machinery; and our layers carry
  *data-bound* semantics (a pollutant time series) rather than *aesthetic
  mappings*, which `aes()` fits poorly. Rejected per survey, as CLAUDE.md
  anticipated.

### The progressive curve, concretely

```r
# two lines, zero new concepts (create_pollution_map stays as the friendly wrapper)
library(quickmap)
quickmap(from_csv("tubes_2018_2024.csv"))

# more control: several layers, explicit styling
quickmap(
  list(from_csv("tubes.csv"), from_rdata("bl.Rdata", "no2"), from_csv("schools.csv")),
  boroughs = "Merton", colour_scale = "who_no2", theme_file = "merton.yaml"
)

# expert: hand-built layer from any source
d <- my_database_pull() |> qm_layer(value_col = "pm25", kind = "temporal")
quickmap(d, boroughs = "Richmond")
```

`quickmap()` accepts a single `qm_layer` or a list; a bare file path or sf
object gets passed through the appropriate wrapper automatically, so users can
defer learning `from_*` until they need it. `create_pollution_map()` becomes a
thin compatibility wrapper (roadmap item 4).

### Open questions for the user

1. **Time column name**: keep `year_str` (zero churn, misleading name for
   sub-annual data) or rename to `time_label` in the formal contract with
   `year_str` accepted and normalised by the constructor during transition?
   Recommendation: rename in the contract, normalise in the constructor.
2. **Colour scale binding**: leave scales entirely to `quickmap()` styling
   (current plan, recommended) or allow an optional `scale` attribute on the
   layer as a hint? Recommendation: keep scales out of the atomic unit.
3. **Constructor name**: `qm_layer()` vs `quickmap_layer()`. Recommendation:
   `qm_layer()` (short, tab-completes beside `quickmap()`).

## Next step

STOP per CLAUDE.md. Implementation (constructor + validators + `from_csv` /
`from_rdata` / `from_openair` wrappers on a feature branch) begins only after
explicit user approval of this design, as a separate PR from this document.

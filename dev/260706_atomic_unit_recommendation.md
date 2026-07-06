# Atomic data unit — survey and recommendation (roadmap item 3)

**Date**: 2026-07-06 · **Revision 3** (rev 2: `kind` dropped — derived, not
declared; time-column inference contract added; parsing placed in the `from_*`
wrappers. rev 3: naming pass — `siteCode` → `code`, `year_str` → `time_label`,
layer `id` → `name`, coordinate duplication dropped; alias rule added) ·
**Status**: awaiting user design approval (STOP point)
**Author**: autonomous session, per CLAUDE.md "The atomic data unit — research
task before implementing"

User comments:

* considering atomic data unit recommendation, and the philosophy to to keep the API simple and progressive, do we need to distinguish between static and temporal data at all? if a time/date  column is present, doesn't this automatically indicate it is time varying?
  * **[resolved in rev 2]** Agreed — no user-facing distinction. Presence of a
    parseable time column ⇒ time-varying; "static" is just the degenerate case
    of ≤1 distinct time step, decided by a predicate at render time, not a
    stored flag. See "Derived, not declared" below.
* For Roadmap Step 5, check if any of the following technology stacks have been reviewed for suitability for our purpose of *plotting time varying point* data *on maps* that are *coloured by value/level* and making these *shareable* with *professional quality results*, e.g. *interactive maps of mutidimensional data*. Key criteria are: 
  * ability to change colours of objects by time slice (currenlty handled in quickmap using leaflet by hiding and revealing layers for each time slice), 
  * features optins of interactive time controller, 
  * allows multiple symbols to appear on a map in different colours, as well as having static layers overlaid on all.
  * ability to control tooltips or labels that appear by symbols, 
  * ability to overlay or underlay polygons of varying transparency, 
  * ability to have map underlays using opensource data suitable for public use, 
  * free or low cost tier (fee is preferred), 
  * Either: (a) produces compact files, does not require a client -server relationship OR (b) can be accessed by sending a link by email to see the product, without sending the file itself (the emailable self-contained file is not a requirement, as long as something can easily be emailed/whatsapped etc that shares the resulting maps and animations)
  * Is maintained and live or part of the wider non-R ecosystem.
  * Produces production standard results
  * This might examine any of
    * https://r-spatial.org/projects/
    * https://github.com/r-spatial/mapview?tab=readme-ov-file
    * https://plotly.com
    * https://r-spatial.github.io/mapview/
    * https://cran.r-project.org/web/views/Spatial.html
    * Any other R accessible technologies, eg RBokeh, Highcharter, Mapdeck, MapGL, Deck.gl etc
  * **[noted — belongs to roadmap item 5]** This comment supersedes/extends the
    candidate list in dev/260705_rendering_backend_candidates.md and relaxes
    the self-contained-file constraint to "easily shareable (file OR link)".
    It will be folded into the item-5 comparison brief; not part of this
    atomic-unit design.







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

Required columns (rev-3 names; same shape as today): `code`, `time_label`
(when time-varying), one value column, `lat`, `lon`, `geometry`. Static layers
(schools) use the same shape with a categorical value column and no time
column.

Attributes (set once by the wrappers, never re-inferred):

| attribute | values | today's source |
|---|---|---|
| `value_col` | e.g. `"no2"` | duck typing per call site |
| `time_col` | column name / NULL | year-column duck typing |
| `shape` | `"circle"` / `"diamond"` / `"cross"` | filename/config guessing |
| `label_col` | `"Label"` / `"School"` / NULL | column duck typing |
| `name` | human-visible layer name | filename auto-generation |
| `resolution` | `"year"`/`"month"`/`"day"`/`"hour"`/`"minute"` / NULL | ad-hoc format checks |

*(Rev 2: the rev-1 `kind = "temporal"/"static"` attribute is removed — see
"Derived, not declared". Rev 3: rev-1/2 `id` renamed `name`.)*

Constructor `qm_layer(data, value_col, ...)` validates the contract and fails
with a plain-English error naming the missing column. A `print.qm_layer()`
method summarises: `qm_layer 'merton_dt': 61 sites x 3 time steps of no2
(circle)`.

### Naming pass (rev 3) — elements are called what they are

Principle: names must say what the element is, in plain language, with no
dataset-specific heritage. Decisions:

| old | rev 3 | rationale |
|---|---|---|
| `siteCode` | **`code`** | The stable unique key linking a marker across time steps (UK convention: codes survive name misspellings — the concept generalises, the "site" qualifier doesn't). Matches openair `importMeta()`'s `code` column, so `from_openair()` maps with zero renaming. Keeps `id` free. Rejected: `site_id` (half-generalised), `identifier` (long, adds nothing), `id_code` (redundant compound), `location_id` (wrong — co-located sensors must stay distinct), `key` (DBA jargon). |
| `year_str` | **`time_label`** | Neither necessarily a year nor meaningfully "str". It is the display text for the time step — what the roller menu shows. |
| *(new)* | **`time_sort`** | POSIXct sort key parsed from the label (formalises v0.9.4 sorting). Open sub-question: stored column vs derived on demand — decide at implementation. |
| layer `id` | **`name`** | It is the human-visible layer name (legends, controls, errors) — "id" is too vague. |
| `Longitude`/`Latitude` + `lat`/`lon` | **`lat`/`lon` only** | The contract must not carry the same fact twice. `lat`/`lon` matches openair; `geometry` remains the sf source of truth. Internal code may add transient duplicates but they are not part of the contract. |
| pollutant value column (`no2`, `pm25`, …) | unchanged | openair convention; the column *is* the pollutant. The `value_col` attribute points at it. |
| `Label` / `School` | unchanged (read, not renamed) | User-supplied CSV headers; the wrappers read them into `label_col`. |

**Alias rule (transition)**: constructors and wrappers accept the legacy names
as recognised aliases and normalise silently — `siteCode` → `code`, `year_str`
→ `time_label`, `Longitude`/`Latitude` → `lat`/`lon` — so every existing RData
file, CSV and script keeps working without edits. Aliases are normalised at
construction (in the `from_*` parsing functions, per rev 2); downstream code
sees only canonical names. The alias list is a documented constant, not
scattered `if`s.

### Derived, not declared (rev 2)

The design principle, sharpened by the user's question: **the atomic unit
carries data plus only what cannot be inferred from it — and almost everything
can be inferred.** In particular there is no temporal/static kind:

- A layer *is* time-varying iff its time column has >1 distinct value. That is
  a one-line predicate evaluated where needed (`n_distinct(time) > 1`), not
  stored state that can go stale. One year of diffusion tubes renders exactly
  like a static layer — no time control — which falls out of the count, not a
  flag.
- `shape`, `label_col`, `id` follow the same pattern: inferred by the wrapper
  (School column ⇒ cross + School labels; Label column ⇒ custom labels;
  filename ⇒ id), stored so inference runs once, overridable by an explicit
  argument for the exceptional case. Progressive disclosure: the arguments
  exist, but nobody needs them on day one.

### Time-column inference contract (rev 2)

Which column is "time", given inputs ranging from a bare `YYYY` header to full
ISO datetimes? Best practice (openair, readr/lubridate) is layered — class,
then name, then content — and never content-sniffing arbitrary columns:

1. **Class**: a column of class `Date`/`POSIXct` is the time column regardless
   of name. Unambiguous; covers OpenAir (which mandates a `date` POSIXct
   column) and database pulls.
2. **Name gate**: a column named `date`, `time`, `datetime` (case-insensitive)
   or `year_str` (back-compat) earns a *parse attempt* — the name grants
   candidacy, the parse validates it.
3. **Content grammar**, most-specific first, applied only inside that gate
   (`lubridate::parse_date_time(orders = ...)`):
   `YYYY-MM-DD HH:MM(:SS)(+ZZ)` (T separator ok) → `YYYY-MM-DD` → `YYYY-MM` →
   `YYYY`. The matched format records the layer's **resolution**, which drives
   the display-label format; the parsed value provides the **sort key** for
   the time control (formalising the v0.9.4 ad-hoc sorting).
4. **Wide CSV headers**: column *names* matching `^\d{4}$` are year columns to
   pivot (existing behaviour — still name-based inference, on headers).
5. Nothing matches ⇒ static layer.

Refusals, deliberately:

- **No date-likeness scanning of arbitrary columns.** A numeric column of
  `2018, 2019, 2021` is indistinguishable from measurements; that is where
  inference schemes rot.
- **A `date`-named column that fails the grammar is a loud error** naming the
  column and the first offending value — never a silent fall-through to
  static.
- **Bare `HH` / cyclic values (diurnal profiles) are excluded from the
  grammar** — `07` as time-of-day is exactly the ambiguity that breaks
  guessing. They are served by the explicit override instead: the animation
  machinery needs an *ordered label set*, not real dates, so
  `qm_layer(d, time_col = "hour")` accepts any ordered column when the user
  says so.

**Where the parsing lives**: in the parsing/wrapper functions (`from_csv`,
`from_rdata`, `from_openair`, `from_worldmet`, `from_yaml`), not in the
renderer and not scattered through the pipeline. Each wrapper normalises its
input's native time representation (CSV year headers, RData `year_str`
strings, OpenAir `date` POSIXct, worldmet hourly `date`) into the canonical
time column + resolution + sort key at construction time; downstream code
never re-parses. `qm_layer()` itself re-runs only the validation, so a
hand-built layer gets the same guarantees.

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

# expert: hand-built layer from any source (time column auto-detected;
# time_col= only needed for non-date orderings like diurnal hours)
d <- my_database_pull() |> qm_layer(value_col = "pm25")
quickmap(d, boroughs = "Richmond")
```

`quickmap()` accepts a single `qm_layer` or a list; a bare file path or sf
object gets passed through the appropriate wrapper automatically, so users can
defer learning `from_*` until they need it. `create_pollution_map()` becomes a
thin compatibility wrapper (roadmap item 4).

### Open questions for the user

1. **Time column name**: ~~keep `year_str` or rename?~~ **Resolved in rev 3**:
   `time_label` is canonical, `year_str` a recognised alias (see "Naming
   pass").
2. **Colour scale binding**: leave scales entirely to `quickmap()` styling
   (current plan, recommended) or allow an optional `scale` attribute on the
   layer as a hint? Recommendation: keep scales out of the atomic unit.
3. **Constructor name**: `qm_layer()` vs `quickmap_layer()`. Recommendation:
   `qm_layer()` (short, tab-completes beside `quickmap()`).

## Next step

STOP per CLAUDE.md. Implementation (constructor + validators + `from_csv` /
`from_rdata` / `from_openair` wrappers on a feature branch) begins only after
explicit user approval of this design, as a separate PR from this document.

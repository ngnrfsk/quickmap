# quickmap

Clean, interactive air quality maps you can email or publish, from a
two-line call.

QuickMap takes the data you already have — a diffusion-tube CSV, an Excel
export, a sensor-network RData object, an OpenAir pull — and produces a
self-contained interactive HTML map, optionally animated over time, plus a
print-resolution static image of the same map. It is built for local
authority officers and air quality consultants producing reports and
public-facing communications, and asks no deep R knowledge.

```r
library(quickmap)

# a usable map
quickmap("wandsworth_2017_2024.csv", boroughs = "Wandsworth")

# more layers, more control
quickmap(
  list("merton_dt_2018_2024.csv", "bl_sensors.Rdata", "schools_Merton.csv"),
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "Merton NO2",
  output_file = "merton_no2.html"
)
```

Each added argument unlocks more: colour scales as YAML, borough
boundaries, per-layer marker symbols, marker labels, a wind overlay,
themes, and a static export sized for the printed page.

## Where QuickMap fits

R already has strong mapping packages, and QuickMap does not try to
replace them. It exists because one combination is not otherwise
available: **an animated, self-contained HTML map of a monitoring network,
with publication chrome, plus a matching print-resolution image.**

- **tmap** is excellent for cartography and highly customisable, but its
  animation (`tm_facets()` + `tmap_animation()`) produces GIF or video
  rather than interactive HTML with a time control, so it cannot deliver
  the core temporal feature. Its grammar also asks the reader to learn
  shape/layer separation and the scale system before the first map.
- **mapview** is the fastest way to explore spatial data interactively and
  has the gentlest learning curve in the R spatial ecosystem, but it has
  no temporal animation and is built for exploration rather than
  publication output.
- **openairmaps** is the closest in subject matter, mapping UK air quality
  networks with polar-analysis markers and trajectory paths on leaflet.
  It maps analysis markers and network locations rather than animated
  concentration maps with configurable chrome.
- **leaflet** is the substrate QuickMap builds on. Everything above the
  base map — the banner, colour-ramp legend, time slider, network
  indicator — is QuickMap's own.

Marker symbol and specification control was also weighed: none of the
above gives the per-layer symbol choice these maps need (circles for
tubes, diamonds for sensors, crosses for schools, all on one map with one
colour scale).

QuickMap is a spatial companion to
[OpenAir](https://openair-project.github.io/book/), which analyses and
fetches UK measurement data; QuickMap maps it.

## Output that survives being shared

Maps are written with all JavaScript and CSS inlined, so a map is one HTML
file that opens offline and attaches to an email. The same call can write
a JPG of every time step for a report or a printed action plan.

Above roughly 50 time steps, markers are rendered on canvas and restyled
from a single embedded JSON payload rather than pre-building a layer per
step, which keeps long animations small enough to send.

## Installation

```r
# install.packages("devtools")
devtools::install_github("ngnrfsk/quickmap")
```

## Documentation

The manual is the package vignettes: start with *Get started*, then
*Layers*, *Time and animation*, *Styling and themes*, *Labels*,
*Boundaries*, *Wind*, *Sharing and export*, *Recipes*, and *For R users*
for the layer contract.

Design decisions behind the package are recorded in `dev/`, notably the
atomic-unit survey (`dev/260706_atomic_unit_recommendation.md`, which
covers tmap and mapview in more detail) and the rendering-backend
comparison (`dev/item5_backend-comparison_v1.md`).

## Licence

MIT. Data licences belong to their sources; QuickMap prints a layer's
required attribution on the map when the layer carries one.

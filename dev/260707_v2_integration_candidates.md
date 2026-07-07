# Post-1.0 ecosystem integration candidates (v>1 roadmap note)

**Date:** 2026-07-07 · **Status:** recorded for the post-1.0 roadmap
(user request, 2026-07-07). Advisory survey — maintenance/user-base claims
should be re-verified when each item is picked up.

## Selection criteria

Well-maintained R or Python suites in meteorology, spatial data analysis,
or air pollution with a large user base, that QuickMap could link into.
Each candidate is shaped to land the way the architecture already expects:
as a `from_*()` wrapper producing a `qm_layer` (or `qm_wind`), or as a new
layer type — never as a change to the map API. Ranked by fit.

## 1. OpenAQ — `openaq` (Python client) / `ropenaq` (R)

- **What:** the global open air-quality data platform, aggregating
  government and research monitors across ~100 countries. Nonprofit-backed,
  active, modern v3 REST API with reference-grade/low-cost flags.
- **Why link:** `from_openaq()` is the single biggest internationalisation
  step available: same two-line map, any city in the world. Directly serves
  the "beyond v1.0: any time-varying, location-based data" positioning.
- **Shape:** `from_openaq(city/bbox, parameter, date range)` → fetch via
  API → long format → `qm_layer` (diamond). Needs an API key (free tier).
- **Risks/notes:** the R client (`ropenaq`) has historically lagged the
  Python client and the v3 API migration — verify R-side maintenance at
  pickup; a thin native httr2 client may be less work than depending on it.

## 2. `saqgetr` (R, Stuart Grange)

- **What:** pre-harmonised European air-quality observations (EEA
  AQ e-Reporting archives and predecessors) served as ready-to-use tables
  in openair-compatible long format.
- **Why link:** culturally the closest fit — it is from the openair orbit,
  so `from_saqgetr()` is nearly free given `from_openair()` exists
  (same column vocabulary). Extends QuickMap from UK to EU local
  government: the same user persona, the same reporting workflows.
- **Shape:** `from_saqgetr(site/country, variable, years)` → its
  `get_saq_observations()` output → `from_openair()` internals → `qm_layer`.
- **Risks/notes:** single-maintainer package; data service continuity
  depends on the maintainer's hosted archive. Check both at pickup.

## 3. ERA5 reanalysis — `ecmwfr` (R, rOpenSci) / `cdsapi` (Python)

- **What:** the standard route to Copernicus Climate Data Store downloads,
  including ERA5 gridded U/V wind at 0.25°, hourly, global, 1940→present.
  rOpenSci-reviewed (ecmwfr); enormous climate-science user base.
- **Why link:** already implicitly on the books — the post-1.0 wind note in
  CLAUDE.md names gridded reanalysis (ERA5) as the alternative source for
  non-uniform wind fields, and the vendored leaflet-velocity renderer is
  already resolution-independent (geometry-cached fast path). `from_era5()`
  upgrades wind from one-station-uniform to a true spatial field with no
  renderer work.
- **Shape:** `from_era5(bbox, times)` → CDS request (user's CDS key) →
  NetCDF → per-step U/V grids → the existing `qm_wind`/payload pipeline.
  Payload budget (grid cells × steps) is the binding constraint, as
  recorded in the wind roadmap note.
- **Risks/notes:** CDS queue latency makes it a pre-fetch step, not an
  interactive call; document as such.

## 4. Mazama Science suite — `AirMonitor` + `AirSensor` (R)

- **What:** the US monitoring ecosystem: `AirMonitor` wraps regulatory data
  (AirNow/AQS/WRCC/AIRSIS), `AirSensor` wraps PurpleAir low-cost sensors;
  tidy time-series structures conceptually close to openair. Maintained by
  Mazama Science under US-agency-adjacent funding (wildfire smoke
  programmes drive active use).
- **Why link:** the US-market equivalent of the Breathe London
  integration. `from_airmonitor()` opens QuickMap to US air districts —
  the same local-government persona — and PurpleAir support answers the
  most common community-sensor request worldwide.
- **Shape:** their `mts_monitor` objects carry meta (lon/lat) + data
  (time × site) tables → pivot → `qm_layer`. Clean mapping.
- **Risks/notes:** two wrappers really (regulatory + PurpleAir); PurpleAir
  API terms/keys change periodically.

## 5. Raster underlays — `stars` / `terra` (R core spatial)

- **What:** the foundational R raster/datacube packages (successors to
  `raster`), heavily maintained (Pebesma; Hijmans), used by essentially all
  spatial R workflows.
- **Why link:** not a data network but the mainstream spatial-analysis
  linkage: accept a raster (modelled concentration surface, LAEI grid,
  dispersion-model output) as a **map underlay** beneath the marker layers.
  This lets QuickMap show *modelled* alongside *measured* air quality — a
  frequent consultant workflow — and generalises to any gridded layer.
- **Shape:** a new static layer type, not a `from_*()` fetch:
  `qm_raster(terra/stars object, palette, opacity)` rendered via
  `leaflet::addRasterImage()` (already supported by leaflet). Temporal
  rasters (one grid per display time) would ride the lazy-payload
  architecture — budget analysis needed, same trade as wind grids.
- **Risks/notes:** file-size is the real constraint for self-contained
  output (mode a); a PNG-tile-per-step approach may be needed. Scope
  carefully.

## Honourable mention — MetPy (Python, Unidata)

Strongest met-analysis suite by user base (NSF-funded, very active), but
bridging Python into an R package via reticulate costs more than any
R-native option above. Better treated as a data-interop target: accept its
NetCDF/CSV exports as inputs to `from_*()` wrappers rather than integrating
the library.

## Suggested ordering when picked up

ERA5 (3) first — it completes an already-recorded roadmap thread with no
renderer work; then saqgetr (2) as the cheapest market extension; then
OpenAQ (1) for global reach; AirMonitor/AirSensor (4) when a US user
materialises; rasters (5) as its own design exercise (payload budget).

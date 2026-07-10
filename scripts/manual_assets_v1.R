# Manual assets: generates the LIVE maps embedded as iframes in the manual
# pages (into vignettes/maps/, gitignored — regenerate before
# pkgdown::build_site()) plus the static screenshots in vignettes/figures/.
# Replaces scripts/manual_screenshots_v2.R.
# Run from the repo root: Rscript scripts/manual_assets_v1.R
library(quickmap)

dir.create("vignettes/maps", showWarnings = FALSE)
dir.create("vignettes/figures", showWarnings = FALSE)

emit <- function(html) {
  file.copy(file.path("aq_maps", html), file.path("vignettes/maps", html),
            overwrite = TRUE)
  cat(html, file.size(file.path("vignettes/maps", html)), "bytes\n")
}

# Get started: the one-argument map (no boundary)
quickmap(
  "wandsworth_2017_2024_csv.csv",
  output_file = "getstarted-first.html"
)
emit("getstarted-first.html")

# Get started: + boundary (vignette on by default)
quickmap(
  "wandsworth_2017_2024_csv.csv",
  boroughs = "Wandsworth",
  output_file = "getstarted-boundary.html"
)
emit("getstarted-boundary.html")

# Get started: several measurement networks + schools
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: tubes, sensors and schools",
  output_file = "getstarted-networks.html"
))
emit("getstarted-networks.html")

# Get started: the animation finale
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "Sensors"),
  boroughs     = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  title        = "PM2.5 Episode: Jan 15-20, 2024",
  output_file  = "getstarted-episode.html",
  autoplay     = TRUE,
  play_speed   = 500
)
emit("getstarted-episode.html")

# Get started: animation + wind overlay (needs worldmet + network; skipped
# cleanly offline — the page's iframe then shows the last generated copy)
if (requireNamespace("worldmet", quietly = TRUE)) {
  heathrow <- tryCatch(
    from_worldmet(station = "037720-99999", year = 2024),
    error = function(e) NULL
  )
  if (!is.null(heathrow)) {
    heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]
    quickmap(
      from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25",
                 name = "Sensors"),
      boroughs     = c("Wandsworth", "Richmond"),
      colour_scale = "stripes_pm25",
      title        = "PM2.5 Episode with wind: Jan 15-20, 2024",
      output_file  = "getstarted-wind.html",
      autoplay     = TRUE,
      play_speed   = 500,
      wind         = heathrow
    )
    emit("getstarted-wind.html")
  }
}

# Layers page: the three-layer example
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: tubes, sensors and schools",
  output_file = "layers-multilayer.html"
))
emit("layers-multilayer.html")

# Static screenshot still used by the Get started data-table section
webshot2::webshot(
  "aq_maps/getstarted-boundary.html",
  file = "vignettes/figures/getstarted-first-map.png",
  vwidth = 992, vheight = 744, delay = 3
)
cat("getstarted-first-map.png regenerated\n")

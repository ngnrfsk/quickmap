# Manual screenshots (prospectus §3/§8a): render the maps shown in the
# manual pages with package-default styling and capture PNGs into
# vignettes/figures/. Rerun whenever the rendered look changes.
# v2 (item 10 look + P8-P15 rework): regenerates all figures with the
# v0.9.9.5 chrome and adds the Get started animation finale.
# Run from the repo root: Rscript scripts/manual_screenshots_v2.R
library(quickmap)

dir.create("vignettes/figures", showWarnings = FALSE)

shot <- function(html, png, delay = 3) {
  webshot2::webshot(
    file.path("aq_maps", html),
    file = file.path("vignettes/figures", png),
    vwidth = 992, vheight = 744, delay = delay
  )
  cat(png, file.size(file.path("vignettes/figures", png)), "bytes\n")
}

# Get started §2: the first map (all defaults)
quickmap(
  "wandsworth_2017_2024_csv.csv",
  boroughs = "Wandsworth",
  output_file = "manual_getstarted-first-map.html"
)
shot("manual_getstarted-first-map.html", "getstarted-first-map.png")

# Get started §6: the animation finale (exactly the page's chunk)
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "Sensors"),
  boroughs     = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  title        = "PM2.5 Episode: Jan 15-20, 2024",
  output_file  = "manual_getstarted-episode.html",
  autoplay     = TRUE,
  play_speed   = 500
)
shot("manual_getstarted-episode.html", "getstarted-episode.png", delay = 5)

# Layers: three layers, default styling
quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: tubes, sensors and schools",
  output_file = "manual_layers-multilayer.html"
)
shot("manual_layers-multilayer.html", "layers-multilayer.png")

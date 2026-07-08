# Manual screenshots (prospectus §3/§8a): render the maps shown in the
# manual pages with package-default styling and capture PNGs into
# vignettes/figures/. Rerun whenever the rendered look changes.
# Run from the repo root: Rscript scripts/manual_screenshots_v1.R
library(quickmap)

dir.create("vignettes/figures", showWarnings = FALSE)

shot <- function(html, png) {
  webshot2::webshot(
    file.path("aq_maps", html),
    file = file.path("vignettes/figures", png),
    vwidth = 992, vheight = 744, delay = 3
  )
  cat(png, file.size(file.path("vignettes/figures", png)), "bytes\n")
}

# Get started: the two-line map (defaults throughout)
quickmap(
  "wandsworth_2017_2024_csv.csv",
  boroughs = "Wandsworth",
  output_file = "manual_getstarted-first-map.html"
)
shot("manual_getstarted-first-map.html", "getstarted-first-map.png")

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

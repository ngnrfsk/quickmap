# Item 9 shape-wiring demonstration maps (v0.9.8.1).
# Run from the repo root: Rscript scripts/item9_demo-maps_v1.R
# Compare against the signed-off set in aq_maps/baseline_260707_item8_signed_off/:
#  - item9_merton-shapes_v1.html vs item6_merton-annual_v1.html
#    (BL sensors: squares -> diamonds; schools: plus -> simple-cross)
#  - item9_episode-diamonds_v1.html vs item6_episode-lazy_v1.html
#    (BL sensors: circles -> diamonds)
library(quickmap)

# 1. Annual multi-layer map: the three from_* conventions now render
#    (tubes circle, sensors diamond, schools simple-cross).
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "item9_merton-shapes_v1.html",
  title = "Merton NO2 2020-2022 (item 9: layer shapes wired)",
  vignette = TRUE,
  marker_labels = "labels"
))

# 2. Episode animation (lazy path): BL sensors now diamonds.
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item9_episode-diamonds_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024 (item 9: diamonds)",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500
)

for (f in c("item9_merton-shapes_v1.html", "item9_episode-diamonds_v1.html")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

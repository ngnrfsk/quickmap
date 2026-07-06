# Item 6 demonstration maps (lazy loading + time step cap).
# Run from the repo root: Rscript scripts/item6_demo-maps_v1.R
# Outputs land in aq_maps/. Compare against aq_maps/baseline_260705_signed_off/
# and item5_leaflet-episode-reference_v1.html.
library(quickmap)

# 1. Sub-annual episode (108 hourly steps) — LAZY path. The headline map:
#    the published 3.46 MB product now ~0.91 MB. Compare side-by-side with
#    item5_leaflet-episode-reference_v1.html.
create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item6_episode-lazy_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500
)

# 2. Annual multi-year with schools + labels — LEGACY path (3 steps, below
#    thresholds). Must be visually identical to the signed-off baseline.
suppressWarnings(create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "item6_merton-annual_v1.html",
  title = "Merton NO2 Annual Mean",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels"
))

# 3. The same annual map FORCED onto the lazy path — direct legacy-vs-lazy
#    comparison of Canvas marker rendering (circles + squares + school
#    crosses, labels, vignette, legend) against map 2.
withr::with_options(list(quickmap.lazy_step_threshold = 1), {
  suppressWarnings(create_pollution_map(
    data_sources = list(
      "merton_dt_2018_2024.csv",
      "bl_imperial_annualised_2021_2025_with_missing.Rdata",
      "schools_Merton.csv"
    ),
    boroughs = "Merton",
    pollutant = "no2",
    display_times = 2020:2022,
    colour_scale = "who_no2",
    output_file = "item6_merton-annual-forced-lazy_v1.html",
    title = "Merton NO2 Annual Mean (lazy)",
    styling_type = "html",
    vignette = TRUE,
    marker_labels = "labels"
  ))
})

for (f in c(
  "item6_episode-lazy_v1.html",
  "item6_merton-annual_v1.html",
  "item6_merton-annual-forced-lazy_v1.html"
)) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

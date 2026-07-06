# Demonstration maps for roadmap item 2 (characterization test net).
# Run from the repo root: Rscript scripts/260706_item2_demo_maps.R
# Writes dated maps to aq_maps/ — compare against aq_maps/baseline_260705_signed_off/.
library(quickmap)

# annual multi-year with schools and labels (same fixture the tests pin)
create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "260706_item2_annual_merton.html",
  title = "Item 2 demo: Merton NO2 2020-2022",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels"
)

# canonical animation example (inst/examples/episode_example.R, map2):
# the ~3.5 MB slow-loading product published at
# parhillresearch.github.io/maps/episode.html
create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "260706_item2_episode.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500
)

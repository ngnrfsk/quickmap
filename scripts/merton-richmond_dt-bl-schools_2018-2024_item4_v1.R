# Demonstration maps for roadmap item 4 (quickmap() core API).
# Run from the repo root:
#   Rscript scripts/merton-richmond_dt-bl-schools_2018-2024_item4_v1.R
# Writes to aq_maps/ — compare against aq_maps/baseline_260705_signed_off/
# and aq_maps/260706_item2_*.html (output should be visually identical).
library(quickmap)

# annual multi-year with schools and labels — via the NEW quickmap() API
quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "merton_dt-bl-schools_2020-2022_item4_v1.html",
  title = "Item 4 demo: Merton NO2 2020-2022 (quickmap API)",
  vignette = TRUE,
  marker_labels = "labels"
)

# canonical sub-annual episode — via the compatibility wrapper (unchanged call)
create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "wandsworth-richmond_bl_2024jan_item4_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500
)

# two-line call
quickmap("merton_dt_2018_2024.csv", boroughs = "Merton",
         output_file = "merton_dt_2018-2024_item4_v1.html")

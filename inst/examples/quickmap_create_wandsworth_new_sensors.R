# Wandsworth sensor location map with proposed new sensors
# Migrated to the quickmap() API (roadmap item 8, v0.9.8)
library(quickmap)

# Wandsworth NO2 with proposed sensor locations
map_wandsworth_sensors <- quickmap(
  list(
    "wandsworth_2017_2024_no_labels.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "wandsworth_proposed_sensors.csv"
  ),
  boroughs = "Wandsworth",
  colour_scale = "lbw_no2",
  output_file = "wandsworth_sites_2017_2024_all.html",
  title = "LB Wandsworth Site Locations, 2017-2024. ● DT ◆ Breathe London ✖ Proposed",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00549F",
  boundary_labels = FALSE
)

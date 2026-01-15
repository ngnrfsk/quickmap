# Wandsworth sensor location map with proposed new sensors
# Updated for QuickMap v0.9.4

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

# Wandsworth NO2 with proposed sensor locations
map_wandsworth_sensors <- create_pollution_map(
  data_sources = list(
    "wandsworth_2017_2024_no_labels.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "wandsworth_proposed_sensors.csv"
  ),
  data_ids = c("dt", "bl_sensors", "proposed"),
  boroughs = "Wandsworth",
  pollutant = "no2",
  display_times = NULL,
  colour_scale = "lbw_no2",
  output_file = "wandsworth_sites_2017_2024_all.html",
  title = "LB Wandsworth Site Locations, 2017-2024. ● DT ◆ Breathe London ✖ Proposed",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00549F",
  boundary_labels = FALSE
)

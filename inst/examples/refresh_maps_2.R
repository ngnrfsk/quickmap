# ASR map generation script
# Updated for QuickMap v0.9.3.20

Sys.setenv(DATA_PATH = "~/Coding/Library/data")

if (!exists("create_pollution_map")) {
  source("R/quickmap.R")
}

# Wandsworth NO2 with ward labels
map_object <- create_pollution_map(
  data_sources = list("wandsworth_2017_2024_no_labels.csv"),
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = NULL,
  colour_scale = "who_no2",
  output_file = "lbw_no2_2017_2024_dt_ward_labels.html",
  title = "LB Wandsworth Annual Mean NO2 2017-2024",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = FALSE,
  boundary_labels = TRUE
)

map_object

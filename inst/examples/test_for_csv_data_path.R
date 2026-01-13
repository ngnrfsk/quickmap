# Test example for DATA_PATH environment variable
# Updated for QuickMap v0.9.3.20

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

# Test map with custom banner color
map_test <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  years = NULL,
  colour_scale = "who_no2",
  output_file = "test_data_path.html",
  title = "DATA_PATH Test Map",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#ff0000",
  boundary_labels = FALSE
)

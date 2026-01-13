# Debug examples - Updated for QuickMap v0.9.3.20

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

# Merton NO2 with schools
map_merton_no2 <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  years = 2022:2024,
  colour_scale = "stripes_no2",
  output_file = "debug_merton_no2.html",
  title = "Debug: Merton NO2 ✖ Schools ● DT ◆ BL",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  boundary_labels = FALSE
)

# Merton PM2.5 with schools and theme
map_merton_pm25 <- create_pollution_map(
  data_sources = list(
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "pm25",
  years = 2022:2024,
  colour_scale = "gla_pm25",
  output_file = "debug_merton_pm25.html",
  title = "Debug: Merton PM2.5 ✖ Schools ◆ BL",
  theme_file = "inst/themes/wandsworth.yaml",
  styling_type = "html",
  marker_labels = "labels",
  boundary_labels = FALSE
)

# Image export test
theme <- load_theme("inst/themes/wandsworth.yaml")
map_image_test <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  years = 2020,
  colour_scale = "who_no2",
  output_file = "debug_image_export.html",
  title = "Debug: Image Export Test",
  styling_type = "html",
  vignette = TRUE,
  export_image = TRUE,
  marker_labels = "labels",
  banner_colour = theme$palette$green,
  boundary_labels = FALSE
)

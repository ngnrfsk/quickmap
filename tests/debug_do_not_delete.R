# Source the main script
Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap_clean.R")

# ==============================================================================
# MAP 1: Merton NO2 (CSV + BL data with schools) 2018-2024
# ==============================================================================
map1_merton_no2 <- create_pollution_map(
  diffusion_tube_file = "richmond_1993_2024-1.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Richmond",
  pollutant = "no2",
  #  years = (2022:2024),
  colour_scale = "stripes_no2",
  output_file = "debug_richmond_dt_bl.html",
  title = "Streamline 2 debug - Richmond full data",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  boundary_labels = FALSE
)

map1_merton_pm25 <- create_pollution_map(
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "pm25",
  years = (2022:2024),
  colour_scale = "gla_pm25",
  output_file = "debug_merton_pm25_2018_2024_dt_bl.html",
  title = "debug 6 LB Merton Annual Mean PM2.5. ✖ Schools. Sensors: ◆ Breathe London.",
  theme_file = "inst/themes/wandsworth.yaml",
  styling_type = "html", # HTML banner + legend
  # vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  boundary_labels = FALSE
)

theme <- load_theme("inst/themes/wandsworth.yaml")

map1_merton_no2 <- create_pollution_map(
  diffusion_tube_file = "merton_dt_2018_2024.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  years = (2020), # All available years
  colour_scale = "who_no2",
  output_file = "debug_image_merton_no2_2018_2024_dt_bl.html",
  title = "debug 5 LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  export_image = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = theme$palette$green,
  boundary_labels = FALSE
)

# ==============================================================================
#### stop here!!!!! PRODUCTION CODE BELOW

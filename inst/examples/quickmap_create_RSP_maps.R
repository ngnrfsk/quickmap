# Create maps for Merton, Richmond and Wandsworth
# NO2 maps use CSV + BL data, PM2.5 maps use BL data only
# Merton includes schools overlay
#
# Updated for QuickMap v0.9.4 with display_times parameter
# Previous version archived as create_all_borough_maps_v090.R

# Set up data path
Sys.setenv(DATA_PATH = "~/Coding/Library/data")

# Source the main script
source("R/quickmap.R")

# API: data_sources list replaces individual file parameters
# data_ids optional (auto-generated from filenames)

# ==============================================================================
# MAP 1: Merton NO2 (CSV + BL data with schools) 2018-2024
# ==============================================================================
map1_merton_no2 <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  data_ids = c("dt", "bl_sensors", "schools"),
  boroughs = "Merton",
  pollutant = "no2",
  display_times = NULL, # All available time periods
  colour_scale = "who_no2",
  output_file = "merton_no2_2018_2024_dt_bl.html",
  title = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = "labels", # Show school names and data labels on hover
  banner_colour = "#5F3E94", # Merton purple
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 2: Wandsworth NO2 (CSV + BL data with schools) 2017-2024
# ==============================================================================
map2_wandsworth_no2 <- create_pollution_map(
  data_sources = list(
    "wandsworth_2017_2024_no_labels.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_wandsworth.csv"
  ),
  data_ids = c("dt", "bl_sensors", "schools"),
  data_symbols = c("circle", "diamond", "cross"),
  boroughs = "Wandsworth",
  pollutant = "no2",
  display_times = NULL, # All available time periods
  colour_scale = "lbw_no2",
  output_file = "wandsworth_no2_2017_2024_dt_bl_schools.html",
  title = "LB Wandsworth Annual Mean NO2, 2017-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = "labels", # Show school names and data labels on hover
  banner_colour = "#00549F", # Wandsworth blue
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 3: Richmond NO2 (CSV + BL data) 1993-2024
# ==============================================================================
map3_richmond_no2 <- create_pollution_map(
  data_sources = list(
    "richmond_1993_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata"
  ),
  data_ids = c("dt", "bl_sensors"),
  boroughs = "Richmond",
  pollutant = "no2",
  display_times = NULL, # All available time periods
  colour_scale = "lbrut_no2",
  output_file = "richmond_no2_1993_2024_dt_bl.html",
  title = "LB Richmond Annual Mean NO2, 1993-2024. Sensors: ● Diffusion Tubes ◆ Breathe London",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = "labels", # Show data labels on hover
  banner_colour = "#00824B", # Richmond green
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 4: Merton PM2.5 (BL data only with schools) 2021-2025
# ==============================================================================
map4_merton_pm25 <- create_pollution_map(
  data_sources = list(
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "your_schools_Merton.csv"
  ),
  data_ids = c("bl_sensors", "schools"),
  boroughs = "Merton",
  pollutant = "pm25",
  display_times = NULL, # All available time periods
  colour_scale = "gla_pm25",
  output_file = "merton_pm25_2022_2024_bl.html",
  title = "LB Merton Annual Mean PM2.5, 2022-2024. ✖ Schools. Sensors: ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = "labels", # Show school names and data labels on hover
  banner_colour = "#5F3E94", # Merton purple
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 5: Wandsworth PM2.5 (BL data only) 2021-2025
# ==============================================================================
map5_wandsworth_pm25 <- create_pollution_map(
  data_sources = list(
    "bl_imperial_annualised_2021_2025_with_missing.Rdata"
  ),
  data_ids = c("bl_sensors"),
  boroughs = "Wandsworth",
  pollutant = "pm25",
  display_times = NULL, # All available time periods
  colour_scale = "gla_pm25",
  output_file = "wandsworth_pm25_2021_2025_bl.html",
  title = "LB Wandsworth Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = "labels", # Show data labels on hover
  banner_colour = "#00549F", # Wandsworth blue
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 6: Richmond PM2.5 (BL data only) 2021-2025
# ==============================================================================
map6_richmond_pm25 <- create_pollution_map(
  data_sources = list(
    "bl_imperial_annualised_2021_2025_with_missing.Rdata"
  ),
  data_ids = c("bl_sensors"),
  boroughs = "Richmond",
  pollutant = "pm25",
  display_times = NULL, # All available time periods
  colour_scale = "gla_pm25",
  output_file = "richmond_pm25_2022_2024_bl.html",
  title = "LB Richmond Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = "labels", # Show data labels on hover
  banner_colour = "#00824B", # Richmond green
  boundary_labels = FALSE
)

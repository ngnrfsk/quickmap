# Create maps for Merton, Richmond and Wandsworth
# NO2 maps use CSV + BL data, PM2.5 maps use BL data only
# Merton includes schools overlay
#
# Updated for QuickMap v0.9.0 parameter changes
# See quickmap.R header lines 39-68 for migration guide

# Set up data path
Sys.setenv(DATA_PATH = "~/Coding/R projects/Library/data")

# Source the main script
source("quickmap.R")

# ==============================================================================
# Parameter Mapping v0.8.x → v0.9.0:
# - csv_data_file → diffusion_tube_file
# - oa_data_file → sensor_file
# - years_to_plot → years
# - vignette_overlay_on → vignette
# - show_marker_labels → marker_labels
# - show_boundary_labels → boundary_labels
# - html_page_title + banner_text → title (merged)
# - show_banner + show_legend + show_title → styling_type ("html" or "none")
# ==============================================================================

# ==============================================================================
# MAP 1: Merton NO2 (CSV + BL data with schools) 2018-2024
# ==============================================================================
map1_merton_no2 <- create_pollution_map(
  diffusion_tube_file = "merton_dt_2018_2024.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  years = NULL, # All available years
  colour_scale = "who_no2",
  output_file = "merton_no2_2018_2024_dt_bl.html",
  title = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$merton$purple,
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 2: Wandsworth NO2 (CSV + BL data) 2017-2024
# ==============================================================================
map2_wandsworth_no2 <- create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "schools_wandsworth.csv",
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = NULL, # All available years
  colour_scale = "lbw_no2",
  output_file = "wandsworth_no2_2017_2024_dt_bl_schools.html",
  title = "LB Wandsworth Annual Mean NO2, 2017-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$wandsworth$blue,
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 3: Richmond NO2 (CSV + BL data) 2017-2024
# ==============================================================================
map3_richmond_no2 <- create_pollution_map(
  diffusion_tube_file = "richmond_1993_2024.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Richmond",
  pollutant = "no2",
  years = NULL, # All available years
  colour_scale = "lbrut_no2",
  output_file = "richmond_no2_1993_2024_dt_bl.html",
  title = "LB Richmond Annual Mean NO2, 1993-2024. Sensors: ● Diffusion Tubes ◆ Breathe London",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$richmond$green,
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 4: Merton PM2.5 (BL data only with schools) 2021-2025
# ==============================================================================
map4_merton_pm25 <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "pm25",
  years = NULL, # All available years
  colour_scale = "gla_pm25",
  output_file = "merton_pm25_2022_2024_bl.html",
  title = "LB Merton Annual Mean PM2.5, 2022-2024. ✖ Schools. Sensors: ◆ Breathe London.",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$merton$purple,
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 5: Wandsworth PM2.5 (BL data only) 2021-2025
# ==============================================================================
map5_wandsworth_pm25 <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Wandsworth",
  pollutant = "pm25",
  years = NULL, # All available years
  colour_scale = "gla_pm25",
  output_file = "wandsworth_pm25_2021_2025_bl.html",
  title = "LB Wandsworth Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$wandsworth$blue,
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 6: Richmond PM2.5 (BL data only) 2021-2025
# ==============================================================================
map6_richmond_pm25 <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Richmond",
  pollutant = "pm25",
  years = NULL, # All available years
  colour_scale = "gla_pm25",
  output_file = "richmond_pm25_2022_2024_bl.html",
  title = "LB Richmond Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$richmond$green,
  boundary_labels = FALSE
)

# Create maps for Merton, Richmond and Wandsworth
# NO2 maps use CSV + BL data, PM2.5 maps use BL data only
# Merton includes schools overlay
#
# Updated for QuickMap v0.9.0 parameter changes
# See quickmap.R header lines 39-68 for migration guide

# Set up data path
Sys.setenv(DATA_PATH = "~/Coding/R projects/Library/data")

# Source the main script
source("R/quickmap.R")


# ==============================================================================
# MAP 2: Wandsworth NO2 (CSV + BL data) 2017-2024
# ==============================================================================
map2_wandsworth_no2 <- create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "wandsworth_proposed_sensors.csv",
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = NULL, # All available years
  colour_scale = "lbw_no2",
  output_file = "wandsworth_sites_2017_2024_all.html",
  title = "LB Wandsworth Site Locations, 2017-2024. Sensors: ● Diffusion Tubes ◆ Old Breathe London ✖ New Sensors",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  marker_labels = TRUE, # Auto-hide labels
  banner_colour = borough_palettes$wandsworth$blue,
  boundary_labels = FALSE
)

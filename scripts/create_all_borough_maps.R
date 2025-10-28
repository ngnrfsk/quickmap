# Create maps for Merton, Richmond and Wandsworth
# NO2 maps use CSV + BL data, PM2.5 maps use BL data only
# Merton includes schools overlay

# Set up data path
Sys.setenv(DATA_PATH = "~/Coding/R projects/Library/data")

# Source the main script
source("quickmap.R")

# ==============================================================================
# MAP 1: Merton NO2 (CSV + BL data with schools) 2018-2024
# ==============================================================================
map1_merton_no2 <- create_pollution_map(
  csv_data_file = "merton_dt_2018_2024.csv",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  years_to_plot = NULL, # All available years
  scale_to_use = "who_no2",
  output_file = "merton_no2_2018_2024_dt_bl.html",
  html_page_title = "LB Merton Annual Mean NO2, 2018-2024",
  banner_text = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  show_banner = TRUE,
  show_legend = FALSE, # Using HTML legend
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE, # Auto-hide labels
  banner_color = borough_palettes$merton$purple,
  border_color = borough_palettes$merton$purple,
  show_boundary_labels = FALSE
)

# ==============================================================================
# MAP 2: Wandsworth NO2 (CSV + BL data) 2017-2024
# ==============================================================================
map2_wandsworth_no2 <- create_pollution_map(
  csv_data_file = "wandsworth_2017_2024_no_labels.csv",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Wandsworth",
  pollutant = "no2",
  years_to_plot = NULL, # All available years
  scale_to_use = "lbw_no2",
  output_file = "wandsworth_no2_2017_2024_dt_bl.html",
  html_page_title = "LB Wandsworth Annual Mean NO2, 2017-2024",
  banner_text = "LB Wandsworth Annual Mean NO2, 2017-2024. Sensors: ● Diffusion Tubes ◆ Breathe London",
  show_banner = TRUE,
  show_legend = FALSE, # Using HTML legend
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE, # Auto-hide labels
  banner_color = borough_palettes$wandsworth$blue,
  border_color = borough_palettes$wandsworth$blue,
  show_boundary_labels = FALSE
)

# ==============================================================================
# MAP 3: Richmond NO2 (CSV + BL data) 2017-2024
# ==============================================================================
map3_richmond_no2 <- create_pollution_map(
  csv_data_file = "richmond_1993_2024.csv",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Richmond",
  pollutant = "no2",
  years_to_plot = NULL, # All available years
  scale_to_use = "lbrut_no2",
  output_file = "richmond_no2_1993_2024_dt_bl.html",
  html_page_title = "LB Richmond Annual Mean NO2, 1993-2024",
  banner_text = "LB Richmond Annual Mean NO2, 1993-2024. Sensors: ● Diffusion Tubes ◆ Breathe London",
  show_banner = TRUE,
  show_legend = FALSE, # Using HTML legend
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE, # Auto-hide labels
  banner_color = borough_palettes$richmond$green,
  border_color = borough_palettes$richmond$green,
  show_boundary_labels = FALSE
)

# ==============================================================================
# MAP 4: Merton PM2.5 (BL data only with schools) 2021-2025
# ==============================================================================
map4_merton_pm25 <- create_pollution_map(
  csv_data_file = "none",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "pm25",
  years_to_plot = NULL, # All available years
  scale_to_use = "gla_pm25",
  output_file = "merton_pm25_2022_2024_bl.html",
  html_page_title = "LB Merton Annual Mean PM2.5, 2022-2024",
  banner_text = "LB Merton Annual Mean PM2.5, 2022-2024. ✖ Schools. Sensors: ◆ Breathe London.",
  show_banner = TRUE,
  show_legend = FALSE, # Using HTML legend
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE, # Auto-hide labels
  banner_color = borough_palettes$merton$purple,
  border_color = borough_palettes$merton$purple,
  show_boundary_labels = FALSE
)

# ==============================================================================
# MAP 5: Wandsworth PM2.5 (BL data only) 2021-2025
# ==============================================================================
map5_wandsworth_pm25 <- create_pollution_map(
  csv_data_file = "none",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Wandsworth",
  pollutant = "pm25",
  years_to_plot = NULL, # All available years
  scale_to_use = "gla_pm25",
  output_file = "wandsworth_pm25_2021_2025_bl.html",
  html_page_title = "LB Wandsworth Annual Mean PM2.5, 2022-2024",
  banner_text = "LB Wandsworth Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  show_banner = TRUE,
  show_legend = FALSE, # Using HTML legend
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE, # Auto-hide labels
  banner_color = borough_palettes$wandsworth$blue,
  border_color = borough_palettes$wandsworth$blue,
  show_boundary_labels = FALSE
)

# ==============================================================================
# MAP 6: Richmond PM2.5 (BL data only) 2021-2025
# ==============================================================================
map6_richmond_pm25 <- create_pollution_map(
  csv_data_file = "none",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "none",
  boroughs = "Richmond",
  pollutant = "pm25",
  years_to_plot = NULL, # All available years
  scale_to_use = "gla_pm25",
  output_file = "richmond_pm25_2022_2024_bl.html",
  html_page_title = "LB Richmond Annual Mean PM2.5, 2022-2024",
  banner_text = "LB Richmond Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  show_banner = TRUE,
  show_legend = FALSE, # Using HTML legend
  show_title = FALSE,
  vignette_overlay_on = TRUE,
  show_marker_labels = TRUE, # Auto-hide labels
  banner_color = borough_palettes$richmond$green,
  border_color = borough_palettes$richmond$green,
  show_boundary_labels = FALSE
)

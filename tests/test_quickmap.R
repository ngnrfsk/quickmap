# 2025 ASR map generation script ####
# Depends on quickmap.R

# check if quickmap.R is sourced otherwise source it
if (!exists("create_pollution_map") || TRUE) {
  # Try local first, then SCRIPTS_PATH
  if (file.exists("quickmap.R")) {
    source("quickmap.R")
  } else {
    source(file.path(Sys.getenv("SCRIPTS_PATH"), "quickmap.R"))
  }
}

 # create_pollution_map(
 #  csv_data_file = "none",
 #  oa_data_file = "none",
 #  boroughs,
 #  school_file = "none",
 #  output_file = "pollution_map.html", # if NULL no output file
 #  image_export = FALSE,
 #  scale_to_use = "who_no2",
 #  title_prefix = "",
 #  vignette_overlay_on = TRUE,
 #  years_to_plot = NULL,
 #  map_width_px = 1200,
 #  map_height_px = 1200,
 #  use_data_labels = FALSE,
 #  pollutant = "no2",
 #  html_page_title = "Air pollution map",
 #  show_legend = TRUE,
 #  show_title = TRUE)

# Test 1: Original map without new styling
# test_original <- create_pollution_map(
#   csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_csv_full_labels.csv",
#   boroughs = c("Wandsworth"),
#   output_file = "LBW_Map_NO2_dts_2017_2024_original.html",
#   image_export = FALSE,
#   scale_to_use = "lbw_no2",
#   vignette_overlay_on = TRUE,
#   use_data_labels = TRUE,
#   title_prefix = "<H2>LB Wandsworth Annual Average NO2, 2017-2024.</H2><p> <h3>Green dashes are ward boundaries ",
#   map_width_px = 1000,
#   map_height_px = 750,
#   html_page_title = "LB Wandsworth Annual Average Diffusion Tube NO2, 2017-2024",
#   pollutant = "no2",
#   show_title = FALSE,
#   show_legend = FALSE,
#   # New styling parameters - disabled for original test
#   show_banner = FALSE,
#   show_full_width_legend = FALSE
# )

# Test 2: Map with banner only
# test_banner <- create_pollution_map(
#   csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_csv_full_labels.csv",
#   boroughs = c("Wandsworth"),
#   output_file = "LBW_Map_NO2_dts_2017_2024_banner.html",
#   image_export = FALSE,
#   scale_to_use = "lbw_no2",
#   vignette_overlay_on = TRUE,
#   use_data_labels = TRUE,
#   title_prefix = "<H2>LB Wandsworth Annual Average NO2, 2017-2024.</H2><p> <h3>Green dashes are ward boundaries ",
#   map_width_px = 1000,
#   map_height_px = 750,
#   html_page_title = "LB Wandsworth Annual Average Diffusion Tube NO2, 2017-2024",
#   pollutant = "no2",
#   show_title = FALSE,
#   show_legend = FALSE,
#   # New styling parameters - banner only
#   show_banner = TRUE,
#   banner_text = "LB Wandsworth Air Quality Monitoring 2017-2024",
#   show_full_width_legend = FALSE
# )

# Test 3: Map with full-width legend only
# test_legend <- create_pollution_map(
#   csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_csv_full_labels.csv",
#   boroughs = c("Wandsworth"),
#   output_file = "LBW_Map_NO2_dts_2017_2024_legend.html",
#   image_export = FALSE,
#   scale_to_use = "lbw_no2",
#   vignette_overlay_on = TRUE,
#   use_data_labels = TRUE,
#   title_prefix = "<H2>LB Wandsworth Annual Average NO2, 2017-2024.</H2><p> <h3>Green dashes are ward boundaries ",
#   map_width_px = 1000,
#   map_height_px = 750,
#   html_page_title = "LB Wandsworth Annual Average Diffusion Tube NO2, 2017-2024",
#   pollutant = "no2",
#   show_title = FALSE,
#   show_legend = FALSE,
#   # New styling parameters - legend only
#   show_banner = FALSE,
#   show_full_width_legend = TRUE
# )

# Test 4: Map with both banner and full-width legend
test_full_styling <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_csv_full_labels.csv",
  boroughs = c("Wandsworth"),
  output_file = "test_full_styling.html",
  image_export = FALSE,
  scale_to_use = "lbw_no2",
  vignette_overlay_on = TRUE,
  use_data_labels = TRUE,
  title_prefix = "<H2>LB Wandsworth Annual Average NO2, 2017-2024.</H2><p> <h3>Green dashes are ward boundaries ",
  map_width_px = 1000,
  map_height_px = 750,
  html_page_title = "Full styling test",
  pollutant = "no2",
  show_title = FALSE,
  show_legend = FALSE,
  # New styling parameters - both banner and legend
  show_banner = TRUE,
  banner_text = "Full styling test",
  border_width = "5px"
)

# Test 5: Map with custom styling colors
# test_custom_styling <- create_pollution_map(
#   csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_csv_full_labels.csv",
#   boroughs = c("Wandsworth"),
#   output_file = "LBW_Map_NO2_dts_2017_2024_custom_styling.html",
#   image_export = FALSE,
#   scale_to_use = "lbw_no2",
#   vignette_overlay_on = TRUE,
#   use_data_labels = TRUE,
#   title_prefix = "<H2>LB Wandsworth Annual Average NO2, 2017-2024.</H2><p> <h3>Green dashes are ward boundaries ",
#   map_width_px = 1000,
#   map_height_px = 750,
#   html_page_title = "LB Wandsworth Annual Average Diffusion Tube NO2, 2017-2024",
#   pollutant = "no2",
#   show_title = FALSE,
#   show_legend = FALSE,
#   # New styling parameters - custom colors
#   show_banner = TRUE,
#   banner_text = "Custom Styled Air Quality Dashboard",
# #   border_color = "#FF6B6B",
#   border_width = "8px"
# )

# Display the test result
test_full_styling

# Print summary of tests
cat("\n=== STYLING TEST COMPLETED ===\n")
cat("Full styling test: LBW_Map_NO2_dts_2017_2024_full_styling.html\n")
cat("\nCheck the aq_maps/ folder for generated HTML file.\n")

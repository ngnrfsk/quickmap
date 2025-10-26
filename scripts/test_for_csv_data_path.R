# create_pollution_map <- function(
# initial parameters - file handling
# input files
#   csv_data_file = "none",
#   oa_data_file = "none",
#   school_file = "none",
# #output file names, image export and image size
#   output_file = "pollution_map.html", # name for the HTML and image files
# image_export = FALSE,
#   map_width_px = 1200,
#   map_height_px = 1200,
# # location parameters
#   boroughs,
# # data processing parameters
#   pollutant = "no2",
#   years_to_plot = NULL,
# # styling parameters
#   vignette_overlay_on = TRUE,
#   scale_to_use = "who_no2",
#   title_prefix = "",
#   use_data_labels = FALSE,
#   html_page_title = "Air pollution map",
#   show_legend = TRUE,
#   show_title = TRUE,
#   border_color = "#078141",
#   banner_color = "#078141", # Optional: green banner (or use "#2c3e50" for dark blue)
#   border_width = "5px",
#   show_banner = FALSE,
#   show_boundary_labels = FALSE,
#   banner_text = "Air Quality Map"
# )

# Test command for create_pollution_map() with new banner/legend system
map_object <- create_pollution_map(
  #  csv_data_file = "~/Coding/R projects/Library/data/merton_dt_2018_2024.csv",
  csv_data_file = "merton_dt_2018_2024.csv",
  oa_data_file = "bl_imperial_annualised_2021_2025_to_250422.Rdata",
  boroughs = c("Merton"),
  output_file = "test_for_csv_data_0_8_8.html",
  scale_to_use = "who_no2",
  map_width_px = 1800,
  map_height_px = 1200,
  image_export = FALSE,
  vignette_overlay_on = TRUE,
  pollutant = "no2",
  html_page_title = "test_for_csv_data_0_8_8", # @simplify - just use the banner text and drop?
  use_data_labels = FALSE,
  show_legend = FALSE, # Set FALSE - external HTML legend replaces leaflet legend @simplify redundant?
  show_banner = TRUE, # Enable banner
  banner_text = "test_for_csv_data", # New parameter
  banner_color = "#ff0000", # green: #078141, dark blue: #2c3e50
  show_title = FALSE # Set FALSE - banner replaces title
)

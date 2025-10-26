# 2025 ASR map generation script ####
# Depends on quickmap.R

# check if quickmap.R is sourced otherwise source it
if (!exists("create_pollution_map")) {
  source(file.path(Sys.getenv("SCRIPTS_PATH"), "quickmap.R"))
}


# create_pollution_map <- function(
#     csv_data_file = "none",
#     oa_data_file = "none",
#     boroughs,
#     school_file = "none",
#     output_file = "pollution_map.html", # if NULL no output file
#     image_export = FALSE,
#     scale_to_use = "who_no2",
#     title_prefix = "none",
#     vignette_overlay_on = TRUE,
#     legend_title = "Annual NO2, ug/m3",
#     years_to_plot = NULL,
#     map_width_px = 1200,
#     use_data_labels = FALSE,
#     pollutant = "no2",
#     map_title = "Air pollution map"
# )

# Test command for create_pollution_map() with new banner/legend system
map_object <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  boroughs = c("Wandsworth"),
  output_file = "test_for_quickmap_0_8_6_2.html",
  scale_to_use = "who_no2",
  image_export = FALSE,
  vignette_overlay_on = TRUE,
  pollutant = "no2",
  html_page_title = "LB Wandsworth Annual Mean NO2 2017-2024",
  use_data_labels = FALSE,
  show_legend = FALSE, # Set FALSE - external HTML legend replaces leaflet legend
  show_banner = TRUE, # Enable banner
  banner_text = "LB Wandsworth Annual Mean NO2 Levels 2017-2024", # New parameter
  banner_color = "#078141", # Optional: green banner (or use "#2c3e50" for dark blue)
  show_title = FALSE # Set FALSE - banner replaces title
)

# display the HMTL map to export to inspect before putting online

map_object

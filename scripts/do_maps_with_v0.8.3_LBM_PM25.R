# 2025 ASR map generation script ####
# Depends on quickmap.R

# check if quickmap.R is sourced otherwise source it
if (!exists("create_pollution_map")) {
  source("../versions/quickmap_0_8_7_3.R")
}

source("versions/quickmap_0_8_7_3.R")


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
  csv_data_file = "~/Coding/R projects/Library/data/merton_dt_2018_2024.csv",
  boroughs = c("Merton"),
  output_file = "LBM_Map_PM25_BL_2024.html",
  scale_to_use = "who_no2",
  map_width_px = 1800,
  map_height_px = 1200,
  image_export = TRUE,
  vignette_overlay_on = TRUE,
  pollutant = "no2",
  years_to_plot = c(2024),
  html_page_title = "LB Merton Annual Mean NO2 2024 (Diffusion Tubes)",
  use_data_labels = FALSE,
  show_legend = FALSE, # Set FALSE - external HTML legend replaces leaflet legend
  show_banner = TRUE, # Enable banner
  banner_text = "LB Merton Annual Mean NO2 2024 (Diffusion Tubes)", # New parameter
  banner_color = "#078141", # Optional: green banner (or use "#2c3e50" for dark blue)
  show_title = FALSE # Set FALSE - banner replaces title
)

# display the HMTL map to export to inspect before putting online

map_object

# Use latest create_pollution_map() to build new Merton maps
map_object <- create_pollution_map(
  #csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv",
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  # "~/Coding/R projects/Library/data/bl_imperial_annualised_2021_2025_to_250422.Rdata"
  boroughs = c("Merton"),
  output_file = "LBM_Map_PM25_BL_2024.html",
  map_width_px = 1800,
  map_height_px = 1200,
  scale_to_use = "gla_pm25",
  #  years_to_plot = c(2024),
  image_export = TRUE,
  vignette_overlay_on = TRUE,
  pollutant = "pm25",
  html_page_title = "LB Merton Annual Mean PM2.5 2021-2024 (Breathe London data > 80%)",
  use_data_labels = FALSE,
  show_legend = FALSE, # Set FALSE - external HTML legend replaces leaflet legend
  show_banner = TRUE, # Enable banner
  banner_text = "LB Merton Annual Mean PM2.5 2021-2024  (Breathe London data > 80%)", # New parameter
  banner_color = "#078141", # Optional: green banner (or use "#2c3e50" for dark blue)
  show_title = FALSE # Set FALSE - banner replaces title
)

# display the HMTL map to export to inspect before putting online

map_object_

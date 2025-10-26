# 2025 ASR map generation script ####
# Depends on quickmap.R

# check if quickmap.R is sourced otherwise source it
if (!exists("create_pollution_map")) {
  source("../quickmap.R")
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

# Richmond PM25 from BL data with vignette overlay
map_object <- create_pollution_map(
  csv_data_file = "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv", # takes off the CSV data
  boroughs = c("Wandsworth"),
  output_file = "lbw_no2_2017_2024_dt_ward_labels.html",
  image_export = FALSE,
  scale_to_use = "who_no2",
  #  legend_title = "Annual mean PM2.5, ug/m3",
  vignette_overlay_on = TRUE, # no vignette overlay for this map
  pollutant = "no2",
  html_page_title = "LB Wandsworth Annual Mean NO2 2017-2024",
  use_data_labels = FALSE,
  show_legend = TRUE,
  show_banner = FALSE,
  show_title = FALSE
)
# display the HMTL map to export to inspect before putting online

map_object

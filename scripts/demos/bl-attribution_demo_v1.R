# Item 12, Step 4: the licence attribution in the map chrome.
#
# The Breathe London API terms require published outputs carrying BL data to
# state the source and link to it. from_breathelondon() puts that statement
# on the layer, so any map showing the layer prints it under the legend.
# Until the new API key arrives this demo builds the same layer from the
# saved annualised file, attaching the attribution by hand exactly as
# from_breathelondon() does.
#
# Run from the project root:
#   Rscript scripts/demos/bl-attribution_demo_v1.R

library(quickmap)

data_path <- path.expand(Sys.getenv("DATA_PATH"))
stopifnot(nzchar(data_path))
load(file.path(data_path, "bl_imperial_annualised_2021_2025_to_250422.Rdata"))

merton <- quickmap:::get_boundary_sf("Merton")
pts <- sf::st_as_sf(dataOAformat, coords = c("lon", "lat"), crs = 4326,
                    remove = FALSE)
sensors <- dataOAformat[lengths(sf::st_intersects(pts, merton)) > 0, ]
sensors <- sensors[as.integer(as.character(sensors$year)) %in% 2021:2024, ]
sensors <- quickmap:::bl_qa_screen(sensors)

layer <- qm_layer(sensors, value_col = "pm25", time_col = "year",
                  shape = "diamond", name = "bl_sensors",
                  attribution = quickmap:::BL_ATTRIBUTION)

quickmap(
  layer,
  boroughs = "Merton",
  pollutant = "pm25",
  display_times = as.character(2021:2024),
  colour_scale = "gla_pm25",
  title = "Attribution demo: Merton PM2.5, Breathe London sensors",
  output_file = "item12_bl-attribution_v1.html"
)

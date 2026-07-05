# Required libraries: install.packages(c("mapgl", "sf", "dplyr", "tidyr"))
library(mapgl)
library(sf)
library(dplyr)
library(tidyr)

create_pollutant_map <- function(csv_path) {
  # 1. Load data with explicit NA handling for the empty cells (like your 2017 gaps)
  # check.names = FALSE keeps your "2026-01-01" headers from turning into "X2026..."
  raw_data <- read.csv(
    csv_path,
    na.strings = c("", "NA", " "),
    check.names = FALSE
  )

  # 2. Identify time columns (supporting 2017, 2026-01-01, or 26-10-01)
  cols <- names(raw_data)
  time_pattern <- "^(\\d{4}|\\d{2}-\\d{2}-\\d{2})"
  time_cols <- grep(time_pattern, cols, value = TRUE)

  # 3. Process into Long format for the MapLibre engine
  # We force numeric conversion so empty 2017 columns don't import as 'Character'
  map_data <- raw_data %>%
    mutate(across(all_of(time_cols), ~ as.numeric(as.character(.x)))) %>%
    pivot_longer(
      cols = all_of(time_cols),
      names_to = "time_step",
      values_to = "pollution_value"
    ) %>%
    filter(!is.na(Easting), !is.na(Northing)) %>%
    st_as_sf(coords = c("Easting", "Northing"), crs = 27700) %>% # OSGB36
    st_transform(4326) # WGS84 for web maps

  # 4. Create the map using the mapgl package (MapLibre backend)
  map <- maplibre(style = maptiler_style("basic")) %>%
    fit_bounds(map_data) %>%
    add_circle_layer(
      id = "pollution_layer",
      source = map_data,
      circle_color = interpolate(
        column = "pollution_value",
        values = c(0, 20, 40, 60),
        stops = c("green", "yellow", "orange", "red")
      ),
      circle_radius = 8,
      circle_stroke_color = "#ffffff",
      circle_stroke_width = 1,
      # This allows the map to filter by the 'time_step' column for animation
      filter = list("==", "time_step", time_cols[1])
    )

  return(map)
}

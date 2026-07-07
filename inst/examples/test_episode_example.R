# Longer-window variant of episode_example.R (Jan 12-20 2024, hourly PM2.5).
# Builds the episodeJan2024_* fixtures and renders the two-borough animation.
# Migrated to the quickmap() API (roadmap item 8, v0.9.8).
library(quickmap)

# ---- one-off data preparation ----------------------------------------------
data_path <- Sys.getenv("DATA_PATH")
fixture_all <- file.path(data_path, "episodeJan2024_sf_all.Rdata")
fixture_richmond <- file.path(data_path, "episodeJan2024_sf_richmond.Rdata")

if (!file.exists(fixture_all)) {
  load(file.path(data_path, "bl_imperial_210122-250422.Rdata"))

  start_time <- as.POSIXct("2024-01-12 15:00:00", tz = "UTC")
  end_time <- as.POSIXct("2024-01-20 03:00:00", tz = "UTC")

  subset_data <- subset(dataOAformat, date >= start_time & date < end_time)
  subset_data$code <- subset_data$siteCode

  subset_data_sf_all <- convert_openair_to_spatial(
    subset_data,
    pollutant = "pm25",
    avg.time = "hour"
  )
  subset_data_sf_all$year <- NULL

  # get_boundary_sf() is internal — borrowed here to clip the Richmond fixture
  borough_sf <- quickmap:::get_boundary_sf("Richmond")
  subset_data_sf_richmond <- sf::st_filter(subset_data_sf_all, borough_sf)

  save(subset_data_sf_all, file = fixture_all)
  save(subset_data_sf_richmond, file = fixture_richmond)
}

# ---- map: both boroughs, airstat theme ---------------------------------------
map2_test <- quickmap(
  from_rdata("episodeJan2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "map2_test_episode_240110_test.html",
  title = "PM2.5 Episode: Jan 10-20, 2024",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  boundary_labels = FALSE,
  autoplay = TRUE,
  play_speed = 500
)

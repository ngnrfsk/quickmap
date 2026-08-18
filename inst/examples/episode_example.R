# Canonical animation example: hourly PM2.5 episode, Jan 15-20 2024, all
# Breathe London sensors across Wandsworth + Richmond. map2 below is the
# reference map pinned by tests/testthat/test-characterization.R — its
# rendered output must stay stable across refactors.
#
# Migrated to the quickmap() API (roadmap item 8, v0.9.8). The historic
# create_pollution_map() call it replaces is a supported compatibility
# wrapper; see ?create_pollution_map.
library(quickmap)

# ---- one-off data preparation ----------------------------------------------
# Builds the episode fixtures from the full hourly BL export. The fixtures
# already exist in DATA_PATH, so this block is skipped on normal runs.
data_path <- Sys.getenv("DATA_PATH")
fixture_all <- file.path(data_path, "episodeJan15-20_2024_sf_all.Rdata")
fixture_richmond <- file.path(data_path, "episodeJan15-20_2024_sf_richmond.Rdata")

if (!file.exists(fixture_all)) {
  load(file.path(data_path, "bl_imperial_210122-250422.Rdata"))

  start_time <- as.POSIXct("2024-01-15 12:00:00", tz = "UTC")
  end_time <- as.POSIXct("2024-01-20 00:00:00", tz = "UTC")

  subset_data <- subset(dataOAformat, date >= start_time & date < end_time)
  subset_data$code <- subset_data$siteCode

  subset_data_sf_all <- convert_openair_to_spatial(
    subset_data,
    pollutant = "pm25",
    avg.time = "hour"
  )
  subset_data_sf_all$year <- NULL

  # get_boundary_sf() is internal — the prep step borrows it to clip the
  # Richmond-only fixture
  borough_sf <- quickmap:::get_boundary_sf("Richmond")
  subset_data_sf_richmond <- sf::st_filter(subset_data_sf_all, borough_sf)

  save(subset_data_sf_all, file = fixture_all)
  save(subset_data_sf_richmond, file = fixture_richmond)
}

# ---- map 1: Richmond only, default theme ------------------------------------
map1_test <- quickmap(
  from_rdata("episodeJan15-20_2024_sf_richmond.Rdata", "pm25",
             name = "bl_sensors"),
  boroughs = "Richmond",
  colour_scale = "stripes_pm25",
  output_file = "map1_test_episode_240115-20.html",
  output_dir = "aq_maps",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  vignette = TRUE,
  symbol_labels = TRUE,
  banner_colour = "#005794",
  boundary_labels = FALSE,
  autoplay = TRUE,
  play_speed = 500
)

# ---- map 2: both boroughs, airstat theme (the pinned reference map) ---------
map2_test <- quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25",
             name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "map2_test_episode_240115-20.html",
  output_dir = "aq_maps",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  vignette = FALSE,
  symbol_labels = TRUE,
  banner_colour = "#005794",
  boundary_labels = FALSE,
  autoplay = TRUE,
  play_speed = 500
)

# ---- optional wind overlay (v0.9.8) ------------------------------------------
# The same episode with an animated wind layer from Heathrow ISD data.
# Needs the worldmet package and a network connection:
# if (requireNamespace("worldmet", quietly = TRUE)) {
#   heathrow <- from_worldmet(station = "037720-99999", year = 2024)
#   heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]
#   quickmap(
#     from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25",
#                name = "bl_sensors"),
#     boroughs = c("Wandsworth", "Richmond"),
#     colour_scale = "stripes_pm25",
#     theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
#     output_file = "map2_test_episode_240115-20_wind.html",
#     title = "PM2.5 Episode: Jan 15-20, 2024",
#     symbol_labels = TRUE,
#     banner_colour = "#005794",
#     autoplay = TRUE,
#     play_speed = 500,
#     wind = heathrow
#   )
# }

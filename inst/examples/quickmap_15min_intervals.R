# Example: 15-minute interval temporal resolution
# Demonstrates sub-annual display_times with fine-grained time periods
# QuickMap v0.9.4

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

# Generate 15-minute intervals from 12:00 to 17:30
start_time <- as.POSIXct("2026-01-01 12:00:00", tz = "UTC")
end_time <- as.POSIXct("2026-01-01 17:30:00", tz = "UTC")
time_seq <- seq(from = start_time, to = end_time, by = "15 min")

cat("Generated", length(time_seq), "time periods:\n")
cat("  From:", format(min(time_seq), "%Y-%m-%d %H:%M"), "\n")
cat("  To:  ", format(max(time_seq), "%Y-%m-%d %H:%M"), "\n")

# Create mock sensor data for 3 Westminster sites
sites <- data.frame(
  siteCode = c("WM1", "WM2", "WM3"),
  lat = c(51.5014, 51.5074, 51.4975),
  lon = c(-0.1419, -0.1278, -0.1357),
  stringsAsFactors = FALSE
)

# Expand to all site-time combinations
mock_data <- expand.grid(
  siteCode = sites$siteCode,
  time = time_seq,
  stringsAsFactors = FALSE
)

# Add coordinates and simulated NO2 values (diurnal pattern)
mock_data <- merge(mock_data, sites, by = "siteCode")
mock_data$hour <- as.numeric(format(mock_data$time, "%H"))
mock_data$no2 <- 25 +
  15 * sin((mock_data$hour - 8) * pi / 12) +
  rnorm(nrow(mock_data), 0, 3)
mock_data$no2 <- pmax(mock_data$no2, 5) # Floor at 5

# Create year_str in sortable format (ISO 8601)
mock_data$year_str <- format(mock_data$time, "%Y-%m-%d %H:%M")
mock_data$year <- as.integer(format(mock_data$time, "%Y"))

# Add required coordinate aliases
mock_data$Longitude <- mock_data$lon
mock_data$Latitude <- mock_data$lat

cat("\nMock data created:", nrow(mock_data), "records\n")
cat("Sites:", length(unique(mock_data$siteCode)), "\n")
cat("Time periods:", length(unique(mock_data$year_str)), "\n")

# Save to RData
temp_file <- file.path(Sys.getenv("DATA_PATH"), "mock_15min_data.Rdata")
dataOAformat <- mock_data[, c(
  "siteCode",
  "year",
  "year_str",
  "no2",
  "lat",
  "lon",
  "Longitude",
  "Latitude"
)]
save(dataOAformat, file = temp_file)

# Generate display_times vector (all 15-min periods)
display_times <- format(time_seq, "%Y-%m-%d %H:%M")

cat("\ndisplay_times vector:\n")
print(display_times)

# Create map with 15-minute resolution
map_15min <- create_pollution_map(
  data_sources = list("mock_15min_data.Rdata"),
  boroughs = "Westminster",
  pollutant = "no2",
  display_times = display_times, # All 23 periods
  colour_scale = "airstat_no2",
  output_file = "example_15min_intervals.html",
  title = "15-Minute NO2 Data: 2026-01-01 12:00-17:30",
  styling_type = "html",
  vignette = TRUE,
  banner_colour = "#2c3e50",
  autoplay = TRUE,
  play_speed = 300 # 300ms per frame for smooth animation
)

# Cleanup temp file
unlink(temp_file)

cat("\nMap created: aq_maps/example_15min_intervals.html\n")
cat("Open in browser to see 15-minute interval animation\n")
cat("Use play button or arrow keys to cycle through time periods\n")

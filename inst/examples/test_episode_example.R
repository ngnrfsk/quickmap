library(data.table)
source("R/quickmap.R")

# Load data
load("~/Coding/Library/data/bl_imperial_210122-250422.Rdata")

start_time <- as.POSIXct("2024-01-12 15:00:00", tz = "UTC")
end_time <- as.POSIXct("2024-01-20 03:00:00", tz = "UTC")

# Subset and add required 'code' column
subset_data <- subset(dataOAformat, date >= start_time & date < end_time)
subset_data$code <- subset_data$siteCode # ADD THIS LINE

# Convert to spatial
subset_data_sf_all <- convert_openair_to_spatial(
  subset_data,
  pollutant = "pm25",
  avg.time = "hour"
)
#|>
# select(-year)

subset_data_sf_all$year <- NULL

#names(subset_data_sf_all)[names(subset_data_sf_all) == "year_str"] <- "year"

# Load borough boundary
borough_sf <- get_boundary_sf("Richmond")

# Filter points inside borough
subset_data_sf_richmond <- st_filter(subset_data_sf_all, borough_sf)

# Check output
print(head(subset_data_sf_richmond$year))
print(paste("Unique times:", length(unique(subset_data_sf_richmond$year))))

# Save
save(
  subset_data_sf_all,
  file = "~/Coding/Library/data/episodeJan2024_sf_all.Rdata"
)
save(
  subset_data_sf_richmond,
  file = "~/Coding/Library/data/episodeJan2024_sf_richmond.Rdata"
)

load("~/Coding/Library/data/episodeJan2024_sf_all.Rdata")
load("~/Coding/Library/data/episodeJan2024_sf_richmond.Rdata")
display_times <- unique(subset_data_sf_all$year_str)


map2_test <- create_pollution_map(
  data_sources = list("episodeJan2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  #  display_times = display_times,
  colour_scale = "stripes_pm25",
  theme_file = "inst/themes/airstat.yaml", # Use default theme for now
  output_file = "map2_test_episode_240110_test.html",
  title = "PM2.5 Episode: Jan 10-20, 2024",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  boundary_labels = FALSE,
  autoplay = TRUE,
  play_speed = 500
)

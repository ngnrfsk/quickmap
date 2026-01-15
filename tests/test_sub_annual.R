# Test: Sub-annual temporal resolution (v0.9.4)
# Verifies roller menu correctly sorts year/month/day/hour formats

source("R/quickmap.R")

# Fetch base data
cat("Fetching AURN data...\n")
data <- openair::importUKAQ(site = "my1", year = 2023, source = "aurn", meta = TRUE)

# Helper to create map at given resolution
test_resolution <- function(avg_time, output_name) {
  cat("\n--- Testing:", avg_time, "resolution ---\n")

  sf_data <- convert_openair_to_spatial(data, pollutant = "no2", avg.time = avg_time)
  cat("Records:", nrow(sf_data), "\n")
  cat("year_str samples:", paste(head(sf_data$year_str, 5), collapse = ", "), "\n")

  # Save temp file
  temp_file <- file.path(Sys.getenv("DATA_PATH"), paste0("test_", avg_time, ".Rdata"))
  dataOAformat <- sf_data |> sf::st_drop_geometry() |> as.data.frame()
  save(dataOAformat, file = temp_file)

  # Create map
  map <- create_pollution_map(
    data_sources = list(paste0("test_", avg_time, ".Rdata")),
    boroughs = "Westminster",
    pollutant = "no2",
    colour_scale = "who_no2",
    output_file = output_name,
    title = paste("v0.9.4 Test:", avg_time, "resolution"),
    styling_type = "html",
    vignette = TRUE
  )

  unlink(temp_file)
  cat("Created: aq_maps/", output_name, "\n", sep = "")
}

# Test each resolution
test_resolution("year", "test_sub_annual_year.html")
test_resolution("month", "test_sub_annual_month.html")
test_resolution("day", "test_sub_annual_day.html")

# Hour test with subset (too many records otherwise)
cat("\n--- Testing: hour resolution (subset to 3 days) ---\n")
data_subset <- data[data$date >= as.POSIXct("2023-06-01") & data$date < as.POSIXct("2023-06-04"), ]
sf_hourly <- convert_openair_to_spatial(data_subset, pollutant = "no2", avg.time = "hour")
cat("Records:", nrow(sf_hourly), "\n")
cat("year_str samples:", paste(head(sf_hourly$year_str, 5), collapse = ", "), "\n")

temp_file <- file.path(Sys.getenv("DATA_PATH"), "test_hour.Rdata")
dataOAformat <- sf_hourly |> sf::st_drop_geometry() |> as.data.frame()
save(dataOAformat, file = temp_file)

map <- create_pollution_map(
  data_sources = list("test_hour.Rdata"),
  boroughs = "Westminster",
  pollutant = "no2",
  colour_scale = "who_no2",
  output_file = "test_sub_annual_hour.html",
  title = "v0.9.4 Test: hour resolution (3 days)",
  styling_type = "html",
  vignette = TRUE
)
unlink(temp_file)
cat("Created: aq_maps/test_sub_annual_hour.html\n")

cat("\n=== All timescale tests complete ===\n")
cat("Open each map in browser to verify roller menu sorting:\n")
cat("  - year:  2023\n")
cat("  - month: 2023-01 -> 2023-12\n")
cat("  - day:   2023-01-01 -> 2023-12-31\n")
cat("  - hour:  2023-06-01 00:00 -> 2023-06-03 23:00\n")

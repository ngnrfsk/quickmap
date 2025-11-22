# Test zeallot unpacking in create_pollution_map()
# Verifies that %<-% operator works correctly for helper function returns

source("R/quickmap_clean.R")

cat("Test 1: parse_export_params() unpacking...\n")
test_export <- function() {
  c(enabled, width, height) %<-% parse_export_params(TRUE)
  stopifnot(enabled == TRUE)
  stopifnot(width == IMAGE_X)
  stopifnot(height == IMAGE_Y)
}
test_export()
cat("✓ Pass\n\n")

cat("Test 2: determine_primary_data_and_years() unpacking...\n")
test_data <- data.frame(
  lat = c(51.5, 51.51),
  lon = c(-0.1, -0.11),
  no2 = c(10, 20),
  year_str = c("2024", "2024")
)
test_sf <- sf::st_as_sf(test_data, coords = c("lon", "lat"), crs = 4326)
borough_sf <- sf::st_buffer(test_sf[1,], 0.01)

spatial_data <- list(
  dt = test_sf,
  sensor = NULL,
  school = NULL
)

c(primary, sensor, years, vignette_overlay, bbox) %<-%
  determine_primary_data_and_years(spatial_data, borough_sf, TRUE, NULL)

stopifnot(!is.null(primary))
stopifnot("2024" %in% years)
stopifnot(!is.null(bbox))
cat("✓ Pass\n\n")

cat("All zeallot unpacking tests passed! ✓\n")

# Test Step 5: Verify simplifications don't break functionality
# Tests removed dead code and simplified conditionals

source("R/quickmap_clean.R")

# Test data
test_data <- data.frame(
  lat = c(51.5, 51.51),
  lon = c(-0.1, -0.11),
  no2 = c(10, 20),
  Level = c("Primary", "Secondary")
)
test_sf <- sf::st_as_sf(test_data, coords = c("lon", "lat"), crs = 4326)

cat("Test 1: Color assignment for schools (simplified if/else)...\n")
school_colors <- create_generic_icons(test_sf, "schools", NULL, NULL, 1.0)
stopifnot(!is.null(school_colors))
cat("✓ Pass\n\n")

cat("Test 2: Color assignment for pollution layers...\n")
dt_colors <- create_generic_icons(test_sf, "dt_sites", "no2", "who_no2", 1.0)
stopifnot(!is.null(dt_colors))
cat("✓ Pass\n\n")

cat("Test 3: Layer config without prepare_function field...\n")
layers <- get_measurement_layers("data.csv", "sensor.Rdata", "schools.csv", FALSE)
stopifnot(is.null(layers$bl_nodes$prepare_function))
stopifnot(is.null(layers$dt_sites$prepare_function))
stopifnot(is.null(layers$schools$prepare_function))
cat("✓ Pass\n\n")

cat("All Step 5 tests passed! ✓\n")

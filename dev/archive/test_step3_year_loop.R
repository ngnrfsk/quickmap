# Test Step 3: Simplified year loop with helpers
# Tests that build_static_map_for_year works correctly

source("R/quickmap_clean.R")

# Setup test data
test_data <- data.frame(
  lat = c(51.5, 51.51, 51.49),
  lon = c(-0.1, -0.11, -0.09),
  no2 = c(10, 20, 30),
  year_str = c("2024", "2024", "2024")
)
test_sf <- sf::st_as_sf(test_data, coords = c("lon", "lat"), crs = 4326)

# Create test measurement layers
measurement_layers <- list(
  test_layer = list(
    enabled = TRUE,
    temporal = TRUE,
    layer_type = "dt_sites",
    data_source = "test_sf"
  )
)

cat("Test 1: Build static map for year...\n")
base_map <- create_base_map(test_sf, interactive = FALSE, base_tiles = NULL)
result <- build_static_map_for_year(
  base_map, "2024", measurement_layers,
  "no2", "who_no2", environment(), 1.0
)
stopifnot("leaflet" %in% class(result))
cat("✓ Pass\n\n")

cat("All Step 3 tests passed! ✓\n")

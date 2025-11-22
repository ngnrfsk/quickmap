# Test Step 2: finalize_and_save_map() helper function
# Tests that map finalization works for both interactive and static modes

source("R/quickmap_clean.R")

# Setup test data
test_data <- data.frame(
  lat = c(51.5, 51.51, 51.49),
  lon = c(-0.1, -0.11, -0.09),
  value = c(10, 20, 30)
)
test_sf <- sf::st_as_sf(test_data, coords = c("lon", "lat"), crs = 4326)

# Create test borough
borough_sf <- sf::st_buffer(test_sf[1,], 0.01)
vignette_overlay <- NULL
bbox <- sf::st_bbox(borough_sf)

# Create base map
base_map <- create_base_map(test_sf, interactive = TRUE, base_tiles = NULL)

cat("Test 1: Finalize interactive map (no image export)...\n")
temp_html <- tempfile(fileext = ".html")
result <- finalize_and_save_map(
  base_map, temp_html, borough_sf, vignette_overlay,
  TRUE, bbox, TRUE, "2024", FALSE, NULL,
  "Test Map", "html", TRUE, "#2c3e50", "who_no2",
  FALSE, 500, 100, NULL
)
stopifnot(file.exists(temp_html))
stopifnot("leaflet" %in% class(result))
unlink(temp_html)
cat("✓ Pass\n\n")

cat("All Step 2 tests passed! ✓\n")

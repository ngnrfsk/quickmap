# Test Step 1: create_base_map() helper function
# Tests that base map creation works for both interactive and static modes

source("R/quickmap_clean.R")

# Test 1: Interactive map with default tiles
cat("Test 1: Interactive base map with default tiles...\n")
test_data <- data.frame(lat = 51.5, lon = -0.1, value = 10)
test_sf <- sf::st_as_sf(test_data, coords = c("lon", "lat"), crs = 4326)
map1 <- create_base_map(test_sf, interactive = TRUE, base_tiles = NULL)
stopifnot("leaflet" %in% class(map1))
cat("✓ Pass\n\n")

# Test 2: Static map with default tiles
cat("Test 2: Static base map (no zoom controls)...\n")
map2 <- create_base_map(test_sf, interactive = FALSE, base_tiles = NULL)
stopifnot("leaflet" %in% class(map2))
cat("✓ Pass\n\n")

# Test 3: Map with provider tiles
cat("Test 3: Base map with CartoDB provider tiles...\n")
map3 <- create_base_map(test_sf, interactive = TRUE, base_tiles = "CartoDB.Positron")
stopifnot("leaflet" %in% class(map3))
cat("✓ Pass\n\n")

cat("All Step 1 tests passed! ✓\n")

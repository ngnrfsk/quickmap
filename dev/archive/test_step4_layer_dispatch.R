# Test Step 4: Simplified layer preparation without switch
# Tests that prepare_generic_layer_data works for all layer types

source("R/quickmap_clean.R")

# Test data for temporal layers
temporal_data <- data.frame(
  lat = c(51.5, 51.51),
  lon = c(-0.1, -0.11),
  no2 = c(10, 20),
  year_str = c("2024", "2024")
)
temporal_sf <- sf::st_as_sf(temporal_data, coords = c("lon", "lat"), crs = 4326)

# Test data for schools
school_data <- data.frame(
  lat = c(51.5, 51.51),
  lon = c(-0.1, -0.11),
  School = c("School A", "School B"),
  Level = c("Primary", "Secondary")
)
school_sf <- sf::st_as_sf(school_data, coords = c("lon", "lat"), crs = 4326)

cat("Test 1: BL nodes layer preparation...\n")
bl_config <- list(layer_type = "bl_nodes", options = list(marker_labels = FALSE))
bl_result <- prepare_generic_layer_data(bl_config, temporal_sf, "no2", "who_no2")
stopifnot(!is.null(bl_result$data))
stopifnot(!is.null(bl_result$labels))
cat("✓ Pass\n\n")

cat("Test 2: DT sites layer preparation...\n")
dt_config <- list(layer_type = "dt_sites", options = list(marker_labels = FALSE))
dt_result <- prepare_generic_layer_data(dt_config, temporal_sf, "no2", "who_no2")
stopifnot(!is.null(dt_result$data))
stopifnot(!is.null(dt_result$labels))
cat("✓ Pass\n\n")

cat("Test 3: Schools layer preparation...\n")
school_config <- list(layer_type = "schools", options = list(marker_labels = FALSE))
school_result <- prepare_generic_layer_data(school_config, school_sf, NULL, NULL)
stopifnot(!is.null(school_result$data))
stopifnot(!is.null(school_result$labels))
stopifnot(school_result$layer_type == "schools")
cat("✓ Pass\n\n")

cat("Test 4: Empty data returns NULL...\n")
empty_sf <- temporal_sf[0,]
empty_result <- prepare_generic_layer_data(bl_config, empty_sf, "no2", "who_no2")
stopifnot(is.null(empty_result))
cat("✓ Pass\n\n")

cat("All Step 4 tests passed! ✓\n")

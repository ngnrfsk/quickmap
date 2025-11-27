# Test Script: 4-Network Mock (Step 6 - v0.9.2.6)
# Demonstrates extensibility by adding mock AURN network via config

# Source the main script
Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

cat("\n=== Step 6: Adding Mock 4th Network (AURN) ===\n")

# ==============================================================================
# 1. Load existing data
# ==============================================================================
cat("\n1. Loading existing data files...\n")

dt_file <- "merton_dt_2018_2024.csv"
bl_file <- "bl_imperial_annualised_2021_2025_with_missing.Rdata"
school_file <- "your_schools_Merton.csv"

# Get borough boundary for spatial filtering
borough_sf <- get_boundary_sf("Merton")
cat("   ✓ Loaded Merton borough boundary\n")

# ==============================================================================
# 2. Create mock AURN data (50 random sites, 3 years, inside Merton)
# ==============================================================================
cat("\n2. Creating mock AURN data (50 sites, 3 years)...\n")

set.seed(42)  # Reproducible random data

# Get borough bounding box
bbox <- st_bbox(borough_sf)

# Generate 50 random points inside bounding box
n_sites <- 50
random_lons <- runif(n_sites, bbox["xmin"], bbox["xmax"])
random_lats <- runif(n_sites, bbox["ymin"], bbox["ymax"])

# Create points and filter to only those inside borough
points_sf <- st_as_sf(
  data.frame(lon = random_lons, lat = random_lats),
  coords = c("lon", "lat"),
  crs = 4326
)

# Keep only points inside Merton
points_inside <- points_sf[st_within(points_sf, borough_sf, sparse = FALSE)[,1], ]

# If we don't have enough points inside, regenerate
while (nrow(points_inside) < 50) {
  extra_lons <- runif(20, bbox["xmin"], bbox["xmax"])
  extra_lats <- runif(20, bbox["ymin"], bbox["ymax"])
  extra_points <- st_as_sf(
    data.frame(lon = extra_lons, lat = extra_lats),
    coords = c("lon", "lat"),
    crs = 4326
  )
  points_inside <- rbind(points_inside, extra_points[st_within(extra_points, borough_sf, sparse = FALSE)[,1], ])
}

# Take first 50 points
points_inside <- points_inside[1:50, ]

# Create AURN data matching bl_annual_means_sf structure
years <- c(2018:2024)
aurn_data <- do.call(rbind, lapply(years, function(yr) {
  data.frame(
    siteCode = paste0("AURN_", 1:50),
    year = yr,
    no2 = runif(50, 0, 49),  # Random NO2 values 0-49
    geometry = st_geometry(points_inside)
  )
}))

# Convert to sf object with proper structure
mock_aurn_sf <- st_as_sf(aurn_data, crs = 4326) |>
  mutate(year_str = as.character(year))

# Add Longitude and Latitude columns (required by quickmap)
coords <- st_coordinates(mock_aurn_sf)
mock_aurn_sf$Longitude <- coords[, 1]
mock_aurn_sf$Latitude <- coords[, 2]

cat("   ✓ Created", nrow(points_inside), "AURN sites across", length(years), "years\n")
cat("   ✓ NO2 range:", round(min(aurn_data$no2), 1), "-", round(max(aurn_data$no2), 1), "µg/m³\n")

# ==============================================================================
# 3. Create AURN config YAML using writer function
# ==============================================================================
cat("\n3. Creating AURN config YAML...\n")

write_data_source_config(
  id = "aurn",
  label = "AURN Network (Mock)",
  icon_shape = "square",
  static = FALSE,
  min_period = "hourly",
  available_aggregations = c("hourly", "daily", "monthly", "annual"),
  pollutants = c("no2", "pm25", "pm10"),
  openair_import_function = NULL,
  monitoring_type = "continuous_automatic",
  provider = "Mock AURN Network"
)

cat("   ✓ AURN config written to inst/config/data_sources/aurn.yaml\n")

# ==============================================================================
# 4. Create 4-network map using new API
# ==============================================================================
cat("\n4. Creating map with 4 networks (DT + BL + Schools + AURN)...\n")

map_4network <- create_pollution_map(
  data_sources = list(
    dt_file,
    bl_file,
    school_file,
    mock_aurn_sf  # Pass sf object directly
  ),
  data_ids = NULL,
  boroughs = "Merton",
  pollutant = "no2",
  years = c(2018:2024),
  colour_scale = "who_no2",
  output_file = "test_4network_mock_merton_no2.html",
  title = "4-Network Test: DT (●) + BL (◆) + Schools (✖) + AURN (■)",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("   ✓ Map created with 4 distinct icon shapes\n")


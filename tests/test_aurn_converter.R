# Test Script: AURN Converter with Multi-Network Overlay (Step 5)
# Maps AURN + dt_sites + schools with 3 distinct icon shapes

source("R/quickmap.R")

cat("\n=== Step 5: AURN Converter Test ===\n\n")

# Check DATA_PATH
data_path <- Sys.getenv("DATA_PATH")
if (data_path == "") {
  stop("DATA_PATH not set. Set with: Sys.setenv(DATA_PATH = 'path/to/data')")
}
cat("DATA_PATH:", data_path, "\n\n")

# 1. Download AURN data (3 London sites, 2 years)
cat("1. Downloading AURN data (3 sites: MY1, LH0, KC1; 2022-2023)...\n")
aurn_data <- openair::importUKAQ(
  site = c("my1", "lh0", "kc1"),  # Marylebone, London Hillingdon, Kings College
  year = 2022:2023,
  source = "aurn",
  meta = TRUE,
  pollutant = "no2"
)
cat("   Downloaded:", nrow(aurn_data), "hourly observations\n\n")

# 2. Convert to spatial
cat("2. Converting AURN data to spatial sf object...\n")
aurn_sf <- convert_openair_to_spatial(
  data = aurn_data,
  pollutant = "no2",
  avg.time = "year"
)
cat("   Converted:", nrow(aurn_sf), "site-years\n")
cat("   Sites:", paste(unique(aurn_sf$siteCode), collapse = ", "), "\n\n")

# 3. Save as Rdata (compatible with quickmap)
cat("3. Saving AURN data to Rdata file...\n")
dataOAformat <- data.frame(
  siteCode = aurn_sf$siteCode,
  year = aurn_sf$year,
  no2 = aurn_sf$no2,
  lat = aurn_sf$lat,
  lon = aurn_sf$lon
)
aurn_file <- file.path(data_path, "aurn_test_data.Rdata")
save(dataOAformat, file = aurn_file)
cat("   Saved to:", aurn_file, "\n\n")

# 4. Create map with 3 networks
cat("4. Creating 3-network map (AURN + dt_sites + schools)...\n")
cat("   Layers:\n")
cat("     - AURN: square icons (blue)\n")
cat("     - Diffusion tubes: circle icons\n")
cat("     - Schools: cross icons\n\n")

tryCatch(
  {
    map <- create_pollution_map(
      diffusion_tube_file = "merton_dt_2018_2024.csv",
      sensor_file = "aurn_test_data.Rdata",
      school_file = "your_schools_Merton.csv",
      boroughs = "Merton",
      pollutant = "no2",
      year = 2023,
      output_file = "aq_maps/test_aurn_3network.html",
      sensor_shape = "square",
      sensor_colour = "blue"
    )
    cat("\n✓ Map created: aq_maps/test_aurn_3network.html\n")
    cat("\nUser test: Open map and verify:\n")
    cat("  - AURN sites show as BLUE SQUARES\n")
    cat("  - Diffusion tube sites show as CIRCLES\n")
    cat("  - Schools show as CROSSES\n")
    cat("  - All 3 icon shapes are distinct\n")
  },
  error = function(e) {
    cat("\nERROR creating map:\n")
    cat(e$message, "\n")
    cat("\nNote: Requires valid data files in DATA_PATH:\n")
    cat("  - merton_dt_2018_2024.csv\n")
    cat("  - your_schools_Merton.csv\n")
  }
)

cat("\n=== Test complete ===\n")

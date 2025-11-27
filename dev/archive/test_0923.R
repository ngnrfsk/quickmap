# Test Suite for Step 3: Generic Layer Processing (v0.9.2.3)
# Tests config-driven layer processing with pollutant_col and icon_shape fields

# Source the main script
Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

# ==============================================================================
# TEST 1: Old API - diffusion_tube_file + sensor_file + school_file
# Should work identically to v0.9.1
# ==============================================================================
cat("\n=== TEST 1: Old API (backward compatibility) ===\n")

test1_old_api <- create_pollution_map(
  diffusion_tube_file = "merton_dt_2018_2024.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  years = 2023,
  colour_scale = "who_no2",
  output_file = "test_0923_old_api_merton_no2.html",
  title = "TEST 1: Old API - Merton NO2 2023",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("✓ TEST 1 completed: Old API works\n")

# ==============================================================================
# TEST 2: New API - data_sources + data_configs (same data as TEST 1)
# Should produce identical map to TEST 1
# ==============================================================================
cat("\n=== TEST 2: New API with file paths ===\n")

test2_new_api <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "your_schools_Merton.csv"
  ),
  data_configs = c("dt_sites", "bl_nodes", "schools"),
  boroughs = "Merton",
  pollutant = "no2",
  years = 2023,
  colour_scale = "who_no2",
  output_file = "test_0923_new_api_merton_no2.html",
  title = "TEST 2: New API - Merton NO2 2023",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("✓ TEST 2 completed: New API with file paths works\n")

# ==============================================================================
# TEST 3: New API - partial data (DT + schools only, no sensors)
# ==============================================================================
cat("\n=== TEST 3: New API with subset of data sources ===\n")

test3_partial <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "your_schools_Merton.csv"
  ),
  data_configs = c("dt_sites", "schools"),
  boroughs = "Merton",
  pollutant = "no2",
  years = 2023,
  colour_scale = "who_no2",
  output_file = "test_0923_new_api_partial.html",
  title = "TEST 3: New API - DT + Schools Only",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("✓ TEST 3 completed: New API with partial data sources works\n")

# ==============================================================================
# TEST 4: Old API - schools only (no pollution data)
# ==============================================================================
cat("\n=== TEST 4: Old API with schools only ===\n")

test4_schools_only <- create_pollution_map(
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "no2",
  colour_scale = "who_no2",
  output_file = "test_0923_old_api_schools_only.html",
  title = "TEST 4: Old API - Schools Only",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("✓ TEST 4 completed: Old API with schools only works\n")

# ==============================================================================
# TEST 5: New API - different borough (Richmond)
# ==============================================================================
cat("\n=== TEST 5: New API with different borough ===\n")

test5_richmond <- create_pollution_map(
  data_sources = list(
    "richmond_1993_2024-1.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "your_schools_Merton.csv"
  ),
  data_configs = c("dt_sites", "bl_nodes", "schools"),
  boroughs = "Richmond",
  pollutant = "no2",
  years = 2023,
  colour_scale = "stripes_no2",
  output_file = "test_0923_new_api_richmond.html",
  title = "TEST 5: New API - Richmond NO2 2023",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("✓ TEST 5 completed: New API with Richmond works\n")

# ==============================================================================
# TEST 6: Old API - PM2.5 pollutant
# ==============================================================================
cat("\n=== TEST 6: Old API with PM2.5 ===\n")

test6_pm25 <- create_pollution_map(
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  school_file = "your_schools_Merton.csv",
  boroughs = "Merton",
  pollutant = "pm25",
  years = 2023,
  colour_scale = "gla_pm25",
  output_file = "test_0923_old_api_pm25.html",
  title = "TEST 6: Old API - Merton PM2.5 2023",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = TRUE,
  boundary_labels = FALSE
)

cat("✓ TEST 6 completed: Old API with PM2.5 works\n")

# ==============================================================================
# Summary
# ==============================================================================
cat("\n" , rep("=", 80), "\n", sep="")
cat("ALL TESTS COMPLETED SUCCESSFULLY\n")
cat(rep("=", 80), "\n", sep="")
cat("\nTest outputs in aq_maps/ directory:\n")
cat("  - test_0923_old_api_merton_no2.html (TEST 1)\n")
cat("  - test_0923_new_api_merton_no2.html (TEST 2 - should match TEST 1)\n")
cat("  - test_0923_new_api_partial.html (TEST 3)\n")
cat("  - test_0923_old_api_schools_only.html (TEST 4)\n")
cat("  - test_0923_new_api_richmond.html (TEST 5)\n")
cat("  - test_0923_old_api_pm25.html (TEST 6)\n")
cat("\nVisual comparison: TEST 1 and TEST 2 should be identical\n")
cat(rep("=", 80), "\n", sep="")

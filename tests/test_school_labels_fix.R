# Test script to verify school labels work with auto-generated data_ids
# Tests the fix for school label detection (removing layer_id == "schools" check)

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

cat("=======================================================\n")
cat("TEST 1: School labels with auto-generated data_ids\n")
cat("(Previously broken, should now work)\n")
cat("=======================================================\n\n")

# Test 1: Auto-generated data_ids (should work now)
# File: schools_wandsworth.csv -> auto-generated ID: "schools_wandsworth"
test1_auto_ids <- create_pollution_map(
  data_sources = list(
    "wandsworth_2017_2024_no_labels.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_wandsworth.csv"  # Will auto-generate ID as "schools_wandsworth"
  ),
  data_ids = NULL,  # Auto-generate IDs
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = 2024,
  colour_scale = "lbw_no2",
  output_file = "test1_auto_ids_school_labels.html",
  title = "TEST 1: Auto-generated data_ids (schools_wandsworth)",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",  # Should show school names
  banner_colour = "#00549F",
  boundary_labels = FALSE
)

cat("\n✓ Test 1 completed: test1_auto_ids_school_labels.html\n")
cat("  Expected: School names should appear on hover\n\n")

cat("=======================================================\n")
cat("TEST 2: Explicit data_ids = 'schools'\n")
cat("(Should continue to work as before)\n")
cat("=======================================================\n\n")

# Test 2: Explicit data_ids (should still work)
test2_explicit_ids <- create_pollution_map(
  data_sources = list(
    "wandsworth_2017_2024_no_labels.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_wandsworth.csv"
  ),
  data_ids = c("dt", "bl_sensors", "schools"),  # Explicit IDs
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = 2024,
  colour_scale = "lbw_no2",
  output_file = "test2_explicit_ids_school_labels.html",
  title = "TEST 2: Explicit data_ids = 'schools'",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00549F",
  boundary_labels = FALSE
)

cat("\n✓ Test 2 completed: test2_explicit_ids_school_labels.html\n")
cat("  Expected: School names should appear on hover\n\n")

cat("=======================================================\n")
cat("TEST 3: Differently named school file\n")
cat("(Should work with any filename containing school data)\n")
cat("=======================================================\n\n")

# Test 3: Different school filename with auto-generated ID
test3_different_name <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "your_schools_Merton.csv"  # Will auto-generate ID as "your_schools_Merton"
  ),
  data_ids = NULL,  # Auto-generate IDs
  boroughs = "Merton",
  pollutant = "no2",
  years = 2024,
  colour_scale = "who_no2",
  output_file = "test3_different_filename_school_labels.html",
  title = "TEST 3: Different filename (your_schools_Merton)",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#5F3E94",
  boundary_labels = FALSE
)

cat("\n✓ Test 3 completed: test3_different_filename_school_labels.html\n")
cat("  Expected: School names should appear on hover\n\n")

cat("=======================================================\n")
cat("TEST 4: Custom layer ID (not 'schools')\n")
cat("(Should work even with arbitrary ID)\n")
cat("=======================================================\n\n")

# Test 4: Explicit custom ID that's NOT "schools"
test4_custom_id <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "schools_Merton.csv"
  ),
  data_ids = c("diffusion_tubes", "educational_institutions"),  # Arbitrary IDs
  boroughs = "Merton",
  pollutant = "no2",
  years = 2024,
  colour_scale = "who_no2",
  output_file = "test4_custom_id_school_labels.html",
  title = "TEST 4: Custom layer ID 'educational_institutions'",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#5F3E94",
  boundary_labels = FALSE
)

cat("\n✓ Test 4 completed: test4_custom_id_school_labels.html\n")
cat("  Expected: School names should appear on hover\n\n")

cat("=======================================================\n")
cat("ALL TESTS COMPLETED\n")
cat("=======================================================\n")
cat("\nCheck the HTML files in aq_maps/ directory:\n")
cat("  - test1_auto_ids_school_labels.html\n")
cat("  - test2_explicit_ids_school_labels.html\n")
cat("  - test3_different_filename_school_labels.html\n")
cat("  - test4_custom_id_school_labels.html\n\n")
cat("Hover over school markers (✖) to verify names appear.\n")
cat("All four tests should show school names on hover.\n\n")

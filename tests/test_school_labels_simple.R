# Simple focused test: Verify school labels work with auto-generated data_ids
# This test verifies the fix works (removed layer_id == "schools" check)

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  TESTING: School labels with auto-generated data_ids          ║\n")
cat("║  Fix: Removed layer_id == 'schools' hardcoded check          ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# THE KEY TEST: Auto-generated data_ids
# - File: schools_wandsworth.csv
# - Auto-generated ID will be: "schools_wandsworth" (NOT "schools")
# - BEFORE fix: Labels wouldn't show (layer_id != "schools")
# - AFTER fix: Labels should show (only checks for "School" column)

cat("Creating map with AUTO-GENERATED data_ids...\n")
cat("  File: schools_wandsworth.csv\n")
cat("  Auto-generated layer_id: 'schools_wandsworth'\n")
cat("  marker_labels: 'labels'\n\n")

map_test <- create_pollution_map(
  data_sources = list(
    "schools_wandsworth.csv"  # Only schools layer for clarity
  ),
  data_ids = NULL,  # Let it auto-generate "schools_wandsworth"
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = NULL,
  colour_scale = "who_no2",
  output_file = "test_school_labels_SIMPLE.html",
  title = "School Labels Test: Auto-generated data_ids",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = "labels",  # KEY: Should show School column values
  banner_colour = "#00549F",
  boundary_labels = FALSE
)

cat("\n✓ Map created: aq_maps/test_school_labels_SIMPLE.html\n\n")

cat("═══════════════════════════════════════════════════════════════\n")
cat("VERIFICATION STEPS:\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("1. Open: aq_maps/test_school_labels_SIMPLE.html in browser\n")
cat("2. Hover over school markers (✖ symbols)\n")
cat("3. Expected: School names should appear in hover tooltip\n")
cat("4. If names appear → FIX WORKS ✓\n")
cat("5. If no names appear → FIX FAILED ✗\n")
cat("═══════════════════════════════════════════════════════════════\n\n")

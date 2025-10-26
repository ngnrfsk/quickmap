# Test Script for Critical-1: Test 3 Only (auto-hide fix verification)
# Version 0.8.8
# Date: 2025-10-16

# Source the working development version
source("versions/quickmap_0_8_8.R")

# Test data path
test_data <- "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv"

cat("\n=== Re-testing Test 3: auto-hide mode ===\n\n")

# Test Case 3: "auto-hide" mode (default)
cat("Test 3: show_boundary_labels = 'auto-hide' (HTML + JPG)\n")
cat("Expected: HTML shows labels on hover, JPG has no labels\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth"),
    years_to_plot = 2024,
    output_file = "aq_maps/test_boundary_autohide_fixed.html",
    image_export = TRUE
    # show_boundary_labels defaults to "auto-hide"
  )
  cat("✓ Test 3 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 3 failed:", e$message, "\n")
})

cat("\n=== Test Complete ===\n")
cat("\nGenerated file: aq_maps/test_boundary_autohide_fixed.html + .jpg\n")
cat("\nPlease verify:\n")
cat("- HTML: Hover over Wandsworth boundary to see label appear\n")
cat("- JPG: No labels visible\n")

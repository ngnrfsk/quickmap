# Test Script for Critical-1: Boundary Labels Control (Boolean Version)
# Version 0.8.8
# Date: 2025-10-16

# Source the working development version
source("versions/quickmap_0_8_8.R")

# Test data path
test_data <- "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv"

cat("\n=== Testing Critical-1: Boundary Labels (Boolean Parameter) ===\n\n")

# Test Case 1: TRUE (labels on)
cat("Test 1: show_boundary_labels = TRUE (HTML + JPG)\n")
cat("Expected: Borough name 'Wandsworth' visible in both outputs\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth"),
    years_to_plot = 2024,
    output_file = "test_labels_true.html",
    image_export = TRUE,
    show_boundary_labels = TRUE
  )
  cat("✓ Test 1 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 1 failed:", e$message, "\n")
})

cat("\n")

# Test Case 2: FALSE (labels off, default)
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth"),
    years_to_plot = 2024,
    output_file = "test_labels_false.html",
    show_banner = TRUE, # Enable banner
    banner_text = "does the banner show",
    image_export = TRUE,
    show_boundary_labels = FALSE
  )
  cat("✓ Test 2 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 2 failed:", e$message, "\n")
})

cat("\n")

# Test Case 3: Multi-borough with labels
cat("Test 3: Multi-borough with show_boundary_labels = TRUE (HTML + JPG)\n")
cat("Expected: All three borough names visible in both outputs\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth", "Merton", "Richmond upon Thames"),
    years_to_plot = 2024,
    output_file = "test_labels_multi.html",
    image_export = TRUE,
    show_boundary_labels = TRUE
  )
  cat("✓ Test 3 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 3 failed:", e$message, "\n")
})

cat("\n=== Testing Complete ===\n")
cat("\nGenerated files in aq_maps/ directory:\n")
cat("- test_labels_true.html + .jpg\n")
cat("- test_labels_false.html + .jpg\n")
cat("- test_labels_multi.html + .jpg\n")
cat("\nPlease visually inspect the outputs to verify:\n")
cat("1. Test 1 (TRUE): Labels visible\n")
cat("2. Test 2 (FALSE): No labels\n")
cat("3. Test 3 (Multi): All borough names visible\n")

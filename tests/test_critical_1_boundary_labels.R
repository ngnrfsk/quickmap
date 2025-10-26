# Test Script for Critical-1: Boundary Labels Control
# Version 0.8.8
# Date: 2025-10-16

# Source the working development version
source("versions/quickmap_0_8_8.R")

# Test data path
test_data <- "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv"

cat("\n=== Testing Critical-1: Boundary Labels Control ===\n\n")

# Test Case 1: "on" mode
cat("Test 1: show_boundary_labels = 'on' (HTML + JPG)\n")
cat("Expected: Borough name 'Wandsworth' always visible in both outputs\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth"),
    years_to_plot = 2024,
    output_file = "aq_maps/test_boundary_on.html",
    image_export = TRUE,
    show_boundary_labels = "on"
  )
  cat("✓ Test 1 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 1 failed:", e$message, "\n")
})

cat("\n")

# Test Case 2: "off" mode
cat("Test 2: show_boundary_labels = 'off' (HTML + JPG)\n")
cat("Expected: No borough labels in either output\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth"),
    years_to_plot = 2024,
    output_file = "aq_maps/test_boundary_off.html",
    image_export = TRUE,
    show_boundary_labels = "off"
  )
  cat("✓ Test 2 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 2 failed:", e$message, "\n")
})

cat("\n")

# Test Case 3: "auto-hide" mode (default)
cat("Test 3: show_boundary_labels = 'auto-hide' (HTML + JPG)\n")
cat("Expected: HTML shows labels on hover, JPG has no labels\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth"),
    years_to_plot = 2024,
    output_file = "aq_maps/test_boundary_autohide.html",
    image_export = TRUE
    # show_boundary_labels defaults to "auto-hide"
  )
  cat("✓ Test 3 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 3 failed:", e$message, "\n")
})

cat("\n")

# Test Case 4: Multi-borough scenario
cat("Test 4: Multi-borough with show_boundary_labels = 'on' (HTML + JPG)\n")
cat("Expected: All three borough names visible in both outputs\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data,
    boroughs = c("Wandsworth", "Merton", "Richmond upon Thames"),
    years_to_plot = 2024,
    output_file = "aq_maps/test_boundary_multi.html",
    image_export = TRUE,
    show_boundary_labels = "on"
  )
  cat("✓ Test 4 completed successfully\n")
}, error = function(e) {
  cat("✗ Test 4 failed:", e$message, "\n")
})

cat("\n=== Testing Complete ===\n")
cat("\nGenerated files in aq_maps/ directory:\n")
cat("- test_boundary_on.html + .jpg\n")
cat("- test_boundary_off.html + .jpg\n")
cat("- test_boundary_autohide.html + .jpg\n")
cat("- test_boundary_multi.html + .jpg\n")
cat("\nPlease visually inspect the outputs to verify:\n")
cat("1. Test 1: Labels always visible\n")
cat("2. Test 2: No labels\n")
cat("3. Test 3: HTML has hover labels, JPG has none\n")
cat("4. Test 4: All borough names visible\n")

# Test Script for Critical-2: Fix Duplicate Legend Bug
# Version 0.8.9
# Date: 2025-10-16

# Source the working development version
source("versions/quickmap_0_8_9.R")

# Test data path
test_data <- "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv"

cat("\n=== Testing Critical-2: No Duplicate Legend ===\n\n")

# Test Case 1: Default behavior (should have ONE HTML legend only)
cat("Test 1: Default behavior (should have ONE HTML legend)\n")
cat("Expected: Single HTML legend at bottom, NO Leaflet legend inside map\n")
tryCatch(
  {
    create_pollution_map(
      csv_data_file = test_data,
      boroughs = c("Wandsworth"),
      years_to_plot = 2024,
      output_file = "test_no_duplicate_default.html"
      # show_legend defaults to TRUE (now has no effect)
    )
    cat("✓ Test 1 completed successfully\n")
  },
  error = function(e) {
    cat("✗ Test 1 failed:", e$message, "\n")
  }
)

cat("\n")

# Test Case 2: Explicit show_legend = TRUE (should still have ONE HTML legend)
cat("Test 2: show_legend = TRUE (backward compatibility check)\n")
cat("Expected: Single HTML legend, no duplicate\n")
tryCatch(
  {
    create_pollution_map(
      csv_data_file = test_data,
      boroughs = c("Wandsworth"),
      years_to_plot = 2024,
      output_file = "test_no_duplicate_explicit.html",
      show_legend = TRUE # Parameter kept for backward compatibility
    )
    cat("✓ Test 2 completed successfully\n")
  },
  error = function(e) {
    cat("✗ Test 2 failed:", e$message, "\n")
  }
)

cat("\n")

# Test Case 3: show_legend = FALSE (should still have HTML legend)
cat("Test 3: show_legend = FALSE\n")
cat("Expected: HTML legend still appears (parameter has no effect)\n")
tryCatch(
  {
    create_pollution_map(
      csv_data_file = test_data,
      boroughs = c("Wandsworth"),
      years_to_plot = 2024,
      output_file = "test_no_duplicate_false.html",
      show_legend = FALSE # Has no effect, HTML legend always added
    )
    cat("✓ Test 3 completed successfully\n")
  },
  error = function(e) {
    cat("✗ Test 3 failed:", e$message, "\n")
  }
)

cat("\n=== Testing Complete ===\n")
cat("\nGenerated files in aq_maps/ directory:\n")
cat("- test_no_duplicate_default.html\n")
cat("- test_no_duplicate_explicit.html\n")
cat("- test_no_duplicate_false.html\n")
cat("\nPlease verify:\n")
cat("- All files have ONE legend (HTML/CSS legend at bottom)\n")
cat("- NO Leaflet legend inside the map (at bottomright)\n")
cat("- All three files should look identical\n")

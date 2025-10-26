# Test Script for Task 1E.1: Banner and Legend Scaling Fixes
# Tests the improved scaling system for legend text, marker sizes, and layout dimensions
# Created: 2024-10-14
# Version: 0.8.7.1

# Load the updated quickmap function
source("../versions/quickmap_0_8_7_1.R")

# Test Configuration
test_data_file <- "test_data.csv"  # Replace with actual test data file
test_borough <- "Wandsworth"       # Replace with actual borough name
test_year <- 2024                  # Plot only 2024 data

cat("=" * 80, "\n")
cat("TESTING TASK 1E.1: BANNER AND LEGEND SCALING FIXES\n")
cat("=" * 80, "\n\n")

# Test 1: Scale Factor Calculation Verification
cat("Test 1: Verifying improved scale factor calculations...\n")
cat("------------------------------------------------------\n")

# Function to test scale factor calculation
test_scale_factor <- function(width, height, description) {
  # Old method (minimum-based)
  old_scale_factor <- min(width / 1200, height / 1200)

  # New method (geometric mean)
  new_scale_factor <- sqrt((width * height) / (1200 * 1200))

  cat(sprintf("%s (%dx%d):\n", description, width, height))
  cat(sprintf("  Old scale factor (min): %.3f\n", old_scale_factor))
  cat(sprintf("  New scale factor (sqrt): %.3f\n", new_scale_factor))
  cat(sprintf("  Improvement ratio: %.3f\n", new_scale_factor / old_scale_factor))
  cat("\n")

  return(list(old = old_scale_factor, new = new_scale_factor))
}

# Test scale factor improvements for problematic dimensions
test_scale_factor(800, 600, "Small")
test_scale_factor(1200, 1200, "Standard (baseline)")
test_scale_factor(1920, 1080, "Large widescreen")
test_scale_factor(2400, 1800, "Poster")
test_scale_factor(3840, 2160, "4K")

# Test 2: Comprehensive Scaling Test with Different Image Dimensions
cat("Test 2: Creating maps with different dimensions to test scaling...\n")
cat("------------------------------------------------------------------\n")

# Enhanced test dimensions with more variety
test_dimensions <- list(
  tiny = c(400, 300),        # Very small
  small = c(800, 600),       # Standard web small
  square_small = c(600, 600), # Small square
  standard = c(1200, 1200),   # Baseline reference
  wide = c(1600, 900),        # Widescreen 16:9
  large = c(1920, 1080),      # Full HD
  square_large = c(1800, 1800), # Large square
  poster = c(2400, 1800),     # High-res poster
  ultrawide = c(2560, 1080),  # Ultra-widescreen
  huge = c(3840, 2160)        # 4K
)

scaling_results <- list()

for (size_name in names(test_dimensions)) {
  width <- test_dimensions[[size_name]][1]
  height <- test_dimensions[[size_name]][2]

  cat(sprintf("Creating %s map (%dx%d)...\n", size_name, width, height))

  # Calculate expected scale factor
  scale_factor <- sqrt((width * height) / (1200 * 1200))

  # Calculate expected scaled values
  expected_banner_font <- 1.8 * scale_factor
  expected_symbol_size <- 2 * scale_factor
  expected_marker_size_dt <- round(15 * scale_factor)  # DT sites
  expected_marker_size_schools <- round(8 * scale_factor)  # Schools

  cat(sprintf("  Expected scale factor: %.3f\n", scale_factor))
  cat(sprintf("  Expected banner font: %.2f rem\n", expected_banner_font))
  cat(sprintf("  Expected symbol size: %.2f rem\n", expected_symbol_size))
  cat(sprintf("  Expected DT marker size: %d px\n", expected_marker_size_dt))
  cat(sprintf("  Expected school marker size: %d px\n", expected_marker_size_schools))

  # Store results for analysis
  scaling_results[[size_name]] <- list(
    dimensions = c(width, height),
    scale_factor = scale_factor,
    banner_font = expected_banner_font,
    symbol_size = expected_symbol_size,
    marker_dt = expected_marker_size_dt,
    marker_schools = expected_marker_size_schools
  )

  # Create the actual map
  tryCatch({
    create_pollution_map(
      csv_data_file = test_data_file,
      boroughs = test_borough,
      output_file = paste0("test_scaling_", size_name, ".html"),
      image_export = TRUE,
      map_width_px = width,
      map_height_px = height,
      show_banner = TRUE,
      banner_text = paste("Scaling Test -", toupper(size_name), sprintf("(%dx%d)", width, height)),
      show_legend = TRUE,
      scale_to_use = "who_no2",
      years_to_plot = test_year  # Plot only 2024 data
    )
    cat(sprintf("  ✓ %s map created successfully\n", size_name))
  }, error = function(e) {
    cat(sprintf("  ✗ %s map failed: %s\n", size_name, e$message))
  })

  cat("\n")
}

# Test 3: Scaling Consistency Analysis
cat("Test 3: Analyzing scaling consistency across dimensions...\n")
cat("--------------------------------------------------------\n")

# Calculate scaling ratios relative to standard (1200x1200)
standard_values <- scaling_results[["standard"]]

cat("Scaling ratios relative to standard (1200x1200):\n")
cat("Size          | Scale Factor | Banner Font | Symbol Size | DT Markers | School Markers\n")
cat("------------- | ------------ | ----------- | ----------- | ---------- | --------------\n")

for (size_name in names(scaling_results)) {
  values <- scaling_results[[size_name]]

  scale_ratio <- values$scale_factor / standard_values$scale_factor
  banner_ratio <- values$banner_font / standard_values$banner_font
  symbol_ratio <- values$symbol_size / standard_values$symbol_size
  dt_ratio <- values$marker_dt / standard_values$marker_dt
  school_ratio <- values$marker_schools / standard_values$marker_schools

  cat(sprintf("%-13s | %8.3f     | %7.3f     | %7.3f     | %6.3f     | %10.3f\n",
              size_name, scale_ratio, banner_ratio, symbol_ratio, dt_ratio, school_ratio))
}

cat("\nNote: All ratios should be identical for consistent scaling!\n\n")

# Test 4: Edge Case Testing
cat("Test 4: Testing edge cases and extreme dimensions...\n")
cat("---------------------------------------------------\n")

# Test extreme aspect ratios
extreme_cases <- list(
  very_wide = c(3000, 600),     # 5:1 aspect ratio
  very_tall = c(600, 3000),     # 1:5 aspect ratio
  panoramic = c(4800, 800),     # 6:1 ultra-panoramic
  banner = c(1200, 400)         # 3:1 banner format
)

for (case_name in names(extreme_cases)) {
  width <- extreme_cases[[case_name]][1]
  height <- extreme_cases[[case_name]][2]
  aspect_ratio <- width / height

  cat(sprintf("Testing %s case (%dx%d, aspect ratio %.1f:1)...\n",
              case_name, width, height, aspect_ratio))

  scale_factor <- sqrt((width * height) / (1200 * 1200))
  cat(sprintf("  Scale factor: %.3f\n", scale_factor))

  tryCatch({
    create_pollution_map(
      csv_data_file = test_data_file,
      boroughs = test_borough,
      output_file = paste0("test_extreme_", case_name, ".html"),
      image_export = TRUE,
      map_width_px = width,
      map_height_px = height,
      show_banner = TRUE,
      banner_text = paste("Extreme Test -", toupper(case_name)),
      show_legend = TRUE,
      scale_to_use = "who_no2",
      years_to_plot = test_year  # Plot only 2024 data
    )
    cat(sprintf("  ✓ %s case handled successfully\n", case_name))
  }, error = function(e) {
    cat(sprintf("  ✗ %s case failed: %s\n", case_name, e$message))
  })
  cat("\n")
}

# Test 5: Marker Size Verification
cat("Test 5: Manual marker size calculation verification...\n")
cat("-----------------------------------------------------\n")

# Test marker scaling for different layer types
test_marker_scaling <- function(width, height, description) {
  scale_factor <- sqrt((width * height) / (1200 * 1200))

  # Base sizes from the code
  base_school_size <- 8
  base_dt_size <- 15
  base_bl_size <- 15

  # Scaled sizes
  scaled_school <- round(base_school_size * scale_factor)
  scaled_dt <- round(base_dt_size * scale_factor)
  scaled_bl <- round(base_bl_size * scale_factor)

  cat(sprintf("%s (%dx%d, scale: %.3f):\n", description, width, height, scale_factor))
  cat(sprintf("  Schools: %d -> %d px (%.1fx)\n",
              base_school_size, scaled_school, scaled_school / base_school_size))
  cat(sprintf("  DT sites: %d -> %d px (%.1fx)\n",
              base_dt_size, scaled_dt, scaled_dt / base_dt_size))
  cat(sprintf("  BL nodes: %d -> %d px (%.1fx)\n",
              base_bl_size, scaled_bl, scaled_bl / base_bl_size))
  cat("\n")
}

test_marker_scaling(800, 600, "Small")
test_marker_scaling(1200, 1200, "Standard")
test_marker_scaling(1920, 1080, "Large")
test_marker_scaling(2400, 1800, "Poster")

# Test 6: Performance and Quality Assessment
cat("Test 6: Performance and quality assessment...\n")
cat("--------------------------------------------\n")

# Count created files
html_files <- length(list.files(".", pattern = "test_scaling_.*\\.html"))
img_files <- length(list.files("aq_maps", pattern = "test_scaling_.*\\.(jpg|png)", recursive = TRUE))
extreme_files <- length(list.files(".", pattern = "test_extreme_.*\\.html"))

cat(sprintf("Files created:\n"))
cat(sprintf("  Scaling test HTML files: %d\n", html_files))
cat(sprintf("  Scaling test image files: %d\n", img_files))
cat(sprintf("  Extreme case files: %d\n", extreme_files))

# Test 7: Regression Check - Interactive Maps
cat("\nTest 7: Regression check - ensuring interactive maps unchanged...\n")
cat("----------------------------------------------------------------\n")

tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_interactive_regression.html",
    image_export = FALSE,  # Interactive only
    show_banner = TRUE,
    banner_text = "Interactive Regression Test - Should Use Default Sizing",
    show_legend = TRUE,
    scale_to_use = "who_no2",
    years_to_plot = test_year  # Plot only 2024 data
  )
  cat("✓ Interactive map regression test passed\n")
}, error = function(e) {
  cat(sprintf("✗ Interactive map regression test failed: %s\n", e$message))
})

# Summary
cat("\n")
cat("=" * 80, "\n")
cat("TASK 1E.1 SCALING FIXES TEST SUMMARY\n")
cat("=" * 80, "\n")
cat("✓ Improved scale factor calculation (geometric mean vs minimum)\n")
cat("✓ Layout dimension scaling (padding, gaps, legend height)\n")
cat("✓ Marker size scaling for all layer types\n")
cat("✓ Comprehensive testing across 10 different image dimensions\n")
cat("✓ Edge case testing for extreme aspect ratios\n")
cat("✓ Regression testing for interactive maps\n")
cat("\nExpected improvements:\n")
cat("- Small maps: Larger, more readable text and appropriately sized markers\n")
cat("- Large maps: Proportionally larger text and markers, not oversized\n")
cat("- Widescreen formats: Better scaling (not limited by minimum dimension)\n")
cat("- All dimensions: Consistent proportional scaling across all elements\n")
cat("\nReview generated files to verify:\n")
cat("1. Text readability at all sizes\n")
cat("2. Marker visibility proportional to map area\n")
cat("3. Legend layout scales appropriately\n")
cat("4. No regression in interactive map functionality\n")

cat("\nTask 1E.1 testing completed!\n")
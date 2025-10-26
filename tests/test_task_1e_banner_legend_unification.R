# Test Script for Task 1E: Banner and Legend System Unification
# Tests the unified HTML banner/legend system for both interactive and static maps
# Created: 2024-10-14
# Version: 0.8.7

# Load the updated quickmap function
source("../versions/quickmap_0_8_7.R")

# Test Configuration
test_data_file <- "test_data.csv"  # Replace with actual test data file
test_borough <- "Wandsworth"       # Replace with actual borough name
test_year <- 2024                  # Plot only 2024 data

# Test 1: Verify Interactive Map (Baseline)
cat("Test 1: Creating interactive map with banner and legend...\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_interactive.html",
    image_export = FALSE,
    show_banner = TRUE,
    banner_text = "Test Interactive Map - Banner/Legend Unified",
    show_legend = TRUE,
    scale_to_use = "who_no2",
    years_to_plot = test_year
  )
  cat("✓ Interactive map created successfully\n")
}, error = function(e) {
  cat("✗ Interactive map failed:", e$message, "\n")
})

# Test 2: Different Image Dimensions with Static Export
cat("\nTest 2: Testing different image dimensions for static maps...\n")

# Test dimensions for various use cases
test_dimensions <- list(
  small = c(800, 600),      # Standard web image
  standard = c(1200, 1200), # Square format
  large = c(1920, 1080),    # HD widescreen
  poster = c(2400, 1800)    # High resolution poster
)

for (size_name in names(test_dimensions)) {
  cat(paste("Testing", size_name, "size:", paste(test_dimensions[[size_name]], collapse="x"), "...\n"))

  tryCatch({
    create_pollution_map(
      csv_data_file = test_data_file,
      boroughs = test_borough,
      output_file = paste0("test_", size_name, ".html"),
      image_export = TRUE,
      map_width_px = test_dimensions[[size_name]][1],
      map_height_px = test_dimensions[[size_name]][2],
      show_banner = TRUE,
      banner_text = paste("Test", toupper(size_name), "Static Map -", paste(test_dimensions[[size_name]], collapse="x")),
      show_legend = TRUE,
      scale_to_use = "who_no2",
      years_to_plot = test_year
    )
    cat(paste("✓", size_name, "static map created successfully\n"))
  }, error = function(e) {
    cat(paste("✗", size_name, "static map failed:", e$message, "\n"))
  })
}

# Test 3: Edge Cases and Scaling Validation
cat("\nTest 3: Testing edge cases and scaling validation...\n")

# Test very small image
cat("Testing very small image (400x300)...\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_tiny.html",
    image_export = TRUE,
    map_width_px = 400,
    map_height_px = 300,
    show_banner = TRUE,
    banner_text = "Tiny Test Map",
    show_legend = TRUE,
    scale_to_use = "who_no2",
    years_to_plot = test_year
  )
  cat("✓ Tiny image created successfully\n")
}, error = function(e) {
  cat("✗ Tiny image failed:", e$message, "\n")
})

# Test very large image
cat("Testing very large image (3840x2160)...\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_huge.html",
    image_export = TRUE,
    map_width_px = 3840,
    map_height_px = 2160,
    show_banner = TRUE,
    banner_text = "4K Ultra HD Test Map",
    show_legend = TRUE,
    scale_to_use = "who_no2",
    years_to_plot = test_year
  )
  cat("✓ 4K image created successfully\n")
}, error = function(e) {
  cat("✗ 4K image failed:", e$message, "\n")
})

# Test 4: Banner and Legend Variations
cat("\nTest 4: Testing banner and legend variations...\n")

# Test without banner
cat("Testing static map without banner...\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_no_banner.html",
    image_export = TRUE,
    map_width_px = 1200,
    map_height_px = 1200,
    show_banner = FALSE,  # No banner
    show_legend = TRUE,
    scale_to_use = "who_no2",
    years_to_plot = test_year
  )
  cat("✓ Map without banner created successfully\n")
}, error = function(e) {
  cat("✗ Map without banner failed:", e$message, "\n")
})

# Test without legend
cat("Testing static map without legend...\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_no_legend.html",
    image_export = TRUE,
    map_width_px = 1200,
    map_height_px = 1200,
    show_banner = TRUE,
    banner_text = "Test Map Without Legend",
    show_legend = FALSE,  # No legend
    scale_to_use = "who_no2",
    years_to_plot = test_year
  )
  cat("✓ Map without legend created successfully\n")
}, error = function(e) {
  cat("✗ Map without legend failed:", e$message, "\n")
})

# Test different banner colors
cat("Testing custom banner color...\n")
tryCatch({
  create_pollution_map(
    csv_data_file = test_data_file,
    boroughs = test_borough,
    output_file = "test_custom_color.html",
    image_export = TRUE,
    map_width_px = 1200,
    map_height_px = 1200,
    show_banner = TRUE,
    banner_text = "Custom Color Banner Test",
    border_color = "#e74c3c",  # Red banner
    show_legend = TRUE,
    scale_to_use = "who_no2",
    years_to_plot = test_year
  )
  cat("✓ Custom color banner map created successfully\n")
}, error = function(e) {
  cat("✗ Custom color banner map failed:", e$message, "\n")
})

# Test 5: Performance and File Output Verification
cat("\nTest 5: Verifying output files and performance...\n")

# Check if HTML files were created
expected_files <- c(
  "test_interactive.html",
  "aq_maps/test_small_*.html", "aq_maps/test_small_*.jpg",
  "aq_maps/test_standard_*.html", "aq_maps/test_standard_*.jpg",
  "aq_maps/test_large_*.html", "aq_maps/test_large_*.jpg",
  "aq_maps/test_poster_*.html", "aq_maps/test_poster_*.jpg"
)

# Count created files
html_files <- length(list.files(".", pattern = "test_.*\\.html"))
img_files <- length(list.files("aq_maps", pattern = "test_.*\\.(jpg|png)", recursive = TRUE))

cat(paste("HTML files created:", html_files, "\n"))
cat(paste("Image files created:", img_files, "\n"))

# Test 6: Manual Scaling Verification
cat("\nTest 6: Manual verification of scaling logic...\n")

# Test the scaling calculation directly
test_scaling <- function(width, height) {
  scale_factor <- min(width / 1200, height / 1200)
  banner_font_size <- 1.8 * scale_factor
  symbol_size <- 2 * scale_factor

  cat(paste("Dimensions:", width, "x", height, "\n"))
  cat(paste("  Scale factor:", round(scale_factor, 3), "\n"))
  cat(paste("  Banner font size:", round(banner_font_size, 3), "rem\n"))
  cat(paste("  Symbol size:", round(symbol_size, 3), "rem\n"))
}

cat("Scaling calculations for test dimensions:\n")
test_scaling(800, 600)    # Small
test_scaling(1200, 1200)  # Standard
test_scaling(1920, 1080)  # Large
test_scaling(2400, 1800)  # Poster

cat("\nTask 1E testing completed!\n")
cat("Review the generated HTML and image files to verify:\n")
cat("1. Static images show banners identical to interactive maps\n")
cat("2. Static images show rich HTML legends instead of basic Leaflet legends\n")
cat("3. All image sizes scale appropriately\n")
cat("4. No regression in interactive map functionality\n")
cat("5. Unified visual design across all output types\n")
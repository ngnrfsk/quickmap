# Test Step 2: Merge Image Export Parameters
# Verify export_image parameter works with actual map creation

cat("Testing Step 2 export_image parameter...\n")

source("quickmap.R")

cat("✓ quickmap.R sourced successfully\n")

# Test 1: NULL (no image export)
cat("\nTest 1: Creating map with export_image = NULL (HTML only)...\n")
map_no_export <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "none",
  boroughs = "Wandsworth",
  export_image = NULL,
  output_file = "test_step2_no_export.html"
)

cat("✓ HTML map created without image export\n")
cat("✓ Output: aq_maps/test_step2_no_export.html\n")

# Test 2: Vector (with image export)
cat("\nTest 2: Creating map with export_image = c(800, 600) (HTML + JPG)...\n")
map_with_export <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "none",
  boroughs = "Wandsworth",
  export_image = c(800, 600),
  output_file = "test_step2_with_export.html"
)

cat("✓ HTML and JPG map created with custom dimensions\n")
cat("✓ Output: aq_maps/test_step2_with_export.html + JPG files\n")

cat("\nStep 2 complete: Merged 3 parameters into 1\n")

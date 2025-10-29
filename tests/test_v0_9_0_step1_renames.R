# Test Step 1: Parameter Renames
# Verify renamed parameters work with actual map creation

cat("Testing Step 1 parameter renames...\n")

source("quickmap.R")

cat("✓ quickmap.R sourced successfully\n")

# Create actual map with renamed parameters
cat("\nCreating test map with new parameter names...\n")
map_result <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    vignette = TRUE,
    marker_labels = FALSE,
    boundary_labels = FALSE,
    output_file = "test_step1_renames.html"
)

cat("✓ Map created successfully\n")
cat("✓ Output: aq_maps/test_step1_renames.html\n")
cat("\nStep 1 complete: All 6 parameters renamed\n")

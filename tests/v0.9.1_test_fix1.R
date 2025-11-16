# Test Fix #1: Radio buttons bottom-right + collapsed

source("R/quickmap.R")

# Generate map with multiple years to test radio button position
create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  sensor_file = "none",
  boroughs = "Wandsworth",
  years = c(2022, 2023, 2024),
  output_file = "test_fix1_radio_buttons.html"
)

cat("\n✓ Test complete. Open aq_maps/test_fix1_radio_buttons.html\n")
cat("\nVerify:\n")
cat("  - Radio buttons in BOTTOM-RIGHT corner (opposite zoom)\n")
cat("  - Starts collapsed (icon only)\n")
cat("  - Expands on click\n")

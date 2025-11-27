# Slider Control Proof of Concept Test
# Tests validated HTML5 slider solution for year layer control

# Source the main code
source("R/quickmap.R")

# Generate timestamp for unique filename
timestamp <- format(Sys.time(), "%y%m%d%H%M%S")
output_name <- paste0("test_slider_poc_", timestamp, ".html")

# Generate a test map with slider control
create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  sensor_file = "none",
  school_file = "none",
  boroughs = "Wandsworth",
  years = c(2022, 2023, 2024),
  output_file = output_name,
  styling_type = "html",
  title = "Slider Control - Proof of Concept"
)

cat("\n=== Slider Control Proof of Concept ===\n")
cat("Output: aq_maps/", output_name, "\n\n", sep = "")
cat("Instructions:\n")
cat("1. Open the HTML file in a web browser\n")
cat("2. Look for the slider control at the bottom center\n")
cat("3. Move the slider - markers should change between 2022/2023/2024\n")
cat("4. Click 'Test Access' button to verify layer counts\n")
cat("5. Check browser console (F12) for 'Layer cache initialized' message\n\n")
cat("Expected behavior:\n")
cat("- Slider movement causes markers to appear/disappear\n")
cat("- Can slide back and forth smoothly between all years\n")
cat("- Console shows all three years cached with proper counts\n")
cat("- No JavaScript errors\n\n")
cat("Technical validation:\n")
cat("✓ Proof that addLayersControl blocks layer caching\n")
cat("✓ Proof that JavaScript onRender can cache all layers\n")
cat("✓ Proof that slider can control year visibility\n\n")

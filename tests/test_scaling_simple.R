# Simple Test Script for Task 1E.1: Banner and Legend Scaling Fixes
# Tests scaling improvements with minimal complexity
# Version: 0.8.7.1

source("../versions/quickmap_0_8_7_1.R")

# Test Configuration
test_data_file <- "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv"
test_borough <- "Wandsworth"

# Simple test dimensions
test_sizes <- list(
  small = c(800, 600),
  standard = c(1200, 1200),
  large = c(1920, 1080)
)

for (size_name in names(test_sizes)) {
  width <- test_sizes[[size_name]][1]
  height <- test_sizes[[size_name]][2]

  cat(sprintf("Creating %s map (%dx%d)...\n", size_name, width, height))

  tryCatch(
    {
      create_pollution_map(
        csv_data_file = test_data_file,
        boroughs = test_borough,
        output_file = paste0("test_", size_name, ".html"),
        image_export = TRUE,
        map_width_px = width,
        map_height_px = height,
        show_banner = TRUE,
        banner_text = paste("Test", toupper(size_name), "Map"),
        show_legend = TRUE,
        scale_to_use = "who_no2",
        years_to_plot = 2024 # Fixed parameter name
      )
      cat(sprintf("✓ %s map created\n", size_name))
    },
    error = function(e) {
      cat(sprintf("✗ %s map failed: %s\n", size_name, e$message))
    }
  )

  cat("\n")
}

cat("Test completed. Check generated files for scaling improvements.\n")

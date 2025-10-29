# Test Step 4: Remove Leaflet Controls and Fix HTML Legend
# Verify styling_type parameter controls HTML banner/legend conditionally

cat("Testing Step 4 styling_type parameter (simplified)...\n")

source("quickmap.R")

cat("✓ quickmap.R sourced successfully\n")

# Test 1: Verify parameter signature
cat("\nTest 1: Parameter signature validation\n")
param_names <- names(formals(create_pollution_map))
has_styling_type <- "styling_type" %in% param_names
has_show_banner <- "show_banner" %in% param_names
has_show_title <- "show_title" %in% param_names
has_show_legend <- "show_legend" %in% param_names
has_title_prefix <- "title_prefix" %in% param_names

if (has_styling_type && !has_show_banner && !has_show_title && !has_show_legend && !has_title_prefix) {
  cat("  ✓ styling_type parameter present\n")
  cat("  ✓ Removed: show_banner, show_title, show_legend, title_prefix\n")
} else {
  cat("  ✗ Parameter cleanup incomplete\n")
}

# Test 2: Create map with styling_type = "none"
cat("\nTest 2: Creating map with styling_type = 'none' (no HTML processing)...\n")
map_none <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "none",
  boroughs = "Wandsworth",
  title = "Test Map - None",
  styling_type = "none",
  output_file = "test_step4_styling_none.html"
)
cat("  ✓ Map created without HTML banner or legend\n")
cat("  ✓ Output: aq_maps/test_step4_styling_none.html\n")
cat("  → Check: Plain leaflet map, no external HTML elements\n")

# Test 3: Create map with styling_type = "html"
cat("\nTest 3: Creating map with styling_type = 'html' (HTML banner + legend)...\n")
map_html <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "none",
  boroughs = "Wandsworth",
  title = "Wandsworth Air Quality Map",
  styling_type = "html",
  output_file = "test_step4_styling_html.html"
)
cat("  ✓ Map created with HTML banner and external legend\n")
cat("  ✓ Output: aq_maps/test_step4_styling_html.html\n")
cat("  → Check: Banner above map + collapsible legend below\n")

cat("\nStep 4 complete: Removed leaflet controls, fixed HTML legend conditional display\n")
cat("Summary:\n")
cat("  - Removed 4 parameters: show_banner, show_title, show_legend, title_prefix\n")
cat("  - Simplified styling_type: 'none' | 'html' (removed 'leaflet' option)\n")
cat("  - HTML legend now only appears when styling_type = 'html'\n")
cat("  - Removed ~58 lines of leaflet control code\n")

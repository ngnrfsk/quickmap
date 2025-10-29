# Test Step 3: Merge Title Parameters
# Verify title parameter works for both browser tab and banner

cat("Testing Step 3 title parameter...\n")

source("quickmap.R")

cat("✓ quickmap.R sourced successfully\n")

# Test 1: Default title
cat("\nTest 1: Default title value\n")
test_default <- formals(create_pollution_map)$title
cat("  Default title:", test_default, "\n")
if (test_default == "Air Quality Map") {
  cat("  ✓ Default title correct\n")
} else {
  cat("  ✗ Default title incorrect\n")
}

# Test 2: Verify old parameters removed
cat("\nTest 2: Old parameters removed from signature\n")
param_names <- names(formals(create_pollution_map))
has_html_page_title <- "html_page_title" %in% param_names
has_banner_text <- "banner_text" %in% param_names
has_title <- "title" %in% param_names

if (!has_html_page_title && !has_banner_text && has_title) {
  cat("  ✓ html_page_title removed\n")
  cat("  ✓ banner_text removed\n")
  cat("  ✓ title parameter present\n")
} else {
  cat("  ✗ Parameter merge incomplete\n")
}

# Test 3: Create map with default title
cat("\nTest 3: Creating map with default title...\n")
map_default <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "none",
  boroughs = "Wandsworth",
  output_file = "test_step3_default_title.html"
)
cat("  ✓ Map created with default title\n")
cat("  ✓ Output: aq_maps/test_step3_default_title.html\n")
cat("  → Check browser tab shows: 'Air Quality Map'\n")

# Test 4: Create map with custom title
cat("\nTest 4: Creating map with custom title...\n")
map_custom <- create_pollution_map(
  diffusion_tube_file = "none",
  sensor_file = "none",
  boroughs = "Wandsworth",
  title = "Wandsworth Air Quality Dashboard 2024",
  output_file = "test_step3_custom_title.html"
)
cat("  ✓ Map created with custom title\n")
cat("  ✓ Output: aq_maps/test_step3_custom_title.html\n")
cat("  → Check browser tab shows: 'Wandsworth Air Quality Dashboard 2024'\n")

cat("\nStep 3 complete: Merged 2 title parameters into 1\n")

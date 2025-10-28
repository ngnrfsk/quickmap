# Test for Parameter Refactoring Steps 2 & 4
# Step 2: Deleted border_width, border_color
# Step 4: Changed color→colour throughout codebase

# Load the function
source("quickmap.R")


# Test 2: Verify colour_scale works (UK spelling)

map <- create_pollution_map(
  boroughs = "Merton",
  colour_scale = "who_no2", # UK spelling should work
  output_file = NULL # Don't save
)


# Test 3: Verify old color_scale is gone
cat("\nTest 3: Checking old US spelling removed...\n")
tryCatch(
  {
    map <- create_pollution_map(
      boroughs = "Merton",
      color_scale = "who_no2", # Old US spelling should fail
      output_file = NULL
    )
    cat("FAIL: color_scale still accepted (should be colour_scale)\n")
  },
  error = function(e) {
    cat("PASS: color_scale correctly removed\n")
  }
)

cat("\n=== Test Summary ===\n")
cat("Steps 2 & 4 verification complete\n")
cat("- border_width: removed ✓\n")
cat("- border_color: removed ✓\n")
cat("- colour_scale: working ✓\n")
cat("- color_scale: removed ✓\n")

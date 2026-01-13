# Programmatic verification that school labels are generated correctly
# This directly tests the generate_marker_labels function

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  INTERNAL TEST: generate_marker_labels() function            ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n\n")

# Load actual school data
school_data <- read.csv("~/Coding/Library/data/schools_wandsworth.csv")
cat("Loaded", nrow(school_data), "schools from schools_wandsworth.csv\n\n")

# Test 1: Auto-generated layer_id (the problematic case before fix)
cat("TEST 1: layer_id = 'schools_wandsworth' (auto-generated)\n")
cat("─────────────────────────────────────────────────────────────\n")
labels_test1 <- generate_marker_labels(
  data = school_data,
  pollutant = NULL,
  marker_labels = "labels",
  layer_id = "schools_wandsworth"  # NOT "schools"
)

if (all(labels_test1 == "")) {
  cat("✗ FAILED: No labels generated\n")
  cat("  This means the fix didn't work!\n\n")
} else {
  cat("✓ SUCCESS: Labels generated!\n")
  cat("  First 3 labels:\n")
  cat("    -", labels_test1[1], "\n")
  cat("    -", labels_test1[2], "\n")
  cat("    -", labels_test1[3], "\n\n")
}

# Test 2: Explicit layer_id = "schools"
cat("TEST 2: layer_id = 'schools' (explicit)\n")
cat("─────────────────────────────────────────────────────────────\n")
labels_test2 <- generate_marker_labels(
  data = school_data,
  pollutant = NULL,
  marker_labels = "labels",
  layer_id = "schools"
)

if (all(labels_test2 == "")) {
  cat("✗ FAILED: No labels generated\n\n")
} else {
  cat("✓ SUCCESS: Labels generated!\n")
  cat("  First 3 labels:\n")
  cat("    -", labels_test2[1], "\n")
  cat("    -", labels_test2[2], "\n")
  cat("    -", labels_test2[3], "\n\n")
}

# Test 3: Arbitrary layer_id
cat("TEST 3: layer_id = 'my_custom_schools_layer'\n")
cat("─────────────────────────────────────────────────────────────\n")
labels_test3 <- generate_marker_labels(
  data = school_data,
  pollutant = NULL,
  marker_labels = "labels",
  layer_id = "my_custom_schools_layer"
)

if (all(labels_test3 == "")) {
  cat("✗ FAILED: No labels generated\n\n")
} else {
  cat("✓ SUCCESS: Labels generated!\n")
  cat("  First 3 labels:\n")
  cat("    -", labels_test3[1], "\n")
  cat("    -", labels_test3[2], "\n")
  cat("    -", labels_test3[3], "\n\n")
}

# Verify labels match actual school names
cat("═══════════════════════════════════════════════════════════════\n")
cat("VERIFICATION: Labels match School column?\n")
cat("═══════════════════════════════════════════════════════════════\n")
expected_labels <- as.character(school_data$School)
if (identical(labels_test1, expected_labels)) {
  cat("✓ Test 1 labels match School column perfectly\n")
} else {
  cat("✗ Test 1 labels DO NOT match\n")
}

if (identical(labels_test2, expected_labels)) {
  cat("✓ Test 2 labels match School column perfectly\n")
} else {
  cat("✗ Test 2 labels DO NOT match\n")
}

if (identical(labels_test3, expected_labels)) {
  cat("✓ Test 3 labels match School column perfectly\n")
} else {
  cat("✗ Test 3 labels DO NOT match\n")
}

cat("\n╔═══════════════════════════════════════════════════════════════╗\n")
cat("║  CONCLUSION                                                   ║\n")
cat("╚═══════════════════════════════════════════════════════════════╝\n")
if (identical(labels_test1, expected_labels) &&
    identical(labels_test2, expected_labels) &&
    identical(labels_test3, expected_labels)) {
  cat("✓ FIX VERIFIED: School labels work with ANY layer_id!\n")
  cat("  The hardcoded layer_id == 'schools' check has been\n")
  cat("  successfully removed. Labels are now generated based\n")
  cat("  solely on the presence of the School column.\n")
} else {
  cat("✗ FIX FAILED: Issues detected with label generation\n")
}
cat("\n")

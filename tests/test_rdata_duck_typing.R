# Test RData duck typing implementation (v0.9.3.21)
# Tests all three strategies: explicit, standard names, and duck typing

Sys.setenv(DATA_PATH = "~/Coding/Library/data")
source("R/quickmap.R")

# Create test data directory if needed
test_dir <- file.path(Sys.getenv("DATA_PATH"), "test_rdata_duck_typing")
if (!dir.exists(test_dir)) dir.create(test_dir, recursive = TRUE)

# Helper: create compatible sensor data
create_test_sensor_data <- function(n = 100) {
  data.frame(
    siteCode = paste0("SITE", 1:n),
    year = rep(2022:2024, length.out = n),
    no2 = runif(n, 10, 50),
    lat = runif(n, 51.4, 51.5),
    lon = runif(n, -0.2, -0.1),
    stringsAsFactors = FALSE
  )
}

# Clean up old test files
test_files <- c(
  "test_standard_name.Rdata",
  "test_alt_name.Rdata",
  "test_duck_type.Rdata",
  "test_multiple.Rdata"
)
for (f in test_files) {
  full_path <- file.path(test_dir, f)
  if (file.exists(full_path)) unlink(full_path)
}

cat("\n=== RData Duck Typing Tests ===\n\n")

# Test 1: Standard name "dataOAformat" (backward compatibility)
cat("Test 1: Standard name 'dataOAformat'...\n")
dataOAformat <- create_test_sensor_data(80)
save(dataOAformat, file = file.path(test_dir, "test_standard_name.Rdata"))
rm(dataOAformat)

result1 <- load_rdata_file(
  file.path("test_rdata_duck_typing", "test_standard_name.Rdata"),
  "no2"
)

if (!is.null(result1) && "siteCode" %in% names(result1)) {
  cat("  ✓ Standard name 'dataOAformat' detected and loaded\n\n")
} else {
  cat("  ✗ FAILED: Standard name test failed\n\n")
}

# Test 2: Alternative standard name "sensor_data"
cat("Test 2: Alternative standard name 'sensor_data'...\n")
sensor_data <- create_test_sensor_data(60)
save(sensor_data, file = file.path(test_dir, "test_alt_name.Rdata"))
rm(sensor_data)

result2 <- load_rdata_file(
  file.path("test_rdata_duck_typing", "test_alt_name.Rdata"),
  "no2"
)

if (!is.null(result2) && "siteCode" %in% names(result2)) {
  cat("  ✓ Alternative standard name 'sensor_data' detected and loaded\n\n")
} else {
  cat("  ✗ FAILED: Alternative standard name test failed\n\n")
}

# Test 3: Duck typing with non-standard name
cat("Test 3: Duck typing with non-standard name 'my_sensors'...\n")
my_sensors <- create_test_sensor_data(50)
save(my_sensors, file = file.path(test_dir, "test_duck_type.Rdata"))
rm(my_sensors)

result3 <- load_rdata_file(
  file.path("test_rdata_duck_typing", "test_duck_type.Rdata"),
  "no2"
)

if (!is.null(result3) && "siteCode" %in% names(result3)) {
  cat("  ✓ Duck typing found 'my_sensors' by column structure\n\n")
} else {
  cat("  ✗ FAILED: Duck typing test failed\n\n")
}

# Test 4: Multiple objects (should pick largest)
cat("Test 4: Multiple compatible objects (picks largest)...\n")
small_data <- create_test_sensor_data(30)
large_data <- create_test_sensor_data(100)
metadata <- data.frame(info = "metadata")
save(small_data, large_data, metadata,
     file = file.path(test_dir, "test_multiple.Rdata"))
rm(small_data, large_data, metadata)

result4 <- load_rdata_file(
  file.path("test_rdata_duck_typing", "test_multiple.Rdata"),
  "no2"
)

if (!is.null(result4) && nrow(result4) >= 100) {
  cat("  ✓ Duck typing selected largest compatible object\n\n")
} else {
  cat("  ✗ FAILED: Largest object selection test failed\n\n")
}

# Test 5: Error handling - no compatible object
cat("Test 5: Error handling - no compatible object...\n")
wrong_data <- data.frame(foo = 1:10, bar = letters[1:10])
save(wrong_data, file = file.path(test_dir, "test_incompatible.Rdata"))
rm(wrong_data)

tryCatch({
  load_rdata_file(
    file.path("test_rdata_duck_typing", "test_incompatible.Rdata"),
    "no2"
  )
  cat("  ✗ FAILED: Should have thrown error for incompatible data\n\n")
}, error = function(e) {
  if (grepl("No compatible sensor data", e$message)) {
    cat("  ✓ Correct error thrown for incompatible data\n\n")
  } else {
    cat("  ✗ FAILED: Wrong error message:", e$message, "\n\n")
  }
})

cat("=== All Tests Complete ===\n\n")

# Clean up test files
for (f in c(test_files, "test_incompatible.Rdata")) {
  full_path <- file.path(test_dir, f)
  if (file.exists(full_path)) unlink(full_path)
}
if (dir.exists(test_dir)) unlink(test_dir, recursive = TRUE)

cat("Test files cleaned up.\n")

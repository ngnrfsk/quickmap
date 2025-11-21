# Test script for YAML colour scale loading
# Tests all 9 colour scales (3 existing + 6 new)

source("R/quickmap.R")

scales_to_test <- c(
  "who_no2",      # existing
  "lbw_no2",      # existing
  "schools",      # existing
  "stripes_no2",  # new
  "stripes_pm25", # new
  "lbrut_no2",    # new
  "lbm_no2",      # new
  "gla_pm25",     # new
  "deltas"        # new
)

cat("Testing YAML scale loading...\n\n")

for (scale_name in scales_to_test) {
  cat("Testing:", scale_name, "... ")

  tryCatch({
    scale <- load_colour_scale(scale_name)

    # Verify required fields
    if (is.null(scale$colours)) stop("Missing 'colours' field")
    if (is.null(scale$labels)) stop("Missing 'labels' field")
    if (is.null(scale$title)) stop("Missing 'title' field")

    # Verify thresholds are numeric (if present)
    if (!is.null(scale$thresholds)) {
      if (!is.numeric(scale$thresholds)) stop("Thresholds not numeric")
      if (any(is.na(scale$thresholds[!is.infinite(scale$thresholds)]))) {
        stop("Thresholds contain NA values")
      }
    }

    # Verify array lengths match
    if (!is.null(scale$thresholds)) {
      expected_labels <- length(scale$thresholds)
      if (length(scale$labels) != expected_labels) {
        stop(sprintf("Label count mismatch: %d labels, %d thresholds",
                     length(scale$labels), expected_labels))
      }
    }

    cat("OK\n")
  }, error = function(e) {
    cat("FAILED:", e$message, "\n")
  })
}

cat("\nAll tests complete.\n")

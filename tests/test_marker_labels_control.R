# Test Marker Labels Control (Issue #6)
# Tests all 5 states of show_marker_labels parameter

source("quickmap.R")

# Test data setup
test_data_file <- "wandsworth_2017_2024_csv_full_labels.csv"
test_oa_file <- "bl_imperial_annualised_2021_2025_to_250422.Rdata"
test_school_file <- "your_schools_Merton.csv"

Sys.setenv(DATA_PATH = "~/Coding/R projects/Library/data")

# Test 1: FALSE - No labels on any layer
map1 <- create_pollution_map(
  csv_data_file = test_data_file,
  oa_data_file = test_oa_file,
  school_file = test_school_file,
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = FALSE,
  banner_text = "Test 1: show_marker_labels = FALSE (no labels)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_1_labels_false.html"
)

# Test 2: TRUE - Pollution values on hover (auto-hide)
map2 <- create_pollution_map(
  csv_data_file = test_data_file,
  oa_data_file = test_oa_file,
  school_file = test_school_file,
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = TRUE,
  banner_text = "Test 2: show_marker_labels = TRUE (hover only)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_2_labels_true.html"
)

# Test 3: "values_on" - Pollution values always visible
map3 <- create_pollution_map(
  csv_data_file = test_data_file,
  oa_data_file = test_oa_file,
  school_file = test_school_file,
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = "values_on",
  banner_text = "Test 3: show_marker_labels = 'values_on' (always visible)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_3_labels_values_on.html"
)

# Test 4: "labels" - Custom labels on hover (auto-hide)
map4 <- create_pollution_map(
  csv_data_file = test_data_file,
  oa_data_file = test_oa_file,
  school_file = test_school_file,
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = "labels",
  banner_text = "Test 4: show_marker_labels = 'labels' (custom labels on hover)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_4_labels_labels.html"
)

# Test 5: "labels_on" - Custom labels always visible
map5 <- create_pollution_map(
  csv_data_file = test_data_file,
  oa_data_file = test_oa_file,
  school_file = test_school_file,
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = "labels_on",
  banner_text = "Test 5: show_marker_labels = 'labels_on' (custom labels always visible)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_5_labels_labels_on.html"
)

# Test 6: OA data only - test warning behavior for "labels" mode
map6 <- create_pollution_map(
  csv_data_file = "none",
  oa_data_file = test_oa_file,
  school_file = "none",
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = "labels",
  banner_text = "Test 6: OA only with 'labels' (should warn)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_6_labels_oa_warning.html"
)

# Test 7: Schools layer with custom label modes (no temporal data)
map7 <- create_pollution_map(
  csv_data_file = "none",
  oa_data_file = "none",
  school_file = test_school_file,
  boroughs = c("Wandsworth", "Merton"),
  # No years_to_plot parameter - schools are static, no temporal data
  show_marker_labels = "labels_on",
  banner_text = "Test 7: Schools with 'labels_on' (static layer)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_7_labels_schools.html"
)

# Test 6: OA data only - test warning behavior for "labels" mode
map8 <- create_pollution_map(
  csv_data_file = "none",
  oa_data_file = test_oa_file,
  school_file = "none",
  boroughs = c("Wandsworth", "Merton"),
  years_to_plot = 2024,
  show_marker_labels = "labels_on",
  banner_text = "Test 8: OA only with 'labels_on' (should warn)",
  show_banner = TRUE,
  show_legend = FALSE,
  output_file = "test_8_labels_oa_warning_on.html"
)

cat("All tests completed. Check aq_maps/ directory for output files.\n")

# Edge case tests for sub-annual temporal resolution (v0.9.4)

source("R/quickmap.R")

# Fetch base data once
cat("Fetching AURN data (2022-2023)...\n")
data_2y <- openair::importUKAQ(site = "my1", year = 2022:2023, source = "aurn", meta = TRUE)

# Helper to save and create map
make_map <- function(sf_data, filename, title) {
  temp <- file.path(Sys.getenv("DATA_PATH"), "test_edge_temp.Rdata")
  dataOAformat <- sf_data |> sf::st_drop_geometry() |> as.data.frame()
  save(dataOAformat, file = temp)

  create_pollution_map(
    data_sources = list("test_edge_temp.Rdata"),
    boroughs = "Westminster",
    pollutant = "no2",
    colour_scale = "who_no2",
    output_file = filename,
    title = title,
    styling_type = "html"
  )
  unlink(temp)
  cat("Created: aq_maps/", filename, "\n", sep = "")
}

# ------------------------------------------------------------------------------
# Test 1: Cross-year boundary (Nov 2022 → Feb 2023)
# Expected: Menu shows 2022-11, 2022-12, 2023-01, 2023-02 in order
# ------------------------------------------------------------------------------
cat("\n=== Test 1: Cross-year boundary ===\n")
data_cross <- data_2y[data_2y$date >= as.POSIXct("2022-11-01") &
                      data_2y$date < as.POSIXct("2023-03-01"), ]
sf_cross <- convert_openair_to_spatial(data_cross, pollutant = "no2", avg.time = "month")
cat("Periods:", paste(sf_cross$year_str, collapse = ", "), "\n")
make_map(sf_cross, "test_edge1_cross_year.html", "Edge 1: Cross-year Nov22-Feb23")
cat("CHECK: Menu shows 2022-11 → 2023-02 chronologically\n")

# ------------------------------------------------------------------------------
# Test 2: Single period (one month only)
# Expected: No dropdown, no play button, just static "2023-06"
# ------------------------------------------------------------------------------
cat("\n=== Test 2: Single period ===\n")
data_one <- data_2y[data_2y$date >= as.POSIXct("2023-06-01") &
                    data_2y$date < as.POSIXct("2023-07-01"), ]
sf_one <- convert_openair_to_spatial(data_one, pollutant = "no2", avg.time = "month")
cat("Periods:", sf_one$year_str, "\n")
make_map(sf_one, "test_edge2_single_period.html", "Edge 2: Single month Jun-2023")
cat("CHECK: No dropdown arrow, no play button\n")

# ------------------------------------------------------------------------------
# Test 3: Fine resolution (hourly over 6 hours)
# Expected: Menu shows 6 hourly timestamps in order
# ------------------------------------------------------------------------------
cat("\n=== Test 3: Hourly (6 hours) ===\n")
data_6hr <- data_2y[data_2y$date >= as.POSIXct("2023-06-15 10:00:00") &
                    data_2y$date < as.POSIXct("2023-06-15 16:00:00"), ]
sf_6hr <- convert_openair_to_spatial(data_6hr, pollutant = "no2", avg.time = "hour")
cat("Periods:", paste(sf_6hr$year_str, collapse = ", "), "\n")
make_map(sf_6hr, "test_edge3_hourly.html", "Edge 3: 6 hours on Jun 15")
cat("CHECK: Menu shows 10:00 → 15:00 in order\n")

# ------------------------------------------------------------------------------
# Test 4: Multiple sites × months
# Expected: 3 markers per period, 6 periods
# ------------------------------------------------------------------------------
cat("\n=== Test 4: Multiple sites ===\n")
data_multi <- openair::importUKAQ(
  site = c("my1", "kc1", "hors"),
  year = 2023,
  source = "aurn",
  meta = TRUE
)
data_6mo <- data_multi[data_multi$date >= as.POSIXct("2023-01-01") &
                       data_multi$date < as.POSIXct("2023-07-01"), ]
sf_multi <- convert_openair_to_spatial(data_6mo, pollutant = "no2", avg.time = "month")
cat("Records:", nrow(sf_multi), "| Sites:", length(unique(sf_multi$siteCode)),
    "| Months:", length(unique(sf_multi$year_str)), "\n")

temp <- file.path(Sys.getenv("DATA_PATH"), "test_edge_temp.Rdata")
dataOAformat <- sf_multi |> sf::st_drop_geometry() |> as.data.frame()
save(dataOAformat, file = temp)
create_pollution_map(
  data_sources = list("test_edge_temp.Rdata"),
  boroughs = c("Westminster", "Kensington and Chelsea", "Hounslow"),
  pollutant = "no2",
  colour_scale = "who_no2",
  output_file = "test_edge4_multi_site.html",
  title = "Edge 4: 3 sites × 6 months",
  styling_type = "html"
)
unlink(temp)
cat("Created: aq_maps/test_edge4_multi_site.html\n")
cat("CHECK: 3 markers visible per period, all update on switch\n")

# ------------------------------------------------------------------------------
# Test 5: Sparse periods (odd months only)
# Expected: Jan, Mar, May, Jul, Sep, Nov (no Feb, Apr, Jun, Aug, Oct, Dec)
# ------------------------------------------------------------------------------
cat("\n=== Test 5: Sparse periods ===\n")
data_2023 <- data_2y[format(data_2y$date, "%Y") == "2023", ]
data_sparse <- data_2023[as.integer(format(data_2023$date, "%m")) %% 2 == 1, ]
sf_sparse <- convert_openair_to_spatial(data_sparse, pollutant = "no2", avg.time = "month")
cat("Periods:", paste(sf_sparse$year_str, collapse = ", "), "\n")
make_map(sf_sparse, "test_edge5_sparse.html", "Edge 5: Odd months only")
cat("CHECK: Menu shows only Jan, Mar, May, Jul, Sep, Nov\n")

# ------------------------------------------------------------------------------
cat("\n=== Summary ===\n")
cat("1. test_edge1_cross_year.html   - Year boundary sorting\n")
cat("2. test_edge2_single_period.html - Single period UI\n")
cat("3. test_edge3_hourly.html        - Hourly resolution\n")
cat("4. test_edge4_multi_site.html    - Multiple sites\n")
cat("5. test_edge5_sparse.html        - Non-contiguous periods\n")

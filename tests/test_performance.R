# Performance Validation Test (Step 7 - v0.9.3)
# Target: 50 sites × 5 years = 250 features
# Metrics: Conversion < 5s, no rendering regression vs baseline

source("R/quickmap.R")

# Get 50 LAQN sites (largest UK network)
laqn_meta <- get_openair_metadata("kcl")
laqn_meta_clean <- laqn_meta[!is.na(laqn_meta$latitude) & !is.na(laqn_meta$longitude), ]

# Filter London area, take first 50
laqn_london <- laqn_meta_clean[
  laqn_meta_clean$latitude >= 51.2 & laqn_meta_clean$latitude <= 51.7 &
  laqn_meta_clean$longitude >= -0.5 & laqn_meta_clean$longitude <= 0.3,
]
sites_50 <- head(laqn_london$code, 50)

message("=== Performance Test: 50 sites × 5 years ===")
message("Sites: ", paste(head(sites_50, 5), collapse = ", "), " ... (", length(sites_50), " total)")

# Download data
message("\n1. API download (network-dependent, not benchmarked)")
time_download <- system.time({
  laqn_data <- openair::importKCL(
    site = sites_50,
    year = 2019:2023,
    pollutant = "no2",
    meta = TRUE
  )
})
message("   Downloaded: ", nrow(laqn_data), " hourly observations")
message("   Time: ", round(time_download["elapsed"], 1), "s")

# Conversion benchmark
message("\n2. Conversion to spatial (target: < 5s)")
time_conversion <- system.time({
  laqn_sf <- convert_openair_to_spatial(
    data = laqn_data,
    pollutant = "no2",
    avg.time = "year"
  )
})
message("   Converted: ", nrow(laqn_sf), " site-years")
message("   Time: ", round(time_conversion["elapsed"], 2), "s")
message("   Result: ", if (time_conversion["elapsed"] < 5) "PASS" else "FAIL")

# Memory profile
message("\n3. Memory usage")
message("   Peak: ", round(sum(gc()[, 2]), 1), " MB")

# Save for rendering test
dataOAformat <- st_drop_geometry(laqn_sf)[, c("siteCode", "year", "no2", "lat", "lon")]
save(dataOAformat, file = file.path(Sys.getenv("DATA_PATH"), "perf_test_250features.Rdata"))

# Rendering benchmark
message("\n4. Rendering (baseline ~25s, check for regression)")
time_render <- system.time({
  create_pollution_map(
    data_sources = list("perf_test_250features.Rdata"),
    data_configs = c("laqn"),
    boroughs = "Wandsworth",
    pollutant = "no2",
    title = "v0.9.3 Performance Test: 250 site-years",
    marker_labels = TRUE,
    output_file = "v093_performance_test.html"
  )
})
message("   Time: ", round(time_render["elapsed"], 1), "s")

message("\n=== Summary ===")
message("Conversion: ", round(time_conversion["elapsed"], 2), "s (target: < 5s) ",
        if (time_conversion["elapsed"] < 5) "[PASS]" else "[FAIL]")
message("Rendering: ", round(time_render["elapsed"], 1), "s (baseline: ~25s)")
message("Total features: ", nrow(laqn_sf))

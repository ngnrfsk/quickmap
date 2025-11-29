# Test: Auto Symbol Assignment by Data Type (v0.9.3.14)
# 6 temporal + 2 static layers
# Validates: solid symbols for temporal, non-solid for static

source("R/quickmap.R")

library(sf)

# Ensure DATA_PATH is set
if (Sys.getenv("DATA_PATH") == "") {
  Sys.setenv(DATA_PATH = "~/Coding/Library/data")
}

# Create synthetic static layer 1: Parks (no year columns)
parks_data <- data.frame(
  Site = c("Merton Park", "Wandsworth Park", "Richmond Park"),
  Easting = c(526000, 524500, 520000),
  Northing = c(169500, 174000, 173500),
  Type = c("Local", "Local", "Royal"),
  stringsAsFactors = FALSE
)
write.csv(parks_data, file.path(Sys.getenv("DATA_PATH"), "test_parks.csv"), row.names = FALSE)

# Create synthetic static layer 2: Hospitals (no year columns)
hospitals_data <- data.frame(
  Site = c("St George's Hospital", "Kingston Hospital", "Queen Mary's Hospital"),
  Easting = c(526500, 518500, 517000),
  Northing = c(170000, 167000, 176000),
  Type = c("Major", "Major", "District"),
  stringsAsFactors = FALSE
)
write.csv(hospitals_data, file.path(Sys.getenv("DATA_PATH"), "test_hospitals.csv"), row.names = FALSE)

# LAQN and AURN data already available in DATA_PATH from test_comprehensive_5network.R

# Test: 6 temporal + 2 static with auto symbol assignment
create_pollution_map(
  data_sources = list(
    # Temporal layers (should get solid symbols: circle, rect, triangle, diamond, stadium, down-triangle)
    "comprehensive_laqn.Rdata",
    "comprehensive_aurn.Rdata",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "richmond_1993_2024-1.csv",
    "merton_dt_2018_2024.csv",
    "your_schools_Merton.csv",
    # additionak dummy Static layers (should get non-solid symbols: simple-plus, simple-cross)
    "test_parks.csv",
    "test_hospitals.csv"
  ),
  boroughs = c("all"),
  pollutant = "no2",
  title = "v0.9.3.14 Test: Auto Symbol Assignment - 6 Temporal (solid) + 2 Static (non-solid)",
  marker_labels = TRUE,
  output_file = "v093_test_symbol_auto_assignment.html"
)

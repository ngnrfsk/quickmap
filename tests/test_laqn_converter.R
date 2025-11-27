# Test Script: LAQN + AURN 4-Network Overlay (Step 6 - v0.9.3)

source("R/quickmap.R")

# Download AURN data (3 London sites, max available years)
aurn_data <- openair::importUKAQ(
  site = c("my1", "lh0", "kc1"),
  year = 1990:2025,
  source = "aurn",
  meta = TRUE,
  pollutant = "no2"
)

aurn_sf <- convert_openair_to_spatial(
  data = aurn_data,
  pollutant = "no2",
  avg.time = "year"
)

dataOAformat <- st_drop_geometry(aurn_sf)[, c("siteCode", "year", "no2", "lat", "lon")]
save(dataOAformat, file = file.path(Sys.getenv("DATA_PATH"), "aurn_4network_test.Rdata"))

# Download LAQN data (3 London sites, max available years)
laqn_data <- openair::importKCL(
  site = c("CT3", "CT6", "HV1"),
  year = 1990:2025,
  pollutant = "no2",
  meta = TRUE
)

laqn_sf <- convert_openair_to_spatial(
  data = laqn_data,
  pollutant = "no2",
  avg.time = "year"
)

dataOAformat <- st_drop_geometry(laqn_sf)[, c("siteCode", "year", "no2", "lat", "lon")]
save(dataOAformat, file = file.path(Sys.getenv("DATA_PATH"), "laqn_4network_test.Rdata"))

# Create 4-network map: AURN + LAQN + dt_sites + schools
create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "aurn_4network_test.Rdata",
    "laqn_4network_test.Rdata",
    "your_schools_Merton.csv"
  ),
  data_ids = NULL,
  boroughs = "Merton",
  pollutant = "no2",
  title = "v0.9.3 Step 6: 4-Network Test (circles/squares/triangles/crosses)",
  marker_labels = TRUE,
  output_file = "v093_step6_4network.html"
)

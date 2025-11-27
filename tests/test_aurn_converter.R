# Test Script: AURN Converter with Multi-Network Overlay (Step 5)
# Tests: 3-site pollution overlay + full network metadata layer

source("R/quickmap.R")

data_path <- Sys.getenv("DATA_PATH")
if (data_path == "") {
  stop("DATA_PATH not set. Set with: Sys.setenv(DATA_PATH = 'path/to/data')")
}

# Test 1: Download 3 sites with pollution data, create 3-network map
aurn_data <- openair::importUKAQ(
  site = c("my1", "lh0", "kc1"),
  year = 2022:2023,
  source = "aurn",
  meta = TRUE,
  pollutant = "no2"
)

aurn_sf <- convert_openair_to_spatial(
  data = aurn_data,
  pollutant = "no2",
  avg.time = "year"
)

dataOAformat <- data.frame(
  siteCode = aurn_sf$siteCode,
  year = aurn_sf$year,
  no2 = aurn_sf$no2,
  lat = aurn_sf$lat,
  lon = aurn_sf$lon
)
save(dataOAformat, file = file.path(data_path, "aurn_test_data.Rdata"))

create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "aurn_test_data.Rdata",
    "your_schools_Merton.csv"
  ),
  data_configs = c("dt_sites", "aurn", "schools"),
  boroughs = "Merton",
  pollutant = "no2",
  years = 2023,
  output_file = "test_aurn_3network.html"
)

# Test 2: Download full AURN network metadata, create static layer map
aurn_metadata <- get_openair_metadata("aurn")
aurn_clean <- aurn_metadata[!is.na(aurn_metadata$latitude) & !is.na(aurn_metadata$longitude), ]

# Filter London area (51.2-51.7°N, -0.5-0.3°E)
aurn_london <- aurn_clean[
  aurn_clean$latitude >= 51.2 & aurn_clean$latitude <= 51.7 &
  aurn_clean$longitude >= -0.5 & aurn_clean$longitude <= 0.3,
]

dataOAformat <- data.frame(
  siteCode = aurn_london$code,
  year = 2023,
  no2 = 20,
  lat = aurn_london$latitude,
  lon = aurn_london$longitude
)
save(dataOAformat, file = file.path(data_path, "aurn_london_network.Rdata"))

create_pollution_map(
  data_sources = list(
    "aurn_london_network.Rdata",
    "your_schools_Merton.csv"
  ),
  data_configs = c("aurn", "schools"),
  boroughs = "Merton",
  pollutant = "no2",
  years = 2023,
  output_file = "test_aurn_network.html"
)

# Comprehensive 5-Network Test: v0.9.3 All Networks (2018-2024)
# Tests: LAQN + AURN + BL + DT + Schools with image export
# Expected: 5 distinct symbols, multi-year data, HTML + JPG outputs

source("R/quickmap.R")

# Download LAQN data (London sites, 2018-2024)
laqn_meta <- get_openair_metadata("kcl")
laqn_london <- laqn_meta[
  !is.na(laqn_meta$latitude) & !is.na(laqn_meta$longitude) &
  laqn_meta$latitude >= 51.2 & laqn_meta$latitude <= 51.7 &
  laqn_meta$longitude >= -0.5 & laqn_meta$longitude <= 0.3,
]

laqn_data <- openair::importKCL(
  site = laqn_london$code,
  year = 2018:2024,
  pollutant = "no2",
  meta = TRUE
)

laqn_sf <- convert_openair_to_spatial(
  data = laqn_data,
  pollutant = "no2",
  avg.time = "year"
)

dataOAformat <- st_drop_geometry(laqn_sf)[, c("siteCode", "year", "no2", "lat", "lon")]
save(dataOAformat, file = file.path(Sys.getenv("DATA_PATH"), "comprehensive_laqn.Rdata"))

# Download AURN data (London sites, 2018-2024)
aurn_meta <- get_openair_metadata("aurn")
aurn_london <- aurn_meta[
  !is.na(aurn_meta$latitude) & !is.na(aurn_meta$longitude) &
  aurn_meta$latitude >= 51.2 & aurn_meta$latitude <= 51.7 &
  aurn_meta$longitude >= -0.5 & aurn_meta$longitude <= 0.3,
]

aurn_data <- openair::importUKAQ(
  site = aurn_london$code,
  year = 2018:2024,
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
save(dataOAformat, file = file.path(Sys.getenv("DATA_PATH"), "comprehensive_aurn.Rdata"))

# Create 5-network map: LAQN + AURN + BL + DT + Schools
# Symbols: triangle, square, diamond, circle, cross
create_pollution_map(
  data_sources = list(
    "comprehensive_laqn.Rdata",
    "comprehensive_aurn.Rdata",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "merton_dt_2018_2024.csv",
    "your_schools_Merton.csv"
  ),
  data_ids = NULL,
  data_symbols = c("triangle", "square", "diamond", "circle", "cross"),
  boroughs = c("Merton", "Wandsworth", "Richmond upon Thames"),
  pollutant = "no2",
  title = "v0.9.3 Comprehensive Test: 5 Networks - LAQN/AURN/BL/DT/Schools (2018-2024)",
  marker_labels = TRUE,
  export_image = c(2400, 2400),
  output_file = "v093_comprehensive_5network_2018_2024.html"
)

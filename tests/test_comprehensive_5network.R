# Comprehensive 6-Network Test: v0.9.3 (2018-2024)
# LAQN + AURN + BL + Richmond DT + Merton DT + Schools
# Tests: Multi-network, symbol assignment, custom IDs, data_dynamic override, image export

source("R/quickmap.R")

# Download LAQN (London sites, 2018-2024)
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

# Download AURN (London sites, 2018-2024)
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

# Test 1: Default symbols (auto-cycle)
create_pollution_map(
  data_sources = list(
    "comprehensive_laqn.Rdata",
    "comprehensive_aurn.Rdata",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "richmond_1993_2024-1.csv",
    "merton_dt_2018_2024.csv",
    "your_schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  title = "v0.9.3 Test 1: Auto-cycling symbols (circle/square/triangle/diamond/cross/star)",
  marker_labels = TRUE,
  output_file = "v093_test1_auto_symbols.html"
)

# Test 2: Custom symbols (swapped order)
create_pollution_map(
  data_sources = list(
    "comprehensive_laqn.Rdata",
    "comprehensive_aurn.Rdata",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "richmond_1993_2024-1.csv",
    "merton_dt_2018_2024.csv",
    "your_schools_Merton.csv"
  ),
  data_symbols = c("star", "plus", "triangle", "diamond", "cross", "circle"),
  boroughs = c("Wandsworth", "Merton", "Richmond upon Thames"),
  pollutant = "no2",
  title = "v0.9.3 Test 2: Custom symbols (star/plus/triangle/diamond/cross/circle)",
  marker_labels = FALSE,
  output_file = "v093_test2_custom_symbols.html"
)

# Test 3: Custom IDs + data_dynamic override + image export
create_pollution_map(
  data_sources = list(
    "comprehensive_laqn.Rdata",
    "comprehensive_aurn.Rdata",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "richmond_1993_2024-1.csv",
    "merton_dt_2018_2024.csv",
    "your_schools_Merton.csv"
  ),
  data_ids = c("laqn_london", "aurn_london", "bl_sensors", "richmond_tubes", "merton_tubes", "schools"),
  data_symbols = c("triangle", "square", "diamond", "circle", "cross", "star"),
  data_dynamic = c(TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
  boroughs = "all",
  pollutant = "no2",
  title = "v0.9.3 Test 3: Custom IDs + data_dynamic override + 3 boroughs",
  marker_labels = TRUE,
  export_image = c(2400, 2400),
  output_file = "v093_test3_full_options.html"
)

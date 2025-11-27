# Test: Create static map from KCL network metadata
# User test for Step 2 completion

source("R/quickmap.R")

# Set DATA_PATH
data_path <- Sys.getenv("DATA_PATH")
if (data_path == "") {
  stop("DATA_PATH environment variable not set. Please set it first.")
}
cat("Using DATA_PATH:", data_path, "\n")

# Get KCL metadata and filter to London area
cat("Fetching KCL network metadata...\n")
kcl_meta <- get_openair_metadata("kcl")
kcl_clean <- kcl_meta[!is.na(kcl_meta$latitude) & !is.na(kcl_meta$longitude), ]

# Filter to London area (roughly 51.2-51.7 lat, -0.5-0.3 lon)
kcl_london <- kcl_clean[
  kcl_clean$latitude >= 51.2 & kcl_clean$latitude <= 51.7 &
  kcl_clean$longitude >= -0.5 & kcl_clean$longitude <= 0.3,
]
cat("KCL sites in London area:", nrow(kcl_london), "\n\n")

# Create RData file for quickmap
cat("Creating layer data...\n")
dataOAformat <- data.frame(
  siteCode = kcl_london$code,
  year = 2023,
  no2 = 20,  # Static value for visualization
  lat = kcl_london$latitude,
  lon = kcl_london$longitude
)
save(dataOAformat, file = file.path(data_path, "kcl_metadata_layer.Rdata"))

# Create map
cat("Creating map...\n")
map <- create_pollution_map(
  sensor_file = "kcl_metadata_layer.Rdata",
  boroughs = "Wandsworth",
  pollutant = "no2",
  output_file = "aq_maps/kcl_network_map.html"
)

cat("\nMap created: aq_maps/kcl_network_map.html\n")
cat("Open in browser to view KCL network sites\n")

# Cleanup
unlink(file.path(data_path, "kcl_metadata_layer.Rdata"))

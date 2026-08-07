# Item 7 demonstration maps (wind layer via worldmet + leaflet-velocity).
# Run from the repo root: Rscript scripts/demos/item7_demo-maps_v1.R
# Needs network for the NOAA fetch (worldmet); outputs land in aq_maps/.
library(quickmap)

# Heathrow ISD station, Jan 2024 — the episode window
heathrow <- from_worldmet(station = "037720-99999", year = 2024)
heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]

# 1. Episode map (lazy path) + hourly wind — the headline item-7 map.
create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item7_episode-wind_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024 (with wind)",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500,
  wind = heathrow
)

# 2. Annual map (legacy pre-built path) + annual-mean wind — proves the
#    overlay coexists with the non-lazy marker path.
wind_annual <- from_worldmet(station = "037720-99999", year = 2020:2022)
suppressWarnings(create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "item7_merton-annual-wind_v1.html",
  title = "Merton NO2 Annual Mean (with wind)",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels",
  wind = wind_annual
))

for (f in c("item7_episode-wind_v1.html", "item7_merton-annual-wind_v1.html")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

# Item 10 final demonstration maps (v0.9.9.5, approved design implemented).
# v2: vignette restored to the default (ON) for the annual and theme demos —
# v1 passed vignette = FALSE everywhere (a leftover from the mock-up chain),
# which the user caught at review. The episode map stays vignette-free,
# matching its baseline.
# Run from the repo root: Rscript scripts/item10_demo-maps_v2.R
# Compare against the approved mocks in aq_maps/item10_assembled-*.html and
# the pre-item-10 baseline in aq_maps/baseline_260707_item8_signed_off/.
library(quickmap)

# 1. Annual multi-layer map, all defaults (strip banner, ramp legend,
#    Positron tiles, slider).
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  display_times = 2020:2022,
  output_file = "item10_final-annual_v2.html",
  title = "Merton NO2 Annual Mean, 2020-2022",
  marker_labels = "labels"
))

# 2. Episode animation + speed-ramp wind (lazy path, 108 steps, slider
#    scrubbing, autoplay).
if (requireNamespace("worldmet", quietly = TRUE)) {
  heathrow <- tryCatch(
    from_worldmet(station = "037720-99999", year = 2024),
    error = function(e) {
      message("NOAA fetch failed, wind omitted: ", conditionMessage(e))
      NULL
    }
  )
  if (!is.null(heathrow)) {
    heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]
  }
} else {
  heathrow <- NULL
}
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  output_file = "item10_final-episode-wind_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500,
  wind = heathrow
)

# 3. The theme options in action: "bar" banner + OSM tiles (the XOR
#    alternatives kept per the user's decisions).
bar_theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:",
  '  style: "bar"',
  "map:",
  '  base_tiles: "OpenStreetMap"'
), bar_theme)
suppressWarnings(quickmap(
  list("merton_dt_2018_2024.csv", "schools_Merton.csv"),
  boroughs = "Merton",
  display_times = 2020:2022,
  theme_file = bar_theme,
  output_file = "item10_final-bar-osm_v2.html",
  title = "Theme options: bar banner + OSM tiles",
  marker_labels = "labels"
))

for (f in c("item10_final-annual_v2.html", "item10_final-episode-wind_v1.html",
            "item10_final-bar-osm_v2.html")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

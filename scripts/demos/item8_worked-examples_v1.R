# Item 8 worked examples: the quickmap() API end-to-end (v0.9.8).
# Run from the repo root: Rscript scripts/demos/item8_worked-examples_v1.R
# Outputs land in aq_maps/ as item8_*_v1.html for human inspection.
library(quickmap)

# ---- 1. Two lines: a usable map ---------------------------------------------
# File paths resolve against DATA_PATH; boroughs is the only other required
# argument. (output_file added here only so the demo files keep the item-8
# naming convention.)
quickmap(
  "wandsworth_2017_2024_csv.csv",
  boroughs = "Wandsworth",
  output_file = "item8_wandsworth-twoline_v1.html"
)

# ---- 2. Several layers plus a theme ----------------------------------------
# Tubes + sensors + schools; shapes auto-assign (circle/diamond/cross) and
# the Merton theme supplies banner/legend/control styling.
quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  title = "Merton NO2 Annual Mean, 2018-2024",
  output_file = "item8_merton-theme_v1.html",
  marker_labels = "labels"
)

# ---- 3. Temporal animation (lazy path) --------------------------------------
# 108 hourly steps: above the 50-step threshold, so markers render via the
# item-6 Canvas/embedded-JSON path automatically. from_worldmet()-style
# per-layer control: the layer name is set on the layer, not the map.
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item8_episode-lazy_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500
)

# ---- 4. Wind overlay (v0.9.8) ------------------------------------------------
# Animated particle wind layer from Heathrow ISD data, advancing with the
# time control. worldmet is Suggests and the fetch needs a network
# connection, so both are guarded.
if (requireNamespace("worldmet", quietly = TRUE)) {
  heathrow <- tryCatch(
    from_worldmet(station = "037720-99999", year = 2024),
    error = function(e) {
      message("Skipping wind example (NOAA fetch failed): ", conditionMessage(e))
      NULL
    }
  )
  if (!is.null(heathrow)) {
    heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]
    quickmap(
      from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25",
                 name = "bl_sensors"),
      boroughs = c("Wandsworth", "Richmond"),
      colour_scale = "stripes_pm25",
      theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
      output_file = "item8_episode-wind_v1.html",
      title = "PM2.5 Episode: Jan 15-20, 2024 (with wind)",
      marker_labels = TRUE,
      banner_colour = "#005794",
      autoplay = TRUE,
      play_speed = 500,
      wind = heathrow
    )
  }
} else {
  message("Skipping wind example: worldmet not installed")
}

for (f in list.files("aq_maps", pattern = "^item8_.*_v1\\.html$")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

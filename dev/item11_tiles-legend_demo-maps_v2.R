# Demo maps for visual sign-off of feature/item11-tiles-legend (v0.9.9.14)
# after its rebase onto PR #53 (2026-10-13). Same three maps as
# item11_tiles-legend_demo-maps_v1.R, on the item 9 API: output_dir names the
# folder and marker_labels is symbol_labels. Install the branch, then:
#   Rscript dev/item11_tiles-legend_demo-maps_v2.R
#
# What to look at, against the v1 maps signed off or queried on 2026-09-22:
#   1. merton-annual_v2: streets visible when opened from disk (not the "Access
#      blocked" tile); legend panel lavender (#DED4E9 from merton.yaml) with a
#      white heading pill; strip banner unchanged.
#   2. episode-subannual_v3: same tiles on an hourly animation; airstat theme
#      on Esri grey canvas. v2 of this map was never signed off.
#   3. croydon-schools-labels_v2: purple bar banner with white text from the
#      theme; school crosses with the banner key; tube names on hover.

library(quickmap)

folder <- "/Users/iarla/Coding/quickmap-work/260911 Croydon LCA maps"
out <- file.path(folder, "aq_maps")

quickmap(
  "merton_dt_2018_2024.csv",
  boroughs = "Merton",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  title = "LB Merton, Annual Mean NO2, 2018-2024 (item 11 tiles/legend demo)",
  output_file = "item11_merton-annual_v2.html",
  output_dir = out
)

create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item11_episode-subannual_v3.html",
  output_dir = out,
  title = "PM2.5 Episode, 15-20 Jan 2024 (item 11 tiles/legend demo)",
  vignette = FALSE,
  autoplay = TRUE
)

quickmap(
  list(file.path(folder, "data", "croydon_dt_2020_2025.csv"),
       file.path(folder, "data", "croydon_schools_qm.csv")),
  boroughs = "Croydon",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "croydon.yaml", package = "quickmap"),
  title = "Croydon Council, Annual Mean NO2, 2020-2025 (item 11 tiles/legend demo)",
  symbol_labels = "labels",
  output_file = "item11_croydon-schools-labels_v2.html",
  output_dir = out
)

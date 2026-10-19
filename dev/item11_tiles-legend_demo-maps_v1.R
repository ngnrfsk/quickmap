# Demo maps for visual sign-off of feature/item11-tiles-legend (v0.9.9.14):
# openstreetmap.de default tiles, theme legend background honoured, bar banner
# text colour, contrast warning. Run from a checkout of the branch:
#   devtools::load_all("<checkout>"); setwd(folder); source(this file)
# Outputs land in aq_maps/ beside this script.
#
# What to look at:
#   1. merton-annual: streets visible when opened from disk (not the "Access
#      blocked" tile); legend panel lavender (#DED4E9 from merton.yaml) with a
#      white heading pill; strip banner unchanged.
#   2. episode-subannual: same tiles on an hourly animation; airstat theme.
#   3. croydon-schools-labels: purple bar banner with white text from the
#      theme; school crosses with the banner key; tube names on hover.

folder <- "/Users/iarla/Coding/quickmap-work/260911 Croydon LCA maps"
setwd(folder)

quickmap(
  "merton_dt_2018_2024.csv",
  boroughs = "Merton",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  title = "LB Merton, Annual Mean NO2, 2018-2024 (item 11 tiles/legend demo)",
  output_file = "item11_merton-annual_v1.html"
)

create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item11_episode-subannual_v2.html",   # v1: Positron, failed from disk
  title = "PM2.5 Episode, 15-20 Jan 2024 (item 11 tiles/legend demo)",
  vignette = FALSE,
  autoplay = TRUE
)

quickmap(
  # full school names: shorten_labels arrives with item 9, not on this branch
  list(file.path(folder, "data", "croydon_dt_2020_2025.csv"),
       file.path(folder, "data", "croydon_schools_qm.csv")),
  boroughs = "Croydon",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "croydon.yaml", package = "quickmap"),
  title = "Croydon Council, Annual Mean NO2, 2020-2025 (item 11 tiles/legend demo)",
  marker_labels = "labels",   # symbol_labels once item 9 merges
  output_file = "item11_croydon-schools-labels_v1.html"
)

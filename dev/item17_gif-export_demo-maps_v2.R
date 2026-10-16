# Demo GIFs for visual sign-off of feature/item17-gif-export (v0.9.9.15).
# Install the branch, then from the repository root:
#   Rscript dev/item17_gif-export_demo-maps_v2.R
# Writes to aq_maps/ (gitignored).
#
# v2 (2026-10-16): v1's always-on labels made the maps unreadable, so both
# maps show names on hover only (symbol_labels = "labels"): in the HTML, not
# in the GIF or JPGs. School names are now shortened by default. The v1 episode GIF had no labels and
# is not rebuilt: item17_episode-hourly_v1.gif stands.
#
# What to look at:
#   1. item17_merton-annual_v2.gif: 14 frames, 2012-2025, from the combined
#      Merton tube table (quickmap item 19), 1200x1200 default size, 800 ms a
#      frame. Years in order; banner, legend mean and maximum change with the
#      frame; school crosses stay put; markers readable. Loops.
#   2. item17_croydon_v2.gif plus its six JPGs at 1000x1000: the GIF frames
#      match the JPGs.

library(quickmap)

out <- "aq_maps"
croydon <- "/Users/iarla/Coding/260911 Croydon LCA maps/data"

quickmap(
  list("tubes/merton_no2_tubes_2012_2025.csv", "schools_Merton.csv"),
  boroughs = "Merton",
  colour_scale = "lbm_aqap_no2",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  title = "LB Merton, Annual Mean NO2, 2012-2025 (item 17 GIF demo)",
  symbol_labels = "labels",
  export_animation = "gif",
  output_file = "item17_merton-annual_v2.html",
  output_dir = out
)

quickmap(
  list(file.path(croydon, "croydon_dt_2020_2025.csv"),
       file.path(croydon, "croydon_schools_qm.csv")),
  boroughs = "Croydon",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "croydon.yaml", package = "quickmap"),
  title = "Croydon Council, Annual Mean NO2, 2020-2025 (item 17 GIF demo)",
  symbol_labels = "labels",
  export_image = c(1000, 1000),
  export_animation = "gif",
  output_file = "item17_croydon_v2.html",
  output_dir = out
)

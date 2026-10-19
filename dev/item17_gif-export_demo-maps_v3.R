# Demo GIFs for visual sign-off of feature/item17-gif-export (v0.9.9.15).
# Install the branch, then from the repository root:
#   Rscript dev/item17_gif-export_demo-maps_v3.R
# Writes to aq_maps/ (gitignored).
#
# v3 (2026-10-19): the legend's mean and maximum figures now have a fixed
# width, so the ramp no longer shifts sideways as they change. Otherwise as v2.
# v2 (2026-10-16): names on hover only (symbol_labels = "labels"), school
# names shortened by default. The v1 episode GIF is not rebuilt.
#
# What to look at:
#   1. item17_merton-annual_v3.gif: 14 frames, 2012-2025, 800 ms a frame. The
#      legend ramp stays still from frame to frame; years in order; banner,
#      legend mean and maximum change with the frame. Loops.
#   2. item17_croydon_v3.gif plus its six JPGs at 1000x1000: ramp still; the
#      GIF frames match the JPGs.

library(quickmap)

out <- "aq_maps"
croydon <- "/Users/iarla/Coding/quickmap-work/260911 Croydon LCA maps/data"

quickmap(
  list("tubes/merton_no2_tubes_2012_2025.csv", "schools_Merton.csv"),
  boroughs = "Merton",
  colour_scale = "lbm_aqap_no2",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  title = "LB Merton, Annual Mean NO2, 2012-2025 (item 17 GIF demo)",
  symbol_labels = "labels",
  export_animation = "gif",
  output_file = "item17_merton-annual_v3.html",
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
  output_file = "item17_croydon_v3.html",
  output_dir = out
)

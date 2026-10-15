# Demo GIFs for visual sign-off of feature/item17-gif-export (v0.9.9.15).
# Install the branch, then from the repository root:
#   Rscript dev/item17_gif-export_demo-maps_v1.R
# Writes to aq_maps/ (gitignored).
#
# What to look at:
#   1. item17_merton-annual_v1.gif: 14 frames, 2012-2025, from the combined
#      Merton tube table (quickmap item 19), 1200x1200 default size, 800 ms a
#      frame (the step-count pace). Banner, legend with the mean and maximum
#      for each year, and the step label all change with the frame; school
#      crosses and their names stay put. Loops.
#   2. item17_episode-hourly_v1.gif: 108 hourly frames at 800x800 and 450 ms.
#      The defect 12 test: every frame present, none blank or half-drawn.
#   3. item17_croydon-labels_v1.gif plus its six JPGs at 1000x1000: the GIF
#      frames match the JPGs; tube names readable at that size.

library(quickmap)

out <- "aq_maps"
croydon <- "/Users/iarla/Coding/260911 Croydon LCA maps/data"

quickmap(
  list("tubes/merton_no2_tubes_2012_2025.csv",
       from_csv("schools_Merton.csv", shorten_labels = TRUE)),
  boroughs = "Merton",
  colour_scale = "lbm_aqap_no2",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  title = "LB Merton, Annual Mean NO2, 2012-2025 (item 17 GIF demo)",
  symbol_labels = "values_on",
  export_animation = "gif",
  output_file = "item17_merton-annual_v1.html",
  output_dir = out
)

create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = "bl_sensors",
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  title = "PM2.5 Episode, 15-20 Jan 2024 (item 17 GIF demo)",
  vignette = FALSE,
  export_image = c(800, 800),
  export_animation = "gif",
  output_file = "item17_episode-hourly_v1.html",
  output_dir = out
)

quickmap(
  list(file.path(croydon, "croydon_dt_2020_2025.csv"),
       file.path(croydon, "croydon_schools_qm.csv")),
  boroughs = "Croydon",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "croydon.yaml", package = "quickmap"),
  title = "Croydon Council, Annual Mean NO2, 2020-2025 (item 17 GIF demo)",
  symbol_labels = "labels_on",
  export_image = c(1000, 1000),
  export_animation = "gif",
  output_file = "item17_croydon-labels_v1.html",
  output_dir = out
)

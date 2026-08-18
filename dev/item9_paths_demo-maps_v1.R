# Demonstration maps for roadmap item 9.1 (output paths) and 9.3
# (marker_labels -> symbol_labels), v0.9.9.13.
#
# Run from the repository root:
#   Rscript dev/item9_paths_demo-maps_v1.R
#
# Every call names its own destination — the package no longer invents
# aq_maps/. The three maps cover the cases CLAUDE.md requires for sign-off:
# an annual multi-year map, a sub-annual animation, and one with schools and
# labels. The fourth writes JPGs, which is where the per-step filename bug
# lived.

library(quickmap)

out <- "aq_maps"   # named by this script, created because it was named

# 1. Annual, multi-year. output_dir prepends; the file name stays short.
quickmap(
  list("merton_dt_2018_2024.csv",
       "bl_imperial_annualised_2021_2025_with_missing.Rdata"),
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "Item 9: Merton NO2, 2018-2024",
  output_file = "item9_merton-annual_v1.html",
  output_dir = out
)

# 2. Sub-annual: 108 hourly steps. Nothing about the paths changes with
#    resolution, but the time step now reaches the JPG filename sanitised.
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "Sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  title = "Item 9: PM2.5 episode, 15-20 Jan 2024",
  output_file = "item9_episode-hourly_v1.html",
  output_dir = out,
  autoplay = TRUE
)

# 3. Schools and labels, under the new argument name.
quickmap(
  list("merton_dt_2018_2024.csv", "schools_Merton.csv"),
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "Item 9: Merton NO2 with schools",
  symbol_labels = "values_on",
  output_file = "item9_merton-schools_v1.html",
  output_dir = out
)

# 4. The old argument name, which must still work and warn. Written into a
#    subfolder named inside output_file, to show a path is honoured.
quickmap(
  "merton_dt_2018_2024.csv",
  boroughs = "Merton",
  title = "Item 9: old argument name still works",
  marker_labels = "values_on",
  output_file = "legacy/item9_old-name_v1.html",
  output_dir = out
)

# 5. Static export: one JPG per step, beside the HTML the caller named.
quickmap(
  "merton_dt_2018_2024.csv",
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "Item 9: Merton NO2",
  display_times = 2022:2024,
  export_image = c(1200, 900),
  output_file = "images/item9_merton-print_v1.html",
  output_dir = out
)

cat("\nWritten under", normalizePath(out), ":\n")
print(list.files(out, recursive = TRUE))

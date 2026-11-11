# Demo maps for visual sign-off of fix/deltas-scale (dev/261111_deltas_issue.md).
# Install the branch, then from the repository root:
#   Rscript dev/deltas_demo-maps_v1.R
# Writes to aq_maps/ (gitignored). Needs DATA_PATH.
#
# What to look at:
#   1. deltas_merton-falls_v1.html and the 2014 JPG beside
#      deltas_merton-falls-2014_v1.html: legend reads
#      "Fall ≥8" (dark blue) on the left to "Rise >8" (dark red), then
#      "Site not in use" (white). Every label sits under its own block; none
#      runs into the next. Sites that fell most are dark blue.
#   2. deltas_merton-falls-lazy_v1.html: same data forced onto the >50-step
#      rendering path. A site that rose by more than 8 is dark red, not white.
#   3. deltas_merton-annual_v1.html (who_no2, multi-year, schools, labels on
#      hover): legend labels unchanged at full width; narrow the window to
#      ~600 px — labels wrap under their blocks instead of overflowing.
#   4. deltas_episode-subannual_v1.html (stripes_pm25, hourly): as 3.

library(quickmap)

out <- "aq_maps"
tubes <- file.path(Sys.getenv("DATA_PATH"), "tubes", "merton_no2_tubes_2012_2025.csv")

# Year-on-year falls: positive = lower than the year before
d <- read.csv(tubes, check.names = FALSE)
years <- grep("^[0-9]{4}$", names(d), value = TRUE)
falls <- d[c("site_id", "Label", "Easting", "Northing")]
for (i in seq_along(years)[-1]) {
  falls[[years[i]]] <- d[[years[i - 1]]] - d[[years[i]]]
}
falls_csv <- file.path(tempdir(), "merton_no2_falls_2013_2025.csv")
write.csv(falls, falls_csv, row.names = FALSE, na = "")

quickmap(
  falls_csv,
  boroughs = "Merton",
  colour_scale = "deltas",
  title = "LB Merton, NO2 fall on previous year, 2013-2025 (deltas demo)",
  symbol_labels = TRUE,
  export_image = TRUE,
  display_times = "2014",
  output_file = "deltas_merton-falls-2014_v1.html",
  output_dir = out
)

quickmap(
  falls_csv,
  boroughs = "Merton",
  colour_scale = "deltas",
  title = "LB Merton, NO2 fall on previous year, 2013-2025 (deltas demo)",
  symbol_labels = TRUE,
  output_file = "deltas_merton-falls_v1.html",
  output_dir = out
)

withr::with_options(list(quickmap.lazy_step_threshold = 5), quickmap(
  falls_csv,
  boroughs = "Merton",
  colour_scale = "deltas",
  title = "LB Merton, NO2 fall on previous year, lazy path (deltas demo)",
  symbol_labels = TRUE,
  output_file = "deltas_merton-falls-lazy_v1.html",
  output_dir = out
))

quickmap(
  list(tubes, file.path(Sys.getenv("DATA_PATH"), "schools_Merton.csv")),
  boroughs = "Merton",
  colour_scale = "who_no2",
  title = "LB Merton, Annual Mean NO2, 2012-2025 (deltas demo)",
  symbol_labels = "labels",
  output_file = "deltas_merton-annual_v1.html",
  output_dir = out
)

create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  output_file = "deltas_episode-subannual_v1.html",
  output_dir = out,
  title = "PM2.5 Episode, 15-20 Jan 2024 (deltas demo)"
)

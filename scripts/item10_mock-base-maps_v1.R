# Item 10 mock-up base maps (real Merton data).
# Run from the repo root: Rscript scripts/item10_mock-base-maps_v1.R
# item10_tiles-osm_v1.html      - current default tiles (Q8 comparison + current-look reference)
# item10_tiles-positron_v1.html - pale CartoDB Positron tiles (Q8 option A);
#                                 also the base file the CSS mock-ups build on.
library(quickmap)

layers <- list(
  "merton_dt_2018_2024.csv",
  "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  "schools_Merton.csv"
)

suppressWarnings(quickmap(
  layers,
  boroughs = "Merton",
  display_times = 2020:2022,
  output_file = "item10_tiles-osm_v1.html",
  title = "Merton NO2 Annual Mean, 2018-2024",
  vignette = FALSE,
  marker_labels = "labels"
))

suppressWarnings(quickmap(
  layers,
  boroughs = "Merton",
  display_times = 2020:2022,
  theme_file = "/Users/iarla/.claude/jobs/6c0b9a7a/tmp/item10_theme_positron.yaml",
  output_file = "item10_tiles-positron_v1.html",
  title = "Merton NO2 Annual Mean, 2018-2024",
  vignette = FALSE,
  marker_labels = "labels"
))

for (f in c("item10_tiles-osm_v1.html", "item10_tiles-positron_v1.html")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

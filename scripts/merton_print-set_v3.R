# The print set for the LB Merton Air Quality Action Plan.
#
# Merton NO2, one image per year 2019-2025, 4000 x 3000 px, with the legend
# indicator (network mean and maximum) switched on.
#
# v3 (2026-08-05):
#   - schools added as a second layer, drawn as the usual crosses and labelled
#     with their names
#   - every site carries its value, always visible, not on hover
#     (marker_labels = "values_on": a layer with a School column duck-types to
#     school names, everything else falls through to the pollutant value)
#   - label text now follows the export size, and map.label_scale pushes it
#     further so it lands at a readable point size on A4. See LABEL_SCALE.
#
# v2: AQAP banner and colour scale. v1: the original set.
#
# Run from the project root:  Rscript scripts/merton_print-set_v3.R

library(quickmap)

STAMP <- "260805"

# The image fills most of an A4 page: about 190mm across, so 4000px lands at
# roughly 21 px/mm. A 9pt label is 3.17mm, i.e. ~67px, and the base label is
# 12px scaled by the export factor (sqrt(4000*3000 / 1200^2) = 2.89), giving
# 34.6px on its own. LABEL_SCALE closes that gap. Measured, not assumed --
# scripts/merton_label-measure_v1.R reports the delivered point size.
LABEL_SCALE <- 1.9

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))

schools <- file.path(Sys.getenv("DATA_PATH"), "schools_Merton.csv")
stopifnot(nzchar(Sys.getenv("DATA_PATH")), file.exists(schools))

theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:",
  '  style: "bar"',
  '  background: "#2a75d4"',
  "indicator:",
  "  show_max: true",
  "map:",
  paste("  label_scale:", LABEL_SCALE)
), theme)

quickmap(
  list(prepared, schools),
  boroughs = "Merton",
  display_times = as.character(2019:2025),
  colour_scale = "lbm_aqap_no2",
  theme_file = theme,
  title = "Merton NO₂ annual mean concentrations (µg/m³)",
  marker_labels = "values_on",
  export_image = c(4000, 3000),
  output_file = "merton_no2_aqap.html"
)

out <- file.path("aq_maps", paste0("print_aqap_", STAMP))
dir.create(out, showWarnings = FALSE)
jpgs <- list.files("aq_maps", pattern = "^merton_no2_aqap_20\\d\\d\\.jpg$",
                   full.names = TRUE)
file.rename(jpgs, file.path(out, basename(jpgs)))

sizes <- file.size(list.files(out, full.names = TRUE))
cat("wrote", length(jpgs), "images to", out,
    sprintf("(%.1f MB)\n", sum(sizes) / 1e6))

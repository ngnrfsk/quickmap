# The print set for the LB Merton Air Quality Action Plan.
#
# Merton NO2, one image per year 2019-2025, 4000 x 3000 px, with the legend
# indicator (network mean and maximum) switched on.
#
# v2 (2026-08-05), for the AQAP as a legal document:
#   - banner is a solid #2a75d4 bar with white text, matching the document's
#     own banner rather than merely accenting a white strip
#   - colour scale is lbm_aqap_no2: same colours and thresholds as before, but
#     the 20 ug/m3 target is named on both sides of the boundary and the
#     footnote symbols are gone
#   - format unchanged at 4000 x 3000
#
# Written to a dated folder so it is a coherent pack and does not overwrite
# earlier sets.
#
# Run from the project root:  Rscript scripts/merton_print-set_v2.R

library(quickmap)

STAMP <- "260805"

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))

theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:",
  '  style: "bar"',
  '  background: "#2a75d4"',
  "indicator:",
  "  show_max: true"
), theme)

quickmap(
  prepared,
  boroughs = "Merton",
  display_times = as.character(2019:2025),
  colour_scale = "lbm_aqap_no2",
  theme_file = theme,
  title = "Merton NO₂ annual mean concentrations (µg/m³)",
  export_image = c(4000, 3000),
  output_file = "merton_no2_aqap.html"
)

# move the year images into a dated folder of their own
out <- file.path("aq_maps", paste0("print_aqap_", STAMP))
dir.create(out, showWarnings = FALSE)
jpgs <- list.files("aq_maps", pattern = "^merton_no2_aqap_20\\d\\d\\.jpg$",
                   full.names = TRUE)
file.rename(jpgs, file.path(out, basename(jpgs)))

sizes <- file.size(list.files(out, full.names = TRUE))
cat("wrote", length(jpgs), "images to", out,
    sprintf("(%.1f MB)\n", sum(sizes) / 1e6))

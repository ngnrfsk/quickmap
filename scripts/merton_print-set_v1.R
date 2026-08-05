# A complete, shareable print set: Merton NO2, one image per year 2019-2025,
# 4000 x 3000 px, with the legend indicator (mean + max) switched on.
#
# Written to a dated folder so it is a coherent pack and does not overwrite
# earlier sets.
#
# Run from the project root:  Rscript scripts/merton_print-set_v1.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))

theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:", '  background: "#5F3E94"',
  "indicator:", "  show_max: true"
), theme)

quickmap(
  prepared,
  boroughs = "Merton",
  display_times = as.character(2019:2025),
  colour_scale = "lbm_no2",
  theme_file = theme,
  title = "Merton NO₂ annual mean concentrations (µg/m³)",
  export_image = c(4000, 3000),
  output_file = "merton_no2_print.html"
)

# move the year images into a dated folder of their own
out <- "aq_maps/print_260804"
dir.create(out, showWarnings = FALSE)
jpgs <- list.files("aq_maps", pattern = "^merton_no2_print_20\\d\\d\\.jpg$",
                   full.names = TRUE)
file.rename(jpgs, file.path(out, basename(jpgs)))
cat("wrote", length(jpgs), "images to", out, "\n")

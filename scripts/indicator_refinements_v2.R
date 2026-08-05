# Refinement prototypes for the ramp indicator (user note 2026-07-30: the bar
# was too thin and did not read as connected to the figure beside it).
#
#   "bar"     — thicker bar, dark cap at the value, colour chip beside the figure
#   "roundel" — a disc on the ramp carrying the figure, with a matching disc
#               beside the caption
#
# Run from the project root:  Rscript scripts/indicator_refinements_v2.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))
years <- as.character(2019:2025)

theme_for <- function(style) {
  f <- tempfile(fileext = ".yaml")
  writeLines(c(
    "banner:",
    '  background: "#5F3E94"',
    "indicator:",
    paste0('  style: "', style, '"')
  ), f)
  f
}

for (style in c("bar", "roundel")) {
  theme <- theme_for(style)

  # Interactive
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = years,
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0("Indicator ", style, " — Merton NO₂ annual mean"),
    output_file = paste0("indicator_", style, "-annual_v2.html")
  )

  # Print, the two ends of the series
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = c("2019", "2025"),
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0("Indicator ", style, " — print export"),
    export_image = c(4000, 3000),
    output_file = paste0("indicator_", style, "-print_v2.html")
  )
}

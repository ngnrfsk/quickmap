# Demonstration maps for the legend indicator.
# Run from the project root:  Rscript scripts/indicator_demo-maps_v1.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))
years <- as.character(2019:2025)
merton <- system.file("themes/merton.yaml", package = "quickmap")

# 1. Annual map, pre-built layer path (the ordinary case). Drag the slider:
#    the pointer and figure should move with it.
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = years,
  colour_scale = "lbm_no2",
  theme_file = merton,
  title = "Indicator demo — Merton NO₂ annual mean",
  output_file = "indicator_merton-annual_v1.html"
)

# 2. The same map forced down the lazy Canvas path, by dropping the step
#    threshold below seven. This is the only way to exercise the lazy path
#    with an indicator today: the indicator is annual-only, and an annual map
#    almost never has the 50+ steps that would trigger lazy rendering
#    naturally. Without this the hook would ship untested.
withr::with_options(list(quickmap.lazy_step_threshold = 3), {
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = years,
    colour_scale = "lbm_no2",
    theme_file = merton,
    title = "Indicator demo — forced lazy path",
    output_file = "indicator_merton-lazy_v1.html"
  )
})

# 3. Static export, two sizes, to check the indicator scales with the image.
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = c("2019", "2025"),
  colour_scale = "lbm_no2",
  theme_file = merton,
  title = "Indicator demo — print export",
  export_image = c(4000, 3000),
  output_file = "indicator_print-4000_v1.html"
)

quickmap(
  prepared,
  boroughs = "Merton",
  display_times = "2025",
  colour_scale = "lbm_no2",
  theme_file = merton,
  title = "Indicator demo — small export",
  export_image = c(900, 700),
  output_file = "indicator_print-900_v1.html"
)

# 4. Indicator switched off through the theme.
off_theme <- tempfile(fileext = ".yaml")
writeLines(c("indicator:", "  show: false"), off_theme)
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = years,
  colour_scale = "lbm_no2",
  theme_file = off_theme,
  title = "Indicator demo — switched off",
  output_file = "indicator_switched-off_v1.html"
)

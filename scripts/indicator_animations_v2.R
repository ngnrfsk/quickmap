# Animated examples of the two indicator styles, 2019-2025.
#
# Both play automatically on load, so the indicator can be judged in motion:
# the marker should move and change colour with every step, in step with the
# markers on the map, without the viewer touching anything.
#
# Run from the project root:  Rscript scripts/indicator_animations_v2.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))
years <- as.character(2019:2025)

for (style in c("bar", "roundel")) {
  theme <- tempfile(fileext = ".yaml")
  writeLines(c(
    "banner:",
    '  background: "#5F3E94"',
    "indicator:",
    paste0('  style: "', style, '"')
  ), theme)

  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = years,
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0(
      "Merton NO₂ annual mean 2019–2025 — ", style, " indicator"
    ),
    # 1400 ms a year: slow enough to read the figure at each step, quick
    # enough that the seven-year fall reads as one movement
    autoplay = TRUE,
    play_speed = 1400,
    output_file = paste0("indicator_", style, "-animated_v2.html")
  )
}

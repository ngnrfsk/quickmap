# Worked examples of the two desktop/tablet placements for the network
# figures, side by side and NOT overwriting each other.
#
#   right       — the figures to the right of the colour ramp (current default)
#   under_title — the figures beneath the legend's title pill
#
# The earlier lead-column prototype (31 July) was lost because the demo script
# reused filenames; every output here is named for its placement.
#
# Run from the project root:  Rscript scripts/indicator_placement_v4.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))
years <- as.character(2019:2025)

theme_for <- function(placement) {
  f <- tempfile(fileext = ".yaml")
  writeLines(c(
    "banner:",
    '  background: "#5F3E94"',
    "indicator:",
    "  show_max: true",
    paste0('  placement: "', placement, '"')
  ), f)
  f
}

for (placement in c("right", "under_title")) {
  theme <- theme_for(placement)

  # interactive, for viewing at any window width
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = years,
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0("Figures ", placement, " — Merton NO₂ 2019–2025"),
    autoplay = TRUE,
    play_speed = 1400,
    output_file = paste0("indicator_placement-", placement, "_v4.html")
  )

  # print export, one year, so the two can be compared on paper
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = "2019",
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0("Figures ", placement, " — Merton NO₂"),
    export_image = c(4000, 3000),
    output_file = paste0("indicator_placement-", placement, "-print_v4.html")
  )

  # and at desktop and tablet widths, which is where placement matters:
  # the tablet query (481-850px) keeps the legend horizontal but tighter
  for (w in c(1400, 820)) {
    webshot2::webshot(
      sprintf("aq_maps/indicator_placement-%s_v4.html", placement),
      sprintf("aq_maps/indicator_placement-%s_%d.png", placement, w),
      vwidth = w, vheight = if (w == 1400) 900 else 1000, delay = 2
    )
  }
}

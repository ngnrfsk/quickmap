# Prototypes for two proposals (user, 2026-07-31):
#   1. a diamond marking the network maximum alongside the mean's roundel
#   2. the network figures moved under the legend title, so they collapse with
#      the legend instead of sitting off to the right
#
# Proposal 2 is now the layout in all cases; proposal 1 is switched by
# indicator.show_max, so both states are rendered here for comparison.
#
# Run from the project root:  Rscript scripts/indicator_max-and-lead_v3.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))
years <- as.character(2019:2025)

theme_for <- function(show_max) {
  f <- tempfile(fileext = ".yaml")
  writeLines(c(
    "banner:",
    '  background: "#5F3E94"',
    "indicator:",
    paste0("  show_max: ", if (show_max) "true" else "false")
  ), f)
  f
}

for (variant in c("mean-only", "with-max")) {
  theme <- theme_for(variant == "with-max")

  # Animated, so both markers can be judged in motion — the maximum moves
  # further than the mean, which is the case that tests the collision rule
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = years,
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0("Merton NO₂ 2019–2025 — ", variant),
    autoplay = TRUE,
    play_speed = 1400,
    output_file = paste0("indicator_", variant, "-animated_v3.html")
  )

  # Print, both ends of the series
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = c("2019", "2025"),
    colour_scale = "lbm_no2",
    theme_file = theme,
    title = paste0("Merton NO₂ — ", variant),
    export_image = c(4000, 3000),
    output_file = paste0("indicator_", variant, "-print_v3.html")
  )
}

# The crowded case: a single year where mean and maximum fall close together.
# 2025's mean is 23.2 and its highest panel site 33.9 — under two blocks
# apart — which is where the collision rule has to earn its keep.
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = "2025",
  colour_scale = "lbm_no2",
  theme_file = theme_for(TRUE),
  title = "Merton NO₂ 2025 — mean and maximum close together",
  export_image = c(1600, 1200),
  output_file = "indicator_crowded_v3.html"
)

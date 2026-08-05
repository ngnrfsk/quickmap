# Animation speed control (2026-08-05): demonstration maps.
# Run from the repo root: Rscript scripts/speed_demo-maps_v2.R
#
# v2: the speed set now varies with the step count (user decision) — short
# animations get 0.5/1/2/4, long ones the full 0.25-8x. Adds map 3 so the
# legend indicator's maximum can be seen beside the mean.
#
# Two animated maps, either side of the step-count default:
#   1. Merton annual, 7 steps  -> default 1200ms, four speeds, pre-built layers
#   2. PM2.5 episode, 108 steps -> default 450ms, six speeds, lazy Canvas path
#      (the only one of the two that crossfades)
#
# What to check: the speed button cycles and wraps; playback changes pace at
# once, including after dragging the slider; at the fastest speed the colours
# still resolve rather than smearing; below 480px wide the button disappears
# and the rest of the card is unchanged.
library(quickmap)

# 1. Annual, 7 steps, all defaults.
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  output_file = "speed_merton-annual_v2.html",
  title = "Merton NO2 Annual Mean, 2018-2024",
  marker_labels = "labels"
))

# 2. Episode, 108 steps, autoplay on so it is moving when the page opens.
#    No legend indicator here: it is annual-only by design, because the
#    thresholds behind it are annual-mean limits (backlog issue 13).
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  output_file = "speed_episode_v2.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE
)

# 3. The same annual map with the indicator's maximum switched on, so the
#    diamond sits beside the mean's roundel. show_max defaults to FALSE.
max_theme <- tempfile(fileext = ".yaml")
writeLines(c("indicator:", "  show_max: true"), max_theme)
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  theme_file = max_theme,
  output_file = "speed_merton-annual-max_v2.html",
  title = "Merton NO2, mean and maximum",
  marker_labels = "labels"
))

for (f in c("speed_merton-annual_v2.html", "speed_episode_v2.html",
            "speed_merton-annual-max_v2.html")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

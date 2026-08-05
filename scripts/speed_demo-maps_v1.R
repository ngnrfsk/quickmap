# Animation speed control (2026-08-05): demonstration maps.
# Run from the repo root: Rscript scripts/speed_demo-maps_v1.R
#
# Two animated maps, chosen to sit either side of the step-count default:
#   1. Merton annual, 7 steps  -> default 1200ms, pre-built-layers path
#   2. PM2.5 episode, 108 steps -> default 450ms, lazy Canvas path (the only
#      one of the two that crossfades)
#
# What to check: the speed button in the time-slider card cycles
# 0.25 -> 0.5 -> 1 -> 2 -> 4 -> 8 and wraps; playback visibly changes pace at
# once, including after dragging the slider; at 8x the colours still resolve
# rather than smearing; below 480px wide the button disappears and the rest of
# the card is unchanged.
library(quickmap)

# 1. Annual, 7 steps, all defaults.
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  output_file = "speed_merton-annual_v1.html",
  title = "Merton NO2 Annual Mean, 2018-2024",
  marker_labels = "labels"
))

# 2. Episode, 108 steps, autoplay on so it is moving when the page opens.
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  output_file = "speed_episode_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE
)

for (f in c("speed_merton-annual_v1.html", "speed_episode_v1.html")) {
  cat(f, file.size(file.path("aq_maps", f)), "bytes\n")
}

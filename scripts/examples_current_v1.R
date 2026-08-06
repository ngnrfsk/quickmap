# The current working examples — one of each kind of output QuickMap makes.
#
# These are the maps to look at when you want to see what the package
# currently produces. They are disposable: this script rebuilds them, so
# aq_maps can be cleared at any time without losing anything.
#
#   1. long animation   108 hourly steps, the January 2024 episode (lazy path)
#   2. short animation  7 annual steps, Merton NO2
#   3. static export    the same map as a print-ready JPG
#
# Run from the repo root:  Rscript scripts/examples_current_v1.R

library(quickmap)

stamp <- "260805"

# -- 1. Long animation -------------------------------------------------------
# 108 hourly steps, so this is the lazy rendering path: markers are drawn on
# Canvas and restyled from one embedded payload rather than pre-built per step.
# Recipe carried over from the item 10 demo maps (removed 2026-08-06;
# see git history): the stripes
# scale, no vignette, autoplay — but on the pale CartoDB.Positron background
# (user, 2026-08-05). OSM was chosen for that demo because the vignette dimming
# is too faint on pale tiles; this map has no vignette, so that reason does not
# apply, and the paler background lets the stripes colours carry the map.
#
# Wind: Heathrow hourly observations for the same days. Density settled at
# 0.00125 (user, 2026-08-05) after three halvings from 0.01 — a quarter of the
# 1/300 default. On pale Positron tiles the flow reads at a far lower density
# than the default assumes, because nothing on the basemap competes with it.
episode_theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "map:", '  base_tiles: "CartoDB.Positron"',
  "wind:",
  "  particle_density: 0.00125",
  "  line_width: 1.8"
), episode_theme)

heathrow <- tryCatch(
  {
    w <- from_worldmet(station = "037720-99999", year = 2024)
    w[format(w$date, "%Y-%m") == "2024-01", ]
  },
  error = function(e) {
    message("NOAA fetch failed, wind omitted: ", conditionMessage(e))
    NULL
  }
)

quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  theme_file = episode_theme,
  title = "PM2.5 episode: 15-20 January 2024",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500,
  wind = heathrow,
  output_file = sprintf("example_long-animation_%s.html", stamp)
)

# -- 2. Short animation ------------------------------------------------------
# 7 annual steps, so the pre-built path, and few enough steps for the legend
# indicator to apply.
merton_theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:", '  background: "#5F3E94"',
  "indicator:", "  show_max: true"
), merton_theme)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")

quickmap(
  prepared,
  boroughs = "Merton",
  display_times = as.character(2019:2025),
  colour_scale = "lbm_no2",
  theme_file = merton_theme,
  title = "Merton NO₂ annual mean 2019–2025",
  autoplay = TRUE,
  play_speed = 1400,
  output_file = sprintf("example_short-animation_%s.html", stamp)
)

# -- 3. Static export --------------------------------------------------------
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = "2025",
  colour_scale = "lbm_no2",
  theme_file = merton_theme,
  title = "Merton NO₂ annual mean concentrations (µg/m³)",
  export_image = c(4000, 3000),
  output_file = sprintf("example_static-export_%s.html", stamp)
)

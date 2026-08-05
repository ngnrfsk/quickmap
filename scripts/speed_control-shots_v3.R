# Animation speed control (2026-08-05): close-ups for review.
# Run after scripts/speed_demo-maps_v3.R.
# Rscript scripts/speed_control-shots_v3.R
#
# v3: legend shots follow the new show_max default.
# v2: the short set (0.5/1/2/4) on the 7-step map, the full set on the
# 108-step episode map, plus the legend with the indicator's maximum on.
setwd("/Users/iarla/Coding/quickmap")

open_map <- function(path, w, h) {
  b <- chromote::ChromoteSession$new(width = w, height = h)
  loaded <- b$Page$loadEventFired(wait_ = FALSE)
  b$Page$navigate(paste0("file://", normalizePath(path)))
  b$wait_for(loaded)
  Sys.sleep(3)
  b
}

ev <- function(b, expr) {
  r <- b$Runtime$evaluate(expr, returnByValue = TRUE)
  if (!is.null(r$exceptionDetails)) stop(r$exceptionDetails$text)
  r$result$value
}

shoot <- function(b, out, sel = "#yearControl", pad = 26) {
  b$screenshot(filename = out, selector = sel, expand = pad)
  cat("wrote", out, "\n")
}

label <- function(b) ev(b, "document.getElementById('speedButton').textContent")
press <- function(b) ev(b, "document.getElementById('speedButton').click()")

# 7 steps: four speeds, so a full cycle is three presses back to 1x
b <- open_map("aq_maps/speed_merton-annual_v3.html", 1200, 900)
cat("annual speeds:", ev(b, "JSON.stringify(window.quickmapConfig.speeds)"), "\n")
shoot(b, "aq_maps/speed_card-annual-1x_v3.png")
press(b); press(b)
stopifnot(identical(label(b), "4×"))
shoot(b, "aq_maps/speed_card-annual-4x_v3.png")
press(b)
stopifnot(identical(label(b), "0.5×"))
shoot(b, "aq_maps/speed_card-annual-05x_v3.png")
b$close()

# 108 steps: the full set is still there
b <- open_map("aq_maps/speed_episode_v3.html", 1200, 900)
cat("episode speeds:", ev(b, "JSON.stringify(window.quickmapConfig.speeds)"), "\n")
press(b); press(b); press(b)
stopifnot(identical(label(b), "8×"))
shoot(b, "aq_maps/speed_card-episode-8x_v3.png")
press(b)
stopifnot(identical(label(b), "0.25×"))
shoot(b, "aq_maps/speed_card-episode-025x_v3.png")
b$close()

# a phone: the button goes, the rest of the card stays
b <- open_map("aq_maps/speed_merton-annual_v3.html", 390, 844)
shoot(b, "aq_maps/speed_card-mobile_v3.png", pad = 14)
b$close()

# the legend as it now comes by default (mean and maximum), and the opt-out
b <- open_map("aq_maps/speed_merton-annual_v3.html", 1200, 900)
shoot(b, "aq_maps/speed_legend-default_v3.png", ".legend-container", 10)
b$close()
b <- open_map("aq_maps/speed_merton-annual-mean-only_v3.html", 1200, 900)
shoot(b, "aq_maps/speed_legend-mean-only_v3.png", ".legend-container", 10)
b$close()

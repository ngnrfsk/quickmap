# Animation speed control (2026-08-05): close-ups of the time-slider card for
# review. Run after scripts/speed_demo-maps_v1.R.
# Rscript scripts/speed_control-shots_v1.R
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

# the card, with generous margin so the shot shows it in place on the map
shoot_card <- function(b, out, pad = 26) {
  b$screenshot(filename = out, selector = "#yearControl", expand = pad)
  cat("wrote", out, "\n")
}

dir.create("aq_maps", showWarnings = FALSE)

b <- open_map("aq_maps/speed_merton-annual_v1.html", 1200, 900)
shoot_card(b, "aq_maps/speed_card-1x_v1.png")
for (i in 1:3) ev(b, "document.getElementById('speedButton').click()")
stopifnot(identical(ev(b, "document.getElementById('speedButton').textContent"), "8×"))
shoot_card(b, "aq_maps/speed_card-8x_v1.png")
for (i in 1:1) ev(b, "document.getElementById('speedButton').click()")
stopifnot(identical(ev(b, "document.getElementById('speedButton').textContent"), "0.25×"))
shoot_card(b, "aq_maps/speed_card-025x_v1.png")
b$close()

# a phone: the button is gone, the rest of the card unchanged
b <- open_map("aq_maps/speed_merton-annual_v1.html", 390, 844)
shoot_card(b, "aq_maps/speed_card-mobile_v1.png", pad = 14)
b$close()

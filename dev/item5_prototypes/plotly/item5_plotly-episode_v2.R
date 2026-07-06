# item5_plotly-episode_v2.R — plotly candidate, best-practice revision after
# review of v1:
#   1. partial_bundle(): ship only the scattermapbox trace module, not the
#      full 3.7 MB plotly.js bundle (documented plotly-R practice for saved
#      widgets).
#   2. Partial frames: the plotly.js animation API accepts frames that update
#      only marker.color/text on the existing trace. v1's plot_ly(frame = ~t)
#      duplicated lon/lat/text into all 108 frames. Frames are hand-built
#      here; slider/play controls use the documented Plotly.animate
#      updatemenus/sliders pattern.
#      Verified caveat: redraw = FALSE silently skips repainting mapbox/GL
#      traces (data updates, canvas does not) — redraw = TRUE is mandatory,
#      measured ~53 ms/frame on the episode fixture.
library(plotly)
library(jsonlite)
library(htmlwidgets)

shared <- "/Users/iarla/Coding/quickmap/dev/item5_prototypes/shared"
out <- "/Users/iarla/Coding/quickmap/aq_maps"

build <- function(data_file, out_name, title) {
  ep <- read_json(file.path(shared, data_file))
  th <- unlist(ep$thresholds); cols <- unlist(ep$colours)
  cols[cols == "white"] <- "#FFFFFF"
  times <- unlist(ep$times)
  nt <- length(times)
  lon <- sapply(ep$sites, `[[`, "lon")
  lat <- sapply(ep$sites, `[[`, "lat")
  code <- sapply(ep$sites, `[[`, "code")
  vals <- lapply(seq_len(nt), function(j)
    sapply(ep$sites, function(s) {
      x <- s$v[[j]]; if (is.null(x)) NA_real_ else x
    }))
  colour_at <- function(v) {
    b <- findInterval(v, th); b <- pmin(b, length(th))
    out <- cols[b]; out[is.na(v)] <- "#FFFFFF"; out
  }
  text_at <- function(v) paste0(code, "<br>", ifelse(is.na(v), "no data", v))

  p <- plot_ly(type = "scattermapbox", mode = "markers",
               lon = lon, lat = lat,
               marker = list(size = 12, color = colour_at(vals[[1]]),
                             opacity = 0.95),
               text = text_at(vals[[1]]), hoverinfo = "text") |>
    layout(title = title,
           mapbox = list(style = "open-street-map",
                         center = list(lon = -0.22, lat = 51.45), zoom = 9),
           sliders = list(list(
             active = 0, currentvalue = list(prefix = ""), pad = list(t = 30),
             steps = lapply(seq_len(nt), function(j) list(
               method = "animate", label = times[j],
               args = list(list(times[j]),
                           list(mode = "immediate", frame = list(duration = 0, redraw = TRUE),
                                transition = list(duration = 0))))))),
           updatemenus = list(list(
             type = "buttons", x = 0, y = -0.05, direction = "right",
             buttons = list(list(
               method = "animate", label = "Play",
               args = list(NULL,
                           list(mode = "immediate", fromcurrent = TRUE,
                                frame = list(duration = 250, redraw = TRUE),
                                transition = list(duration = 0))))))))

  pb <- plotly_build(p)
  # partial frames: colour + hover text only, no coordinate duplication
  pb$x$frames <- lapply(seq_len(nt), function(j) list(
    name = times[j],
    data = list(list(marker = list(size = 12, color = colour_at(vals[[j]]),
                                   opacity = 0.95),
                     text = text_at(vals[[j]]))),
    traces = list(0)))

  f <- file.path(out, out_name)
  saveWidget(partial_bundle(pb), f, selfcontained = TRUE)
  cat(out_name, file.size(f), "bytes\n")
}

build("episode.json", "item5_plotly-episode_v2.html",
      "plotly v2 - PM2.5 episode Jan 15-20 2024")
build("synthetic.json", "item5_plotly-synthetic_v2.html",
      "plotly v2 - synthetic 500x200")

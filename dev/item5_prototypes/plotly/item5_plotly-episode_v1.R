# item5_plotly-episode_v1.R — plotly candidate: native animation frames +
# slider on a map trace. Measures the per-frame data duplication cost.
library(plotly)
library(jsonlite)
library(htmlwidgets)

shared <- "/Users/iarla/Coding/quickmap/dev/item5_prototypes/shared"
out <- "/Users/iarla/Coding/quickmap/aq_maps"

build <- function(data_file, out_name, title) {
  ep <- read_json(file.path(shared, data_file))
  th <- unlist(ep$thresholds); cols <- unlist(ep$colours)
  times <- unlist(ep$times)
  n <- length(ep$sites); nt <- length(times)
  # long format: plotly frames need one row per site per step
  d <- data.frame(
    code = rep(sapply(ep$sites, `[[`, "code"), each = nt),
    lon = rep(sapply(ep$sites, `[[`, "lon"), each = nt),
    lat = rep(sapply(ep$sites, `[[`, "lat"), each = nt),
    t = rep(times, n),
    v = unlist(lapply(ep$sites, function(s)
      sapply(s$v, function(x) if (is.null(x)) NA_real_ else x)))
  )
  bin <- findInterval(d$v, th)
  bin[is.na(bin)] <- length(cols)
  d$colour <- cols[pmin(bin, length(th))]
  d$colour[is.na(d$v)] <- "#FFFFFF"

  p <- plot_ly(d, lon = ~lon, lat = ~lat, frame = ~t,
               type = "scattermapbox", mode = "markers",
               marker = list(size = 12, color = ~I(colour)),
               text = ~paste0(code, "<br>", ifelse(is.na(v), "no data", v)),
               hoverinfo = "text") |>
    layout(title = title,
           mapbox = list(style = "open-street-map",
                      center = list(lon = -0.22, lat = 51.45), zoom = 9)) |>
    animation_opts(frame = 250, transition = 0, redraw = FALSE)

  f <- file.path(out, out_name)
  saveWidget(p, f, selfcontained = TRUE)
  cat(out_name, file.size(f), "bytes\n")
}

build("episode.json", "item5_plotly-episode_v1.html",
      "plotly - PM2.5 episode Jan 15-20 2024")
build("synthetic.json", "item5_plotly-synthetic_v1.html",
      "plotly - synthetic 500x200")

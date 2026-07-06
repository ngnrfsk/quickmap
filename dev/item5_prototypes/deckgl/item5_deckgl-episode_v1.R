# item5_deckgl-episode_v1.R — mapdeck (deck.gl CRAN wrapper) prototype.
# Scope finding: a saved mapdeck widget has no time control and no documented
# way to swap layer data from page JS (proxy updates are Shiny-only), so this
# prototype renders step 0 + boundary + schools to measure bundle size and
# offline behaviour. Time-stepping would require reverse-engineering
# mapdeck.js internals — recorded as a migration cost, not built.
library(mapdeck)
library(sf)
library(jsonlite)
library(htmlwidgets)

shared <- "/Users/iarla/Coding/quickmap/dev/item5_prototypes/shared"
out <- "/Users/iarla/Coding/quickmap/aq_maps"

ep <- read_json(file.path(shared, "episode.json"))
th <- unlist(ep$thresholds); cols <- unlist(ep$colours)
cols[cols == "white"] <- "#FFFFFF"  # colourvalues requires hex
colour_for <- function(v) {
  if (is.null(v)) return(cols[length(cols)])
  i <- findInterval(v, th)
  cols[max(1, min(i, length(th)))]
}
pts <- data.frame(
  lon = sapply(ep$sites, function(s) s$lon),
  lat = sapply(ep$sites, function(s) s$lat),
  code = sapply(ep$sites, function(s) s$code),
  colour = sapply(ep$sites, function(s) colour_for(s$v[[1]]))
)

boundary <- st_read(file.path(shared, "boundary_simplified.json"), quiet = TRUE)
sch <- read_json(file.path(shared, "schools.json"))
schools <- data.frame(
  lon = sapply(sch$features, function(f) f$geometry$coordinates[[1]]),
  lat = sapply(sch$features, function(f) f$geometry$coordinates[[2]]),
  name = sapply(sch$features, function(f) f$properties$name)
)

m <- mapdeck(location = c(-0.22, 51.45), zoom = 9) |>
  add_polygon(data = boundary, fill_colour = "#00579415",
              stroke_colour = "#005794", stroke_width = 30) |>
  add_scatterplot(data = pts, lon = "lon", lat = "lat",
                  fill_colour = "colour", radius = 250,
                  tooltip = "code", layer_id = "aq") |>
  add_scatterplot(data = schools, lon = "lon", lat = "lat",
                  fill_colour = "#4a90d9", radius = 150,
                  tooltip = "name", layer_id = "schools")

f <- file.path(out, "item5_deckgl-episode_v1.html")
saveWidget(m, f, selfcontained = TRUE)
cat("saved:", f, file.size(f), "bytes\n")

# Leaflegend Symbol Sampler
# Creates interactive map showing all available symbol shapes

library(leaflet)
library(leaflegend)
library(sf)
library(htmlwidgets)

# Get all available shapes
shapes <- availableShapes()
all_shapes <- unique(c(shapes$default, shapes$pch))

# Create grid of points in London area
n_cols <- 10
n_rows <- ceiling(length(all_shapes) / n_cols)

# Generate coordinates (grid layout)
lat_base <- 51.5
lon_base <- -0.3
lat_spacing <- 0.02
lon_spacing <- 0.03

coords <- data.frame(
  shape = all_shapes,
  lat = lat_base - ((seq_along(all_shapes) - 1) %/% n_cols) * lat_spacing,
  lon = lon_base + ((seq_along(all_shapes) - 1) %% n_cols) * lon_spacing
)

# Create map
m <- leaflet(coords) %>%
  addTiles() %>%
  setView(lng = mean(coords$lon), lat = mean(coords$lat), zoom = 11)

# Add each symbol type
for (i in seq_len(nrow(coords))) {
  m <- m %>%
    addSymbols(
      lng = coords$lon[i],
      lat = coords$lat[i],
      shape = coords$shape[i],
      color = "black",
      fillColor = "red",
      opacity = 1,
      fillOpacity = 0.7,
      width = 15,
      strokeWidth = 2,
      label = coords$shape[i],
      labelOptions = labelOptions(
        permanent = TRUE,
        direction = "right",
        offset = c(10, 0),
        textsize = "10px"
      )
    )
}

# Save
saveWidget(m, "symbols_sampler.html", selfcontained = TRUE)
cat("Symbol sampler saved to symbols_sampler.html\n")
cat("Total shapes:", length(all_shapes), "\n")

# item5_prepare-data_v1.R — shared datasets for the item-5 backend comparison.
# Produces, in dev/item5_prototypes/shared/:
#   episode.json     compact shared payload: {times, thresholds, colours, sites:[{code,lon,lat,v:[...]}]}
#   synthetic.json   500 markers x 200 steps, same structure
#   boundary.json    GeoJSON of the Wandsworth+Richmond boundary
#   schools.json     GeoJSON points, Merton schools (static overlay)
# And regenerates the Leaflet reference episode map in aq_maps/.

library(quickmap)
library(sf)
library(jsonlite)

repo <- "/Users/iarla/Coding/quickmap"
shared <- file.path(repo, "dev/item5_prototypes/shared")
dp <- Sys.getenv("DATA_PATH")
stopifnot(dp != "")

# ---- 1. Episode fixture -> compact JSON ----
load(file.path(dp, "episodeJan15-20_2024_sf_all.Rdata"))  # subset_data_sf_all
ep <- subset_data_sf_all
coords <- st_coordinates(ep)
d <- data.frame(code = ep$siteCode, t = ep$year_str, v = ep$pm25,
                lon = round(coords[, 1], 5), lat = round(coords[, 2], 5))
times <- sort(unique(d$t))
sites <- unique(d[, c("code", "lon", "lat")])
sites <- sites[!duplicated(sites$code), ]
m <- matrix(NA_real_, nrow(sites), length(times),
            dimnames = list(sites$code, times))
m[cbind(match(d$code, sites$code), match(d$t, times))] <- round(d$v, 1)

scale <- load_colour_scale("stripes_pm25")
payload <- list(
  times = times,
  thresholds = scale$thresholds[is.finite(scale$thresholds)],
  colours = scale$colours,
  sites = lapply(seq_len(nrow(sites)), function(i) {
    list(code = sites$code[i], lon = sites$lon[i], lat = sites$lat[i],
         v = unname(as.list(ifelse(is.na(m[i, ]), "null", m[i, ]))))
  })
)
# write with proper nulls
payload$sites <- lapply(seq_len(nrow(sites)), function(i) {
  vv <- m[i, ]
  list(code = sites$code[i], lon = sites$lon[i], lat = sites$lat[i],
       v = unname(lapply(vv, function(x) if (is.na(x)) NULL else x)))
})
write_json(payload, file.path(shared, "episode.json"), auto_unbox = TRUE,
           null = "null", digits = 5)
cat("episode:", nrow(sites), "sites x", length(times), "steps\n")

# ---- 2. Synthetic 500 x 200 ----
set.seed(42)
ns <- 500; nt <- 200
lon <- runif(ns, -0.35, 0.05); lat <- runif(ns, 51.35, 51.6)
vals <- matrix(NA_real_, ns, nt)
vals[, 1] <- runif(ns, 5, 40)
for (j in 2:nt) vals[, j] <- pmax(0, pmin(80, vals[, j - 1] + rnorm(ns, 0, 3)))
vals <- round(vals, 1)
syn_times <- format(seq(as.POSIXct("2024-01-01 00:00", tz = "UTC"),
                        by = "hour", length.out = nt), "%Y-%m-%d %H:%M")
syn <- list(
  times = syn_times,
  thresholds = scale$thresholds[is.finite(scale$thresholds)],
  colours = scale$colours,
  sites = lapply(seq_len(ns), function(i) {
    list(code = sprintf("SYN%03d", i), lon = round(lon[i], 5),
         lat = round(lat[i], 5), v = unname(as.list(vals[i, ])))
  })
)
write_json(syn, file.path(shared, "synthetic.json"), auto_unbox = TRUE,
           null = "null", digits = 5)
cat("synthetic written\n")

# ---- 3. Boundary + schools overlays ----
gbs <- quickmap:::get_boundary_sf  # unexported; research use only
b <- rbind(gbs("Wandsworth"), gbs("Richmond"))
st_write(st_geometry(b), file.path(shared, "boundary.json"),
         driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)

sch <- read.csv(file.path(dp, "schools_Merton.csv"))
sch_sf <- st_transform(st_as_sf(sch, coords = c("Easting", "Northing"),
                                crs = 27700), 4326)
sc <- st_coordinates(sch_sf)
sch_gj <- list(type = "FeatureCollection",
  features = lapply(seq_len(nrow(sch)), function(i) {
    list(type = "Feature",
         geometry = list(type = "Point",
                         coordinates = c(round(sc[i, 1], 5), round(sc[i, 2], 5))),
         properties = list(name = sch$School[i]))
  }))
write_json(sch_gj, file.path(shared, "schools.json"), auto_unbox = TRUE,
           digits = 5)
cat("overlays written\n")

# ---- 4. Leaflet reference episode map (mode-a baseline) ----
old <- setwd(repo)
create_pollution_map(
  data_sources = list("episodeJan15-20_2024_sf_all.Rdata"),
  data_ids = c("bl_sensors"),
  boroughs = c("Wandsworth", "Richmond"),
  pollutant = "pm25",
  colour_scale = "stripes_pm25",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "item5_leaflet-episode-reference_v1.html",
  title = "PM2.5 Episode: Jan 15-20, 2024",
  styling_type = "html",
  vignette = FALSE,
  marker_labels = TRUE,
  banner_colour = "#005794",
  autoplay = TRUE,
  play_speed = 500
)
setwd(old)
sz <- file.size(file.path(repo, "aq_maps/item5_leaflet-episode-reference_v1.html"))
cat("Leaflet reference size:", sz, "bytes\n")

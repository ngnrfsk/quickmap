# Wind layer (roadmap item 7): worldmet observations rendered as a
# leaflet-velocity particle overlay, time-synced with the pollution layers.
# The plugin JS/CSS is vendored in inst/controls/leaflet-velocity/ and
# attached as an htmlwidgets dependency so saveWidget(selfcontained = TRUE)
# inlines it (sharing mode (a)).

#' Create a wind layer from worldmet data
#'
#' Builds the wind input for [quickmap()]'s `wind` argument from NOAA
#' Integrated Surface Database observations. Supply either a data frame
#' already fetched (e.g. via [worldmet::importNOAA()], or anything with
#' `date`, `ws`, `wd` columns) or a station code plus year(s) to fetch.
#' Wind speed/direction are converted to U/V components and averaged to the
#' map's displayed time steps at render time; a uniform city-scale field is
#' assumed (one representative station).
#'
#' @param data Data frame with POSIXct `date`, wind speed `ws` (m/s) and
#'   wind direction `wd` (degrees, meteorological). NULL to fetch instead.
#' @param station NOAA station code (e.g. `"037720-99999"` for Heathrow),
#'   used when `data` is NULL.
#' @param year Year(s) to fetch when `data` is NULL.
#' @return A `qm_wind` object.
#' @family wind
#' @export
from_worldmet <- function(data = NULL, station = NULL, year = NULL) {
  if (is.null(data)) {
    if (is.null(station) || is.null(year)) {
      stop("Supply either `data`, or `station` and `year` to fetch from NOAA.",
           call. = FALSE)
    }
    if (!requireNamespace("worldmet", quietly = TRUE)) {
      stop("Package 'worldmet' required to fetch wind data. ",
           "Install with: install.packages('worldmet')", call. = FALSE)
    }
    data <- worldmet::importNOAA(code = station, year = year)
  }

  required <- c("date", "ws", "wd")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop("Wind data must have columns date, ws, wd (missing: ",
         paste(missing, collapse = ", "), ").", call. = FALSE)
  }

  data <- as.data.frame(data)[, intersect(
    c("date", "ws", "wd", "latitude", "longitude", "station", "code"),
    names(data)
  )]
  data <- data[!is.na(data$ws) & !is.na(data$wd), , drop = FALSE]
  if (nrow(data) == 0) stop("Wind data has no complete ws/wd rows.", call. = FALSE)

  # meteorological decomposition: wd is the direction the wind comes FROM
  rad <- data$wd * pi / 180
  data$u <- -data$ws * sin(rad)
  data$v <- -data$ws * cos(rad)

  structure(data, class = c("qm_wind", "data.frame"))
}

#' @keywords internal
as_qm_wind <- function(x) {
  if (inherits(x, "qm_wind")) return(x)
  if (is.data.frame(x)) return(from_worldmet(data = x))
  stop("`wind` must be a qm_wind object (see from_worldmet()) or a data ",
       "frame with date/ws/wd columns.", call. = FALSE)
}

# strftime format matching the year_str grammar of a display time label
#' @keywords internal
wind_time_format <- function(time_label) {
  switch(as.character(nchar(time_label)),
    "4" = "%Y",
    "7" = "%Y-%m",
    "10" = "%Y-%m-%d",
    "13" = "%Y-%m-%d %H",
    "16" = "%Y-%m-%d %H:%M",
    stop("Unrecognised display time format: ", time_label, call. = FALSE)
  )
}

#' Build the leaflet-velocity payload: per display time, the period-mean
#' U/V wind on a uniform 2x2 grid covering the map bbox (GRIB-like headers
#' as leaflet-velocity expects). Steps with no observations get null frames
#' (the overlay empties rather than showing stale wind).
#' @keywords internal
build_wind_payload <- function(wind, display_times, bbox) {
  times <- as.character(sort(unique(display_times)))
  fmt <- wind_time_format(times[1])
  wind_key <- format(wind$date, fmt, tz = attr(wind$date, "tzone") %||% "UTC")

  # Uniform field, so widening the grid is free: +-3 degrees keeps particles
  # over the whole viewport at any plausible zoom-out (issue (a), 2026-07-07)
  pad <- 3
  lo1 <- unname(bbox["xmin"]) - pad
  lo2 <- unname(bbox["xmax"]) + pad
  la1 <- unname(bbox["ymax"]) + pad  # velocity grids scan north -> south
  la2 <- unname(bbox["ymin"]) - pad

  header <- function(parameter_number) {
    list(
      parameterCategory = 2,
      parameterNumber = parameter_number,
      nx = 2, ny = 2,
      lo1 = lo1, la1 = la1, lo2 = lo2, la2 = la2,
      dx = lo2 - lo1, dy = la1 - la2
    )
  }

  frames <- lapply(times, function(t) {
    rows <- wind_key == t
    if (!any(rows)) return(NULL)
    u <- mean(wind$u[rows], na.rm = TRUE)
    v <- mean(wind$v[rows], na.rm = TRUE)
    list(
      list(header = header(2), data = I(rep(u, 4))),
      list(header = header(3), data = I(rep(v, 4)))
    )
  })

  covered <- sum(!vapply(frames, is.null, TRUE))
  if (covered == 0) {
    warning("Wind data covers none of the displayed time steps; ",
            "the wind layer will be empty.", call. = FALSE)
  } else if (covered < length(times)) {
    message("Wind data covers ", covered, " of ", length(times),
            " displayed time steps.")
  }

  list(
    times = I(times),
    frames = frames,
    maxVelocity = ceiling(max(wind$ws, na.rm = TRUE)) + 2
  )
}

#' Particle styling for the wind overlay (item 10): theme-controlled, with
#' the approved speed-ramp defaults. Maps theme keys to leaflet-velocity
#' option names.
#' @keywords internal
wind_style_options <- function(wind_style = NULL) {
  defaults <- get_default_theme()$wind
  s <- utils::modifyList(defaults, wind_style %||% list())
  list(
    colorScale = I(unlist(s$colour_ramp)),
    particleMultiplier = s$particle_density,
    lineWidth = s$line_width,
    velocityScale = s$velocity_scale
  )
}

#' @keywords internal
load_wind_controller_js <- function() {
  read_template_file(
    file.path(get_package_dir("controls"), "wind-controller.js")
  )
}

#' @keywords internal
velocity_dependency <- function() {
  htmltools::htmlDependency(
    name = "leaflet-velocity",
    version = "2.1.4",
    # unminified build carrying the QUICKMAP updateData patch (in-place wind
    # swap without particle reset) — see LICENSE.md alongside
    src = file.path(get_package_dir("controls"), "leaflet-velocity"),
    script = "leaflet-velocity.js",
    stylesheet = "leaflet-velocity.min.css"
  )
}

#' Attach the wind overlay to an interactive map widget
#' @keywords internal
add_wind_layer <- function(map, wind, display_times, bbox, wind_style = NULL) {
  payload <- build_wind_payload(wind, display_times, bbox)
  payload$style <- wind_style_options(wind_style)
  map$dependencies <- c(map$dependencies, list(velocity_dependency()))
  htmlwidgets::onRender(map, load_wind_controller_js(), data = payload)
}

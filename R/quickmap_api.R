# quickmap() public API (roadmap item 4)
# quickmap() is the core entry point consuming qm_layer atomic units;
# create_pollution_map() is a thin compatibility wrapper over it.

# Downgrade a qm_layer to the column names the render pipeline consumes
# (year_str/siteCode/Longitude/Latitude). Purely additive: canonical columns
# stay, so this disappears when the pipeline itself adopts the qm contract.
#' @keywords internal
qm_to_legacy <- function(layer) {
  m <- qm_meta(layer)
  data <- layer
  class(data) <- setdiff(class(data), "qm_layer")
  if (!is.null(m$time_col) && !"year_str" %in% names(data)) {
    data$year_str <- data$time_label
  }
  if (!"siteCode" %in% names(data) && "code" %in% names(data)) {
    data$siteCode <- data$code
  }
  if (!all(c("Longitude", "Latitude") %in% names(data))) {
    coords <- sf::st_coordinates(data)
    data$Longitude <- as.numeric(coords[, 1])
    data$Latitude <- as.numeric(coords[, 2])
  }
  data
}

# Normalise one element of `layers` to a qm_layer
#' @keywords internal
as_qm_layer <- function(x, pollutant, temporal = NULL) {
  if (inherits(x, "qm_layer")) return(x)
  if (is.character(x) && length(x) == 1) {
    if (grepl("\\.rdata$", x, ignore.case = TRUE)) {
      return(from_rdata(x, pollutant))
    }
    return(from_csv(x, pollutant = pollutant, temporal = temporal))
  }
  if (is.data.frame(x)) return(qm_layer(x))
  stop("Cannot interpret a layer of class ", paste(class(x), collapse = "/"),
       ". Supply a qm_layer, a file path, or a data.frame/sf object.",
       call. = FALSE)
}

#' Build an interactive air quality map
#'
#' The core QuickMap entry point. Takes one layer or a list of layers — file
#' paths, [qm_layer()] objects, or data.frames — and renders a self-contained
#' interactive HTML map (optionally with static JPG export). A two-line call
#' works; each additional parameter unlocks more sophistication.
#'
#' @section Design rule — where parameters live:
#' Properties of a *layer* (its value column, time column, label column,
#' symbol shape, name) belong on the layer itself, set by [qm_layer()] or the
#' `from_*()` wrappers. Properties of the *map* (boroughs, colour scale,
#' title, theme, output) belong here. `quickmap()` therefore has no per-layer
#' parallel-vector arguments: to customise one layer of several, customise
#' that layer — e.g.
#' `quickmap(list(from_csv("tubes.csv"), qm_layer(d, value_col = "pm25")), ...)`.
#'
#' @param layers One layer or a list of layers. Each element may be a file
#'   path (CSV or RData, resolved against `DATA_PATH`), a [qm_layer()], or a
#'   data.frame/sf object (converted via [qm_layer()]).
#' @param boroughs Character vector of borough names (or "All")
#' @param pollutant Pollutant to display. NULL (default) infers it from the
#'   first time-varying layer's value column.
#' @param display_times Time periods to display (NULL = all available)
#' @param colour_scale Name of a bundled colour scale (see inst/config/scales/)
#' @param output_file HTML file name written into `aq_maps/`
#' @param title Banner title
#' @param styling_type "html" (banner + legend + time control) or "none"
#' @param export_image NULL, TRUE, or c(width, height) for JPG export
#' @param marker_labels FALSE, TRUE (hover), "values_on", "labels", "labels_on"
#' @param vignette Dim the area outside the boundary
#' @param banner_colour Banner background colour
#' @param boundary_labels Show boundary name labels
#' @param autoplay Auto-advance the time control
#' @param play_speed Autoplay interval in ms
#' @param theme_file Path to a YAML theme file
#' @param data_symbols Optional character vector of marker symbols per layer
#'   (default: automatic assignment — solid symbols for time-varying layers,
#'   outline symbols for static layers)
#' @param wind Optional wind layer: a [from_worldmet()] object or a data
#'   frame with `date`/`ws`/`wd` columns. Rendered as an animated particle
#'   overlay (leaflet-velocity) that advances with the time control.
#'   Interactive HTML only — omitted from static JPG exports.
#' @return Invisible Leaflet map object; writes HTML (and optionally JPGs) to
#'   `aq_maps/`
#'
#' @examples
#' \dontrun{
#' # two lines: a usable map
#' library(quickmap)
#' quickmap("wandsworth_2017_2024.csv", boroughs = "Wandsworth")
#'
#' # several layers plus styling
#' quickmap(
#'   list("merton_dt_2018_2024.csv", "bl_sensors.Rdata", "schools_Merton.csv"),
#'   boroughs = "Merton",
#'   colour_scale = "who_no2",
#'   title = "Merton NO2",
#'   output_file = "merton_no2.html"
#' )
#'
#' # expert: hand-built atomic unit
#' quickmap(qm_layer(my_data, value_col = "pm25"), boroughs = "Richmond")
#' }
#' @family map
#' @export
quickmap <- function(
  layers,
  boroughs,
  pollutant = NULL,
  display_times = NULL,
  colour_scale = "who_no2",
  output_file = "quickmap.html",
  title = NULL,
  styling_type = "html",
  export_image = NULL,
  marker_labels = NULL,
  vignette = NULL,
  banner_colour = NULL,
  boundary_labels = NULL,
  autoplay = NULL,
  play_speed = NULL,
  theme_file = NULL,
  data_symbols = NULL,
  wind = NULL
) {
  if (inherits(layers, c("qm_layer", "data.frame")) || !is.list(layers)) {
    layers <- list(layers)
  }

  qm_layers <- lapply(layers, as_qm_layer,
                      pollutant = pollutant %||% "no2")

  # Infer pollutant from the first time-varying layer
  if (is.null(pollutant)) {
    for (l in qm_layers) {
      if (!is.null(qm_meta(l)$time_col)) {
        pollutant <- qm_meta(l)$value_col
        break
      }
    }
    pollutant <- pollutant %||% "no2"
  }

  legacy <- lapply(qm_layers, qm_to_legacy)
  ids <- vapply(qm_layers, function(l) qm_meta(l)$name, "")
  ids <- make.unique(ids, sep = "_")

  render_pollution_map(
    data_sources = legacy,
    data_ids = ids,
    data_symbols = data_symbols,
    output_file = output_file,
    export_image = export_image,
    boroughs = boroughs,
    pollutant = pollutant,
    display_times = display_times,
    title = title,
    vignette = vignette,
    colour_scale = colour_scale,
    styling_type = styling_type,
    marker_labels = marker_labels,
    banner_colour = banner_colour,
    boundary_labels = boundary_labels,
    autoplay = autoplay,
    play_speed = play_speed,
    theme_file = theme_file,
    wind = wind
  )
}

#' Create interactive and/or static pollution maps
#'
#' Compatibility wrapper around [quickmap()] — the historic QuickMap entry
#' point, retained with its existing signature. It converts `data_sources`
#' (file paths or sf objects) into [qm_layer()] atomic units and delegates to
#' [quickmap()]. New code should call [quickmap()] directly.
#'
#' @param data_sources List of data inputs: CSV/RData file paths or sf objects
#' @param data_ids Optional layer IDs (NULL auto-generates from filenames)
#' @param data_symbols Optional marker symbols per layer
#' @param data_dynamic Optional logical vector forcing temporal (TRUE) or
#'   static (FALSE) handling per layer (NULL = auto-detect)
#' @param output_file HTML file name written into `aq_maps/`
#' @param export_image NULL, TRUE, or c(width, height) for JPG export
#' @param boroughs Character vector of borough names (or "All")
#' @param pollutant Pollutant to display (e.g. "no2", "pm25")
#' @param display_times Time periods to display (NULL = all available)
#' @param title Banner title
#' @param vignette Dim the area outside the boundary
#' @param colour_scale Name of a bundled colour scale
#' @param styling_type "html" or "none"
#' @param marker_labels FALSE, TRUE (hover), "values_on", "labels", "labels_on"
#' @param banner_colour Banner background colour
#' @param boundary_labels Show boundary name labels
#' @param autoplay Auto-advance the time control
#' @param play_speed Autoplay interval in ms
#' @param theme_file Path to a YAML theme file
#' @param wind Optional wind layer (see [quickmap()])
#' @return Invisible Leaflet map object; writes HTML (and optionally JPGs) to
#'   `aq_maps/`
#' @family map
#' @export
create_pollution_map <- function(
  data_sources = NULL,
  data_ids = NULL,
  data_symbols = NULL,
  data_dynamic = NULL,
  output_file = "pollution_map.html",
  export_image = NULL,
  boroughs,
  pollutant = "no2",
  display_times = NULL,
  title = NULL,
  vignette = NULL,
  colour_scale = "who_no2",
  styling_type = "html",
  marker_labels = NULL,
  banner_colour = NULL,
  boundary_labels = NULL,
  autoplay = NULL,
  play_speed = NULL,
  theme_file = NULL,
  wind = NULL
) {
  qm_layers <- lapply(seq_along(data_sources), function(i) {
    layer <- as_qm_layer(
      data_sources[[i]],
      pollutant = pollutant,
      temporal = if (!is.null(data_dynamic)) data_dynamic[[i]] else NULL
    )
    if (!is.null(data_ids)) attr(layer, "qm")$name <- data_ids[i]
    layer
  })

  quickmap(
    layers = qm_layers,
    boroughs = boroughs,
    pollutant = pollutant,
    display_times = display_times,
    colour_scale = colour_scale,
    output_file = output_file,
    title = title,
    styling_type = styling_type,
    export_image = export_image,
    marker_labels = marker_labels,
    vignette = vignette,
    banner_colour = banner_colour,
    boundary_labels = boundary_labels,
    autoplay = autoplay,
    play_speed = play_speed,
    theme_file = theme_file,
    data_symbols = data_symbols,
    wind = wind
  )
}

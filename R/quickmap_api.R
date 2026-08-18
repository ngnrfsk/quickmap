# quickmap() public API (roadmap item 4)
# quickmap() is the core entry point consuming qm_layer atomic units;
# create_pollution_map() is a thin compatibility wrapper over it.

#' Downgrade a qm_layer to the column names the render pipeline consumes
#'
#' The renderer predates the `qm_layer` contract and still reads `year_str`,
#' `siteCode`, `Longitude` and `Latitude`. This adds those names alongside the
#' canonical ones rather than replacing them, so nothing is lost and the whole
#' function disappears once the renderer adopts the contract directly.
#'
#' @param layer A [qm_layer()] object
#' @return An sf data.frame with the renderer's column names added
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

#' Normalise one element of `layers` to a qm_layer
#'
#' `quickmap()` accepts a mixture of file paths, data frames and ready-made
#' layers so that a beginner never has to construct anything; this is where
#' that mixture becomes one type. A file path is routed by its extension.
#'
#' @param x A [qm_layer()], a CSV/RData file path, or a data.frame/sf object
#' @param pollutant Pollutant name, passed to the file readers
#' @param temporal Optional override of the time-varying guess for CSVs
#' @return A [qm_layer()]
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
#' @param boroughs Character vector of borough names (or "All"). NULL
#'   (default) draws no boundary and fits the map to the data.
#' @param pollutant Pollutant to display. NULL (default) infers it from the
#'   first time-varying layer's value column.
#' @param display_times Time periods to display (NULL = all available)
#' @param colour_scale Name of a bundled colour scale (see inst/config/scales/)
#' @param output_file Required. Where to write the map: a bare name goes in
#'   the working directory, a path goes where it says, creating the directory.
#' @param output_dir Directory prepended to `output_file`, and to any JPGs.
#'   Default: the `quickmap.output_dir` option, else NULL.
#' @param title Banner title
#' @param styling_type "html" (banner + legend + time control) or "none"
#' @param export_image NULL, TRUE, or c(width, height) for JPG export
#' @param symbol_labels FALSE, TRUE (hover), "values_on", "labels", "labels_on"
#' @param vignette Dim the area outside the boundary
#' @param banner_colour Banner background colour
#' @param boundary_labels Show boundary name labels
#' @param autoplay Auto-advance the time control
#' @param play_speed Autoplay interval in ms. NULL takes the theme's value,
#'   and failing that a pace set by the number of time steps
#' @param theme_file Path to a YAML theme file
#' @param data_symbols Optional character vector of marker symbols per layer.
#'   Overrides the shapes carried by the layers themselves
#'   (`qm_layer(shape=)` and the `from_*()` conventions: tubes circle,
#'   sensors diamond, schools cross). Layers with no shape set get an
#'   automatic assignment — solid symbols for time-varying layers, outline
#'   symbols for static layers
#' @param wind Optional wind layer: a [from_worldmet()] object or a data
#'   frame with `date`/`ws`/`wd` columns. Rendered as an animated particle
#'   overlay (leaflet-velocity) that advances with the time control.
#'   Interactive HTML only — omitted from static JPG exports.
#' @param ... Accepts the old argument name `marker_labels`, with a warning.
#'   Any other name is an error.
#' @return The saved file is the product; the Leaflet object comes back
#'   invisibly as a byproduct. Writes `output_file`, and JPGs when
#'   `export_image` is set.
#'
#' @examples
#' \dontrun{
#' # two arguments: a usable map
#' library(quickmap)
#' quickmap("wandsworth_2017_2024.csv", boroughs = "Wandsworth",
#'          output_file = "wandsworth.html")
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
#' quickmap(qm_layer(my_data, value_col = "pm25"), boroughs = "Richmond",
#'          output_file = "richmond_pm25.html")
#' }
#' @family map
#' @export
quickmap <- function(
  layers,
  boroughs = NULL,
  pollutant = NULL,
  display_times = NULL,
  colour_scale = "who_no2",
  output_file,
  output_dir = getOption("quickmap.output_dir", NULL),
  title = NULL,
  styling_type = "html",
  export_image = NULL,
  symbol_labels = NULL,
  vignette = NULL,
  banner_colour = NULL,
  boundary_labels = NULL,
  autoplay = NULL,
  play_speed = NULL,
  theme_file = NULL,
  data_symbols = NULL,
  wind = NULL,
  ...
) {
  symbol_labels <- absorb_legacy_args(symbol_labels, ...)
  # A single layer may be passed unwrapped — quickmap("data.csv") is the
  # two-line call the package is built around. Note the data.frame test comes
  # first: a data.frame is also a list, and would otherwise be split into
  # one "layer" per column.
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
  # Layer names become Leaflet group names, which must be distinct; two files
  # of the same name in different folders would otherwise collide
  ids <- vapply(qm_layers, function(l) qm_meta(l)$name, "")
  ids <- make.unique(ids, sep = "_")

  # Per-layer shape metadata (item 9): honour qm_layer(shape=) unless the
  # map-level data_symbols override is given. Shapes are stored
  # renderer-canonical by qm_normalise_shape(); NA entries (layers with no
  # explicit shape) fall back to the renderer's auto-cycle.
  if (is.null(data_symbols)) {
    meta_shapes <- vapply(qm_layers, function(l) {
      qm_meta(l)$shape %||% NA_character_
    }, "")
    if (any(!is.na(meta_shapes))) data_symbols <- meta_shapes
  }

  render_pollution_map(
    data_sources = legacy,
    data_ids = ids,
    data_symbols = data_symbols,
    output_file = output_file,
    output_dir = output_dir,
    export_image = export_image,
    boroughs = boroughs,
    pollutant = pollutant,
    display_times = display_times,
    title = title,
    vignette = vignette,
    colour_scale = colour_scale,
    styling_type = styling_type,
    symbol_labels = symbol_labels,
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
#' @param output_file Required. Where to write the map: a bare name goes in
#'   the working directory, a path goes where it says, creating the directory.
#' @param output_dir Directory prepended to `output_file`, and to any JPGs.
#'   Default: the `quickmap.output_dir` option, else NULL.
#' @param export_image NULL, TRUE, or c(width, height) for JPG export
#' @param boroughs Character vector of borough names (or "All"). NULL
#'   (default) draws no boundary and fits the map to the data.
#' @param pollutant Pollutant to display (e.g. "no2", "pm25")
#' @param display_times Time periods to display (NULL = all available)
#' @param title Banner title
#' @param vignette Dim the area outside the boundary
#' @param colour_scale Name of a bundled colour scale
#' @param styling_type "html" or "none"
#' @param symbol_labels FALSE, TRUE (hover), "values_on", "labels", "labels_on"
#' @param banner_colour Banner background colour
#' @param boundary_labels Show boundary name labels
#' @param autoplay Auto-advance the time control
#' @param play_speed Autoplay interval in ms. NULL takes the theme's value,
#'   and failing that a pace set by the number of time steps
#' @param theme_file Path to a YAML theme file
#' @param wind Optional wind layer (see [quickmap()])
#' @param ... Accepts the old argument name `marker_labels`, with a warning.
#'   Any other name is an error.
#' @return The saved file is the product; the Leaflet object comes back
#'   invisibly as a byproduct. Writes `output_file`, and JPGs when
#'   `export_image` is set.
#' @family map
#' @export
create_pollution_map <- function(
  data_sources = NULL,
  data_ids = NULL,
  data_symbols = NULL,
  data_dynamic = NULL,
  output_file,
  output_dir = getOption("quickmap.output_dir", NULL),
  export_image = NULL,
  boroughs = NULL,
  pollutant = "no2",
  display_times = NULL,
  title = NULL,
  vignette = NULL,
  colour_scale = "who_no2",
  styling_type = "html",
  symbol_labels = NULL,
  banner_colour = NULL,
  boundary_labels = NULL,
  autoplay = NULL,
  play_speed = NULL,
  theme_file = NULL,
  wind = NULL,
  ...
) {
  symbol_labels <- absorb_legacy_args(symbol_labels, ...)
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
    output_dir = output_dir,
    title = title,
    styling_type = styling_type,
    export_image = export_image,
    symbol_labels = symbol_labels,
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

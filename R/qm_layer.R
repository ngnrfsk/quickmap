# qm_layer - the atomic data unit (roadmap item 3)
# Design: dev/260706_atomic_unit_recommendation.md (rev 3, approved 2026-07-06)
#
# A qm_layer is an sf object in long format (one row per marker per time step)
# with layer metadata as attributes. The from_* wrappers normalise every input
# format into it; quickmap() (roadmap item 4) will consume lists of them.

# Legacy column names accepted and normalised at construction. One documented
# constant, not scattered ifs.
QM_ALIASES <- list(
  code = c("siteCode", "site_code"),
  time_label = c("year_str"),
  lat = c("Latitude", "latitude"),
  lon = c("Longitude", "longitude")
)

# Pollutant columns recognised when value_col is not given
QM_KNOWN_POLLUTANTS <- c("no2", "pm25", "pm10", "nox", "no", "o3", "so2", "co")

# Time-column name gate: these names earn a parse attempt (case-insensitive)
QM_TIME_NAMES <- c("date", "time", "datetime", "time_label", "year_str")

#' Parse a vector of time labels against the fixed grammar
#'
#' Grammar, most-specific first: `YYYY-MM-DD HH:MM(:SS)` (T separator
#' accepted), `YYYY-MM-DD`, `YYYY-MM`, `YYYY`. All non-NA values must match a
#' single format.
#'
#' @param x Character (or numeric year) vector
#' @return list(sort = POSIXct, resolution = chr) or NULL if no format matches
#' @keywords internal
qm_parse_time <- function(x) {
  x <- as.character(x)
  vals <- unique(x[!is.na(x) & x != ""])
  if (length(vals) == 0) return(NULL)
  vals_norm <- sub("T", " ", vals, fixed = TRUE)

  grammar <- list(
    list(rx = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$",
         fmt = "%Y-%m-%d %H:%M:%S", res = "minute"),
    list(rx = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}$",
         fmt = "%Y-%m-%d %H:%M", res = "minute"),
    list(rx = "^\\d{4}-\\d{2}-\\d{2}$", fmt = "%Y-%m-%d", res = "day"),
    list(rx = "^\\d{4}-\\d{2}$", fmt = "%Y-%m", res = "month",
         pre = function(v) paste0(v, "-01")),
    list(rx = "^\\d{4}$", fmt = "%Y", res = "year",
         pre = function(v) paste0(v, "-01-01"))
  )

  for (g in grammar) {
    if (all(grepl(g$rx, vals_norm))) {
      parse_vals <- if (is.null(g$pre)) vals_norm else g$pre(vals_norm)
      fmt <- if (g$fmt %in% c("%Y-%m", "%Y")) "%Y-%m-%d" else g$fmt
      parsed <- as.POSIXct(parse_vals, format = fmt, tz = "UTC")
      if (anyNA(parsed)) return(NULL) # e.g. month 13 — regex passed, date invalid

      resolution <- g$res
      if (g$res == "minute") {
        mins <- as.integer(format(parsed, "%M"))
        if (all(mins == 0)) resolution <- "hour"
      }

      x_norm <- sub("T", " ", x, fixed = TRUE)
      all_parse_vals <- if (is.null(g$pre)) x_norm else g$pre(x_norm)
      sort_key <- as.POSIXct(all_parse_vals, format = fmt, tz = "UTC")
      return(list(sort = sort_key, resolution = resolution))
    }
  }
  NULL
}

#' Find the time column of a data.frame
#'
#' Inference contract (design doc rev 2/3): explicit `time_col` override, then
#' column class (Date/POSIXct), then the name gate + parse grammar. Arbitrary
#' columns are never content-scanned. A gate-named column that fails the
#' grammar is a loud error, not a silent fall-through.
#'
#' @return list(col, sort, resolution) or NULL (static layer)
#' @keywords internal
qm_find_time_col <- function(data, time_col = NULL) {
  if (!is.null(time_col)) {
    if (!time_col %in% names(data)) {
      stop("time_col '", time_col, "' is not a column of the data. Columns: ",
           paste(names(data), collapse = ", "), call. = FALSE)
    }
    x <- data[[time_col]]
    if (inherits(x, c("Date", "POSIXct"))) {
      parsed <- qm_parse_time(format(x, if (inherits(x, "Date")) "%Y-%m-%d" else "%Y-%m-%d %H:%M:%S"))
      return(list(col = time_col, sort = parsed$sort, resolution = parsed$resolution))
    }
    parsed <- qm_parse_time(x)
    if (is.null(parsed)) {
      # explicit override with a non-date ordering (e.g. diurnal hours):
      # honour the user's ordering; sort by first appearance of sorted labels
      labels <- as.character(x)
      return(list(col = time_col, sort = NULL, resolution = NULL))
    }
    return(list(col = time_col, sort = parsed$sort, resolution = parsed$resolution))
  }

  # 1. class wins, whatever the name
  for (nm in setdiff(names(data), attr(data, "sf_column"))) {
    if (inherits(data[[nm]], c("Date", "POSIXct"))) {
      fmt <- if (inherits(data[[nm]], "Date")) "%Y-%m-%d" else "%Y-%m-%d %H:%M:%S"
      parsed <- qm_parse_time(format(data[[nm]], fmt))
      return(list(col = nm, sort = parsed$sort, resolution = parsed$resolution))
    }
  }

  # 2. name gate earns a parse attempt
  gate <- names(data)[tolower(names(data)) %in% QM_TIME_NAMES]
  for (nm in gate) {
    parsed <- qm_parse_time(data[[nm]])
    if (is.null(parsed)) {
      bad <- data[[nm]][!is.na(data[[nm]])][1]
      stop("Column '", nm, "' looks like a time column but could not be ",
           "parsed (first value: '", bad, "'). Accepted formats: YYYY, ",
           "YYYY-MM, YYYY-MM-DD, YYYY-MM-DD HH:MM(:SS).", call. = FALSE)
    }
    return(list(col = nm, sort = parsed$sort, resolution = parsed$resolution))
  }

  NULL # static layer
}

#' Create a qm_layer — the QuickMap atomic data unit
#'
#' A `qm_layer` is an sf object in long format (one row per marker per time
#' step) carrying its layer metadata as attributes, so nothing is re-inferred
#' downstream. Most users never call this directly: [from_csv()],
#' [from_rdata()] and [from_openair()] build layers from files, and (from
#' roadmap item 4) `quickmap()` accepts file paths directly. Call `qm_layer()`
#' to map data you assembled yourself.
#'
#' Canonical columns: `code` (stable marker key), `time_label` (display text
#' per time step, absent for static layers), `time_sort` (POSIXct sort key),
#' the value column named by `value_col`, `lat`, `lon`, `geometry`. Legacy
#' names (`siteCode`, `year_str`, `Latitude`/`Longitude`) are accepted and
#' normalised.
#'
#' @param data An sf object, or a data.frame with `lat`/`lon` columns
#' @param value_col Name of the column holding the plotted value. If NULL,
#'   inferred: a known pollutant column (no2, pm25, ...), else the single
#'   numeric non-contract column.
#' @param time_col Name of the time column. If NULL, inferred: a Date/POSIXct
#'   column, else a column named date/time/datetime/year_str that parses under
#'   the grammar. Pass explicitly for non-date orderings (e.g. diurnal hours).
#' @param label_col Name of the column supplying marker labels (NULL = none;
#'   inferred from `Label` or `School` columns when present)
#' @param shape Marker symbol: "circle" (default), "diamond" or "cross"
#' @param name Human-visible layer name (legends, controls, errors)
#' @return The data as a `qm_layer` (still an sf data.frame)
#' @family atomic unit
#' @export
qm_layer <- function(
  data,
  value_col = NULL,
  time_col = NULL,
  label_col = NULL,
  shape = c("circle", "diamond", "cross"),
  name = "layer"
) {
  shape <- match.arg(shape)
  if (!is.data.frame(data) || nrow(data) == 0) {
    stop("data must be a non-empty data.frame or sf object", call. = FALSE)
  }

  # Normalise legacy names to canonical (alias rule, design doc rev 3)
  for (canonical in names(QM_ALIASES)) {
    if (!canonical %in% names(data)) {
      hit <- intersect(QM_ALIASES[[canonical]], names(data))
      if (length(hit) > 0) names(data)[names(data) == hit[1]] <- canonical
    }
  }
  # Contract carries each fact once: drop leftover alias duplicates
  data <- data[, !names(data) %in% unlist(QM_ALIASES), drop = FALSE]

  if (!"code" %in% names(data)) {
    stop("Missing required column 'code' (or legacy 'siteCode'): the stable ",
         "identifier linking a marker across time steps.", call. = FALSE)
  }

  # Geometry: accept sf as-is, else build from lat/lon
  if (!inherits(data, "sf")) {
    if (!all(c("lat", "lon") %in% names(data))) {
      stop("data needs either an sf geometry or 'lat'/'lon' columns",
           call. = FALSE)
    }
    data <- sf::st_as_sf(data, coords = c("lon", "lat"), crs = 4326,
                         remove = FALSE)
  }
  if (!all(c("lat", "lon") %in% names(data))) {
    coords <- sf::st_coordinates(data)
    data$lon <- as.numeric(coords[, 1])
    data$lat <- as.numeric(coords[, 2])
  }

  # Label column: explicit, else duck-typed from user CSV conventions
  if (is.null(label_col)) {
    label_col <- intersect(c("Label", "School"), names(data))[1]
    if (is.na(label_col)) label_col <- NULL
  } else if (!label_col %in% names(data)) {
    stop("label_col '", label_col, "' is not a column of the data",
         call. = FALSE)
  }

  # Time column per the inference contract
  time_info <- qm_find_time_col(data, time_col)
  resolution <- NULL
  if (!is.null(time_info)) {
    if (time_info$col != "time_label") {
      data$time_label <- as.character(data[[time_info$col]])
      if (time_info$col %in% QM_TIME_NAMES ||
            inherits(data[[time_info$col]], c("Date", "POSIXct"))) {
        # normalise datetime classes to the label the roller menu shows
        if (inherits(data[[time_info$col]], c("Date", "POSIXct")) &&
              !is.null(time_info$resolution)) {
          fmt <- switch(time_info$resolution,
            year = "%Y", month = "%Y-%m", day = "%Y-%m-%d",
            hour = "%Y-%m-%d %H:%M", minute = "%Y-%m-%d %H:%M"
          )
          data$time_label <- format(data[[time_info$col]], fmt)
        }
        if (time_info$col != "time_label") data[[time_info$col]] <- NULL
      }
    }
    if (!is.null(time_info$sort)) data$time_sort <- time_info$sort
    resolution <- time_info$resolution
  }

  # Value column: explicit, else known pollutant, else the single numeric
  # non-contract column
  contract_cols <- c("code", "time_label", "time_sort", "lat", "lon",
                     attr(data, "sf_column"), label_col)
  if (is.null(value_col)) {
    value_col <- intersect(QM_KNOWN_POLLUTANTS, tolower(names(data)))[1]
    if (!is.na(value_col)) {
      value_col <- names(data)[tolower(names(data)) == value_col][1]
    } else {
      candidates <- setdiff(names(data), contract_cols)
      candidates <- candidates[vapply(candidates, function(cl)
        is.numeric(data[[cl]]) || is.character(data[[cl]]) ||
          is.factor(data[[cl]]), TRUE)]
      if (length(candidates) != 1) {
        stop("Cannot infer value_col. Specify it explicitly. Candidate ",
             "columns: ", paste(candidates, collapse = ", "), call. = FALSE)
      }
      value_col <- candidates
    }
  } else if (!value_col %in% names(data)) {
    stop("value_col '", value_col, "' not found in data. Available columns: ",
         paste(names(data), collapse = ", "), call. = FALSE)
  }

  structure(
    data,
    class = c("qm_layer", class(data)),
    qm = list(
      value_col = value_col,
      time_col = if (!is.null(time_info)) "time_label" else NULL,
      label_col = label_col,
      shape = shape,
      name = name,
      resolution = resolution
    )
  )
}

#' Layer metadata of a qm_layer
#' @param x A qm_layer
#' @return Named list: value_col, time_col, label_col, shape, name, resolution
#' @family atomic unit
#' @export
qm_meta <- function(x) {
  if (!inherits(x, "qm_layer")) stop("not a qm_layer", call. = FALSE)
  attr(x, "qm")
}

#' @export
print.qm_layer <- function(x, ...) {
  m <- qm_meta(x)
  n_steps <- if (is.null(m$time_col)) 0L else length(unique(x$time_label))
  temporal <- n_steps > 1
  cat(sprintf(
    "qm_layer '%s': %d %s%s of %s (%s)\n",
    m$name,
    length(unique(x$code)),
    "sites",
    if (temporal) sprintf(" x %d time steps [%s]", n_steps,
                          m$resolution %||% "custom order") else " (static)",
    m$value_col,
    m$shape
  ))
  NextMethod()
}

# ---- wrappers: one per input format --------------------------------------

#' Build a qm_layer from a CSV file
#'
#' Diffusion-tube CSVs (`Easting`/`Northing` + year columns, British National
#' Grid) are pivoted to long format; school/contextual CSVs (a `School`
#' column, no year columns) become static cross layers. Any filename works —
#' content decides (duck typing).
#'
#' @param file Path to the CSV (relative paths resolve against `DATA_PATH`)
#' @param pollutant Name for the value column of temporal data (default "no2")
#' @param name Layer name (default: the file name without extension)
#' @param temporal Force temporal (TRUE) or static (FALSE) handling; NULL
#'   (default) auto-detects: more than one year column means temporal
#' @return A [qm_layer()]
#' @family atomic unit
#' @export
from_csv <- function(file, pollutant = "no2", name = NULL, temporal = NULL) {
  name <- name %||% tools::file_path_sans_ext(basename(file))
  imported <- import_csv_data(file)
  data <- imported$data

  is_school <- "School" %in% names(data)
  year_cols <- names(data)[grepl("^\\d{4}$", names(data))]
  temporal <- temporal %||% (!is_school && length(year_cols) > 1)

  if (temporal && length(year_cols) > 0) {
    data[year_cols] <- lapply(data[year_cols],
                              function(x) as.numeric(as.character(x)))
    data <- tidyr::pivot_longer(
      data, cols = dplyr::all_of(year_cols),
      names_to = "time_label", values_to = pollutant
    )
    data <- data[!is.na(data[[pollutant]]), ]
    sf_data <- transform_to_wgs84(data)
    sf_data$code <- if ("Label" %in% names(sf_data)) sf_data$Label else
      paste0("site_", as.integer(factor(paste(sf_data$Longitude, sf_data$Latitude))))
    return(qm_layer(sf_data, value_col = pollutant, shape = "circle",
                    name = name))
  }

  # static/contextual layer (schools etc.)
  sf_data <- transform_to_wgs84(data)
  sf_data$code <- if ("School" %in% names(sf_data)) sf_data$School else
    paste0("site_", seq_len(nrow(sf_data)))
  qm_layer(
    sf_data,
    value_col = if ("Level" %in% names(sf_data)) "Level" else NULL,
    shape = if (is_school) "cross" else "circle",
    name = name
  )
}

#' Build a qm_layer from an RData file
#'
#' Duck-typed loading (explicit object name, then largest compatible
#' data.frame; see [load_rdata_file()]), then normalisation to the atomic
#' unit. Sensor-network data renders as diamonds by convention.
#'
#' @param file Path to the RData file (relative paths resolve against
#'   `DATA_PATH`)
#' @param pollutant Pollutant column to plot (e.g. "no2", "pm25")
#' @param name Layer name (default: the file name without extension)
#' @param data_object_name Optional explicit object name inside the file
#' @return A [qm_layer()]
#' @family atomic unit
#' @export
from_rdata <- function(file, pollutant, name = NULL, data_object_name = NULL) {
  name <- name %||% tools::file_path_sans_ext(basename(file))
  sf_data <- load_rdata_file(file, pollutant, data_object_name)
  qm_layer(sf_data, value_col = pollutant, shape = "diamond", name = name)
}

#' Build a qm_layer from an OpenAir tibble
#'
#' Wraps [convert_openair_to_spatial()]: accepts the output of
#' `openair::importUKAQ()` and friends (long format with a `date` column),
#' aggregates to `avg.time`, fetches coordinates from network metadata when
#' absent, and returns the atomic unit.
#'
#' @param data OpenAir-format data.frame (`date`, site code, pollutant columns)
#' @param pollutant Pollutant column to plot
#' @param source Network source for metadata lookup when coordinates are
#'   missing ("aurn", "kcl", ...)
#' @param avg.time Aggregation period: "year", "month", "day" or "hour"
#' @param name Layer name
#' @return A [qm_layer()]
#' @family atomic unit
#' @export
from_openair <- function(data, pollutant, source = NULL, avg.time = "year",
                         name = "openair") {
  sf_data <- convert_openair_to_spatial(
    data, source = source, pollutant = pollutant, avg.time = avg.time
  )
  qm_layer(sf_data, value_col = pollutant, shape = "diamond", name = name)
}

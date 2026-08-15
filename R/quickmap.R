# quickmap - Air Quality Mapping for R
#
# The rendering engine. The public entry points live in quickmap_api.R
# (quickmap(), create_pollution_map()); the layer type lives in qm_layer.R;
# the wind overlay in wind.R.
#
# Sections of this file, in order:
#   1. Small helpers and the {{placeholder}} template system
#   2. OpenAir data: metadata lookup and conversion to spatial form
#   3. Data loading: CSV, RData, boundaries, coordinate transformation
#   4. Colour scales and themes
#   5. Legend and banner: HTML and CSS generation
#   6. Saving and static export
#   7. Time control and the lazy embedded payload (roadmap item 6)
#   8. HTML post-processing: injecting banner, legend and controls
#   9. Symbols and layers
#  10. Map assembly: boundaries, viewport, base map
#  11. Orchestration: render_pollution_map()
#
# The overall flow is the pipeline described in CLAUDE.md:
#   load data -> configure layers -> process generically -> make icons -> render
#
# Version history is in CLAUDE.md; archived copies of this file are in
# versions/.

# NULL coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Constants
MISSING_DATA_THRESHOLD <- 20 # Percent - sites with more missing data are filtered
IMAGE_X <- 1200
IMAGE_Y <- 1200
IMAGE_AREA <- IMAGE_X * IMAGE_Y

# Helper functions for DRY code patterns

#' Locate a directory inside the installed package
#'
#' Falls back to the source-tree path (`inst/<subdir>`) so the code also runs
#' from a working copy that has not been installed.
#'
#' @param subdir Sub-directory of `inst/`, e.g. "controls" or "themes"
#' @return Path to the directory
#' @keywords internal
get_package_dir <- function(subdir) {
  dir <- system.file(subdir, package = "quickmap")
  if (dir == "") dir <- file.path("inst", subdir)
  return(dir)
}

#' Read a CSS/JS/HTML template file into a single string
#'
#' @param filepath Path to the template file
#' @return The file contents as one newline-joined string
#' @keywords internal
read_template_file <- function(filepath) {
  paste(readLines(filepath, warn = FALSE), collapse = "\n")
}

#' Substitute {{placeholder}} values into a template
#'
#' The `{{name}}` pattern is the project's template convention (see CLAUDE.md,
#' "Named Placeholder Pattern"). A `{{name}}` key that is not present in the
#' template is a hard error rather than a silent no-op: silently skipping it
#' would ship the literal text "{{name}}" into the user's HTML.
#'
#' @param template Template string from [read_template_file()]
#' @param replacements Named list; names are the placeholders (usually
#'   `{{...}}`), values the text to insert
#' @return The template with all replacements applied
#' @keywords internal
apply_template_replacements <- function(template, replacements) {
  result <- template
  for (placeholder in names(replacements)) {
    # {{name}} placeholders are mandatory template anchors; a silent non-match
    # ships literal "{{name}}" text in the output HTML
    if (startsWith(placeholder, "{{") && !grepl(placeholder, result, fixed = TRUE)) {
      stop("Template placeholder not found: ", placeholder)
    }
    result <- gsub(
      placeholder,
      replacements[[placeholder]],
      result,
      fixed = TRUE
    )
  }
  return(result)
}

# == 2. OpenAir data ==========================================================

# OpenAir Metadata Cache System
# Session-level cache for site coordinates from importMeta()
# Used as fallback when data lacks coordinates (e.g., legacy importAURN/importKCL)
.openair_metadata_cache <- new.env(parent = emptyenv())

#' Get OpenAir site metadata with caching
#'
#' Fetches site metadata (coordinates, site_type) from OpenAir's importMeta()
#' function with session-level caching to avoid redundant API calls.
#'
#' @param source Character. Network source: "aurn", "kcl", "aqe", "saqn", "waqn", "ni"
#' @return data.frame with columns: source, site, code, latitude, longitude, site_type
#' @family openair
#' @export
#' @examples
#' \dontrun{
#' # First call fetches from API
#' meta <- get_openair_metadata("aurn")
#' # Second call uses cache
#' meta <- get_openair_metadata("aurn")
#' }
get_openair_metadata <- function(source) {
  if (!requireNamespace("openair", quietly = TRUE)) {
    stop(
      "Package 'openair' is required for this function. ",
      "Install with: install.packages('openair')",
      call. = FALSE
    )
  }

  # Check cache first
  if (exists(source, envir = .openair_metadata_cache)) {
    message("Using cached metadata for source: ", source)
    return(get(source, envir = .openair_metadata_cache))
  }

  # Fetch from OpenAir API
  if (!requireNamespace("openair", quietly = TRUE)) {
    stop("Package 'openair' required. Install with: install.packages('openair')")
  }
  message("Fetching metadata for source: ", source)
  tryCatch(
    {
      metadata <- openair::importMeta(source = source)

      if (is.null(metadata) || nrow(metadata) == 0) {
        stop(
          "No metadata returned for source '",
          source,
          "'. ",
          "Check that the source name is valid.",
          call. = FALSE
        )
      }

      # Cache the result
      assign(source, metadata, envir = .openair_metadata_cache)

      message(
        "Cached metadata for ",
        nrow(metadata),
        " sites from source: ",
        source
      )

      return(metadata)
    },
    error = function(e) {
      stop(
        "Failed to fetch metadata for source '",
        source,
        "': ",
        e$message,
        call. = FALSE
      )
    }
  )
}

#' Clear OpenAir metadata cache
#'
#' Removes all cached metadata, forcing fresh API calls on next request.
#' Useful if metadata needs to be refreshed during a session.
#'
#' @param source Character (optional). Specific source to clear, or NULL to clear all
#' @return Invisible NULL
#' @family openair
#' @export
#' @examples
#' \dontrun{
#' # Clear specific source
#' clear_openair_metadata_cache("aurn")
#' # Clear all cached metadata
#' clear_openair_metadata_cache()
#' }
clear_openair_metadata_cache <- function(source = NULL) {
  if (is.null(source)) {
    # Clear entire cache
    rm(
      list = ls(envir = .openair_metadata_cache),
      envir = .openair_metadata_cache
    )
    message("Cleared all OpenAir metadata cache")
  } else {
    # Clear specific source
    if (exists(source, envir = .openair_metadata_cache)) {
      rm(list = source, envir = .openair_metadata_cache)
      message("Cleared metadata cache for source: ", source)
    } else {
      message("No cached metadata for source: ", source)
    }
  }
  invisible(NULL)
}

#' Convert OpenAir data to spatial sf object
#'
#' Transforms OpenAir data.frames (from importUKAQ, importAURN, importKCL, etc.)
#' into sf spatial objects compatible with quickmap's layer system.
#'
#' @param data data.frame. OpenAir data with date, site identifier, and pollutant columns.
#'   Site identifier: 'code' (OpenAir) or 'siteCode' (quickmap) accepted.
#'   Coordinates: 'latitude'/'longitude' or 'lat'/'lon' accepted.
#'   Preferably from importUKAQ(meta=TRUE) which includes coordinates.
#' @param source Character (optional). Network source ("aurn", "kcl", etc.).
#'   Required only if data lacks latitude/longitude columns.
#' @param pollutant Character. Pollutant column name (e.g., "no2", "pm2.5").
#' @param avg.time Character. Temporal aggregation period: "year" (default),
#'   "month", "day", "hour". Passed to dplyr grouping.
#' @param data_capture Numeric. Minimum fraction of a period's expected
#'   observations that must carry a value for its mean to exist; sparser
#'   site-periods yield NA instead of an average of whatever was measured.
#'   Expected counts come from the calendar and the data's own time step.
#'   Default 0.75; 0 reproduces the pre-v0.9.9.12 behaviour.
#' @return sf object with columns: siteCode, year, year_str, pollutant value,
#'   lat, lon, Longitude, Latitude, geometry. Compatible with process_oa_data() output.
#' @family openair
#' @export
#' @examples
#' \dontrun{
#' # With importUKAQ (coordinates included)
#' data <- importUKAQ(site = "my1", year = 2023, source = "aurn", meta = TRUE)
#' sf_data <- convert_openair_to_spatial(data, pollutant = "no2")
#'
#' # With importAURN (needs source for metadata)
#' data <- importAURN(site = "my1", year = 2023)
#' sf_data <- convert_openair_to_spatial(data, source = "aurn", pollutant = "no2")
#' }
convert_openair_to_spatial <- function(
  data,
  source = NULL,
  pollutant,
  avg.time = "year",
  data_capture = 0.75
) {
  # -- Input checks: column names differ between OpenAir and quickmap, so
  # both spellings are accepted rather than made the user's problem ---------
  if (!is.data.frame(data) || nrow(data) == 0) {
    stop("data must be a non-empty data.frame", call. = FALSE)
  }

  if (!requireNamespace("openair", quietly = TRUE)) {
    stop(
      "Package 'openair' is required for this function. ",
      "Install with: install.packages('openair')",
      call. = FALSE
    )
  }

  # Check required columns
  if (!"date" %in% names(data)) {
    stop("Missing required column: date", call. = FALSE)
  }

  # Site identifier: OpenAir uses 'code', quickmap uses 'siteCode' - accept both
  if ("code" %in% names(data)) {
    data$siteCode <- data$code
  } else if (!"siteCode" %in% names(data)) {
    stop(
      "Missing site identifier column: need 'code' or 'siteCode'",
      call. = FALSE
    )
  }

  # Check pollutant exists
  if (!pollutant %in% names(data)) {
    stop(
      "Pollutant '",
      pollutant,
      "' not found in data. ",
      "Available columns: ",
      paste(names(data), collapse = ", "),
      call. = FALSE
    )
  }

  # Coordinates: OpenAir uses 'latitude'/'longitude', also accept 'lat'/'lon'
  if (all(c("latitude", "longitude") %in% names(data))) {
    has_coords <- TRUE
  } else if (all(c("lat", "lon") %in% names(data))) {
    data$latitude <- data$lat
    data$longitude <- data$lon
    has_coords <- TRUE
  } else {
    has_coords <- FALSE
  }

  # -- Coordinates: some OpenAir imports carry none, so they are looked up
  # from the network's site metadata by site code --------------------------
  if (!has_coords) {
    # Need to fetch metadata - requires code column for OpenAir lookup
    if (is.null(source)) {
      stop(
        "source parameter required when data lacks coordinates. ",
        "Either use importUKAQ(meta=TRUE) or provide source name.",
        call. = FALSE
      )
    }
    if (!"code" %in% names(data)) {
      stop(
        "Metadata lookup requires 'code' column matching OpenAir site codes. ",
        "Your data has 'siteCode' which may not match OpenAir metadata.",
        call. = FALSE
      )
    }

    message("Fetching coordinates from metadata (source: ", source, ")")
    metadata <- get_openair_metadata(source)

    # Join metadata to data
    data <- merge(
      data,
      metadata[, c("code", "latitude", "longitude")],
      by = "code",
      all.x = TRUE
    )

    # Check for sites without coordinates
    missing_coords <- is.na(data$latitude) | is.na(data$longitude)
    if (any(missing_coords)) {
      missing_codes <- unique(data$code[missing_coords])
      warning(
        "Sites without coordinates in metadata (filtered out): ",
        paste(head(missing_codes, 10), collapse = ", "),
        if (length(missing_codes) > 10)
          paste0(" (and ", length(missing_codes) - 10, " more)") else "",
        call. = FALSE
      )
      data <- data[!missing_coords, ]
    }

    if (nrow(data) == 0) {
      stop(
        "No data remaining after filtering sites without coordinates",
        call. = FALSE
      )
    }
  }

  # -- Aggregation to the requested resolution ------------------------------
  # `year_str` is the string the time control displays and the rest of the
  # pipeline groups by; its format is what distinguishes an annual map from a
  # monthly, daily or hourly one.
  # A mean exists only where at least `data_capture` of the period's expected
  # observations carry a value. Expected counts are calendar seconds divided
  # by the data's own median time step, so hours absent from the data
  # entirely count against capture, not just NA rows.
  steps <- diff(sort(unique(data$date)))
  units(steps) <- "secs"
  step_secs <- if (length(steps)) stats::median(as.numeric(steps)) else NA
  capped_mean <- function(values, period_secs) {
    if (!is.na(step_secs) && data_capture > 0 &&
          sum(!is.na(values)) / (period_secs / step_secs) < data_capture) {
      return(NA_real_)
    }
    mean(values, na.rm = TRUE)
  }
  year_secs <- function(year) {
    (365 + lubridate::leap_year(year)) * 86400
  }

  if (avg.time == "year") {
    # Annual aggregation
    data$year <- as.integer(format(data$date, "%Y"))
    data$year_str <- format(data$date, "%Y")

    aggregated <- data |>
      group_by(siteCode, year) |>
      summarise(
        !!sym(pollutant) := capped_mean(!!sym(pollutant),
                                        year_secs(year[1])),
        latitude = first(latitude),
        longitude = first(longitude),
        year_str = first(year_str),
        .groups = "drop"
      )
  } else if (avg.time %in% c("month", "day", "hour")) {
    # Sub-annual aggregation
    data$year <- as.integer(format(data$date, "%Y"))

    # Create year_str based on resolution
    data$year_str <- switch(
      avg.time,
      "month" = format(data$date, "%Y-%m"),
      "day" = format(data$date, "%Y-%m-%d"),
      "hour" = format(data$date, "%Y-%m-%d %H:00")
    )

    # Create period column for grouping
    data$period <- data$date
    data$period <- switch(
      avg.time,
      "month" = as.Date(format(data$date, "%Y-%m-01")),
      "day" = as.Date(data$date),
      "hour" = data$date
    )

    period_secs <- switch(
      avg.time,
      "month" = function(p) lubridate::days_in_month(p) * 86400,
      "day" = function(p) 86400,
      "hour" = function(p) 3600
    )
    aggregated <- data |>
      group_by(siteCode, period, year, year_str) |>
      summarise(
        !!sym(pollutant) := capped_mean(!!sym(pollutant),
                                        period_secs(period[1])),
        latitude = first(latitude),
        longitude = first(longitude),
        .groups = "drop"
      ) |>
      select(-period) # Remove temporary grouping column
  } else {
    stop(
      "Invalid avg.time: '",
      avg.time,
      "'. ",
      "Valid options: 'year', 'month', 'day', 'hour'",
      call. = FALSE
    )
  }

  # -- To sf, keeping plain coordinate columns too --------------------------
  # Four names for two numbers is redundant, but lat/lon and
  # Longitude/Latitude are both read elsewhere in the pipeline; unifying them
  # is an item-9 tidy-up, not a change to make in passing.
  aggregated$lat <- aggregated$latitude
  aggregated$lon <- aggregated$longitude

  # Convert to sf object
  sf_data <- st_as_sf(
    aggregated,
    coords = c("longitude", "latitude"),
    crs = 4326
  )

  # Extract coordinates for Longitude/Latitude columns (compatibility)
  coords <- st_coordinates(sf_data)
  sf_data$Longitude <- as.numeric(coords[, 1])
  sf_data$Latitude <- as.numeric(coords[, 2])

  message(
    "Converted ",
    nrow(sf_data),
    " site-",
    if (avg.time == "year") "years" else paste0(avg.time, "s"),
    " to sf object"
  )

  return(sf_data)
}

#' Check that OpenAir-format data has the columns the pipeline needs
#'
#' @param data data.frame in OpenAir long format
#' @param pollutant Pollutant column name, e.g. "no2"
#' @return TRUE invisibly; stops with the missing column names otherwise
#' @keywords internal
validate_oa_data <- function(data, pollutant) {
  required_cols <- c("siteCode", "year", pollutant, "lat", "lon")
  missing_cols <- setdiff(required_cols, names(data))

  if (length(missing_cols) > 0) {
    stop(
      "Missing required columns in OA data: ",
      paste(missing_cols, collapse = ", ")
    )
  }
  return(TRUE)
}

#' Aggregate OpenAir-format data to annual site means and convert to sf
#'
#' Drops site-years with more than `MISSING_DATA_THRESHOLD` percent missing
#' data (warning as it does so), averages the pollutant per site per year, and
#' returns spatial points carrying both the geometry and plain
#' `Longitude`/`Latitude` columns (the renderer uses the plain columns).
#'
#' @param data data.frame in OpenAir long format
#' @param pollutant Pollutant column name, e.g. "no2"
#' @return sf object with one row per site per year, plus `year_str`
#' @keywords internal
process_oa_data <- function(data, pollutant) {
  validate_oa_data(data, pollutant)

  # Future enhancement (see dev/FUTURE_ENHANCEMENTS.md #1): insufficient data markers
  missing_col <- paste0("missing_", pollutant)
  if (missing_col %in% names(data)) {
    n_before <- nrow(data)
    data <- data[
      is.na(data[[missing_col]]) |
        data[[missing_col]] <= MISSING_DATA_THRESHOLD,
    ]
    n_filtered <- n_before - nrow(data)
    if (n_filtered > 0) {
      warning(
        "Filtered out ",
        n_filtered,
        " site-years for ",
        pollutant,
        " (>",
        MISSING_DATA_THRESHOLD,
        "% missing data)",
        call. = FALSE
      )
    }
  }

  processed_data <- data |>
    group_by(siteCode, year) |>
    summarise(
      !!sym(pollutant) := mean(!!sym(pollutant), na.rm = TRUE),
      lat = first(lat),
      lon = first(lon),
      .groups = "drop"
    ) |>
    st_as_sf(coords = c("lon", "lat"), crs = 4326) |>
    mutate(year_str = as.character(year))

  coords <- st_coordinates(processed_data)
  processed_data$Longitude <- coords[, 1]
  processed_data$Latitude <- coords[, 2]

  return(processed_data)
}

# == 3. Data loading ==========================================================

#' Dispatch a data file to the loader for its type
#'
#' @param file_path Path to the file, or the literal "none" for no layer
#' @param file_type "csv" or "rdata"
#' @param required_cols Columns the CSV must contain (CSV only)
#' @param pollutant Pollutant name (RData only)
#' @return The loader's result, or NULL when `file_path` is "none"
#' @keywords internal
load_data_file <- function(
  file_path,
  file_type,
  required_cols = NULL,
  pollutant = NULL
) {
  if (file_path == "none") return(NULL)

  switch(
    file_type,
    "csv" = import_csv_data(file_path, required_cols),
    "rdata" = load_rdata_file(file_path, pollutant),
    stop("Unknown file type: ", file_type)
  )
}

#' Load an RData file and find the sensor data inside it by duck typing
#'
#' An RData file may hold several objects under any names, so the object to map
#' is identified by its columns rather than its name: either the object named in
#' `data_object_name`, or — failing that — the largest data.frame carrying
#' `siteCode`, the pollutant, `lat`, `lon` and one temporal column.
#'
#' The temporal column decides how the data is treated, in precedence order:
#' `year_str` means the data has already been through
#' [convert_openair_to_spatial()] and is converted straight to sf; a datetime
#' column (`date`/`date_time`/`time`/`datetime`/`timestamp`) is aggregated by
#' the resolution inferred from the median gap between timestamps; a bare `year`
#' column is the annual fallback.
#'
#' @param file_path Path to RData file (relative to DATA_PATH)
#' @param pollutant Pollutant name (e.g., "no2", "pm25")
#' @param data_object_name Optional: explicit object name in RData file
#' @return An sf object in long format with `year_str`, `Longitude` and
#'   `Latitude` columns
#' @keywords internal
load_rdata_file <- function(file_path, pollutant, data_object_name = NULL) {
  # Explicit param → duck typing (largest compatible data.frame)
  env <- new.env()
  load(
    file.path(Sys.getenv("DATA_PATH"), file_path),
    envir = env,
    verbose = TRUE
  )

  obj_names <- ls(envir = env)
  base_required_cols <- c("siteCode", pollutant, "lat", "lon")
  # Precedence: year_str (processed) → datetime columns → year (annual fallback)
  datetime_cols <- c("date", "date_time", "time", "datetime", "timestamp")
  temporal_cols <- c("year_str", datetime_cols, "year")

  # Helper: infer temporal resolution from datetime column
  infer_resolution <- function(dates) {
    if (length(dates) < 2) return("year")
    sorted_dates <- sort(unique(dates))
    if (length(sorted_dates) < 2) return("year")
    diffs <- as.numeric(diff(sorted_dates), units = "hours")
    median_diff <- median(diffs, na.rm = TRUE)
    if (median_diff <= 1) return("hour")
    if (median_diff <= 24) return("day")
    if (median_diff <= 744) return("month")
    return("year")
  }

  # Helper: validate and process object
  use_object <- function(obj, name) {
    if (!is.data.frame(obj)) {
      stop("Object '", name, "' is not a data.frame", call. = FALSE)
    }

    # Check base required columns
    if (!all(base_required_cols %in% names(obj))) {
      stop(
        "Object '",
        name,
        "' missing columns: ",
        paste(setdiff(base_required_cols, names(obj)), collapse = ", "),
        call. = FALSE
      )
    }

    # Check for at least one temporal column
    has_temporal <- any(temporal_cols %in% names(obj))
    if (!has_temporal) {
      stop(
        "Object '",
        name,
        "' missing temporal column. ",
        "Expected one of: ",
        paste(temporal_cols, collapse = ", "),
        call. = FALSE
      )
    }

    message("Using sensor data: ", name, " (", nrow(obj), " rows)")

    # Precedence: year_str → datetime → year
    if ("year_str" %in% names(obj)) {
      # Already processed - convert to sf directly
      sf_obj <- st_as_sf(obj, coords = c("lon", "lat"), crs = 4326)
      coords <- st_coordinates(sf_obj)
      sf_obj$Longitude <- coords[, 1]
      sf_obj$Latitude <- coords[, 2]
      return(sf_obj)
    }

    # Find first available datetime column
    datetime_col <- intersect(datetime_cols, names(obj))[1]
    if (!is.na(datetime_col)) {
      # Normalize to 'date' for convert_openair_to_spatial
      obj$date <- obj[[datetime_col]]
      resolution <- infer_resolution(obj$date)
      message(
        "Inferred temporal resolution from '",
        datetime_col,
        "': ",
        resolution
      )
      return(convert_openair_to_spatial(
        obj,
        pollutant = pollutant,
        avg.time = resolution
      ))
    }

    # Fallback: year column (annual resolution)
    obj$year_str <- as.character(obj$year)
    sf_obj <- st_as_sf(obj, coords = c("lon", "lat"), crs = 4326)
    coords <- st_coordinates(sf_obj)
    sf_obj$Longitude <- coords[, 1]
    sf_obj$Latitude <- coords[, 2]
    return(sf_obj)
  }

  # Explicit user choice (if data_object_name specified)
  if (!is.null(data_object_name)) {
    if (!exists(data_object_name, envir = env, inherits = FALSE)) {
      stop(
        "Object '",
        data_object_name,
        "' not found.\n",
        "Available: ",
        paste(obj_names, collapse = ", "),
        call. = FALSE
      )
    }
    return(use_object(get(data_object_name, envir = env), data_object_name))
  }

  # Duck typing: find largest compatible data.frame
  compatible <- list()
  for (obj_name in obj_names) {
    obj <- get(obj_name, envir = env, inherits = FALSE)
    if (
      is.data.frame(obj) &&
        all(base_required_cols %in% names(obj)) &&
        any(temporal_cols %in% names(obj))
    ) {
      compatible[[obj_name]] <- list(data = obj, nrow = nrow(obj))
    }
  }

  if (length(compatible) == 0) {
    stop(
      "No compatible sensor data in: ",
      basename(file_path),
      "\n",
      "Expected: data.frame with [",
      paste(base_required_cols, collapse = ", "),
      "] and one of [",
      paste(temporal_cols, collapse = ", "),
      "]\n",
      "Found: ",
      paste(obj_names, collapse = ", "),
      call. = FALSE
    )
  }

  sizes <- sapply(compatible, function(x) x$nrow)
  selected <- names(which.max(sizes))

  if (length(compatible) > 1) {
    message(
      "Found ",
      length(compatible),
      " compatible objects, using largest: ",
      selected
    )
  }

  return(use_object(compatible[[selected]]$data, selected))
}


#' Pivot wide year columns into long format
#'
#' Diffusion-tube CSVs hold one column per time period ("2017", "2018", ...).
#' This turns them into one row per site per period, which is the shape the rest
#' of the pipeline works in.
#'
#' @param data data.frame with one column per time period
#' @param time_pattern Regex identifying the time columns; the default matches a
#'   four-digit year
#' @param pollutant Name to give the value column
#' @return Long-format data.frame with a `year` date column
#' @keywords internal
get_temporal_data <- function(
  data,
  time_pattern = "\\d{4}",
  pollutant = "no2"
) {
  temporal_cols <- names(data)[grepl(time_pattern, names(data))]

  data |>
    pivot_longer(
      cols = all_of(temporal_cols),
      names_to = "time_col",
      values_to = pollutant
    ) |>
    dplyr::mutate(
      year_str = gsub("^.*(\\d{4}).*$", "\\1", time_col), # extract the year
      year = as_date(paste0(year_str, "-01-01")) # do rest with lubridate
    ) |>
    dplyr::select(-time_col, -year_str)
}

#' Get maximum data value across all measurement layers
#' @param measurement_layers Layer configuration from get_measurement_layers()
#' @param pollutant Pollutant name (for bl_nodes data)
#' @param spatial_data Spatial data list from load_spatial_data_sources()
#' @param display_times Character vector of time period strings to include (e.g., "2023", "2023-01", "2023-01-15")
#' @return Maximum value or NULL if no data
#' @family layer
get_data_maximum <- function(
  measurement_layers,
  pollutant,
  spatial_data,
  display_times = NULL
) {
  layer_maxima <- lapply(measurement_layers, function(layer_config) {
    if (!layer_config$enabled || layer_config$static) {
      return(NULL)
    }

    data <- spatial_data$all_data[[layer_config$id]]
    if (is.null(data) || nrow(data) == 0) return(NULL)

    if (!is.null(display_times) && "year_str" %in% names(data)) {
      data <- data[data$year_str %in% display_times, ]
      if (nrow(data) == 0) return(NULL)
    }

    # Use pollutant parameter consistently
    if (!pollutant %in% names(data)) return(NULL)

    max_val <- max(data[[pollutant]], na.rm = TRUE)
    if (is.infinite(max_val) || is.nan(max_val)) NULL else max_val
  })

  max_values <- unlist(Filter(Negate(is.null), layer_maxima))

  if (length(max_values) > 0) {
    result <- max(max_values)
    message(
      "Legend trimming: data_max = ",
      round(result, 2),
      " (from ",
      if (is.null(display_times)) "all periods" else
        paste(length(display_times), "selected periods"),
      ")"
    )
    return(result)
  } else {
    message("Legend trimming: No data found, showing full legend")
    return(NULL)
  }
}

#' Aggregate the network down to one figure per time step
#'
#' Feeds the legend indicator: the mean concentration across the monitoring
#' network at each displayed time step, so a reader can see the whole network
#' move against the WHO and UK thresholds.
#'
#' Two rules, both user decisions of 2026-07-29, both of which change what the
#' number means:
#'
#' **Fixed panel.** Only sites with a reading at *every* displayed step are
#' counted. Real networks gain and lose sites — three of Merton's opened
#' partway through 2019-2025 — and a mean over whoever happened to be
#' reporting moves when the network changes, not when the air does. The fixed
#' panel is comparable year to year at the cost of discarding sites, and the
#' count that survives is reported alongside the figure so the reader can see
#' what it rests on.
#'
#' **One combined figure.** Every time-varying layer contributes to a single
#' mean. On a map carrying both diffusion tubes and reference-grade sensors
#' this averages two measurement methods; that was chosen deliberately with the
#' caveat noted.
#'
#' Returns NULL — no indicator — when the map is not annual. The thresholds
#' behind the indicator are annual-mean limits, and drawing a 40 µg/m³ "UK
#' limit" line behind an hourly reading would be simply wrong. Sub-annual
#' target sets are backlog issue 13.
#'
#' @param measurement_layers Layer configuration from [get_measurement_layers()]
#' @param spatial_data Loaded layers from [load_spatial_data_sources()]
#' @param display_times Time steps the map will show
#' @param pollutant Pollutant column name
#' @return List of `values` (named numeric, one per time step), `n_sites` and
#'   `pollutant`; or NULL when no honest figure can be produced
#' @family layer
#' @keywords internal
build_indicator_data <- function(
  measurement_layers,
  spatial_data,
  display_times,
  pollutant
) {
  if (identical(display_times, "static_only")) return(NULL)
  times <- as.character(sort(unique(display_times)))
  if (length(times) == 0) return(NULL)

  # Annual maps only: every step must be a bare four-digit year
  if (!all(grepl("^\\d{4}$", times))) return(NULL)

  # One long table of site / step / value across every temporal layer. Sites
  # are keyed per layer, so two layers can share a site name without merging.
  rows <- lapply(measurement_layers, function(layer_config) {
    if (!layer_config$enabled || layer_config$static) return(NULL)
    d <- spatial_data$all_data[[layer_config$id]]
    if (is.null(d) || nrow(d) == 0) return(NULL)
    if (!all(c("year_str", pollutant) %in% names(d))) return(NULL)
    if (inherits(d, "sf")) d <- sf::st_drop_geometry(d)
    d <- as.data.frame(d)
    d <- d[d$year_str %in% times & !is.na(d[[pollutant]]), , drop = FALSE]
    if (nrow(d) == 0) return(NULL)

    site <- if ("siteCode" %in% names(d)) {
      as.character(d$siteCode)
    } else {
      paste(d$Longitude, d$Latitude)
    }
    data.frame(
      site = paste0(layer_config$id, ":", site),
      step = as.character(d$year_str),
      value = as.numeric(d[[pollutant]]),
      stringsAsFactors = FALSE
    )
  })

  obs <- do.call(rbind, Filter(Negate(is.null), rows))
  if (is.null(obs) || nrow(obs) == 0) return(NULL)

  # The fixed panel: sites reporting in every step. A site measured twice in
  # one step (duplicate rows) must not count as two steps, hence the unique().
  steps_per_site <- tapply(obs$step, obs$site, function(s) length(unique(s)))
  panel <- names(steps_per_site)[steps_per_site == length(times)]
  if (length(panel) == 0) return(NULL)

  # The maximum is the worst site actually reporting at each step — every
  # site, not the panel (user decision, 2026-07-31). "The highest reading in
  # the borough" is a statement about the worst place, and excluding a site
  # because it opened late would understate it. The consequence, and the
  # reason each figure states its own basis: the maximum can jump when a new
  # site opens, so it is not the comparable-across-years figure the mean is.
  all_factor <- factor(obs$step, levels = times)
  maxima <- tapply(obs$value, all_factor, max)
  max_counts <- tapply(obs$site, all_factor, function(x) length(unique(x)))

  panel_obs <- obs[obs$site %in% panel, , drop = FALSE]
  means <- tapply(
    panel_obs$value, factor(panel_obs$step, levels = times), mean
  )

  list(
    values = round(as.numeric(means), 1),
    max_values = round(as.numeric(maxima), 1),
    max_counts = as.integer(max_counts),
    times = times,
    n_sites = length(panel),
    pollutant = pollutant
  )
}

#' Geocode UK postcodes to OSGB36 eastings/northings
#'
#' Uses the postcodes.io bulk API (100 per request). Falls back to the
#' terminated postcodes endpoint for retired postcodes, converting the
#' returned WGS84 coordinates to OSGB36 via sf.
#'
#' @param postcodes Character vector of postcodes (spaces optional, case-insensitive)
#' @return data.frame with columns: postcode, Easting, Northing (NA where lookup fails)
#' @family utils
geocode_uk_postcodes <- function(postcodes) {
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' required. Install with: install.packages('httr')")
  }

  clean <- toupper(trimws(postcodes))
  result <- data.frame(postcode = clean, Easting = NA_integer_,
                       Northing = NA_integer_, stringsAsFactors = FALSE)

  wgs84_to_osgb36 <- function(lon, lat) {
    pt <- sf::st_as_sf(data.frame(lon = lon, lat = lat),
                       coords = c("lon", "lat"), crs = 4326)
    coords <- sf::st_coordinates(sf::st_transform(pt, crs = 27700))
    list(Easting = as.integer(round(coords[, 1])),
         Northing = as.integer(round(coords[, 2])))
  }

  unique_pcs <- unique(clean[!is.na(clean) & clean != ""])
  batches <- split(unique_pcs, ceiling(seq_along(unique_pcs) / 100))

  for (batch in batches) {
    resp <- httr::POST(
      "https://api.postcodes.io/postcodes",
      body    = list(postcodes = as.list(batch)),
      encode  = "json"
    )
    if (httr::status_code(resp) != 200) next
    items <- httr::content(resp, as = "parsed")$result

    for (item in items) {
      pc <- toupper(trimws(item$query))
      idx <- result$postcode == pc
      if (!is.null(item$result)) {
        result$Easting[idx]  <- as.integer(item$result$eastings)
        result$Northing[idx] <- as.integer(item$result$northings)
      } else {
        # Try terminated postcodes endpoint
        url  <- paste0("https://api.postcodes.io/terminated_postcodes/",
                       gsub("\\s+", "", pc))
        tresp <- httr::GET(url)
        if (httr::status_code(tresp) == 200) {
          tr <- httr::content(tresp, as = "parsed")$result
          if (!is.null(tr$longitude) && !is.null(tr$latitude)) {
            osgb <- wgs84_to_osgb36(tr$longitude, tr$latitude)
            result$Easting[idx]  <- osgb$Easting
            result$Northing[idx] <- osgb$Northing
            message("NOTE: ", pc, " is a terminated postcode — coordinates approximated from WGS84")
          }
        } else {
          message("WARNING: geocoding failed for ", pc)
        }
      }
    }
  }
  result
}

#' Read a diffusion-tube or schools CSV
#'
#' Relative paths are resolved against DATA_PATH. Leading "X" characters that
#' `read.csv()` adds to numeric column names ("X2017") are stripped, so year
#' columns keep the names the user gave them. Rows missing any required column
#' (or a `Label`, where one is present) are dropped.
#'
#' @param file_path Path to the CSV, absolute or relative to DATA_PATH
#' @param required_cols Columns that must be present and non-missing
#' @return List of `data` (the data.frame) and `value_columns` (everything that
#'   is not a required column — the year columns for tube data)
#' @keywords internal
import_csv_data <- function(
  file_path,
  required_cols = c("Easting", "Northing")
) {
  # Prepend DATA_PATH if relative
  if (!grepl("^[/~]", file_path)) {
    file_path <- file.path(Sys.getenv("DATA_PATH"), file_path)
  }
  data <- read.csv(
    file_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", " ", "NA", "NaN")
  )
  names(data) <- gsub("^X", "", names(data))
  if (!all(required_cols %in% names(data))) {
    stop(paste(
      "Missing required columns:",
      paste(setdiff(required_cols, names(data)), collapse = ", ")
    ))
  }
  if ("Label" %in% names(data)) {
    required_cols <- unique(c(required_cols, "Label"))
  }
  data <- data[complete.cases(data[, required_cols]), ]
  value_columns <- setdiff(names(data), required_cols)
  if (length(value_columns) == 0 && !"Label" %in% names(data)) {
    stop("No value or label columns found in data")
  }
  list(data = data, value_columns = value_columns)
}


# TODO (see dev/FUTURE_ENHANCEMENTS.md #2): Add boundary_names validation

#' Look up boundary polygons by name
#'
#' Names are matched case-insensitively, after the spelling corrections listed
#' in `inst/config/boundaries.yaml` (which fix the common informal names). The
#' single name "all" returns every boundary. An unmatched name stops with the
#' full list of accepted names — the user cannot be expected to guess the
#' dataset's exact spelling.
#'
#' @param boundary_names Character vector of boundary names, or "all"
#' @param crs Target coordinate system; 4326 (WGS84) for Leaflet
#' @return sf object of the matching polygons
#' @keywords internal
get_boundary_sf <- function(boundary_names, crs = 4326) {
  config <- load_yaml_config("boundaries")

  load(file.path(Sys.getenv("DATA_PATH"), config$data_file))
  boundary_data <- get(config$data_object)

  input_names <- tools::toTitleCase(tolower(boundary_names))
  corrected_names <- ifelse(
    input_names %in% names(config$name_corrections),
    config$name_corrections[input_names],
    input_names
  )

  if (length(corrected_names) == 1 && tolower(corrected_names) == "all") {
    return(st_transform(boundary_data, crs = crs))
  }

  valid_names <- unique(tolower(boundary_data[[config$name_column]]))
  invalid_names <- corrected_names[!tolower(corrected_names) %in% valid_names]

  if (length(invalid_names) > 0) {
    all_names <- sort(unique(boundary_data[[config$name_column]]))
    stop(paste(
      "Error: Boundary name(s) not found:",
      paste(invalid_names, collapse = ", "),
      "\n\n",
      "Accepted names are:\n",
      paste("All,", paste(all_names, collapse = ", "), "."),
      "\n\n",
      "Note: Input is case-insensitive."
    ))
  }

  boundary_data |>
    filter(
      tolower(.data[[config$name_column]]) %in%
        tolower(corrected_names)
    ) |>
    st_transform(crs = crs)
}

#' Convert British National Grid coordinates to WGS84 points
#'
#' UK survey data arrives as Easting/Northing (EPSG:27700); Leaflet needs
#' latitude and longitude. Both the sf geometry and plain
#' `Longitude`/`Latitude` columns are returned, because the renderer reads the
#' plain columns.
#'
#' @param df data.frame with easting and northing columns
#' @param easting,northing Column names holding the grid references
#' @param crs_from Source coordinate system; 27700 is the British National Grid
#' @return sf object in WGS84, with `year_str` added when `df` has a `year`
#'   column
#' @keywords internal
transform_to_wgs84 <- function(
  df,
  easting = "Easting",
  northing = "Northing",
  crs_from = 27700
) {
  sf_obj <- sf::st_as_sf(
    df,
    coords = c(easting, northing),
    crs = crs_from
  ) |>
    sf::st_transform(crs = 4326)
  coords <- sf::st_coordinates(sf_obj)
  sf_obj$Longitude <- coords[, 1]
  sf_obj$Latitude <- coords[, 2]

  if ("year" %in% names(df)) {
    sf_obj$year_str <- format(sf_obj$year, "%Y")
  }

  sf_obj
}

#' Build the dimming shape that sits outside the boundary
#'
#' The vignette is drawn as a single polygon: a rectangle much larger than the
#' boundary, with the boundary itself punched out of it. Filling that shape
#' dims everything beyond the mapped area while leaving the area itself clear.
#'
#' @param spatial_feature sf boundary object
#' @return sfc polygon covering everything outside the boundary
#' @keywords internal
create_vignette_overlay <- function(spatial_feature) {
  tryCatch(
    {
      original_bbox <- st_bbox(spatial_feature)
      width <- original_bbox["xmax"] - original_bbox["xmin"]
      height <- original_bbox["ymax"] - original_bbox["ymin"]
      extended_bbox <- c(
        original_bbox["xmin"] - 1.5 * width,
        original_bbox["ymin"] - 1.5 * height,
        original_bbox["xmax"] + 1.5 * width,
        original_bbox["ymax"] + 1.5 * height
      )
      extended_bbox <- st_bbox(extended_bbox, crs = st_crs(spatial_feature))
      bbox_polygon <- st_as_sfc(extended_bbox)
      vignette_overlay <- st_difference(bbox_polygon, st_union(spatial_feature))
      vignette_overlay
    },
    error = function(e) {
      stop("Error in bounding box creation: ", e$message)
    }
  )
}

# == 4. Colour scales and themes ==============================================

#' Show borough theme colours
#'
#' Displays the colour palettes defined in the bundled borough theme files.
#'
#' @param borough Character. Borough name to show colours for, or NULL for all.
#' @return Invisibly, a list of theme palettes.
#' @family config
#' @export
show_borough_colours <- function(borough = NULL) {
  themes_dir <- get_package_dir("themes")

  if (!dir.exists(themes_dir)) {
    stop("Themes directory not found: ", themes_dir)
  }

  available_files <- list.files(themes_dir, pattern = "\\.yaml$")
  available <- gsub("\\.yaml$", "", available_files)

  if (is.null(borough)) {
    cat(
      "Available borough themes:",
      paste(available, collapse = ", "),
      "\n"
    )
    cat("Usage: show_borough_colours('merton_purple')\n")
    return(invisible(NULL))
  }

  theme_file <- file.path(themes_dir, paste0(borough, ".yaml"))
  if (!file.exists(theme_file)) {
    stop(
      "Theme '",
      borough,
      "' not found. Available: ",
      paste(available, collapse = ", ")
    )
  }

  theme <- yaml::read_yaml(theme_file)

  if (is.null(theme$palette)) {
    cat("Theme '", borough, "' has no palette section\n", sep = "")
    return(invisible(NULL))
  }

  cat("Colours for", borough, ":\n")
  for (name in names(theme$palette)) {
    cat("  ", name, ": ", theme$palette[[name]], "\n", sep = "")
  }
  cat(
    "\nUsage: load_theme('inst/themes/",
    borough,
    ".yaml')$palette$",
    names(theme$palette)[1],
    "\n",
    sep = ""
  )
}

#' Load colour scale from YAML configuration file
#' @param scale_name Character string, name of the colour scale (e.g., "who_no2")
#' @return List containing colour scale definition
#' @family config
#' @export
load_colour_scale <- function(scale_name) {
  scale <- load_yaml_config(
    scale_name,
    subdirectory = "scales",
    list_available = TRUE
  )

  # Convert thresholds to numeric if present
  if (!is.null(scale$thresholds)) {
    scale$thresholds <- as.numeric(scale$thresholds)
  }

  scale$name <- scale_name
  scale
}

#' Load data source configuration from YAML file
#' @param source_name Character string, name of the data source (e.g., "dt_sites", "bl_nodes", "schools")
#' @return List containing data source configuration with fields: id, label, icon_shape, static
#' @family config

#' @keywords internal
load_yaml_config <- function(
  name,
  subdirectory = NULL,
  list_available = FALSE
) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' required. Install with: install.packages('yaml')")
  }

  config_base <- get_package_dir("config")
  config_dir <- if (is.null(subdirectory)) {
    config_base
  } else {
    file.path(config_base, subdirectory)
  }

  if (!dir.exists(config_dir)) {
    stop("Config directory not found: ", config_dir)
  }

  yaml_file <- file.path(config_dir, paste0(name, ".yaml"))

  if (!file.exists(yaml_file)) {
    if (list_available) {
      available <- gsub(
        "\\.yaml$",
        "",
        list.files(config_dir, pattern = "\\.yaml$")
      )
      stop(
        "Config '",
        name,
        "' not found. Available: ",
        paste(available, collapse = ", ")
      )
    } else {
      stop("Config file '", name, ".yaml' not found in ", config_dir)
    }
  }

  tryCatch(
    yaml::read_yaml(yaml_file),
    error = function(e) {
      stop("Failed to load '", yaml_file, "': ", e$message)
    }
  )
}

#' @keywords internal
get_default_theme <- function() {
  list(
    banner = list(
      background = "#5F3E94",
      text_color = "white",
      title = "Air Quality Map",
      style = "strip"
    ),
    legend = list(
      show = TRUE,
      background = "white"
    ),
    # Aggregate indicator (user-approved 2026-07-29): the network mean for
    # the displayed time step, shown in the legend against the scale's
    # thresholds. Annual maps only — see build_indicator_data().
    indicator = list(
      show = TRUE,
      label = NULL, # NULL builds "Network mean, N sites"
      # Also mark the network maximum, as a diamond beside the mean's
      # roundel. On by default since 2026-08-05 (user, reversing the 07-31
      # decision): the busier legend is worth it, because a mean alone is
      # read as though it described everywhere, and the worst site is what
      # an air quality report is usually about.
      show_max = TRUE,
      # Where the figures sit: "title_row" (default) puts them on the legend
      # title's own line, which costs the legend no extra height at any width;
      # "under_title" stacks them beneath it; "right" puts them past the ramp.
      # Phones use the wrapping row layout whichever is set (mobile.css).
      placement = "title_row"
    ),
    map = list(
      # default reverted to OSM 2026-07-11 (user): the vignette dimming is
      # too faint on the pale Positron tiles; Positron stays a theme option
      vignette = TRUE,
      base_tiles = NULL,
      zoom_level = NULL,
      boundary_labels = FALSE,
      marker_labels = FALSE,
      # Multiplier on marker-label text. 1 puts labels on MARKER_LABEL_REM,
      # the same size as the smallest text in the legend, at every export
      # size — there is no page-size correction to make, because the labels
      # are rem and the export scales the root. Change it only to depart
      # from the legend's scale on purpose.
      label_scale = 1,
      # The translucent plate behind each marker label. Worth its clutter on
      # busy tiles, not worth it where labels are dense.
      label_background = TRUE
    ),
    controls = list(
      autoplay = FALSE,
      # No constant here (2026-08-05): with play_speed unset the pace follows
      # the number of time steps — see default_play_speed(). A theme that
      # names a value still wins.
      play_speed = NULL,
      background = NULL,
      text_color = NULL
    ),
    # Item 10: wind-particle styling, threaded into the leaflet-velocity
    # payload (see build_wind_payload). colour_ramp maps to colorScale,
    # particle_density to particleMultiplier. Defaults tuned 2026-07-12:
    # calm episodes sit at the ramp's low end, so it starts at a visible
    # mid-blue, with heavier lines and more particles for busy basemaps.
    wind = list(
      colour_ramp = c("#4575b4", "#74add1", "#8fc3a7", "#fdae61",
                      "#f46d43", "#d73027"),
      particle_density = 1 / 300,
      line_width = 1.5,
      velocity_scale = 0.01
    )
  )
}

#' Load theme from YAML file with fallback to defaults
#' @param theme_file Path to YAML theme file (NULL for defaults)
#' @return Complete theme list (merged with defaults)
#' @family config
#' @export
load_theme <- function(theme_file = NULL) {
  defaults <- get_default_theme()

  if (is.null(theme_file)) {
    return(defaults)
  }

  if (!file.exists(theme_file)) {
    warning("Theme file not found: ", theme_file, ". Using default theme.")
    return(defaults)
  }

  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "Package 'yaml' required for theme loading. Install with: install.packages('yaml')"
    )
  }

  theme <- tryCatch(
    {
      yaml::read_yaml(theme_file)
    },
    error = function(e) {
      warning(
        "Failed to load theme file: ",
        e$message,
        ". Using default theme."
      )
      return(NULL)
    }
  )

  if (is.null(theme)) {
    return(defaults)
  }

  modifyList(defaults, theme)
}

#' Extract the legend fields from a colour scale
#'
#' @param scale Name of a YAML scale in `inst/config/scales/`
#' @return List of `colors`, `labels`, `title` and `thresholds`
#' @family colour
#' @keywords internal
get_colour_legend <- function(scale = "lbrut_no2") {
  scale_data <- load_colour_scale(scale)

  list(
    colors = scale_data$colours,
    labels = scale_data$labels,
    title = scale_data$title,
    thresholds = scale_data$thresholds
  )
}

#' Pick the band colour for one measured value
#'
#' Missing or non-numeric values return white, which the scales label as
#' "insufficient data" rather than as a low reading.
#'
#' @param value A single measured value
#' @param scale Name of a YAML scale in `inst/config/scales/`
#' @return Colour name or hex code
#' @family colour
#' @keywords internal
assign_colour <- function(value, scale = "lbrut_no2") {
  if (is.na(value) || !is.numeric(value)) return("white")

  scale_data <- load_colour_scale(scale)

  thresholds <- scale_data$thresholds
  colours <- scale_data$colours
  index <- findInterval(value, thresholds, left.open = FALSE)
  return(colours[index])
}

#' Convert R color names to hex codes
#' @param color_vector Character vector of R color names or hex codes
#' @return Character vector of hex codes (uppercase format)
#' @family colour
convert_colors_to_hex <- function(color_vector) {
  sapply(
    color_vector,
    function(color) {
      if (grepl("^#[0-9A-Fa-f]{6}$", color)) {
        return(toupper(color))
      } else {
        tryCatch(
          {
            rgb_vals <- col2rgb(color)
            return(toupper(sprintf(
              "#%02X%02X%02X",
              rgb_vals[1],
              rgb_vals[2],
              rgb_vals[3]
            )))
          },
          error = function(e) {
            warning("Invalid color: ", color, ". Using black (#000000).")
            return("#000000")
          }
        )
      }
    },
    USE.NAMES = FALSE
  )
}

# == 5. Legend and banner =====================================================

#' Parse legend label into range and description
#' @param label Character string like "< 10: WHO guideline" or "25-30"
#' @return List with $range and $description (description is NULL if no colon)
#' @family legend
parse_legend_label <- function(label) {
  parts <- strsplit(label, ":", fixed = TRUE)[[1]]

  if (length(parts) >= 2) {
    range <- trimws(parts[1])
    description <- trimws(paste(parts[-1], collapse = ":"))
    return(list(range = range, description = description))
  } else {
    return(list(range = trimws(label), description = NULL))
  }
}

#' Get footnote symbol for index
#' @param index Integer index (1-based)
#' @return Character symbol (†, ‡, §, ¶, etc.)
#' @family legend
get_symbol_for_index <- function(index) {
  symbols <- c(
    "†",
    "‡",
    "§",
    "¶",
    "*",
    "⁑",
    "◊",
    "※",
    "⁂",
    "⁕",
    "∗",
    "∘",
    "•",
    "∙",
    "⋆",
    "★",
    "☆",
    "⊕",
    "⊗",
    "⊙"
  )

  if (index <= length(symbols)) {
    return(symbols[index])
  } else {
    return(paste0("(", index, ")"))
  }
}

#' Calculate maximum range width for fixed-width legend blocks
#' @param labels Character vector of legend labels
#' @return Integer number of characters for the longest range (including symbol space)
#' @family legend
calculate_max_range_width <- function(labels) {
  max_width <- 0

  for (label in labels) {
    parsed <- parse_legend_label(label)
    range_text <- parsed$range

    if (!is.null(parsed$description)) {
      range_width <- nchar(range_text) + 2
    } else {
      range_width <- nchar(range_text)
    }

    if (range_width > max_width) {
      max_width <- range_width
    }
  }

  return(max_width)
}

#' Generate HTML legend structure from colour_scale
#'
#' Creates a collapsible legend with header, toggle arrow, and color-coded items.
#' Mobile responsive: automatically collapses on screens < 480px if enabled.
#' Optionally trims legend to show only ranges up to maximum data value.
#'
#' @param scale_name Name of scale in colour_scales list (e.g., "who_no2")
#' @param collapsed_mobile Should legend start collapsed on mobile (default TRUE)
#' @param data_max Optional maximum data value to trim legend (shows only ranges up to this value)
#' @return Character string containing complete HTML legend structure
#' @details Validates:
#'   - Scale exists in colour_scales
#'   - colours and labels arrays have matching lengths
#'   Converts all colors to hex format for CSS compatibility
#'   If data_max provided, filters legend to show only relevant ranges (minimum 2 items)
#' @family legend
#' Trim a colour scale to the bands the data actually reaches
#'
#' A legend running to 100 µg/m³ under data topping out at 33 wastes most of
#' its width on bands nothing falls in. Extracted from
#' [generate_legend_html()] so the legend and the indicator bar drawn above it
#' are trimmed identically — if they disagreed, the bar would point at the
#' wrong block.
#'
#' @param legend_scale Scale list from [load_colour_scale()]
#' @param data_max Largest value in the data, or NULL for no trimming
#' @return The scale with `colours` and `labels` cut to the bands in use
#' @family legend
#' @keywords internal
trim_colour_scale <- function(legend_scale, data_max = NULL) {
  if (is.null(data_max) || is.null(legend_scale$thresholds) || data_max <= 0) {
    return(legend_scale)
  }

  # thresholds are breaks: [0, 10, 20, 30, 40, ...]. For data_max = 45,
  # which(45 < thresholds) first hits index 6 (threshold 50), but the band
  # containing 45 is item 5 (40-50) — hence the subtraction. Two items is the
  # smallest legend that still reads as a scale.
  threshold_idx <- which(data_max < legend_scale$thresholds)[1]
  num_items <- max(2, threshold_idx - 1)
  num_items <- min(num_items, length(legend_scale$colours))

  legend_scale$colours <- legend_scale$colours[1:num_items]
  legend_scale$labels <- legend_scale$labels[1:num_items]
  legend_scale
}

generate_legend_html <- function(
  scale_name,
  collapsed_mobile = TRUE,
  data_max = NULL,
  indicator_html = "",
  indicator_bar = "",
  indicator_placement = "right",
  attributions = NULL
) {
  legend_scale <- load_colour_scale(scale_name)

  if (length(legend_scale$colours) != length(legend_scale$labels)) {
    stop(sprintf(
      "Mismatch in colour_scale '%s': %d colours vs %d labels",
      scale_name,
      length(legend_scale$colours),
      length(legend_scale$labels)
    ))
  }

  legend_scale <- trim_colour_scale(legend_scale, data_max)

  hex_colors <- convert_colors_to_hex(legend_scale$colours)

  # Ramp legend (item 10, approved design): a thin row of colour blocks
  # with the range labels outside (below) the colours, plus the restyled
  # footnote-symbol key.
  # A scale can drop the footnote symbols (2026-08-05, Merton AQAP print set):
  # the †/‡/§ pairs cross-refer a ramp label to its pill, but each pill already
  # carries its band's colour, so on a scale whose bands are distinct the
  # symbols are redundant — and at print size they are the first thing to
  # become illegible. Default TRUE, so every existing scale is untouched.
  use_symbols <- !identical(legend_scale$footnote_symbols, FALSE)

  symbol_index <- 1
  ramp_blocks <- list()
  ramp_labels <- list()
  symbol_key_items <- list()

  for (i in seq_along(hex_colors)) {
    parsed <- parse_legend_label(legend_scale$labels[i])
    text_color <- get_contrast_text_color(hex_colors[i])

    if (!is.null(parsed$description)) {
      if (use_symbols) {
        symbol <- get_symbol_for_index(symbol_index)
        range_with_symbol <- paste0(parsed$range, " ", symbol)
        symbol_index <- symbol_index + 1
        key_text <- paste(symbol, parsed$description)
      } else {
        range_with_symbol <- parsed$range
        key_text <- parsed$description
      }

      symbol_key_items[[length(symbol_key_items) + 1]] <- sprintf(
        '      <span style="background: %s; color: %s;">%s</span>',
        hex_colors[i],
        text_color,
        key_text
      )
    } else {
      range_with_symbol <- parsed$range
    }

    ramp_blocks[[i]] <- sprintf(
      '        <div class="ramp-block" style="background: %s;"></div>',
      hex_colors[i]
    )
    ramp_labels[[i]] <- sprintf(
      '        <div class="ramp-label">%s</div>',
      range_with_symbol
    )
  }

  legend_items_html <- paste0(
    indicator_bar,
    '      <div class="legend-ramp">\n',
    paste(unlist(ramp_blocks), collapse = "\n"),
    '\n      </div>\n      <div class="legend-ramp-labels">\n',
    paste(unlist(ramp_labels), collapse = "\n"),
    '\n      </div>'
  )

  if (length(symbol_key_items) > 0) {
    symbol_key_html <- paste(symbol_key_items, collapse = "\n")
  } else {
    symbol_key_html <- ""
  }

  mobile_script <- if (collapsed_mobile) {
    '  if (window.innerWidth <= 480) {
    document.getElementById("mapLegend").classList.add("collapsed");
  }'
  } else {
    ''
  }

  legend_dir <- get_package_dir("legend")

  html_file <- file.path(legend_dir, "legend.html")

  html_template <- read_template_file(html_file)

  # {{placeholder}} substitution, not sprintf: the old positional form broke
  # on any injected content containing a literal % (a percentage in a label,
  # a CSS width) and gave no clue why.
  # Two slots, one filled: the figures sit either under the legend title or
  # to the right of the ramp. Both are real positions in the markup rather
  # than one position moved by CSS, because the two differ in nesting, not
  # just in order.
  # "title_row" and "under_title" both put the figures in the lead column;
  # they differ only in whether that column runs across or down.
  in_lead <- indicator_placement %in% c("title_row", "under_title")

  # Source credits sit under the legend content, inside the collapsible
  # body: a licence line belongs with the data it describes, and hiding it
  # with the legend keeps a phone screen usable without losing it.
  attribution_html <- if (length(attributions)) {
    paste0(
      '<div class="legend-attribution">',
      paste(htmltools::htmlEscape(attributions), collapse = "<br>"),
      "</div>"
    )
  } else {
    ""
  }

  apply_template_replacements(
    html_template,
    list(
      "{{legend_title}}" = legend_scale$title,
      "{{legend_attribution}}" = attribution_html,
      "{{legend_items}}" = legend_items_html,
      "{{legend_key}}" = symbol_key_html,
      "{{legend_lead_class}}" = if (identical(indicator_placement, "title_row"))
        "qm-title-row" else "",
      "{{legend_indicator_lead}}" = if (in_lead) indicator_html else "",
      "{{legend_indicator_right}}" = if (in_lead) "" else indicator_html,
      "{{legend_script}}" = mobile_script
    )
  )
}

#' Position a value along the rendered legend ramp
#'
#' The ramp is a flex row of equal-width blocks, one per band
#' (`.ramp-block { flex: 1 }`), so its geometry is *not* linear in
#' concentration: `gla_pm25`'s bands are 5, 2.5, 2.5, 2.5, 2.5, 5, 5 units
#' wide and all draw the same width. A bar measured against the ramp must
#' therefore be placed band by band — find the band, then interpolate inside
#' it — never by a straight value/max fraction.
#'
#' The open-ended top band (`.Inf`) has no width to interpolate within, so a
#' value inside it sits at the band's midpoint; anything else would imply a
#' precision the scale does not have.
#'
#' @param value A concentration
#' @param thresholds The scale's thresholds
#' @param n_blocks Number of blocks the legend actually rendered, which may
#'   include a trailing "insufficient data" block that is not a value band
#' @return Percentage of the ramp's width, 0-100
#' @family legend
#' @keywords internal
ramp_position <- function(value, thresholds, n_blocks) {
  if (is.na(value) || n_blocks < 1) return(0)
  finite_upper <- thresholds[-1]
  band <- findInterval(value, thresholds, left.open = FALSE)
  band <- max(1, min(band, length(finite_upper)))

  lower <- thresholds[band]
  upper <- finite_upper[band]
  frac <- if (is.finite(upper) && upper > lower) {
    (value - lower) / (upper - lower)
  } else {
    0.5 # open-ended top band: midpoint, no false precision
  }
  frac <- max(0, min(1, frac))

  round(100 * (band - 1 + frac) / n_blocks, 2)
}

#' Mark the network figures on the legend's colour ramp
#'
#' The legend's own colour ramp is the scale (user proposal, 2026-07-30), so
#' there is only one scale on the page and the markers cannot disagree with it.
#'
#' The mean is a roundel carrying its own figure, sitting at its place on the
#' ramp. Optionally the maximum joins it as a diamond, distinguished by shape
#' rather than by colour — colour is already spoken for, since both markers take
#' the band colour of their own value.
#'
#' When the two figures fall close together their markers would overlap, so the
#' maximum lifts above the ramp and the mean drops below it. That is a collision
#' rule, not a layout: markers move only when they would otherwise sit on top of
#' each other.
#'
#' The retired "bar" style is at
#' `dev/archive/260731_indicator_bar-style_v1.R`.
#'
#' @param indicator Result of [build_indicator_data()]
#' @param scale_name Colour scale name
#' @param data_max Largest value in the data, so markers are positioned against
#'   the ramp the legend actually drew
#' @param image_mode TRUE for the static export
#' @param display_times The step being drawn (image mode)
#' @param show_max Also mark the network maximum, as a diamond
#' @return HTML placed inside the legend, over the ramp
#' @family legend
#' @keywords internal
generate_indicator_bar <- function(
  indicator,
  scale_name,
  data_max = NULL,
  image_mode = FALSE,
  display_times = NULL,
  show_max = FALSE
) {
  if (is.null(indicator) || length(indicator$values) == 0) return("")

  scale_data <- trim_colour_scale(load_colour_scale(scale_name), data_max)
  n_blocks <- length(scale_data$colours)
  thresholds <- load_colour_scale(scale_name)$thresholds

  step <- if (image_mode && !is.null(display_times)) {
    as.character(display_times[1])
  } else {
    indicator$times[1]
  }
  idx <- match(step, indicator$times)
  if (is.na(idx)) idx <- 1

  mean_pos <- ramp_position(indicator$values[idx], thresholds, n_blocks)
  mean_colour <- convert_colors_to_hex(
    assign_colour(indicator$values[idx], scale_name)
  )
  mean_figure <- format(round(indicator$values[idx], 1), nsmall = 1)

  show_max <- isTRUE(show_max) && !is.null(indicator$max_values)

  crowded <- FALSE
  max_html <- ""
  if (show_max) {
    max_pos <- ramp_position(indicator$max_values[idx], thresholds, n_blocks)
    max_colour <- convert_colors_to_hex(
      assign_colour(indicator$max_values[idx], scale_name)
    )
    max_figure <- format(round(indicator$max_values[idx], 1), nsmall = 1)
    crowded <- abs(max_pos - mean_pos) < QM_MARKER_CLEARANCE

    max_html <- sprintf(
      paste0(
        '        <div class="qm-diamond%s" id="qmIndicatorMax" ',
        'style="left: %s%%; background: %s;" title="max all sites, %s"></div>\n'
      ),
      if (crowded) " qm-lifted" else "",
      format(max_pos, trim = TRUE), max_colour, max_figure
    )
  }

  # Markers only. The figures they used to carry above them are in the legend
  # title's row now (user, 2026-08-04), so repeating them here would say the
  # same number twice; the values remain as hover text.
  sprintf(
    paste0(
      '      <div class="legend-indicator-roundel">\n',
      '%s',
      '        <div class="qm-roundel%s" id="qmIndicatorBar" ',
      'style="left: %s%%; background: %s;" title="mean, %s"></div>\n',
      '      </div>\n'
    ),
    max_html,
    if (crowded) " qm-dropped" else "",
    format(mean_pos, trim = TRUE), mean_colour, mean_figure
  )
}

#' Draw the indicator's wording and figures
#'
#' The words half of the indicator: what the figure is, how many sites it rests
#' on, and the figure itself — plus the network maximum when that is switched
#' on. The scale half (the markers on the legend's colour ramp) is drawn by
#' [generate_indicator_bar()], because it has to live inside the legend block
#' to inherit the ramp's width.
#'
#' A chip repeating the marker's shape and colour sits beside each figure. That
#' is the visual link between the words and the ramp (user note, 2026-07-30 —
#' the first bar was "not obviously connected visually" to its figure), and it
#' is what distinguishes the mean's roundel from the maximum's diamond without
#' relying on colour, which is already carrying the concentration band.
#'
#' In an interactive map every step is emitted and `indicator.js` selects
#' between them. A static export has one step per image, so R draws that step
#' and emits no script.
#'
#' @param indicator Result of [build_indicator_data()], or NULL for no
#'   indicator
#' @param scale_name Name of the colour scale supplying the thresholds
#' @param image_mode TRUE for the static export
#' @param display_times The step being drawn (image mode) or all steps
#' @param label Caption above the figure; NULL builds "Network mean, N sites"
#' @param show_max Also report the network maximum
#' @param data_max Largest value in the data, so markers are positioned against
#'   the ramp the legend actually drew
#' @return HTML string, empty when there is nothing to show
#' @family legend
#' @keywords internal
generate_indicator_html <- function(
  indicator,
  scale_name,
  image_mode = FALSE,
  display_times = NULL,
  label = NULL,
  show_max = FALSE,
  data_max = NULL
) {
  if (is.null(indicator) || length(indicator$values) == 0) return("")

  thresholds <- load_colour_scale(scale_name)$thresholds
  n_blocks <- length(
    trim_colour_scale(load_colour_scale(scale_name), data_max)$colours
  )
  show_max <- isTRUE(show_max) && !is.null(indicator$max_values)

  # The step to show: one image shows one step; the slider drives the rest
  step <- if (image_mode && !is.null(display_times)) {
    as.character(display_times[1])
  } else {
    indicator$times[1]
  }
  idx <- match(step, indicator$times)
  if (is.na(idx)) idx <- 1
  value <- indicator$values[idx]

  # Short captions (user, 2026-08-04). The mean states its count because it is
  # a subset — the fixed panel; the maximum does not, because "all sites" is
  # what it means by definition.
  caption <- label %||% sprintf(
    "mean of %d site%s",
    indicator$n_sites,
    if (indicator$n_sites == 1) "" else "s"
  )

  colour <- convert_colors_to_hex(assign_colour(value, scale_name))

  figure_row <- function(shape, id_chip, id_value, colour, figure, extra = "") {
    sprintf(
      paste0(
        '<span class="qm-ind-chip qm-ind-chip-%s" id="%s" ',
        'style="background: %s;"></span>',
        '<span id="%s">%s</span> ',
        '<span class="qm-ind-units">\u00b5g/m\u00b3</span>%s'
      ),
      shape, id_chip, colour, id_value, figure, extra
    )
  }

  value_text <- figure_row(
    "roundel", "qmIndicatorChip", "qmIndicatorValue", colour,
    format(round(value, 1), nsmall = 1)
  )

  # Each figure is a wrapped pair (caption + value) rather than four loose
  # siblings, so a phone can lay the two side by side instead of stacking
  # them: vertical space is what a narrow screen is short of.
  figure_block <- function(caption, caption_class, value_html) {
    sprintf(
      paste0(
        '<div class="qm-ind-figure">',
        '<div class="qm-ind-caption%s">%s</div>',
        '<div class="qm-ind-value">%s</div>',
        '</div>'
      ),
      caption_class, caption, value_html
    )
  }

  max_block <- ""
  if (show_max) {
    max_value <- indicator$max_values[idx]
    # Each figure states the sites it rests on, because since 2026-07-31 they
    # rest on different ones: the mean on the fixed panel, the maximum on
    # every site reporting at that step. Unlabelled, the pair would invite the
    # reader to assume one basis.
    max_caption <- "max all sites"
    max_block <- paste0(
      "\n        ",
      figure_block(
        sprintf('<span id="qmIndicatorMaxCaption">%s</span>', max_caption),
        " qm-ind-caption-max",
        figure_row(
          "diamond", "qmIndicatorMaxChip", "qmIndicatorMaxValue",
          convert_colors_to_hex(assign_colour(max_value, scale_name)),
          format(round(max_value, 1), nsmall = 1)
        )
      )
    )
  }

  block <- sprintf(
    paste0(
      '      <div class="legend-indicator" id="qmIndicator">\n',
      '        %s%s\n',
      '      </div>'
    ),
    figure_block(caption, "", value_text), max_block
  )

  if (image_mode) return(block)

  # Interactive: positions are computed in R and shipped ready-made, so the
  # browser never has to know the colour scale
  positions <- vapply(
    indicator$values, ramp_position, 0,
    thresholds = thresholds, n_blocks = n_blocks
  )
  colours <- convert_colors_to_hex(vapply(
    indicator$values, assign_colour, "", scale = scale_name
  ))

  max_fields <- ""
  if (show_max) {
    max_positions <- vapply(
      indicator$max_values, ramp_position, 0,
      thresholds = thresholds, n_blocks = n_blocks
    )
    max_fields <- sprintf(
      paste0(',"maxValues":[%s],"maxW":[%s],"maxColours":[%s],',
             '"maxCounts":[%s],"clearance":%d'),
      paste(format(round(indicator$max_values, 1), nsmall = 1, trim = TRUE),
            collapse = ","),
      paste(sprintf("%.2f", max_positions), collapse = ","),
      paste0('"', convert_colors_to_hex(vapply(
        indicator$max_values, assign_colour, "", scale = scale_name
      )), '"', collapse = ","),
      paste(indicator$max_counts, collapse = ","),
      QM_MARKER_CLEARANCE
    )
  }

  payload <- sprintf(
    '{"times":[%s],"values":[%s],"w":[%s],"colours":[%s]%s}',
    paste0('"', indicator$times, '"', collapse = ","),
    paste(format(round(indicator$values, 1), nsmall = 1, trim = TRUE),
          collapse = ","),
    paste(sprintf("%.2f", positions), collapse = ","),
    paste0('"', colours, '"', collapse = ","),
    max_fields
  )

  controls_dir <- get_package_dir("controls")
  indicator_js <- read_template_file(
    file.path(controls_dir, "indicator.js")
  )

  paste0(
    block,
    sprintf("\n<script>\nwindow.quickmapIndicatorData = %s;\n%s\n</script>",
            payload, indicator_js)
  )
}

#' Lighten or darken a hex color
#' @param color Hex color string (e.g., "#2c3e50")
#' @param amount Percentage to lighten (positive) or darken (negative), range -100 to 100
#' @return Hex color string
#' @family colour
lighten_color <- function(color, amount = 15) {
  rgb_vals <- col2rgb(color)[, 1]

  if (amount > 0) {
    rgb_vals <- rgb_vals + ((255 - rgb_vals) * amount / 100)
  } else {
    rgb_vals <- rgb_vals + (rgb_vals * amount / 100)
  }

  rgb_vals <- pmin(pmax(rgb_vals, 0), 255)

  rgb(rgb_vals[1], rgb_vals[2], rgb_vals[3], maxColorValue = 255)
}

#' Calculate contrast text color for background using WCAG luminance formula
#' @param color Background color (hex or R color name)
#' @return "white" for dark backgrounds, "black" for light backgrounds
#' @family colour
get_contrast_text_color <- function(color) {
  rgb_vals <- col2rgb(color)[, 1]

  # Calculate relative luminance using standard formula
  # https://www.w3.org/TR/WCAG20/#relativeluminancedef
  luminance <- (0.299 *
    rgb_vals[1] +
    0.587 * rgb_vals[2] +
    0.114 * rgb_vals[3]) /
    255

  if (luminance < 0.5) {
    return("white")
  } else {
    return("black")
  }
}

# Marker labels are the smallest annotation on the map, the same class of text
# as the legend's captions. 0.75rem is not a taste: the old base was 12px
# against a 16px root, and 12/16 is 0.75 — so this is the size the labels have
# always meant to be, now written in the unit that survives an export.
MARKER_LABEL_REM <- 0.75

#' Marker-label font size, as CSS
#'
#' In `rem`, so it needs no export scaling of its own. A static export scales
#' the root font size (see [inject_banner_legend_controls()]), which is how
#' banner, legend and year label stay in proportion; expressing marker labels
#' the same way puts them in that system instead of beside it. At
#' `label_scale = 1` they land on `MARKER_LABEL_REM`, matching the smallest
#' text in the legend at any export size.
#'
#' The unit is not optional, and its absence is silent: leaflet puts
#' `textsize` straight into a CSS `font-size`, where a bare number is invalid
#' and the browser drops it, leaving the label at whatever it inherits. The
#' code passed `as.character(12 * label_sizing)` for years, so every value was
#' inert — unnoticed because the multiplier was always 1.0 and the ignored
#' value and the fallback were both 12.
#'
#' @param label_scale Multiplier on [MARKER_LABEL_REM].
#' @return A CSS length, e.g. `"0.75rem"`.
#' @keywords internal
label_font_size <- function(label_scale) {
  paste0(round(MARKER_LABEL_REM * label_scale, 4), "rem")
}

#' Build the banner's reference-layer key
#'
#' A static reference layer carries no value, so it gets no place on the
#' colour ramp and its symbol would otherwise go unexplained. Where such a
#' layer has a `Level` column, its categories and their colours become a small
#' key at the end of the banner — "✕ Primary, ✕ Secondary" — which is also
#' what lets the map labels drop the words "Primary School" and stay legible.
#'
#' @param measurement_layers Layer configuration from [get_measurement_layers()]
#' @param spatial_data Loaded layers from [load_spatial_data_sources()]
#' @return List with `shape` and `items` (label and colour), or NULL when no
#'   layer qualifies.
#' @keywords internal
build_banner_key <- function(measurement_layers, spatial_data) {
  for (layer_config in measurement_layers) {
    if (!isTRUE(layer_config$enabled) || !isTRUE(layer_config$static)) next
    data <- spatial_data$all_data[[layer_config$id]]
    if (is.null(data) || !"Level" %in% names(data)) next

    scale_data <- load_yaml_config("schools", subdirectory = "scales")
    present <- unique(trimws(as.character(data$Level)))
    domain <- unlist(scale_data$domain)
    colours <- unlist(scale_data$colours)

    keep <- domain %in% present
    if (!any(keep)) next

    return(list(
      shape = layer_config$icon_shape,
      items = Map(
        function(label, colour) list(label = label, colour = colour),
        domain[keep],
        colours[keep]
      )
    ))
  }
  NULL
}

#' Render the banner key as inline SVG
#'
#' Sized in `em`, so it follows the banner's own font size and therefore
#' scales with a static export like the rest of the chrome.
#'
#' @param key Output of [build_banner_key()], or NULL.
#' @return HTML string, empty when `key` is NULL.
#' @keywords internal
generate_banner_key_html <- function(key) {
  if (is.null(key)) return("")

  # The key repeats the marker's own geometry rather than a generic swatch:
  # a reader matches the mark on the map to the mark in the key by shape.
  mark <- function(colour) {
    sprintf(
      paste0(
        '<svg class="banner-key-mark" viewBox="0 0 20 20" aria-hidden="true">',
        '<path d="M4 4 L16 16 M16 4 L4 16" stroke="%s" stroke-width="3.6"',
        ' fill="none" stroke-linecap="round"/></svg>'
      ),
      colour
    )
  }

  items <- vapply(
    key$items,
    function(it) sprintf(
      '<span class="banner-key-item">%s%s</span>',
      mark(it$colour),
      it$label
    ),
    ""
  )

  paste0(
    '<span class="banner-key">',
    paste(items, collapse = ""),
    "</span>"
  )
}

#' @keywords internal
build_banner_css <- function(banner_colour = "#2c3e50", image_mode = FALSE,
                             banner_style = "strip") {
  banner_dir <- get_package_dir("banner")
  css_variant <- if (image_mode) "banner-image.css" else
    "banner-interactive.css"
  css_file <- file.path(banner_dir, css_variant)
  css_content <- read_template_file(css_file)

  # Item 10 (approved design): "strip" (default) is a slim white title bar
  # with a brand-colour rule; "bar" keeps the brand-colour block, refined.
  style_css <- switch(
    banner_style,
    strip = if (image_mode) {
      paste0(".banner { background: #ffffff; color: #111111; text-align: left;",
             " padding: 1.1rem 1.6rem 1rem; font-size: 1.7rem;",
             " border-bottom: 5px solid ", banner_colour, "; }")
    } else {
      paste0(".banner { background: #ffffff; color: #111111; text-align: left;",
             " padding: 0.6rem 1.25rem 0.55rem; font-size: 1.05rem;",
             " font-weight: 650;",
             " border-bottom: 3px solid ", banner_colour, "; }")
    },
    bar = if (image_mode) {
      paste0(".banner { background: ", banner_colour, "; color: white;",
             " text-align: left; padding: 1.6rem; font-size: 1.8rem; }")
    } else {
      paste0(".banner { background: ", banner_colour, "; color: white;",
             " text-align: left; padding: 0.7rem 1.25rem; font-size: 1.1rem;",
             " font-weight: 600; }")
    },
    stop("Unknown banner style '", banner_style, "'. Use \"strip\" or \"bar\".")
  )

  # Title left, reference-layer key right. With no key the flex row has a
  # single child and lays out exactly as the plain banner did.
  style_css <- paste0(
    style_css,
    "\n.banner { display: flex; align-items: baseline;",
    " justify-content: space-between; gap: 1.5em; }",
    "\n.banner-key { display: flex; align-items: baseline; gap: 1.1em;",
    " font-size: 0.62em; font-weight: 600; white-space: nowrap;",
    " flex-shrink: 0; }",
    "\n.banner-key-item { display: inline-flex; align-items: center;",
    " gap: 0.3em; }",
    "\n.banner-key-mark { width: 1.15em; height: 1.15em; flex-shrink: 0; }"
  )

  # The year label on an exported image, sized to match the banner title
  # (user, 2026-08-04: at its old size a reader could miss which year they
  # were looking at). Built here because this is where the banner's own size
  # is decided, so the two cannot drift apart. rem, so it scales with the
  # export like the rest of the chrome.
  if (image_mode) {
    banner_size <- if (identical(banner_style, "bar")) "1.8rem" else "1.7rem"
    style_css <- paste0(
      style_css,
      "\n.year-label { font-size: ", banner_size, "; }"
    )
  }

  replacements <- list("{{banner_style_css}}" = style_css)

  if (!image_mode) {
    mobile_file <- file.path(banner_dir, "mobile.css")
    replacements[["{{mobile_css}}"]] <- read_template_file(mobile_file)
  }

  css_content <- apply_template_replacements(css_content, replacements)
  sprintf("\n<style>\n%s\n</style>\n", css_content)
}

#' @keywords internal
build_legend_css <- function(banner_colour = "#2c3e50", image_mode = FALSE) {
  legend_dir <- get_package_dir("legend")
  css_variant <- if (image_mode) "legend-image.css" else
    "legend-interactive.css"
  css_file <- file.path(legend_dir, css_variant)
  css_content <- read_template_file(css_file)

  # Item 10 (approved design): neutral chrome — the legend header no longer
  # tints with the brand colour; hover uses a faint brand-tinted wash.
  replacements <- list(
    "{{legend_header_bg}}" = "#ffffff",
    "{{legend_header_hover}}" = lighten_color(banner_colour, 92)
  )

  if (!image_mode) {
    mobile_file <- file.path(legend_dir, "mobile.css")
    replacements[["{{mobile_css}}"]] <- read_template_file(mobile_file)
  }

  css_content <- apply_template_replacements(css_content, replacements)
  sprintf("\n<style>\n%s\n</style>\n", css_content)
}

# == 6. Saving and static export ==============================================

#' @keywords internal
add_year_and_static_layers <- function(
  template,
  year,
  measurement_layers,
  pollutant,
  colour_scale,
  spatial_data,
  scale_factor,
  label_scale = 1.0,
  label_background = TRUE
) {
  template |>
    generate_map_layers(
      measurement_layers,
      year,
      pollutant,
      colour_scale,
      spatial_data,
      scale_factor,
      label_scale,
      label_background
    ) |>
    generate_map_layers(
      measurement_layers,
      "static_only",
      pollutant,
      colour_scale,
      spatial_data,
      scale_factor,
      label_scale,
      label_background
    )
}

#' Add the map furniture, save the file, and export a JPG if asked
#'
#' The last step of one output pass. Boundary, vignette, viewport and time
#' controls go on, the HTML is written and post-processed, and — for an image
#' pass — the saved HTML is screenshotted to JPG and then deleted, because the
#' image is the deliverable and the intermediate HTML is styled for a camera,
#' not for a reader.
#'
#' @param map Leaflet map object
#' @param html_file Output path for the HTML
#' @param borough_sf Boundary polygons, or NULL for no boundary
#' @param vignette_overlay Dimming shape from [create_vignette_overlay()]
#' @param vignette Logical; whether to draw the dimming
#' @param bbox Viewport bounding box
#' @param interactive TRUE for the HTML pass, FALSE for the image pass
#' @param display_times Time steps offered by the control
#' @param boundary_labels Logical; label the boundary areas
#' @param zoom_level Fixed zoom, or NULL to fit `bbox`
#' @param title Banner title
#' @param styling_type "html" to inject banner/legend/controls, "none" to skip
#' @param show_banner Logical; show the title strip
#' @param banner_colour Brand accent colour
#' @param colour_scale Name of the colour scale (drives the legend)
#' @param autoplay,play_speed Animation settings for the time control
#' @param data_max Largest value in the data (legend scaling)
#' @param image_dimensions c(width, height) for the JPG pass; NULL for HTML
#' @param lazy_payload Embedded JSON payload when lazy rendering is in use
#' @param banner_style "strip" or "bar"
#' @param indicator Aggregate figures from [build_indicator_data()], or NULL
#' @param indicator_label Caption for the indicator, or NULL for the default
#' @param indicator_show_max Also mark the network maximum, as a diamond
#' @param indicator_placement "right" of the ramp or "under_title"
#' @param banner_key Reference-layer key from [build_banner_key()], drawn at
#'   the end of the banner. NULL for no key.
#' @return The map object, invisibly used by the caller's loop
#' @keywords internal
finalize_and_save_map <- function(
  map,
  html_file,
  borough_sf,
  vignette_overlay,
  vignette,
  bbox,
  interactive,
  display_times,
  boundary_labels,
  zoom_level,
  title,
  styling_type,
  show_banner,
  banner_colour,
  colour_scale,
  autoplay,
  play_speed,
  data_max,
  image_dimensions = NULL,
  lazy_payload = NULL,
  banner_style = "strip",
  indicator = NULL,
  indicator_label = NULL,
  indicator_show_max = FALSE,
  indicator_placement = "right",
  banner_key = NULL,
  attributions = NULL
) {
  map <- add_map_controls(
    map,
    borough_sf,
    vignette_overlay,
    vignette,
    bbox,
    interactive,
    display_times,
    boundary_labels,
    zoom_level,
    lazy_payload
  )

  save_html_and_style(
    map,
    html_file,
    title,
    styling_type,
    show_banner,
    banner_colour,
    colour_scale,
    !interactive,
    !interactive,
    image_dimensions,
    autoplay,
    play_speed,
    data_max,
    display_times,
    banner_style,
    indicator,
    indicator_label,
    indicator_show_max,
    indicator_placement,
    banner_key,
    attributions
  )

  if (!is.null(image_dimensions)) {
    img_file <- sub("\\.html$", ".jpg", html_file)
    webshot2::webshot(
      html_file,
      img_file,
      vwidth = image_dimensions[1],
      vheight = image_dimensions[2]
    )
    unlink(html_file)
  }

  return(map)
}

#' Write the widget to a self-contained HTML file and style it
#'
#' Leaflet's own output has no banner, legend or time control; those are added
#' by rewriting the saved file (see [inject_banner_legend_controls()]). The
#' `_files` folder that `saveWidget()` leaves behind is removed — with
#' `selfcontained = TRUE` everything is already inside the HTML, and the folder
#' would only confuse a user emailing the map.
#'
#' @inheritParams finalize_and_save_map
#' @param collapsed_mobile Logical; start the legend collapsed on small screens
#' @param image_mode Logical; use the static-export styling
#' @return NULL, called for its side effect
#' @keywords internal
save_html_and_style <- function(
  map,
  html_file,
  title,
  styling_type,
  show_banner,
  banner_colour,
  colour_scale,
  collapsed_mobile,
  image_mode,
  image_dimensions,
  autoplay,
  play_speed,
  data_max,
  display_times = NULL,
  banner_style = "strip",
  indicator = NULL,
  indicator_label = NULL,
  indicator_show_max = FALSE,
  indicator_placement = "right",
  banner_key = NULL,
  attributions = NULL
) {
  htmlwidgets::saveWidget(
    map,
    file = html_file,
    selfcontained = TRUE,
    title = title
  )

  if (styling_type == "html") {
    inject_banner_legend_controls(
      html_file = html_file,
      title = if (show_banner) title else NULL,
      banner_colour = banner_colour,
      scale_name = colour_scale,
      collapsed_mobile = collapsed_mobile,
      image_mode = image_mode,
      image_dimensions = image_dimensions,
      autoplay = autoplay,
      play_speed = play_speed,
      data_max = data_max,
      display_times = display_times,
      banner_style = banner_style,
      indicator = indicator,
      indicator_label = indicator_label,
      indicator_show_max = indicator_show_max,
      indicator_placement = indicator_placement,
      banner_key = banner_key,
      attributions = attributions
    )
  }

  files_folder <- paste0(tools::file_path_sans_ext(html_file), "_files")
  if (dir.exists(files_folder)) {
    unlink(files_folder, recursive = TRUE)
  }
}

# == 7. Time control and the lazy payload =====================================

#' Default milliseconds per step, from the number of steps
#'
#' A flat 500ms is too fast for an annual map: the colour crossfade is then
#' close to half the interval, so the map is in motion as much as it is still.
#' At 1200ms the fade is about a fifth of the step, leaving nearly a second
#' settled — enough to read the year and scan the markers. Long animations
#' keep a brisk pace because what they show is the sweep, not the step.
#'
#' @param n_steps Number of time steps being displayed.
#' @return Milliseconds per step.
#' @keywords internal
default_play_speed <- function(n_steps) {
  if (n_steps <= 12) {
    1200
  } else if (n_steps <= 60) {
    800
  } else {
    450
  }
}

#' Playback multipliers offered by the speed button
#'
#' Six speeds means up to five presses to reach the one you want. On a short
#' animation the fastest of them are not worth the presses: at 8× a seven-step
#' map spends 150ms on each, too fast to read, so it is a speed you pass
#' through rather than one you choose. Short animations therefore get the
#' middle four and long ones the full set (user decision 2026-08-05).
#'
#' @param n_steps Number of time steps being displayed.
#' @return Numeric vector of multipliers, always containing 1.
#' @keywords internal
speed_multipliers <- function(n_steps) {
  if (n_steps <= 12) {
    c(0.5, 1, 2, 4)
  } else {
    c(0.25, 0.5, 1, 2, 4, 8)
  }
}

#' @keywords internal
load_time_slider_control <- function(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500,
  image_mode = FALSE,
  display_times = NULL
) {
  controls_dir <- get_package_dir("controls")

  # Static export: no interaction — just a quiet label pill naming the
  # rendered time step
  if (image_mode) {
    time_text <- if (!is.null(display_times) && length(display_times) > 0) {
      as.character(display_times[1])
    } else ""
    # Top-left (user, 2026-08-04): the corner a reader looks at first, and
    # free in an export because the zoom buttons are not drawn. Sized by
    # .year-label in the banner CSS so it matches the title.
    return(sprintf(
      paste0(
        '\n<div id="yearControl" class="year-label"',
        ' style="position: absolute; top: 1.2rem;',
        ' left: 1.2rem; z-index: 1000; background: rgba(255,255,255,0.95);',
        ' border: 1px solid #ddd; border-radius: 0.5rem;',
        ' padding: 0.5rem 1rem; font-weight: 700;',
        ' font-family: system-ui, -apple-system, sans-serif;',
        ' box-shadow: 0 1px 4px rgba(0,0,0,0.18);">%s</div>\n'
      ),
      time_text
    ))
  }

  html_content <- read_template_file(
    file.path(controls_dir, "time-slider.html")
  )
  css_content <- apply_template_replacements(
    read_template_file(file.path(controls_dir, "time-slider.css")),
    list(
      "{{accent}}" = banner_colour,
      "{{accent_light}}" = lighten_color(banner_colour, 15)
    )
  )
  js_content <- read_template_file(file.path(controls_dir, "time-slider.js"))

  # The speed set is chosen here rather than in the browser because only R
  # knows how many steps there are.
  n_steps <- if (is.null(display_times)) 0 else length(unique(display_times))
  config_script <- sprintf(
    'window.quickmapConfig = {autoplay: %s, playSpeed: %d, speeds: [%s]};',
    tolower(as.character(autoplay)),
    as.integer(play_speed),
    paste(speed_multipliers(n_steps), collapse = ", ")
  )

  sprintf(
    '
%s

<style>
%s
</style>

<script>
%s
</script>

<script>
%s
</script>
',
    html_content,
    css_content,
    config_script,
    js_content
  )
}

#' @keywords internal
load_layer_cache_js <- function() {
  controls_dir <- get_package_dir("controls")

  js_file <- file.path(controls_dir, "layer-cache.js")
  return(read_template_file(js_file))
}

#' @keywords internal
load_lazy_controller_js <- function() {
  controls_dir <- get_package_dir("controls")
  read_template_file(file.path(controls_dir, "lazy-time-controller.js"))
}

# Shapes coloured by stroke rather than fill (kept in sync with the Canvas
# controller's drawSymbol and create_generic_icons)
# Percentage of the legend ramp within which two markers would overlap, at
# which point the collision rule separates them vertically. Calibrated to the
# roundel's own width against a full-width legend.
QM_MARKER_CLEARANCE <- 9

NONSOLID_SHAPES <- c(
  "simple-plus", "simple-cross", "cross-rect", "simple-star",
  "plus-circle", "plus-rect", "cross-circle", "cross", "plus"
)

#' Enforce the default time step cap (CLAUDE.md "Time steps and file size")
#' @keywords internal
apply_time_step_cap <- function(display_times) {
  if (identical(display_times, "static_only")) return(display_times)
  cap <- getOption("quickmap.time_step_cap", 200)
  times <- sort(unique(display_times))
  if (length(times) <= cap) return(display_times)
  warning(
    length(times), " time steps exceed the ", cap,
    "-step cap; showing the most recent ", cap, ".",
    call. = FALSE
  )
  utils::tail(times, cap)
}

# Marker rows across enabled temporal layers within display_times
#' @keywords internal
count_temporal_rows <- function(
  measurement_layers,
  spatial_data,
  display_times,
  pollutant
) {
  sum(vapply(measurement_layers, function(layer_config) {
    if (!layer_config$enabled || layer_config$static) return(0L)
    d <- spatial_data$all_data[[layer_config$id]]
    if (!pollutant %in% names(d)) return(0L)
    sum(d$year_str %in% as.character(display_times) & !is.na(d[[pollutant]]))
  }, 0L))
}

#' Decide between pre-built layers and the lazy embedded-JSON path (item 6).
#' Lazy when time steps exceed 50 or the estimated pre-built file size exceeds
#' ~5 MB (~1 MB widget base + ~65 bytes per serialized marker, calibrated on
#' the characterization fixtures).
#' @keywords internal
use_lazy_rendering <- function(n_steps, n_marker_rows) {
  n_steps > getOption("quickmap.lazy_step_threshold", 50) ||
    (1e6 + 65 * n_marker_rows) >
      getOption("quickmap.lazy_size_threshold", 5e6)
}

#' Build the compact embedded payload consumed by lazy-time-controller.js:
#' {times, thresholds, colours, naColour, layers: [{id, shape, radius,
#' nonsolid, labelMode, noHide, sites: [{code, lat, lon, label?, v: [...]}]}]}
#'
#' The shape of this payload is the whole point of item 6. A site appears once,
#' with its readings as a plain vector in time order, so a coordinate pair is
#' serialized once rather than once per time step; the colours are sent as
#' thresholds for the controller to apply, rather than as a colour per marker
#' per step. That is what turns a multi-megabyte file into a small one.
#'
#' @param measurement_layers Layer configuration from [get_measurement_layers()]
#' @param spatial_data Loaded layers from [load_spatial_data_sources()]
#' @param display_times Time steps to include
#' @param pollutant Pollutant column name
#' @param colour_scale Name of the colour scale
#' @return A list ready for JSON serialization
#' @keywords internal
build_lazy_payload <- function(
  measurement_layers,
  spatial_data,
  display_times,
  pollutant,
  colour_scale
) {
  scale_data <- load_colour_scale(colour_scale)
  finite <- is.finite(scale_data$thresholds)
  colours_hex <- convert_colors_to_hex(unlist(scale_data$colours))
  times <- as.character(sort(unique(display_times)))

  layers <- list()
  for (layer_config in measurement_layers) {
    if (!layer_config$enabled || layer_config$static) next
    d <- spatial_data$all_data[[layer_config$id]]
    if (inherits(d, "sf")) d <- sf::st_drop_geometry(d)
    d <- as.data.frame(d)
    d <- d[d$year_str %in% times & !is.na(d[[pollutant]]), , drop = FALSE]
    if (nrow(d) == 0) next

    marker_labels <- layer_config$options$marker_labels %||% FALSE
    want_custom <- isTRUE(marker_labels %in% c("labels", "labels_on"))
    has_label_col <- "Label" %in% names(d)
    label_mode <- if (isTRUE(marker_labels) ||
                      identical(marker_labels, "values_on")) {
      "values"
    } else if (want_custom && has_label_col) {
      "custom"
    } else if (want_custom) {
      warning(
        "marker_labels set to '", marker_labels,
        "' but no Label column found. Showing pollution values instead.",
        call. = FALSE
      )
      "values"
    } else {
      "none"
    }

    # One row per site, readings as a vector across `times`. A site is
    # identified by siteCode where the data has one, and by its coordinates
    # otherwise (tube CSVs have no site code).
    key <- if ("siteCode" %in% names(d)) {
      as.character(d$siteCode)
    } else {
      paste(d$Longitude, d$Latitude)
    }
    first <- !duplicated(key)
    ukey <- key[first]
    # Sites x times grid; gaps stay NA and are drawn in the "no data" colour
    values <- matrix(NA_real_, nrow = length(ukey), ncol = length(times))
    values[cbind(match(key, ukey), match(d$year_str, times))] <-
      d[[pollutant]]

    sites <- lapply(seq_along(ukey), function(i) {
      site <- list(
        code = ukey[i],
        lat = d$Latitude[first][i],
        lon = d$Longitude[first][i],
        v = I(round(values[i, ], 1))
      )
      if (label_mode == "custom") {
        site$label <- as.character(d$Label[first][i])
      }
      site
    })

    layers[[length(layers) + 1]] <- list(
      id = layer_config$id,
      shape = layer_config$icon_shape,
      radius = get_icon_shape_config(layer_config$icon_shape)$base_size / 2,
      nonsolid = layer_config$icon_shape %in% NONSOLID_SHAPES,
      labelMode = label_mode,
      noHide = marker_labels %in% c("values_on", "labels_on"),
      sites = sites
    )
  }

  # Infinite thresholds are dropped: JSON has no Inf, and the controller
  # treats "above the last threshold" as the top band anyway
  list(
    times = I(times),
    thresholds = I(scale_data$thresholds[finite]),
    colours = I(colours_hex[finite]),
    naColour = colours_hex[length(colours_hex)],
    layers = layers
  )
}

# == 8. HTML post-processing ==================================================

#' Inject banner, legend, and year control into saved HTML
#'
#' Modifies an existing HTML file in place to add:
#'   1. Viewport meta tag for mobile compatibility
#'   2. Custom CSS for banner/legend/map layout
#'   3. Banner div above map (optional)
#'   4. Map container with flexbox layout
#'   5. Year control menu (for temporal data)
#'   6. External legend below map (generated from colour_scale)
#'
#' @param html_file Path to saved HTML file (will be modified in place)
#' @param title Text for banner (NULL to skip banner entirely)
#' @param banner_colour Hex color for banner background (default "#2c3e50")
#' @param scale_name Name of colour_scale to use for legend (e.g., "who_no2")
#' @param collapsed_mobile Should legend start collapsed on mobile (default TRUE)
#' @param data_max Optional maximum data value for legend trimming (default NULL shows full legend)
#' @return Invisibly returns TRUE on success
#' @details Uses flexbox layout:
#'   - Banner: fixed height at top (optional)
#'   - Map: flex: 1 (fills remaining space)
#'   - Legend: fixed height at bottom (collapsible)
#'   Layout is 100vh total height with no scrollbars
#' @family layout
inject_banner_legend_controls <- function(
  html_file,
  title = NULL,
  banner_colour = "#2c3e50",
  scale_name,
  collapsed_mobile = TRUE,
  image_mode = FALSE,
  image_dimensions = c(IMAGE_X, IMAGE_Y),
  autoplay = FALSE,
  play_speed = 500,
  data_max = NULL,
  display_times = NULL,
  banner_style = "strip",
  indicator = NULL,
  indicator_label = NULL,
  indicator_show_max = FALSE,
  indicator_placement = "right",
  banner_key = NULL,
  attributions = NULL
) {
  if (!file.exists(html_file)) {
    stop("HTML file not found: ", html_file)
  }

  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")

  # every injection below anchors on saveWidget's markup; a silent non-match
  # would ship a map with no banner, legend, or controls
  anchors <- c("</head>", "<body", "</body>")
  found <- vapply(anchors, grepl, logical(1), x = html_text, fixed = TRUE)
  if (!all(found)) {
    stop(
      "HTML injection anchors not found in ", html_file, ": ",
      paste(anchors[!found], collapse = ", "),
      " (htmlwidgets/leaflet output format may have changed)"
    )
  }

  viewport_meta <- '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'

  banner_css <- build_banner_css(banner_colour, image_mode, banner_style)

  legend_css <- build_legend_css(banner_colour, image_mode)

  custom_css <- paste0(banner_css, legend_css)

  if (image_mode) {
    width <- image_dimensions[1]
    height <- image_dimensions[2]

    # Unified chrome scaling (item 10, fixes the inert substitutions logged
    # 2026-07-05): every chrome size is rem-based, so scaling the root
    # font-size scales banner, legend and time label together. Geometric
    # mean keeps 1920x1080 and 800x600 balanced against the 1200x1200
    # baseline.
    scale_factor <- sqrt((width * height) / (IMAGE_X * IMAGE_Y))
    custom_css <- paste0(
      custom_css,
      sprintf("\n<style>\nhtml { font-size: %.2fpx; }\n</style>\n",
              16 * scale_factor)
    )
  }

  html_text <- sub(
    "</head>",
    paste0(viewport_meta, custom_css, "</head>"),
    html_text
  )

  banner_html <- if (!is.null(title)) {
    sprintf(
      '<div class="banner"><span class="banner-title">%s</span>%s</div>\n<div class="map-container">\n',
      title,
      generate_banner_key_html(banner_key)
    )
  } else {
    '<div class="map-container">\n'
  }

  html_text <- sub("(<body[^>]*>)", paste0("\\1\n", banner_html), html_text)

  # Only add time control if we have temporal data
  if (!identical(display_times, "static_only")) {
    time_control_html <- load_time_slider_control(
      banner_colour,
      autoplay,
      play_speed,
      image_mode,
      display_times
    )
  } else {
    time_control_html <- ""
  }

  indicator_html <- generate_indicator_html(
    indicator,
    scale_name,
    image_mode,
    display_times,
    indicator_label,
    indicator_show_max,
    data_max
  )

  indicator_bar <- generate_indicator_bar(
    indicator, scale_name, data_max, image_mode, display_times,
    indicator_show_max
  )

  legend_html <- generate_legend_html(
    scale_name, collapsed_mobile, data_max, indicator_html, indicator_bar,
    indicator_placement, attributions
  )

  combined_html <- paste0(time_control_html, "\n", legend_html)
  html_text <- sub("</body>", paste0(combined_html, "</body>"), html_text)

  writeLines(html_text, html_file)

  return(invisible(TRUE))
}

# == 9. Symbols and layers ====================================================

#' @keywords internal
validate_and_fix_icon_shape <- function(shape_name) {
  # Valid shape names: solid symbols first, then non-solid
  # Solid: suitable for temporal/dynamic data with color-coded concentrations
  # Non-solid: suitable for static reference layers
  valid_shapes <- c(
    # Solid symbols
    "circle",
    "rect",
    "square",
    "triangle",
    "diamond",
    "stadium",
    "down-triangle",
    "solid-circle-sm",
    "solid-circle-md",
    # Non-solid symbols
    "simple-plus",
    "simple-cross",
    "cross-rect",
    "simple-star",
    "plus-circle",
    "plus-rect",
    "cross-circle",
    # Legacy mixed (kept for backward compatibility)
    "cross",
    "star",
    "plus"
  )

  if (!shape_name %in% valid_shapes) {
    stop(
      "Invalid icon shape: '",
      shape_name,
      "'. ",
      "Valid shapes: ",
      paste(valid_shapes, collapse = ", ")
    )
  }

  # Fix "square" → "rect" for leaflegend compatibility
  if (shape_name == "square") {
    return("rect")
  }

  return(shape_name)
}

#' Look up the drawing parameters for a symbol shape
#'
#' Base sizes are chosen per shape so that the symbols look the same visual
#' weight next to each other: outline symbols (plus, cross) read larger than
#' filled ones at the same nominal size, so they are given a smaller base.
#'
#' @param shape_name A shape name already passed through
#'   [validate_and_fix_icon_shape()]
#' @return List of `shape` (the leaflegend name) and `base_size` in pixels at
#'   the 1200x1200 reference size
#' @keywords internal
get_icon_shape_config <- function(shape_name) {
  # Data-driven shape mapping
  # Maps shape names to leaflegend icon parameters
  # Note: shape_name should be validated before calling this
  shape_definitions <- list(
    # Solid symbols
    "circle" = list(shape = "circle", base_size = 20),
    "rect" = list(shape = "rect", base_size = 20),
    "triangle" = list(shape = "triangle", base_size = 20),
    "diamond" = list(shape = "diamond", base_size = 20),
    "stadium" = list(shape = "stadium", base_size = 20),
    "down-triangle" = list(shape = "down-triangle", base_size = 20),
    "solid-circle-sm" = list(shape = "solid-circle-sm", base_size = 15),
    "solid-circle-md" = list(shape = "solid-circle-md", base_size = 18),
    # Non-solid symbols
    "simple-plus" = list(shape = "simple-plus", base_size = 12),
    "simple-cross" = list(shape = "simple-cross", base_size = 12),
    "cross-rect" = list(shape = "cross-rect", base_size = 20),
    "simple-star" = list(shape = "simple-star", base_size = 20),
    "plus-circle" = list(shape = "plus-circle", base_size = 20),
    "plus-rect" = list(shape = "plus-rect", base_size = 20),
    "cross-circle" = list(shape = "cross-circle", base_size = 20),
    # Legacy symbols
    "cross" = list(shape = "cross", base_size = 12),
    "star" = list(shape = "star", base_size = 20),
    "plus" = list(shape = "plus", base_size = 12)
  )

  config <- shape_definitions[[shape_name]]
  if (is.null(config)) {
    stop("Internal error: Unknown icon shape after validation: ", shape_name)
  }
  return(config)
}

#' Build the marker symbols for one layer at one time step
#'
#' Every layer type goes through this one function; what differs is only the
#' shape and how the colour is chosen. A layer with a `Level` column and no
#' pollutant (schools) is coloured categorically from the schools scale; a
#' pollutant layer is coloured by threshold band; anything else falls back to
#' grey.
#'
#' Outline shapes (plus, cross, star) are coloured through `color`, the stroke,
#' because they have no interior to fill; filled shapes are coloured through
#' `fillColor` and given a white stroke so that overlapping markers stay
#' separable.
#'
#' @param data Layer data for this time step
#' @param icon_shape Validated shape name
#' @param pollutant Pollutant column name, or NULL for a static layer
#' @param colour_scale Name of the colour scale for pollutant layers
#' @param image_scale_factor Symbol scaling for static export; 1.0 for HTML.
#'   Base sizes assume a 1200x1200 image, so other sizes use
#'   `sqrt((width * height) / (1200 * 1200))`
#' @param layer_id Layer identifier (used by callers for grouping)
#' @return leaflegend symbol list ready for `addMarkers()`
#' @keywords internal
create_generic_icons <- function(
  data,
  icon_shape,
  pollutant = NULL,
  colour_scale = NULL,
  image_scale_factor = 1.0,
  layer_id = NULL
) {
  # Base sizes are for 1200x1200px reference images
  # For other sizes: scale = sqrt((width × height) / (1200 × 1200))
  # HTML maps: image_scale_factor = 1.0 (no scaling)
  # Static maps: image_scale_factor calculated from dimensions

  # Get shape config from data-driven lookup (icon_shape now passed from config)
  base_shape_config <- get_icon_shape_config(icon_shape)

  shape_config <- list(
    shape = base_shape_config$shape,
    size = round(base_shape_config$base_size * image_scale_factor)
  )

  # Color assignment: static layers with Level column use categorical colors
  has_level <- "Level" %in% names(data)
  colors <- if (has_level && is.null(pollutant)) {
    # Level-based layers use the categorical schools scale, not the pollutant scale
    scale_data <- load_yaml_config("schools", subdirectory = "scales")
    pal <- colorFactor(
      unlist(scale_data$colours),
      domain = NULL,
      levels = scale_data$domain
    )
    pal(trimws(data$Level))
  } else if (!is.null(pollutant)) {
    sapply(data[[pollutant]], assign_colour, scale = colour_scale)
  } else {
    rep("gray", nrow(data)) # Fallback for static without Level
  }

  # Non-solid symbols use color (stroke), solid symbols use fillColor
  is_nonsolid <- shape_config$shape %in% NONSOLID_SHAPES

  makeSymbolsSize(
    values = rep(1, length(colors)),
    shape = shape_config$shape,
    color = if (is_nonsolid) colors else "#ffffff",
    fillColor = colors,
    baseSize = shape_config$size,
    fillOpacity = 0.75,
    # Scales with the export like the symbol it draws. At a flat 2px an
    # outline shape — a cross has nothing but its stroke — came out hairline
    # on a 4000px print while its size grew almost threefold.
    strokeWidth = max(2, round(2 * image_scale_factor)),
    opacity = 1
  )
}

#' @keywords internal
get_measurement_layers <- function(
  spatial_data,
  marker_labels,
  data_symbols = NULL
) {
  layer_ids <- spatial_data$ids
  # Solid symbols for temporal/dynamic data
  default_solid_symbols <- c(
    "circle",
    "rect",
    "triangle",
    "diamond",
    "stadium",
    "down-triangle",
    "solid-circle-sm",
    "solid-circle-md"
  )
  # Non-solid symbols for static reference layers
  default_nonsolid_symbols <- c(
    "simple-plus",
    "simple-cross",
    "cross-rect",
    "simple-star",
    "plus-circle",
    "plus-rect",
    "cross-circle"
  )

  layers <- list()

  # Track separate counters for dynamic and static layers
  dynamic_counter <- 0
  static_counter <- 0

  for (i in seq_along(layer_ids)) {
    layer_id <- layer_ids[i]
    data_obj <- spatial_data$all_data[[layer_id]]
    enabled <- !is.null(data_obj)

    # Detect if static (no year_str column) - do this before symbol assignment
    is_static <- enabled && !("year_str" %in% names(data_obj))

    # Symbol: use data_symbols or auto-cycle based on static/dynamic type.
    # NA entries mean "no shape set for this layer" — fall to the cycle.
    symbol <- if (!is.null(data_symbols) && i <= length(data_symbols) &&
                    !is.na(data_symbols[i])) {
      data_symbols[i]
    } else if (is_static) {
      static_counter <- static_counter + 1
      default_nonsolid_symbols[
        ((static_counter - 1) %% length(default_nonsolid_symbols)) + 1
      ]
    } else {
      dynamic_counter <- dynamic_counter + 1
      default_solid_symbols[
        ((dynamic_counter - 1) %% length(default_solid_symbols)) + 1
      ]
    }
    icon_shape <- validate_and_fix_icon_shape(symbol)

    layers[[layer_id]] <- list(
      enabled = enabled,
      id = layer_id,
      static = is_static,
      icon_shape = icon_shape,
      options = list(marker_labels = marker_labels)
    )
  }

  layers
}

#' Assemble one layer's data and labels for a single time step
#'
#' The middle step of the generic layer pipeline
#' (`prepare_generic_layer_data()` -> [create_generic_icons()] ->
#' [add_layer()]). Static layers are passed a NULL pollutant so that their
#' labels and colours come from their own columns rather than from readings
#' they do not have.
#'
#' @param layer_config One entry from [get_measurement_layers()]
#' @param year_data Rows for this layer at this time step
#' @param pollutant Pollutant column name
#' @param colour_scale Name of the colour scale
#' @return List of `data` and `labels`, or NULL when there are no rows
#' @keywords internal
prepare_generic_layer_data <- function(
  layer_config,
  year_data,
  pollutant = NULL,
  colour_scale = NULL
) {
  if (nrow(year_data) == 0) return(NULL)

  show_labels <- if (!is.null(layer_config$options))
    layer_config$options$marker_labels else FALSE

  # Static layers don't have pollutant columns
  use_pollutant <- if (layer_config$static) NULL else pollutant

  result <- list(
    data = year_data,
    labels = generate_marker_labels(
      year_data,
      use_pollutant,
      show_labels,
      layer_config$id
    )
  )

  result
}


#' @keywords internal
add_layer <- function(
  map,
  layer_data,
  layer_config,
  year = NULL,
  pollutant = NULL,
  colour_scale = NULL,
  label_sizing = 1.0,
  image_scale_factor = 1.0,
  marker_labels = FALSE,
  label_background = TRUE
) {
  if (is.null(layer_data)) return(map)

  layer_id <- layer_config$id

  # Static layers use categorical colors (e.g., Primary/Secondary), not pollutant scale
  use_pollutant <- if (layer_config$static) NULL else pollutant

  icons <- create_generic_icons(
    layer_data$data,
    icon_shape = layer_config$icon_shape,
    use_pollutant,
    colour_scale,
    image_scale_factor,
    layer_id = layer_id
  )

  label_text_size <- label_font_size(label_sizing)

  # Always-visible labels for values_on/labels_on
  no_hide <- marker_labels %in% c("values_on", "labels_on")

  label_opts <- labelOptions(
    noHide = no_hide,
    direction = "bottom",
    offset = c(0, 12),
    textOnly = TRUE,
    textsize = label_text_size,
    # The plate behind a label buys legibility over busy tiles and costs
    # clutter where the labels are dense; map.label_background turns it off.
    style = if (isFALSE(label_background)) {
      list("background-color" = "transparent", "border" = "none",
           "padding" = "0")
    } else {
      list(
        "background-color" = "rgba(255,255,255,0.5)",
        "padding" = "1px",
        "border-radius" = "3px",
        "border" = "1px solid rgba(0,0,0,0.1)"
      )
    }
  )

  marker_params <- list(
    data = layer_data$data,
    lng = ~Longitude,
    lat = ~Latitude,
    icon = icons,
    label = layer_data$labels,
    labelOptions = label_opts
  )

  # Use static flag from config: non-static (temporal) layers grouped by year
  if (!layer_config$static) {
    marker_params$group <- year
  }

  do.call(addMarkers, c(list(map = map), marker_params))
}


#' Generate marker labels via duck typing (School/Label/pollutant columns)
#'
#' @param data Data frame with spatial data
#' @param pollutant Pollutant name or NULL for static layers
#' @param marker_labels Label visibility setting
#' @param layer_id Layer identifier (not used for detection)
#' @return Character vector of labels
#' @keywords internal
generate_marker_labels <- function(data, pollutant, marker_labels, layer_id) {
  show_values <- marker_labels %in% c(TRUE, "values_on")
  show_custom <- marker_labels %in% c("labels", "labels_on")

  if (!show_values && !show_custom) {
    return(rep("", nrow(data)))
  }

  # School data: detect via School column
  if ("School" %in% names(data)) {
    return(as.character(data$School))
  }

  # Custom labels (Label column)
  if (show_custom) {
    if ("Label" %in% names(data)) {
      return(as.character(data$Label))
    }
    # Fallback: show pollution values if available
    if (!is.null(pollutant) && pollutant %in% names(data)) {
      warning(
        "marker_labels set to '",
        marker_labels,
        "' but no Label column found. Showing pollution values instead.",
        call. = FALSE
      )
      return(ifelse(
        is.na(data[[pollutant]]),
        "",
        paste(round(data[[pollutant]], 0), "µg/m³")
      ))
    }
    warning(
      "marker_labels set to '",
      marker_labels,
      "' but no Label column found. No labels will be shown.",
      call. = FALSE
    )
    return(rep("", nrow(data)))
  }

  # Pollution values
  if (show_values && !is.null(pollutant) && pollutant %in% names(data)) {
    return(ifelse(
      is.na(data[[pollutant]]),
      "",
      paste(round(data[[pollutant]], 0), "µg/m³")
    ))
  }

  rep("", nrow(data))
}


#' Take one layer's rows for one time step
#'
#' The literal year "static" means a layer that does not vary over time
#' (schools, for instance), so all of its rows are returned unfiltered.
#'
#' @param layer_id Layer identifier
#' @param year Time step string, or "static"
#' @param spatial_data Loaded data from [load_spatial_data_sources()]
#' @return The matching rows
#' @keywords internal
get_layer_year_data <- function(layer_id, year, spatial_data) {
  data_source <- spatial_data$all_data[[layer_id]]

  if (year != "static") {
    data_source[data_source$year_str == year, ]
  } else {
    data_source
  }
}


# == 10. Map assembly =========================================================

#' Add boundary polygons to map
#'
#' Adds borough boundary polygons with optional labels
#'
#' @param map Leaflet map object
#' @param borough_sf Borough spatial data
#' @param interactive If TRUE, for interactive HTML map; if FALSE, for static export
#' @param show_labels If TRUE, show borough labels on the map
#' @return Modified map with boundary polygons
#' @family map
add_boundary_polygons <- function(
  map,
  borough_sf,
  interactive,
  show_labels = FALSE
) {
  styles <- load_yaml_config("boundary-styles")
  style <- styles[[if (interactive) "interactive" else "static"]]

  if (show_labels) {
    label <- ~NAME
    labelOptions <- labelOptions(
      style = list(
        "font-weight" = "bold",
        padding = "3px 8px",
        "background-color" = "rgba(255,255,255,0.7)",
        "border-color" = "rgba(0,0,0,0.1)",
        "border-radius" = "4px"
      ),
      textsize = "12px",
      direction = "auto",
      noHide = TRUE
    )
  } else {
    label <- NULL
    labelOptions <- NULL
  }

  map |>
    addPolygons(
      data = borough_sf,
      color = style$color,
      weight = style$weight,
      dashArray = style$dashArray,
      opacity = style$opacity,
      fillColor = style$fillColor,
      fillOpacity = style$fillOpacity,
      label = label,
      labelOptions = labelOptions
    )
}

#' Add boundary, viewport and time machinery to the map
#'
#' Everything that goes on the map after the data layers: the boundary
#' polygons, the viewport, the JavaScript that drives the time control, and the
#' vignette last so that it sits above the markers it dims.
#'
#' Which JavaScript is attached depends on how the map was built. With a lazy
#' payload (item 6) the temporal markers are Canvas shapes restyled per step
#' from the embedded JSON, so the lazy controller is attached and there are no
#' per-step Leaflet layers to cache. Otherwise the layers were pre-built and
#' the smaller layer-cache script is enough.
#'
#' @inheritParams finalize_and_save_map
#' @return The map with controls added
#' @keywords internal
add_map_controls <- function(
  map,
  borough_sf = NULL,
  vignette_overlay = NULL,
  vignette = FALSE,
  bbox,
  interactive = TRUE,
  display_times,
  boundary_labels = FALSE,
  zoom_level = NULL,
  lazy_payload = NULL
) {
  # Handle "static_only" case (no temporal layers - only schools)
  if (identical(display_times, "static_only")) {
    display_times <- "2024"
  }

  if (is.null(display_times)) stop("display_times parameter is required")
  if (is.null(bbox)) stop("bbox parameter is required")

  if (!is.null(borough_sf)) {
    map <- add_boundary_polygons(
      map,
      borough_sf,
      interactive,
      show_labels = boundary_labels
    )
  }

  options <- list(padding = c(5, 5))
  map <- map |>
    fitBounds(
      lng1 = unname(bbox["xmin"]),
      lat1 = unname(bbox["ymin"]),
      lng2 = unname(bbox["xmax"]),
      lat2 = unname(bbox["ymax"]),
      options = options
    )

  if (!is.null(zoom_level)) {
    center_lng <- mean(c(unname(bbox["xmin"]), unname(bbox["xmax"])))
    center_lat <- mean(c(unname(bbox["ymin"]), unname(bbox["ymax"])))
    map <- map |> setView(lng = center_lng, lat = center_lat, zoom = zoom_level)
  }

  # NOTE: addLayersControl() removed - it hides inactive groups before onRender,
  # making layers inaccessible to JavaScript caching
  baseGroups <- if (interactive && length(display_times) >= 1)
    display_times else NULL
  if (!is.null(lazy_payload)) {
    # Lazy path (item 6): temporal markers are Canvas-rendered and restyled
    # per step from the embedded payload; no per-step layer cache exists
    map <- map |>
      htmlwidgets::onRender(load_lazy_controller_js(), data = lazy_payload)
    # 7 significant digits (~1 m coordinate precision) instead of the
    # htmlwidgets default 16, which serializes 22.8 as 22.800000000000001
    attr(map$x, "TOJSON_ARGS") <- list(digits = 7)
  } else if (!is.null(baseGroups)) {
    map <- map |>
      htmlwidgets::onRender(load_layer_cache_js())
  }

  if (vignette && !is.null(vignette_overlay)) {
    vignette_style <- load_yaml_config("vignette-style")
    map <- map |>
      addPolygons(
        data = vignette_overlay,
        fillColor = vignette_style$fillColor,
        fillOpacity = vignette_style$fillOpacity,
        color = vignette_style$color,
        weight = vignette_style$weight
      )
  }

  return(map)
}

#' @keywords internal
create_base_map <- function(data, interactive = TRUE, base_tiles = NULL) {
  map <- leaflet(
    data,
    options = leafletOptions(
      zoomControl = interactive,
      zoomDelta = 0.5,
      zoomSnap = 0
    )
  )

  if (!is.null(base_tiles)) {
    map |> addProviderTiles(base_tiles)
  } else {
    map |> addTiles()
  }
}

#' Draw every enabled layer onto a map for one time step
#'
#' Temporal layers are filtered to `target_year` and added as a Leaflet group
#' named after that step, which is how the time control shows one step at a
#' time. Static layers carry no group and are drawn once; passing
#' `target_year = "static_only"` adds those alone.
#'
#' @param base_map Map to add to
#' @param measurement_layers Layer configuration from [get_measurement_layers()]
#' @param target_year Time step, or "static_only" for static layers only
#' @param pollutant Pollutant column name
#' @param colour_scale Name of the colour scale
#' @param spatial_data Loaded layers from [load_spatial_data_sources()]
#' @param image_scale_factor Symbol scaling for static export
#' @param label_scale Multiplier on the marker-label text size. 1 is the
#'   default and needs no correction for export size: labels are expressed in
#'   `rem` and the export scales the root, exactly as it does for banner,
#'   legend and year label. Raise it only to depart deliberately from the
#'   legend's own scale — see the `map.label_scale` theme key.
#' @return The map with this step's layers added
#' @keywords internal
generate_map_layers <- function(
  base_map,
  measurement_layers,
  target_year,
  pollutant,
  colour_scale,
  spatial_data,
  image_scale_factor = 1.0,
  label_scale = 1.0,
  label_background = TRUE
) {
  # Symbols still need the export factor — they are drawn as sized SVG. Labels
  # do not: they are rem, and the export has already scaled the root.
  label_sizing <- label_scale
  for (layer_name in names(measurement_layers)) {
    layer_config <- measurement_layers[[layer_name]]
    if (!layer_config$enabled) next

    if (!layer_config$static) {
      if (target_year != "static_only") {
        year_data <- get_layer_year_data(
          layer_config$id,
          target_year,
          spatial_data
        )
        if (nrow(year_data) == 0) next

        # Filter missing pollution data (non-static layers have pollution data)
        year_data <- dplyr::filter(year_data, !is.na(.data[[pollutant]]))
        if (nrow(year_data) == 0) next

        layer_data <- prepare_generic_layer_data(
          layer_config,
          year_data,
          pollutant,
          colour_scale
        )
        if (!is.null(layer_data)) {
          show_labels <- if (!is.null(layer_config$options))
            layer_config$options$marker_labels else FALSE

          base_map <- add_layer(
            base_map,
            layer_data,
            layer_config,
            target_year,
            pollutant,
            colour_scale,
            label_sizing,
            image_scale_factor,
            marker_labels = show_labels,
            label_background
          )
        }
      }
    } else {
      static_data <- spatial_data$all_data[[layer_config$id]]
      layer_data <- prepare_generic_layer_data(layer_config, static_data)

      show_labels <- if (!is.null(layer_config$options))
        layer_config$options$marker_labels else FALSE

      base_map <- add_layer(
        base_map,
        layer_data,
        layer_config,
        year = NULL,
        pollutant = NULL,
        colour_scale = colour_scale,
        label_sizing,
        image_scale_factor,
        marker_labels = show_labels,
        label_background
      )
    }
  }
  # Show the target year group (last year processed = most recent)
  if (!is.null(target_year) && target_year != "static_only") {
    base_map <- base_map |> showGroup(target_year)
  }
  return(base_map)
}

# == 11. Orchestration ========================================================

#' Normalise the export_image argument
#'
#' `export_image` is deliberately loose for the user's sake: NULL for no image,
#' TRUE for the default size, or `c(width, height)`. This turns all three into
#' one shape the rest of the code can rely on.
#'
#' @param export_image NULL, TRUE, or c(width, height)
#' @return List of `enabled`, `width` and `height`
#' @keywords internal
parse_export_params <- function(export_image) {
  if (is.null(export_image)) {
    list(enabled = FALSE, width = IMAGE_X, height = IMAGE_Y)
  } else if (isTRUE(export_image)) {
    list(enabled = TRUE, width = IMAGE_X, height = IMAGE_Y)
  } else {
    list(enabled = TRUE, width = export_image[1], height = export_image[2])
  }
}


#' Load every data source and return them as spatial layers
#'
#' Accepts sf objects (used as they are), RData files, and CSV files. A CSV is
#' treated as time-varying only when it has more than one time-shaped column
#' name: a single such column is far more likely to be a one-off measurement
#' set than an animation, and the user can override the guess with
#' `data_dynamic`.
#'
#' The returned list carries both the general `all_data`/`ids` pair used by the
#' current pipeline and the older positional `dt`/`sensor`/`school` slots (first,
#' second and third source), which pre-v0.9.2 callers still read.
#'
#' @param data_sources List of file paths and/or sf objects
#' @param data_ids Layer names; NULL derives them from the file names
#' @param data_dynamic Logical vector overriding the time-varying guess
#' @param pollutant Pollutant name, for RData loading
#' @return List with `all_data` (named list of sf layers), `ids`, and the
#'   legacy positional slots
#' @keywords internal
load_spatial_data_sources <- function(
  data_sources,
  data_ids = NULL,
  data_dynamic = NULL,
  pollutant = "no2"
) {
  loaded_data <- list()

  # 1. Auto-generate IDs if not provided
  if (is.null(data_ids)) {
    data_ids <- sapply(seq_along(data_sources), function(i) {
      src <- data_sources[[i]]
      if (inherits(src, "sf")) {
        paste0("layer_", i)
      } else {
        tools::file_path_sans_ext(basename(src))
      }
    })
  }

  for (i in seq_along(data_sources)) {
    data_src <- data_sources[[i]]
    layer_id <- data_ids[i]

    # Handle sf objects directly
    if (inherits(data_src, "sf")) {
      loaded_data[[layer_id]] <- data_src
      next
    }

    # 2. Handle RData files
    if (grepl("\\.Rdata$", data_src, ignore.case = TRUE)) {
      loaded_data[[layer_id]] <- load_data_file(
        data_src,
        "rdata",
        pollutant = pollutant
      )
    } else {
      # 3. Handle CSV files
      # This explicitly treats empty strings as NA to prevent 'NULL' returns on missing data
      result <- load_data_file(
        data_src,
        "csv",
        c("Easting", "Northing")
      )

      if (!is.null(result)) {
        csv_data <- result$data
        cols <- names(csv_data)

        # 4. FIXED LOGIC: Detect Time-Series Structure
        # Pattern catches '2026', '2026-01-01', or '26-10-01'
        time_pattern <- "^(\\d{4}|\\d{2}-\\d{2}-\\d{2})"
        time_cols <- grep(time_pattern, cols)

        is_temporal <- if (!is.null(data_dynamic)) {
          # Use [[i]] to get the logical value, not a list subset
          data_dynamic[[i]]
        } else {
          # A file is ONLY temporal if it has multiple time-step columns.
          # We ignore pollutant names here because they indicate static data.
          length(time_cols) > 1
        }

        # 5. Process based on detected type
        if (is_temporal) {
          # Ensure time columns are numeric (critical for missing values like your 2017 data)
          csv_data[time_cols] <- lapply(
            csv_data[time_cols],
            function(x) as.numeric(as.character(x))
          )

          loaded_data[[layer_id]] <- get_temporal_data(csv_data) |>
            transform_to_wgs84()
        } else {
          loaded_data[[layer_id]] <- csv_data |> transform_to_wgs84()
        }
      }
    }
  }

  # 6. Legacy compatibility and Output
  # Helper to safely grab layers by index
  get_layer <- function(idx) {
    if (length(data_ids) >= idx) loaded_data[[data_ids[idx]]] else NULL
  }

  list(
    dt = get_layer(1),
    sensor = get_layer(2),
    school = get_layer(3),
    dt_enabled = !is.null(get_layer(1)),
    sensor_enabled = !is.null(get_layer(2)),
    school_enabled = !is.null(get_layer(3)),
    all_data = loaded_data,
    ids = data_ids
  )
}


#' Decide which time steps to show and where the map should look
#'
#' The time steps come from the first time-varying layer: with several such
#' layers one has to set the animation's steps, and the first is the one the
#' user listed first. A map with no time-varying layer at all is marked
#' "static_only", which suppresses the time control downstream.
#'
#' The viewport follows the boundary when there is one, and otherwise the
#' combined extent of the data (boroughs became optional in v0.9.9.6).
#'
#' @param spatial_data Loaded layers from [load_spatial_data_sources()]
#' @param borough_sf Boundary polygons, or NULL
#' @param vignette Logical; whether the dimming shape is wanted
#' @param requested_times The user's `display_times`, or NULL for all
#' @return List of `primary_data`, `display_times`, `vignette_overlay` and
#'   `bbox`
#' @keywords internal
determine_times_and_viewport <- function(
  spatial_data,
  borough_sf,
  vignette,
  requested_times
) {
  # Find first temporal (non-static) layer to determine available time periods
  temporal_layers <- Filter(
    function(x) !is.null(x) && "year_str" %in% names(x),
    spatial_data$all_data
  )

  primary_data <- if (length(temporal_layers) > 0) {
    temporal_layers[[1]]
  } else {
    NULL
  }

  # boroughs are optional (2026-07-10): without a boundary the viewport
  # fits the data and there is nothing to vignette
  vignette_overlay <- if (vignette && !is.null(borough_sf)) {
    create_vignette_overlay(borough_sf)
  }
  bbox <- if (!is.null(borough_sf)) {
    st_bbox(borough_sf)
  } else {
    layer_boxes <- lapply(
      Filter(Negate(is.null), spatial_data$all_data),
      st_bbox
    )
    if (length(layer_boxes) == 0) {
      stop("No data layers to fit the map to and no boroughs given.",
           call. = FALSE)
    }
    structure(
      c(
        xmin = min(vapply(layer_boxes, `[[`, 0, "xmin")),
        ymin = min(vapply(layer_boxes, `[[`, 0, "ymin")),
        xmax = max(vapply(layer_boxes, `[[`, 0, "xmax")),
        ymax = max(vapply(layer_boxes, `[[`, 0, "ymax"))
      ),
      class = "bbox"
    )
  }

  if (is.null(primary_data)) {
    display_times <- requested_times %||% "static_only"
  } else {
    available_times <- unique(primary_data$year_str)
    display_times <- if (is.null(requested_times)) {
      available_times
    } else {
      intersect(requested_times, available_times)
    }
    if (length(display_times) == 0) {
      warning(
        "None of the requested display_times match the data. Available: ",
        paste(sort(available_times), collapse = ", "),
        call. = FALSE
      )
    }
  }

  list(
    primary_data = primary_data,
    display_times = display_times,
    vignette_overlay = vignette_overlay,
    bbox = bbox
  )
}

#' Create interactive and/or static pollution maps
#'
#' Main function to create Leaflet maps showing air pollution data with optional
#' schools overlay. Generates both interactive HTML maps and static JPG exports.
#'
#' @param data_sources List of file paths or sf objects. Files can be CSV (diffusion tubes, schools)
#'   or RData (sensor data). Prepends DATA_PATH if set.
#' @param data_ids Character vector of layer IDs (default: NULL, auto-generated from filenames).
#' @param data_symbols Character vector of marker symbols, one per layer
#'   (default: NULL — layer shape metadata, else the automatic cycle).
#'   Accepts the friendly names "circle", "diamond", "cross", "square",
#'   "triangle", "star", "plus" and every renderer symbol name (18 in all;
#'   an unknown name errors with the full list).
#' @param data_dynamic Logical vector indicating temporal (TRUE) vs static (FALSE) layers (default: NULL, auto-detected).
#' @param attributions Character vector of source credits to print beneath
#'   the legend, collected from the layers' `attribution` metadata.
#' @param output_file Output file name, used verbatim (include the .html
#'   extension). Saved to the 'aq_maps/' directory; NULL returns the widget
#'   without writing a file.
#' @param export_image NULL (no export), TRUE (export 1200x1200), or c(width, height) vector for custom dimensions.
#' @param boroughs Borough name(s) for boundary display. NULL (default) draws
#'   no boundary and fits the map to the data.
#' @param pollutant Pollutant type: "no2" or "pm25" (default: "no2").
#' @param display_times Time periods to display (e.g., "2023", "2023-01", "2023-01-15 10:00").
#'   NULL uses all available periods from data. Must match year_str format in data.
#' @param title Page title and banner text. Default: NULL (uses theme).
#' @param vignette If TRUE, darkens areas outside borough(s). Default: NULL (uses theme).
#' @param colour_scale Color scale name (default: "who_no2"). See \code{load_colour_scale()} for options.
#' @param styling_type Controls banner/legend display: "html" (default) or "none".
#' @param marker_labels Label visibility: FALSE, TRUE (hover), "values_on" (always), "labels" (custom/hover),
#'   "labels_on" (custom/always). Default: NULL (uses theme). Content: School/Label/pollutant columns.
#' @param banner_colour Color for banner and vignette. Default: NULL (uses theme).
#' @param boundary_labels If TRUE, shows borough boundary labels. Default: NULL (uses theme).
#' @param autoplay Auto-start year animation on load. Default: NULL (uses theme).
#' @param play_speed Milliseconds per time step during animation. Default:
#'   NULL, which uses the theme, and failing that a pace set by how many steps
#'   there are (1200ms for 12 or fewer, 800ms up to 60, 450ms above). The
#'   viewer can scale whatever this ends up being with the speed button on the
#'   map, from a quarter of it to eight times.
#' @param theme_file Path to YAML theme file (default: NULL). See inst/themes/ for examples.
#' @param wind Wind data for the particle overlay: a \code{from_worldmet()}
#'   object or a data frame of date/ws/wd. Interactive HTML only.
#'
#' @return Invisible Leaflet map object. Side effects: Saves HTML to \code{aq_maps/}.
#'   If \code{export_image} is not NULL, also saves JPG files (one per year).
#'
#' @details
#' \strong{Data Files:} CSV files (diffusion tubes, schools) require Easting/Northing columns.
#' RData files (sensors) are searched for a compatible data.frame by column, whatever the object
#' is called (see \code{load_rdata_file()}). School data auto-detected by School column.
#'
#' \strong{Coordinates:} Input British National Grid (EPSG:27700), output WGS84 (EPSG:4326).
#'
#' \strong{Setup:} Set \code{Sys.setenv(DATA_PATH = "~/path/to/data")} before use.
#'
#' \strong{Symbols:} Auto-assigned by data type. Override with data_symbols parameter.
#'
#' @examples
#' # Basic interactive map (annual)
#' Sys.setenv(DATA_PATH = "~/data")
#' create_pollution_map(
#'   data_sources = list("wandsworth_2017_2024.csv", "schools_Wandsworth.csv"),
#'   boroughs = "Wandsworth",
#'   display_times = "2024",
#'   output_file = "wandsworth_2024.html"
#' )
#'
#' # Monthly data (sub-annual)
#' create_pollution_map(
#'   data_sources = list("sensor_monthly.Rdata"),
#'   boroughs = "Merton",
#'   display_times = c("2024-01", "2024-02", "2024-03"),
#'   output_file = "merton_q1_2024"
#' )
#'
#' @note
#' Year columns in CSV files must be YYYY format (e.g., "2024").
#' Static JPG exports require Chrome/Chromium for webshot2.
#'
#' @family map
#' @keywords internal
render_pollution_map <- function(
  data_sources = NULL,
  data_ids = NULL,
  data_symbols = NULL,
  data_dynamic = NULL,
  attributions = NULL,
  output_file = "pollution_map.html",
  export_image = NULL,
  boroughs = NULL,
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
  # -- 1. Settings ---------------------------------------------------------
  # An explicit argument always wins over the theme file; the theme fills in
  # everything the caller left NULL. This is what lets a one-line call work.
  if (!styling_type %in% c("html", "none")) {
    stop('styling_type must be "html" or "none".', call. = FALSE)
  }
  c(image_export, map_width_px, map_height_px) %<-%
    parse_export_params(export_image)
  show_banner <- (styling_type == "html")
  theme <- load_theme(theme_file)
  c(
    title,
    vignette,
    banner_colour,
    boundary_labels,
    marker_labels,
    autoplay,
    play_speed,
    base_tiles_provider
  ) %<-%
    list(
      title %||% theme$banner$title,
      vignette %||% theme$map$vignette,
      banner_colour %||% theme$banner$background,
      boundary_labels %||% theme$map$boundary_labels,
      marker_labels %||% theme$map$marker_labels,
      autoplay %||% theme$controls$autoplay,
      play_speed %||% theme$controls$play_speed,
      theme$map$base_tiles
    )
  banner_style <- theme$banner$style %||% "strip"
  wind_style <- theme$wind

  # -- 2. Boundary ---------------------------------------------------------
  # boroughs are optional (2026-07-10): NULL means no boundary is drawn,
  # the viewport fits the data, and the vignette is meaningless
  if (is.null(boroughs)) {
    borough_sf <- NULL
    vignette <- FALSE
  } else {
    borough_sf <- get_boundary_sf(boroughs)
    if (is.null(borough_sf)) return()
  }

  if (!dir.exists("aq_maps")) dir.create("aq_maps", showWarnings = TRUE)

  # -- 3. Data, time steps and viewport ------------------------------------
  spatial_data <- load_spatial_data_sources(
    data_sources,
    data_ids,
    data_dynamic,
    pollutant
  )

  c(primary_data, display_times, vignette_overlay, bbox) %<-%
    determine_times_and_viewport(
      spatial_data,
      borough_sf,
      vignette,
      display_times
    )
  display_times <- apply_time_step_cap(display_times)

  # Resolved here rather than with the other settings above because it needs
  # the step count, which is only known once the times are determined and
  # capped. An explicit argument or theme value has already filled it in.
  play_speed <- play_speed %||%
    default_play_speed(length(unique(display_times)))

  legend_info <- get_colour_legend(colour_scale)

  # -- 4. Base maps --------------------------------------------------------
  # Two are built when an image is wanted: the interactive one, and a
  # non-interactive template reused as the starting point for every JPG frame.
  # Use primary data for base map, or borough boundary if no temporal data
  base_map_data <- primary_data %||% borough_sf
  html_map <- create_base_map(base_map_data, TRUE, base_tiles_provider)

  if (image_export) {
    static_map_template <- create_base_map(
      base_map_data,
      FALSE,
      base_tiles_provider
    )
  }

  measurement_layers <- get_measurement_layers(
    spatial_data,
    marker_labels,
    data_symbols
  )

  data_max <- get_data_maximum(
    measurement_layers,
    pollutant,
    spatial_data,
    display_times
  )

  # Aggregate indicator: NULL when switched off in the theme, and NULL anyway
  # for anything but an annual map (see build_indicator_data)
  indicator <- if (isTRUE(theme$indicator$show)) {
    build_indicator_data(
      measurement_layers,
      spatial_data,
      display_times,
      pollutant
    )
  }
  # Reference layers carry no value, so they get no place on the colour ramp.
  # Where one has categories (schools by Level) they are named in the banner,
  # which is also what lets the map labels drop "Primary School" and stay
  # readable at print size.
  banner_key <- build_banner_key(measurement_layers, spatial_data)

  indicator_label <- theme$indicator$label
  indicator_show_max <- isTRUE(theme$indicator$show_max)
  indicator_placement <- theme$indicator$placement %||% "right"

  marker_scale_factor <- if (image_export) {
    sqrt((map_width_px * map_height_px) / (1200 * 1200))
  } else NULL

  # Marker labels follow the export scaling (they used to sit at a flat 12px,
  # so a 4000px print had scaled symbols and unscaled labels). label_scale is
  # the further push a given page size needs: symbol scaling alone leaves a
  # 4000px image at about 4.7pt on A4, which is below what prints legibly.
  label_scale <- theme$map$label_scale %||% 1
  label_background <- theme$map$label_background %||% TRUE

  # -- 5. Layers -----------------------------------------------------------
  # Lazy path (item 6): above the size/step thresholds the interactive map
  # embeds one compact JSON payload restyled in JS instead of pre-building
  # per-step hidden layers. Static image export always uses the pre-built
  # path (one non-interactive map per step; webshot never sees JS restyling).
  lazy <- !identical(display_times, "static_only") &&
    use_lazy_rendering(
      length(unique(display_times)),
      count_temporal_rows(
        measurement_layers, spatial_data, display_times, pollutant
      )
    )

  lazy_payload <- NULL
  if (lazy) {
    lazy_payload <- build_lazy_payload(
      measurement_layers,
      spatial_data,
      display_times,
      pollutant,
      colour_scale
    )
    html_map <- generate_map_layers(
      html_map,
      measurement_layers,
      "static_only",
      pollutant,
      colour_scale,
      spatial_data,
      1.0
    )
  }

  # One pass per time step. The same loop feeds both outputs (CLAUDE.md,
  # "Single Loop Processing"): the interactive map gains a layer group per
  # step, and each JPG is a complete map saved and screenshotted on its own.
  for (yr in unique(display_times)) {
    if (!lazy) {
      html_map <- generate_map_layers(
        html_map,
        measurement_layers,
        yr,
        pollutant,
        colour_scale,
        spatial_data,
        1.0
      )
    }

    if (image_export) {
      static_map <- add_year_and_static_layers(
        static_map_template,
        yr,
        measurement_layers,
        pollutant,
        colour_scale,
        spatial_data,
        marker_scale_factor,
        label_scale,
        label_background
      )

      file_parts <- tools::file_path_sans_ext(basename(output_file))
      html_file <- file.path("aq_maps", paste0(file_parts, "_", yr, ".html"))

      finalize_and_save_map(
        static_map,
        html_file,
        borough_sf,
        vignette_overlay,
        vignette,
        bbox,
        FALSE,
        yr,
        boundary_labels,
        theme$map$zoom_level,
        title,
        styling_type,
        show_banner,
        banner_colour,
        colour_scale,
        autoplay,
        play_speed,
        data_max,
        c(map_width_px, map_height_px),
        NULL,
        banner_style,
        indicator,
        indicator_label,
        indicator_show_max,
        indicator_placement,
        banner_key,
        attributions
      )
    }
  }

  # -- 6. Wind overlay -----------------------------------------------------
  # (item 7): interactive map only — a particle animation has
  # no meaning in a static JPG frame
  if (!is.null(wind) && !identical(display_times, "static_only")) {
    html_map <- add_wind_layer(
      html_map,
      as_qm_wind(wind),
      display_times,
      bbox,
      wind_style
    )
  }

  # -- 7. Save -------------------------------------------------------------
  # With no output_file the widget is returned unsaved, for a user working at
  # the console or knitting the map into a document.
  if (!is.null(output_file)) {
    html_file <- file.path("aq_maps", output_file)

    html_map <- finalize_and_save_map(
      html_map,
      html_file,
      borough_sf,
      vignette_overlay,
      vignette,
      bbox,
      TRUE,
      display_times,
      boundary_labels,
      theme$map$zoom_level,
      title,
      styling_type,
      show_banner,
      banner_colour,
      colour_scale,
      autoplay,
      play_speed,
      data_max,
      NULL,
      lazy_payload,
      banner_style,
      indicator,
      indicator_label,
      indicator_show_max,
      indicator_placement,
      banner_key,
      attributions
    )
  } else {
    html_map <- add_map_controls(
      html_map,
      borough_sf,
      vignette_overlay,
      vignette,
      bbox,
      TRUE,
      display_times,
      boundary_labels,
      theme$map$zoom_level,
      lazy_payload
    )
  }

  return(invisible(html_map))
}

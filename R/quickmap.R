# quickmap - Air Quality Mapping for R
# Version 0.9.5  2026/07/04
# v0.9.5: R package installation - devtools::install() + library(quickmap)
# v0.9.4: Sub-annual temporal resolution - month/day/hour support, renamed years→display_times
# v0.9.3.21: RData duck typing - standard names, then any compatible data.frame

# NULL coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Constants
MISSING_DATA_THRESHOLD <- 20 # Percent - sites with more missing data are filtered
IMAGE_X <- 1200
IMAGE_Y <- 1200
IMAGE_AREA <- IMAGE_X * IMAGE_Y

# Helper functions for DRY code patterns
get_package_dir <- function(subdir) {
  dir <- system.file(subdir, package = "quickmap")
  if (dir == "") dir <- file.path("inst", subdir)
  return(dir)
}

read_template_file <- function(filepath) {
  paste(readLines(filepath, warn = FALSE), collapse = "\n")
}

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
  avg.time = "year"
) {
  # Validate inputs
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

  # Temporal aggregation using dplyr (preserves grouping columns)
  if (avg.time == "year") {
    # Annual aggregation
    data$year <- as.integer(format(data$date, "%Y"))
    data$year_str <- format(data$date, "%Y")

    aggregated <- data |>
      group_by(siteCode, year) |>
      summarise(
        !!sym(pollutant) := mean(!!sym(pollutant), na.rm = TRUE),
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

    aggregated <- data |>
      group_by(siteCode, period, year, year_str) |>
      summarise(
        !!sym(pollutant) := mean(!!sym(pollutant), na.rm = TRUE),
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

  # Add lat/lon aliases for compatibility
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

#' Load RData file with duck typing
#'
#' Three-strategy loader: (1) explicit data_object_name, (2) standard names
#' (dataOAformat/data/oa_data/sensor_data), (3) any compatible data.frame (largest)
#'
#' @param file_path Path to RData file (relative to DATA_PATH)
#' @param pollutant Pollutant name (e.g., "no2", "pm25")
#' @param data_object_name Optional: explicit object name in RData file
#' @return Processed sensor data
#' @keywords internal
# load_rdata_file <- function(file_path, pollutant, data_object_name = NULL) {
#   # Explicit param → standard names (dataOAformat/data/oa_data/sensor_data) → largest compatible data.frame
#   # Priority order ensures backward compatibility with OpenAir conventions while enabling duck typing for non-standard files
#   env <- new.env()
#   load(
#     file.path(Sys.getenv("DATA_PATH"), file_path),
#     envir = env,
#     verbose = TRUE
#   )

# obj_names <- ls(envir = env)
# required_cols <- c("siteCode", "year", pollutant, "lat", "lon")
#
# # Helper: validate and use object
# use_object <- function(obj, name) {
#   if (!is.data.frame(obj)) {
#     stop("Object '", name, "' is not a data.frame", call. = FALSE)
#   }
#   if (!all(required_cols %in% names(obj))) {
#     stop(
#       "Object '",
#       name,
#       "' missing columns: ",
#       paste(setdiff(required_cols, names(obj)), collapse = ", "),
#       call. = FALSE
#     )
#   }
#   message("Using sensor data: ", name, " (", nrow(obj), " rows)")
#
#   # If year_str exists, data is already processed (e.g., from convert_openair_to_spatial)
#   # Just convert to sf without re-aggregating (preserves sub-annual resolution)
#   if ("year_str" %in% names(obj)) {
#     sf_obj <- st_as_sf(obj, coords = c("lon", "lat"), crs = 4326)
#     coords <- st_coordinates(sf_obj)
#     sf_obj$Longitude <- coords[, 1]
#     sf_obj$Latitude <- coords[, 2]
#     return(sf_obj)
#   }
#
#   return(process_oa_data(obj, pollutant))
# }

# If Explicit user choice (if data_object_name specified)
#   if (!is.null(data_object_name)) {
#     if (!exists(data_object_name, envir = env)) {
#       stop(
#         "Object '",
#         data_object_name,
#         "' not found.\n",
#         "Available: ",
#         paste(obj_names, collapse = ", "),
#         call. = FALSE
#       )
#     }
#     return(use_object(get(data_object_name, envir = env), data_object_name))
#   }
#
#   # Else screen for standard names (backward compatible)
#   standard_names <- c("dataOAformat", "data", "sensor_data", "measurements")
#   for (sname in standard_names) {
#     if (exists(sname, envir = env)) {
#       obj <- get(sname, envir = env)
#       if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
#         return(use_object(obj, sname))
#       }
#     }
#   }
#
#   # Else duck typing (largest compatible data.frame)
#   compatible <- list()
#   for (obj_name in obj_names) {
#     obj <- get(obj_name, envir = env)
#     if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
#       compatible[[obj_name]] <- list(data = obj, nrow = nrow(obj))
#     }
#   }
#
#   if (length(compatible) == 0) {
#     stop(
#       "No compatible sensor data in: ",
#       basename(file_path),
#       "\n",
#       "Expected: data.frame with [",
#       paste(required_cols, collapse = ", "),
#       "]\n",
#       "Found: ",
#       paste(obj_names, collapse = ", "),
#       call. = FALSE
#     )
#   }
#
#   sizes <- sapply(compatible, function(x) x$nrow)
#   selected <- names(which.max(sizes))
#
#   if (length(compatible) > 1) {
#     message(
#       "Found ",
#       length(compatible),
#       " compatible objects, using largest: ",
#       selected
#     )
#   }
#
#   return(use_object(compatible[[selected]]$data, selected))
# }

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


get_temporal_data <- function(
  #
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
    map = list(
      vignette = TRUE,
      base_tiles = "CartoDB.Positron",
      zoom_level = NULL,
      boundary_labels = FALSE,
      marker_labels = FALSE
    ),
    controls = list(
      autoplay = FALSE,
      play_speed = 500,
      background = NULL,
      text_color = NULL
    ),
    # Item 10: wind-particle styling, threaded into the leaflet-velocity
    # payload (see build_wind_payload). colour_ramp maps to colorScale,
    # particle_density to particleMultiplier.
    wind = list(
      colour_ramp = c("#3288bd", "#66c2a5", "#abdda4", "#fee08b",
                      "#f46d43", "#d53e4f"),
      particle_density = 1 / 500,
      line_width = 1,
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

get_colour_legend <- function(scale = "lbrut_no2") {
  scale_data <- load_colour_scale(scale)

  list(
    colors = scale_data$colours,
    labels = scale_data$labels,
    title = scale_data$title,
    thresholds = scale_data$thresholds
  )
}

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
generate_legend_html <- function(
  scale_name,
  collapsed_mobile = TRUE,
  data_max = NULL
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

  if (!is.null(data_max) && !is.null(legend_scale$thresholds) && data_max > 0) {
    # Find which threshold index contains data_max
    # thresholds define breaks: [0, 10, 20, 30, 40, 50, 60, ...]
    # If data_max = 45, which(45 < thresholds) = [F,F,F,F,F,T,...] -> first TRUE at index 6 (threshold=50)
    # We want to show up to the range CONTAINING 45 (40-50), which is item 5, not item 6
    threshold_idx <- which(data_max < legend_scale$thresholds)[1]

    # Include all items up to and including the threshold containing data_max
    # Subtract 1 because threshold_idx is the NEXT threshold after data_max
    # Always include at least 2 items (minimum viable legend)
    num_items <- max(2, threshold_idx - 1)

    num_items <- min(num_items, length(legend_scale$colours))

    legend_scale$colours <- legend_scale$colours[1:num_items]
    legend_scale$labels <- legend_scale$labels[1:num_items]
  }

  hex_colors <- convert_colors_to_hex(legend_scale$colours)

  # Ramp legend (item 10, approved design): a thin row of colour blocks
  # with the range labels outside (below) the colours, plus the restyled
  # footnote-symbol key.
  symbol_index <- 1
  ramp_blocks <- list()
  ramp_labels <- list()
  symbol_key_items <- list()

  for (i in seq_along(hex_colors)) {
    parsed <- parse_legend_label(legend_scale$labels[i])
    text_color <- get_contrast_text_color(hex_colors[i])

    if (!is.null(parsed$description)) {
      symbol <- get_symbol_for_index(symbol_index)
      range_with_symbol <- paste0(parsed$range, " ", symbol)
      symbol_index <- symbol_index + 1

      symbol_key_items[[length(symbol_key_items) + 1]] <- sprintf(
        '      <span style="background: %s; color: %s;">%s</span>',
        hex_colors[i],
        text_color,
        paste(symbol, parsed$description)
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

  sprintf(
    html_template,
    legend_scale$title,
    legend_items_html,
    symbol_key_html,
    mobile_script
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

#' @keywords internal
add_year_and_static_layers <- function(
  template,
  year,
  measurement_layers,
  pollutant,
  colour_scale,
  spatial_data,
  scale_factor
) {
  template |>
    generate_map_layers(
      measurement_layers,
      year,
      pollutant,
      colour_scale,
      spatial_data,
      scale_factor
    ) |>
    generate_map_layers(
      measurement_layers,
      "static_only",
      pollutant,
      colour_scale,
      spatial_data,
      scale_factor
    )
}

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
  banner_style = "strip"
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
    banner_style
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
  banner_style = "strip"
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
      banner_style = banner_style
    )
  }

  files_folder <- paste0(tools::file_path_sans_ext(html_file), "_files")
  if (dir.exists(files_folder)) {
    unlink(files_folder, recursive = TRUE)
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
    return(sprintf(
      paste0(
        '\n<div id="yearControl" style="position: absolute; top: 1.2rem;',
        ' right: 1.2rem; z-index: 1000; background: rgba(255,255,255,0.95);',
        ' border: 1px solid #ddd; border-radius: 0.5rem;',
        ' padding: 0.45rem 0.9rem; font-weight: 650; font-size: 1.1rem;',
        ' font-family: system-ui, -apple-system, sans-serif;',
        ' box-shadow: 0 1px 4px rgba(0,0,0,0.15);">%s</div>\n'
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

  config_script <- sprintf(
    'window.quickmapConfig = {autoplay: %s, playSpeed: %d};',
    tolower(as.character(autoplay)),
    as.integer(play_speed)
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

    key <- if ("siteCode" %in% names(d)) {
      as.character(d$siteCode)
    } else {
      paste(d$Longitude, d$Latitude)
    }
    first <- !duplicated(key)
    ukey <- key[first]
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

  list(
    times = I(times),
    thresholds = I(scale_data$thresholds[finite]),
    colours = I(colours_hex[finite]),
    naColour = colours_hex[length(colours_hex)],
    layers = layers
  )
}

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
  banner_style = "strip"
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
      '<div class="banner">%s</div>\n<div class="map-container">\n',
      title
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

  legend_html <- generate_legend_html(scale_name, collapsed_mobile, data_max)

  combined_html <- paste0(time_control_html, "\n", legend_html)
  html_text <- sub("</body>", paste0(combined_html, "</body>"), html_text)

  writeLines(html_text, html_file)

  return(invisible(TRUE))
}

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
    # note
    values = rep(1, length(colors)),
    shape = shape_config$shape,
    color = if (is_nonsolid) colors else "#ffffff",
    fillColor = colors,
    baseSize = shape_config$size,
    fillOpacity = 0.75,
    #   stroke = TRUE,
    #  weight = 10,
    strokeWidth = 2,
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
  marker_labels = FALSE
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

  label_text_size <- as.character(12 * label_sizing)

  # Always-visible labels for values_on/labels_on
  no_hide <- marker_labels %in% c("values_on", "labels_on")

  label_opts <- labelOptions(
    noHide = no_hide,
    direction = "bottom",
    offset = c(0, 12),
    textOnly = TRUE,
    textsize = label_text_size,
    style = list(
      "background-color" = "rgba(255,255,255,0.5)",
      "padding" = "1px",
      "border-radius" = "3px",
      "border" = "1px solid rgba(0,0,0,0.1)"
    )
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
        paste(round(data[[pollutant]], 0), "ug/m3")
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
      paste(round(data[[pollutant]], 0), "ug/m3")
    ))
  }

  rep("", nrow(data))
}


get_layer_year_data <- function(layer_id, year, spatial_data) {
  data_source <- spatial_data$all_data[[layer_id]]

  if (year != "static") {
    data_source[data_source$year_str == year, ]
  } else {
    data_source
  }
}


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

#' @keywords internal
generate_map_layers <- function(
  base_map,
  measurement_layers,
  target_year,
  pollutant,
  colour_scale,
  spatial_data,
  image_scale_factor = 1.0
) {
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
            label_sizing = 1.0,
            image_scale_factor,
            marker_labels = show_labels
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
        label_sizing = 1.0,
        image_scale_factor,
        marker_labels = show_labels
      )
    }
  }
  # Show the target year group (last year processed = most recent)
  if (!is.null(target_year) && target_year != "static_only") {
    base_map <- base_map |> showGroup(target_year)
  }
  return(base_map)
}

parse_export_params <- function(export_image) {
  if (is.null(export_image)) {
    list(enabled = FALSE, width = IMAGE_X, height = IMAGE_Y)
  } else if (isTRUE(export_image)) {
    list(enabled = TRUE, width = IMAGE_X, height = IMAGE_Y)
  } else {
    list(enabled = TRUE, width = export_image[1], height = export_image[2])
  }
}


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
#' @param data_symbols Character vector of marker symbols (default: NULL, auto-cycles through defaults).
#'   Valid: "circle", "diamond", "cross", "square", "triangle", "star", "plus".
#' @param data_dynamic Logical vector indicating temporal (TRUE) vs static (FALSE) layers (default: NULL, auto-detected).
#' @param output_file Output filename (without extension). Saved to 'aq_maps/' directory.
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
#' @param play_speed Milliseconds per year during animation. Default: NULL (uses theme).
#' @param theme_file Path to YAML theme file (default: NULL). See inst/themes/ for examples.
#'
#' @return Invisible Leaflet map object. Side effects: Saves HTML to \code{aq_maps/}.
#'   If \code{export_image} is not NULL, also saves JPG files (one per year).
#'
#' @details
#' \strong{Data Files:} CSV files (diffusion tubes, schools) require Easting/Northing columns.
#' RData files (sensors) require 'dataOAformat' object. School data auto-detected by School column.
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
  legend_info <- get_colour_legend(colour_scale)

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

  marker_scale_factor <- if (image_export) {
    sqrt((map_width_px * map_height_px) / (1200 * 1200))
  } else NULL

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
        marker_scale_factor
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
        banner_style
      )
    }
  }

  # Wind overlay (item 7): interactive map only — a particle animation has
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
      banner_style
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

# Working, stable production codebase for quickmap ####
# Version 0.9.0.2

#2345678901234567890123456789012345678901234567890123456789012345678901234567890 Hollerith limit

# Architecture: Unified single-loop processing generates both HTML and static images.
# Generic layer system: prepare_generic_layer_data() → create_generic_icons() → addMarkers()

# Version History:
#   v0.1-v0.6: Basic NO2 and schools data import, leaflet maps with year selectors,
#              CSV and OA format support, BL nodes as squares, year labels
#   v0.8: Refactor - Unified architecture with single-loop processing, generic layer system,
#         single marker-based architecture (circles=DT, diamonds=BL, crosses=schools),
#         configuration-driven layer system, integrated image export
#   v0.8.5: Code cleanup - simplified data loading, improved error handling, data validation
#   v0.8.7-v0.8.7.3: Unified banner/legend system with scaling, missing data filtering,
#                    static map zoom/initialization fixes
#   v0.8.8: Boundary labels control - Added boundary_labels parameter
#   v0.8.9: Marker labels control - Added marker_labels parameter (5-state control),
#          REMOVED use_data_labels parameter (breaking change)
#   v0.8.10: Fixed schools label behavior and OA data label fallback with warnings
#   v0.8.11: Borough colour palettes - Added nested named list structure for easy access,
#           Added show_borough_colours() helper function to display available colours
#   v0.9.0: Parameter simplification following OpenAir design patterns (BREAKING CHANGES)
#          Reduced from 21 to 14 parameters (33% reduction)
#          Renamed 6 parameters for clarity (removed "show_" prefixes)
#          Merged 7 parameters into 3 (image export, title, styling)
#          Removed leaflet legend/title controls (HTML-only styling system)
#          Removed 58 lines of code (2.3% reduction)
#   v0.9.0.1: UI fixes - Year control bottom-right, collapsed, defaults to latest year
#   v0.9.0.2: Touch-friendly collapsible year menu with dynamic banner-based theming

# Breaking Changes:
#   v0.8.9: use_data_labels parameter removed (replaced by marker_labels)
#           Old usage: use_data_labels = TRUE
#           New usage: marker_labels = TRUE (or "values_on", "labels", "labels_on")
#
#   v0.9.0: Major parameter refactoring - MIGRATION REQUIRED
#           See migration guide below for all changes

# Migration Guide v0.8.11 → v0.9.0:
#
#   RENAMED PARAMETERS (simple find/replace in your scripts):
#     OLD: years_to_plot = 2024            NEW: years = 2024
#     OLD: vignette_overlay_on = TRUE      NEW: vignette = TRUE
#     OLD: csv_data_file = "data.csv"      NEW: diffusion_tube_file = "data.csv"
#     OLD: oa_data_file = "sensors.Rdata"  NEW: sensor_file = "sensors.Rdata"
#     OLD: show_marker_labels = TRUE       NEW: marker_labels = TRUE
#     OLD: show_boundary_labels = FALSE    NEW: boundary_labels = FALSE
#
#   MERGED PARAMETERS:
#     Image Export (3 → 1):
#       OLD: image_export = TRUE, map_width_px = 1920, map_height_px = 1080
#       NEW: export_image = c(1920, 1080)
#       NEW: export_image = NULL  # for no export (replaces image_export = FALSE)
#
#     Title (2 → 1):
#       OLD: html_page_title = "Map", banner_text = "Dashboard"
#       NEW: title = "Dashboard"  # used for both browser tab and banner
#
#     Styling System (4 → 1):
#       OLD: show_banner = TRUE, show_title = FALSE, show_legend = FALSE, title_prefix = ""
#       NEW: styling_type = "html"  # HTML banner + legend
#       NEW: styling_type = "none"  # No banner or legend
#
#   REMOVED PARAMETERS:
#     - show_banner, show_title, show_legend, title_prefix (merged into styling_type)
#     - Leaflet legend and title controls removed (HTML system is superior)
#
#   FINAL PARAMETER COUNT: 14 (down from 21, 33% reduction)

# Core Functions:
#   create_pollution_map() - Main entry point, unified processing for HTML and static images
#   generate_map_layers() - Adds layers to map (handles temporal and static layers)
#   create_generic_icons() - Universal icon system for all layer types
#   get_measurement_layers() - Returns layer configuration (bl_nodes, dt_sites, schools)
#   prepare_generic_layer_data() - Prepares data for mapping based on layer type
#   generate_marker_labels() - Generates labels based on marker_labels parameter
#   add_layer() - Adds markers to map with label visibility control

# Configuration:
# Setup: Set DATA_PATH environment variable before sourcing
# Example: Sys.setenv(DATA_PATH = "~/path/to/data")
#
# Marker Sizing: Base sizes for 1200x1200px images (Schools:12px, DT/BL:20px)
# Scaling: Static images use geometric mean based on dimensions
#
# Available Color Scales: who_no2, stripes_no2, gla_pm25, lbw_no2, lbrut_no2, lbm_no2, deltas
#
# Static-Only Maps: Set diffusion_tube_file="none" and sensor_file="none" for schools-only maps
#
# Package Dependencies (auto-installed):
# Required: leaflet, sf, dplyr, leaflegend, tidyr, lubridate, stringr,
#          webshot2, htmlwidgets, htmltools, leaflet.extras

# Install and load required packages
packages <- c(
  "leaflet",
  "sf",
  "dplyr",
  "leaflegend",
  "tidyr",
  "lubridate",
  "stringr",
  "webshot2",
  "htmlwidgets",
  "htmltools",
  "leaflet.extras"
)

# Install missing packages
installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed])
}

# Load all packages
lapply(packages, library, character.only = TRUE)

# Note: Linter warnings for package functions are false positives.
# All required packages are loaded via lapply() above.
# Functions from dplyr, sf, leaflet, leaflegend, and other packages are available at runtime.

# Data quality threshold ####
# Sites with more than this percentage of missing data will be filtered out
# Used by process_oa_data() to remove low-quality site-years
# Modify this value to change quality filtering threshold
MISSING_DATA_THRESHOLD <- 20 # Percent

# function definitions ####

# Data validation functions
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

# Process OA data after validation
process_oa_data <- function(data, pollutant) {
  validate_oa_data(data, pollutant)

  # Filter out low-quality data based on missing data threshold
  # NOTE: Future enhancement - could display these as white disks with "Insufficient data" labels
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

  # Add coordinate columns
  coords <- st_coordinates(processed_data)
  processed_data$Longitude <- coords[, 1]
  processed_data$Latitude <- coords[, 2]

  return(processed_data)
}

# Unified data loader with consistent error handling
load_data_file <- function(
  file_path,
  file_type,
  required_cols = NULL,
  pollutant = NULL
) {
  if (file_path == "none") return(NULL)

  tryCatch(
    {
      switch(
        file_type,
        "csv" = import_csv_data(file_path, required_cols),
        "rdata" = load_rdata_file(file_path, pollutant),
        stop("Unknown file type: ", file_type)
      )
    },
    error = function(e) {
      warning(
        "Failed to load ",
        file_type,
        " file: ",
        file_path,
        "\n",
        e$message
      )
      return(NULL)
    }
  )
}

# Specialized RData loader
load_rdata_file <- function(file_path, pollutant) {
  load(file.path(Sys.getenv("DATA_PATH"), file_path), verbose = TRUE)

  if (!exists("dataOAformat")) {
    stop("dataOAformat object not found in RData file")
  }

  return(process_oa_data(dataOAformat, pollutant))
}

# Function to get temporal data columns and extract time periods
get_temporal_data <- function(data, time_pattern = "\\d{4}") {
  # Find columns that match the time pattern
  temporal_cols <- names(data)[grepl(time_pattern, names(data))]

  # Pivot and extract time periods
  data |>
    tidyr::pivot_longer(
      cols = all_of(temporal_cols),
      names_to = "time_col",
      values_to = "no2"
    ) |>
    dplyr::mutate(
      year = lubridate::as_datetime(paste0(
        stringr::str_extract(time_col, time_pattern),
        "-01-01"
      ))
    ) |>
    dplyr::select(-time_col)
}

#' Get maximum data value across all measurement layers
#'
#' Finds the highest pollutant value across all enabled temporal layers
#' (dt_sites and bl_nodes) for the specified years to determine what legend range to display
#'
#' @param measurement_layers Layer configuration from get_measurement_layers()
#' @param pollutant Pollutant name (for bl_nodes data)
#' @param data_env Environment containing data objects
#' @param years Character vector of year strings to include (e.g., c("2020", "2021"))
#' @return Single numeric value representing maximum across specified years and layers, or NULL if no data
get_data_maximum <- function(
  measurement_layers,
  pollutant,
  data_env,
  years = NULL
) {
  max_values <- c()

  for (layer_name in names(measurement_layers)) {
    layer_config <- measurement_layers[[layer_name]]

    # Only process enabled temporal layers (pollution data)
    if (!layer_config$enabled || !layer_config$temporal) next

    # Skip schools layer (no pollution data)
    if (layer_config$layer_type == "schools") next

    # Get data from environment
    data_source_name <- layer_config$data_source

    # Try to get data - use safer approach
    data <- tryCatch(
      get(data_source_name, envir = data_env, inherits = FALSE),
      error = function(e) NULL
    )

    if (is.null(data) || nrow(data) == 0) next

    # Filter by years if specified
    if (!is.null(years) && "year_str" %in% names(data)) {
      data <- data[data$year_str %in% years, ]
      if (nrow(data) == 0) next
    }

    # Determine which column contains pollutant values
    if (layer_config$layer_type == "dt_sites") {
      # Diffusion tubes use "no2" column (hardcoded in get_temporal_data)
      pollutant_col <- "no2"
    } else if (layer_config$layer_type == "bl_nodes") {
      # Breathe London uses pollutant parameter column
      pollutant_col <- pollutant
    } else {
      next
    }

    # Check column exists
    if (!pollutant_col %in% names(data)) next

    # Get maximum value, removing NAs
    layer_max <- max(data[[pollutant_col]], na.rm = TRUE)
    if (!is.infinite(layer_max) && !is.nan(layer_max)) {
      max_values <- c(max_values, layer_max)
    }
  }

  # Return maximum across all layers, or NULL if none found
  if (length(max_values) > 0) {
    result <- max(max_values)
    message(
      "Legend trimming: data_max = ",
      round(result, 2),
      " (from ",
      ifelse(
        is.null(years),
        "all years",
        paste(length(years), "selected years")
      ),
      ")"
    )
    return(result)
  } else {
    message("Legend trimming: No data found, showing full legend")
    return(NULL)
  }
}

# import and prepares the data from csv files in wide format
import_csv_data <- function(
  file_path,
  required_cols = c("Easting", "Northing")
) {
  # Handle CSV file paths consistently with RData files
  # If path is relative (doesn't start with / or ~), prepend DATA_PATH
  if (!grepl("^[/~]", file_path)) {
    file_path <- file.path(Sys.getenv("DATA_PATH"), file_path)
  }
  data <- read.csv(
    file_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA", "NaN")
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
  if (length(value_columns) == 0) {
    stop("No value columns found in data")
  }
  list(data = data, value_columns = value_columns)
}


# Helper function to retrieve boundary data (case-insensitive)
# TODO: Add input validation for boundary_names parameter to handle NULL, missing,
# or invalid input gracefully. Currently assumes input is always valid.
get_boundary_sf <- function(boundary_names, crs = 4326) {
  # Load boundary data
  load(file.path(Sys.getenv("DATA_PATH"), BOUNDARY_CONFIG$data_file))
  boundary_data <- get(BOUNDARY_CONFIG$data_object)

  # Standardise input and apply corrections
  input_names <- tools::toTitleCase(tolower(boundary_names))
  corrected_names <- ifelse(
    input_names %in% names(BOUNDARY_CONFIG$name_corrections),
    BOUNDARY_CONFIG$name_corrections[input_names],
    input_names
  )

  # Return all boundaries if "all" specified
  if (length(corrected_names) == 1 && tolower(corrected_names) == "all") {
    return(st_transform(boundary_data, crs = crs))
  }

  # Validate input names
  valid_names <- unique(tolower(boundary_data[[BOUNDARY_CONFIG$name_column]]))
  invalid_names <- corrected_names[!tolower(corrected_names) %in% valid_names]

  if (length(invalid_names) > 0) {
    all_names <- sort(unique(boundary_data[[BOUNDARY_CONFIG$name_column]]))
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

  # Filter and return selected boundaries
  boundary_data %>%
    filter(
      tolower(.data[[BOUNDARY_CONFIG$name_column]]) %in%
        tolower(corrected_names)
    ) %>%
    st_transform(crs = crs)
}

# helper function to convert from OS northings and eastings (CRS 27700) to standard
# latitude-longitude coordinates (CRS 4326) optionally adding year_str (probably
# not needed as moved to OA long data tables)
transform_to_wgs84 <- function(
  df,
  easting = "Easting",
  northing = "Northing",
  crs_from = 27700
) {
  tryCatch(
    {
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
    },
    error = function(e) {
      stop("Coordinate transformation failed: ", e$message)
    }
  )
}

# Create vignette overlay from extended bounding box
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

# Boundary data configuration ####
# Configures boundary loading and name handling
# name_corrections: Auto-corrects common borough name variations
# To add corrections, add entries to name_corrections vector below
BOUNDARY_CONFIG <- list(
  data_file = "ward_boundaries.Rdata",
  data_object = "wardBoundaries",
  name_column = "DISTRICT",
  name_corrections = c(
    "The City" = "City and County of the City of London",
    "Westminster" = "City of Westminster",
    "Kingston" = "Kingston upon Thames",
    "Richmond" = "Richmond upon Thames"
  )
)

# Map styling constants ####
# Edit these to customize map appearance

# Boundary polygons: dashed for interactive, solid for static
BOUNDARY_STYLES <- list(
  interactive = list(
    color = "#078141",
    weight = 2.5,
    dashArray = "5, 10",
    opacity = 0.75,
    fillColor = "transparent",
    fillOpacity = 0.1
  ),
  static = list(
    color = "#078141",
    weight = 2.5,
    dashArray = NULL,
    opacity = 1,
    fillColor = "transparent",
    fillOpacity = 0
  )
)

# Vignette: darkens area outside borough boundary (grey overlay at 40% opacity)
VIGNETTE_STYLE <- list(
  fillColor = "grey",
  fillOpacity = 0.4,
  color = "transparent",
  weight = 0
)

# Legend styling: font sizes and symbol dimensions
LEGEND_STYLE <- list(
  title = "font-size: 12px; font-weight:bold; margin: 2px 0; line-height: 1.4;",
  labels = "font-size: 12px; margin: 2px 0; line-height: 1.4; vertical-align: middle;",
  symbol_size = list(width = 15, height = 15),
  display_size = list(width = 12, height = 12)
)

# Title styling: semi-transparent background, responsive widths
TITLE_STYLES <- list(
  base = "background-color: rgba(255,255,255,0.8); padding: 2px 2px; border-radius: 3px; text-align: center; margin-top: 4px; line-height: 0.9; margin-left: auto; margin-right: auto;",
  interactive_width = "50vw",
  static_width = "95vw"
)

# Borough brand palettes ####
borough_palettes <- list(
  merton = list(
    purple = "#5F3E94",
    green = "#078141",
    black = "#000000",
    white = "#ffffff",
    cream = "#f5f7e3",
    lavender = "#DED4E9",
    lime = "#39b54a",
    pink = "#b94090"
  ),
  wandsworth = list(
    blue = "#01a7f5",
    white = "#ffffff",
    black = "#000000",
    navy = "#306cb2",
    orange = "#ff9c30",
    green = "#159b48",
    lime = "#83c44c"
  ),
  richmond = list(
    blue = "#005794",
    green = "#9bcc66",
    white = "#ffffff",
    black = "#000000",
    grey = "#e6e7e8"
  )
)

# Helper function to display available borough colours
show_borough_colours <- function(borough = NULL) {
  if (is.null(borough)) {
    cat(
      "Available boroughs:",
      paste(names(borough_palettes), collapse = ", "),
      "\n"
    )
    cat("Usage: show_borough_colours('merton')\n")
    return(invisible(NULL))
  }

  if (!borough %in% names(borough_palettes)) {
    stop(
      "Borough '",
      borough,
      "' not found. Available: ",
      paste(names(borough_palettes), collapse = ", ")
    )
  }

  colours <- borough_palettes[[borough]]
  cat("Colours for", borough, ":\n")
  for (name in names(colours)) {
    cat("  ", name, ": ", colours[[name]], "\n", sep = "")
  }
  cat(
    "\nUsage: borough_palettes$",
    borough,
    "$",
    names(colours)[1],
    "\n",
    sep = ""
  )
}

# Unified colour scale definitions ####
colour_scales <- list(
  stripes_no2 = list(
    colours = c(
      "#A4ffff",
      "#b0dae9",
      "#b0ceed",
      "#f9e047",
      "#f2c84b",
      "#f1a63f",
      "#e98725",
      "#af4553",
      "#863b47",
      "#462f30",
      "#252424",
      "white"
    ),
    thresholds = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, Inf),
    labels = c(
      "< 10: WHO guideline",
      "10-19: WHO Int 3",
      "20-29: WHO Int 2",
      "30-39: UK/WHO Int 1",
      "40-49: > UK",
      "50-60",
      "60-70",
      "70-80",
      "80-90",
      "90-100",
      "> 100",
      "Insufficient data"
    ),
    title = "NO2 annual mean, µg/m3",
    shape = "circle"
  ),
  stripes_pm25_ = list(
    colours = c(
      "#A4ffff",
      "#b0dae9",
      "#b0ceed",
      "#f9e047",
      "#f2c84b",
      "#f1a63f",
      "#e98725",
      "#af4553",
      "#863b47",
      "#462f30",
      "#252424",
      "white"
    ),
    thresholds = c(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, Inf),
    labels = c(
      "< 5: WHO guideline",
      "5-10: < GLA/WHO Int 4",
      "10-15: WHO Int 3",
      "15-20: UK",
      "20-25: WHO Int 2",
      "25-30",
      "30-35: WHO Int 1",
      "35-40",
      "40-45",
      "45-50",
      "Insufficient data"
    ),
    title = "PM<sub>2.5</sub>, µg/m³",
    shape = "circle"
  ),
  who_no2 = list(
    colours = c(
      "blue",
      "green",
      "yellow",
      "orange",
      "#FF4500",
      "#8B0000",
      "#DA70D6",
      "#4B0082",
      "#696969",
      "black",
      "white"
    ),
    thresholds = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, Inf),
    labels = c(
      "< 10: WHO guideline",
      "10-19: WHO Int 3",
      "20-29: WHO Int 2",
      "30-39: UK/WHO Int 1",
      "40-49: > UK",
      "50-60",
      "60-70",
      "70-80",
      "80-90",
      "90-100",
      "Insufficient data"
    ),
    title = "NO2, µg/m³",
    shape = "circle"
  ),
  lbrut_no2 = list(
    colours = c(
      "blue",
      "green",
      "yellow",
      "orange",
      "#FF4500",
      "#8B0000",
      "#DA70D6",
      "#4B0082",
      "#696969",
      "black",
      "white"
    ),
    thresholds = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, Inf),
    labels = c(
      "< 10: WHO guideline",
      "10-19: < LB Richmond",
      "20-29: WHO Int 2",
      "30-39: < UK",
      "40-49: > UK",
      "50-60",
      "60-70",
      "70-80",
      "80-90",
      "90-100",
      "Insufficient data"
    ),
    title = "NO2, µg/m³"
  ),
  lbw_no2 = list(
    colours = c(
      "blue",
      "green",
      "yellow",
      "orange",
      "#FF4500",
      "#8B0000",
      "#DA70D6",
      "#4B0082",
      "#696969",
      "black",
      "white"
    ),
    thresholds = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, Inf),
    labels = c(
      "< 10: WHO guideline",
      "10-19: WHO Int 3",
      "20-29: < LB Wandsworth",
      "30-39: < UK",
      "40-49: > UK",
      "50-60",
      "60-70",
      "70-80",
      "80-90",
      "90-100",
      "Insufficient data"
    ),
    title = "NO2, µg/m³"
  ),
  lbm_no2 = list(
    colours = c(
      "blue",
      "green",
      "yellow",
      "orange",
      "#FF4500",
      "#8B0000",
      "#DA70D6",
      "#4B0082",
      "#696969",
      "black",
      "white"
    ),
    thresholds = c(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, Inf),
    labels = c(
      "< 10: WHO guideline",
      "10-19: WHO Int 3",
      "20-29: WHO Int 2",
      "30-39: UK/WHO Int 1",
      "40-49: > UK",
      "50-60",
      "60-70",
      "70-80",
      "80-90",
      "90-100",
      "Insufficient data"
    ),
    title = "NO2, µg/m³"
  ),
  gla_pm25 = list(
    colours = c(
      "darkblue", # 0–5
      "blue", # 5–7.5
      "lightgreen", # 7.5–10
      "yellow", # 10–12.5
      "orange", # 12.5–15
      "darkorange", # 15–20
      "red", # 20–25
      "darkred", # 25–Inf
      "white" # NA
    ),
    thresholds = c(0, 5, 7.5, 10, 12.5, 15, 20, 25, Inf),
    labels = c(
      "< 5: WHO guideline",
      "5-7.5",
      "7.5-10: < GLA/WHO Int 1",
      "10-12.5",
      "12.5-15: < WHO Int 2",
      "15-20: < UK",
      "20-25: < WHO Int 2",
      "> 25",
      "Insufficient data"
    ),
    title = "PM<sub>2.5</sub>, µg/m³"
  ),
  deltas = list(
    colours = c(
      "#084594",
      "#2171B5",
      "#4292C6",
      "#6BAED6",
      "#9ECAE1",
      "#FEE391",
      "#FEB24C",
      "#FB6A4A",
      "#DE2D26",
      "#A50F15",
      "white"
    ),
    thresholds = c(Inf, 8, 6, 4, 2, 0, -2, -4, -6, -8, -Inf),
    labels = c(
      ">8",
      "6-8",
      "4-6",
      "2-4",
      "0-2",
      "Increase 0-2",
      "increase of 2-4",
      "increase of 4-6",
      "increase of 6-8",
      "increase over 8",
      "Site not in use"
    ),
    title = "Fall in NO2 levels, µg/m3, year on year"
  ),
  schools = list(
    colours = c("#1E90FF", "#32CD32"),
    domain = c("Primary", "Secondary"),
    labels = c("Primary", "Secondary"),
    title = "School Level"
  )
)

#' Load colour scale from YAML file or fallback to R list
#' @param scale_name Character string, name of the colour scale (e.g., "who_no2")
#' @return List containing colour scale definition
load_colour_scale <- function(scale_name) {
  yaml_available <- requireNamespace("yaml", quietly = TRUE)

  if (yaml_available) {
    scale_dir <- system.file("config/scales", package = "quickmap")
    if (scale_dir == "") scale_dir <- "inst/config/scales"
    yaml_file <- file.path(scale_dir, paste0(scale_name, ".yaml"))

    if (file.exists(yaml_file)) {
      tryCatch({
        scale <- yaml::read_yaml(yaml_file)
        # Ensure thresholds are numeric (yaml may parse .Inf as string/NA)
        if (!is.null(scale$thresholds)) {
          scale$thresholds <- as.numeric(scale$thresholds)
        }
        return(scale)
      }, error = function(e) {
        warning(sprintf("Failed to load '%s': %s. Using R list.", yaml_file, e$message))
      })
    }
  }

  if (!scale_name %in% names(colour_scales)) {
    stop("Scale '", scale_name, "' not found. Available: ", paste(names(colour_scales), collapse = ", "))
  }

  return(colour_scales[[scale_name]])
}

# Get colour legend info from unified scale
get_colour_legend <- function(scale = "lbrut_no2") {
  scale_data <- load_colour_scale(scale)

  list(
    colors = scale_data$colours,
    labels = scale_data$labels,
    title = scale_data$title,
    thresholds = scale_data$thresholds
  )
}

# Assign colour to a value based on scale
assign_colour <- function(value, scale = "lbrut_no2") {
  if (is.na(value) || !is.numeric(value)) return("white")

  scale_data <- load_colour_scale(scale)

  thresholds <- scale_data$thresholds
  colours <- scale_data$colours
  index <- findInterval(value, thresholds, left.open = FALSE)
  return(colours[index])
}

################################################################################
# HTML BANNER AND LEGEND FUNCTIONS (Add to quickmap.R after colour_scales) ####
################################################################################

# Purpose of functions and code marked in PART 3  ####
# ✓ Creates collapsible HTML legend system (external to leaflet map)
# ✓ Add an HTML banner above map (customizable color and text)
# ✓ Mobile responsive (legend auto-collapses on <480px screens)
# ✓ Color conversion from R names to hex codes
# ✓ Two-layer temporal system with radio button controls
# ✓ Legend generated from colour_scales structure
# ✓ Reduced line spacing for compact legend display

#' Convert R color names to hex codes
#'
#' Handles both R color names (e.g., "blue") and existing hex codes.
#' Invalid colors default to black with a warning.
#'
#' @param color_vector Character vector of R color names or hex codes
#' @return Character vector of hex codes (uppercase format)
#' @examples
#' convert_colors_to_hex(c("blue", "red", "#FF0000"))
#' # Returns: c("#0000FF", "#FF0000", "#FF0000")
convert_colors_to_hex <- function(color_vector) {
  sapply(
    color_vector,
    function(color) {
      # Check if already in hex format
      if (grepl("^#[0-9A-Fa-f]{6}$", color)) {
        return(toupper(color))
      } else {
        # Convert R color name to hex
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
#'
#' Splits label on first colon to extract numeric range and descriptive text
#'
#' @param label Character string like "< 10: WHO guideline" or "25-30"
#' @return List with $range and $description (description is NULL if no colon)
parse_legend_label <- function(label) {
  # Split on first colon
  parts <- strsplit(label, ":", fixed = TRUE)[[1]]

  if (length(parts) >= 2) {
    # Has description after colon
    range <- trimws(parts[1])
    description <- trimws(paste(parts[-1], collapse = ":")) # Rejoin in case of multiple colons
    return(list(range = range, description = description))
  } else {
    # No description (just a range or special label like "Insufficient data")
    return(list(range = trimws(label), description = NULL))
  }
}

#' Get footnote symbol for index
#'
#' Returns traditional footnote symbols in sequence
#'
#' @param index Integer index (1-based)
#' @return Character symbol (†, ‡, §, ¶, etc.)
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
    # Fallback for more than 20 items
    return(paste0("(", index, ")"))
  }
}

#' Calculate maximum range width for fixed-width legend blocks
#'
#' Finds the longest range text (before colon) to determine uniform block width
#'
#' @param labels Character vector of legend labels
#' @return Integer number of characters for the longest range (including symbol space)
calculate_max_range_width <- function(labels) {
  max_width <- 0

  for (label in labels) {
    parsed <- parse_legend_label(label)
    range_text <- parsed$range

    # Add 2 chars if has description (space + symbol)
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
generate_legend_html <- function(
  scale_name,
  collapsed_mobile = TRUE,
  data_max = NULL
) {
  legend_scale <- load_colour_scale(scale_name)

  # Validate structure integrity
  if (length(legend_scale$colours) != length(legend_scale$labels)) {
    stop(sprintf(
      "Mismatch in colour_scale '%s': %d colours vs %d labels",
      scale_name,
      length(legend_scale$colours),
      length(legend_scale$labels)
    ))
  }

  # Filter legend items based on data maximum (if provided)
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

    # Ensure we don't exceed available items
    num_items <- min(num_items, length(legend_scale$colours))

    # Filter colours and labels
    legend_scale$colours <- legend_scale$colours[1:num_items]
    legend_scale$labels <- legend_scale$labels[1:num_items]
  }

  # Convert all colors to hex codes
  hex_colors <- convert_colors_to_hex(legend_scale$colours)

  # Calculate fixed width for uniform-width legend blocks
  max_width <- calculate_max_range_width(legend_scale$labels)

  # Parse labels and assign symbols
  symbol_index <- 1
  legend_items <- list()
  symbol_key_items <- list()

  for (i in seq_along(hex_colors)) {
    parsed <- parse_legend_label(legend_scale$labels[i])
    text_color <- get_contrast_text_color(hex_colors[i])

    # Build range text with symbol (if has description)
    if (!is.null(parsed$description)) {
      symbol <- get_symbol_for_index(symbol_index)
      range_with_symbol <- paste0(parsed$range, " ", symbol)
      symbol_index <- symbol_index + 1

      # Pad to fixed width
      padded_range <- sprintf(paste0("%-", max_width, "s"), range_with_symbol)

      # Create symbol key entry (colored background with description)
      # Use monospace and pad to fixed width for vertical alignment with legend items
      symbol_text <- paste(symbol, parsed$description)
      padded_symbol_text <- sprintf(
        paste0("%-", max_width + 10, "s"),
        symbol_text
      ) # Extra width for description

      symbol_key_items[[length(symbol_key_items) + 1]] <- sprintf(
        '      <span style="background: %s; color: %s; padding: 0.5rem 0.625rem; border-radius: 0.25rem; font-family: monospace; display: inline-block;">%s</span>',
        hex_colors[i],
        text_color,
        padded_symbol_text
      )
    } else {
      # No description, just show range (no symbol)
      padded_range <- sprintf(paste0("%-", max_width, "s"), parsed$range)
    }

    # Create colored range block (matching header height with 0.5rem vertical padding)
    legend_items[[i]] <- sprintf(
      '      <div class="legend-item"><span style="background: %s; color: %s; padding: 0.5rem 0.625rem; border-radius: 0.25rem; font-family: monospace;">%s</span></div>',
      hex_colors[i],
      text_color,
      padded_range
    )
  }

  legend_items_html <- paste(legend_items, collapse = "\n")

  # Ensure symbol_key_html is always a string (even if empty)
  if (length(symbol_key_items) > 0) {
    symbol_key_html <- paste(symbol_key_items, collapse = "\n")
  } else {
    symbol_key_html <- ""
  }

  # Optional mobile collapse script
  mobile_script <- if (collapsed_mobile) {
    '  if (window.innerWidth <= 480) {
    document.getElementById("mapLegend").classList.add("collapsed");
  }'
  } else {
    ''
  }

  # Load HTML template from external file
  legend_dir <- system.file("legend", package = "quickmap")

  # Fall back to local inst/legend if package not installed
  if (legend_dir == "") {
    legend_dir <- "inst/legend"
  }

  html_file <- file.path(legend_dir, "legend.html")

  # Read template
  html_template <- paste(readLines(html_file, warn = FALSE), collapse = "\n")

  # Inject title, items, symbol key, and script into template
  sprintf(
    html_template,
    legend_scale$title,
    legend_items_html,
    symbol_key_html,
    mobile_script
  )
}

#' Lighten or darken a hex color
#'
#' Adjusts color brightness by a percentage
#'
#' @param color Hex color string (e.g., "#2c3e50")
#' @param amount Percentage to lighten (positive) or darken (negative), range -100 to 100
#' @return Hex color string
lighten_color <- function(color, amount = 15) {
  # Convert hex to RGB
  rgb_vals <- col2rgb(color)[, 1]

  # Calculate adjustment (positive = lighter, negative = darker)
  if (amount > 0) {
    # Lighten: move toward white (255)
    rgb_vals <- rgb_vals + ((255 - rgb_vals) * amount / 100)
  } else {
    # Darken: move toward black (0)
    rgb_vals <- rgb_vals + (rgb_vals * amount / 100)
  }

  # Clamp values to 0-255
  rgb_vals <- pmin(pmax(rgb_vals, 0), 255)

  # Convert back to hex
  rgb(rgb_vals[1], rgb_vals[2], rgb_vals[3], maxColorValue = 255)
}

#' Calculate contrast text color for background
#'
#' Determines whether white or black text should be used on a given
#' background color for optimal readability using WCAG luminance formula
#'
#' @param color Background color (hex or R color name)
#' @return "white" for dark backgrounds, "black" for light backgrounds
get_contrast_text_color <- function(color) {
  # Convert color to RGB values (0-255)
  rgb_vals <- col2rgb(color)[, 1]

  # Calculate relative luminance using standard formula
  # https://www.w3.org/TR/WCAG20/#relativeluminancedef
  luminance <- (0.299 *
    rgb_vals[1] +
    0.587 * rgb_vals[2] +
    0.114 * rgb_vals[3]) /
    255

  # Return white for dark backgrounds, black for light backgrounds
  if (luminance < 0.5) {
    return("white")
  } else {
    return("black")
  }
}

#' Load banner CSS from external file
#'
#' Reads banner CSS template from inst/banner/ directory and injects
#' banner color and mode-specific styling values using named placeholders.
#'
#' Named placeholders used:
#' - {{banner_bg}}: Banner background color
#' - {{padding}}: Banner padding
#' - {{font_size}}: Banner font size
#' - {{font_weight}}: Banner font weight (bold for images, empty for interactive)
#' - {{mobile_css}}: Mobile responsive CSS (empty for images, full breakpoints for interactive)
#'
#' Pattern: Uses gsub() with named placeholders ({{name}}) for self-documenting,
#' maintainable code. Follows the roller menu control pattern established in
#' load_roller_menu_control().
#'
#' @param banner_colour Hex color for banner background
#' @param image_mode Logical, if TRUE uses image-optimized styles, if FALSE uses interactive responsive styles
#' @return Character string containing CSS wrapped in <style> tags
load_banner_css <- function(banner_colour = "#2c3e50", image_mode = FALSE) {
  # Define path to banner CSS file
  banner_dir <- system.file("banner", package = "quickmap")

  # Fall back to local inst/banner if package not installed
  if (banner_dir == "") {
    banner_dir <- "inst/banner"
  }

  css_file <- file.path(banner_dir, "banner.css")

  # Read CSS template
  css_content <- paste(readLines(css_file, warn = FALSE), collapse = "\n")

  # Determine values based on mode
  if (image_mode) {
    # Image-optimized: larger sizes for JPG clarity
    padding <- "2rem"
    font_size <- "1.8rem"
    font_weight <- "font-weight: bold;"
    mobile_css <- "" # No mobile styles for static images
  } else {
    # Interactive: responsive design with mobile breakpoints
    padding <- "1.25rem"
    font_size <- "1.3rem"
    font_weight <- "" # No extra font-weight

    # Mobile responsive CSS for banner
    mobile_css <- "
/* Small phones (320-374px) */
@media (max-width: 374px) {
  .banner {
    padding: 0.5rem 0.25rem;
    font-size: 0.9rem;
    line-height: 1.2em;
  }
}

/* Standard phones (375-480px) */
@media (min-width: 375px) and (max-width: 480px) {
  .banner {
    padding: 0.625rem 0.375rem;
    font-size: 1rem;
    line-height: 1.25em;
  }
}

/* Landscape phones */
@media (max-width: 850px) and (orientation: landscape) {
  .banner {
    padding: 0.75rem 0.5rem;
    font-size: 1.1rem;
    line-height: 1.3em;
  }
}"
  }

  # Replace named placeholders with actual values using gsub()
  css_content <- gsub("{{banner_bg}}", banner_colour, css_content, fixed = TRUE)
  css_content <- gsub("{{padding}}", padding, css_content, fixed = TRUE)
  css_content <- gsub("{{font_size}}", font_size, css_content, fixed = TRUE)
  css_content <- gsub("{{font_weight}}", font_weight, css_content, fixed = TRUE)
  css_content <- gsub("{{mobile_css}}", mobile_css, css_content, fixed = TRUE)

  # Return CSS wrapped in style tags
  return(sprintf("\n<style>\n%s\n</style>\n", css_content))
}

#' Load legend CSS from external file
#'
#' Reads legend CSS template from inst/legend/ directory and injects
#' legend colors and mode-specific styling values using named placeholders.
#'
#' Named placeholders used:
#' - {{border_top}}: Legend border top style
#' - {{container_padding}}: Legend container padding
#' - {{header_gap}}: Gap between header elements
#' - {{header_font_size}}: Header font size (bold for images, empty for interactive)
#' - {{legend_header_bg}}: Legend header background color (calculated from banner_colour)
#' - {{legend_header_hover}}: Legend header hover background color
#' - {{items_gap}}: Gap between legend items
#' - {{items_font_size}}: Font size for legend items
#' - {{symbol_key_gap}}: Gap between symbol key items
#' - {{symbol_key_font_size}}: Font size for symbol key
#' - {{mobile_css}}: Mobile responsive CSS (empty for images, full breakpoints for interactive)
#'
#' Pattern: Uses gsub() with named placeholders ({{name}}) for self-documenting,
#' maintainable code. Follows the roller menu control pattern established in
#' load_roller_menu_control().
#'
#' @param banner_colour Hex color for banner (used to calculate legend header colors)
#' @param image_mode Logical, if TRUE uses image-optimized styles, if FALSE uses interactive responsive styles
#' @return Character string containing CSS wrapped in <style> tags
load_legend_css <- function(banner_colour = "#2c3e50", image_mode = FALSE) {
  # Define path to legend CSS file
  legend_dir <- system.file("legend", package = "quickmap")

  # Fall back to local inst/legend if package not installed
  if (legend_dir == "") {
    legend_dir <- "inst/legend"
  }

  css_file <- file.path(legend_dir, "legend.css")

  # Read CSS template
  css_content <- paste(readLines(css_file, warn = FALSE), collapse = "\n")

  # Calculate legend header colors from banner_colour
  legend_header_bg <- lighten_color(banner_colour, 85) # Very light tint
  legend_header_hover <- lighten_color(banner_colour, 75) # Slightly darker for hover

  # Determine values based on mode
  if (image_mode) {
    # Image-optimized: larger sizes for JPG clarity
    border_top <- "3px solid #dee2e6"
    container_padding <- "1.5rem 2rem"
    header_gap <- "1rem"
    header_font_size <- "font-size: 1.2rem;"
    items_gap <- "1rem"
    items_font_size <- "font-size: 1.2rem;" # Match header size
    symbol_key_gap <- "1rem"
    symbol_key_font_size <- "font-size: 1rem;" # Smaller than items
    mobile_css <- "" # No mobile styles for static images
  } else {
    # Interactive: responsive design with mobile breakpoints
    border_top <- "2px solid #dee2e6"
    container_padding <- "0.75rem 1rem"
    header_gap <- "0.625rem"
    header_font_size <- ""
    items_gap <- "0.625rem"
    items_font_size <- "font-size: 1rem;" # Match header size
    symbol_key_gap <- "0.625rem"
    symbol_key_font_size <- "font-size: 0.85rem;" # Smaller than items

    # Mobile responsive CSS for horizontal legend layout
    mobile_css <- "
/* Mobile: Stack vertically on small screens */
@media (max-width: 480px) {
  .legend-container {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
    padding: 0.5rem;
  }

  .legend-header {
    padding: 0.5rem 0.75rem;
    font-size: 0.9rem;
    gap: 0.375rem;
  }

  .legend-items {
    gap: 0.5rem;
    font-size: 0.9rem;
  }

  .legend-key {
    gap: 0.5rem;
    font-size: 0.75rem;
  }
}

/* Tablet/Landscape: Keep horizontal but tighter spacing */
@media (min-width: 481px) and (max-width: 850px) {
  .legend-container {
    gap: 0.75rem;
    padding: 0.625rem;
  }

  .legend-header {
    padding: 0.5rem 0.875rem;
    font-size: 1rem;
    gap: 0.5rem;
  }

  .legend-items {
    gap: 0.625rem;
    font-size: 1rem;
  }

  .legend-key {
    gap: 0.625rem;
    font-size: 0.85rem;
  }
}

/* Year control toggle with text character */
.leaflet-control-layers-toggle {
  background-image: none !important;
  width: 32px;
  height: 32px;
  background-color: white;
  border-radius: 4px;
  box-shadow: 0 1px 5px rgba(0,0,0,0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  text-decoration: none;
}

.leaflet-control-layers-toggle::before {
  content: '▲▼';
}

.leaflet-control-layers-toggle:hover {
  background-color: #f4f4f4;
}

.leaflet-control-layers-expanded {
  padding: 10px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  min-width: 100px;
}

.leaflet-control-layers-base label {
  display: block;
  padding: 4px 8px;
  cursor: pointer;
  font-size: 14px;
}

.leaflet-control-layers-base label:hover {
  background-color: #f0f0f0;
  border-radius: 2px;
}

@media (max-width: 768px) {
  .leaflet-control-layers-toggle {
    width: 36px;
    height: 36px;
    font-size: 16px;
  }
}"
  }

  # Replace named placeholders with actual values using gsub()
  css_content <- gsub("{{border_top}}", border_top, css_content, fixed = TRUE)
  css_content <- gsub("{{container_padding}}", container_padding, css_content, fixed = TRUE)
  css_content <- gsub("{{header_gap}}", header_gap, css_content, fixed = TRUE)
  css_content <- gsub("{{header_font_size}}", header_font_size, css_content, fixed = TRUE)
  css_content <- gsub("{{legend_header_bg}}", legend_header_bg, css_content, fixed = TRUE)
  css_content <- gsub("{{legend_header_hover}}", legend_header_hover, css_content, fixed = TRUE)
  css_content <- gsub("{{items_gap}}", items_gap, css_content, fixed = TRUE)
  css_content <- gsub("{{items_font_size}}", items_font_size, css_content, fixed = TRUE)
  css_content <- gsub("{{symbol_key_gap}}", symbol_key_gap, css_content, fixed = TRUE)
  css_content <- gsub("{{symbol_key_font_size}}", symbol_key_font_size, css_content, fixed = TRUE)
  css_content <- gsub("{{mobile_css}}", mobile_css, css_content, fixed = TRUE)

  # Return CSS wrapped in style tags
  return(sprintf("\n<style>\n%s\n</style>\n", css_content))
}

#' Load roller menu control from external files
#'
#' Reads HTML, CSS, and JavaScript from inst/controls/ directory
#' and combines them into a single HTML string for injection
#'
#' @param banner_colour Hex color for theming (default "#2c3e50")
#' @param autoplay Logical, whether to start animation automatically on load
#' @param play_speed Numeric, milliseconds per year during animation
#' @return Character string containing combined HTML/CSS/JS
load_roller_menu_control <- function(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500
) {
  # Define paths to control files
  controls_dir <- system.file("controls", package = "quickmap")

  # Fall back to local inst/controls if package not installed
  if (controls_dir == "") {
    controls_dir <- "inst/controls"
  }

  html_file <- file.path(controls_dir, "roller-menu.html")
  css_file <- file.path(controls_dir, "roller-menu.css")
  js_file <- file.path(controls_dir, "roller-menu.js")

  # Read files
  html_content <- paste(readLines(html_file, warn = FALSE), collapse = "\n")
  css_content <- paste(readLines(css_file, warn = FALSE), collapse = "\n")
  js_content <- paste(readLines(js_file, warn = FALSE), collapse = "\n")

  # Calculate accent colors from banner_colour
  accent_light <- lighten_color(banner_colour, 15) # Lighter shade for selected background
  hover_tint <- lighten_color(banner_colour, 85) # Very light tint for hover background

  # Inject banner_colour and accent into CSS template
  # Order: play_bg, play_border, play_hover_bg, play_hover_border, play_focus_outline,
  #        button_bg, button_border, button_hover_bg, button_hover_border, button_focus_outline,
  #        menu_border, item_hover_bg, selected_bg, selected_hover_bg,
  #        keyboard_focused_bg, keyboard_focused_outline
  css_content <- sprintf(
    css_content,
    banner_colour,
    banner_colour,
    accent_light,
    accent_light,
    "#ffffff", # Play button
    banner_colour,
    banner_colour,
    accent_light,
    accent_light,
    "#ffffff", # Year button
    banner_colour,
    hover_tint,
    accent_light,
    hover_tint, # Menu items
    hover_tint,
    banner_colour
  ) # Keyboard focus

  # Create config script to inject settings into JavaScript
  config_script <- sprintf(
    'window.quickmapConfig = {autoplay: %s, playSpeed: %d};',
    tolower(as.character(autoplay)), # Convert TRUE/FALSE to true/false for JS
    as.integer(play_speed)
  )

  # Combine into single HTML string (config script injected before main JS)
  combined <- sprintf(
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

  return(combined)
}

#' Post-process saved HTML to add banner and external legend
#'
#' Modifies an existing HTML file in place to add:
#'   1. Viewport meta tag for mobile compatibility
#'   2. Custom CSS for banner/legend/map layout
#'   3. Banner div above map (optional)
#'   4. Map container with flexbox layout
#'   5. External legend below map (generated from colour_scale)
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
apply_custom_layout_in_html <- function(
  html_file,
  title = NULL,
  banner_colour = "#2c3e50",
  scale_name,
  collapsed_mobile = TRUE,
  image_mode = FALSE, # FALSE = interactive HTML, TRUE = static image export
  image_dimensions = c(1200, 1200), # Image dimensions [width, height] for scaling
  autoplay = FALSE, # Start animation automatically on load
  play_speed = 500, # Milliseconds per year during animation
  data_max = NULL # Maximum data value for legend trimming
) {
  # Validate file exists
  if (!file.exists(html_file)) {
    stop("HTML file not found: ", html_file)
  }

  # Read entire HTML file
  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")

  # Viewport meta tag for mobile compatibility
  viewport_meta <- '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'

  # Load banner CSS from external file
  banner_css <- load_banner_css(banner_colour, image_mode)

  # Load legend CSS from external file
  legend_css <- load_legend_css(banner_colour, image_mode)

  # Combine banner and legend CSS
  custom_css <- paste0(banner_css, legend_css)

  # quickmap_0_8_6_3.R uses new mobile sizes to be multiply adaptive
  # 0.8.6.x test a range of settings for mobile

  # Apply image dimension scaling if in image mode
  if (image_mode) {
    width <- image_dimensions[1] # e.g., 1920
    height <- image_dimensions[2] # e.g., 1080

    # Calculate scale factor (1200px = baseline) using geometric mean for balanced scaling
    scale_factor <- sqrt((width * height) / (1200 * 1200))
    # For 1920x1080: sqrt((1920*1080)/(1200*1200)) = sqrt(1.44) = 1.2 (balanced scaling)
    # For 800x600: sqrt((800*600)/(1200*1200)) = sqrt(0.33) = 0.58 (proportional reduction)

    # Apply scaling to CSS values (text sizes)
    banner_font_size <- 1.8 * scale_factor
    symbol_size <- 1.3 * scale_factor # Reduced from 2rem to 1.3rem for better proportion with text
    header_font_size <- 1.2 * scale_factor
    legend_font_size <- 1.0 * scale_factor

    # Apply scaling to layout dimensions (NEW)
    legend_padding <- 1.0 * scale_factor # Scale legend padding
    legend_gap <- 1.0 * scale_factor # Scale gaps between items
    legend_max_height <- 18.75 * scale_factor # Scale max legend height
    header_padding <- 1.5 * scale_factor # Scale header padding
    banner_padding <- 2.0 * scale_factor # Scale banner padding

    # Replace fixed sizes with calculated ones (text)
    custom_css <- gsub("1\\.8rem", paste0(banner_font_size, "rem"), custom_css)
    custom_css <- gsub("1\\.3rem", paste0(symbol_size, "rem"), custom_css) # Updated pattern for new symbol size
    custom_css <- gsub("1\\.2rem", paste0(header_font_size, "rem"), custom_css)
    custom_css <- gsub("1rem", paste0(legend_font_size, "rem"), custom_css)

    # Replace layout dimensions with calculated ones (NEW)
    custom_css <- gsub(
      "18\\.75rem",
      paste0(legend_max_height, "rem"),
      custom_css
    )
    custom_css <- gsub(
      "padding: 1\\.5rem 2rem",
      paste0("padding: ", header_padding, "rem ", banner_padding, "rem"),
      custom_css
    )
    custom_css <- gsub(
      "padding: 1rem",
      paste0("padding: ", legend_padding, "rem"),
      custom_css
    )
    custom_css <- gsub(
      "gap: 1rem",
      paste0("gap: ", legend_gap, "rem"),
      custom_css
    )
  }

  # Insert viewport and CSS before </head>
  html_text <- sub(
    "</head>",
    paste0(viewport_meta, custom_css, "</head>"),
    html_text
  )

  # Build banner HTML (optional)
  banner_html <- if (!is.null(title)) {
    sprintf(
      '<div class="banner">%s</div>\n<div class="map-container">\n',
      title
    )
  } else {
    '<div class="map-container">\n'
  }

  # Insert banner/container after <body> tag (handles attributes)
  html_text <- sub("(<body[^>]*>)", paste0("\\1\n", banner_html), html_text)

  # Load roller menu control from external files
  roller_menu_html <- load_roller_menu_control(
    banner_colour,
    autoplay,
    play_speed
  )

  # Generate legend HTML (starts with </div> to close map-container)
  legend_html <- generate_legend_html(scale_name, collapsed_mobile, data_max)

  # Insert control before legend (so it's inside map-container)
  combined_html <- paste0(roller_menu_html, "\n", legend_html)
  html_text <- sub("</body>", paste0(combined_html, "</body>"), html_text)

  # Write modified HTML back to file
  writeLines(html_text, html_file)

  return(invisible(TRUE))
}

# Unified icon creation function for all point layers
create_generic_icons <- function(
  data,
  layer_type,
  pollutant = NULL,
  colour_scale = NULL,
  image_scale_factor = 1.0 # Scale factor for marker sizing (1.0 = default, >1.0 for larger images)
) {
  # Determine shape and base size, then apply scaling
  # Base sizes are for 1200x1200px reference images
  # For other sizes: scale = sqrt((width × height) / (1200 × 1200))
  # HTML maps: image_scale_factor = 1.0 (no scaling)
  # Static maps: image_scale_factor calculated from dimensions
  base_shape_config <- switch(
    layer_type,
    "schools" = list(shape = 'cross', size = 12),
    "dt_sites" = list(shape = 'circle', size = 20),
    "bl_nodes" = list(shape = 'diamond', size = 20),
    stop("Unknown layer type: ", layer_type)
  )

  # Apply scaling to marker size for static images
  shape_config <- list(
    shape = base_shape_config$shape,
    size = round(base_shape_config$size * image_scale_factor)
  )

  # Determine colors based on layer type
  colors <- switch(
    layer_type,
    "schools" = {
      # Use colorFactor for categorical school data (same logic as create_school_icons)
      pal <- colorFactor(
        palette = c("#1E90FF", "#32CD32"),
        domain = unique(data$Level)
      )
      pal(data$Level)
    },
    "dt_sites" = {
      # Use assign_colour for continuous pollution data
      sapply(data[[pollutant]], assign_colour, scale = colour_scale)
    },
    "bl_nodes" = {
      # Use assign_colour for continuous pollution data
      sapply(data[[pollutant]], assign_colour, scale = colour_scale)
    }
  )

  # Create icons with unified approach
  makeSymbolsSize(
    values = rep(1, length(colors)),
    shape = shape_config$shape,
    color = "black",
    fillColor = colors,
    baseSize = shape_config$size,
    fillOpacity = 0.7,
    stroke = TRUE,
    weight = 1
  )
}

# Map styling and layout functions ####

# Add colored bounding box around map
add_map_border <- function(
  map,
  banner_colour = "#078141",
  border_width = "5px",
  border_radius = "8px",
  padding = "10px"
) {
  # Create styled container
  styled_map <- tags$div(
    style = sprintf(
      "
      border: %s solid %s;
      border-radius: %s;
      padding: %s;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      overflow: hidden;
    ",
      border_width,
      banner_colour,
      border_radius,
      padding
    ),
    map
  )

  return(styled_map)
}

#' Create layer configuration for map generation
#'
#' Defines which layers to include based on data availability and their properties
#'
#' @param diffusion_tube_file,diffusion_tube_file,sensor_file,school_file Data file paths
#' @param marker_labels Label display mode for all layers
#' @return List of layer configurations with data sources and preparation functions
get_measurement_layers <- function(
  diffusion_tube_file,
  sensor_file,
  school_file,
  marker_labels
) {
  list(
    bl_nodes = list(
      enabled = (sensor_file != "none"),
      data_source = "bl_annual_means_sf",
      layer_type = "bl_nodes",
      temporal = TRUE,
      prepare_function = "prepare_bl_layer_data",
      options = list(marker_labels = marker_labels)
    ),
    dt_sites = list(
      enabled = (diffusion_tube_file != "none"),
      data_source = "sf_data_wgs84",
      layer_type = "dt_sites",
      temporal = TRUE,
      prepare_function = "prepare_dt_layer_data",
      options = list(marker_labels = marker_labels)
    ),
    schools = list(
      enabled = (school_file != "none"),
      data_source = "sf_schools_wgs84",
      layer_type = "schools",
      temporal = FALSE,
      prepare_function = "prepare_static_layer_data",
      options = list(marker_labels = marker_labels)
    )
  )
}

# Create data preparation functions
# Re-add this function (it's still needed):
prepare_bl_layer_data <- function(
  oa_subset,
  pollutant,
  colour_scale,
  marker_labels
) {
  # Return NULL if no data to process
  if (nrow(oa_subset) == 0) return(NULL)

  # Generate labels using unified function
  labels <- generate_marker_labels(
    oa_subset,
    pollutant,
    marker_labels,
    "bl_nodes"
  )

  # Return structured data ready for marker creation
  list(
    data = oa_subset,
    labels = labels
  )
}

# Re-add these functions that are still called by the generic system:
prepare_dt_layer_data <- function(
  subset_data,
  pollutant,
  colour_scale,
  marker_labels
) {
  # Pre-compute colors for all points
  colors <- sapply(
    subset_data[[pollutant]],
    assign_colour,
    scale = colour_scale
  )

  # Generate labels using unified function
  labels <- generate_marker_labels(
    subset_data,
    pollutant,
    marker_labels,
    "dt_sites"
  )

  # Return structured data ready for mapping
  list(
    data = subset_data,
    colors = colors,
    labels = labels
  )
}

prepare_generic_layer_data <- function(
  layer_config,
  year_data,
  pollutant = NULL,
  colour_scale = NULL
) {
  # Extract marker_labels from options
  show_labels <- if (!is.null(layer_config$options))
    layer_config$options$marker_labels else FALSE

  # Route to appropriate preparation function based on layer type
  switch(
    layer_config$layer_type,
    "bl_nodes" = {
      prepare_bl_layer_data(year_data, pollutant, colour_scale, show_labels)
    },
    "dt_sites" = {
      prepare_dt_layer_data(year_data, pollutant, colour_scale, show_labels)
    },
    "schools" = {
      prepare_static_layer_data(year_data, show_labels)
    },
    stop("Unknown layer type: ", layer_config$layer_type)
  )
}


#' Add a layer to the map with unified parameter handling
#'
#' @param map The leaflet map object
#' @param layer_data The data for the layer including points and labels
#' @param layer_config Configuration object containing layer_type and other
#'   settings
#' @param year The year for temporal layers (NULL for static layers)
#' @param pollutant The pollutant type for relevant layers
#' @param colour_scale The scale to use for icons
#' @param label_sizing Scaling factor for label size (default 1.0)
#' @return Updated map object with new layer
add_layer <- function(
  map,
  layer_data,
  layer_config,
  year = NULL,
  pollutant = NULL,
  colour_scale = NULL,
  label_sizing = 1.0,
  image_scale_factor = 1.0, # Scale factor for marker sizing (1.0 = default)
  marker_labels = FALSE # Label visibility mode from layer configuration
) {
  # Early return if layer data is NULL
  if (is.null(layer_data)) return(map)

  # Extract layer type from config
  layer_type <- layer_config$layer_type

  # Create icons based on layer type
  icons <- create_generic_icons(
    layer_data$data,
    layer_type,
    pollutant,
    colour_scale,
    image_scale_factor
  )

  # Calculate label text size
  label_text_size <- as.character(12 * label_sizing)

  # Determine if labels should be always visible (noHide) based on marker_labels parameter
  # "values_on" and "labels_on" make labels always visible, others use auto-hide
  no_hide <- marker_labels %in% c("values_on", "labels_on")

  # Common label options
  label_opts <- labelOptions(
    noHide = no_hide, # Controlled by marker_labels parameter: TRUE for "values_on"/"labels_on", FALSE otherwise
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

  # Base marker parameters
  marker_params <- list(
    data = layer_data$data,
    lng = ~Longitude,
    lat = ~Latitude,
    icon = icons,
    label = layer_data$labels,
    labelOptions = label_opts
  )

  # Add group parameter only for dynamic layers (not schools)
  if (layer_type != "schools") {
    marker_params$group <- year
  }

  # Add markers with do.call to handle dynamic parameters
  do.call(addMarkers, c(list(map = map), marker_params))
}


#' Prepare static layer data (schools)
#'
#' Prepares schools data for mapping with label generation
#'
#' @param static_sf Schools spatial data frame
#' @param marker_labels Label visibility control parameter
#' @return List with data, labels, and layer_type for schools
prepare_static_layer_data <- function(static_sf, marker_labels) {
  # Generate labels using unified function (schools always use School column)
  labels <- generate_marker_labels(
    static_sf,
    pollutant = NULL,
    marker_labels,
    "schools"
  )

  # Return structured data ready for generic processing
  # (same pattern as other layers)
  list(
    data = static_sf,
    labels = labels,
    layer_type = "schools" # Add layer type for generic processing
  )
}

#' Generate labels for markers based on marker_labels parameter
#'
#' Handles label generation for all data sources (CSV/DT sites, OA/BL nodes, schools)
#' with different behavior depending on data availability and layer type.
#'
#' @param data Data frame with spatial data
#' @param pollutant Pollutant column name (e.g., "no2", "pm25"). NULL for schools.
#' @param marker_labels Control parameter: FALSE (none), TRUE (hover),
#'        "values_on" (always), "labels" (hover), "labels_on" (always)
#' @param layer_type Layer type: "bl_nodes" (OA data), "dt_sites" (CSV data), or "schools"
#' @return Character vector of labels for markers
#'
#' @details
#' Label behavior by data source:
#' - Schools: Always uses School column regardless of mode
#' - CSV/DT: Uses Label column if available, otherwise pollution values
#' - OA/BL: Shows pollution values (no Label column available)
#'
#' Mode behavior:
#' - FALSE: Returns empty labels
#' - TRUE: Returns values for hover (auto-hide)
#' - "values_on": Returns values always visible
#' - "labels": Returns custom labels for hover (auto-hide)
#' - "labels_on": Returns custom labels always visible
generate_marker_labels <- function(
  data,
  pollutant,
  marker_labels,
  layer_type
) {
  # Determine what labels to generate
  show_values <- marker_labels %in% c(TRUE, "values_on")
  show_custom <- marker_labels %in% c("labels", "labels_on")

  if (!show_values && !show_custom) {
    # No labels
    return(rep("", nrow(data)))
  }

  # Special handling for schools: always use School column regardless of marker_labels mode
  # Schools don't have pollutant data, so they show school names in all modes (when enabled)
  if (layer_type == "schools") {
    if ("School" %in% names(data)) {
      return(as.character(data$School))
    } else {
      return(rep("", nrow(data)))
    }
  }

  if (show_custom) {
    # Try to use Label column (CSV/DT data)
    if ("Label" %in% names(data)) {
      return(as.character(data[["Label"]]))
    } else {
      # For bl_nodes (OA data), fall back to showing pollution values if available
      # and issue a warning
      if (layer_type == "bl_nodes") {
        if (!is.null(pollutant) && pollutant %in% names(data)) {
          warning(
            "marker_labels set to '",
            marker_labels,
            "' but no Label column found in bl_nodes data. Showing pollution values instead.",
            call. = FALSE
          )
          value_str <- ifelse(
            is.na(data[[pollutant]]),
            "",
            paste(round(data[[pollutant]], 0), "ug/m3")
          )
          return(value_str)
        } else {
          warning(
            "marker_labels set to '",
            marker_labels,
            "' but no Label column found in bl_nodes data. No labels will be shown.",
            call. = FALSE
          )
          return(rep("", nrow(data)))
        }
      }
      # Otherwise return no labels
      return(rep("", nrow(data)))
    }
  }

  # Show pollution values (for CSV and OA data)
  if (show_values) {
    if (is.null(pollutant) || !pollutant %in% names(data)) {
      return(rep("", nrow(data)))
    }
    value_str <- ifelse(
      is.na(data[[pollutant]]),
      "",
      paste(round(data[[pollutant]], 0), "ug/m3")
    )
    return(value_str)
  }

  return(rep("", nrow(data)))
}


# STEP 4: Create data subset function for temporal layers
get_layer_year_data <- function(data_source_name, year, data_environment) {
  # Get the actual data object from the calling environment
  data_source <- get(data_source_name, envir = data_environment)

  # Filter by year if it's temporal data
  if (year != "static") {
    data_source[data_source$year_str == year, ]
  } else {
    data_source
  }
}


# Helper to create title HTML
add_title <- function(map, text, interactive) {
  width <- if (interactive) TITLE_STYLES$interactive_width else
    TITLE_STYLES$static_width

  map |>
    addControl(
      html = htmltools::HTML(sprintf(
        '<div style="%s width: %s;">%s</div>',
        TITLE_STYLES$base,
        width,
        text
      )),
      position = "topright"
    )
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
add_boundary_polygons <- function(
  map,
  borough_sf,
  interactive,
  show_labels = FALSE
) {
  style <- BOUNDARY_STYLES[[if (interactive) "interactive" else "static"]]

  # Set label and labelOptions based on show_labels parameter
  if (show_labels) {
    label <- ~NAME
    # Always visible labels
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
      noHide = TRUE # Makes labels permanently visible
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

# Combined function for adding map controls
add_map_controls <- function(
  map,
  borough_sf = NULL,
  vignette_overlay = NULL,
  vignette = FALSE,
  bbox,
  interactive = TRUE,
  years,
  boundary_labels = FALSE
) {
  # Handle "static_only" case (no temporal layers - only schools) before validation
  # This happens when diffusion_tube_file == "none" && sensor_file == "none"
  if (identical(years, "static_only")) {
    years <- "2024" # Use dummy year for processing (will be ignored for layer control)
  }

  # Validation - years and bbox must be provided
  if (is.null(years)) stop("years parameter is required")
  if (is.null(bbox)) stop("bbox parameter is required")

  # Add boundaries
  if (!is.null(borough_sf)) {
    map <- add_boundary_polygons(
      map,
      borough_sf,
      interactive,
      show_labels = boundary_labels
    )
  }

  # Fit bounds with minimal padding for both interactive and static maps (tighter fill)
  options <- list(padding = c(5, 5))
  map <- map |>
    fitBounds(
      lng1 = unname(bbox["xmin"]),
      lat1 = unname(bbox["ymin"]),
      lng2 = unname(bbox["xmax"]),
      lat2 = unname(bbox["ymax"]),
      options = options
    )

  # Layer control: JavaScript-based (year menu control)
  # NOTE: addLayersControl() removed - it hides inactive groups before onRender,
  # making layers inaccessible to JavaScript caching
  # Always create layer cache (even for single year) so roller menu can initialize
  baseGroups <- if (interactive && length(years) >= 1) years else NULL
  if (!is.null(baseGroups)) {
    # Cache all year layers while visible, then hide all except latest
    map <- map %>%
      htmlwidgets::onRender(
        "
        function(el, x) {
          var map = this;
          var layersByGroup = {};
          var latestYear = null;

          // STAGE 1: Cache all layers by group (all visible at this point)
          map.eachLayer(function(layer) {
            if (layer.options && layer.options.group) {
              var group = String(layer.options.group);
              if (!layersByGroup[group]) {
                layersByGroup[group] = [];
              }
              layersByGroup[group].push(layer);

              // Track latest year
              if (!latestYear || parseInt(group) > parseInt(latestYear)) {
                latestYear = group;
              }
            }
          });

          // Store globally for slider access
          window.quickmapLayerCache = layersByGroup;

          // STAGE 2: Hide all years except latest
          Object.keys(layersByGroup).forEach(function(yr) {
            if (yr !== latestYear) {
              layersByGroup[yr].forEach(function(layer) {
                map.removeLayer(layer);
              });
            }
          });

          console.log('Layer cache initialized:', Object.keys(layersByGroup).reduce(function(acc, k) {
            acc[k] = layersByGroup[k].length;
            return acc;
          }, {}));
          console.log('Default year visible:', latestYear);
        }
      "
      )
  }

  # Leaflet legend and title controls removed - using HTML banner/legend system only

  # Vignette overlay
  if (vignette && !is.null(vignette_overlay)) {
    map <- map |>
      addPolygons(
        data = vignette_overlay,
        fillColor = VIGNETTE_STYLE$fillColor,
        fillOpacity = VIGNETTE_STYLE$fillOpacity,
        color = VIGNETTE_STYLE$color,
        weight = VIGNETTE_STYLE$weight
      )
  }

  return(map)
}

#' Generate map layers for interactive or static maps
#'
#' Processes all configured layers (temporal and static) and adds them to the map
#'
#' @param base_map Leaflet map object to add layers to
#' @param measurement_layers Layer configuration from get_measurement_layers()
#' @param target_year Year to display (or "static_only" for static layers only)
#' @param pollutant,pollutant Pollutant name for coloring markers
#' @param colour_scale Color scale name
#' @param data_env Environment containing data objects
#' @param image_scale_factor Scale factor for marker sizing (1.0 for HTML, >1.0 for images)
#' @return Map with all layers added
generate_map_layers <- function(
  base_map,
  measurement_layers,
  target_year,
  pollutant,
  colour_scale,
  data_env,
  image_scale_factor = 1.0
) {
  for (layer_name in names(measurement_layers)) {
    layer_config <- measurement_layers[[layer_name]]
    if (!layer_config$enabled) next

    # Handle temporal vs static layers
    if (layer_config$temporal) {
      # For temporal layers, only process if we have a specific year
      if (target_year != "static_only") {
        year_data <- get_layer_year_data(
          layer_config$data_source,
          target_year,
          data_env
        )
        if (nrow(year_data) == 0) next

        # Filter pollution data for DT and BL layers
        if (layer_config$layer_type %in% c("dt_sites", "bl_nodes")) {
          year_data <- dplyr::filter(year_data, !is.na(.data[[pollutant]]))
          if (nrow(year_data) == 0) next
        }

        layer_data <- prepare_generic_layer_data(
          layer_config,
          year_data,
          pollutant,
          colour_scale
        )
        if (!is.null(layer_data)) {
          # Extract marker_labels from layer config
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
      # Static layers (schools, hospitals, etc.) - always process
      static_data <- get(layer_config$data_source, envir = data_env)
      layer_data <- prepare_generic_layer_data(layer_config, static_data)

      # Extract marker_labels from layer config
      show_labels <- if (!is.null(layer_config$options))
        layer_config$options$marker_labels else FALSE

      base_map <- add_layer(
        base_map,
        layer_data,
        layer_config,
        year = NULL,
        pollutant = NULL,
        colour_scale = NULL,
        label_sizing = 1.0,
        image_scale_factor,
        marker_labels = show_labels
      )
    }
  }
  # use showGroup to show the highest value layer
  print(paste("Setting visible layer:", layer_name))
  base_map <- base_map %>%
    showGroup(layer_name)
  return(base_map)
}


#' Create interactive and/or static pollution maps
#'
#' Main function to create Leaflet maps showing air pollution data with optional
#' schools overlay. Generates both interactive HTML maps and static JPG exports.
#'
#' @param diffusion_tube_file CSV file with diffusion tube data (or "none" to disable). Prepends DATA_PATH environment variable if set.
#'   File should contain 'Easting' and 'Northing' columns plus year columns.
#' @param sensor_file RData file with Breathe London data (or "none" to disable). Prepends DATA_PATH environment variable if set.
#'   File must contain 'dataOAformat' object with siteCode, year, pollutant, lat, lon columns.
#' @param school_file CSV file with school locations (or "none" to disable). Prepends DATA_PATH environment variable if set.
#'   File should contain 'Easting', 'Northing', 'Level', and 'School' columns.
#' @param output_file Output filename for HTML file and JPG files (without extension).
#'   Files are saved in 'aq_maps/' directory.
#' @param image_export If TRUE, generates static JPG exports in addition to interactive HTML map.
#'   Creates one JPG per year with dimensions specified by map_width_px and map_height_px.
#' @param map_width_px Width in pixels for static JPG image exports (default: 1200).
#' @param map_height_px Height in pixels for static JPG image exports (default: 1200).
#' @param boroughs Borough name(s) for boundary display and data filtering.
#'   Can be a single name or vector of names (required parameter).
#' @param pollutant Pollutant type to display: "no2" or "pm25" (default: "no2").
#'   Used for coloring markers and legend generation.
#' @param years Years to display on map. NULL uses all available years from data,
#'   or specify a vector like c(2020, 2021, 2022).
#' @param vignette If TRUE, adds vignette overlay around borough boundary to
#'   darken areas outside the selected borough(s) for visual focus.
#' @param colour_scale Color scale name for pollution values (default: "who_no2").
#'   Options: "who_no2", "stripes_no2", "gla_pm25", "lbw_no2", "lbrut_no2", "lbm_no2", "deltas".
#' @param marker_labels Control marker label visibility (default: FALSE).
#'   - FALSE: No labels shown on any markers
#'   - TRUE: Show pollution values on hover (auto-hide, works on interactive maps only)
#'   - "values_on": Show pollution values always visible (noHide=TRUE)
#'   - "labels": Show custom labels from Label/School column on hover (auto-hide)
#'   - "labels_on": Show custom labels from Label/School column always visible
#'   For CSV data: uses Label column if available, otherwise pollution values
#'   For OA data: shows pollution values (no Label column in this data source)
#'   For schools: always shows School column regardless of mode
#' @param title Page title and banner text for HTML output (default: "Air Quality Map").
#' @param styling_type Controls HTML banner and legend display (default: "none").
#'   - "none": No banner or legend
#'   - "html": HTML banner above map with external HTML legend
#' @param boundary_labels If TRUE, shows borough boundary labels on the map (default: FALSE).
#'   Labels appear on borough polygons and are always visible when enabled.
#' @param banner_colour Color for border and banner styling (default: "#078141" green).
#'   Also used for vignette overlay if vignette is TRUE.
#' @param title Text to display in banner if show_banner is TRUE (default: "Air Quality Map").
#'
#' @return Invisible Leaflet map object. Side effects: Saves HTML file to
#'   \code{aq_maps/} directory. If \code{image_export=TRUE}, also saves JPG
#'   files (one per year).
#'
#' @details
#' This function creates interactive Leaflet maps or static JPG images showing
#' air quality data from multiple sources:
#'
#' \strong{Data Sources:}
#' - Diffusion tubes (CSV): Annual NO2 measurements with Easting/Northing columns
#' - Breathe London (RData): Continuous sensor data with hourly measurements
#' - Schools (CSV): Location data with Level (Primary/Secondary) classifications
#'
#' \strong{Visual Output:}
#' - Interactive maps: Clickable year selector, zoom/pan, marker labels on hover
#' - Static images: High-resolution JPG files suitable for reports/publications
#' - Base map: OpenStreetMap tiles
#' - Markers: Colored shapes (circles=DT sites, diamonds=BL nodes, crosses=schools)
#'
#' \strong{Coordinate Systems:}
#' - Input: British National Grid (Easting/Northing, CRS 27700)
#' - Output: WGS84 (lat/lon, CRS 4326)
#' - Boundary data: Automatic coordinate transformation
#'
#' \strong{Setup Required:}
#' Set \code{Sys.setenv(DATA_PATH = "~/path/to/data")} before sourcing.
#' This allows relative file paths for all data sources.
#'
#' \strong{Marker Sizing:}
#' Base sizes for 1200x1200px reference: Schools (12px cross), DT sites (20px circle),
#' BL nodes (20px diamond). Static images automatically scale markers using geometric mean.
#'
#' \strong{Static-Only Maps:}
#' Create schools-only maps by setting \code{diffusion_tube_file="none"} and \code{sensor_file="none"}.
#' System automatically detects and handles this configuration.
#'
#' \strong{Available Color Scales:}
#' Use with \code{colour_scale} parameter:
#' - \code{who_no2} (default): WHO NO2 guidelines
#' - \code{stripes_no2}: Striped NO2 scale
#' - \code{gla_pm25}: GLA PM2.5 scale
#' - \code{lbw_no2}: Wandsworth NO2 scale
#' - \code{lbrut_no2}: Richmond NO2 scale
#' - \code{lbm_no2}: Merton NO2 scale
#' - \code{deltas}: Year-on-year NO2 changes (blue=improvement, red=deterioration)
#'
#' \strong{Label Display Modes:}
#' - \code{FALSE}: No labels
#' - \code{TRUE}: Values on hover (interactive only)
#' - \code{"values_on"}: Values always visible
#' - \code{"labels"}: Custom labels on hover
#' - \code{"labels_on"}: Custom labels always visible
#'
#' \strong{Borough Colour Palettes:}
#' Use \code{borough_palettes$borough$colour} for banner/border styling:
#' - \code{borough_palettes$merton$purple} - Merton purple (#5F3E94)
#' - \code{borough_palettes$wandsworth$blue} - Wandsworth blue (#01a7f5)
#' - \code{borough_palettes$richmond$navy} - Richmond navy (#00123d)
#' Call \code{show_borough_colours()} to list all available boroughs and colours.
#'
#' @examples
#' # Basic usage (set DATA_PATH first)
#' Sys.setenv(DATA_PATH = "~/path/to/data")
#'
#' # Create interactive map with NO2 data
#' create_pollution_map(
#'   diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
#'   school_file = "schools_Wandsworth.csv",
#'   boroughs = "Wandsworth",
#'   years = 2024,
#'   pollutant = "no2",
#'   output_file = "wandsworth_2024.html"
#' )
#'
#' # Create static JPG export
#' create_pollution_map(
#'   diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
#'   sensor_file = "bl_imperial_annualised_2021_2025.Rdata",
#'   school_file = "schools_Wandsworth.csv",
#'   boroughs = "Wandsworth",
#'   pollutant = "no2",
#'   years = 2024,
#'   image_export = TRUE,
#'   map_width_px = 1920,
#'   map_height_px = 1080,
#'   output_file = "wandsworth_2024"
#' )
#'
#' # Schools-only map (static data)
#' create_pollution_map(
#'   diffusion_tube_file = "none",
#'   sensor_file = "none",
#'   school_file = "schools_Wandsworth.csv",
#'   boroughs = "Wandsworth",
#'   output_file = "schools_only.html"
#' )

#' @seealso Color scales: \code{who_no2} (default), \code{stripes_no2}, \code{gla_pm25},
#'   \code{lbw_no2}, \code{lbrut_no2}, \code{lbm_no2}, \code{deltas} (year-on-year changes)
#'
#' Setup: Set \code{DATA_PATH} environment variable before use
#'
#' Static-only maps: Set both \code{diffusion_tube_file="none"} and \code{sensor_file="none"}

#' @note
#' \itemize{
#'   \item Set \code{DATA_PATH} environment variable before sourcing script
#'   \item Borough names are case-insensitive
#'   \item Year columns in CSV should be named YYYY format (e.g., "2024")
#'   \item Static JPG exports require Chrome/Chromium browser for webshot2
#'   \item All output files saved to \code{aq_maps/} directory (auto-created)
#' }

#' @section Configuration Constants:
#' These constants control system behavior and can be modified in the code:
#'
#' \itemize{
#'   \item{\code{MISSING_DATA_THRESHOLD} (line 68): Filter threshold for data quality (default: 20\%)}
#'   \item{\code{BOUNDARY_CONFIG} (line 340): Borough name corrections and boundary file configuration}
#'   \item{\code{BOUNDARY_STYLES} (line 355): Visual styling for interactive vs static boundary polygons}
#'   \item{\code{VIGNETTE_STYLE} (line 375): Grey overlay appearance outside borough boundaries}
#'   \item{\code{LEGEND_STYLE} (line 383): Legend font sizes and symbol dimensions}
#'   \item{\code{TITLE_STYLES} (line 391): Map title styling and responsive widths}
#' }

#' @section Breaking Changes (v0.8.9):
#' The parameter \code{use_data_labels} was removed and replaced by \code{marker_labels}.
#'
#' \strong{Migration guide:}
#' \itemize{
#'   \item Old: \code{use_data_labels = TRUE}
#'   \item New: \code{marker_labels = TRUE} (shows values on hover, auto-hide)
#'   \item For always-visible values: \code{marker_labels = "values_on"}
#'   \item For custom labels on hover: \code{marker_labels = "labels"}
#'   \item For custom labels always visible: \code{marker_labels = "labels_on"}
#' }
#'
#' @note Consider adding input validation for boundary_names, pollutant, and colour scale parameters

create_pollution_map <- function(
  # initial parameters - file handling
  # input files
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",
  #output file names, image export and image size
  output_file = "pollution_map.html", # name for the HTML and image files
  export_image = NULL, # NULL for no export, c(width, height) for export at dimensions
  # location parameters
  boroughs,
  # data processing parameters
  pollutant = "no2",
  years = NULL,
  # titles
  title = "Air Quality Map", # used for both browser tab and banner
  # styling parameters
  vignette = TRUE,
  colour_scale = "who_no2",
  styling_type = "html", # "none" | "html" - controls HTML banner and legend display
  marker_labels = FALSE, # FALSE | TRUE | "values_on" | "labels" | "labels_on"
  banner_colour = borough_palettes$merton$purple, # show_borough_colours() to list all available
  boundary_labels = FALSE,
  # year control animation parameters
  autoplay = FALSE, # Start animation automatically on load
  play_speed = 500 # Milliseconds per year during animation
) {
  ## Initial setup

  # Unpack export_image parameter into internal variables
  if (is.null(export_image)) {
    image_export <- FALSE
    map_width_px <- 1920
    map_height_px <- 1080
  } else if (export_image == TRUE) {
    image_export <- TRUE
    map_width_px <- 1920
    map_height_px <- 1080
  } else {
    image_export <- TRUE
    map_width_px <- export_image[1]
    map_height_px <- export_image[2]
  }

  # Unpack styling_type parameter into internal variable
  # Only "html" or "none" - controls whether HTML banner/legend is applied
  show_banner <- (styling_type == "html")

  # setup the bounding box and overlays, limited error traps  ####

  borough_sf <- tryCatch(
    get_boundary_sf(boroughs),
    error = function(e) {
      message(e$message)
      return(NULL)
    }
  )

  # create directory to hold the output files
  if (!dir.exists("aq_maps")) dir.create("aq_maps", showWarnings = TRUE)

  # data loading section ####

  # Load CSV data (diffusion tubes)
  if (diffusion_tube_file != "none") {
    csv_result <- load_data_file(
      diffusion_tube_file,
      "csv",
      c("Easting", "Northing")
    )
    if (!is.null(csv_result)) {
      sf_data_wgs84 <- get_temporal_data(csv_result$data) |>
        transform_to_wgs84()
    } else {
      diffusion_tube_file <- "none"
    }
  }

  # Load school data
  if (school_file != "none") {
    school_result <- load_data_file(
      school_file,
      "csv",
      c("Easting", "Northing")
    )
    if (!is.null(school_result)) {
      # Data is accessed by name in generate_map_layers() via layer_config$data_source
      # nolint start: object_usage_linter
      sf_schools_wgs84 <- school_result$data |> transform_to_wgs84()
      # nolint end
    } else {
      school_file <- "none"
    }
  }

  # Load OpenAir format data (BreatheLondon)
  bl_annual_means_sf <- NULL
  if (sensor_file != "none") {
    bl_annual_means_sf <- load_data_file(
      sensor_file,
      "rdata",
      pollutant = pollutant
    )
    if (is.null(bl_annual_means_sf)) {
      sensor_file <- "none"
    }
  }

  # Fallback: use OA data if no CSV data
  if (diffusion_tube_file == "none" && !is.null(bl_annual_means_sf)) {
    sf_data_wgs84 <- bl_annual_means_sf
  }

  # data filtering section ####

  # if vignette, filter out BL points not inside the
  # borough_sf boundary as this will save on file size & increase load speed
  if (sensor_file != "none" && !is.null(borough_sf) && vignette) {
    bl_annual_means_sf <- bl_annual_means_sf |>
      st_filter(borough_sf, .predicate = st_intersects)
  }

  if (is.null(borough_sf)) return()
  if (vignette) vignette_overlay <- create_vignette_overlay(borough_sf)
  bbox <- st_bbox(borough_sf)
  legend_info <- get_colour_legend(colour_scale)

  # create the HMTL map object ####

  # select main map content based on Diffusion Tube file existence, else use
  # the BL data for the map, which is already an SF object
  if (diffusion_tube_file == "none") sf_data_wgs84 <- bl_annual_means_sf

  # extract vector of years to be plotted
  # Handle case where only static layers (schools) exist - no temporal data
  if (diffusion_tube_file == "none" && sensor_file == "none") {
    # No temporal data, set years to a default year for processing
    if (is.null(years)) {
      years <- "static_only"
    }
    # Create dummy sf_data_wgs84 for map initialization (will use borough_sf for bounds)
    sf_data_wgs84 <- borough_sf
  } else {
    # Extract years from available data
    if (is.null(years)) {
      years <- unique(sf_data_wgs84$year_str)
    } else {
      years <- intersect(years, unique(sf_data_wgs84$year_str))
    }
  }

  # add the dynamic layers to the HMTL map
  # MODIFIED: Sections 2 & 3 in create_pollution_map function
  # Replace both sections with this unified approach:

  # Initialize HTML map
  html_map <- leaflet(
    sf_data_wgs84,
    options = leafletOptions(zoomDelta = 0.5, zoomSnap = 0)
    # zoomSnap = 0 means that the zoom snaps to the nearest integer
  ) %>%
    addTiles()

  if (image_export) {
    # Create fresh static map with same data initialization as HTML map
    static_map_template <- leaflet(
      sf_data_wgs84,
      options = leafletOptions(
        zoomControl = FALSE,
        zoomDelta = 0.5,
        zoomSnap = 0
      )
    ) %>%
      addTiles()
  }

  # Get layer configuration
  measurement_layers <- get_measurement_layers(
    diffusion_tube_file,
    sensor_file,
    school_file,
    marker_labels
  )

  # Calculate maximum data value for legend trimming (only from years being mapped)
  data_max <- get_data_maximum(
    measurement_layers,
    pollutant,
    environment(),
    years
  )

  # SINGLE LOOP: add layers to the dyamic HTML map and export an image for each year
  for (yr in unique(years)) {
    # Add layers to HTML map (cumulative - builds interactive HTML map with year selection)
    html_map <- generate_map_layers(
      html_map,
      measurement_layers,
      yr,
      pollutant,
      colour_scale,
      environment(),
      1.0 # Interactive HTML maps use default scale factor (no scaling)
    )

    # Generate fresh static image to export if enabled
    if (image_export) {
      # Calculate marker scale factor for static images using same logic as HTML processing
      marker_scale_factor <- sqrt(
        (map_width_px * map_height_px) / (1200 * 1200)
      )

      # Create fresh yearly map from the template
      static_map <- static_map_template

      # Add the required layers for this group (usually a timeslice like year)
      static_map <- generate_map_layers(
        static_map,
        measurement_layers,
        yr,
        pollutant,
        colour_scale,
        environment(),
        marker_scale_factor
      )

      # Add layers (schools, etc.) to static map exported as images
      static_map <- generate_map_layers(
        static_map,
        measurement_layers,
        "static_only",
        pollutant,
        colour_scale,
        environment(),
        marker_scale_factor
      )

      # Add static map controls and styling
      static_map <- add_map_controls(
        static_map,
        borough_sf,
        vignette_overlay,
        vignette,
        bbox,
        interactive = FALSE,
        years = yr,
        boundary_labels = boundary_labels
      )

      # Save static image
      file_parts <- tools::file_path_sans_ext(basename(output_file))
      html_file <- file.path("aq_maps", paste0(file_parts, "_", yr, ".html"))
      img_file <- file.path("aq_maps", paste0(file_parts, "_", yr, ".jpg"))

      saveWidget(
        static_map,
        file = html_file,
        selfcontained = TRUE,
        title = title
      )

      # Apply HTML banner/legend processing (only if styling_type = "html")
      if (styling_type == "html") {
        tryCatch(
          {
            apply_custom_layout_in_html(
              html_file = html_file,
              title = if (show_banner) title else NULL,
              banner_colour = banner_colour,
              scale_name = colour_scale,
              collapsed_mobile = FALSE, # Keep expanded for static images
              image_mode = TRUE, # Enable image optimization for static JPG export
              image_dimensions = c(map_width_px, map_height_px),
              autoplay = autoplay,
              play_speed = play_speed,
              data_max = data_max
            )
          },
          error = function(e) {
            warning("Failed to apply static image layout: ", e$message)
          }
        )
      }

      webshot2::webshot(
        url = html_file,
        file = img_file,
        vwidth = map_width_px,
        vheight = map_height_px
      )
    }
  }

  # Add HTML controls and styling
  html_map <- add_map_controls(
    html_map,
    borough_sf,
    vignette_overlay,
    vignette,
    bbox,
    interactive = TRUE,
    years = years,
    boundary_labels = boundary_labels
  )

  # Save HTML map if required
  if (!is.null(output_file)) {
    html_file <- file.path("aq_maps", output_file)

    # Save standard leaflet widget
    htmlwidgets::saveWidget(
      html_map,
      file = html_file,
      selfcontained = TRUE,
      title = title
    )

    # Apply custom layout with banner and external legend (only if styling_type = "html")
    if (styling_type == "html") {
      tryCatch(
        {
          apply_custom_layout_in_html(
            html_file = html_file,
            title = if (show_banner) title else NULL,
            banner_colour = banner_colour,
            scale_name = colour_scale,
            collapsed_mobile = TRUE,
            autoplay = autoplay,
            play_speed = play_speed,
            data_max = data_max
          )
        },
        error = function(e) {
          warning("Failed to apply custom layout: ", e$message)
        }
      )
    }

    # Force cleanup of _files folder
    files_folder <- paste0(tools::file_path_sans_ext(html_file), "_files")
    if (dir.exists(files_folder)) {
      unlink(files_folder, recursive = TRUE)
    }
  }

  # Return the map (remove the image export conditional return)
  return(invisible(html_map))
}

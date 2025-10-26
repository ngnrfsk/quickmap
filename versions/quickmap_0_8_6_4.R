# Working, stable production codebase for quickmap ####
# Version 0.8 - Refactor Stage 1

# Rebuilt Architecture:
#   get_measurement_layers() → generate_map_layers() → unified HTML + image output
#   All layers use: prepare_generic_layer_data() → create_generic_icons() → addMarkers()
#   The generic layer genertion functions will be replaced

# Refactor 2
# - Add database import using duckdb
# - divide the code into standalone IO, data processing, map layer generation,
#   map rendering, and utility functions.
# - Replace existing hardcoded layer creation with new generic layer system
# - Rebuild the create_pollution_map() function as a wrapper that uses the new system

# Minor bugs to fix and features to consider:
# - (bug to avoid) replace tick box control with slider for many years
# - in wrapper create_pollution_map() add data cacheing to avoid repeated data loading
# - Develop a uniform approach to text sizing across the code base, that
#   coordinates text sizes depending on the map size, which is largely
#   dependent on whether its for JPG export or screen
# - (bug) Remove the stray temporary HTML files on image generation (eliminate _files folders, temp file cleanup)
# - Simplify and clarify all function names to make more consistent
# - rename parameters and restructure using a ggplot type approach
# - create animations
# - Performance and scalability (lazy loading, batch processing)
# - User experience enhancements (clustering, custom popups, export formats)
# - Error handling and robustness (validation, logging, graceful failures)
# 250910 - changed references to WHO "safe level" to "guideline" in colour scales

# History:
#   Original scripts (pre-0.1):
#     Basic NO2 and schools data import from CSV
#     Simple leaflet map with year selector
#     Basic colour schemes (WHO NO2, small value changes)
#   v0.1 -  Adjusted for long data, OA format compatibility 250520
#   v0.2 -  Added schools locations, improved error handling
#   v0.3 -  Fixed assign_color interval issue, added image export, year labels
#   v0.4 -  Added Breathe London nodes as squares, optional CSV labels
#   v0.5 -  Added year selector functionality
#   v0.6 -  Removed white circles for NA values, OpenAir format support
#   v0.8 -  Refactor 1: Unified architecture with single loop processing
#           Prep for refactor 2
#             Separated data loading from layer creation with generic interfaces
#             Modularised mapping code for both HTML and static export
#             Major changes to symbol and layer generation to improve performance and modularity
#               Single marker-based architecture (circles=DT, diamonds=BL, crosses=schools)
#               Configuration-driven layer system for easy extensibility
#               Integrated image export with unified layer processing
#               Single loop processing for HTML and image generation
#               Generic icon system replacing all hardcoded layer creation
#               Better performance optimization by removing polygon rendering for some data types
#   v0.8.1 - bugs fixed, label size correction, scaling legend to width
#   v0.8.2 - "stripes" colour scheme added https://airqualitystripes.info/
#   v0.8.4 - streamlined addition of map controls, legend with improved style controls
#   v0.8.5 - code cleanup and simplification:
#             - Simplified unified load_data_file() function
#             - Data validation in validate_oa_data, process_oa_data
#             - Updated get_borough_sf() as get_boundary_sf() with configuration constants
#             - Improved error handling and parameter reset behavior
#             - Added get_temporal_data() for flexible temporal data processing during data loading

# Core Functions:
#   create_pollution_map() - Main function with unified single-loop processing
#   generate_map_layers() - Unified layer generation for HTML and images
#   create_generic_icons() - Universal icon system for all layer types
#   get_measurement_layers() - Configuration-driven layer definitions
#   prepare_generic_layer_data() - Unified data preparation
#   add_layer() - Universal layer addition

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

# import and prepares the data from csv files in wide format
import_csv_data <- function(
  file_path,
  required_cols = c("Easting", "Northing")
) {
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
        original_bbox["xmin"] - 0.5 * width,
        original_bbox["ymin"] - 0.5 * height,
        original_bbox["xmax"] + 0.5 * width,
        original_bbox["ymax"] + 0.5 * height
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

VIGNETTE_STYLE <- list(
  fillColor = "grey",
  fillOpacity = 0.4,
  color = "transparent",
  weight = 0
)

LEGEND_STYLE <- list(
  title = "font-size: 12px; font-weight:bold; margin: 2px 0; line-height: 1.4;",
  labels = "font-size: 12px; margin: 2px 0; line-height: 1.4; vertical-align: middle;",
  symbol_size = list(width = 30, height = 30),
  display_size = list(width = 12, height = 12)
)

TITLE_STYLES <- list(
  base = "background-color: rgba(255,255,255,0.8); padding: 2px 2px; border-radius: 3px; text-align: center; margin-top: 4px; line-height: 0.9; margin-left: auto; margin-right: auto;",
  interactive_width = "50vw",
  static_width = "95vw"
)

LABEL_OPTIONS <- labelOptions(
  style = list(
    "font-weight" = "bold",
    padding = "3px 8px",
    "background-color" = "rgba(255,255,255,0.7)",
    "border-color" = "rgba(0,0,0,0.1)",
    "border-radius" = "4px"
  ),
  textsize = "12px",
  direction = "auto",
  noHide = TRUE, # @to do: make configurable
  sticky = TRUE
)


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
      "10-19: WHO Interim 3",
      "20-29: WHO Interim 2",
      "30-39: WHO Interim 1/UK Limit",
      "40-49: Over UK limit",
      "50-60: 5x WHO guideline",
      "60-70: 6x WHO guideline",
      "70-80: 7x WHO guideline",
      "80-90: 8x WHO guideline",
      "90-100: 9x WHO guideline",
      "> 100µg/m3: Over 10x WHO guideline",
      "Site not in use that year"
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
      "  < 5: WHO guideline",
      " 5-10: WHO Interim 4/GLA target",
      "10-15: WHO Interim 3 target",
      "15-20: UK target",
      "20-25: WHO Interim 2 target",
      "25-30",
      "30-35: WHO Interim 1 target",
      "35-40",
      "40-45",
      "45-50",
      "Site not in use that year"
    ),
    title = "PM2.5 annual mean, µg/m3",
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
      "10-19: WHO Interim 3",
      "20-29: WHO Interim 2",
      "30-39: WHO Interim 1/UK Limit",
      "40-49: Over UK limit",
      "50-60: 5x WHO guideline",
      "60-70: 6x WHO guideline",
      "70-80: 7x WHO guideline",
      "80-90: 8x WHO guideline",
      "90-100: 9x WHO guideline",
      "Site not in use that year"
    ),
    title = "NO2 levels",
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
      "10-19: Under Richmond target",
      "20-29: WHO Interim 2",
      "30-39: Under UK target",
      "40-49: Over UK target",
      "50-60: 5x WHO guideline",
      "60-70: 6x WHO guideline",
      "70-80: 7x WHO guideline",
      "80-90: 8x WHO guideline",
      "90-100: 9x WHO guideline",
      "Site not in use that year"
    ),
    title = "NO2 levels"
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
      "10-19: WHO Interim 3",
      "20-29: Under Wandsworth target",
      "30-39: Under UK target",
      "40-49: Over UK target",
      "50-60: 5x WHO guideline",
      "60-70: 6x WHO guideline",
      "70-80: 7x WHO guideline",
      "80-90: 8x WHO guideline",
      "90-100: 9x WHO guideline",
      "Site not in use that year"
    ),
    title = "NO2 levels"
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
      "10-19: WHO Interim 3",
      "20-29: WHO Interim 2",
      "30-39: UK/WHO Interim 1 target",
      "40-49: Over UK target",
      "50-60: 5x WHO guideline",
      "60-70: 6x WHO guideline",
      "70-80: 7x WHO guideline",
      "80-90: 8x WHO guideline",
      "90-100: 9x WHO guideline",
      "Site not in use that year"
    ),
    title = "NO2 levels"
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
      "7.5-10 Under GLA/WHO Interim 1 target",
      "10-12.5",
      "12.5-15: Under WHO Interim 2 target",
      "15-20: Under UK target",
      "20-25: Under WHO Interim 2 target",
      "> 25",
      "Site not in use that year"
    ),
    title = "PM2.5 annual ug/m3"
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

# Get colour legend info from unified scale
get_colour_legend <- function(scale = "lbrut_no2") {
  if (!scale %in% names(colour_scales)) {
    stop("Unknown scale: ", scale)
  }
  with(
    colour_scales[[scale]],
    list(
      colors = colours,
      labels = labels,
      title = title,
      thresholds = thresholds
    )
  )
}

# Assign colour to a value based on scale
assign_colour <- function(value, scale = "lbrut_no2") {
  if (is.na(value) || !is.numeric(value)) return("white")
  if (!scale %in% names(colour_scales)) stop("Invalid scale specified.")

  thresholds <- colour_scales[[scale]]$thresholds
  colours <- colour_scales[[scale]]$colours
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

#' Generate HTML legend structure from colour_scale
#'
#' Creates a collapsible legend with header, toggle arrow, and color-coded items.
#' Mobile responsive: automatically collapses on screens < 480px if enabled.
#'
#' @param scale_name Name of scale in colour_scales list (e.g., "who_no2")
#' @param collapsed_mobile Should legend start collapsed on mobile (default TRUE)
#' @return Character string containing complete HTML legend structure
#' @details Validates:
#'   - Scale exists in colour_scales
#'   - colours and labels arrays have matching lengths
#'   Converts all colors to hex format for CSS compatibility
generate_legend_html <- function(scale_name, collapsed_mobile = TRUE) {
  # Validate scale exists
  if (!scale_name %in% names(colour_scales)) {
    stop(
      "Scale '",
      scale_name,
      "' not found in colour_scales. ",
      "Available scales: ",
      paste(names(colour_scales), collapse = ", ")
    )
  }

  legend_scale <- colour_scales[[scale_name]]

  # Validate structure integrity
  if (length(legend_scale$colours) != length(legend_scale$labels)) {
    stop(sprintf(
      "Mismatch in colour_scale '%s': %d colours vs %d labels",
      scale_name,
      length(legend_scale$colours),
      length(legend_scale$labels)
    ))
  }

  # Convert all colors to hex codes
  hex_colors <- convert_colors_to_hex(legend_scale$colours)

  # Generate individual legend items
  legend_items <- sapply(1:length(hex_colors), function(i) {
    sprintf(
      '    <div class="legend-item"><div class="legend-symbol" style="background: %s;"></div><span>%s</span></div>',
      hex_colors[i],
      legend_scale$labels[i]
    )
  })

  legend_items_html <- paste(legend_items, collapse = "\n")

  # Optional mobile collapse script
  mobile_script <- if (collapsed_mobile) {
    '  if (window.innerWidth <= 480) {
    document.getElementById("mapLegend").classList.add("collapsed");
  }'
  } else {
    ''
  }

  # Return complete legend HTML structure
  sprintf(
    '</div>
<div class="legend" id="mapLegend">
  <div class="legend-header" onclick="this.parentElement.classList.toggle(\'collapsed\')">
    <span class="legend-toggle">▼</span>
    <span>%s</span>
  </div>
  <div class="legend-items">
%s
  </div>
</div>
<script>
%s
</script>
',
    legend_scale$title,
    legend_items_html,
    mobile_script
  )
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
#' @param banner_text Text for banner (NULL to skip banner entirely)
#' @param banner_color Hex color for banner background (default "#2c3e50")
#' @param scale_name Name of colour_scale to use for legend (e.g., "who_no2")
#' @param collapsed_mobile Should legend start collapsed on mobile (default TRUE)
#' @return Invisibly returns TRUE on success
#' @details Uses flexbox layout:
#'   - Banner: fixed height at top (optional)
#'   - Map: flex: 1 (fills remaining space)
#'   - Legend: fixed height at bottom (collapsible)
#'   Layout is 100vh total height with no scrollbars
apply_custom_layout_in_html <- function(
  html_file,
  banner_text = NULL,
  banner_color = "#2c3e50",
  scale_name,
  collapsed_mobile = TRUE
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

  # Custom CSS for banner/legend layout
  # NOTE: All % signs must be escaped as %% for sprintf()
  custom_css <- "\n<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { height: 100%%; font-family: Arial, sans-serif; overflow: hidden; }
  body { display: flex; flex-direction: column; }
  
  .banner { 
    background: %s; 
    color: white; 
    padding: 1.25rem; 
    text-align: center; 
    font-size: 1.3rem;
    line-height: 1.3em;
    flex-shrink: 0;
  }
  
  .map-container { flex: 1; position: relative; min-height: 0; }
  .map-container > div { height: 100%% !important; }
  
  .legend { 
    background: #f8f9fa; 
      border-top: 2px solid #dee2e6; 
    flex-shrink: 0; 
  }
  
  .legend-header { 
    padding: 0.9375rem 1.25rem;
    cursor: pointer; 
    user-select: none;
    display: flex;
    gap: 0.625rem;
    align-items: center;
    font-weight: bold;
    background: #e9ecef;
  }
  
  .legend-header:hover { background: #dee2e6; }
      
      .legend-toggle { 
        transition: transform 0.3s ease;
        font-size: 0.8em;
      }
    
    .legend.collapsed .legend-toggle { transform: rotate(-90deg); }
    
    .legend-items { 
      padding: 0.625rem;
      display: flex; 
      gap: 0.625rem;
      justify-content: center; 
      flex-wrap: wrap;
      max-height: 18.75rem;
      overflow: hidden;
      transition: max-height 0.3s ease, padding 0.3s ease;
    }
    
    .legend.collapsed .legend-items { 
      max-height: 0; 
      padding: 0 0.25rem;
    }
    
    .legend-item { display: flex; align-items: center; gap: 0.625rem; }
    
    .legend-symbol { 
      width: 1.25rem;
      height: 1.25rem;
      border-radius: 50%%; 
      border: 2px solid rgba(0,0,0,0.2); 
    }
    
    /* Small phones (320-374px) */
      @media (max-width: 374px) {
        .banner { 
          padding: 0.5rem 0.25rem;
          font-size: 0.9rem;
          line-height: 1.2em;
        }
        .legend-header { 
          padding: 0.5rem 0.75rem;
          font-size: 0.9rem;
          gap: 0.375rem;
        }
        .legend-items { 
          gap: 0.5rem;
          padding: 0.2rem;      /* Was 0.2rem */
          flex-wrap: wrap;
          font-size: 0.7rem;
        }
        .legend-item { gap: 0.2rem; }  /* Was 0.325rem */
        .legend-symbol { 
          width: 0.7rem;
          height: 0.7rem;
          border-width: 1px;    /* Add this */
        }
      }
    /* Standard phones (375-480px) */
    @media (min-width: 375px) and (max-width: 480px) {
      .banner { 
        padding: 0.625rem 0.375rem;
        font-size: 1rem;
        line-height: 1.25em;
      }
      .legend-header { 
        padding: 0.625rem 1rem;
        font-size: 1rem;
        gap: 0.5rem;
      }
      .legend-items { 
        gap: 0.625rem;
        padding: 0.3rem;
        flex-wrap: wrap;
        font-size: 0.85rem;
      }
      .legend-item { gap: 0.25rem; }
      .legend-symbol { 
        width: 0.9rem;
        height: 0.9rem;
        border-width: 1px;
      }
    }
    /* Landscape phones - use intermediate sizing */
    @media (max-width: 850px) and (orientation: landscape) {
      .banner { 
        padding: 0.75rem 0.5rem;
        font-size: 1.1rem;
        line-height: 1.3em;
      }
      .legend-header { 
        padding: 0.75rem 1rem;
        font-size: 0.95rem;
        gap: 0.5rem;
      }
      .legend-items { 
        gap: 0.625rem;
        padding: 0.4rem;
        flex-wrap: wrap;
        font-size: 0.8rem;
      }
      .legend-item { gap: 0.3rem; }
      .legend-symbol { 
        width: 0.85rem;
        height: 0.85rem;
        border-width: 1px;
      }
      .legend.collapsed .legend-toggle { transform: rotate(-90deg); }
    }
    </style>\n"

  # quickmap_0_8_6_3.R uses new mobile sizes to be multiply adaptive
  # 0.8.6.x test a range of settings for mobile

  # Insert banner color into CSS
  custom_css <- sprintf(custom_css, banner_color)

  # Insert viewport and CSS before </head>
  html_text <- sub(
    "</head>",
    paste0(viewport_meta, custom_css, "</head>"),
    html_text
  )

  # Build banner HTML (optional)
  banner_html <- if (!is.null(banner_text)) {
    sprintf(
      '<div class="banner">%s</div>\n<div class="map-container">\n',
      banner_text
    )
  } else {
    '<div class="map-container">\n'
  }

  # Insert banner/container after <body> tag (handles attributes)
  html_text <- sub("(<body[^>]*>)", paste0("\\1\n", banner_html), html_text)

  # Generate and insert legend before </body>
  legend_html <- generate_legend_html(scale_name, collapsed_mobile)
  html_text <- sub("</body>", paste0(legend_html, "</body>"), html_text)

  # Write modified HTML back to file
  writeLines(html_text, html_file)

  return(invisible(TRUE))
}

# Unified icon creation function for all point layers
create_generic_icons <- function(
  data,
  layer_type,
  pollutant = NULL,
  scale_to_use = NULL
) {
  # Determine shape and size @to do - make this configurable
  shape_config <- switch(
    layer_type,
    "schools" = list(shape = 'cross', size = 8), # Keep current working size
    "dt_sites" = list(shape = 'circle', size = 15), # Keep current working size
    "bl_nodes" = list(shape = 'diamond', size = 15), # Keep current working size
    stop("Unknown layer type: ", layer_type)
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
      sapply(data[[pollutant]], assign_colour, scale = scale_to_use)
    },
    "bl_nodes" = {
      # Use assign_colour for continuous pollution data
      sapply(data[[pollutant]], assign_colour, scale = scale_to_use)
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
  border_color = "#078141",
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
      border_color,
      border_radius,
      padding
    ),
    map
  )

  return(styled_map)
}

# @ deprecated function
# Add full-width banner above map using add_control
# add_full_width_banner_control <- function(
#   map,
#   banner_text = "Air Quality Map",
#   background_color = "#078141",
#   text_color = "white",
#   font_size = "18px",
#   padding = "15px"
# ) {
#   banner_html <- HTML(sprintf(
#     '
#     <div style="
#       position: fixed;
#       top: 0;
#       left: 0;
#       width: 100vw;
#       background: linear-gradient(90deg, %s, #0a9d4a);
#       color: %s;
#       text-align: center;
#       padding: %s;
#       font-size: %s;
#       font-weight: bold;
#       box-sizing: border-box;
#       z-index: 500;
#       pointer-events: none;
#     ">
#       %s
#     </div>
#   ',
#     background_color,
#     text_color,
#     padding,
#     font_size,
#     banner_text
#   ))
#
#   map %>%
#     addControl(
#       html = banner_html,
#       position = "topleft",
#       className = "banner-control"
#     )
# }

# @ deprecated function
# # Combined function to add all styling elements
# add_map_styling <- function(
#   map,
#   border_color = "#078141",
#   border_width = "5px",
#   show_banner = TRUE,
#   banner_text = "Air Quality Map"
# ) {
#   # Add banner if requested
#   if (show_banner) {
#     map <- add_full_width_banner_control(map, banner_text)
#   }
#
#   return(map)
# }

# STEP 1: Create layer configuration system
get_measurement_layers <- function(
  csv_data_file,
  oa_data_file,
  school_file,
  use_data_labels
) {
  list(
    bl_nodes = list(
      enabled = (oa_data_file != "none"),
      data_source = "bl_annual_means_sf",
      layer_type = "bl_nodes",
      temporal = TRUE,
      prepare_function = "prepare_bl_layer_data"
    ),
    dt_sites = list(
      enabled = (csv_data_file != "none"),
      data_source = "sf_data_wgs84",
      layer_type = "dt_sites",
      temporal = TRUE,
      prepare_function = "prepare_dt_layer_data",
      options = list(use_data_labels = use_data_labels)
    ),
    schools = list(
      enabled = (school_file != "none"),
      data_source = "sf_schools_wgs84",
      layer_type = "schools",
      temporal = FALSE,
      prepare_function = "prepare_static_layer_data"
    )
  )
}

# Create data preparation functions
# Re-add this function (it's still needed):
prepare_bl_layer_data <- function(oa_subset, pollutant, scale_to_use) {
  # Return NULL if no data to process
  if (nrow(oa_subset) == 0) return(NULL)

  # Pre-compute labels only (colors handled by icons)
  labels <- paste(round(oa_subset[[pollutant]], 0), "ug/m3")

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
  scale_to_use,
  use_data_labels
) {
  # Pre-compute colors for all points
  colors <- sapply(
    subset_data[[pollutant]],
    assign_colour,
    scale = scale_to_use
  )

  # Pre-compute labels based on data or values
  labels <- if (use_data_labels) {
    paste(subset_data$Label)
  } else {
    # return a blank set of values of the length of subset_data
    paste("")
    # @to do
    #
    # value_str <- ifelse(
    #   is.na(subset_data[[pollutant]]),
    #   "",
    #   paste(as.integer(subset_data[[pollutant]]), "ug/m3")
    # )
    # value_str
  }

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
  scale_to_use = NULL
) {
  # Route to appropriate preparation function based on layer type
  switch(
    layer_config$layer_type,
    "bl_nodes" = {
      prepare_bl_layer_data(year_data, pollutant, scale_to_use)
    },
    "dt_sites" = {
      use_labels <- if (!is.null(layer_config$options))
        layer_config$options$use_data_labels else FALSE
      prepare_dt_layer_data(year_data, pollutant, scale_to_use, use_labels)
    },
    "schools" = {
      prepare_static_layer_data(year_data)
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
#' @param scale_to_use The scale to use for icons
#' @param label_sizing Scaling factor for label size (default 1.0)
#' @return Updated map object with new layer
add_layer <- function(
  map,
  layer_data,
  layer_config,
  year = NULL,
  pollutant = NULL,
  scale_to_use = NULL,
  label_sizing = 1.0
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
    scale_to_use
  )

  # Calculate label text size
  label_text_size <- as.character(12 * label_sizing)

  # Common label options
  label_opts <- labelOptions(
    noHide = TRUE,
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


# Gneralise static layer preparation code
prepare_static_layer_data <- function(static_sf) {
  # Pre-compute labels for schools
  labels <- static_sf$School

  # Return structured data ready for generic processing
  # (same pattern as other layers)
  list(
    data = static_sf,
    labels = labels,
    layer_type = "schools" # Add layer type for generic processing
  )
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

# Helper to add boundary polygons
add_boundary_polygons <- function(map, borough_sf, interactive) {
  style <- BOUNDARY_STYLES[[if (interactive) "interactive" else "static"]]
  label <- if (interactive) ~NAME else NULL
  labelOptions <- if (interactive) LABEL_OPTIONS else NULL

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
  legend_info = NULL,
  title_prefix = "",
  borough_sf = NULL,
  vignette_overlay = NULL,
  vignette_overlay_on = FALSE,
  bbox,
  show_title = TRUE,
  show_legend = TRUE,
  interactive = TRUE,
  years
) {
  # Validation
  if (is.null(years)) stop("years parameter is required")
  if (is.null(bbox)) stop("bbox parameter is required")

  # Add boundaries
  if (!is.null(borough_sf)) {
    map <- add_boundary_polygons(map, borough_sf, interactive)
  }

  # Fit bounds
  options <- if (interactive) list(padding = c(30, 30)) else NULL
  map <- map |>
    fitBounds(
      lng1 = unname(bbox["xmin"]),
      lat1 = unname(bbox["ymin"]),
      lng2 = unname(bbox["xmax"]),
      lat2 = unname(bbox["ymax"]),
      options = options
    )

  # Layer control
  baseGroups <- if (interactive && length(years) > 1) years else NULL
  if (!is.null(baseGroups)) {
    map <- map |>
      addLayersControl(
        baseGroups = baseGroups,
        options = layersControlOptions(collapsed = FALSE, position = 'topleft')
      )
  }

  # Legend
  if (show_legend) {
    if (is.null(legend_info))
      stop("legend_info is required when show_legend = TRUE")
    color_symbols <- Map(
      f = makeSymbol,
      shape = 'rect',
      fillColor = legend_info$colors,
      color = 'black',
      width = LEGEND_STYLE$symbol_size$width,
      height = LEGEND_STYLE$symbol_size$height,
      opacity = 1,
      fillOpacity = 1
    )
    map <- map |>
      addLegendImage(
        images = color_symbols,
        labels = legend_info$labels,
        title = htmltools::tags$div(
          legend_info$title,
          style = LEGEND_STYLE$title
        ),
        labelStyle = LEGEND_STYLE$labels,
        width = LEGEND_STYLE$display_size$width,
        height = LEGEND_STYLE$display_size$height,
        position = "bottomright"
      )
  }

  # Title, which includes some complex logic to handle interactive vs static
  if (show_title && nzchar(title_prefix)) {
    title_text <- if (interactive) title_prefix else
      paste(title_prefix, if (length(years) > 1) years[1] else years)
    map <- add_title(map, title_text, interactive)
  }

  # Vignette overlay
  if (vignette_overlay_on && !is.null(vignette_overlay)) {
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

# NEW FUNCTION: Unified layer generation for both HTML and image export
generate_map_layers <- function(
  base_map,
  measurement_layers,
  target_year,
  pollutant,
  scale_to_use,
  data_env
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
          scale_to_use
        )
        if (!is.null(layer_data)) {
          base_map <- add_layer(
            base_map,
            layer_data,
            layer_config,
            target_year,
            pollutant,
            scale_to_use
          )
        }
      }
    } else {
      # Static layers (schools, hospitals, etc.) - always process
      static_data <- get(layer_config$data_source, envir = data_env)
      layer_data <- prepare_generic_layer_data(layer_config, static_data)
      base_map <- add_layer(base_map, layer_data, layer_config)
    }
  }
  # use showGroup to show the highest value layer
  print(paste("Setting visible layer:", layer_name))
  base_map <- base_map %>%
    showGroup(layer_name)
  return(base_map)
}


# MAIN FUNCTION create_pollution_map: map data with optional school/points overlay ####
# TODO: work out the correct the use of the show_banner and show_legend parameters now that HTML is used to correctly display these
# TODO: Add default value for boroughs parameter to improve usability. Currently required with no default, causing "argument 'boroughs' is missing" error
# TODO: do error trap for colour scale and invalid pollutants

create_pollution_map <- function(
  # initial parameters - file handling
  # input files
  csv_data_file = "none",
  oa_data_file = "none",
  school_file = "none",
  #output file names, image export and image size
  output_file = "pollution_map.html", # if NULL no output file
  image_export = FALSE,
  map_width_px = 1200,
  map_height_px = 1200,
  # location parameters
  boroughs,
  # data processing parameters
  pollutant = "no2",
  years_to_plot = NULL,
  # styling parameters
  vignette_overlay_on = TRUE,
  scale_to_use = "who_no2",
  title_prefix = "",
  use_data_labels = FALSE,
  html_page_title = "Air pollution map",
  show_legend = TRUE,
  show_title = TRUE,
  border_color = "#078141",
  banner_color = "#078141", # Optional: green banner (or use "#2c3e50" for dark blue)
  border_width = "5px",
  show_banner = FALSE,
  banner_text = "Air Quality Map"
) {
  # initial setup
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
  if (csv_data_file != "none") {
    csv_result <- load_data_file(csv_data_file, "csv", c("Easting", "Northing"))
    if (!is.null(csv_result)) {
      sf_data_wgs84 <- get_temporal_data(csv_result$data) |>
        transform_to_wgs84()
    } else {
      csv_data_file <- "none"
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
      sf_schools_wgs84 <- school_result$data |> transform_to_wgs84()
    } else {
      school_file <- "none"
    }
  }

  # Load OpenAir format data (BreatheLondon)
  bl_annual_means_sf <- NULL
  if (oa_data_file != "none") {
    bl_annual_means_sf <- load_data_file(
      oa_data_file,
      "rdata",
      pollutant = pollutant
    )
    if (is.null(bl_annual_means_sf)) {
      oa_data_file <- "none"
    }
  }

  # Fallback: use OA data if no CSV data
  if (csv_data_file == "none" && !is.null(bl_annual_means_sf)) {
    sf_data_wgs84 <- bl_annual_means_sf
  }

  # data filtering section ####

  # if vignette_overlay_on, filter out BL points not inside the
  # borough_sf boundary as this will save on file size & increase load speed
  if (oa_data_file != "none" && !is.null(borough_sf) && vignette_overlay_on) {
    bl_annual_means_sf <- bl_annual_means_sf |>
      st_filter(borough_sf, .predicate = st_intersects)
  }

  if (is.null(borough_sf)) return()
  if (vignette_overlay_on)
    vignette_overlay <- create_vignette_overlay(borough_sf)
  bbox <- st_bbox(borough_sf)
  legend_info <- get_colour_legend(scale_to_use)

  # create the HMTL map object ####

  # select main map content based on Diffusion Tube file existence, else use
  # the BL data for the map, which is already an SF object
  if (csv_data_file == "none") sf_data_wgs84 <- bl_annual_means_sf

  # extract vector of years to be plotted
  if (is.null(years_to_plot)) {
    years_to_plot <- unique(sf_data_wgs84$year_str)
  } else {
    years_to_plot <- intersect(years_to_plot, unique(sf_data_wgs84$year_str))
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
    # Create fresh static map
    static_map_template <- leaflet(
      options = leafletOptions(
        zoomControl = FALSE
      )
    ) %>%
      addTiles()
  }

  # Get layer configuration
  measurement_layers <- get_measurement_layers(
    csv_data_file,
    oa_data_file,
    school_file,
    use_data_labels
  )

  # SINGLE LOOP: add layers to the dyamic HTML map and export an image for each year
  for (yr in unique(years_to_plot)) {
    # Add layers to HTML map (cumulative - builds interactive HTML map with year selection)
    html_map <- generate_map_layers(
      html_map,
      measurement_layers,
      yr,
      pollutant,
      scale_to_use,
      environment()
    )

    # Generate fresh static image to export if enabled
    if (image_export) {
      # Create fresh yearly map from the template
      static_map <- static_map_template

      # Add the required layers for this group (usually a timeslice like year)
      static_map <- generate_map_layers(
        static_map,
        measurement_layers,
        yr,
        pollutant,
        scale_to_use,
        environment()
      )

      # Add layers (schools, etc.) to static map exported as images
      static_map <- generate_map_layers(
        static_map,
        measurement_layers,
        "static_only",
        pollutant,
        scale_to_use,
        environment()
      )

      # Add static map controls and styling
      static_map <- add_map_controls(
        static_map,
        legend_info,
        title_prefix,
        borough_sf,
        vignette_overlay,
        vignette_overlay_on,
        bbox,
        show_title = show_title,
        show_legend = show_legend,
        interactive = FALSE,
        years = yr
      )

      # Save static image
      file_parts <- tools::file_path_sans_ext(basename(output_file))
      html_file <- file.path("aq_maps", paste0(file_parts, "_", yr, ".html"))
      img_file <- file.path("aq_maps", paste0(file_parts, "_", yr, ".jpg"))

      saveWidget(
        static_map,
        file = html_file,
        selfcontained = TRUE,
        title = html_page_title
      )
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
    legend_info,
    title_prefix,
    borough_sf,
    vignette_overlay,
    vignette_overlay_on,
    bbox,
    show_title,
    show_legend,
    interactive = TRUE,
    years = years_to_plot
  )

  # @ deprecated
  # # Apply custom styling (banner and legend) using leaflet controls
  # html_map <- add_map_styling(
  #   html_map,
  #   border_color = border_color,
  #   border_width = border_width,
  #   show_banner = show_banner,
  #   banner_text = banner_text
  # )

  # Save HTML map if required
  if (!is.null(output_file)) {
    html_file <- file.path("aq_maps", output_file)

    # Save standard leaflet widget
    htmlwidgets::saveWidget(
      html_map,
      file = html_file,
      selfcontained = TRUE,
      title = html_page_title
    )

    # Apply custom layout with banner and external legend using html/CSS/JS
    tryCatch(
      {
        apply_custom_layout_in_html(
          html_file = html_file,
          banner_text = if (show_banner) banner_text else NULL,
          banner_color = border_color, # Reuse border_color parameter
          scale_name = scale_to_use, # Uses existing scale parameter
          collapsed_mobile = TRUE
        )
      },
      error = function(e) {
        warning("Failed to apply custom layout: ", e$message)
      }
    )

    # Force cleanup of _files folder
    files_folder <- paste0(tools::file_path_sans_ext(html_file), "_files")
    if (dir.exists(files_folder)) {
      unlink(files_folder, recursive = TRUE)
    }
  }
  #
  # ### END OF NEW CODE
  #
  #   # Save HTML map if required
  #   if (!is.null(output_file)) {
  #     html_file <- file.path("aq_maps", output_file)
  #
  #     # Save the leaflet widget directly (banner and legend styling already applied)
  #     htmlwidgets::saveWidget(
  #       html_map,
  #       file = html_file,
  #       selfcontained = TRUE,
  #       title = html_page_title
  #     )
  #
  #     # Apply border styling by modifying the HTML file after saving
  #     if (border_width != "0px") {
  #       html_content <- readLines(html_file)
  #
  #       # Add CSS for border styling
  #       border_css <- sprintf(
  #         '
  #       <style>
  #         body {
  #           margin: 0;
  #           padding: 0;
  #         }
  #         #htmlwidget_container {
  #           border: %s solid %s !important;
  #           border-radius: 8px;
  #           box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  #           margin: 0;
  #           padding: 0;
  #         }
  #         .leaflet-container {
  #           border-radius: 8px;
  #         }
  #         .banner-control {
  #           background: transparent !important;
  #           border: none !important;
  #           box-shadow: none !important;
  #         }
  #       </style>
  #       ',
  #         border_width,
  #         border_color
  #       )
  #
  #       # Insert CSS before </head>
  #       html_content <- gsub(
  #         "</head>",
  #         paste0(border_css, "</head>"),
  #         html_content
  #       )
  #
  #       # Write back to file
  #       writeLines(html_content, html_file)
  #     }
  #
  #     # Force cleanup of _files folder as there seems to be a bug
  #     files_folder <- paste0(tools::file_path_sans_ext(html_file), "_files")
  #     if (dir.exists(files_folder)) {
  #       unlink(files_folder, recursive = TRUE)
  #     }
  #   }

  # Return the map (remove the image export conditional return)
  return(invisible(html_map))
}

# quickmap - Air Quality Mapping for R
# Version 0.9.0.4  2025/11/22, 15:50

packages <- c(
  "leaflet",
  "sf",
  "dplyr",
  "leaflegend",
  "tidyr",
  "lubridate",
  "webshot2",
  "htmlwidgets",
  "htmltools",
  "leaflet.extras"
)

installed <- packages %in% rownames(installed.packages())
if (any(!installed)) {
  install.packages(packages[!installed])
}

lapply(packages, library, character.only = TRUE)

# Note: Linter warnings for package functions are false positives.
# All required packages are loaded via lapply() above.
# Functions from dplyr, sf, leaflet, leaflegend, and other packages are available at runtime.

# NULL coalescing operator - returns y if x is NULL, otherwise x
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
    result <- gsub(
      placeholder,
      replacements[[placeholder]],
      result,
      fixed = TRUE
    )
  }
  return(result)
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

load_rdata_file <- function(file_path, pollutant) {
  load(file.path(Sys.getenv("DATA_PATH"), file_path), verbose = TRUE)

  if (!exists("dataOAformat")) {
    stop("dataOAformat object not found in RData file")
  }

  return(process_oa_data(dataOAformat, pollutant))
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
#' @param data_env Environment containing data objects
#' @param years Character vector of year strings to include
#' @return Maximum value or NULL if no data
#' @family layer
get_data_maximum <- function(
  measurement_layers,
  pollutant,
  data_env,
  years = NULL
) {
  get_pollutant_col <- function(layer_type) {
    switch(layer_type, "dt_sites" = "no2", "bl_nodes" = pollutant, NULL)
  }

  layer_maxima <- lapply(measurement_layers, function(layer_config) {
    if (
      !layer_config$enabled ||
        !layer_config$temporal ||
        layer_config$layer_type == "schools"
    ) {
      return(NULL)
    }

    data <- tryCatch(
      get(layer_config$data_source, envir = data_env, inherits = FALSE),
      error = function(e) NULL
    )
    if (is.null(data) || nrow(data) == 0) return(NULL)

    if (!is.null(years) && "year_str" %in% names(data)) {
      data <- data[data$year_str %in% years, ]
      if (nrow(data) == 0) return(NULL)
    }

    pollutant_col <- get_pollutant_col(layer_config$layer_type)
    if (is.null(pollutant_col) || !pollutant_col %in% names(data)) return(NULL)

    max_val <- max(data[[pollutant_col]], na.rm = TRUE)
    if (is.infinite(max_val) || is.nan(max_val)) NULL else max_val
  })

  max_values <- unlist(Filter(Negate(is.null), layer_maxima))

  if (length(max_values) > 0) {
    result <- max(max_values)
    message(
      "Legend trimming: data_max = ",
      round(result, 2),
      " (from ",
      if (is.null(years)) "all years" else
        paste(length(years), "selected years"),
      ")"
    )
    return(result)
  } else {
    message("Legend trimming: No data found, showing full legend")
    return(NULL)
  }
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

  scale
}


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
      title = "Air Quality Map"
    ),
    legend = list(
      show = TRUE,
      background = "white"
    ),
    map = list(
      vignette = TRUE,
      base_tiles = NULL,
      zoom_level = NULL,
      boundary_labels = FALSE,
      marker_labels = FALSE
    ),
    controls = list(
      autoplay = FALSE,
      play_speed = 500,
      background = NULL,
      text_color = NULL
    )
  )
}

#' Load theme from YAML file with fallback to defaults
#' @param theme_file Path to YAML theme file (NULL for defaults)
#' @return Complete theme list (merged with defaults)
#' @family config
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

  max_width <- calculate_max_range_width(legend_scale$labels)

  symbol_index <- 1
  legend_items <- list()
  symbol_key_items <- list()

  for (i in seq_along(hex_colors)) {
    parsed <- parse_legend_label(legend_scale$labels[i])
    text_color <- get_contrast_text_color(hex_colors[i])

    if (!is.null(parsed$description)) {
      symbol <- get_symbol_for_index(symbol_index)
      range_with_symbol <- paste0(parsed$range, " ", symbol)
      symbol_index <- symbol_index + 1

      padded_range <- sprintf(paste0("%-", max_width, "s"), range_with_symbol)

      symbol_text <- paste(symbol, parsed$description)
      padded_symbol_text <- sprintf(
        paste0("%-", max_width + 10, "s"),
        symbol_text
      )

      symbol_key_items[[length(symbol_key_items) + 1]] <- sprintf(
        '      <span style="background: %s; color: %s;">%s</span>',
        hex_colors[i],
        text_color,
        padded_symbol_text
      )
    } else {
      padded_range <- sprintf(paste0("%-", max_width, "s"), parsed$range)
    }

    legend_items[[i]] <- sprintf(
      '      <div class="legend-item"><span style="background: %s; color: %s;">%s</span></div>',
      hex_colors[i],
      text_color,
      padded_range
    )
  }

  legend_items_html <- paste(legend_items, collapse = "\n")

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
load_banner_css <- function(banner_colour = "#2c3e50", image_mode = FALSE) {
  banner_dir <- get_package_dir("banner")
  css_variant <- if (image_mode) "banner-image.css" else "banner-interactive.css"
  css_file <- file.path(banner_dir, css_variant)
  css_content <- read_template_file(css_file)

  replacements <- list("{{banner_bg}}" = banner_colour)

  if (!image_mode) {
    mobile_file <- file.path(banner_dir, "mobile.css")
    replacements[["{{mobile_css}}"]] <- read_template_file(mobile_file)
  }

  css_content <- apply_template_replacements(css_content, replacements)
  sprintf("\n<style>\n%s\n</style>\n", css_content)
}

#' @keywords internal
load_legend_css <- function(banner_colour = "#2c3e50", image_mode = FALSE) {
  legend_dir <- get_package_dir("legend")
  css_variant <- if (image_mode) "legend-image.css" else "legend-interactive.css"
  css_file <- file.path(legend_dir, css_variant)
  css_content <- read_template_file(css_file)

  legend_header_bg <- lighten_color(banner_colour, 85)
  legend_header_hover <- lighten_color(banner_colour, 75)

  replacements <- list(
    "{{legend_header_bg}}" = legend_header_bg,
    "{{legend_header_hover}}" = legend_header_hover
  )

  if (!image_mode) {
    mobile_file <- file.path(legend_dir, "mobile.css")
    replacements[["{{mobile_css}}"]] <- read_template_file(mobile_file)
  }

  css_content <- apply_template_replacements(css_content, replacements)
  sprintf("\n<style>\n%s\n</style>\n", css_content)
}

#' @keywords internal
build_static_map_for_year <- function(template, year, measurement_layers,
                                      pollutant, colour_scale, data_env,
                                      scale_factor) {
  template |>
    generate_map_layers(measurement_layers, year, pollutant,
                       colour_scale, data_env, scale_factor) |>
    generate_map_layers(measurement_layers, "static_only", pollutant,
                       colour_scale, data_env, scale_factor)
}

finalize_and_save_map <- function(map, html_file, borough_sf, vignette_overlay,
                                  vignette, bbox, interactive, years, boundary_labels,
                                  zoom_level, title, styling_type, show_banner,
                                  banner_colour, colour_scale, autoplay, play_speed,
                                  data_max, image_dimensions = NULL) {
  map <- add_map_controls(
    map, borough_sf, vignette_overlay, vignette, bbox,
    interactive, years, boundary_labels, zoom_level
  )

  save_styled_map(
    map, html_file, title, styling_type, show_banner,
    banner_colour, colour_scale, !interactive, !interactive,
    image_dimensions, autoplay, play_speed, data_max, years
  )

  if (!is.null(image_dimensions)) {
    img_file <- sub("\\.html$", ".jpg", html_file)
    webshot2::webshot(html_file, img_file,
                     vwidth = image_dimensions[1],
                     vheight = image_dimensions[2])
    unlink(html_file)
  }

  return(map)
}

save_styled_map <- function(map, html_file, title, styling_type, show_banner,
                            banner_colour, colour_scale, collapsed_mobile,
                            image_mode, image_dimensions, autoplay, play_speed,
                            data_max, years = NULL) {
  htmlwidgets::saveWidget(
    map,
    file = html_file,
    selfcontained = TRUE,
    title = title
  )

  if (styling_type == "html") {
    tryCatch(
      {
        apply_custom_layout_in_html(
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
          years = years
        )
      },
      error = function(e) {
        warning("Failed to apply layout: ", e$message)
      }
    )
  }

  files_folder <- paste0(tools::file_path_sans_ext(html_file), "_files")
  if (dir.exists(files_folder)) {
    unlink(files_folder, recursive = TRUE)
  }
}

#' @keywords internal
load_roller_menu_control <- function(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500,
  image_mode = FALSE,
  years = NULL
) {
  controls_dir <- get_package_dir("controls")

  html_file <- file.path(controls_dir, "roller-menu.html")
  css_file <- file.path(controls_dir, "roller-menu.css")
  js_file <- file.path(controls_dir, "roller-menu.js")

  html_content <- read_template_file(html_file)
  css_content <- read_template_file(css_file)
  js_content <- read_template_file(js_file)

  if (image_mode) {
    html_content <- gsub(
      '<button id="playPauseButton"[^>]*>.*?</button>',
      '',
      html_content
    )
    html_content <- gsub(
      '<span class="arrow">▼</span>',
      '',
      html_content
    )
    if (!is.null(years) && length(years) > 0) {
      year_text <- as.character(years[1])
      html_content <- gsub(
        '<span id="selectedYear"></span>',
        sprintf('<span id="selectedYear">%s</span>', year_text),
        html_content
      )
    }
  }

  accent_light <- lighten_color(banner_colour, 15)
  hover_tint <- lighten_color(banner_colour, 85)

  css_content <- sprintf(
    css_content,
    banner_colour,
    banner_colour,
    accent_light,
    accent_light,
    "#ffffff",
    banner_colour,
    banner_colour,
    accent_light,
    accent_light,
    "#ffffff",
    banner_colour,
    hover_tint,
    accent_light,
    hover_tint,
    hover_tint,
    banner_colour
  )

  config_script <- sprintf(
    'window.quickmapConfig = {autoplay: %s, playSpeed: %d};',
    tolower(as.character(autoplay)),
    as.integer(play_speed)
  )

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

#' @keywords internal
load_layer_cache_js <- function() {
  controls_dir <- get_package_dir("controls")

  js_file <- file.path(controls_dir, "layer-cache.js")
  return(read_template_file(js_file))
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
#' @family layout
apply_custom_layout_in_html <- function(
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
  years = NULL
) {
  if (!file.exists(html_file)) {
    stop("HTML file not found: ", html_file)
  }

  html_content <- readLines(html_file, warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")

  viewport_meta <- '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'

  banner_css <- load_banner_css(banner_colour, image_mode)

  legend_css <- load_legend_css(banner_colour, image_mode)

  custom_css <- paste0(banner_css, legend_css)

  if (image_mode) {
    width <- image_dimensions[1]
    height <- image_dimensions[2]

    # Calculate scale factor (1200px = baseline) using geometric mean for balanced scaling
    scale_factor <- sqrt((width * height) / (IMAGE_X * IMAGE_Y))
    # For 1920x1080: sqrt((1920*1080)/(1200*1200)) = sqrt(1.44) = 1.2 (balanced scaling)
    # For 800x600: sqrt((800*600)/(1200*1200)) = sqrt(0.33) = 0.58 (proportional reduction)

    banner_font_size <- 1.8 * scale_factor
    symbol_size <- 1.3 * scale_factor
    header_font_size <- 1.2 * scale_factor
    legend_font_size <- 1.0 * scale_factor

    legend_padding <- 1.0 * scale_factor
    legend_gap <- 1.0 * scale_factor
    legend_max_height <- 18.75 * scale_factor
    header_padding <- 1.5 * scale_factor
    banner_padding <- 2.0 * scale_factor

    custom_css <- apply_template_replacements(
      custom_css,
      list(
        "1\\.8rem" = paste0(banner_font_size, "rem"),
        "1\\.3rem" = paste0(symbol_size, "rem"),
        "1\\.2rem" = paste0(header_font_size, "rem"),
        "1rem" = paste0(legend_font_size, "rem"),
        "18\\.75rem" = paste0(legend_max_height, "rem"),
        "padding: 1\\.5rem 2rem" = paste0(
          "padding: ",
          header_padding,
          "rem ",
          banner_padding,
          "rem"
        ),
        "padding: 1rem" = paste0("padding: ", legend_padding, "rem"),
        "gap: 1rem" = paste0("gap: ", legend_gap, "rem")
      )
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

  roller_menu_html <- load_roller_menu_control(
    banner_colour,
    autoplay,
    play_speed,
    image_mode,
    years
  )

  legend_html <- generate_legend_html(scale_name, collapsed_mobile, data_max)

  combined_html <- paste0(roller_menu_html, "\n", legend_html)
  html_text <- sub("</body>", paste0(combined_html, "</body>"), html_text)

  writeLines(html_text, html_file)

  return(invisible(TRUE))
}

create_generic_icons <- function(
  data,
  layer_type,
  pollutant = NULL,
  colour_scale = NULL,
  image_scale_factor = 1.0
) {
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

  shape_config <- list(
    shape = base_shape_config$shape,
    size = round(base_shape_config$size * image_scale_factor)
  )

  colors <- if (layer_type == "schools") {
    pal <- colorFactor(c("#1E90FF", "#32CD32"), unique(data$Level))
    pal(data$Level)
  } else {
    sapply(data[[pollutant]], assign_colour, scale = colour_scale)
  }

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

#' @keywords internal
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
      options = list(marker_labels = marker_labels)
    ),
    dt_sites = list(
      enabled = (diffusion_tube_file != "none"),
      data_source = "sf_data_wgs84",
      layer_type = "dt_sites",
      temporal = TRUE,
      options = list(marker_labels = marker_labels)
    ),
    schools = list(
      enabled = (school_file != "none"),
      data_source = "sf_schools_wgs84",
      layer_type = "schools",
      temporal = FALSE,
      options = list(marker_labels = marker_labels)
    )
  )
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

  layer_type <- layer_config$layer_type
  use_pollutant <- if (layer_type == "schools") NULL else pollutant

  result <- list(
    data = year_data,
    labels = generate_marker_labels(year_data, use_pollutant, show_labels, layer_type)
  )

  if (layer_type == "schools") result$layer_type <- "schools"

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

  layer_type <- layer_config$layer_type

  icons <- create_generic_icons(
    layer_data$data,
    layer_type,
    pollutant,
    colour_scale,
    image_scale_factor
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

  if (layer_type != "schools") {
    marker_params$group <- year
  }

  do.call(addMarkers, c(list(map = map), marker_params))
}


#' @keywords internal
generate_marker_labels <- function(data, pollutant, marker_labels, layer_type) {
  show_values <- marker_labels %in% c(TRUE, "values_on")
  show_custom <- marker_labels %in% c("labels", "labels_on")

  if (!show_values && !show_custom) {
    return(rep("", nrow(data)))
  }

  # Schools: show School column
  if (layer_type == "schools") {
    if ("School" %in% names(data)) {
      return(as.character(data$School))
    }
    return(rep("", nrow(data)))
  }

  # Custom labels (Label column)
  if (show_custom) {
    if ("Label" %in% names(data)) {
      return(as.character(data$Label))
    }
    # Fallback for bl_nodes only
    if (layer_type == "bl_nodes") {
      if (!is.null(pollutant) && pollutant %in% names(data)) {
        warning(
          "marker_labels set to '", marker_labels,
          "' but no Label column found in bl_nodes data. Showing pollution values instead.",
          call. = FALSE
        )
        return(ifelse(is.na(data[[pollutant]]), "", paste(round(data[[pollutant]], 0), "ug/m3")))
      }
      warning(
        "marker_labels set to '", marker_labels,
        "' but no Label column found in bl_nodes data. No labels will be shown.",
        call. = FALSE
      )
    }
    return(rep("", nrow(data)))
  }

  # Pollution values
  if (show_values && !is.null(pollutant) && pollutant %in% names(data)) {
    return(ifelse(is.na(data[[pollutant]]), "", paste(round(data[[pollutant]], 0), "ug/m3")))
  }

  rep("", nrow(data))
}


get_layer_year_data <- function(data_source_name, year, data_environment) {
  data_source <- get(data_source_name, envir = data_environment)

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
  years,
  boundary_labels = FALSE,
  zoom_level = NULL
) {
  # Handle "static_only" case (no temporal layers - only schools)
  if (identical(years, "static_only")) {
    years <- "2024"
  }

  if (is.null(years)) stop("years parameter is required")
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
  baseGroups <- if (interactive && length(years) >= 1) years else NULL
  if (!is.null(baseGroups)) {
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
  map <- leaflet(data, options = leafletOptions(
    zoomControl = interactive,
    zoomDelta = 0.5,
    zoomSnap = 0
  ))

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
  data_env,
  image_scale_factor = 1.0
) {
  for (layer_name in names(measurement_layers)) {
    layer_config <- measurement_layers[[layer_name]]
    if (!layer_config$enabled) next

    if (layer_config$temporal) {
      if (target_year != "static_only") {
        year_data <- get_layer_year_data(
          layer_config$data_source,
          target_year,
          data_env
        )
        if (nrow(year_data) == 0) next

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
      static_data <- get(layer_config$data_source, envir = data_env)
      layer_data <- prepare_generic_layer_data(layer_config, static_data)

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
  base_map <- base_map |>
    showGroup(layer_name)
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

load_spatial_data_sources <- function(dt_file, sensor_file, school_file, pollutant) {
  dt_data <- if (dt_file != "none") {
    result <- load_data_file(dt_file, "csv", c("Easting", "Northing"))
    if (!is.null(result)) {
      get_temporal_data(result$data) |> transform_to_wgs84()
    }
  }

  sensor_data <- if (sensor_file != "none") {
    load_data_file(sensor_file, "rdata", pollutant = pollutant)
  }

  school_data <- if (school_file != "none") {
    result <- load_data_file(school_file, "csv", c("Easting", "Northing"))
    if (!is.null(result)) result$data |> transform_to_wgs84()
  }

  list(
    dt = dt_data,
    sensor = sensor_data,
    school = school_data,
    dt_enabled = !is.null(dt_data),
    sensor_enabled = !is.null(sensor_data),
    school_enabled = !is.null(school_data)
  )
}

determine_primary_data_and_years <- function(spatial_data, borough_sf, vignette, requested_years) {
  dt_data <- spatial_data$dt
  sensor_data <- spatial_data$sensor

  primary_data <- dt_data %||% sensor_data

  if (!is.null(sensor_data) && !is.null(borough_sf) && vignette) {
    sensor_data <- sensor_data |> st_filter(borough_sf, .predicate = st_intersects)
  }

  vignette_overlay <- if (vignette) create_vignette_overlay(borough_sf)
  bbox <- st_bbox(borough_sf)

  if (is.null(primary_data)) {
    years <- requested_years %||% "static_only"
    primary_data <- borough_sf
  } else {
    available_years <- unique(primary_data$year_str)
    years <- if (is.null(requested_years)) {
      available_years
    } else {
      intersect(requested_years, available_years)
    }
  }

  list(
    primary = primary_data,
    sensor = sensor_data,
    years = years,
    vignette_overlay = vignette_overlay,
    bbox = bbox
  )
}

#' Create interactive and/or static pollution maps
#'
#' Main function to create Leaflet maps showing air pollution data with optional
#' schools overlay. Generates both interactive HTML maps and static JPG exports.
#'
#' @param diffusion_tube_file CSV file with Easting/Northing columns and year columns (or "none"). Prepends DATA_PATH if set.
#' @param sensor_file RData file with 'dataOAformat' object (or "none"). Prepends DATA_PATH if set.
#' @param school_file CSV file with Easting/Northing/Level/School columns (or "none"). Prepends DATA_PATH if set.
#' @param output_file Output filename (without extension). Saved to 'aq_maps/' directory.
#' @param image_export If TRUE, generates static JPG exports in addition to interactive HTML.
#' @param map_width_px Width in pixels for JPG exports (default: 1200).
#' @param map_height_px Height in pixels for JPG exports (default: 1200).
#' @param boroughs Borough name(s) for boundary display and data filtering (required).
#' @param pollutant Pollutant type: "no2" or "pm25" (default: "no2").
#' @param years Years to display. NULL uses all available years from data.
#' @param vignette If TRUE, darkens areas outside borough(s). Default: NULL (uses theme).
#' @param colour_scale Color scale name (default: "who_no2"). See \code{load_colour_scale()} for options.
#' @param marker_labels Control label visibility. Options: FALSE (no labels), TRUE (values on hover),
#'   "values_on" (values always visible), "labels" (custom labels on hover), "labels_on" (custom labels always visible).
#'   Default: NULL (uses theme).
#' @param title Page title and banner text. Default: NULL (uses theme).
#' @param styling_type Controls banner/legend display: "html" (default) or "none".
#' @param boundary_labels If TRUE, shows borough boundary labels. Default: NULL (uses theme).
#' @param banner_colour Color for banner and vignette. Default: NULL (uses theme).
#' @param autoplay Auto-start year animation on load. Default: NULL (uses theme).
#' @param play_speed Milliseconds per year during animation. Default: NULL (uses theme).
#' @param theme_file Path to YAML theme file (default: NULL). See inst/themes/ for examples.
#'
#' @return Invisible Leaflet map object. Side effects: Saves HTML to \code{aq_maps/}.
#'   If \code{image_export=TRUE}, also saves JPG files (one per year).
#'
#' @details
#' \strong{Data Sources:} Diffusion tubes (CSV), Breathe London sensors (RData), Schools (CSV)
#'
#' \strong{Coordinate Systems:} Input uses British National Grid (EPSG:27700), output WGS84 (EPSG:4326)
#'
#' \strong{Setup:} Set \code{Sys.setenv(DATA_PATH = "~/path/to/data")} before use
#'
#' \strong{Markers:} Circles (DT sites), diamonds (BL nodes), crosses (schools). Automatically scaled for static exports.
#'
#' @examples
#' # Basic interactive map
#' Sys.setenv(DATA_PATH = "~/data")
#' create_pollution_map(
#'   diffusion_tube_file = "wandsworth_2017_2024.csv",
#'   school_file = "schools_Wandsworth.csv",
#'   boroughs = "Wandsworth",
#'   years = 2024,
#'   output_file = "wandsworth_2024.html"
#' )
#'
#' # Static JPG export with theme
#' create_pollution_map(
#'   diffusion_tube_file = "data.csv",
#'   boroughs = "Merton",
#'   years = 2024,
#'   image_export = TRUE,
#'   theme_file = "inst/themes/merton_purple.yaml",
#'   output_file = "merton_2024"
#' )
#'
#' @note
#' \itemize{
#'   \item Set \code{DATA_PATH} environment variable before use
#'   \item Year columns in CSV: YYYY format (e.g., "2024")
#'   \item Static JPG exports require Chrome/Chromium for webshot2
#'   \item Use \code{show_borough_colours()} to list available borough palettes
#' }
#'
#' @family map
create_pollution_map <- function(
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",
  output_file = "pollution_map.html",
  export_image = NULL,
  boroughs,
  pollutant = "no2",
  years = NULL,
  title = NULL,
  vignette = NULL,
  colour_scale = "who_no2",
  styling_type = "html",
  marker_labels = NULL,
  banner_colour = NULL,
  boundary_labels = NULL,
  autoplay = NULL,
  play_speed = NULL,
  theme_file = NULL
) {
  export_params <- parse_export_params(export_image)
  image_export <- export_params$enabled
  map_width_px <- export_params$width
  map_height_px <- export_params$height

  show_banner <- (styling_type == "html")

  theme <- load_theme(theme_file)

  # Apply theme defaults for NULL parameters
  title <- title %||% theme$banner$title
  vignette <- vignette %||% theme$map$vignette
  banner_colour <- banner_colour %||% theme$banner$background
  boundary_labels <- boundary_labels %||% theme$map$boundary_labels
  marker_labels <- marker_labels %||% theme$map$marker_labels
  autoplay <- autoplay %||% theme$controls$autoplay
  play_speed <- play_speed %||% theme$controls$play_speed
  base_tiles_provider <- theme$map$base_tiles

  borough_sf <- tryCatch(
    get_boundary_sf(boroughs),
    error = function(e) {
      message(e$message)
      return(NULL)
    }
  )

  if (!dir.exists("aq_maps")) dir.create("aq_maps", showWarnings = TRUE)

  spatial_data <- load_spatial_data_sources(
    diffusion_tube_file, sensor_file, school_file, pollutant
  )

  if (is.null(borough_sf)) return()

  map_data <- determine_primary_data_and_years(
    spatial_data, borough_sf, vignette, years
  )

  sf_data_wgs84 <- map_data$primary
  bl_annual_means_sf <- map_data$sensor
  sf_schools_wgs84 <- spatial_data$school
  years <- map_data$years
  vignette_overlay <- map_data$vignette_overlay
  bbox <- map_data$bbox
  legend_info <- get_colour_legend(colour_scale)

  html_map <- create_base_map(sf_data_wgs84, TRUE, base_tiles_provider)

  if (image_export) {
    static_map_template <- create_base_map(sf_data_wgs84, FALSE, base_tiles_provider)
  }

  measurement_layers <- get_measurement_layers(
    diffusion_tube_file,
    sensor_file,
    school_file,
    marker_labels
  )

  data_max <- get_data_maximum(measurement_layers, pollutant, environment(), years)

  marker_scale_factor <- if (image_export) {
    sqrt((map_width_px * map_height_px) / (1200 * 1200))
  } else NULL

  for (yr in unique(years)) {
    html_map <- generate_map_layers(html_map, measurement_layers, yr,
                                     pollutant, colour_scale, environment(), 1.0)

    if (image_export) {
      static_map <- build_static_map_for_year(
        static_map_template, yr, measurement_layers,
        pollutant, colour_scale, environment(), marker_scale_factor
      )

      file_parts <- tools::file_path_sans_ext(basename(output_file))
      html_file <- file.path("aq_maps", paste0(file_parts, "_", yr, ".html"))

      finalize_and_save_map(
        static_map, html_file, borough_sf, vignette_overlay,
        vignette, bbox, FALSE, yr, boundary_labels, theme$map$zoom_level,
        title, styling_type, show_banner, banner_colour, colour_scale,
        autoplay, play_speed, data_max, c(map_width_px, map_height_px)
      )
    }
  }

  if (!is.null(output_file)) {
    html_file <- file.path("aq_maps", output_file)

    html_map <- finalize_and_save_map(
      html_map, html_file, borough_sf, vignette_overlay,
      vignette, bbox, TRUE, years, boundary_labels, theme$map$zoom_level,
      title, styling_type, show_banner, banner_colour, colour_scale,
      autoplay, play_speed, data_max, NULL
    )
  } else {
    html_map <- add_map_controls(
      html_map, borough_sf, vignette_overlay, vignette, bbox,
      TRUE, years, boundary_labels, theme$map$zoom_level
    )
  }

  return(invisible(html_map))
}

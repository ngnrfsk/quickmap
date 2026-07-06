# Characterization-test fixtures: generate the reference maps once per test run
# and parse the rendered HTML. These assert on output, not function signatures,
# so they survive API refactors (roadmap items 4 and 6).

char_data_files <- c(
  "merton_dt_2018_2024.csv",
  "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  "schools_Merton.csv",
  "mock_15min_data.Rdata"
)

char_data_available <- function() {
  dp <- Sys.getenv("DATA_PATH")
  dp != "" && all(file.exists(file.path(dp, char_data_files)))
}

.char_cache <- new.env(parent = emptyenv())

# Generate both fixture maps in a session tempdir (maps land in <dir>/aq_maps/)
char_map_dir <- function() {
  if (!is.null(.char_cache$dir)) return(.char_cache$dir)

  work <- file.path(tempdir(), "quickmap-characterization")
  dir.create(work, showWarnings = FALSE, recursive = TRUE)
  old_wd <- setwd(work)
  on.exit(setwd(old_wd))

  # merton_dt CSV has no Label column: marker_labels = "labels" falls back to
  # values with a warning; that is a known data property, not a test signal
  suppressWarnings(create_pollution_map(
    data_sources = list(
      "merton_dt_2018_2024.csv",
      "bl_imperial_annualised_2021_2025_with_missing.Rdata",
      "schools_Merton.csv"
    ),
    boroughs = "Merton",
    pollutant = "no2",
    display_times = 2020:2022,
    colour_scale = "who_no2",
    output_file = "char_annual.html",
    title = "Characterization annual",
    styling_type = "html",
    vignette = TRUE,
    marker_labels = "labels"
  ))

  create_pollution_map(
    data_sources = list("mock_15min_data.Rdata"),
    boroughs = "Westminster",
    pollutant = "no2",
    colour_scale = "who_no2",
    output_file = "char_subannual.html",
    title = "Characterization sub-annual",
    styling_type = "html"
  )

  .char_cache$dir <- file.path(work, "aq_maps")
  .char_cache$dir
}

char_html <- function(name) {
  key <- paste0("html_", name)
  if (is.null(.char_cache[[key]])) {
    path <- file.path(char_map_dir(), name)
    .char_cache[[key]] <- paste(readLines(path, warn = FALSE), collapse = "\n")
  }
  .char_cache[[key]]
}

# Extract the htmlwidgets payload embedded in the saved map
char_payload <- function(html) {
  m <- regmatches(
    html,
    regexpr('<script type="application/json" data-for="[^"]*">.*?</script>', html)
  )
  stopifnot(length(m) == 1)
  json <- sub("^<script[^>]*>", "", sub("</script>$", "", m))
  jsonlite::fromJSON(json, simplifyVector = FALSE)
}

char_methods <- function(payload) {
  vapply(payload$x$calls, function(cl) cl$method, "")
}

# data.frame of addMarkers calls: group (NA for static layers) and point count
char_marker_calls <- function(payload) {
  calls <- Filter(function(cl) cl$method == "addMarkers", payload$x$calls)
  data.frame(
    group = vapply(calls, function(cl) {
      g <- cl$args[[5]]
      if (is.null(g)) NA_character_ else as.character(unlist(g))
    }, ""),
    n = vapply(calls, function(cl) length(cl$args[[1]]), 0L),
    stringsAsFactors = FALSE
  )
}

char_shown_groups <- function(payload) {
  unlist(lapply(
    payload$x$calls,
    function(cl) if (cl$method == "showGroup") unlist(cl$args) else NULL
  ))
}

# Breathe London fetch (roadmap item 12, dev/260815_bl_fetch_plan.md).
#
# Targets the 2025 API: https://breathe-london-7x54d7qf.ew.gateway.dev,
# X-API-KEY header auth, /ListSensors and /SensorData with query parameters,
# hourly-only responses, requests limited to 366 days unless a single
# SiteCode is given. The pre-2025 api.breathelondon.org service is dead
# (probed 2026-08-15: 403 for every caller) and old keys were not migrated.
#
# The network layer is isolated in bl_request(); everything else is pure and
# unit-tested against fixtures taken from the API documentation, so the
# untested surface when a live key arrives is one function.

BL_BASE_URL <- "https://breathe-london-7x54d7qf.ew.gateway.dev"
BL_MAX_WINDOW_DAYS <- 365  # documented limit is "shorter than 366 days"

# Required by the API terms of use (effective 23 June 2025): published
# outputs carrying this data must state the source and link to it. Carried
# on the layer, so any map showing the layer prints it.
BL_ATTRIBUTION <- paste0(
  "Contains Breathe London data licensed under the Open Government ",
  "Licence v3.0 (breathelondon.org)"
)

bl_check_deps <- function() {
  for (pkg in c("httr", "jsonlite")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required for Breathe London fetches. ",
           "Install with: install.packages('", pkg, "')", call. = FALSE)
    }
  }
}

bl_check_key <- function(key) {
  if (!is.character(key) || length(key) != 1 || !nzchar(key)) {
    stop("No Breathe London API key. Set BREATHE_LONDON_KEY in ~/.Renviron ",
         "(register at https://www.breathelondon.org/developers) or pass ",
         "key = explicitly.", call. = FALSE)
  }
  key
}

#' One GET against the Breathe London gateway
#'
#' Retries on 429 and 5xx with exponential backoff. On a definitive error
#' the gateway's own JSON message is surfaced verbatim, distinguishing a
#' missing key (401) from a rejected one (400).
#'
#' @param path Endpoint path ("ListSensors" or "SensorData")
#' @param params Named list of query parameters; NULL entries dropped
#' @param key API key string
#' @param max_attempts Attempts before giving up on 429/5xx
#' @return Parsed JSON (list/data.frame from jsonlite)
#' @keywords internal
bl_request <- function(path, params, key, max_attempts = 4) {
  bl_check_deps()
  bl_check_key(key)
  params <- params[!vapply(params, is.null, logical(1))]

  for (attempt in seq_len(max_attempts)) {
    resp <- httr::GET(
      paste0(BL_BASE_URL, "/", path),
      query = params,
      httr::add_headers(`X-API-KEY` = key,
                        `Content-Type` = "application/json")
    )
    status <- httr::status_code(resp)
    if (status < 400) {
      return(jsonlite::fromJSON(
        httr::content(resp, as = "text", encoding = "UTF-8")
      ))
    }
    if (status %in% c(429L, 500L, 502L, 503L, 504L) &&
          attempt < max_attempts) {
      Sys.sleep(2^attempt)
      next
    }
    body <- tryCatch(
      jsonlite::fromJSON(httr::content(resp, as = "text", encoding = "UTF-8")),
      error = function(e) NULL
    )
    stop("Breathe London API error ", status, ": ",
         body$message %||% "no detail returned", call. = FALSE)
  }
}

#' Split a period into windows the API will accept
#'
#' /SensorData refuses periods of 366 days or longer unless a single
#' SiteCode is given; borough-wide fetches must be chunked.
#'
#' @param start,end POSIXct bounds
#' @return data.frame with POSIXct columns start, end; windows abut exactly
#' @keywords internal
bl_chunk_windows <- function(start, end) {
  starts <- seq(start, end, by = paste(BL_MAX_WINDOW_DAYS, "days"))
  ends <- c(starts[-1], end)
  keep <- starts < ends
  data.frame(start = starts[keep], end = ends[keep])
}

#' /ListSensors response to a metadata tibble
#'
#' The documented example carries coordinates as strings; they are made
#' numeric here so nothing downstream has to know.
#'
#' @param raw Parsed JSON from /ListSensors
#' @return data.frame, one row per installation
#' @keywords internal
bl_parse_sensors <- function(raw) {
  if (is.null(raw) || NROW(raw) == 0) {
    stop("No sensors returned. Check the Borough/SiteCode spelling.",
         call. = FALSE)
  }
  raw <- as.data.frame(raw)
  raw$Latitude <- as.numeric(raw$Latitude)
  raw$Longitude <- as.numeric(raw$Longitude)
  raw$Location <- NULL  # GeoJSON duplicate of Latitude/Longitude
  raw
}

#' /SensorData response to quickmap's hourly contract
#'
#' Long per-observation rows (Species/SiteCode/DateTime/ScaledValue) become
#' one row per site per hour with a column per pollutant, joined to sensor
#' coordinates: siteCode, date, no2, pm25, lat, lon.
#'
#' @param raw Parsed JSON from /SensorData
#' @param sensors Output of [bl_parse_sensors()]
#' @return data.frame in contract order
#' @keywords internal
bl_parse_sensordata <- function(raw, sensors) {
  if (is.null(raw) || NROW(raw) == 0) {
    return(data.frame(siteCode = character(), date = as.POSIXct(character()),
                      no2 = numeric(), pm25 = numeric(),
                      lat = numeric(), lon = numeric()))
  }
  raw <- as.data.frame(raw)
  obs <- data.frame(
    siteCode = raw$SiteCode,
    date = as.POSIXct(raw$DateTime, format = "%Y-%m-%dT%H:%M:%SZ",
                      tz = "UTC"),
    species = tolower(raw$Species),
    value = as.numeric(raw$ScaledValue)
  )
  wide <- tidyr::pivot_wider(obs, names_from = "species",
                             values_from = "value",
                             values_fn = function(x) mean(x, na.rm = TRUE))
  for (col in c("no2", "pm25")) {
    if (!col %in% names(wide)) wide[[col]] <- NA_real_
  }
  merged <- merge(
    wide,
    data.frame(siteCode = sensors$SiteCode,
               lat = sensors$Latitude, lon = sensors$Longitude),
    by = "siteCode"
  )
  merged[order(merged$siteCode, merged$date),
         c("siteCode", "date", "no2", "pm25", "lat", "lon")]
}

#' Hourly plausibility screen
#'
#' The thresholds are the A02 download scripts' long-standing ones, chosen
#' against local AURN measurements; values at or above them become NA
#' before any averaging.
#'
#' @param data Hourly contract data.frame (no2/pm25 columns optional)
#' @param no2_max,pm25_max Screening thresholds in µg/m³
#' @return data.frame with implausible values set NA
#' @keywords internal
bl_qa_screen <- function(data, no2_max = 500, pm25_max = 130) {
  if ("no2" %in% names(data)) {
    data$no2[!is.na(data$no2) & data$no2 >= no2_max] <- NA_real_
  }
  if ("pm25" %in% names(data)) {
    data$pm25[!is.na(data$pm25) & data$pm25 >= pm25_max] <- NA_real_
  }
  data
}

#' Period means with a completeness requirement
#'
#' A period's mean exists only where at least `data_capture` of its hours
#' carry a value; sparser periods yield NA rather than an average of
#' whatever happened to be measured. Expected hours are counted from the
#' calendar, so hours missing from the data entirely (not just NA rows)
#' count against capture.
#'
#' @param data Hourly contract data.frame
#' @param pollutant Column to average ("no2" or "pm25")
#' @param period "year" or "month"
#' @param data_capture Minimum fraction of expected hours, default 0.75
#' @return data.frame: siteCode, period label, mean value, capture, lat, lon
#' @keywords internal
bl_period_means <- function(data, pollutant, period = "year",
                            data_capture = 0.75) {
  label <- switch(period,
    year = format(data$date, "%Y"),
    month = format(data$date, "%Y-%m"),
    stop("period must be \"year\" or \"month\"", call. = FALSE)
  )
  expected <- switch(period,
    year = ifelse(lubridate::leap_year(as.integer(substr(label, 1, 4))),
                  8784, 8760),
    month = lubridate::days_in_month(data$date) * 24
  )
  df <- data.frame(
    siteCode = data$siteCode, period = label, expected = expected,
    value = data[[pollutant]], lat = data$lat, lon = data$lon
  )
  out <- df |>
    dplyr::summarise(
      capture = sum(!is.na(value)) / expected[1],
      mean = ifelse(capture >= data_capture,
                    mean(value, na.rm = TRUE), NA_real_),
      lat = lat[1], lon = lon[1],
      .by = c("siteCode", "period")
    )
  names(out)[names(out) == "mean"] <- pollutant
  out[, c("siteCode", "period", pollutant, "capture", "lat", "lon")]
}

#' List Breathe London sensors
#'
#' Wraps /ListSensors. With no filter, every installation on the network;
#' filters narrow to a borough, a site, or any other documented parameter
#' (Sponsor, Facility, Latitude/Longitude/RadiusKM) via `...`.
#'
#' @param borough London borough name, e.g. "Merton"
#' @param site Site code
#' @param ... Further query parameters passed as given
#' @param key API key; defaults to the BREATHE_LONDON_KEY environment
#'   variable (set it once in ~/.Renviron)
#' @return data.frame of sensor metadata, coordinates numeric
#' @family breathe london
#' @export
bl_sensors <- function(borough = NULL, site = NULL, ...,
                       key = Sys.getenv("BREATHE_LONDON_KEY")) {
  raw <- bl_request(
    "ListSensors",
    c(list(Borough = borough, SiteCode = site), list(...)),
    key
  )
  bl_parse_sensors(raw)
}

#' Fetch Breathe London measurements
#'
#' Wraps /SensorData: hourly NO2 and PM2.5 for a borough or a set of sites
#' between two times, returned in quickmap's contract format (`siteCode`,
#' `date`, `no2`, `pm25`, `lat`, `lon`). Periods longer than the API's
#' 366-day window are fetched in chunks; transient errors (429, 5xx) are
#' retried with backoff.
#'
#' @param borough London borough name, e.g. "Merton"
#' @param site Site code(s); fetched one at a time when several
#' @param start,end Period bounds, anything `as.POSIXct()` accepts
#' @param species Pollutants to request, from "NO2" and "PM25"
#' @param key API key; defaults to the BREATHE_LONDON_KEY environment
#'   variable
#' @return Hourly data.frame, one row per site-hour
#' @family breathe london
#' @export
bl_data <- function(borough = NULL, site = NULL, start, end,
                    species = c("NO2", "PM25"),
                    key = Sys.getenv("BREATHE_LONDON_KEY")) {
  if (is.null(borough) && is.null(site)) {
    stop("Give either a borough or site code(s): the API requires a filter ",
         "with startTime/endTime.", call. = FALSE)
  }
  species <- match.arg(species, c("NO2", "PM25"), several.ok = TRUE)
  start <- as.POSIXct(start, tz = "UTC")
  end <- as.POSIXct(end, tz = "UTC")
  windows <- bl_chunk_windows(start, end)
  sensors <- bl_sensors(borough = borough,
                        site = if (length(site) == 1) site else NULL,
                        key = key)
  targets <- if (is.null(site)) list(NULL) else as.list(site)

  pieces <- list()
  for (sp in species) {
    for (tg in targets) {
      for (i in seq_len(nrow(windows))) {
        raw <- bl_request("SensorData", list(
          Borough = if (is.null(tg)) borough else NULL,
          SiteCode = tg,
          Species = sp,
          startTime = format(windows$start[i], "%Y-%m-%dT%H:%M:%SZ"),
          endTime = format(windows$end[i], "%Y-%m-%dT%H:%M:%SZ")
        ), key)
        pieces[[length(pieces) + 1]] <- bl_parse_sensordata(raw, sensors)
      }
    }
  }
  combined <- dplyr::bind_rows(pieces)
  if (nrow(combined) == 0) return(combined)
  # species fetched separately: fold each site-hour's rows into one
  combined |>
    dplyr::summarise(
      no2 = if (all(is.na(no2))) NA_real_ else mean(no2, na.rm = TRUE),
      pm25 = if (all(is.na(pm25))) NA_real_ else mean(pm25, na.rm = TRUE),
      lat = lat[1], lon = lon[1],
      .by = c("siteCode", "date")
    )
}

#' Breathe London data as a quickmap layer
#'
#' Fetches, screens and aggregates in one call: hourly data via
#' [bl_data()], the plausibility screen ([bl_qa_screen()]), then period
#' means that exist only where at least `data_capture` of the period's
#' hours were measured ([bl_period_means()]) — an annual mean built from a
#' few weeks of data misleads, so it becomes NA instead.
#'
#' @inheritParams bl_data
#' @param pollutant Which pollutant the layer carries, "no2" or "pm25"
#' @param period Aggregation period, "year" or "month"
#' @param data_capture Minimum fraction of the period's hours that must
#'   carry a value, default 0.75
#' @param name Layer name
#' @return A [qm_layer()], diamond-shaped like the other sensor layers
#' @family breathe london
#' @export
from_breathelondon <- function(borough = NULL, site = NULL, start, end,
                               pollutant = c("no2", "pm25"),
                               period = "year", data_capture = 0.75,
                               name = "breathe_london",
                               key = Sys.getenv("BREATHE_LONDON_KEY")) {
  pollutant <- match.arg(pollutant)
  hourly <- bl_data(borough = borough, site = site, start = start, end = end,
                    species = toupper(pollutant), key = key)
  hourly <- bl_qa_screen(hourly)
  means <- bl_period_means(hourly, pollutant, period = period,
                           data_capture = data_capture)
  means <- means[!is.na(means[[pollutant]]), ]
  if (nrow(means) == 0) {
    stop("No site reached ", data_capture * 100, "% data capture in any ",
         period, ". Widen the period or lower data_capture.", call. = FALSE)
  }
  qm_layer(means, value_col = pollutant, time_col = "period",
           shape = "diamond", name = name,
           attribution = BL_ATTRIBUTION)
}

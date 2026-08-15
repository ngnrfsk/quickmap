# Breathe London fetch (roadmap item 12). Everything here runs offline:
# fixtures are the API documentation's own example response objects (saved
# page reviewed 2026-08-14), so the only surface these tests cannot reach is
# the live network call inside bl_request() — covered by the keyed smoke
# test at the bottom.

sensors_fixture <- data.frame(
  SiteCode = c("BL0057", "BL0086"),
  SiteName = c("St Annes RC Primary School", "Second Site"),
  Latitude = c("51.4856300", "51.4000000"),   # strings, as documented
  Longitude = c("-0.1191570", "-0.2000000"),
  Borough = c("Lambeth", "Merton"),
  SiteClassification = c("Urban Background", "Roadside"),
  stringsAsFactors = FALSE
)

# one site, two pollutants, three hours (one NO2 hour missing)
sensordata_fixture <- data.frame(
  Species = c("PM25", "PM25", "PM25", "NO2", "NO2"),
  Source = "Measurement",
  Units = "ug.m-3",
  SiteCode = "BL0086",
  DateTime = c("2025-04-01T00:00:00Z", "2025-04-01T01:00:00Z",
               "2025-04-01T02:00:00Z", "2025-04-01T00:00:00Z",
               "2025-04-01T02:00:00Z"),
  Duration = "PT1H",
  ScaledValue = c(5.55, 6.05, 6.55, 30.1, 32.3),
  RatificationStatus = "P",
  stringsAsFactors = FALSE
)

hourly_year <- function(values_no2, year = 2023, site = "BL0001") {
  hours <- seq(as.POSIXct(paste0(year, "-01-01 00:00"), tz = "UTC"),
               by = "1 hour", length.out = length(values_no2))
  data.frame(siteCode = site, date = hours, no2 = values_no2,
             pm25 = NA_real_, lat = 51.4, lon = -0.2)
}

test_that("window chunking respects the 366-day limit and abuts exactly", {
  start <- as.POSIXct("2021-01-01", tz = "UTC")
  end <- as.POSIXct("2024-01-01", tz = "UTC")
  w <- quickmap:::bl_chunk_windows(start, end)
  expect_true(all(as.numeric(w$end - w$start, units = "days") <= 365))
  expect_identical(w$start[1], start)
  expect_identical(w$end[nrow(w)], end)
  expect_identical(w$start[-1], w$end[-nrow(w)])  # no gaps, no overlaps

  short <- quickmap:::bl_chunk_windows(start,
                                       start + as.difftime(10, units = "days"))
  expect_identical(nrow(short), 1L)
})

test_that("sensor metadata parses with numeric coordinates", {
  s <- quickmap:::bl_parse_sensors(sensors_fixture)
  expect_type(s$Latitude, "double")
  expect_type(s$Longitude, "double")
  expect_equal(s$Latitude[1], 51.48563)
  expect_error(quickmap:::bl_parse_sensors(NULL), "No sensors")
})

test_that("observations pivot to the contract columns", {
  s <- quickmap:::bl_parse_sensors(sensors_fixture)
  d <- quickmap:::bl_parse_sensordata(sensordata_fixture, s)
  expect_identical(names(d),
                   c("siteCode", "date", "no2", "pm25", "lat", "lon"))
  expect_identical(nrow(d), 3L)          # three hours, one row each
  expect_s3_class(d$date, "POSIXct")
  expect_equal(d$pm25, c(5.55, 6.05, 6.55))
  expect_equal(d$no2, c(30.1, NA, 32.3)) # the missing NO2 hour is NA
  expect_equal(d$lat[1], 51.4)

  empty <- quickmap:::bl_parse_sensordata(NULL, s)
  expect_identical(nrow(empty), 0L)
})

test_that("the plausibility screen nulls A02's thresholds and above", {
  d <- hourly_year(c(10, 499.9, 500, 750))
  d$pm25 <- c(10, 129.9, 130, 200)
  screened <- quickmap:::bl_qa_screen(d)
  expect_equal(screened$no2, c(10, 499.9, NA, NA))
  expect_equal(screened$pm25, c(10, 129.9, NA, NA))
})

test_that("a period below 75% capture yields NA, at or above it a mean", {
  # 2023: 8760 hours. 60% coverage -> NA; 80% coverage -> a mean.
  sparse <- hourly_year(rep(20, 8760 * 0.6))
  m <- quickmap:::bl_period_means(sparse, "no2")
  expect_true(is.na(m$no2))
  expect_lt(m$capture, 0.75)

  dense <- hourly_year(rep(20, round(8760 * 0.8)))
  m2 <- quickmap:::bl_period_means(dense, "no2")
  expect_equal(m2$no2, 20)
  expect_gt(m2$capture, 0.75)

  # NA hours count against capture even when the rows exist
  na_heavy <- hourly_year(c(rep(20, 4000), rep(NA_real_, 4760)))
  expect_true(is.na(quickmap:::bl_period_means(na_heavy, "no2")$no2))
})

test_that("convert_openair_to_spatial applies the capture threshold", {
  skip_if_not_installed("openair")
  hours <- seq(as.POSIXct("2023-01-01", tz = "UTC"), by = "1 hour",
               length.out = 8760)
  full_site <- data.frame(siteCode = "FULL", date = hours, no2 = 30,
                          latitude = 51.4, longitude = -0.2)
  sparse_site <- data.frame(siteCode = "SPARSE", date = hours[1:4000],
                            no2 = 40, latitude = 51.5, longitude = -0.1)
  both <- rbind(full_site, sparse_site)

  out <- convert_openair_to_spatial(both, pollutant = "no2")
  expect_equal(out$no2[out$siteCode == "FULL"], 30)
  expect_true(is.na(out$no2[out$siteCode == "SPARSE"]))

  legacy <- convert_openair_to_spatial(both, pollutant = "no2",
                                       data_capture = 0)
  expect_equal(legacy$no2[legacy$siteCode == "SPARSE"], 40)
})

test_that("missing key and missing filter fail with instructions", {
  expect_error(bl_sensors(key = ""), "BREATHE_LONDON_KEY")
  expect_error(bl_data(start = "2024-01-01", end = "2024-02-01", key = "x"),
               "borough or site")
})

test_that("live smoke test", {
  skip_if(Sys.getenv("BREATHE_LONDON_KEY") == "",
          "BREATHE_LONDON_KEY not set")
  s <- bl_sensors(borough = "Merton")
  expect_gt(nrow(s), 0)
  expect_type(s$Latitude, "double")
})

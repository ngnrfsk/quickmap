# Item 7: wind layer (worldmet -> U/V -> leaflet-velocity payload).

test_that("from_worldmet decomposes ws/wd into meteorological U/V", {
  d <- data.frame(
    date = as.POSIXct(c("2024-01-15 12:00", "2024-01-15 13:00"), tz = "UTC"),
    ws = c(4, 10),
    wd = c(270, 180)  # westerly, southerly
  )
  w <- from_worldmet(data = d)

  expect_s3_class(w, "qm_wind")
  # wind FROM the west blows eastward: u = +ws, v = 0
  expect_equal(w$u[1], 4, tolerance = 1e-10)
  expect_equal(w$v[1], 0, tolerance = 1e-10)
  # wind FROM the south blows northward: u = 0, v = +ws
  expect_equal(w$u[2], 0, tolerance = 1e-10)
  expect_equal(w$v[2], 10, tolerance = 1e-10)
})

test_that("from_worldmet validates input", {
  expect_error(from_worldmet(), "Supply either")
  expect_error(
    from_worldmet(data = data.frame(date = Sys.time(), ws = 1)),
    "missing: wd"
  )
  expect_error(
    from_worldmet(data = data.frame(
      date = Sys.time(), ws = NA_real_, wd = NA_real_
    )),
    "no complete ws/wd rows"
  )
})

test_that("wind_time_format matches the year_str grammar", {
  expect_equal(quickmap:::wind_time_format("2024"), "%Y")
  expect_equal(quickmap:::wind_time_format("2024-01"), "%Y-%m")
  expect_equal(quickmap:::wind_time_format("2024-01-15"), "%Y-%m-%d")
  expect_equal(quickmap:::wind_time_format("2024-01-15 12:00"), "%Y-%m-%d %H:%M")
  expect_error(quickmap:::wind_time_format("junk-format"), "Unrecognised")
})

test_that("build_wind_payload aggregates to display times with null gaps", {
  wind <- from_worldmet(data = data.frame(
    date = as.POSIXct(
      c("2020-06-01 00:00", "2020-06-01 12:00", "2022-06-01 00:00"),
      tz = "UTC"
    ),
    ws = c(2, 4, 6),
    wd = c(270, 270, 180)
  ))
  bbox <- c(xmin = -0.3, ymin = 51.3, xmax = 0.0, ymax = 51.5)

  expect_message(
    payload <- quickmap:::build_wind_payload(
      wind, c("2020", "2021", "2022"), bbox
    ),
    "covers 2 of 3"
  )

  expect_equal(as.character(payload$times), c("2020", "2021", "2022"))
  expect_length(payload$frames, 3)
  expect_null(payload$frames[[2]])  # 2021: no data

  f2020 <- payload$frames[[1]]
  expect_length(f2020, 2)
  expect_equal(f2020[[1]]$header$parameterNumber, 2)  # U
  expect_equal(f2020[[2]]$header$parameterNumber, 3)  # V
  expect_equal(f2020[[1]]$header$nx, 2)
  # 2020 mean of two westerlies (ws 2 and 4): u = 3, uniform over the grid
  expect_equal(as.numeric(f2020[[1]]$data), rep(3, 4), tolerance = 1e-10)
  expect_equal(as.numeric(f2020[[2]]$data), rep(0, 4), tolerance = 1e-10)
  # velocity grids scan north -> south
  expect_gt(f2020[[1]]$header$la1, f2020[[1]]$header$la2)

  expect_equal(payload$maxVelocity, 8)  # ceiling(6) + 2

  expect_warning(
    quickmap:::build_wind_payload(wind, "1999", bbox),
    "covers none"
  )
})

test_that("wind map embeds the velocity dependency and controller hook", {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixture files not available")

  work <- withr::local_tempdir()
  withr::local_dir(work)
  wind <- data.frame(
    date = as.POSIXct(c("2020-06-01", "2021-06-01", "2022-06-01"), tz = "UTC"),
    ws = c(3, 4, 5),
    wd = c(200, 220, 240)
  )
  suppressWarnings(create_pollution_map(
    data_sources = list("merton_dt_2018_2024.csv"),
    boroughs = "Merton",
    pollutant = "no2",
    display_times = 2020:2022,
    colour_scale = "who_no2",
    output_file = "item7_wind_test.html",
    title = "Wind test",
    styling_type = "html",
    vignette = FALSE,
    wind = wind
  ))

  html <- paste(
    readLines("item7_wind_test.html", warn = FALSE),
    collapse = "\n"
  )
  expect_true(grepl("quickmapWindController", html, fixed = TRUE))
  expect_true(grepl("velocityLayer", html))          # plugin inlined
  expect_false(grepl('<script[^>]+src="https?://', html))  # still self-contained

  payload <- char_payload(html)
  wind_hooks <- Filter(
    function(h) !is.null(h$data$frames),
    payload$jsHooks$render
  )
  expect_length(wind_hooks, 1)
  expect_length(wind_hooks[[1]]$data$frames, 3)
})

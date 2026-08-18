# Item 6: time step cap and lazy-loading decision/payload behaviour.
# The rendered-output regression net for the lazy path lives in
# test-characterization.R (episode fixture); these tests cover the decision
# logic and the payload contract directly.

test_that("time step cap warns and subsets to the most recent steps", {
  times <- as.character(2000:2299)  # 300 steps
  expect_warning(
    capped <- quickmap:::apply_time_step_cap(times),
    "200-step cap"
  )
  expect_length(capped, 200)
  expect_equal(capped[1], "2100")
  expect_equal(capped[200], "2299")

  expect_identical(quickmap:::apply_time_step_cap("static_only"), "static_only")
  expect_identical(quickmap:::apply_time_step_cap(2020:2022), 2020:2022)

  withr::local_options(quickmap.time_step_cap = 2)
  expect_warning(
    capped <- quickmap:::apply_time_step_cap(c("2021", "2020", "2022")),
    "2-step cap"
  )
  expect_equal(capped, c("2021", "2022"))
})

test_that("lazy rendering triggers on step count or estimated size", {
  expect_false(quickmap:::use_lazy_rendering(3, 1000))
  expect_true(quickmap:::use_lazy_rendering(51, 1000))    # step threshold
  expect_true(quickmap:::use_lazy_rendering(3, 70000))    # ~5.5 MB estimate
  expect_false(quickmap:::use_lazy_rendering(50, 60000))  # ~4.9 MB estimate

  withr::local_options(quickmap.lazy_step_threshold = 2)
  expect_true(quickmap:::use_lazy_rendering(3, 10))
})

test_that("build_lazy_payload produces the controller contract", {
  d <- data.frame(
    siteCode = rep(c("A", "B"), each = 3),
    year_str = rep(c("2020", "2021", "2022"), 2),
    no2 = c(12.34, NA, 45.6, 8.9, 21.5, 33.3),
    Longitude = rep(c(-0.20, -0.21), each = 3),
    Latitude = rep(c(51.45, 51.46), each = 3)
  )
  layers <- list(dt = list(
    enabled = TRUE, id = "dt", static = FALSE, icon_shape = "circle",
    options = list(symbol_labels = TRUE)
  ))
  spatial <- list(all_data = list(dt = d))

  payload <- quickmap:::build_lazy_payload(
    layers, spatial, c("2020", "2021", "2022"), "no2", "who_no2"
  )

  expect_equal(as.character(payload$times), c("2020", "2021", "2022"))
  expect_true(all(is.finite(payload$thresholds)))       # .Inf dropped
  expect_equal(length(payload$colours), length(payload$thresholds))
  expect_true(all(grepl("^#[0-9A-F]{6}$", payload$colours)))
  expect_equal(payload$naColour, "#FFFFFF")

  expect_length(payload$layers, 1)
  layer <- payload$layers[[1]]
  expect_equal(layer$shape, "circle")
  expect_equal(layer$radius, 10)
  expect_false(layer$nonsolid)
  expect_equal(layer$labelMode, "values")
  expect_false(layer$noHide)

  expect_length(layer$sites, 2)
  site_a <- layer$sites[[1]]
  expect_equal(site_a$code, "A")
  # NA row (2021) survives as NA in the value vector -> null in JSON
  expect_equal(as.numeric(site_a$v), c(12.3, NA, 45.6))
})

test_that("build_lazy_payload falls back to values when Label is missing", {
  d <- data.frame(
    siteCode = "A", year_str = "2020", no2 = 10,
    Longitude = -0.2, Latitude = 51.45
  )
  layers <- list(dt = list(
    enabled = TRUE, id = "dt", static = FALSE, icon_shape = "circle",
    options = list(symbol_labels = "labels")
  ))
  spatial <- list(all_data = list(dt = d))

  expect_warning(
    payload <- quickmap:::build_lazy_payload(
      layers, spatial, "2020", "no2", "who_no2"
    ),
    "no Label column"
  )
  expect_equal(payload$layers[[1]]$labelMode, "values")
})

test_that("forced-lazy annual map keeps static schools layer and both temporal layers", {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixture files not available")
  withr::local_options(quickmap.lazy_step_threshold = 1)

  work <- withr::local_tempdir()
  withr::local_dir(work)
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
    output_file = "item6_forced_lazy.html",
    title = "Forced lazy annual",
    styling_type = "html",
    vignette = TRUE,
    symbol_labels = "labels"
  ))

  html <- paste(
    readLines("item6_forced_lazy.html", warn = FALSE),
    collapse = "\n"
  )
  payload <- char_payload(html)
  methods <- char_methods(payload)
  mk <- char_marker_calls(payload)

  # schools remain a pre-built static layer, added once (not once per year)
  expect_equal(sum(methods == "addMarkers"), 1)
  expect_equal(mk$n, 53)
  expect_true(is.na(mk$group))

  lazy <- char_lazy_payload(payload)
  expect_equal(as.character(unlist(lazy$times)), c("2020", "2021", "2022"))
  expect_length(lazy$layers, 2)                        # dt + bl sensors
  expect_equal(
    vapply(lazy$layers, function(l) l$shape, ""),
    # DELIBERATE CHANGE (item 9, v0.9.8.1): layer shape metadata is now
    # honoured — from_csv tubes are circles, from_rdata sensors diamonds
    # (previously the auto-cycle gave circle/rect).
    c("circle", "diamond")
  )
})

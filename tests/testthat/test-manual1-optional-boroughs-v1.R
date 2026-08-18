# boroughs became optional (user decision 2026-07-10, v0.9.9.6): NULL draws
# no boundary, disables the vignette and fits the viewport to the data.

boroughless_layer <- function() {
  d <- data.frame(
    code = paste0("s", 1:3),
    year_str = "2024",
    no2 = c(12, 28, 44),
    lat = c(51.44, 51.45, 51.46),
    lon = c(-0.17, -0.19, -0.21)
  )
  qm_layer(d, name = "survey")
}

test_that("quickmap works without boroughs: no boundary, viewport from data", {
  testthat::skip_if_not_installed("jsonlite")

  work <- withr::local_tempdir()
  withr::local_dir(work)
  suppressWarnings(quickmap(
    boroughless_layer(),
    output_file = "no_boroughs.html",
    title = "no boundary"
  ))
  html <- paste(
    readLines("no_boroughs.html", warn = FALSE),
    collapse = "\n"
  )
  payload <- char_payload(html)
  methods <- char_methods(payload)

  expect_equal(sum(methods == "addPolygons"), 0)   # no boundary, no vignette
  expect_gt(sum(methods == "addMarkers"), 0)

  # viewport fits the data (leaflet stores fitBounds as x$fitBounds:
  # lat1, lng1, lat2, lng2, options)
  fit <- unlist(payload$x$fitBounds[1:4])
  expect_lt(abs(fit[1] - 51.44), 0.01)             # lat1 ~ min latitude
  expect_lt(abs(fit[3] - 51.46), 0.01)             # lat2 ~ max latitude
})

test_that("vignette request is ignored without a boundary", {
  testthat::skip_if_not_installed("jsonlite")

  work <- withr::local_tempdir()
  withr::local_dir(work)
  suppressWarnings(quickmap(
    boroughless_layer(),
    vignette = TRUE,
    output_file = "no_boroughs_vignette.html",
    title = "vignette ignored"
  ))
  html <- paste(
    readLines("no_boroughs_vignette.html", warn = FALSE),
    collapse = "\n"
  )
  expect_equal(sum(char_methods(char_payload(html)) == "addPolygons"), 0)
})

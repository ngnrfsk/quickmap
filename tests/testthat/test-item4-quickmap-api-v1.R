# quickmap() public API (roadmap item 4): the two-line call, layer input
# forms, and equivalence between quickmap() and the create_pollution_map()
# compatibility wrapper.

generate_in_tmp <- function(expr) {
  work <- file.path(tempdir(), "quickmap-api-item4")
  dir.create(work, showWarnings = FALSE, recursive = TRUE)
  old_wd <- setwd(work)
  on.exit(setwd(old_wd))
  suppressWarnings(force(expr))
}

api_payload <- function(name) {
  path <- file.path(tempdir(), "quickmap-api-item4", name)
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")
  char_payload(html)
}

test_that("two-line quickmap() call produces a map", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  generate_in_tmp(
    quickmap("merton_dt_2018_2024.csv", boroughs = "Merton",
             output_file = "merton_dt_2018-2024_item4_v1.html")
  )
  payload <- api_payload("merton_dt_2018-2024_item4_v1.html")
  methods <- char_methods(payload)
  # default tiles: OSM (addTiles) — Positron default reverted 2026-07-11
  expect_equal(sum(methods == "addTiles"), 1)
  expect_gt(sum(methods == "addMarkers"), 0)
})

test_that("quickmap() accepts a list mixing paths and qm_layers", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  schools <- from_csv("schools_Merton.csv")
  generate_in_tmp(
    quickmap(
      list("merton_dt_2018_2024.csv", schools),
      boroughs = "Merton",
      display_times = 2022,
      output_file = "merton_dt-schools_2022_item4_v1.html"
    )
  )
  mk <- char_marker_calls(api_payload("merton_dt-schools_2022_item4_v1.html"))
  expect_equal(sum(is.na(mk$group)), 1)   # static schools layer
  expect_equal(sum(!is.na(mk$group)), 1)  # one temporal step
})

test_that("create_pollution_map() and quickmap() produce equivalent payloads", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  generate_in_tmp({
    create_pollution_map(
      data_sources = list("merton_dt_2018_2024.csv", "schools_Merton.csv"),
      boroughs = "Merton",
      pollutant = "no2",
      display_times = 2020:2022,
      output_file = "merton_wrapper_2020-2022_item4_v1.html"
    )
    quickmap(
      list(from_csv("merton_dt_2018_2024.csv"), from_csv("schools_Merton.csv")),
      boroughs = "Merton",
      display_times = 2020:2022,
      output_file = "merton_direct_2020-2022_item4_v1.html"
    )
  })

  p1 <- api_payload("merton_wrapper_2020-2022_item4_v1.html")
  p2 <- api_payload("merton_direct_2020-2022_item4_v1.html")

  expect_equal(table(char_methods(p1)), table(char_methods(p2)))
  expect_equal(char_marker_calls(p1)$n, char_marker_calls(p2)$n)
  expect_equal(char_marker_calls(p1)$group, char_marker_calls(p2)$group)
})

test_that("quickmap() infers pollutant from the first temporal layer", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  layer <- suppressMessages(
    from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25")
  )
  generate_in_tmp(
    quickmap(layer, boroughs = "Richmond",
             display_times = "2024-01-15 12:00",
             colour_scale = "stripes_pm25",
             output_file = "richmond_bl_2024jan15_item4_v1.html")
  )
  expect_true(file.exists(file.path(
    tempdir(), "quickmap-api-item4",
    "richmond_bl_2024jan15_item4_v1.html"
  )))
})

# qm_layer atomic unit (roadmap item 3) — contract, inference, aliases, wrappers

synthetic_df <- function(time_vals = c("2022", "2023"), n_sites = 3) {
  expand.grid(
    code = paste0("S", seq_len(n_sites)),
    time_label = time_vals,
    stringsAsFactors = FALSE
  ) |>
    transform(
      no2 = 20,
      lat = 51.5 + seq_len(n_sites * length(time_vals)) / 1000,
      lon = -0.1
    )
}

# ---- constructor and contract ----

test_that("qm_layer builds from a plain data.frame with lat/lon", {
  layer <- qm_layer(synthetic_df(), name = "test")

  expect_s3_class(layer, "qm_layer")
  expect_s3_class(layer, "sf")
  m <- qm_meta(layer)
  expect_equal(m$value_col, "no2")
  expect_equal(m$time_col, "time_label")
  expect_equal(m$name, "test")
  expect_equal(m$shape, "circle")
  expect_equal(m$resolution, "year")
  expect_true("time_sort" %in% names(layer))
  expect_s3_class(layer$time_sort, "POSIXct")
})

test_that("qm_layer errors plainly on missing code column", {
  df <- synthetic_df()
  df$code <- NULL
  expect_error(qm_layer(df), "code")
})

test_that("qm_layer errors plainly on missing coordinates", {
  df <- synthetic_df()
  df$lat <- NULL
  df$lon <- NULL
  expect_error(qm_layer(df), "lat")
})

test_that("qm_layer errors when value_col cannot be inferred", {
  df <- synthetic_df()
  names(df)[names(df) == "no2"] <- "mystery1"
  df$mystery2 <- 1
  expect_error(qm_layer(df), "value_col")
})

test_that("explicit value_col must exist", {
  expect_error(qm_layer(synthetic_df(), value_col = "pm25"), "pm25")
})

# ---- alias rule ----

test_that("legacy names are normalised: siteCode, year_str, Latitude/Longitude", {
  df <- synthetic_df()
  names(df) <- c("siteCode", "year_str", "no2", "Latitude", "Longitude")
  layer <- qm_layer(df)

  expect_true(all(c("code", "time_label", "lat", "lon") %in% names(layer)))
  expect_false(any(c("siteCode", "year_str", "Latitude", "Longitude") %in% names(layer)))
})

test_that("alias duplicates are dropped, canonical wins", {
  df <- synthetic_df()
  df$siteCode <- "SHOULD_BE_DROPPED"
  df$Longitude <- 999
  layer <- qm_layer(df)
  expect_false("siteCode" %in% names(layer))
  expect_false("Longitude" %in% names(layer))
  expect_equal(unique(layer$lon), -0.1)
})

# ---- static vs temporal is derived, not declared ----

test_that("no time column means a static layer", {
  df <- synthetic_df()[1:3, ]
  df$time_label <- NULL
  layer <- qm_layer(df)
  expect_null(qm_meta(layer)$time_col)
  expect_null(qm_meta(layer)$resolution)
})

# ---- time inference contract ----

test_that("Date/POSIXct class wins regardless of column name", {
  df <- synthetic_df(time_vals = "x")
  df$time_label <- NULL
  df$when_measured <- as.Date("2023-06-15") + seq_len(nrow(df))
  layer <- qm_layer(df)
  expect_equal(qm_meta(layer)$resolution, "day")
  expect_true(all(grepl("^2023-06-\\d{2}$", layer$time_label)))
})

test_that("grammar parses each resolution", {
  cases <- list(
    list(vals = c("2022", "2023"), res = "year"),
    list(vals = c("2023-01", "2023-02"), res = "month"),
    list(vals = c("2023-01-15", "2023-01-16"), res = "day"),
    list(vals = c("2023-01-15 12:00", "2023-01-15 13:00"), res = "hour"),
    list(vals = c("2023-01-15 12:15", "2023-01-15 12:30"), res = "minute")
  )
  for (case in cases) {
    layer <- qm_layer(synthetic_df(time_vals = case$vals))
    expect_equal(qm_meta(layer)$resolution, case$res)
    expect_equal(order(unique(layer$time_sort)),
                 order(sort(unique(case$vals))))
  }
})

test_that("gate-named column that fails the grammar is a loud error", {
  df <- synthetic_df(time_vals = c("Q1-2023", "Q2-2023"))
  expect_error(qm_layer(df), "could not be\\s+parsed")
})

test_that("non-date columns are never content-scanned", {
  df <- synthetic_df()[1:3, ]
  df$time_label <- NULL
  df$survey_round <- c("2022", "2023", "2024") # date-like content, wrong name
  layer <- qm_layer(df, value_col = "no2")
  expect_null(qm_meta(layer)$time_col) # static: name not in gate
})

test_that("explicit time_col accepts non-date orderings (diurnal hours)", {
  df <- synthetic_df()[1:6, ]
  df$time_label <- NULL
  df$hour <- rep(c("07", "08", "09"), 2)
  layer <- qm_layer(df, time_col = "hour")
  expect_equal(qm_meta(layer)$time_col, "time_label")
  expect_equal(sort(unique(layer$time_label)), c("07", "08", "09"))
  expect_null(qm_meta(layer)$resolution)
})

# ---- label duck typing ----

test_that("Label and School columns become label_col", {
  df <- synthetic_df()
  df$Label <- "site name"
  expect_equal(qm_meta(qm_layer(df))$label_col, "Label")

  df2 <- synthetic_df()[1:3, ]
  df2$time_label <- NULL
  df2$School <- c("A", "B", "C")
  df2$Level <- "Primary"
  layer2 <- qm_layer(df2, value_col = "Level")
  expect_equal(qm_meta(layer2)$label_col, "School")
})

# ---- print method ----

test_that("print summarises sites, steps, value and shape", {
  out <- capture.output(print(qm_layer(synthetic_df(), name = "merton_dt")))
  expect_match(out[1], "qm_layer 'merton_dt': 3 sites x 2 time steps \\[year\\] of no2 \\(circle\\)")

  static <- synthetic_df()[1:3, ]
  static$time_label <- NULL
  out2 <- capture.output(print(qm_layer(static, name = "ctx")))
  expect_match(out2[1], "static")
})

# ---- wrappers against DATA_PATH fixtures ----

test_that("from_csv builds a temporal circle layer from diffusion tubes", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  layer <- from_csv("merton_dt_2018_2024.csv")
  m <- qm_meta(layer)
  expect_s3_class(layer, "qm_layer")
  expect_equal(m$value_col, "no2")
  expect_equal(m$shape, "circle")
  expect_equal(m$resolution, "year")
  expect_true(all(grepl("^\\d{4}$", layer$time_label)))
  expect_equal(m$name, "merton_dt_2018_2024")
})

test_that("from_csv builds a static cross layer from schools", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  layer <- from_csv("schools_Merton.csv")
  m <- qm_meta(layer)
  expect_equal(m$shape, "cross")
  expect_equal(m$label_col, "School")
  expect_null(m$time_col)
})

test_that("from_rdata builds a diamond layer with normalised names", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  layer <- suppressMessages(
    from_rdata("bl_imperial_annualised_2021_2025_with_missing.Rdata", "no2")
  )
  m <- qm_meta(layer)
  expect_equal(m$shape, "diamond")
  expect_equal(m$value_col, "no2")
  expect_true("code" %in% names(layer))
  expect_false("siteCode" %in% names(layer))
  expect_false("year_str" %in% names(layer))
})

test_that("from_rdata preserves sub-annual resolution (episode fixture)", {
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixtures absent")

  layer <- suppressMessages(
    from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25")
  )
  m <- qm_meta(layer)
  expect_equal(m$resolution, "hour")
  expect_equal(length(unique(layer$time_label)), 108)
})

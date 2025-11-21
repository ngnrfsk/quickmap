test_that("load_colour_scale loads valid YAML scale", {
  scale <- load_colour_scale("who_no2")

  expect_type(scale, "list")
  expect_true("colours" %in% names(scale))
  expect_true("thresholds" %in% names(scale))
  expect_true("labels" %in% names(scale))
  expect_true("name" %in% names(scale))
  expect_true("title" %in% names(scale))
})

test_that("load_colour_scale validates threshold count matches colour count", {
  scale <- load_colour_scale("who_no2")

  # thresholds should be 1 more than colours (n+1 breakpoints for n ranges)
  expect_equal(length(scale$thresholds), length(scale$colours) + 1)
})

test_that("load_colour_scale validates label count", {
  scale <- load_colour_scale("who_no2")

  # labels should match colour count (one per range)
  expect_equal(length(scale$labels), length(scale$colours))
})

test_that("load_colour_scale handles missing file gracefully", {
  expect_error(
    load_colour_scale("nonexistent_scale"),
    "not found"
  )
})

test_that("load_colour_scale loads all bundled scales", {
  scales <- c("who_no2", "lbw_no2", "schools", "stripes_no2",
              "stripes_pm25", "lbrut_no2", "lbm_no2", "gla_pm25", "deltas")

  for (scale_name in scales) {
    scale <- load_colour_scale(scale_name)
    expect_type(scale, "list")
    expect_equal(scale$name, scale_name)
  }
})

test_that("colour scales have valid structure", {
  scale <- load_colour_scale("who_no2")

  # All thresholds numeric or Inf
  expect_true(all(sapply(scale$thresholds, function(x) is.numeric(x) || is.infinite(x))))

  # All colours are character strings
  expect_true(all(sapply(scale$colours, is.character)))

  # All labels are character strings
  expect_true(all(sapply(scale$labels, is.character)))
})

# Item 9 (partial fix, v0.9.8.1): qm_layer(shape=) metadata is wired through
# quickmap() to the renderer. Precedence: map-level data_symbols > layer
# shape metadata > automatic cycle (solid symbols for temporal layers,
# outline symbols for static layers).

shape_test_layer <- function(code_prefix, shape = NULL) {
  d <- data.frame(
    code = rep(paste0(code_prefix, 1:2), each = 3),
    year_str = rep(c("2020", "2021", "2022"), 2),
    no2 = c(12, 18, 25, 31, 42, 55),
    lat = rep(c(51.45, 51.46), each = 3),
    lon = rep(c(-0.20, -0.21), each = 3)
  )
  qm_layer(d, shape = shape, name = paste0(code_prefix, "_layer"))
}

shape_map_payload <- function(layers, ...) {
  withr::local_options(quickmap.lazy_step_threshold = 1)
  work <- withr::local_tempdir()
  withr::local_dir(work)
  suppressWarnings(quickmap(
    layers,
    boroughs = "Wandsworth",
    output_file = "item9_shapes.html",
    title = "shape test",
    styling_type = "html",
    ...
  ))
  html <- paste(
    readLines(file.path("aq_maps", "item9_shapes.html"), warn = FALSE),
    collapse = "\n"
  )
  char_lazy_payload(char_payload(html))
}

test_that("quickmap honours qm_layer shape metadata; unset shapes cycle", {
  testthat::skip_if_not_installed("jsonlite")

  lazy <- shape_map_payload(list(
    shape_test_layer("a", shape = "diamond"),
    shape_test_layer("b")                     # no shape: cycle -> circle
  ))
  expect_equal(
    vapply(lazy$layers, function(l) l$shape, ""),
    c("diamond", "circle")
  )
})

test_that("map-level data_symbols overrides layer shape metadata", {
  testthat::skip_if_not_installed("jsonlite")

  lazy <- shape_map_payload(
    list(shape_test_layer("a", shape = "diamond"), shape_test_layer("b")),
    data_symbols = c("triangle", "stadium")
  )
  expect_equal(
    vapply(lazy$layers, function(l) l$shape, ""),
    c("triangle", "stadium")
  )
})

test_that("qm shape 'cross' renders as the outline simple-cross symbol", {
  testthat::skip_if_not_installed("jsonlite")

  lazy <- shape_map_payload(list(shape_test_layer("a", shape = "cross")))
  expect_equal(lazy$layers[[1]]$shape, "simple-cross")
  expect_true(lazy$layers[[1]]$nonsolid)
})

test_that("qm_layer rejects unknown shapes and accepts NULL", {
  expect_error(shape_test_layer("a", shape = "hexagon"), "Valid shapes")
  expect_null(qm_meta(shape_test_layer("a"))$shape)
})

test_that("friendly shape names normalise; renderer names pass through", {
  expect_equal(qm_meta(shape_test_layer("a", "square"))$shape, "rect")
  expect_equal(qm_meta(shape_test_layer("a", "star"))$shape, "simple-star")
  expect_equal(qm_meta(shape_test_layer("a", "plus"))$shape, "simple-plus")
  expect_equal(qm_meta(shape_test_layer("a", "stadium"))$shape, "stadium")
  expect_equal(qm_meta(shape_test_layer("a", "triangle"))$shape, "triangle")
})

test_that("full-vocabulary shapes reach the rendered payload", {
  testthat::skip_if_not_installed("jsonlite")

  lazy <- shape_map_payload(list(
    shape_test_layer("a", shape = "star"),
    shape_test_layer("b", shape = "square")
  ))
  expect_equal(
    vapply(lazy$layers, function(l) l$shape, ""),
    c("simple-star", "rect")
  )
})

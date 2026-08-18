# Small fixes from the traced API catalogue's audit worklist
# (dev/260712_api_catalogue_v1.md), applied 2026-07-12 (v0.9.9.8).

small_fix_layer <- function() {
  d <- data.frame(
    code = rep(c("A", "B"), each = 2),
    year_str = rep(c("2021", "2022"), 2),
    no2 = c(12, 18, 25, 31),
    lat = rep(c(51.44, 51.46), each = 2),
    lon = rep(c(-0.17, -0.21), each = 2)
  )
  qm_layer(d, name = "survey")
}

test_that("non-matching display_times warns and names the available steps", {
  work <- withr::local_tempdir()
  withr::local_dir(work)
  expect_warning(
    quickmap(small_fix_layer(), display_times = "1999",
             output_file = "empty_times.html", title = "t"),
    "Available: 2021, 2022"
  )
})

test_that("styling_type rejects unknown values", {
  expect_error(
    quickmap(small_fix_layer(), styling_type = "fancy",
             output_file = "never_written.html"),
    'styling_type must be "html" or "none"'
  )
})

test_that("styling_type = 'none' still works (bare widget)", {
  work <- withr::local_tempdir()
  withr::local_dir(work)
  m <- quickmap(small_fix_layer(), styling_type = "none",
                output_file = "bare.html", title = "t")
  html <- paste(readLines("bare.html", warn = FALSE),
                collapse = "\n")
  expect_false(grepl('class="banner"', html, fixed = TRUE))
  expect_false(grepl('id="yearControl"', html, fixed = TRUE))
})

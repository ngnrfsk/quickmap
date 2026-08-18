# Roadmap item 9.3: marker_labels became symbol_labels. The old name keeps
# working, with a warning, at both public entry points and in a theme file.

labels_layer <- function() {
  d <- data.frame(
    code = rep(c("A", "B"), each = 2),
    year_str = rep(c("2021", "2022"), 2),
    no2 = c(12, 18, 25, 31),
    lat = rep(c(51.44, 51.46), each = 2),
    lon = rep(c(-0.17, -0.21), each = 2)
  )
  qm_layer(d, name = "survey")
}

test_that("the old argument name still works, with a warning", {
  work <- withr::local_tempdir()
  withr::local_dir(work)
  expect_warning(
    quickmap(labels_layer(), output_file = "old_name.html",
             marker_labels = "values_on", title = "t"),
    "marker_labels is now symbol_labels"
  )
  expect_true(file.exists("old_name.html"))
})

test_that("the old name reaches the renderer, not just the signature", {
  old <- suppressWarnings(
    absorb_legacy_args_result <- quickmap:::absorb_legacy_args(
      NULL, marker_labels = "values_on"
    )
  )
  expect_equal(old, "values_on")
})

test_that("giving both names is an error", {
  expect_error(
    quickmap(labels_layer(), output_file = "x.html",
             symbol_labels = TRUE, marker_labels = TRUE),
    "not both"
  )
})

test_that("an unrecognised argument is an error, not silently swallowed", {
  expect_error(
    quickmap(labels_layer(), output_file = "x.html", markr_labels = TRUE),
    "unused argument"
  )
  expect_error(
    quickmap:::absorb_legacy_args(NULL, nonsense = 1),
    "unused argument"
  )
})

test_that("create_pollution_map takes the old name too", {
  expect_error(
    create_pollution_map(data_sources = list(labels_layer()),
                         output_file = "x.html",
                         symbol_labels = TRUE, marker_labels = TRUE),
    "not both"
  )
})

test_that("a theme file with the old YAML key still applies, with a warning", {
  work <- withr::local_tempdir()
  theme_path <- file.path(work, "legacy.yaml")
  writeLines(c("map:", '  marker_labels: "values_on"'), theme_path)
  expect_warning(
    theme <- quickmap:::load_theme(theme_path),
    "rename it to map.symbol_labels"
  )
  expect_equal(theme$map$symbol_labels, "values_on")
  expect_null(theme$map$marker_labels)
})

test_that("the bundled themes use the new key", {
  for (f in list.files(system.file("themes", package = "quickmap"),
                       full.names = TRUE)) {
    yml <- yaml::read_yaml(f)
    expect_null(yml$map$marker_labels, info = basename(f))
  }
})

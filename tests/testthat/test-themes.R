test_that("get_default_theme returns complete structure", {
  theme <- get_default_theme()

  expect_type(theme, "list")
  expect_true("banner" %in% names(theme))
  expect_true("legend" %in% names(theme))
  expect_true("map" %in% names(theme))
  expect_true("controls" %in% names(theme))

  expect_true("background" %in% names(theme$banner))
  expect_true("text_color" %in% names(theme$banner))
  expect_true("title" %in% names(theme$banner))
})

test_that("load_theme returns defaults when theme_file is NULL", {
  theme <- load_theme(NULL)
  defaults <- get_default_theme()

  expect_identical(theme, defaults)
})

test_that("load_theme warns and returns defaults for nonexistent file", {
  expect_warning(
    theme <- load_theme("nonexistent_file.yaml"),
    "Theme file not found"
  )

  expect_identical(theme, get_default_theme())
})

test_that("load_theme loads and merges valid YAML theme", {
  # Use existing merton_purple theme
  theme_file <- "inst/themes/merton_purple.yaml"

  if (file.exists(theme_file)) {
    theme <- load_theme(theme_file)

    expect_type(theme, "list")
    expect_equal(theme$banner$background, "#5F3E94")
    expect_equal(theme$banner$title, "Merton Air Quality")

    # Verify defaults still present for unspecified fields
    expect_true(!is.null(theme$map$base_tiles))
  }
})

test_that("load_theme handles malformed YAML gracefully", {
  temp_file <- tempfile(fileext = ".yaml")
  writeLines("banner:\n  invalid: {]", temp_file)

  expect_warning(
    theme <- load_theme(temp_file),
    "Failed to load theme file"
  )

  expect_identical(theme, get_default_theme())
  unlink(temp_file)
})

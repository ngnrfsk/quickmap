test_that("build_banner_css replaces placeholders correctly", {
  css <- quickmap:::build_banner_css(banner_colour = "#FF0000", image_mode = FALSE)

  expect_type(css, "character")
  expect_true(grepl("#FF0000", css))
  expect_true(grepl("<style", css))
  expect_false(grepl("\\{\\{", css)) # No unreplaced placeholders
})

test_that("build_banner_css handles image mode", {
  interactive_css <- quickmap:::build_banner_css(banner_colour = "#FF0000", image_mode = FALSE)
  image_css <- quickmap:::build_banner_css(banner_colour = "#FF0000", image_mode = TRUE)

  expect_type(interactive_css, "character")
  expect_type(image_css, "character")
  expect_false(identical(interactive_css, image_css))
})

test_that("build_legend_css replaces placeholders correctly", {
  css <- quickmap:::build_legend_css(banner_colour = "#FF0000", image_mode = FALSE)

  expect_type(css, "character")
  expect_true(grepl("<style", css))
  expect_false(grepl("\\{\\{", css)) # No unreplaced placeholders
})

test_that("build_legend_css handles image mode", {
  interactive_css <- quickmap:::build_legend_css(banner_colour = "#FF0000", image_mode = FALSE)
  image_css <- quickmap:::build_legend_css(banner_colour = "#FF0000", image_mode = TRUE)

  expect_type(interactive_css, "character")
  expect_type(image_css, "character")
  expect_false(identical(interactive_css, image_css))
})

test_that("load_roller_menu_control replaces placeholders", {
  control <- quickmap:::load_roller_menu_control(
    banner_colour = "#FF0000",
    autoplay = TRUE,
    play_speed = 1000
  )

  expect_type(control, "character")
  expect_true(grepl("#FF0000", control))
  expect_true(grepl("true", control, ignore.case = TRUE)) # autoplay
  expect_true(grepl("1000", control)) # play_speed
  expect_false(grepl("\\{\\{", control)) # No unreplaced placeholders
})

test_that("CSS builders don't use sprintf with >3 positional params", {
  banner_src <- deparse(quickmap:::build_banner_css)
  legend_src <- deparse(quickmap:::build_legend_css)

  expect_false(any(grepl("sprintf.*%s.*%s.*%s.*%s", banner_src)))
  expect_false(any(grepl("sprintf.*%s.*%s.*%s.*%s", legend_src)))
})

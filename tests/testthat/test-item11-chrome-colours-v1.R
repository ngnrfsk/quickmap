# Item 11, user decisions 2026-09-22: default tiles openstreetmap.de (defect
# 18); the theme's legend.background honoured again (defect 17, reversing item
# 10); banner text_color read by the "bar" style; a warning when chrome text
# would be unreadable on its background.

test_that("default base tiles are OpenStreetMap.DE, a provider not a NULL", {
  theme <- quickmap:::get_default_theme()
  expect_equal(theme$map$base_tiles, "OpenStreetMap.DE")
  expect_true(theme$map$base_tiles %in% names(leaflet::providers))
})

test_that("legend CSS takes the theme's legend background", {
  css <- quickmap:::build_legend_css("#5F3E94", legend_background = "#DED4E9")
  expect_match(css, ".legend {\n  background: #DED4E9;", fixed = TRUE)
  expect_false(grepl("{{", css, fixed = TRUE))

  image <- quickmap:::build_legend_css("#5F3E94", image_mode = TRUE,
                                       legend_background = "#DED4E9")
  expect_match(image, "background: #DED4E9;", fixed = TRUE)

  # the default is still white, so the smoke output is unchanged
  expect_match(quickmap:::build_legend_css("#5F3E94"),
               ".legend {\n  background: white;", fixed = TRUE)
})

test_that("bar banner reads text_colour; strip keeps dark text on white", {
  bar <- quickmap:::build_banner_css("#880088", banner_style = "bar",
                                     text_colour = "#FFBB00")
  expect_match(bar, "background: #880088; color: #FFBB00;", fixed = TRUE)

  strip <- quickmap:::build_banner_css("#880088", text_colour = "#FFBB00")
  expect_match(strip, "background: #ffffff; color: #111111;", fixed = TRUE)
})

test_that("contrast_ratio follows WCAG 2", {
  expect_equal(quickmap:::contrast_ratio("black", "white"), 21)
  expect_equal(quickmap:::contrast_ratio("white", "white"), 1)
  expect_equal(quickmap:::contrast_ratio("#880088", "white"),
               quickmap:::contrast_ratio("white", "#880088"))
  expect_gt(quickmap:::contrast_ratio("white", "#880088"), 3)
})

test_that("check_chrome_contrast warns below 3:1 and is quiet above", {
  expect_warning(quickmap:::check_chrome_contrast("white", "#FFFFFF", "Banner"),
                 "Banner text white on background #FFFFFF")
  expect_warning(quickmap:::check_chrome_contrast("#FFBB00", "white", "Banner"),
                 "below 3:1")
  expect_silent(quickmap:::check_chrome_contrast("white", "#880088", "Banner"))
  expect_silent(quickmap:::check_chrome_contrast(quickmap:::LEGEND_TEXT_COLOUR,
                                                 "#DED4E9", "Legend"))
  expect_warning(quickmap:::check_chrome_contrast(quickmap:::LEGEND_TEXT_COLOUR,
                                                  "#222222", "Legend"),
                 "Legend text")
})

test_that("bundled themes all pass the contrast check", {
  themes <- list.files(system.file("themes", package = "quickmap"),
                       pattern = "\\.yaml$", full.names = TRUE)
  expect_gt(length(themes), 0)
  for (f in themes) {
    theme <- load_theme(f)
    if (identical(theme$banner$style, "bar")) {
      expect_silent(quickmap:::check_chrome_contrast(
        theme$banner$text_color, theme$banner$background, basename(f)))
    }
    expect_silent(quickmap:::check_chrome_contrast(
      quickmap:::LEGEND_TEXT_COLOUR, theme$legend$background, basename(f)))
  }
})

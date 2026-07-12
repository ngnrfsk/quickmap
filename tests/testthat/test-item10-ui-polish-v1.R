# Item 10 (v0.9.9.5): UI polish surface — banner styles, ramp legend,
# neutral chrome, Positron default, wind styling via theme.

test_that("build_banner_css supports strip (default) and bar styles", {
  strip <- quickmap:::build_banner_css("#5F3E94")
  expect_match(strip, "background: #ffffff", fixed = TRUE)
  expect_match(strip, "border-bottom: 3px solid #5F3E94", fixed = TRUE)
  expect_match(strip, "system-ui", fixed = TRUE)
  expect_false(grepl("{{", strip, fixed = TRUE))

  bar <- quickmap:::build_banner_css("#00549F", banner_style = "bar")
  expect_match(bar, "background: #00549F", fixed = TRUE)
  expect_false(grepl("border-bottom", bar, fixed = TRUE))

  expect_error(quickmap:::build_banner_css("#000", banner_style = "neon"),
               "banner style")
})

test_that("generate_legend_html emits the ramp structure with symbols kept", {
  html <- quickmap:::generate_legend_html("who_no2")
  expect_match(html, 'class="legend-ramp"', fixed = TRUE)
  expect_match(html, 'class="ramp-block"', fixed = TRUE)
  expect_match(html, 'class="ramp-label"', fixed = TRUE)
  expect_match(html, "†", fixed = TRUE)  # dagger symbol retained
  expect_match(html, 'class="legend-key"', fixed = TRUE)
})

test_that("default theme: OSM tiles, strip banner, wind styling block", {
  theme <- quickmap:::get_default_theme()
  # 2026-07-11: default reverted to OSM (NULL) — vignette too faint on
  # Positron; Positron remains a theme option
  expect_null(theme$map$base_tiles)
  expect_equal(theme$banner$style, "strip")
  expect_equal(length(theme$wind$colour_ramp), 6)
  expect_equal(theme$wind$particle_density, 1 / 300)
})

test_that("wind_style_options applies theme overrides over speed-ramp defaults", {
  defaults <- quickmap:::wind_style_options(NULL)
  # visibility-tuned defaults (2026-07-12): darker low-speed blue, denser
  expect_equal(unclass(defaults$colorScale)[1], "#4575b4")
  expect_equal(defaults$particleMultiplier, 1 / 300)

  custom <- quickmap:::wind_style_options(list(
    line_width = 2, colour_ramp = c("#111111", "#222222")
  ))
  expect_equal(custom$lineWidth, 2)
  expect_equal(length(custom$colorScale), 2)
  expect_equal(custom$velocityScale, 0.01)  # untouched default survives
})

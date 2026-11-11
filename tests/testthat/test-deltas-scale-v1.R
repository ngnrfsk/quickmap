# deltas scale (dev/261111_deltas_issue.md): ascending thresholds, missing-
# value entry, legend largest-fall-first, legend labels inside their blocks.

deltas_band_colours <- c(
  "#A50F15", "#DE2D26", "#FB6A4A", "#FEB24C", "#FEE391",   # rises, >8 to >0
  "#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#084594"    # falls, 0 to >=8
)

test_that("assign_colour gives the right colour inside every deltas band", {
  inside <- c(-12, -7, -5, -3, -1, 1, 3, 5, 7, 12)
  got <- vapply(inside, quickmap:::assign_colour, "", scale = "deltas")
  expect_equal(got, deltas_band_colours)
})

test_that("each deltas band includes its lower bound", {
  boundaries <- c(-8, -6, -4, -2, 0, 2, 4, 6, 8)
  got <- vapply(boundaries, quickmap:::assign_colour, "", scale = "deltas")
  expect_equal(got, deltas_band_colours[2:10])
  # just below each boundary is the band beneath
  below <- vapply(boundaries - 1e-9, quickmap:::assign_colour, "",
                  scale = "deltas")
  expect_equal(below, deltas_band_colours[1:9])
})

test_that("NA takes the 'Site not in use' colour", {
  scale <- quickmap::load_colour_scale("deltas")
  expect_equal(tail(scale$labels, 1), "Site not in use")
  expect_equal(quickmap:::assign_colour(NA, scale = "deltas"),
               tail(scale$colours, 1))
  expect_equal(quickmap:::assign_colour(NA_real_, scale = "deltas"), "white")
})

test_that("descending thresholds stop with a clear error", {
  local_mocked_bindings(
    load_yaml_config = function(...) list(
      thresholds = list(Inf, 8, 0, -Inf),
      colours = c("a", "b", "c", "white"),
      labels = c("x", "y", "z", "No data")
    ),
    .package = "quickmap"
  )
  expect_error(quickmap:::assign_colour(3, scale = "broken"),
               "Colour scale 'broken': thresholds must be in ascending order",
               fixed = TRUE)
})

test_that("deltas legend has one block and one label per scale label", {
  html <- quickmap:::generate_legend_html("deltas", collapsed_mobile = FALSE)
  n_labels <- length(quickmap::load_colour_scale("deltas")$labels)
  expect_equal(n_labels, 11)
  expect_equal(lengths(regmatches(html, gregexpr('class="ramp-block"', html))),
               n_labels)
  expect_equal(lengths(regmatches(html, gregexpr('class="ramp-label"', html))),
               n_labels)
})

test_that("deltas legend reads largest fall first, missing value last", {
  html <- quickmap:::generate_legend_html("deltas", collapsed_mobile = FALSE)
  labels <- regmatches(
    html, gregexpr('(?<=<div class="ramp-label">)[^\n]*(?=</div>)', html,
                   perl = TRUE)
  )[[1]]
  expect_equal(labels[1], "Fall ≥8")
  expect_equal(labels[5], "Fall 0 to <2")
  expect_equal(labels[10], "Rise >8")
  expect_equal(labels[11], "Site not in use")

  blocks <- regmatches(
    html, gregexpr('(?<=class="ramp-block" style="background: )#[0-9A-F]{6}',
                   html, perl = TRUE)
  )[[1]]
  expect_equal(blocks, c(rev(deltas_band_colours), "#FFFFFF"))
})

test_that("ascending scales keep their legend order", {
  html <- quickmap:::generate_legend_html("who_no2", collapsed_mobile = FALSE)
  first <- regmatches(
    html, regexpr('(?<=<div class="ramp-label">)[^\n]*(?=</div>)', html,
                  perl = TRUE)
  )
  expect_match(first, "^< 10")
})

test_that("ramp_position mirrors a descending legend and handles -Inf bands", {
  thr <- quickmap::load_colour_scale("deltas")$thresholds
  # 11 blocks: 10 bands + the missing-value block
  asc <- quickmap:::ramp_position(12, thr, 11)
  desc <- quickmap:::ramp_position(12, thr, 11, descending = TRUE)
  expect_equal(asc, round(100 * 9.5 / 11, 2))   # top band, midpoint
  expect_equal(desc, round(100 * 0.5 / 11, 2))   # drawn first when descending

  bottom <- quickmap:::ramp_position(-12, thr, 11)
  expect_true(is.finite(bottom))
  expect_equal(bottom, round(100 * 0.5 / 11, 2))

  expect_equal(quickmap:::ramp_position(1, thr, 11, descending = TRUE),
               round(100 * (10 - 5.5) / 11, 2))
})

test_that("lazy payload keeps the deltas bottom band's colour", {
  d <- data.frame(
    siteCode = "A", year_str = "2020", no2 = -12,
    Longitude = -0.2, Latitude = 51.45
  )
  layers <- list(dt = list(
    enabled = TRUE, id = "dt", static = FALSE, icon_shape = "circle",
    options = list(symbol_labels = FALSE)
  ))
  payload <- quickmap:::build_lazy_payload(
    layers, list(all_data = list(dt = d)), "2020", "no2", "deltas"
  )
  expect_equal(as.character(payload$colours), deltas_band_colours)
  expect_length(payload$thresholds, 10)
  expect_true(all(is.finite(payload$thresholds)))
  expect_lt(payload$thresholds[1], -8)
  expect_equal(payload$naColour, "#FFFFFF")
  json <- jsonlite::toJSON(payload$thresholds)
  expect_false(grepl("Inf|null", json))
})

test_that("legend CSS lets ramp labels shrink and wrap within their block", {
  for (mode in c(TRUE, FALSE)) {
    css <- quickmap:::build_legend_css(image_mode = mode)
    rule <- regmatches(css, regexpr("\\.ramp-label \\{[^}]*\\}", css))
    expect_match(rule, "min-width: 0", fixed = TRUE)
    expect_false(grepl("nowrap", rule, fixed = TRUE))
  }
})

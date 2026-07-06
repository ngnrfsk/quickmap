# Characterization net (roadmap item 2): pin the rendered HTML output of the
# reference maps. Counts and group names below were recorded from v0.9.5 output
# and act as the regression baseline for the item-4 API refactor and item-6
# lazy-loading work. If a deliberate rendering change alters them, update the
# expected values in the same change and flag it for human visual sign-off.

skip_if_no_char_data <- function() {
  testthat::skip_if_not_installed("jsonlite")
  testthat::skip_if_not(char_data_available(), "DATA_PATH fixture files not available")
}

# ---- annual multi-year map (diffusion tubes + BL sensors + schools) ----

test_that("annual map: payload method counts are stable", {
  skip_if_no_char_data()
  payload <- char_payload(char_html("char_annual.html"))
  methods <- char_methods(payload)

  expect_equal(sum(methods == "addTiles"), 1)
  expect_equal(sum(methods == "addPolygons"), 2) # borough boundary + vignette
  expect_equal(sum(methods == "addMarkers"), 9)  # (dt + bl + schools) x 3 years
  expect_equal(sum(methods == "showGroup"), 3)
})

test_that("annual map: marker counts per layer and time step", {
  skip_if_no_char_data()
  mk <- char_marker_calls(char_payload(char_html("char_annual.html")))

  # temporal layers, one group per displayed year
  expect_equal(sort(unique(mk$group[!is.na(mk$group)])), c("2020", "2021", "2022"))

  # diffusion tubes then BL sensors per year (recorded v0.9.5 baseline)
  expect_equal(mk$n[!is.na(mk$group)][order(mk$group[!is.na(mk$group)])],
               c(59, 1, 59, 276, 61, 363))

  # schools: static layer (no group), repeated once per year, 53 schools
  expect_equal(mk$n[is.na(mk$group)], c(53, 53, 53))
})

test_that("annual map: displayed years are shown as groups", {
  skip_if_no_char_data()
  payload <- char_payload(char_html("char_annual.html"))
  expect_equal(sort(char_shown_groups(payload)), c("2020", "2021", "2022"))
})

test_that("annual map: banner, legend and year control are injected", {
  skip_if_no_char_data()
  html <- char_html("char_annual.html")

  expect_true(grepl('class="banner"', html, fixed = TRUE))
  expect_true(grepl("Characterization annual", html, fixed = TRUE))
  expect_true(grepl('id="mapLegend"', html, fixed = TRUE))
  expect_true(grepl('class="legend-container"', html, fixed = TRUE))
  expect_true(grepl('id="yearControl"', html, fixed = TRUE))
  expect_true(grepl('id="yearList"', html, fixed = TRUE))
  expect_true(grepl('id="playPauseButton"', html, fixed = TRUE))
})

test_that("annual map: no unreplaced template placeholders", {
  skip_if_no_char_data()
  expect_false(grepl("\\{\\{[a-z_]+\\}\\}", char_html("char_annual.html")))
})

test_that("annual map: self-contained (no external script/css loads)", {
  skip_if_no_char_data()
  html <- char_html("char_annual.html")
  expect_false(grepl('<script[^>]+src="https?://', html))
  expect_false(grepl('<link[^>]+href="https?://', html))
})

# ---- canonical animation example (inst/examples/episode_example.R, map2) ----
# Reproduces the published parhillresearch.github.io/maps/episode.html byte
# size: the ~3.5 MB, 108-time-step product whose slow loading motivates the
# rendering-backend decision (item 5) and lazy loading (item 6).

test_that("episode map: one marker group per hourly time step", {
  skip_if_no_char_data()
  payload <- char_payload(char_html("char_episode.html"))
  methods <- char_methods(payload)
  mk <- char_marker_calls(payload)

  expect_equal(sum(methods == "addMarkers"), 108)      # 108 hourly steps
  expect_equal(sum(methods == "showGroup"), 108)
  expect_equal(sum(methods == "addProviderTiles"), 1)  # airstat theme base tiles
  expect_equal(sum(methods == "addPolygons"), 1)       # boundaries, no vignette

  expect_true(all(!is.na(mk$group)))
  expect_equal(length(unique(mk$group)), 108)
  groups <- sort(mk$group)
  expect_equal(groups[1], "2024-01-15 12:00")
  expect_equal(groups[108], "2024-01-19 23:00")

  # all BL sensors across the two boroughs, per step (recorded baseline)
  expect_true(all(mk$n >= 369 & mk$n <= 385))
  expect_equal(sum(mk$n), 40876)
})

test_that("episode map: file size baseline — the problem item 6 must fix", {
  skip_if_no_char_data()
  size <- char_file_size("char_episode.html")

  # Recorded v0.9.5 baseline: 3,456,970 bytes (matches the published map).
  # Item 6 (lazy loading) should CUT this dramatically — when it does, lower
  # these bounds in the same change. A rise above the ceiling is a regression.
  expect_gt(size, 3.2e6)
  expect_lt(size, 3.7e6)
})

test_that("episode map: banner, time control and autoplay injected", {
  skip_if_no_char_data()
  html <- char_html("char_episode.html")

  expect_true(grepl("PM2.5 Episode: Jan 15-20, 2024", html, fixed = TRUE))
  expect_true(grepl('id="yearControl"', html, fixed = TRUE))
  expect_true(grepl('id="playPauseButton"', html, fixed = TRUE))
  expect_false(grepl("\\{\\{[a-z_]+\\}\\}", html))
})

test_that("episode map: self-contained (no external script/css loads)", {
  skip_if_no_char_data()
  html <- char_html("char_episode.html")
  expect_false(grepl('<script[^>]+src="https?://', html))
  expect_false(grepl('<link[^>]+href="https?://', html))
})

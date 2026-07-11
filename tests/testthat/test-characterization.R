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

  # v0.9.9.5 made Positron the default; REVERTED 2026-07-11 (v0.9.9.7):
  # OSM default again (vignette too faint on pale tiles).
  expect_equal(sum(methods == "addTiles"), 1)
  expect_equal(sum(methods == "addProviderTiles"), 0)
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
  # DELIBERATE CHANGE (item 10, v0.9.9.5): the roller dropdown (yearList)
  # was replaced by the bottom time slider (sliderTrack).
  expect_true(grepl('id="yearControl"', html, fixed = TRUE))
  expect_true(grepl('id="sliderTrack"', html, fixed = TRUE))
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

# DELIBERATE FORMAT CHANGE (item 6, v0.9.7): above 50 time steps the episode
# map now renders via the lazy embedded-JSON path — no per-step addMarkers /
# showGroup calls; one onRender payload restyles Canvas markers in JS. The
# marker-count parity is asserted on the payload instead (40,876 non-null
# site-step values, matching the v0.9.5 addMarkers baseline). Flagged for
# human visual sign-off in the item-6 PR.

test_that("episode map: lazy payload replaces per-step marker groups", {
  skip_if_no_char_data()
  payload <- char_payload(char_html("char_episode.html"))
  methods <- char_methods(payload)

  expect_equal(sum(methods == "addMarkers"), 0)        # lazy path: no pre-built layers
  expect_equal(sum(methods == "showGroup"), 0)
  expect_equal(sum(methods == "addProviderTiles"), 1)  # airstat theme base tiles
  expect_equal(sum(methods == "addPolygons"), 1)       # boundaries, no vignette

  lazy <- char_lazy_payload(payload)
  times <- unlist(lazy$times)
  expect_equal(length(times), 108)                     # 108 hourly steps
  expect_equal(times[1], "2024-01-15 12:00")
  expect_equal(times[108], "2024-01-19 23:00")

  expect_equal(length(lazy$layers), 1)
  sites <- lazy$layers[[1]]$sites
  expect_equal(length(sites), 395)                     # BL sensors, both boroughs
  expect_true(all(vapply(sites, function(s) length(s$v), 0L) == 108))

  # marker parity with the v0.9.5 pre-built baseline: one non-null value per
  # marker that the old path drew (40,876 across all steps)
  n_values <- sum(vapply(
    sites,
    function(s) sum(!vapply(s$v, is.null, TRUE)),
    0L
  ))
  expect_equal(n_values, 40876)

  # styling contract consumed by lazy-time-controller.js
  expect_equal(unlist(lazy$thresholds), c(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50))
  expect_equal(length(lazy$colours), 11)
  expect_true(all(grepl("^#[0-9A-F]{6}$", unlist(lazy$colours))))
  expect_equal(lazy$layers[[1]]$labelMode, "values")   # marker_labels = TRUE
})

test_that("episode map: file size — item 6 lazy-loading result", {
  skip_if_no_char_data()
  size <- char_file_size("char_episode.html")

  # v0.9.5 baseline was 3,456,970 bytes; the item-6 lazy path cuts it to
  # ~914 KB (~520 KB of that is the fixed leaflet/htmlwidgets stack every
  # quickmap output carries). A rise above the ceiling is a regression.
  expect_gt(size, 6e5)
  expect_lt(size, 1.1e6)
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

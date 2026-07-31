# Legend indicator (user-approved 2026-07-29): the network mean per time step,
# drawn against the colour scale's thresholds.
#
# The behaviours asserted here are the user's decisions, not implementation
# detail: a fixed panel of sites, a mean, one combined figure, and nothing at
# all on sub-annual maps.

make_layers <- function(ids, static = FALSE) {
  stats::setNames(
    lapply(ids, function(id) {
      list(enabled = TRUE, id = id, static = static, icon_shape = "circle",
           options = list(marker_labels = FALSE))
    }),
    ids
  )
}

# Three sites, three years; site C is missing 2021 entirely.
fixture <- function() {
  d <- data.frame(
    siteCode = c(rep("A", 3), rep("B", 3), "C", "C"),
    year_str = c("2019", "2020", "2021", "2019", "2020", "2021",
                 "2019", "2020"),
    no2 = c(40, 30, 20, 60, 50, 40, 10, 10),
    Longitude = -0.19,
    Latitude = 51.41,
    stringsAsFactors = FALSE
  )
  list(all_data = list(tubes = d), ids = "tubes")
}

test_that("the aggregate is a mean over the fixed panel", {
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020", "2021"), "no2"
  )

  # C is dropped: it has no 2021 reading, so including it would make 2021
  # rise purely because a low-reading site stopped reporting
  expect_equal(ind$n_sites, 2L)
  expect_equal(ind$values, c(50, 40, 30))
  expect_equal(ind$times, c("2019", "2020", "2021"))
})

test_that("the panel is defined over the displayed steps only", {
  # Asking for 2019-2020 alone lets site C back in: it reports in both
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020"), "no2"
  )
  expect_equal(ind$n_sites, 3L)
  expect_equal(ind$values, c(36.7, 30))
})

test_that("a site measured twice in one step does not count as two steps", {
  sp <- fixture()
  sp$all_data$tubes <- rbind(
    sp$all_data$tubes,
    data.frame(siteCode = "C", year_str = "2020", no2 = 12,
               Longitude = -0.19, Latitude = 51.41)
  )
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), sp, c("2019", "2020", "2021"), "no2"
  )
  expect_equal(ind$n_sites, 2L)
})

test_that("layers are combined into one figure, keyed per layer", {
  sp <- fixture()
  sp$all_data$sensors <- data.frame(
    siteCode = "A", # same code as a tube site: must not merge
    year_str = c("2019", "2020", "2021"),
    no2 = c(10, 10, 10),
    Longitude = -0.2, Latitude = 51.4,
    stringsAsFactors = FALSE
  )
  sp$ids <- c("tubes", "sensors")

  ind <- quickmap:::build_indicator_data(
    make_layers(c("tubes", "sensors")), sp, c("2019", "2020", "2021"), "no2"
  )
  expect_equal(ind$n_sites, 3L) # tubes A, tubes B, sensors A
  expect_equal(ind$values, c(36.7, 30, 23.3))
})

test_that("no indicator on sub-annual, static or empty maps", {
  layers <- make_layers("tubes")
  sp <- fixture()

  expect_null(quickmap:::build_indicator_data(layers, sp, "static_only", "no2"))
  expect_null(quickmap:::build_indicator_data(
    layers, sp, c("2024-01", "2024-02"), "no2"
  ))
  expect_null(quickmap:::build_indicator_data(
    layers, sp, c("2019-01-15 10:00"), "no2"
  ))
  expect_null(quickmap:::build_indicator_data(layers, sp, character(0), "no2"))
  expect_null(quickmap:::build_indicator_data(
    layers, sp, c("2019", "2030"), "no2" # no site spans both
  ))
  expect_null(quickmap:::build_indicator_data(
    make_layers("tubes", static = TRUE), sp, c("2019", "2020"), "no2"
  ))
})

test_that("missing readings are gaps, never zeros", {
  sp <- fixture()
  sp$all_data$tubes$no2[sp$all_data$tubes$siteCode == "B" &
                          sp$all_data$tubes$year_str == "2020"] <- NA
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), sp, c("2019", "2020", "2021"), "no2"
  )
  # B now fails the panel; A alone remains, and 2020 is A's 30, not (40+0)/2
  expect_equal(ind$n_sites, 1L)
  expect_equal(ind$values, c(40, 30, 20))
})

test_that("the drawn indicator carries the figure, units and every step", {
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020", "2021"), "no2"
  )
  html <- quickmap:::generate_indicator_html(ind, "who_no2")

  expect_match(html, 'id="qmIndicator"', fixed = TRUE)
  expect_match(html, "Network mean, 2 sites", fixed = TRUE)
  expect_match(html, "µg/m³", fixed = TRUE)
  expect_match(html, '"values":[50.0,40.0,30.0]', fixed = TRUE)
  expect_match(html, "window.quickmapIndicatorController", fixed = TRUE)

  # rem/viewBox only: fixed pixel sizes would reproduce defect 9 by hand
  expect_false(grepl("width=\"[0-9]+px\"", html))
})

test_that("a static export shows its own step and ships no script", {
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020", "2021"), "no2"
  )
  html <- quickmap:::generate_indicator_html(
    ind, "who_no2", image_mode = TRUE, display_times = "2021"
  )

  expect_match(html, ">30.0<", fixed = TRUE)
  expect_false(grepl("<script", html, fixed = TRUE))
  expect_false(grepl("quickmapIndicatorData", html, fixed = TRUE))
})

test_that("no indicator data means no indicator markup", {
  expect_identical(quickmap:::generate_indicator_html(NULL, "who_no2"), "")
})

test_that("the legend still renders when there is no indicator", {
  legend <- quickmap:::generate_legend_html("who_no2")
  expect_match(legend, 'id="mapLegend"', fixed = TRUE)
  expect_false(grepl("qmIndicator", legend, fixed = TRUE))
  expect_false(grepl("{{", legend, fixed = TRUE)) # every placeholder filled
})

test_that("legend content containing a percent sign survives", {
  # the old sprintf template broke on any literal % in injected content
  legend <- quickmap:::generate_legend_html(
    "who_no2", indicator_html = '<div style="width: 50%">50% done</div>'
  )
  expect_match(legend, "50% done", fixed = TRUE)
})

test_that("the time slider drives the indicator on both rendering paths", {
  js <- quickmap:::read_template_file(
    file.path(quickmap:::get_package_dir("controls"), "time-slider.js")
  )
  hook <- regexpr("window.quickmapIndicatorController.setTime", js,
                  fixed = TRUE)
  # the branch itself, not the file header that also names it
  lazy_branch <- regexpr("if (window.quickmapTimeController)", js,
                         fixed = TRUE)

  # above the lazy-path branch, or it silently never fires over 50 steps
  expect_true(hook > 0)
  expect_true(lazy_branch > 0)
  expect_true(hook < lazy_branch)
})

test_that("ramp positions are measured band by band, not linearly", {
  # gla_pm25: bands 5, 2.5, 2.5, 2.5, 2.5, 5, 5, Inf — all drawn equal width,
  # so position must follow the blocks, not the numbers
  th <- c(0, 5, 7.5, 10, 12.5, 15, 20, 25, Inf)
  n <- 8

  # 7.5 ends band 2 of 8
  expect_equal(quickmap:::ramp_position(7.5, th, n), 25)
  # 8.75 is halfway through band 3
  expect_equal(quickmap:::ramp_position(8.75, th, n), 31.25)
  # a linear reading of 8.75 against a 25-max scale would be 35 — different
  expect_false(isTRUE(all.equal(
    quickmap:::ramp_position(8.75, th, n), 35
  )))

  # open-ended top band: midpoint, never a fabricated position
  expect_equal(quickmap:::ramp_position(400, th, n),
               quickmap:::ramp_position(30, th, n))
  # below the scale, and NA
  expect_equal(quickmap:::ramp_position(0, th, n), 0)
  expect_equal(quickmap:::ramp_position(NA_real_, th, n), 0)
})

test_that("the bar is trimmed with the legend it sits above", {
  scale <- quickmap:::load_colour_scale("lbm_no2")
  full <- length(scale$colours)
  trimmed <- length(quickmap:::trim_colour_scale(scale, 33.9)$colours)

  expect_lt(trimmed, full)
  # same value, fewer blocks -> further along the bar, because the bar is a
  # fraction of the ramp actually drawn
  expect_gt(
    quickmap:::ramp_position(23.2, scale$thresholds, trimmed),
    quickmap:::ramp_position(23.2, scale$thresholds, full)
  )
})

test_that("the roundel marks the ramp and nothing draws a second scale", {
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020", "2021"), "no2"
  )

  roundel <- quickmap:::generate_indicator_bar(ind, "who_no2")
  expect_match(roundel, "qm-roundel", fixed = TRUE)
  expect_match(roundel, "left:", fixed = TRUE) # positioned, not filled
  expect_match(roundel, ">50.0<", fixed = TRUE) # carries its own figure

  block <- quickmap:::generate_indicator_html(ind, "who_no2")
  expect_match(block, "Network mean, 2 sites", fixed = TRUE)
  expect_match(block, '"w":[', fixed = TRUE) # positions for every step
  expect_match(block, "qm-ind-chip-roundel", fixed = TRUE)

  # the retired track and bar styles are archived; nothing draws either now
  expect_false(grepl("qm-ind-svg", block, fixed = TRUE))
  expect_false(grepl("qm-bar-fill", roundel, fixed = TRUE))

  expect_identical(quickmap:::generate_indicator_html(NULL, "who_no2"), "")
})

test_that("the maximum comes from the same panel as the mean", {
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020", "2021"), "no2"
  )
  # panel is A (40/30/20) and B (60/50/40); C is excluded from both figures,
  # so the two are computed over the same sites and remain comparable
  expect_equal(ind$values, c(50, 40, 30))
  expect_equal(ind$max_values, c(60, 50, 40))
})

test_that("the maximum is drawn as a diamond, off by default", {
  ind <- quickmap:::build_indicator_data(
    make_layers("tubes"), fixture(), c("2019", "2020", "2021"), "no2"
  )

  plain <- quickmap:::generate_indicator_bar(ind, "who_no2")
  expect_false(grepl("qm-diamond", plain, fixed = TRUE))

  with_max <- quickmap:::generate_indicator_bar(
    ind, "who_no2", show_max = TRUE
  )
  expect_match(with_max, "qm-diamond", fixed = TRUE)
  expect_match(with_max, ">60.0<", fixed = TRUE) # the maximum's own figure
  expect_match(with_max, "qm-roundel", fixed = TRUE) # mean still there

  block <- quickmap:::generate_indicator_html(ind, "who_no2", show_max = TRUE)
  expect_match(block, "Highest site", fixed = TRUE)
  expect_match(block, "qm-ind-chip-diamond", fixed = TRUE)
  expect_match(block, '"maxValues":[', fixed = TRUE)
  # shape distinguishes the two, not colour: both take their own band colour
  expect_match(block, "qm-ind-chip-roundel", fixed = TRUE)
})

test_that("markers separate only when they would overlap", {
  # far apart: 10 and 90 on a 0-100 scale
  apart <- list(
    values = 10, max_values = 90, times = "2019", n_sites = 5L,
    pollutant = "no2"
  )
  html <- quickmap:::generate_indicator_bar(apart, "who_no2", show_max = TRUE)
  expect_false(grepl("qm-lifted", html, fixed = TRUE))
  expect_false(grepl("qm-dropped", html, fixed = TRUE))

  # nearly equal: the rule must fire, or the two markers sit on top of each
  # other and the figures become unreadable
  close <- list(
    values = 42, max_values = 43, times = "2019", n_sites = 5L,
    pollutant = "no2"
  )
  html <- quickmap:::generate_indicator_bar(close, "who_no2", show_max = TRUE)
  expect_match(html, "qm-lifted", fixed = TRUE)
  expect_match(html, "qm-dropped", fixed = TRUE)
})

test_that("the network figures sit under the legend title and collapse with it", {
  template <- quickmap:::read_template_file(
    file.path(quickmap:::get_package_dir("legend"), "legend.html")
  )
  lead <- regexpr("legend-lead", template, fixed = TRUE)
  header <- regexpr("legend-header", template, fixed = TRUE)
  indicator <- regexpr("{{legend_indicator}}", template, fixed = TRUE)
  content <- regexpr("legend-content", template, fixed = TRUE)

  # the figures live in the lead column, after the title and before the ramp
  expect_true(lead > 0 && lead < header)
  expect_true(header < indicator)
  expect_true(indicator < content)

  css <- quickmap:::read_template_file(
    file.path(quickmap:::get_package_dir("legend"), "legend-interactive.css")
  )
  expect_match(css, ".legend.collapsed .legend-indicator", fixed = TRUE)
})

test_that("the indicator is switchable through the theme", {
  expect_true(quickmap:::get_default_theme()$indicator$show)

  theme_file <- tempfile(fileext = ".yaml")
  writeLines(c("indicator:", "  show: false"), theme_file)
  expect_false(quickmap:::load_theme(theme_file)$indicator$show)
})

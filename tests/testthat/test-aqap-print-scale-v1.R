# LB Merton AQAP print set (2026-08-05): the footnote-symbol opt-out and the
# lbm_aqap_no2 scale it was added for. The AQAP is a legal document, so the
# label wording is asserted, not just the mechanism.

test_that("a scale can drop the footnote symbols and keep its pills", {
  html <- quickmap:::generate_legend_html("lbm_aqap_no2", data_max = 47)

  # no cross-reference markers anywhere
  for (sym in c("†", "‡", "§", "¶", "*")) {
    expect_false(grepl(sym, html, fixed = TRUE), info = sym)
  }
  # but the pills survive, which is the point of the opt-out
  expect_match(html, 'class="legend-key"', fixed = TRUE)
  expect_match(html, "WHO guideline", fixed = TRUE)
})

test_that("the default is unchanged: other scales keep their symbols", {
  html <- quickmap:::generate_legend_html("lbm_no2", data_max = 47)
  expect_match(html, "†", fixed = TRUE)
  expect_match(html, "‡", fixed = TRUE)
})

test_that("the 20 ug/m3 target is named from both sides", {
  html <- quickmap:::generate_legend_html("lbm_aqap_no2", data_max = 47)
  # Naming only one side lets the band label be read as the target itself,
  # which is the mistake this scale exists to prevent.
  expect_match(html, "meets Merton 2030 target", fixed = TRUE)
  expect_match(html, "over Merton 2030 target", fixed = TRUE)

  scale <- quickmap:::load_colour_scale("lbm_aqap_no2")
  meets <- grep("meets Merton 2030 target", scale$labels)
  above <- grep("over Merton 2030 target", scale$labels)
  # the boundary between the two bands must be exactly 20
  expect_equal(scale$thresholds[meets + 1], 20)
  expect_equal(scale$thresholds[above], 20)

  # no band claims compliance with the UK limit; "below UK limit" on 30-39
  # would be true but reads as reassurance well above Merton's own target
  expect_false(any(grepl("below UK limit", scale$labels, fixed = TRUE)))
})

test_that("the print scale matches lbm_no2 on colours and thresholds", {
  # The printed maps must agree with every Merton map already circulated:
  # only the wording and the symbols were meant to change.
  aqap <- quickmap:::load_colour_scale("lbm_aqap_no2")
  base <- quickmap:::load_colour_scale("lbm_no2")
  expect_equal(aqap$colours, base$colours)
  expect_equal(aqap$thresholds, base$thresholds)
  expect_equal(length(aqap$labels), length(base$labels))
})

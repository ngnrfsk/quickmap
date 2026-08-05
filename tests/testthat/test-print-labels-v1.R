# Print-set labelling (2026-08-05): marker labels follow the export size, and
# the value labels carry proper units. Both matter because the output is an
# A4 page in a legal document, not a screen.

test_that("marker labels scale with the export, not a flat 12px", {
  # The defect (roadmap item 11, "unified marker/text/legend scaling"): a
  # 4000px export scaled its symbols and left its labels at 12px, which lands
  # near 4.7pt on A4 — below what prints legibly.
  args <- names(formals(quickmap:::generate_map_layers))
  expect_true("label_scale" %in% args)
  expect_equal(formals(quickmap:::generate_map_layers)$label_scale, 1.0)

  # add_year_and_static_layers must pass it through, or the static path (the
  # only path that exports) silently keeps the old behaviour
  expect_true("label_scale" %in%
                names(formals(quickmap:::add_year_and_static_layers)))
})

test_that("label_scale is a theme key, defaulting to no change", {
  expect_equal(quickmap:::get_default_theme()$map$label_scale, 1)
})

test_that("symbol stroke scales with the export too", {
  # A cross is nothing but its stroke, so a flat 2px came out hairline on a
  # 4000px print while the symbol itself grew almost threefold.
  data <- data.frame(School = "x", Level = "Primary")
  interactive <- quickmap:::create_generic_icons(
    data, "simple-cross", image_scale_factor = 1.0
  )
  print_icons <- quickmap:::create_generic_icons(
    data, "simple-cross", image_scale_factor = sqrt(4000 * 3000 / 1200^2)
  )
  # the icon is a URL-encoded SVG data URI: stroke-width%3D%22N%22
  stroke <- function(ic) {
    svg <- utils::URLdecode(as.character(ic$iconUrl[[1]]))
    m <- regmatches(svg, regexpr('stroke-width="[0-9.]+"', svg))
    as.numeric(gsub("[^0-9.]", "", m))
  }
  expect_equal(stroke(interactive), 2)      # screens are unchanged
  expect_equal(stroke(print_icons), 6)      # round(2 * 2.887)
})

test_that("value labels carry proper units on both rendering paths", {
  data <- data.frame(no2 = c(28.4, NA), Easting = 1, Northing = 1)
  labels <- quickmap:::generate_marker_labels(data, "no2", "values_on", "dt")
  expect_equal(labels[1], "28 µg/m³")
  expect_equal(labels[2], "")          # no label where there is no value
  expect_false(grepl("ug/m3", labels[1], fixed = TRUE))

  # the lazy Canvas path writes its own tooltips in JS and must agree
  js <- paste(readLines(
    system.file("controls", "lazy-time-controller.js", package = "quickmap"),
    warn = FALSE
  ), collapse = "\n")
  expect_match(js, "µg/m³", fixed = TRUE)
  expect_false(grepl("ug/m3", js, fixed = TRUE))
})

test_that("values_on labels schools by name and sites by value", {
  # This is the whole reason "values_on" is the right setting for the print
  # set: content is duck-typed per layer, so one setting gives both.
  schools <- data.frame(School = c("Aragon Primary School"), no2 = NA)
  expect_equal(
    quickmap:::generate_marker_labels(schools, "no2", "values_on", "schools"),
    "Aragon Primary School"
  )

  # a site layer with a Label column still shows values under "values_on" —
  # "labels_on" is what asks for the Label column instead
  sites <- data.frame(Label = "Bushey Road", no2 = 47)
  expect_equal(
    quickmap:::generate_marker_labels(sites, "no2", "values_on", "dt"),
    "47 µg/m³"
  )
  expect_equal(
    quickmap:::generate_marker_labels(sites, "no2", "labels_on", "dt"),
    "Bushey Road"
  )
})

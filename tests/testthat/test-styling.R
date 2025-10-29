# Test styling system functionality

test_that("styling_type='none' creates plain map without banner/legend", {
  map_none <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    styling_type = "none",
    output_file = "test_styling_none.html"
  )

  expect_s3_class(map_none, "leaflet")
  expect_true(file.exists("aq_maps/test_styling_none.html"))

  # Read HTML and check for absence of banner/legend
  html_content <- readLines("aq_maps/test_styling_none.html", warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")

  # Should NOT contain custom banner div
  expect_false(grepl("custom-banner", html_text, fixed = TRUE))
  # Should NOT contain external legend div
  expect_false(grepl("external-legend", html_text, fixed = TRUE))
})

test_that("styling_type='html' creates map with banner and legend", {
  map_html <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    styling_type = "html",
    title = "Wandsworth Air Quality Test",
    output_file = "test_styling_html.html"
  )

  expect_s3_class(map_html, "leaflet")
  expect_true(file.exists("aq_maps/test_styling_html.html"))

  # Read HTML and check for presence of banner/legend
  html_content <- readLines("aq_maps/test_styling_html.html", warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")

  # Should contain custom banner div
  expect_true(grepl("custom-banner", html_text, fixed = TRUE))
  # Should contain external legend div
  expect_true(grepl("external-legend", html_text, fixed = TRUE))
  # Should contain the title text
  expect_true(grepl("Wandsworth Air Quality Test", html_text, fixed = TRUE))
})

test_that("banner_colour parameter works", {
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Merton",
      years = 2024,
      styling_type = "html",
      banner_colour = "#9370DB",
      output_file = "test_styling_banner_colour.html"
    )
  )

  # Check banner colour is applied
  html_content <- readLines("aq_maps/test_styling_banner_colour.html", warn = FALSE)
  html_text <- paste(html_content, collapse = "\n")
  expect_true(grepl("#9370DB", html_text, fixed = TRUE))
})

test_that("vignette parameter controls vignette overlay", {
  # With vignette
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      vignette = TRUE,
      output_file = "test_styling_vignette_on.html"
    )
  )

  # Without vignette
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      vignette = FALSE,
      output_file = "test_styling_vignette_off.html"
    )
  )
})

test_that("marker_labels and boundary_labels parameters work", {
  # Marker labels on, boundary labels off
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      marker_labels = TRUE,
      boundary_labels = FALSE,
      output_file = "test_styling_labels_1.html"
    )
  )

  # Both off
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      marker_labels = FALSE,
      boundary_labels = FALSE,
      output_file = "test_styling_labels_2.html"
    )
  )

  # Both on
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      marker_labels = TRUE,
      boundary_labels = TRUE,
      output_file = "test_styling_labels_3.html"
    )
  )
})

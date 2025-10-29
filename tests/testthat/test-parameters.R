# Test parameter renames and basic functionality

test_that("renamed parameters work correctly", {
  # Test all 6 renamed parameters
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      school_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      vignette = TRUE,
      marker_labels = FALSE,
      boundary_labels = FALSE,
      output_file = "test_parameters_renames.html"
    )
  )

  # Check output file was created
  expect_true(file.exists("aq_maps/test_parameters_renames.html"))
})

test_that("title parameter works for both browser and banner", {
  # Test default title
  map_default <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    output_file = "test_parameters_title_default.html"
  )
  expect_s3_class(map_default, "leaflet")
  expect_true(file.exists("aq_maps/test_parameters_title_default.html"))

  # Test custom title
  map_custom <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    title = "Wandsworth Air Quality Dashboard 2024",
    output_file = "test_parameters_title_custom.html"
  )
  expect_s3_class(map_custom, "leaflet")
  expect_true(file.exists("aq_maps/test_parameters_title_custom.html"))
})

test_that("years parameter accepts NULL and vectors", {
  # NULL (all years)
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = NULL,
      output_file = "test_parameters_years_null.html"
    )
  )

  # Single year
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      output_file = "test_parameters_years_single.html"
    )
  )

  # Multiple years
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = c(2022, 2023, 2024),
      output_file = "test_parameters_years_multiple.html"
    )
  )
})

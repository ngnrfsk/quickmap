# Test image export functionality

test_that("export_image parameter works with NULL (no export)", {
  map_no_export <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    export_image = NULL,
    output_file = "test_export_none.html"
  )

  expect_s3_class(map_no_export, "leaflet")
  expect_true(file.exists("aq_maps/test_export_none.html"))
  # JPG should NOT exist
  expect_false(file.exists("aq_maps/test_export_none_2024.jpg"))
})

test_that("export_image parameter works with dimensions vector", {
  skip_if_not(webshot2::is_chromote_installed(),
              "Chromote not installed - skipping image export test")

  map_with_export <- create_pollution_map(
    diffusion_tube_file = "none",
    sensor_file = "none",
    school_file = "none",
    boroughs = "Wandsworth",
    years = 2024,
    export_image = c(800, 600),
    output_file = "test_export_small.html"
  )

  expect_s3_class(map_with_export, "leaflet")
  expect_true(file.exists("aq_maps/test_export_small.html"))
  # JPG should exist
  expect_true(file.exists("aq_maps/test_export_small_2024.jpg"))
})

test_that("export_image handles different dimensions", {
  skip_if_not(webshot2::is_chromote_installed(),
              "Chromote not installed - skipping image export test")

  # Test standard size
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      export_image = c(1200, 1200),
      output_file = "test_export_standard.html"
    )
  )

  # Test wide format
  expect_no_error(
    create_pollution_map(
      diffusion_tube_file = "none",
      sensor_file = "none",
      boroughs = "Wandsworth",
      years = 2024,
      export_image = c(1920, 1080),
      output_file = "test_export_wide.html"
    )
  )
})

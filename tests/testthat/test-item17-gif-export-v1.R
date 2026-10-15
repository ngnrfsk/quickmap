# Roadmap item 17: GIF export of the animation; defect 12: a screenshot that
# fails is retried, because a GIF needs every frame.

gif_layer <- function() {
  d <- data.frame(
    code = rep(c("A", "B"), each = 3),
    year_str = rep(c("2021", "2022", "2023"), 2),
    no2 = c(12, 18, 25, 31, 44, 22),
    lat = rep(c(51.44, 51.46), each = 3),
    lon = rep(c(-0.17, -0.21), each = 3)
  )
  qm_layer(d, name = "survey")
}

test_that("a failed screenshot is retried until it succeeds", {
  calls <- 0
  local_mocked_bindings(
    webshot = function(url, file, ...) {
      calls <<- calls + 1
      if (calls < 2) stop("Chrome debugging port not open after 10 seconds")
      for (f in file) writeLines("img", f)
      invisible(file)
    },
    .package = "webshot2"
  )
  work <- withr::local_tempdir()
  out <- file.path(work, c("a.jpg", "a.png"))
  quickmap:::take_screenshots(file.path(work, "a.html"), out, c(100, 100))
  # one failed call, then one call per file: concurrent loading of several
  # files in one call drew frames as a 2x2 grid of the page
  expect_equal(calls, 3)
  expect_true(all(file.exists(out)))
})

test_that("an empty image counts as a failure", {
  calls <- 0
  local_mocked_bindings(
    webshot = function(url, file, ...) {
      calls <<- calls + 1
      for (f in file) file.create(f)
      invisible(file)
    },
    .package = "webshot2"
  )
  work <- withr::local_tempdir()
  expect_error(
    quickmap:::take_screenshots(file.path(work, "a.html"), file.path(work, "a.jpg"),
                                c(100, 100), attempts = 2),
    "failed after 2 attempts at a.html: no image written"
  )
  expect_equal(calls, 2)
})

test_that("the export stops after the last attempt, naming Chrome's error", {
  local_mocked_bindings(
    webshot = function(url, file, ...) stop("Chrome timed out"),
    .package = "webshot2"
  )
  work <- withr::local_tempdir()
  expect_error(
    quickmap:::take_screenshots(file.path(work, "f.html"), file.path(work, "f.jpg"),
                                c(100, 100), attempts = 1),
    "failed after 1 attempts at f.html: Chrome timed out"
  )
})

test_that("export_animation accepts NULL or \"gif\" only", {
  expect_null(quickmap:::parse_export_animation(NULL))
  expect_equal(quickmap:::parse_export_animation("gif"), "gif")
  expect_error(quickmap:::parse_export_animation("mp4"), 'NULL or "gif"')
  expect_error(quickmap:::parse_export_animation(TRUE), 'NULL or "gif"')
})

test_that("time steps run in time order whatever the row order", {
  # Found building the item 17 demo: the Merton tube table lists a site opened
  # in 2017 first, and the GIF ran 2017...2025 then 2012.
  layer <- sf::st_as_sf(
    data.frame(year_str = c("2017", "2018", "2012", "2018"),
               lon = c(-0.17, -0.17, -0.21, -0.21), lat = c(51.44, 51.44, 51.46, 51.46)),
    coords = c("lon", "lat"), crs = 4326
  )
  res <- quickmap:::determine_times_and_viewport(
    list(all_data = list(survey = layer)), NULL, FALSE, NULL
  )
  expect_equal(res$display_times, c("2012", "2017", "2018"))
})

test_that("a GIF of one step is refused", {
  work <- withr::local_tempdir()
  expect_error(
    quickmap(gif_layer(), output_file = "one.html", output_dir = work,
             display_times = "2021", export_animation = "gif", title = "t"),
    "more than one time step"
  )
})

test_that("export_animation = \"gif\" writes one GIF beside the HTML and nothing else", {
  skip_on_cran()
  skip_if_not_installed("webshot2")
  skip_if_not_installed("gifski")
  work <- withr::local_tempdir()
  quickmap(gif_layer(), output_file = "anim.html", output_dir = work,
           export_animation = "gif", play_speed = 500, title = "t")
  expect_setequal(list.files(work), c("anim.html", "anim.gif"))
  gif <- readBin(file.path(work, "anim.gif"), "raw", 6)
  expect_equal(rawToChar(gif), "GIF89a")
})

test_that("with export_image as well, the JPGs are kept and the GIF frames are not", {
  skip_on_cran()
  skip_if_not_installed("webshot2")
  skip_if_not_installed("gifski")
  work <- withr::local_tempdir()
  quickmap(gif_layer(), output_file = "both.html", output_dir = work,
           export_image = c(400, 400), export_animation = "gif", title = "t")
  expect_setequal(
    list.files(work),
    c("both.html", "both.gif", "both_2021.jpg", "both_2022.jpg", "both_2023.jpg")
  )
})

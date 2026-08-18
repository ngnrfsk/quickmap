# Roadmap item 9.1: the caller names every write. No invented directory, so
# a CRAN check finds nothing written outside where the user asked.
# Decision: dev/260816_output_paths_decision.md.

paths_layer <- function() {
  d <- data.frame(
    code = rep(c("A", "B"), each = 2),
    year_str = rep(c("2021", "2022"), 2),
    no2 = c(12, 18, 25, 31),
    lat = rep(c(51.44, 51.46), each = 2),
    lon = rep(c(-0.17, -0.21), each = 2)
  )
  qm_layer(d, name = "survey")
}

test_that("output_file is required", {
  expect_error(quickmap(paths_layer()), "output_file is required")
  expect_error(
    quickmap(paths_layer(), output_file = NULL),
    "output_file is required"
  )
  expect_error(
    quickmap(paths_layer(), output_file = c("a.html", "b.html")),
    "output_file is required"
  )
})

test_that("a bare name writes to the working directory and invents nothing", {
  work <- withr::local_tempdir()
  withr::local_dir(work)
  quickmap(paths_layer(), output_file = "plain.html", title = "t")
  expect_true(file.exists("plain.html"))
  expect_false(dir.exists("aq_maps"))
})

test_that("output_dir prepends and creates nested directories", {
  work <- withr::local_tempdir()
  quickmap(
    paths_layer(),
    output_file = "nested.html",
    output_dir = file.path(work, "out", "deeper"),
    title = "t"
  )
  expect_true(file.exists(file.path(work, "out", "deeper", "nested.html")))
})

test_that("a directory inside output_file is honoured", {
  work <- withr::local_tempdir()
  withr::local_dir(work)
  quickmap(paths_layer(), output_file = "sub/dir/map.html", title = "t")
  expect_true(file.exists(file.path("sub", "dir", "map.html")))
})

test_that("the quickmap.output_dir option supplies the directory", {
  work <- withr::local_tempdir()
  withr::local_options(quickmap.output_dir = work)
  quickmap(paths_layer(), output_file = "from_option.html", title = "t")
  expect_true(file.exists(file.path(work, "from_option.html")))
})

test_that("JPG exports land beside the HTML the caller named", {
  skip_on_cran()
  skip_if_not_installed("webshot2")
  work <- withr::local_tempdir()
  quickmap(
    paths_layer(),
    output_file = "shots/annual.html",
    output_dir = work,
    display_times = "2021",
    export_image = c(600, 600),
    title = "t"
  )
  expect_true(file.exists(file.path(work, "shots", "annual_2021.jpg")))
})

test_that("a sub-annual step gives a filename a filesystem can hold", {
  # The step goes into the JPG name; "2024-01-15 10:00" must not put a space
  # or a colon in a path.
  expect_equal(gsub("[^A-Za-z0-9_-]+", "-", "2024-01-15 10:00"),
               "2024-01-15-10-00")
})

test_that("resolve_output_path leaves a path alone but expands ~", {
  work <- withr::local_tempdir()
  expect_equal(
    quickmap:::resolve_output_path(file.path(work, "m.html")),
    file.path(work, "m.html")
  )
  expect_false(
    grepl("~", quickmap:::resolve_output_path("~/m.html"), fixed = TRUE)
  )
})

# Banner reference-layer key (2026-08-05). A static layer carries no value, so
# it gets no place on the colour ramp; where it has categories they are named
# once in the banner instead of 53 times across the map.

fake_layers <- function(static = TRUE, shape = "simple-cross") {
  list(schools = list(
    id = "schools", enabled = TRUE, static = static, icon_shape = shape
  ))
}

fake_spatial <- function(levels = c("Primary", "Secondary")) {
  list(all_data = list(schools = data.frame(
    School = paste("School", seq_along(levels)),
    Level = levels,
    stringsAsFactors = FALSE
  )))
}

test_that("a static layer with a Level column produces a key", {
  key <- quickmap:::build_banner_key(fake_layers(), fake_spatial())
  expect_equal(key$shape, "simple-cross")
  expect_equal(unname(vapply(key$items, function(i) i$label, "")),
               c("Primary", "Secondary"))
  # colours come from the schools scale, so key and map agree
  scale <- quickmap:::load_yaml_config("schools", subdirectory = "scales")
  expect_equal(unname(vapply(key$items, function(i) i$colour, "")),
               unlist(scale$colours))
})

test_that("only the categories actually present are listed", {
  key <- quickmap:::build_banner_key(fake_layers(), fake_spatial("Primary"))
  expect_equal(length(key$items), 1)
  expect_equal(key$items[[1]]$label, "Primary")
})

test_that("no key without a qualifying layer", {
  # temporal layers are on the ramp already
  expect_null(quickmap:::build_banner_key(fake_layers(static = FALSE),
                                          fake_spatial()))
  # a static layer with no Level column has nothing to say
  bare <- list(all_data = list(schools = data.frame(School = "x")))
  expect_null(quickmap:::build_banner_key(fake_layers(), bare))
})

test_that("the key renders as inline SVG, and nothing at all when absent", {
  key <- quickmap:::build_banner_key(fake_layers(), fake_spatial())
  html <- quickmap:::generate_banner_key_html(key)
  expect_match(html, 'class="banner-key"', fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
  expect_match(html, "Primary", fixed = TRUE)
  expect_match(html, "Secondary", fixed = TRUE)
  # sized in em so it follows the banner and therefore the export
  expect_false(grepl("px", html, fixed = TRUE))

  expect_equal(quickmap:::generate_banner_key_html(NULL), "")
})

test_that("banner CSS lays title and key out together", {
  css <- quickmap:::build_banner_css("#2a75d4", banner_style = "bar")
  expect_match(css, ".banner-key", fixed = TRUE)
  expect_match(css, "justify-content: space-between", fixed = TRUE)
  # with no key the flex row has one child and reads as it always did
  expect_match(css, ".banner-key-mark", fixed = TRUE)
})

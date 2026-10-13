# Roadmap item 9.8: quickmap:::shorten_school_names() brought into the package from the
# LB Merton AQAP print script (2026-08-05), where it lived as shorten_school().
# The rule that matters is the collision guard: a label must not stand for two
# schools that the reader cannot tell apart.

test_that("the school type is dropped", {
  expect_equal(
    quickmap:::shorten_school_names(c("Abbotsbury Primary School",
                           "Aragon Primary School",
                           "Ursuline Secondary School")),
    c("Abbotsbury", "Aragon", "Ursuline")
  )
})

test_that("a trailing Academy or College goes too", {
  expect_equal(
    quickmap:::shorten_school_names(c("Wimbledon College",
                           "Harris Academy",
                           "St Mark's Community College")),
    c("Wimbledon", "Harris", "St Mark's")
  )
})

test_that("names that would collide keep their full form", {
  full <- c("Harris Primary Academy Merton", "Harris Academy Merton")
  # same Level: the reader has nothing left to tell them apart
  expect_equal(quickmap:::shorten_school_names(full, c("Primary", "Primary")), full)
})

test_that("a shared short name survives when the cross colour separates it", {
  full <- c("Harris Primary Academy Merton", "Harris Academy Merton")
  short <- quickmap:::shorten_school_names(full, c("Primary", "Secondary"))
  expect_equal(short, c("Harris Academy Merton", "Harris Academy Merton"))
})

test_that("with no Level given, any collision reverts", {
  full <- c("Harris Primary Academy Merton", "Harris Academy Merton")
  expect_equal(quickmap:::shorten_school_names(full), full)
})

test_that("a name that is nothing but its type is left alone", {
  expect_equal(quickmap:::shorten_school_names("Primary School"), "Primary School")
})

test_that("qm_layer shortens the label column, not the marker identity", {
  d <- data.frame(
    School = c("Abbotsbury Primary School", "Aragon Primary School"),
    Level = c("Primary", "Primary"),
    code = c("Abbotsbury Primary School", "Aragon Primary School"),
    lat = c(51.40, 51.41),
    lon = c(-0.19, -0.20)
  )
  lay <- qm_layer(d, value_col = "Level", shorten_labels = TRUE)
  expect_equal(lay$School, c("Abbotsbury", "Aragon"))
  expect_equal(as.character(lay$code), d$code)
})

test_that("the default leaves names untouched", {
  d <- data.frame(
    School = "Abbotsbury Primary School", Level = "Primary",
    code = "a", lat = 51.4, lon = -0.19
  )
  expect_equal(qm_layer(d, value_col = "Level")$School,
               "Abbotsbury Primary School")
})

test_that("asking to shorten a layer with no labels warns", {
  d <- data.frame(code = c("a", "b"), no2 = c(20, 30),
                  lat = c(51.4, 51.41), lon = c(-0.19, -0.2))
  expect_warning(qm_layer(d, shorten_labels = TRUE), "no label column")
})

test_that("from_csv passes the option through", {
  skip_if_not(char_data_available(), "DATA_PATH fixtures absent")
  f <- file.path(Sys.getenv("DATA_PATH"), "schools_Merton.csv")
  raw <- utils::read.csv(f, check.names = FALSE)
  lay <- from_csv(f, name = "schools", shorten_labels = TRUE)
  expect_equal(sum(lay$School != raw$School), 47)
  expect_equal(max(nchar(lay$School)), 32)
  expect_equal(as.character(lay$code), as.character(raw$School))
})

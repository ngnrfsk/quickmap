# Animation speed control (2026-08-05): the playback multiplier button, the
# step-count-based default pace, and the proportional colour crossfade.
#
# The browser block at the bottom drives the real control in headless Chrome.
# The pure-R tests above it cover what can be settled without one.

test_that("default_play_speed follows the step count", {
  expect_equal(quickmap:::default_play_speed(7), 1200)
  expect_equal(quickmap:::default_play_speed(30), 800)
  expect_equal(quickmap:::default_play_speed(108), 450)

  # the boundaries, which is where an off-by-one would hide
  expect_equal(quickmap:::default_play_speed(1), 1200)
  expect_equal(quickmap:::default_play_speed(12), 1200)
  expect_equal(quickmap:::default_play_speed(13), 800)
  expect_equal(quickmap:::default_play_speed(60), 800)
  expect_equal(quickmap:::default_play_speed(61), 450)
})

test_that("the default theme names no play_speed, so the step count decides", {
  expect_null(quickmap:::get_default_theme()$controls$play_speed)

  # the shipped themes that merely echoed the old 500ms constant were cleared
  # so they inherit the step-count default; wandsworth's 1000 was deliberate
  for (nm in c("merton", "richmond", "high_contrast", "airstat")) {
    theme <- quickmap:::load_theme(
      system.file("themes", paste0(nm, ".yaml"), package = "quickmap")
    )
    expect_null(theme$controls$play_speed, info = nm)
  }
  wandsworth <- quickmap:::load_theme(
    system.file("themes", "wandsworth.yaml", package = "quickmap")
  )
  expect_equal(wandsworth$controls$play_speed, 1000)
})

test_that("the speed button is in the interactive card and not in an export", {
  control <- quickmap:::load_time_slider_control("#005794", FALSE, 1200)
  expect_match(control, 'id="speedButton"', fixed = TRUE)
  expect_match(control, "playSpeed: 1200", fixed = TRUE)
  expect_match(control, ".speed-button", fixed = TRUE)
  expect_false(grepl("{{", control, fixed = TRUE))

  # a static export has no controls at all — only a label pill
  image <- quickmap:::load_time_slider_control(
    "#005794", FALSE, 1200, image_mode = TRUE, display_times = 2024
  )
  expect_false(grepl("speedButton", image, fixed = TRUE))
  expect_false(grepl("<script", image, fixed = TRUE))
  expect_match(image, "2024", fixed = TRUE)
})

test_that("both timers take their interval from one place", {
  js <- readLines(
    system.file("controls", "time-slider.js", package = "quickmap"),
    warn = FALSE
  )
  # The trap: two setInterval sites (play, and resuming after the tab was
  # hidden). Both must go through startTimer(), or a speed change applies on
  # play and not on resume.
  expect_equal(sum(grepl("setInterval", js)), 1)
  expect_equal(sum(grepl("startTimer\\(\\);", js)), 3) # 2 call sites + renderSpeed
  expect_false(any(grepl("}, config.playSpeed)", js, fixed = TRUE)))
  expect_true(any(grepl("window.quickmapPlayInterval = currentInterval()", js,
                        fixed = TRUE)))
})

test_that("the crossfade is proportional to the interval and capped", {
  js <- paste(readLines(
    system.file("controls", "lazy-time-controller.js", package = "quickmap"),
    warn = FALSE
  ), collapse = "\n")
  expect_match(js, "FADE_MAX_MS = 250", fixed = TRUE)
  expect_match(js, "FADE_FRACTION = 0.4", fixed = TRUE)
  expect_match(js, "Math.min(FADE_MAX_MS, interval * FADE_FRACTION)", fixed = TRUE)
  # the fixed 250ms is gone
  expect_false(grepl("FADE_MS = 250", js, fixed = TRUE))
})

test_that("a rendered map carries the step-count pace, unless told otherwise", {
  skip_if_not(char_data_available(), "characterization data not available")

  # char_annual: 3 steps, no play_speed given -> the <= 12 default
  expect_match(char_html("char_annual.html"), "playSpeed: 1200", fixed = TRUE)
  # char_episode: play_speed = 500 passed explicitly -> the argument wins
  expect_match(char_html("char_episode.html"), "playSpeed: 500", fixed = TRUE)
})

test_that("the control behaves in a browser", {
  skip_on_cran()
  skip_if_not_installed("chromote")
  skip_if_not(char_data_available(), "characterization data not available")

  path <- file.path(char_map_dir(), "char_annual.html")
  b <- chromote::ChromoteSession$new(width = 1200, height = 900)
  on.exit(try(b$close(), silent = TRUE), add = TRUE)
  loaded <- b$Page$loadEventFired(wait_ = FALSE)
  b$Page$navigate(paste0("file://", normalizePath(path)))
  b$wait_for(loaded)
  Sys.sleep(3)

  ev <- function(expr) {
    r <- b$Runtime$evaluate(expr, returnByValue = TRUE)
    if (!is.null(r$exceptionDetails)) stop(r$exceptionDetails$text)
    r$result$value
  }
  label <- function() ev("document.getElementById('speedButton').textContent")
  press <- function() ev("document.getElementById('speedButton').click()")

  # opens at 1x on the theme's pace
  expect_equal(label(), "1×")
  expect_equal(ev("window.quickmapPlayInterval"), 1200)
  expect_match(
    ev("document.getElementById('speedButton').getAttribute('aria-label')"),
    "Playback speed 1×"
  )

  # cycles and wraps, and the interval is the theme speed over the multiplier
  expected <- list(
    c("2×", 600), c("4×", 300), c("8×", 150),
    c("0.25×", 4800), c("0.5×", 2400), c("1×", 1200)
  )
  for (step in expected) {
    press()
    expect_equal(label(), step[[1]])
    expect_equal(ev("window.quickmapPlayInterval"), as.numeric(step[[2]]))
  }

  # Enter and Space work like a press
  for (k in c("Enter", " ")) {
    ev(sprintf(
      "document.getElementById('speedButton').dispatchEvent(
         new KeyboardEvent('keydown',{key:'%s',bubbles:true}))", k))
  }
  expect_equal(label(), "4×")

  # hidden on a phone, while the rest of the card stays
  b$Emulation$setDeviceMetricsOverride(
    width = 390, height = 844, deviceScaleFactor = 0, mobile = FALSE
  )
  Sys.sleep(1)
  expect_equal(
    ev("getComputedStyle(document.getElementById('speedButton')).display"),
    "none"
  )
  expect_equal(
    ev("getComputedStyle(document.getElementById('playPauseButton')).display"),
    "flex"
  )
})

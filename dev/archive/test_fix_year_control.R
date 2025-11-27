# Test: Year control fix for image mode
# Verifies that year control properly displays year text in static exports

source("R/quickmap_clean.R")

cat("Test 1: Interactive mode - includes play button and dropdown arrow...\n")
html_interactive <- load_roller_menu_control(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500,
  image_mode = FALSE,
  years = "2024"
)
stopifnot(grepl("playPauseButton", html_interactive))
stopifnot(grepl("arrow", html_interactive))
stopifnot(grepl('<span id="selectedYear"></span>', html_interactive, fixed = TRUE))
cat("✓ Pass\n\n")

cat("Test 2: Image mode - removes play button and dropdown arrow...\n")
html_image <- load_roller_menu_control(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500,
  image_mode = TRUE,
  years = "2024"
)
stopifnot(!grepl("playPauseButton", html_image))
stopifnot(!grepl("arrow", html_image))
stopifnot(grepl('<span id="selectedYear">2024</span>', html_image, fixed = TRUE))
cat("✓ Pass\n\n")

cat("Test 3: Image mode with NULL years - no year text...\n")
html_no_year <- load_roller_menu_control(
  banner_colour = "#2c3e50",
  autoplay = FALSE,
  play_speed = 500,
  image_mode = TRUE,
  years = NULL
)
stopifnot(!grepl("playPauseButton", html_no_year))
stopifnot(!grepl("arrow", html_no_year))
stopifnot(grepl('<span id="selectedYear"></span>', html_no_year, fixed = TRUE))
cat("✓ Pass\n\n")

cat("All year control fix tests passed! ✓\n")

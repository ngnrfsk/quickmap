# QuickMap's own credit (2026-08-15): the software slot of the attribution
# control, plus source metadata. Neither touches the tile provider's credit
# or a data licence line.

test_that("the credit goes in the prefix, naming QuickMap and Leaflet", {
  expect_match(quickmap:::QM_CREDIT_PREFIX, "QuickMap", fixed = TRUE)
  expect_match(quickmap:::QM_CREDIT_PREFIX, "leafletjs.com", fixed = TRUE)
  expect_match(quickmap:::QM_CREDIT_PREFIX,
               "github.com/ngnrfsk/quickmap", fixed = TRUE)
  # no version on screen: the version lives in the source metadata
  expect_false(grepl("[0-9]\\.[0-9]", quickmap:::QM_CREDIT_PREFIX))
})

test_that("the base map carries the credit unless the theme drops it", {
  pts <- sf::st_as_sf(
    data.frame(lat = c(51.4, 51.5), lon = c(-0.2, -0.1)),
    coords = c("lon", "lat"), crs = 4326
  )
  with_credit <- quickmap:::create_base_map(pts, TRUE, NULL, TRUE)
  without <- quickmap:::create_base_map(pts, TRUE, NULL, FALSE)

  has_prefix <- function(map) {
    any(grepl("setPrefix", unlist(map$jsHooks), fixed = TRUE))
  }
  expect_true(has_prefix(with_credit))
  expect_false(has_prefix(without))

  # the tile layer is added either way, keeping its own attribution
  tile_calls <- function(map) {
    vapply(map$x$calls, function(c) c$method, "")
  }
  expect_true("addTiles" %in% tile_calls(with_credit))
  expect_true("addTiles" %in% tile_calls(without))
})

test_that("map.credit defaults to TRUE in the theme", {
  expect_true(quickmap:::get_default_theme()$map$credit)
})

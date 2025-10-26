library(sf)

# Test vignette calculation
# Simulate a borough bbox
test_bbox <- st_bbox(c(xmin = -0.3, ymin = 51.4, xmax = -0.1, ymax = 51.5), crs = 4326)
test_polygon <- st_as_sfc(test_bbox)

cat("Original bbox:\n")
print(test_bbox)

# Test with 1.5 multiplier
width <- test_bbox["xmax"] - test_bbox["xmin"]
height <- test_bbox["ymax"] - test_bbox["ymin"]

cat("\nWidth:", width, "\n")
cat("Height:", height, "\n")

extended_bbox_1.5 <- c(
  test_bbox["xmin"] - 1.5 * width,
  test_bbox["ymin"] - 1.5 * height,
  test_bbox["xmax"] + 1.5 * width,
  test_bbox["ymax"] + 1.5 * height
)

cat("\nExtended bbox (1.5x):\n")
print(extended_bbox_1.5)

# Test with 3.0 multiplier
extended_bbox_3.0 <- c(
  test_bbox["xmin"] - 3.0 * width,
  test_bbox["ymin"] - 3.0 * height,
  test_bbox["xmax"] + 3.0 * width,
  test_bbox["ymax"] + 3.0 * height
)

cat("\nExtended bbox (3.0x):\n")
print(extended_bbox_3.0)

cat("\nDifference in xmin:\n")
cat("  1.5x:", extended_bbox_1.5[1], "\n")
cat("  3.0x:", extended_bbox_3.0[1], "\n")
cat("  Delta:", extended_bbox_3.0[1] - extended_bbox_1.5[1], "\n")

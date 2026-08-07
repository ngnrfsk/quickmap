# Demonstrate the measured collision rule.
#
# Merton's own network never triggers it — with 59 sites the worst reading sits
# far above the mean. This fixture is a handful of sites with near-identical
# readings, which is the case the rule exists for: a uniform network, where the
# mean and the maximum land almost on top of each other.
library(quickmap)
setwd("/Users/iarla/Coding/quickmap")

src <- read.csv("aq_maps/prepared/merton_no2_2019_2025.csv", check.names = FALSE)

# four neighbouring sites, readings nudged to within a couple of µg/m³
tight <- src[1:4, ]
tight[["2019"]] <- c(41, 42.5, 43, 43.5)
tight[["2020"]] <- c(38, 39, 39.5, 40)
tight <- tight[, c("ID", "Label", "Easting", "Northing", "2019", "2020")]

prepared <- file.path(getwd(), "aq_maps/prepared/collision_fixture.csv")
write.csv(tight, prepared, row.names = FALSE)

theme <- tempfile(fileext = ".yaml")
writeLines(c("indicator:", "  show_max: true"), theme)

quickmap(
  prepared,
  boroughs = "Merton",
  display_times = c("2019", "2020"),
  colour_scale = "lbm_no2",
  theme_file = theme,
  title = "Collision rule — mean and maximum nearly equal",
  output_file = "indicator_collision_v1.html"
)

# the same page at a phone width and at a desktop width
for (w in c(390, 1400)) {
  webshot2::webshot(
    "aq_maps/indicator_collision_v1.html",
    sprintf("aq_maps/indicator_collision_%d.png", w),
    vwidth = w, vheight = if (w == 390) 844 else 900, delay = 2
  )
}

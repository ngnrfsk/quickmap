library(quickmap)
setwd("/Users/iarla/Coding/quickmap")
prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
theme <- tempfile(fileext = ".yaml")
writeLines(c("banner:", '  background: "#5F3E94"',
             "indicator:", "  show_max: true"), theme)

# print export, to check the year label and the smaller figures
quickmap(
  prepared, boroughs = "Merton", display_times = "2019",
  colour_scale = "lbm_no2", theme_file = theme,
  title = "Merton NO₂ annual mean",
  export_image = c(4000, 3000),
  output_file = "indicator_titlerow-print_v5.html"
)

# and a smaller export, to prove the year scales with the image
quickmap(
  prepared, boroughs = "Merton", display_times = "2019",
  colour_scale = "lbm_no2", theme_file = theme,
  title = "Merton NO₂ annual mean",
  export_image = c(1000, 750),
  output_file = "indicator_titlerow-print-small_v5.html"
)

# interactive, for the desktop and phone layouts
quickmap(
  prepared, boroughs = "Merton", display_times = as.character(2019:2025),
  colour_scale = "lbm_no2", theme_file = theme,
  title = "Merton NO₂ annual mean 2019–2025",
  autoplay = TRUE, play_speed = 1400,
  output_file = "indicator_titlerow_v5.html"
)
for (w in c(390, 820, 1400)) {
  webshot2::webshot("aq_maps/indicator_titlerow_v5.html",
                    sprintf("aq_maps/indicator_titlerow_%d.png", w),
                    vwidth = w, vheight = if (w == 390) 780 else 900, delay = 2)
}

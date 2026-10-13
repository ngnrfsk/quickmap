dir <- "/Users/iarla/Coding/quickmap/dev/archviz_v1"
svgs <- list.files(file.path(dir, "svg"), pattern = "\\.svg$", full.names = TRUE)
for (f in svgs) {
  png <- file.path(dir, "png", sub("\\.svg$", ".png", basename(f)))
  rsvg::rsvg_png(f, png, width = 2560, height = 1440)
}

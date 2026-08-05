src <- "/Users/iarla/Coding/quickmap/aq_maps/indicator_titlerow_v5.html"
for (w in c(1400, 1100, 900, 760, 620, 500, 390)) {
  webshot2::webshot(
    src,
    sprintf("/Users/iarla/Coding/quickmap/aq_maps/sweep_%d.png", w),
    vwidth = w, vheight = 720, delay = 2
  )
}
cat("done\n")

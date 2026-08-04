# The same page down a ladder of widths, to see how the legend gives up space
src <- "/Users/iarla/Coding/quickmap/aq_maps/indicator_titlerow_v5.html"
for (w in c(1400, 1000, 760, 560)) {
  webshot2::webshot(
    src,
    sprintf("/Users/iarla/Coding/quickmap/aq_maps/ladder_%d.png", w),
    vwidth = w, vheight = 820, delay = 2
  )
}
cat("done\n")

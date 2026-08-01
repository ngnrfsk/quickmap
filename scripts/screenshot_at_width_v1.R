# Screenshot an interactive map at phone dimensions.
#
# This is NOT the same as export_image = c(390, 844): that scales the chrome
# down by the geometric mean, which is right for a small IMAGE but wrong for
# the case we care about. A phone shows the ordinary interactive page in a
# narrow viewport, at normal font size, with the mobile media queries active.
# Screenshotting the saved interactive HTML at a phone viewport reproduces
# that exactly.
args <- commandArgs(trailingOnly = TRUE)
src <- args[1]
out <- args[2]
w <- as.numeric(args[3])
h <- as.numeric(args[4])

webshot2::webshot(src, out, vwidth = w, vheight = h, delay = 2)
cat("wrote", out, "\n")

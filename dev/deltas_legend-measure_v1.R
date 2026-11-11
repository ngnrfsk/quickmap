# Measure whether legend ramp labels fit their blocks, every bundled scale,
# both legend CSS variants, at 1200 and 600 px (dev/261111_deltas_issue.md).
#   Rscript dev/deltas_legend-measure_v1.R <repo root> <empty output dir>
# Prints one row per scale/variant/width; writes each page and a PNG of it.
# Pass: labels_wider_than_block = 0 and page_scroll = viewport everywhere.
args <- commandArgs(trailingOnly = TRUE)
pkg <- args[1]
out_dir <- args[2]
suppressMessages(devtools::load_all(pkg, quiet = TRUE))

scales <- sub("\\.yaml$", "", list.files(file.path(pkg, "inst/config/scales"), pattern = "\\.yaml$"))
b <- chromote::ChromoteSession$new(width = 1200, height = 1200)

js <- "(() => {
  const items = [...document.querySelectorAll('.ramp-label')];
  const blocks = [...document.querySelectorAll('.ramp-block')];
  const wider = items.filter((e, i) => blocks[i] &&
    e.getBoundingClientRect().width > blocks[i].getBoundingClientRect().width + 0.5).length;
  const right = Math.max(...items.map(e => e.getBoundingClientRect().right));
  return JSON.stringify({
    n_labels: items.length,
    labels_wider_than_block: wider,
    labels_right_edge: Math.round(right),
    viewport: window.innerWidth,
    page_scroll: document.documentElement.scrollWidth
  });
})()"

res <- list()
for (w in c(1200, 600)) {
  b$Emulation$setDeviceMetricsOverride(width = w, height = 1200,
                                       deviceScaleFactor = 1, mobile = FALSE)
  for (s in scales) {
    for (mode in c(TRUE, FALSE)) {
      css <- build_legend_css(image_mode = mode)
      html <- generate_legend_html(s, collapsed_mobile = FALSE)
      page <- paste0("<!doctype html><html><head><meta charset='utf-8'><style>", css,
                     "</style></head><body>", html, "</body></html>")
      f <- file.path(out_dir, paste0(s, if (mode) "_image" else "_interactive", "_", w, ".html"))
      writeLines(page, f, useBytes = TRUE)
      b$Page$navigate(paste0("file://", f))
      Sys.sleep(0.4)
      r <- jsonlite::fromJSON(b$Runtime$evaluate(js)$result$value)
      res[[length(res) + 1]] <- data.frame(scale = s, image_mode = mode, r)
      b$screenshot(sub("\\.html$", ".png", f), show = FALSE)
    }
  }
}
print(do.call(rbind, res), row.names = FALSE)

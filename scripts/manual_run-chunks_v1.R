# Manual chunk harness (prospectus §7): extract every code chunk from the
# manual vignettes and run it against DATA_PATH, so the eval=FALSE chunks in
# the built pages are proven runnable. Chunks labelled "net-*" need a network
# (OpenAir/NOAA fetches): a failure there is reported as a skip, not an
# error (prospectus §2a). Chunks marked purl=FALSE (install, DATA_PATH
# setup) are never extracted.
# Run from the repo root: Rscript scripts/manual_run-chunks_v1.R
library(quickmap)

run_vignette_chunks <- function(rmd) {
  tmp <- tempfile(fileext = ".R")
  knitr::purl(rmd, output = tmp, documentation = 1L, quiet = TRUE)
  lines <- readLines(tmp)

  starts <- grep("^## ----", lines)
  bounds <- c(starts, length(lines) + 1L)
  env <- new.env(parent = globalenv())
  failures <- 0L

  for (i in seq_along(starts)) {
    header <- lines[starts[i]]
    label <- gsub("^## ----|[-,= ].*$", "", header)
    code <- lines[(starts[i] + 1L):(bounds[i + 1L] - 1L)]
    net <- startsWith(label, "net")

    result <- tryCatch({
      eval(parse(text = code), envir = env)
      "ok"
    }, error = function(e) conditionMessage(e))

    if (identical(result, "ok")) {
      cat(sprintf("  ok    %s\n", label))
    } else if (net) {
      cat(sprintf("  SKIP  %s (network chunk failed: %s)\n", label, result))
    } else {
      cat(sprintf("  FAIL  %s: %s\n", label, result))
      failures <- failures + 1L
    }
  }
  failures
}

rmds <- list.files("vignettes", pattern = "\\.Rmd$", full.names = TRUE)
total <- 0L
for (rmd in rmds) {
  cat(rmd, "\n")
  total <- total + run_vignette_chunks(rmd)
}
cat("\nchunk harness:", if (total == 0L) "ALL OK" else paste(total, "FAILURES"), "\n")
if (total > 0L) stop("manual chunk harness failed")

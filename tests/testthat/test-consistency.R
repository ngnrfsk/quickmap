# Mechanical internal-consistency checks: CLAUDE.md vs the actual project.
# Dependency-free (no quickmap load) so these stay green regardless of the
# known-red baseline. Full consistency is a v1.0 goal; these catch the cheap,
# objective staleness classes automatically.

find_root <- function() {
  for (cand in c(".", "..", "../..")) {
    if (file.exists(file.path(cand, "CLAUDE.md")) &&
        file.exists(file.path(cand, "DESCRIPTION"))) {
      return(normalizePath(cand))
    }
  }
  stop("project root not found")
}
root <- find_root()
claude_md <- readLines(file.path(root, "CLAUDE.md"), warn = FALSE)
claude_text <- paste(claude_md, collapse = "\n")

# Functions named in the roadmap that are designed but not yet implemented
planned_functions <- c(
  "quickmap", "from_csv", "from_rdata", "from_openair", "from_worldmet",
  "from_yaml",
  # roadmap item 12: written, but on feature/breathe-london-fetch (PR #51)
  "bl_sensors", "bl_data", "from_breathelondon", "bl_request"
)

# Functions cited from other packages (not expected in R/quickmap.R or base R)
external_functions <- c("aes")

test_that("DESCRIPTION Version matches the version PROJECT_STATUS states", {
  # The version moved out of CLAUDE.md on 2026-08-16: DESCRIPTION is
  # authoritative, PROJECT_STATUS states it in prose for the reader, and
  # those two are what must agree.
  desc_version <- read.dcf(file.path(root, "DESCRIPTION"))[1, "Version"]
  status <- readLines(file.path(root, "dev/PROJECT_STATUS.md"), warn = FALSE)
  heading <- grep("\\*\\*Current Version\\*\\*:", status, value = TRUE)
  expect_length(heading, 1)
  stated <- sub(".*\\*\\*Current Version\\*\\*:\\s*v?([0-9.]+).*", "\\1",
                heading)
  expect_identical(unname(desc_version), stated)
})

test_that("file paths referenced in CLAUDE.md exist", {
  spans <- regmatches(claude_text, gregexpr("`[^`\n]+`", claude_text))[[1]]
  spans <- gsub("`", "", spans)
  known_prefix <- "^(R|dev|tests|inst|versions|scripts|vignettes|\\.claude)/"
  paths <- unique(grep(known_prefix, spans, value = TRUE))
  # keep plain paths only: no code, globs, or brace expansions
  paths <- paths[!grepl("[ ({}*\"']", paths)]
  missing <- paths[!file.exists(file.path(root, paths))]
  expect_identical(missing, character(0))
})

test_that("functions cited as existing in CLAUDE.md are defined", {
  cited <- regmatches(
    claude_text,
    gregexpr("`[A-Za-z_][A-Za-z0-9_.]*\\(\\)`", claude_text)
  )[[1]]
  cited <- unique(sub("`([A-Za-z_][A-Za-z0-9_.]*)\\(\\)`", "\\1", cited))
  cited <- setdiff(cited, c(planned_functions, external_functions))

  source_code <- paste(
    unlist(lapply(
      list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE),
      readLines, warn = FALSE
    )),
    collapse = "\n"
  )
  defined_in_pkg <- vapply(
    cited,
    function(f) grepl(paste0(f, " <- function"), source_code, fixed = TRUE),
    logical(1)
  )
  in_base_r <- vapply(
    cited,
    function(f) exists(f, mode = "function"),
    logical(1)
  )
  unknown <- cited[!(defined_in_pkg | in_base_r)]
  expect_identical(unknown, character(0))
})

test_that("YAML configs named in CLAUDE.md exist in inst/", {
  yamls <- regmatches(claude_text, gregexpr("`[a-z0-9_]+\\.yaml`", claude_text))[[1]]
  yamls <- unique(gsub("`", "", yamls))
  found <- vapply(
    yamls,
    function(y) {
      file.exists(file.path(root, "inst", "config", "scales", y)) ||
        file.exists(file.path(root, "inst", "themes", y)) ||
        file.exists(file.path(root, "inst", "config", y))
    },
    logical(1)
  )
  expect_identical(yamls[!found], character(0))
})

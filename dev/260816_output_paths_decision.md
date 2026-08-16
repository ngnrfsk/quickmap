# Output paths and the file API — decision, 2026-08-16

Roadmap item 9 (CRAN compliance). Blocks release.

## The problem

`render_pollution_map()` creates `aq_maps/` in the working directory and
writes every map into it:

- `R/quickmap.R` — `if (!dir.exists("aq_maps")) dir.create("aq_maps", ...)`
- `R/quickmap.R` — `html_file <- file.path("aq_maps", output_file)`
- `R/quickmap.R` — the same prefix for each static JPG

CRAN policy: a package may not write anywhere on the file system except
the session temporary directory, unless the user specified the location.
Inventing `aq_maps/` is the violation, not the folder itself.

## The decision

`output_file` becomes **required, with no default**. Every write is then
user-specified.

| Call | Result |
|---|---|
| `quickmap("d.csv", output_file = "map.html")` | writes `map.html` in the working directory |
| `output_file = "aq_maps/map.html"` | writes there; directory created because it was named |
| `output_file = "~/maps/map.html"` | used verbatim |
| `output_dir = "out"` | prepended to `output_file`; governs the JPG set too |
| `options(quickmap.output_dir = "aq_maps")` | session default, e.g. in `.Rprofile` |

No invented directory. Relative paths resolve against the working
directory, as any R function does — the same convention as
`ggplot2::ggsave(filename, path =)` and `rmarkdown::render(output_file,
output_dir =)`.

The widget is still returned invisibly. It is not offered as a default,
because the chrome — banner, legend, time slider, indicator, attribution
— is injected into the *saved file* by `inject_banner_legend_controls()`.
An unsaved return is a bare leaflet map, not the product.

## What breaks

- Every script calling `quickmap()`/`create_pollution_map()` without
  `output_file`, and every one relying on the `aq_maps/` prefix.
- The manual: `vignettes/quickmap.Rmd` (two places) and
  `vignettes/sharing.Rmd` describe `aq_maps/`.
- Roxygen: five `@param output_file` blocks in `R/quickmap.R` and
  `R/quickmap_api.R`.
- `tests/testthat/helper-characterization.R`, which reads maps from
  `aq_maps/` inside a temp working directory.

Pre-1.0 with an API-reform mandate: break cleanly, document in the manual
and version history. No deprecation cycle.

## Sequencing

1. Land the change with the manual and roxygen edits in the same commit
   (CLAUDE.md docs-consistency rule).
2. `feature/breathe-london-fetch` (PR #51) edits the same function; rebase
   it afterwards.
3. Do it with the `marker_labels` → `symbol_labels` rename, also queued in
   item 9, so the manual is edited once rather than twice.

## Related

- `dev/260708_item9_check-baseline_v1.md` — the R CMD CHECK findings.
- CLAUDE.md roadmap item 9, "package/workspace separation".

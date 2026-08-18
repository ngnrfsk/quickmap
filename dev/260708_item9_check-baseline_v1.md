# Roadmap item 9: R CMD CHECK baseline — 2026-07-08

**Run:** `devtools::check()` on main at v0.9.8.1 (post PR #32).
**Result: 2 ERRORS / 2 WARNINGS / 3 NOTES.** CRAN requires 0/0 and
explains any remaining NOTEs. Raw findings: this file; full log lives in
the session tmp (regenerate any time with `devtools::check()`).

Every finding, what it means, and the intended fix. None are fixed yet —
fixes are item-9 work proper, sequenced below.

## Errors (must fix)

**E1 — Example fails: `create_pollution_map()` roxygen example.**
**Fixed 2026-08-17 (v0.9.9.13)**, with item 9.1: both
`render_pollution_map()` examples are now `\dontrun{}`. An example that
runs would also write a file, which is the policy 9.1 exists to satisfy.
E2 below is still open, so a check with tests still errors.

The help-page example sets `DATA_PATH = "~/data"` and reads
`wandsworth_2017_2024.csv`, which doesn't exist on a checking machine, so
R CMD CHECK executes it and dies. Fix: wrap map-rendering examples in
`\dontrun{}` (the `quickmap()` example already is) — or, better long
term, point them at the bundled teaching data proposed as template
principle P7 (dev/260708_page_template_review_v2.md), which would make
them genuinely runnable.

**E2 — Test suite fails under check: `test-consistency.R` can't find the
project root.** The consistency test locates CLAUDE.md by walking up from
the working directory; under R CMD CHECK the tests run from an installed
copy with no project root, so `find_root()` errors (note: errors, rather
than skipping). Fix: make the test skip cleanly when no project root
exists (`skip_if` on the root search) — it is a repo-consistency test,
not an installed-package test.

## Warnings (must fix)

**W1 — Non-ASCII characters in R/quickmap.R.** Portable packages must be
ASCII-only outside comments. Likely µ/°/arrow characters in strings. Fix:
locate with `tools::showNonASCIIfile()`, replace string literals with
`\uxxxx` escapes (comments may stay).

**W2 — Undocumented arguments in `inject_banner_legend_controls()`:**
`image_mode`, `image_dimensions`, `autoplay`, `play_speed`,
`display_times` have no roxygen `@param` entries. Fix: document them (it
is internal — also give it `@keywords internal`, see N-extra below).

## Notes (fix or justify)

**N1 — future file timestamps: "unable to verify current time".**
Environment artefact (offline time service), not a package problem.
No action; re-check on a normal run.

**N2 — non-standard top-level directory `docs/`.** The locally built
pkgdown site. Fix: add `docs` (and `dev`, `aq_maps`, `versions`,
`scripts` if flagged later) to `.Rbuildignore` — the check saw `docs/`
because it isn't build-ignored, independent of .gitignore.

**N3 — "no visible binding for global variable" (13 symbols).** Standard
NSE false-positives from dplyr/data.table code (`siteCode`, `year`,
`:=`, …) plus two genuinely missing stats imports. Fix:
`importFrom(stats, complete.cases, median)` in roxygen, and a
`utils::globalVariables()` declaration for the NSE column names.

## Adjacent item-9 debts (not surfaced by this check but queued)

- 11 internal helpers lack `@keywords internal` (currently hidden via
  _pkgdown.yml's `internal` section on the manual branch — the roxygen
  tags are the real fix).
- Full docs-vs-code audit and dev/PROJECT_STATUS.md restructure
  (current-state section + archived history), per the roadmap item text.
  (Restructure done early, 2026-07-13 — plain-language rewrite; the
  docs-vs-code audit remains, with dev/260712_api_catalogue_v1.md as its
  worklist.)
- Ship small teaching-data extracts inside the package (inst/extdata) so
  manual examples and R CMD CHECK examples run on any machine — the
  second half of template principle P7; the DATA_PATH copies
  (scripts/manual/manual_data_v3.R) are the interim.
- pkgdown renders the top-level CLAUDE.md into the built site
  (docs/CLAUDE.html) — exclude it before the site is ever deployed
  publicly.
- `marker_labels` → `symbol_labels` rename with the old name aliased
  (aligns API with the "symbols" terminology; also resolves the
  marker_labels/data_symbols inconsistency). **DECIDED 2026-07-13 (user,
  option a): do the rename with the alias, in this item.** Scope when
  implementing: parameter on quickmap()/create_pollution_map(), roxygen,
  manual pages and theme key `map.marker_labels` (add `symbol_labels`
  equivalent), deprecation-free alias behaviour, tests.

## Suggested fix order (each with full gate)

1. E2 + N2 (test skip + .Rbuildignore) — mechanical, zero behaviour risk.
2. W2 + the @keywords internal sweep — roxygen only.
3. N3 (imports + globalVariables) — NAMESPACE change, re-gate carefully.
4. W1 (non-ASCII) — string literals touched; characterization net guards
   the rendered output (legend labels contain µg/m³ — verify bytes).
5. E1 (examples) — decide \dontrun vs P7 teaching data first (user
   decision pending on P7).

Fixes should start after PR #33 (manual phase 1) merges, to avoid
DESCRIPTION/_pkgdown.yml collisions.

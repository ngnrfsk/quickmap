---
editor_options:
  markdown:
    wrap: 80
---

# Roadmap item 9: restructuring the project record

**2026-08-16.** Step 1 done the same day; steps 2 and 3 outstanding.

## Why

- 1391 lines, ~120 headings, three organising schemes at once: by date, by
  priority, by version. The same fixes appeared under two of them.
- Open defects sat at line 1077, below ~400 lines of 2025 history. "CRITICAL:
  HTML File Size Bloat" still read as blocking; item 6 fixed it at v0.9.7.
- Chronology broke twice; the tail was v0.9.3 instructions contradicting
  CLAUDE.md, telling the reader to `source("R/quickmap.R")`.
- Ids 12, 13 and 14 were each used twice. "Medium Priority Issues" was empty.
  Only three entries carried `id | area | severity | status`.

## Step 1 — split current from history (done)

- Live file keeps: status, waiting-on list, roadmap, open defects, concepts,
  August entries. Rewritten to the conciseness rules; detail cited to dev/ docs.
- Everything older moved verbatim to
  dev/archive/PROJECT_STATUS_history_to_260816.md. Nothing deleted except the
  empty heading and issue 17, done at v0.9.5.
- Gate: tests/testthat/test-consistency.R, which reads the stated version.

## Step 2 — defects and roadmap to GitHub Issues

- Repo is public with Issues enabled; no issues or milestones exist yet.
- Each defect becomes an issue; labels and state replace the hand-kept fields
  and make duplicate ids impossible.
- Items 9, 11, 12, 13, 14 become issues in a `v1.0` milestone. PRs close them
  with `Closes #n`.
- DESCRIPTION gains `URL:` and `BugReports:`. Both are CRAN convention; neither
  exists.
- Redaction pass first: client names, the 12 July data-loss incident, the
  unresolved Breathe London discrepancies.
- A `dev/ISSUES.md` register was rejected: it hand-builds what GitHub supplies.

## Step 3 — what the file keeps

- Status, waiting-on list, link to the v1.0 milestone. ~120 lines.
- Narrative stays in the repo; issue threads scatter it.
- Version history stays in NEWS.md, which CRAN and pkgdown render.

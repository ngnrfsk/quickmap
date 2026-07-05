# Autonomous session start prompt

**Date:** 2026-07-05
**Use:** paste into a fresh interactive `claude` session in the terminal to
start autonomous roadmap work (foreground, so the user can monitor).

```
Begin autonomous work on the QuickMap roadmap per the "Autonomous Agent
Instructions" section of CLAUDE.md. Read that section in full first — it is the
approved plan and overrides general instincts.

Start with roadmap item 1 (path-resolution/packaging fix), then proceed in
roadmap order as far as the defined STOP points allow.

Item 1 was partially executed by a previous failed run. Its work sits
UNCOMMITTED in the stale worktree .claude/worktrees/agent-a74c8a79472843d40/
(branch feature/packaging, whose tip is an ancestor of main — no committed
work). Relevant files there: DESCRIPTION, NAMESPACE, LICENSE, .Rbuildignore,
R/quickmap-package.R, and modifications to R/quickmap.R. Begin item 1 by
reviewing that diff critically — do NOT merge it wholesale; the worktree also
contains files of doubtful lineage (CLAUDE_gem.md, PROJECT_STATUS_gem.md,
251029_README.md) and is based on a main that predates the current permission
guards and CLAUDE.md. Port only what is still correct onto a fresh branch cut
from current main (pick a new branch name, e.g. feature/packaging-2, to avoid
colliding with the stale branch), then delete the stale worktree and the old
feature/packaging branch once salvage is complete.

Reminders:

- Verify Sys.getenv("DATA_PATH") points to ~/Coding/Library/data before
  anything else; if the data is absent, STOP and report.
- Create a feature branch before modifying anything (e.g. feature/packaging).
  Never commit on main.
- Follow the permission-safe command style exactly (no cd, no inline env
  assignments, no $(), no loops/redirects — script files via Rscript instead).
- Gate every change: testthat suite (no new failures beyond the known-red
  baseline; item 1 includes making it green), smoke test writing to aq_maps/,
  and test-consistency.R always green.
- Preserve the signed-off baseline aq_maps/baseline_260705_signed_off/ —
  never overwrite it; use dated outputs for new maps.
- Honour every STOP: atomic-unit design approval (item 3), the item-5
  candidate-list confirmation (dev/260705_rendering_backend_candidates.md is
  the proposed expanded field) and recommendation approval, human visual
  sign-off on rendering-touching PRs, and never stacking more than one
  unreviewed roadmap item.
- Open a PR per item with the human-check instructions the CLAUDE.md
  verification section requires; never merge or push to main.

Work steadily and report progress as you go; when you hit a STOP, summarise
state and wait.
```

Note: because unreviewed roadmap items must not stack, the realistic scope of
one run is item 1 (plus item 2 if the item-1 PR is reviewed while it runs).
Re-use this prompt after each review cycle.

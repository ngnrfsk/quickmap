# Prompt scraps

/plugin install frontend-design\@claude-plugins-official

## prompt to start autonomous quickmap run

Operate autonomously per CLAUDE.md's "Autonomous Agent Instructions", starting with roadmap item 1. Item 1 is partially complete and uncommitted in the worktree .claude/worktrees/agent-a74c8a79472843d40 (branch feature/packaging) — enter that worktree, review what's there, and continue it rather than restarting. Until item 1 lands, run the testthat gate as: source("R/quickmap.R") then test_dir(..., env = globalenv()); the known-red baseline is 29 failing expectations across 5 files (test-themes and test-consistency must be fully green); fixing the gate and the stale baseline figure in CLAUDE.md is part of item 1.

## prompt to start autonomous quickmap run

Context: Quickmap (main branch) is an advanced, but still in development (v0.9.4) codebase that ingests air pollution data or other time varying location based information and creates dynamic, time varying maps of it in HTML, with JPG export capability. The final goal (v1.0) is a new R library on CRAN. The interim goals (some partially complete) are to

- modularise the elements of the current main function create_pollution_map so these can easily be combined with OpenAir library functions that access UK air pollution measurement networks in near real time,
- process OpenAir's time-oriented table/tibble, non-geographic data into time varying spatial features that can be used by the existing code, to they can be mapped using exist codebase.
- Adjust create_pollution_map() becomes a thin wrapper around the new quickmap() function that takes data in an appropriate format and maps it.
- Select a norm for the graphical grammars to use, and progress towards that.
- Migrate examples so they work in the final form.

Task:

- Use the existing documentation to develop a plan to achieve these goals. Where there are gaps, search for 1-3 code examples or manuals online to close those gaps.
- Plan to itegrating the current approaches (eg YAML) with the finally chosen grammars.
- Refactor the existing codebase to progress it towards the stated final goal.

\## Begin autonomous operation on QuickMap.

Authority: CLAUDE.md, section "Autonomous Agent Instructions". Read it in full

before doing anything else. The roadmap there is the approved plan; the only

stops are the ones it enumerates. This prompt adds no scope beyond it.

Setup and constraints:

\- Base all work on `main`. Create a new branch per roadmap item, e.g.

`feature/packaging`.

\- First action: verify DATA_PATH points to \~/Coding/Library/data and the test

data is present. If absent, STOP and report.

\- Confirm the known-red test baseline (\~11 testthat failures) matches what you

observe before changing anything, so you can distinguish new failures from

baseline ones.

Task: execute roadmap item 1 (path resolution / packaging), whose exit

criteria are: quickmap installs via devtools::install() and loads with

library(quickmap); the smoke test is updated to match in the same change; the

testthat suite is fully green (fix or delete stale tests as part of this item);

R CMD CHECK may be red but must not regress. Archive the current R/quickmap.R

to versions/ before refactoring.

Deliverable: an open PR (never merge it yourself)

the three demonstration maps locally in aq_maps/ and list in the PR description the generating script, output paths, and what ck.

Update dev/PROJECT_STATUS.md before ending the session.

While the item 1 PR awaits review you may begin roadmap item 2 RESEARCH ONLY:

the API survey and the atomic-unit recommendatt

the design-approval STOP. No item 2 implementation until the design is

approved and the item 1 PR is reviewed.

## Permissions pre-Test approach

\## This is a PERMISSIONS TEST, not real work. Execute the numbered steps below in

order, in the QuickMap repo. Before EACH step, output the step number and name

on its own line, then run it. Never prefix commands with `cd` — use absolute

paths or git -C. Do not improvise extra commands; if a step fails or is denied,

record it and move on.

1.  READ: run `git -C ~/Coding/quickmap status --short` and grep for "Level"

in R/quickmap.R

2.  WRITE: create file `permtest/probe.txt` in the repo (mkdir + Write tool)
3.  EDIT: append one line to permtest/probe.txt with the Edit tool
4.  FILE-OPS: cp permtest/probe.txt to permtest/probe2.txt, then mv probe2.txt

to probe3.txt

5.  BRANCH: `git -C ~/Coding/quickmap checkout -b permtest-branch`
6.  COMMIT: git add the permtest/ folder and commit "permissions probe"
7.  PUSH (dry-run only): \`git -C \~/Coding/quickmap push --dry-run origin

permtest-branch\`

8.  GITHUB READ: `gh pr list -R ngnrfsk/quickmap` and `gh auth status`
9.  R: `Rscript -e "sessionInfo()"` and `R --version`
10. CLEANUP: `git -C ~/Coding/quickmap checkout main`, delete permtest-branch

(`git branch -D permtest-branch`), confirm permtest/ is gone from the

working tree

11. KNOWN-BAD PROBE (expected to trigger a permission prompt — this one is

deliberate): run `cd /tmp && ls`. Whether it prompts tells us if compound

`cd` commands still bypass the allowlist.

Then report a table: step \| command class \| succeeded / denied / skipped.

Make no other changes. Do not push anything for real, do not open PRs, do not

touch main's content.

## Testing/setup for autonomous operations

during a trial autonomous agent run, the agent had to be killed as it needed many user permissions due to poorly autonomous permissions handling, e.g. breaking for "Tilde in assignment value — bash may expand at assignment time". Investigate this and safe autonomous permissions, reviewing the pre-test prompt idea included in `Permissions pre-Test approach.md`, whether the CLAUDE.md addresses the issues fully, test and whether anything else is needed on permissions to allow Fable to work autonomously, including protective action e.g. steps start by creating a fresh branch to protect stable code on main, following best practice for Claude autonomous option. Don't trigger the "Tilde in assignment value" break during this task or else start by proposing a fix for that before proceeding.
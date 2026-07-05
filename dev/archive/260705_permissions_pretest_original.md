## Permissions pre-Test approach

\## This is a PERMISSIONS TEST, not real work. Execute the numbered steps below in

order, in the QuickMap repo. Before EACH step, output the step number and name

on its own line, then run it. Never prefix commands with `cd` — use absolute

paths or git -C. Do not improvise extra commands; if a step fails or is denied,

record it and move on.



1. READ: run `git -C ~/Coding/quickmap status --short` and grep for "Level"

  in R/quickmap.R

2. WRITE: create file `permtest/probe.txt` in the repo (mkdir + Write tool)
3. EDIT: append one line to permtest/probe.txt with the Edit tool
4. FILE-OPS: cp permtest/probe.txt to permtest/probe2.txt, then mv probe2.txt

  to probe3.txt

5. BRANCH: `git -C ~/Coding/quickmap checkout -b permtest-branch`
6. COMMIT: git add the permtest/ folder and commit "permissions probe"
7. PUSH (dry-run only): `git -C ~/Coding/quickmap push --dry-run origin

  permtest-branch`

8. GITHUB READ: `gh pr list -R ngnrfsk/quickmap` and `gh auth status`
9. R: `Rscript -e "sessionInfo()"` and `R --version`
10. CLEANUP: `git -C ~/Coding/quickmap checkout main`, delete permtest-branch

  (`git branch -D permtest-branch`), confirm permtest/ is gone from the

  working tree

11. KNOWN-BAD PROBE (expected to trigger a permission prompt — this one is

  deliberate): run `cd /tmp && ls`. Whether it prompts tells us if compound

  `cd` commands still bypass the allowlist.



Then report a table: step | command class | succeeded / denied / skipped.

Make no other changes. Do not push anything for real, do not open PRs, do not

touch main's content.
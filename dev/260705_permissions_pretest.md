# Permissions Pre-Test — interactive probe run

Run this **interactively** (human at the keyboard) after any change to
`.claude/settings.json`, the protect-main hook, or the CLAUDE.md command-style
rules — and before launching the next autonomous session. Purpose: surface every
permission prompt while a human is present to answer it, so autonomous runs never
stall on one.

Supersedes the root-level "Permissions pre-Test approach.md" draft (archived to
dev/archive/). Changes from the draft: absolute paths throughout (tilde as a
command *argument* doesn't match path-anchored allow rules), an env probe, a
protect-main hook probe, a deny-rule probe, and the tilde-assignment trial killer
added as a deliberate known-bad probe.

## Prompt to paste to the agent

This is a PERMISSIONS TEST, not real work. Execute the numbered steps below in
order, in the QuickMap repo. Before EACH step, output the step number and name on
its own line, then run it. Never prefix commands with `cd` — use absolute paths or
`git -C /Users/iarla/Coding/quickmap`. Do not improvise extra commands; if a step
fails or is denied, record it and move on. Steps marked EXPECTED PROMPT or
EXPECTED DENY are deliberate — record the outcome, answer No to any prompt, and do
not retry.

1. READ: run `git -C /Users/iarla/Coding/quickmap status --short` and grep for
   "Level" in /Users/iarla/Coding/quickmap/R/quickmap.R
2. ENV: `Rscript -e 'cat(Sys.getenv("DATA_PATH"))'` — must print the data path
   with no inline assignment needed
3. WRITE: create file permtest/probe.txt in the repo (mkdir + Write tool)
4. EDIT: append one line to permtest/probe.txt with the Edit tool
5. FILE-OPS: cp permtest/probe.txt to permtest/probe2.txt, then mv probe2.txt to
   probe3.txt (absolute paths)
6. HOOK PROBE (EXPECTED PROMPT — answer No): while on main, run
   `git -C /Users/iarla/Coding/quickmap commit --allow-empty -m "hook probe"`.
   The protect-main hook must raise an approval prompt; answering No must block
   the commit
7. BRANCH: `git -C /Users/iarla/Coding/quickmap checkout -b permtest-branch`
8. COMMIT: git add the permtest/ folder and commit "permissions probe" — must
   pass silently on the branch (hook stays quiet off main)
9. PUSH (dry-run only): `git -C /Users/iarla/Coding/quickmap push --dry-run
   origin permtest-branch`
10. DENY PROBE (EXPECTED DENY): `git -C /Users/iarla/Coding/quickmap merge
    --no-ff permtest-branch` — the deny rule must block it without a prompt
11. GITHUB READ: `gh pr list -R ngnrfsk/quickmap` and `gh auth status`
12. R: `Rscript -e "sessionInfo()"` and `R --version`
13. CLEANUP: `git -C /Users/iarla/Coding/quickmap checkout main`, delete the
    branch (`git branch -D permtest-branch`), confirm permtest/ is gone from the
    working tree
14. KNOWN-BAD PROBE 1 (EXPECTED SANDBOX, NO PROMPT — deliberate): run
    `cd /tmp && ls`. As of the 2026-07-05 run, Claude Code no longer prompts on
    compound `cd` commands — it runs them in a sandbox and resets the cwd
    afterwards ("Shell cwd was reset" in the output). Expected outcome: runs
    sandboxed, cwd reset, no prompt. If it prompts instead, the sandbox
    behaviour has changed again — note the Claude Code version
15. KNOWN-BAD PROBE 2 (EXPECTED PROMPT — deliberate; this one killed the
    2026-07-04 trial run): run `DATA_PATH=~/Coding/Library/data Rscript -e
    "cat(1)"`. It must trigger the "Tilde in assignment value" prompt; answer No.
    If it ever stops prompting, note the Claude Code version — the heuristic has
    changed

Then report a table: step | command class | allowed silently / prompted / denied.
Make no other changes. Do not push anything for real, do not open PRs, do not
touch main's content.

## Pass criteria

- Steps 1–5, 7–9, 11–13 complete with **zero prompts**
- Step 6 prompts (hook working), step 10 denies (deny rules working)
- Step 14 runs sandboxed with no prompt (cwd reset); step 15 prompts
  (tilde-assignment heuristic unchanged)

History: the 2026-07-05 run failed steps 6 and 10 — the hook matched only the
literal string "git commit" and the deny rules only bare `git merge`/`git push`
prefixes, so the `git -C /Users/iarla/Coding/quickmap` form mandated by
CLAUDE.md bypassed both. Fixed same day: hook now matches both forms; deny list
carries `-C` variants of every rule.

Any silent pass on 6/10 or unexpected prompt on 1–13 means the config or the
heuristics have drifted: fix `.claude/settings.json` / the hook, or update the
command-style rules in CLAUDE.md, before autonomous work resumes.

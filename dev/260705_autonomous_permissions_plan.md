# Autonomous Permissions — investigation and fix (260705)

A trial autonomous run on **2026-07-04, killed ~21:00 local** (initially
misrecorded here as 2026-07-05 — corrected after the user flagged it), stalled
repeatedly on permission prompts, e.g. "Tilde in assignment value — bash may
expand at assignment time". This doc records the investigation, what was
implemented on `chore/autonomous-permissions`, and what remains.

## Trial run evidence (transcript recovered)

The corrected date located the transcript: the trial was the **roadmap item 1
packaging agent**, run as a subagent in the `agent-a74c8a79472843d40` worktree,
2026-07-04 19:44–20:14 UTC (20:44–21:14 BST) — which is why `feature/packaging`
sits uncommitted in that worktree. Findings from the transcript:

- 35 Bash commands in ~30 minutes; the run was killed mid-task after the
  testthat audit phase.
- Two outright denials recorded: `cd /tmp && Rscript -e '...'` (cd-compound)
  and a `for f in ...; do ... $(Rscript ...)` loop (loop + command
  substitution).
- The other prompts were manually **approved** by the user — each one a stall.
  Their residue is the tail of ad-hoc rules in settings.local.json
  (`gh auth *`, `R --version`, `git checkout *`, `perl -i -pe ' *`).
- The "Tilde in assignment value" prompt appears in the UI dialog only; it is
  not persisted in transcripts (0 matches), consistent with the user's report.
- The agent's habitual command style was the problem: cd-compounds, `for`
  loops, `$(...)` substitution, heredoc appends (`cat >> file << 'EOF'`),
  `perl -i` — every novel construct raised a fresh prompt.

## Root cause — two layers

**1. Parse-safety heuristics beat the allowlist.** Claude Code's Bash permission
evaluator contains safety checks that force a manual prompt even when an allow
rule matches the command. Confirmed set (researched against current official
docs 2026-07-05; some behaviors are undocumented):

- Env-assignment prefixes with `~` in the value (`DATA_PATH=~/x cmd`) — the
  trial killer. Absolute-path values avoid it.
- Compound commands (`&&`, `||`, `;`, pipes, newlines): split and matched
  segment-by-segment; one unmatched segment (e.g. `cd /tmp`) prompts.
- Exec wrappers (`find -exec`, `xargs`, `watch`, `flock`): cannot be
  auto-approved by prefix rules at all.
- Unquoted globs in write/delete commands.
- Command substitution `$(...)`/backticks: undocumented; assume they prompt.

No `permissions.allow` rule suppresses these. The only fixes are (a) removing
the need for the triggering construct, and (b) command-style discipline.

**2. The prerequisite forced the trigger.** CLAUDE.md's gate says DATA_PATH must
point at the data library and shows only the R-side `Sys.setenv` form. An agent
running the gate from bash naturally writes `DATA_PATH=~/... Rscript ...` —
guaranteeing the tilde prompt. (Ironically the user's shell profile already
exports DATA_PATH, so the assignment was never needed — but nothing told the
agent that.) The curated allowlist also lived only in `.claude/settings.local.json`
(personal, auto-mutating, accumulated from one-off approvals), not in a
committed project file.

**A process note:** the initial version of this investigation assumed the trial
ran on 2026-07-05 instead of asking the user, searched the transcripts around
the wrong date, and wrongly concluded the transcript was unrecoverable. Facts
about events outside the session (when, where, which run) should be confirmed
with the user before building on them.

## Implemented (branch `chore/autonomous-permissions`)

1. **`.claude/settings.json`** (project, committed):
   - `env.DATA_PATH = /Users/iarla/Coding/Library/data` (absolute) — removes the
     inline-assignment need structurally; applies to Bash and all child
     processes in every session.
   - `permissions.allow`: curated 72-rule allowlist migrated from
     settings.local.json (R/Rscript, git read+write, gh, file ops, read-only
     text tools, WebFetch domains).
   - `permissions.deny`: push-to-main variants (`origin main`, `origin
     HEAD:main`), force push, `git merge` (humans merge), `git reset --hard`,
     `git branch -D main`, `rm -rf`. Deny beats allow across all settings
     scopes.
   - `permissions.defaultMode = acceptEdits`.
   - PreToolUse hook registration (object-keyed schema, verified against the
     current settings schema; an initial research pass returned a wrong array
     format — corrected against the hooks reference).
2. **`.claude/hooks/protect-main.sh`**: on any Bash `git commit` it checks the
   tool call's cwd branch; on `main` it returns `permissionDecision: "ask"` —
   interactive users get a confirm dialog (doc commits to main stay possible),
   autonomous runs are stopped from silently committing to main and are told to
   branch. Pipe-tested (non-commit, commit-on-branch, commit-on-main via a temp
   worktree) and proven live via sentinel — hooks hot-reload without restart.
3. **CLAUDE.md**: new "Permissions and command style — autonomous safety"
   subsection (the command-style rules above, branch-first, pre-test pointer);
   Environment Setup now states DATA_PATH is provided by settings.
4. **Pre-test**: the root draft "Permissions pre-Test approach.md" reviewed and
   superseded by `dev/260705_permissions_pretest.md`. Verdict on the idea:
   sound — an interactive probe run is the only way to observe prompts safely;
   kept its structure (numbered steps, no improvisation, known-bad probes
   last). Gaps fixed: tilde args in `git -C ~/...` wouldn't match the
   path-anchored allow rule (absolute paths now); no probe existed for the
   actual trial killer (added, deliberate, last); no probes for the hook, the
   deny rules, or the env injection (added); pass criteria added.
5. **`settings.local.json`** untracked (auto-mutating personal file; was causing
   perpetual dirty status) — kept on disk, added to .gitignore.

## Verification performed

- Hook: 3 pipe-tests correct; sentinel proof that it fires on live Bash calls.
- settings.json: jq schema/nesting validation passed.
- `Rscript -e 'cat(Sys.getenv("DATA_PATH"))'` prints the path with no inline
  assignment (currently via shell profile; settings env covers non-login
  contexts and future sessions).
- Full interactive pre-test: **not runnable from this background session**
  (deliberate prompts would stall it) — the human should run
  dev/260705_permissions_pretest.md once before the next autonomous session.

## Residual gaps / recommendations

1. **GitHub branch protection on `main`** (Settings → Branches, or
   `gh api`): local deny rules can't cover every push spelling; server-side
   protection is definitive. Requires repo owner action.
2. **`ask` in headless runs**: documented as "show the prompt as normal"; in a
   truly unattended `-p` run this means the call blocks/fails and the agent
   sees the reason and can branch — acceptable, but observe the first
   autonomous run's behaviour at the hook.
3. **Launch mode**: `acceptEdits` plus this allowlist should cover roadmap
   work. If prompts still occur for novel commands, consider launching
   autonomous sessions with `--permission-mode auto` (background safety
   classifier handles the unmatched tail) rather than widening the allowlist.
4. ~~The trial run's transcript was not found~~ — superseded: the transcript
   was recovered once the correct date (2026-07-04) was known; see "Trial run
   evidence" above. The prompt inventory is now evidence-based.
5. **Resuming roadmap item 1**: the killed packaging agent's work sits
   uncommitted on the `feature/packaging` worktree. With the permission config
   now in place, that item can be resumed without the prompt storm that killed
   it.

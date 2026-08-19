#!/bin/bash
# PreToolUse hook: merging a PR requires explicit human approval, every time.
# "gh pr" is allowlisted for view/create/close, so without this hook a merge
# would run unprompted. The "ask" decision below overrides the allowlist and
# raises a permission prompt naming the exact command — that prompt is the
# formal approval. In unattended runs a prompt is a stall, which is correct:
# merging never happens unattended.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

case "$cmd" in
  *"gh pr merge"*|*"gh api"*merge*|*"gh pr"*"--merge"*) ;;
  *) exit 0 ;;
esac

reason="Merging a pull request: [$cmd]. Approval must come from the human at this prompt — approve only if you asked for this specific PR to be merged. Approval covers this one merge only."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":%s}}\n' \
  "$(printf '%s' "$reason" | jq -Rs .)"
exit 0

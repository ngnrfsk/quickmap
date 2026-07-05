#!/bin/bash
# PreToolUse hook: commits on main require explicit human approval.
# Autonomous agents must work on a feature branch; interactive users get a prompt.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

case "$cmd" in
  *git*" commit"*) ;;
  *) exit 0 ;;
esac

dir=$(printf '%s' "$input" | jq -r '.cwd // "."')
branch=$(git -C "$dir" branch --show-current 2>/dev/null)

if [ "$branch" = "main" ]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Committing on main. Autonomous work belongs on a feature branch (git checkout -b <branch>); only a human should approve a direct commit to main."}}
JSON
fi
exit 0

#!/usr/bin/env python3
"""Mechanical test for gatekeeper.py — pipes hook-protocol JSON into the real
script and asserts allow/deny. Run after any change to the gatekeeper or to
permissions.allow: python3 .claude/hooks/test_gatekeeper.py"""
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GATEKEEPER = os.path.join(HERE, "gatekeeper.py")
PROJECT = os.path.dirname(os.path.dirname(HERE))
REPO = "/Users/iarla/Coding/quickmap"


def denied(tool_name, tool_input):
    payload = json.dumps({"tool_name": tool_name, "tool_input": tool_input, "cwd": PROJECT})
    env = dict(os.environ, CLAUDE_PROJECT_DIR=PROJECT)
    r = subprocess.run([sys.executable, GATEKEEPER], input=payload,
                       capture_output=True, text=True, env=env)
    if r.returncode != 0:
        raise RuntimeError("gatekeeper crashed: " + r.stderr)
    return '"deny"' in r.stdout


BASH_CASES = [
    # (description, command, expect_deny)
    ("plain allowlisted git -C", "git -C %s status --short" % REPO, False),
    ("metacharacters inside single quotes",
     "Rscript -e 'cat(\"a; b && $(x) `y`\")'", False),
    ("parens inside double quotes",
     'Rscript -e "cat(Sys.getenv(\'DATA_PATH\'))"', False),
    ("grep with quoted pattern", 'grep -n "Level" %s/R/quickmap.R' % REPO, False),
    ("compound of allowlisted segments",
     "git -C %s add permtest/ && git -C %s commit -m \"probe (x); y\"" % (REPO, REPO), False),
    ("pipe between allowlisted commands", "printf '%s' hi | jq -r .a", False),
    ("redirect to /dev/null plus echo",
     "jq . %s/.claude/settings.json > /dev/null && echo JSON_OK" % REPO, False),
    ("stderr merge 2>&1", "Rscript /tmp/x.R 2>&1", False),
    ("Rscript wrapper for unlisted work",
     "Rscript /Users/iarla/.claude/jobs/6c0b9a7a/tmp/test_hook.R", False),
    ("cd compound (pretest step 14)", "cd /tmp && ls", True),
    ("inline tilde assignment (pretest step 15, killed 2026-07-04 run)",
     'DATA_PATH=~/Coding/Library/data Rscript -e "cat(1)"', True),
    ("unlisted executable in job dir (raised 3 prompts on 2026-07-05)",
     "printf '{}' | /Users/iarla/.claude/jobs/x/tmp/hook.sh", True),
    ("command substitution $(...)", "echo $(date)", True),
    ("backticks", "echo `date`", True),
    ("shell variable in double quotes", 'echo "$HOME"', True),
    ("heredoc", "cat <<EOF", True),
    ("output redirect to a file", "ls /tmp > /tmp/out.txt", True),
    ("redirect hidden after allowlisted git", "git -C %s show main:R/quickmap.R > /tmp/q.R" % REPO, True),
    ("shell loop", "for f in a b; do echo hi; done", True),
    ("find -exec", "find . -name '*.tmp' -exec rm {} \\;", True),
    ("unlisted command", "curl https://example.com", True),
    ("unlisted second segment", "git status && whoami", True),
    ("sneaky /dev/null lookalike", "ls > /dev/null.txt", True),
]

WEBFETCH_CASES = [
    ("allowlisted domain", "https://github.com/ngnrfsk/quickmap", False),
    ("allowlisted domain subpage", "https://cran.r-project.org/web/packages/", False),
    ("unlisted domain", "https://evil.example.com/payload", True),
    ("unlisted subdomain of nothing", "https://github.com.evil.net/x", True),
]

fails = 0
for desc, cmd, expect in BASH_CASES:
    got = denied("Bash", {"command": cmd})
    ok = got == expect
    if not ok:
        fails += 1
    print("[%s] Bash: %s" % ("PASS" if ok else "FAIL", desc))

for desc, url, expect in WEBFETCH_CASES:
    got = denied("WebFetch", {"url": url})
    ok = got == expect
    if not ok:
        fails += 1
    print("[%s] WebFetch: %s" % ("PASS" if ok else "FAIL", desc))

# Other tools must pass through untouched
ok = not denied("Read", {"file_path": "/etc/hosts"})
if not ok:
    fails += 1
print("[%s] Other tools untouched" % ("PASS" if ok else "FAIL"))

if fails:
    sys.exit("%d gatekeeper test(s) FAILED" % fails)
print("ALL GATEKEEPER TESTS PASS")

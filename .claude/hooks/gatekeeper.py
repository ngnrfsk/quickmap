#!/usr/bin/env python3
"""PreToolUse gatekeeper: deny any Bash/WebFetch call that could raise a
permission prompt, so an unattended run can never stall on one.

Reads permissions.allow live from .claude/settings.json — one source of truth,
nothing to keep in sync. Deliberately stricter than Claude Code's own matcher:
a false deny costs one rewritten command; a prompt costs the rest of an
autonomous session. Fails closed — an internal error denies with its message.

Mechanical test: python3 .claude/hooks/test_gatekeeper.py
"""
import json
import os
import re
import sys
import urllib.parse

ALLOWED_REDIRECT = re.compile(r"(?:\d+|&)?>{1,2}\s*/dev/null(?![\w./-])|\d+>&\d+")
SEGMENT_SPLIT = re.compile(r"&&|\|\||;|\||\n|(?<!>)&")
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")
EXPANSION = re.compile(r"\$[A-Za-z_{(]")

REWRITE_HINT = (
    " Rewrite it: single allowlisted command, absolute paths, no shell"
    " metacharacters; put multi-step work in a script file run via Rscript or"
    " python3; or add a rule to permissions.allow in .claude/settings.json."
)

KEYWORD_REASONS = {
    "cd": "'cd' is banned — use absolute paths or git -C /path",
    "for": "shell loops are banned — write a script file instead",
    "while": "shell loops are banned — write a script file instead",
    "until": "shell loops are banned — write a script file instead",
    "if": "shell conditionals are banned — write a script file instead",
    "eval": "'eval' is banned",
    "exec": "'exec' is banned",
    "source": "'source' is banned",
    ".": "'.' (source) is banned",
    "sudo": "'sudo' is banned",
    "xargs": "exec wrappers (xargs) are banned — write a script file instead",
    "watch": "exec wrappers (watch) are banned",
    "nohup": "exec wrappers (nohup) are banned",
    "env": "'env' (inline environment) is banned — DATA_PATH is already set",
    "export": "'export' is banned — env vars belong in .claude/settings.json",
}


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "[gatekeeper] " + reason + REWRITE_HINT,
    }}))
    sys.exit(0)


def project_dir(data):
    for candidate in (os.environ.get("CLAUDE_PROJECT_DIR"), data.get("cwd")):
        if candidate and os.path.isfile(os.path.join(candidate, ".claude", "settings.json")):
            return candidate
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_allow_rules(data):
    path = os.path.join(project_dir(data), ".claude", "settings.json")
    with open(path) as f:
        rules = json.load(f)["permissions"]["allow"]
    bash_exact, bash_prefix, web_domains = [], [], []
    for rule in rules:
        if rule.startswith("Bash(") and rule.endswith(")"):
            body = rule[5:-1]
            if body.endswith(":*"):
                bash_prefix.append(body[:-2])
            else:
                bash_exact.append(body)
        elif rule.startswith("WebFetch(domain:") and rule.endswith(")"):
            web_domains.append(rule[16:-1])
    return bash_exact, bash_prefix, web_domains


def mask(cmd):
    """Same-length copy with quoted content replaced by 'x', so metacharacter
    and segment scanning cannot be fooled by quotes. Inside double quotes '$'
    and '`' stay visible because the shell still expands them there."""
    out = []
    i, n = 0, len(cmd)
    in_single = in_double = False
    while i < n:
        c = cmd[i]
        if in_single:
            if c == "'":
                in_single = False
                out.append("'")
            else:
                out.append("x")
            i += 1
        elif c == "\\":
            out.append("x")
            if i + 1 < n:
                out.append("x")
            i += 2
        elif in_double:
            if c == '"':
                in_double = False
                out.append('"')
            elif c in "`$":
                out.append(c)
            else:
                out.append("x")
            i += 1
        else:
            if c == "'":
                in_single = True
            elif c == '"':
                in_double = True
            out.append(c)
            i += 1
    return "".join(out)


def check_bash(cmd, bash_exact, bash_prefix):
    masked = mask(cmd)

    if "`" in masked:
        deny("backticks (command substitution) are banned.")
    m = EXPANSION.search(masked)
    if m:
        deny("shell expansion (%r) is banned — use literal values;"
             " a literal '$' must be single-quoted." % cmd[m.start():m.start() + 2])
    if "<<" in masked:
        deny("heredocs are banned — write the content with the Write tool.")
    if "<" in masked:
        deny("input redirects are banned — pipe from an allowlisted 'cat' instead.")
    allowed_spans = [m.span() for m in ALLOWED_REDIRECT.finditer(masked)]
    for i, ch in enumerate(masked):
        if ch == ">" and not any(s <= i < e for s, e in allowed_spans):
            deny("output redirects are banned (only /dev/null and 2>&1 are allowed)"
                 " — write files with the Write tool or inside a script.")
    if "(" in masked or ")" in masked:
        deny("unquoted parentheses (subshell/grouping) are banned.")

    pos = 0
    spans = []
    for m in SEGMENT_SPLIT.finditer(masked):
        spans.append((pos, m.start()))
        pos = m.end()
    spans.append((pos, len(masked)))

    for start, end in spans:
        seg = cmd[start:end].strip()
        if not seg:
            continue
        if ASSIGNMENT.match(seg):
            deny("inline environment assignment in %r — DATA_PATH is already set"
                 " via .claude/settings.json." % seg[:40])
        word = seg.split()[0]
        if word in KEYWORD_REASONS:
            deny(KEYWORD_REASONS[word] + " (segment: %r)." % seg[:60])
        if word == "find" and "-exec" in seg:
            deny("find -exec is banned — write a script file instead.")
        if not (seg in bash_exact
                or any(seg == p or seg.startswith(p + " ") for p in bash_prefix)):
            deny("segment %r does not match any permissions.allow rule." % seg[:80])


def check_webfetch(url, web_domains):
    host = urllib.parse.urlparse(url).hostname or ""
    if not any(host == d or host.endswith("." + d) for d in web_domains):
        deny("WebFetch domain %r is not allowlisted." % host)


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    tool_input = data.get("tool_input") or {}
    bash_exact, bash_prefix, web_domains = load_allow_rules(data)
    if tool == "Bash":
        cmd = tool_input.get("command", "")
        if cmd.strip():
            check_bash(cmd, bash_exact, bash_prefix)
    elif tool == "WebFetch":
        check_webfetch(tool_input.get("url", ""), web_domains)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        deny("internal error (%s: %s) — fix .claude/hooks/gatekeeper.py."
             % (type(e).__name__, e))

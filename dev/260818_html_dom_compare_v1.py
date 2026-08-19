#!/usr/bin/env python3
"""Structural comparison of two quickmap-generated HTML files.

Manual dev tool, not part of R CMD check or the testthat gate (see
dev/260818_merton_comparison_testset.md for why). Standard library only —
deliberately avoids adding a Python dependency after the xfun/knitr incident
of 2026-08-18.

Compares two axes independently, since they're expected to differ for
different reasons:

1. Chrome (banner, legend, time-slider): the `<div>` an interactive map's
   fixed elements sit in. Boilerplate JS/CSS around it (dependency bundling
   order, htmlwidget element ids) is expected to differ between two renders
   of the same data and is ignored.
2. The embedded leaflet widget payload: the `<script type="application/
   json" data-for="htmlwidget-...">` block(s) carrying the actual map data.
   Compared structurally (call sequence, marker counts per call), not
   byte-for-byte, since floating-point formatting and htmlwidget ids are not
   meaningful differences.

Usage:
    python3 260818_html_dom_compare_v1.py <file_a.html> <file_b.html>
    python3 260818_html_dom_compare_v1.py <dir_a> <dir_b>   # pairs by filename

Example (this branch's canonical comparison set — see the companion .md):
    python3 260818_html_dom_compare_v1.py \\
        "/Users/iarla/Coding/260814 Merton AQAP maps and figures refresh/animations" \\
        "/Users/iarla/Coding/260818 Merton AQAP item9-retest/animations"

Exit code 0 if every compared pair matches structurally, 1 otherwise.
"""

import sys
import os
import re
import json
from html.parser import HTMLParser

CHROME_TARGETS = {
    "banner": ("class", "banner"),
    "legend": ("id", "mapLegend"),
    "time-slider": ("id", "yearControl"),
}

WIDGET_JSON_RE = re.compile(
    r'<script type="application/json" data-for="htmlwidget-[^"]*">(.*?)</script>',
    re.DOTALL,
)


class _TreeBuilder(HTMLParser):
    """Builds a minimal (tag, sorted-classes, children, text) tree."""

    VOID_TAGS = {
        "area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "param", "source", "track", "wbr",
    }

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = {"tag": "#root", "attrs": {}, "children": [], "text": ""}
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = {"tag": tag, "attrs": dict(attrs), "children": [], "text": ""}
        self.stack[-1]["children"].append(node)
        if tag not in self.VOID_TAGS:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        node = {"tag": tag, "attrs": dict(attrs), "children": [], "text": ""}
        self.stack[-1]["children"].append(node)

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i]["tag"] == tag:
                del self.stack[i + 1:]
                self.stack.pop()
                return

    def handle_data(self, data):
        text = data.strip()
        if text:
            self.stack[-1]["text"] += text


def parse_tree(html_text):
    builder = _TreeBuilder()
    builder.feed(html_text)
    return builder.root


def find_by(node, key, value):
    attrs = node.get("attrs", {})
    if key == "class":
        classes = attrs.get("class", "").split()
        if value in classes:
            return node
    elif attrs.get(key) == value:
        return node
    for child in node.get("children", []):
        found = find_by(child, key, value)
        if found is not None:
            return found
    return None


def fingerprint(node):
    """(tag, sorted classes, direct text, [child fingerprints]) — ignores
    id/style/other volatile attributes, keeps structure + visible text."""
    classes = tuple(sorted(node.get("attrs", {}).get("class", "").split()))
    children = tuple(fingerprint(c) for c in node.get("children", []))
    return (node["tag"], classes, node.get("text", ""), children)


TEXT_DIFF_MAXLEN = 120


def _shorten(text):
    if len(text) > TEXT_DIFF_MAXLEN:
        return text[:TEXT_DIFF_MAXLEN] + f"...({len(text)} chars)"
    return text


def diff_fingerprints(fp_a, fp_b, path="root"):
    diffs = []
    if fp_a is None or fp_b is None:
        if fp_a != fp_b:
            diffs.append(f"{path}: element missing in one file")
        return diffs
    tag_a, cls_a, text_a, children_a = fp_a
    tag_b, cls_b, text_b, children_b = fp_b
    if tag_a != tag_b:
        diffs.append(f"{path}: tag {tag_a!r} vs {tag_b!r}")
    if cls_a != cls_b:
        diffs.append(f"{path}: classes {cls_a} vs {cls_b}")
    if text_a != text_b:
        diffs.append(
            f"{path}: text {_shorten(text_a)!r} vs {_shorten(text_b)!r}"
        )
    if len(children_a) != len(children_b):
        diffs.append(
            f"{path}: {len(children_a)} children vs {len(children_b)}"
        )
    for i, (ca, cb) in enumerate(zip(children_a, children_b)):
        diffs.extend(diff_fingerprints(ca, cb, f"{path}[{i}]"))
    return diffs


def extract_widget_calls(html_text):
    """One summary per embedded leaflet widget JSON block: an ordered list
    of (method, marker_count_or_None) — marker_count is len(lat array) for
    calls that add point markers, None for everything else (tiles,
    polygons, controls, ...)."""
    summaries = []
    for match in WIDGET_JSON_RE.finditer(html_text):
        try:
            payload = json.loads(match.group(1))
        except json.JSONDecodeError:
            summaries.append([("<unparseable json>", None)])
            continue
        calls = payload.get("x", {}).get("calls", [])
        summary = []
        for call in calls:
            method = call.get("method", "?")
            args = call.get("args", [])
            marker_count = None
            if method in ("addMarkers", "addCircleMarkers", "addCircles"):
                if args and isinstance(args[0], list):
                    marker_count = len(args[0])
            summary.append((method, marker_count))
        summaries.append(summary)
    return summaries


def diff_widget_calls(calls_a, calls_b):
    diffs = []
    if len(calls_a) != len(calls_b):
        diffs.append(
            f"widget count: {len(calls_a)} vs {len(calls_b)}"
        )
    for i, (wa, wb) in enumerate(zip(calls_a, calls_b)):
        if len(wa) != len(wb):
            diffs.append(f"widget[{i}]: {len(wa)} calls vs {len(wb)} calls")
        for j, (ca, cb) in enumerate(zip(wa, wb)):
            if ca != cb:
                diffs.append(f"widget[{i}].call[{j}]: {ca} vs {cb}")
    return diffs


def compare_files(path_a, path_b):
    with open(path_a, encoding="utf-8") as f:
        html_a = f.read()
    with open(path_b, encoding="utf-8") as f:
        html_b = f.read()

    tree_a, tree_b = parse_tree(html_a), parse_tree(html_b)

    report = {"chrome": {}, "payload": None}
    for name, (key, value) in CHROME_TARGETS.items():
        node_a = find_by(tree_a, key, value)
        node_b = find_by(tree_b, key, value)
        if node_a is None and node_b is None:
            report["chrome"][name] = ["not present in either file"]
            continue
        fp_a = fingerprint(node_a) if node_a is not None else None
        fp_b = fingerprint(node_b) if node_b is not None else None
        report["chrome"][name] = diff_fingerprints(fp_a, fp_b, name)

    calls_a = extract_widget_calls(html_a)
    calls_b = extract_widget_calls(html_b)
    report["payload"] = diff_widget_calls(calls_a, calls_b)

    return report


def report_is_clean(report):
    chrome_clean = all(
        d == [] or d == ["not present in either file"]
        for d in report["chrome"].values()
    )
    return chrome_clean and report["payload"] == []


def print_report(label_a, label_b, report):
    print(f"--- {label_a}  vs  {label_b} ---")
    for name, diffs in report["chrome"].items():
        if diffs == []:
            print(f"  chrome/{name}: match")
        elif diffs == ["not present in either file"]:
            print(f"  chrome/{name}: not present in either file (skipped)")
        else:
            print(f"  chrome/{name}: {len(diffs)} difference(s)")
            for d in diffs[:10]:
                print(f"    - {d}")
            if len(diffs) > 10:
                print(f"    ... and {len(diffs) - 10} more")
    if report["payload"] == []:
        print("  payload: match")
    else:
        print(f"  payload: {len(report['payload'])} difference(s)")
        for d in report["payload"][:10]:
            print(f"    - {d}")
        if len(report["payload"]) > 10:
            print(f"    ... and {len(report['payload']) - 10} more")


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2

    a, b = argv[1], argv[2]
    all_clean = True

    if os.path.isdir(a) and os.path.isdir(b):
        names = sorted(
            f for f in os.listdir(a)
            if f.endswith(".html") and os.path.isfile(os.path.join(b, f))
        )
        if not names:
            print(f"no matching .html filenames in both {a!r} and {b!r}")
            return 2
        for name in names:
            report = compare_files(os.path.join(a, name), os.path.join(b, name))
            print_report(f"{a}/{name}", f"{b}/{name}", report)
            all_clean = all_clean and report_is_clean(report)
    elif os.path.isfile(a) and os.path.isfile(b):
        report = compare_files(a, b)
        print_report(a, b, report)
        all_clean = report_is_clean(report)
    else:
        print("both arguments must be files, or both must be directories")
        return 2

    return 0 if all_clean else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))

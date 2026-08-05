"""Tidy aq_maps: keep the current working set and anything the repo still
refers to; move everything else to aq_maps/archived/.

Nothing is deleted. Run with --apply to move; without it, it only reports.

The keep rule has three parts:
  1. the current examples (this build's outputs)
  2. anything named in a dev document, an archived-code file, or a script —
     those references are how a future reader finds the option examples, so
     moving the file would break the document
  3. folders: signed-off baselines, prepared source data, the print set
"""
import os
import re
import shutil
import sys

ROOT = "/Users/iarla/Coding/quickmap"
MAPS = os.path.join(ROOT, "aq_maps")
ARCHIVE = os.path.join(MAPS, "archived")

# 1. the current working set
CURRENT = {
    "indicator_titlerow_v5.html",
    "indicator_titlerow-print_v5_2019.jpg",
    "indicator_titlerow-print-small_v5_2019.jpg",
    "titlerow_390.png",
    "legend_strip_v5.png",
    "sweep_legends.png",
    "merton_no2_annual_2019_2025.html",
}
CURRENT |= {f"sweep_{w}.png" for w in (1400, 1100, 900, 760, 620, 500, 390)}
# the collision rule is live and these are its only demonstration; the script
# that makes them builds the names dynamically, so the scan below misses them
CURRENT |= {"indicator_collision_390.png", "indicator_collision_1400.png"}

# 3. folders kept whole
KEEP_DIRS = {
    "archived", "prepared", "print_260804",
    # Both signed-off baselines were cleared on 5 August at the user's
    # request. Future ones match KEEP_DIR_RE below rather than being listed.
}
# What the user approved is never reproducible, so baselines are kept by
# shape rather than by name.
KEEP_DIR_RE = re.compile(r"^baseline_.*_signed_off$")


def referenced_names():
    """Filenames mentioned anywhere in the tracked source of the project."""
    names = set()
    pattern = re.compile(r"[\w\-.]+\.(?:html|jpg|png)")
    for sub in ("dev", "scripts", "tests", "inst/examples"):
        for dirpath, _, files in os.walk(os.path.join(ROOT, sub)):
            for f in files:
                if not f.endswith((".md", ".R", ".py", ".txt")):
                    continue
                path = os.path.join(dirpath, f)
                try:
                    text = open(path, encoding="utf-8", errors="ignore").read()
                except OSError:
                    continue
                names |= set(pattern.findall(text))
    text = open(os.path.join(ROOT, "CLAUDE.md"), encoding="utf-8").read()
    names |= set(pattern.findall(text))
    return names


def main(apply):
    keep = set(CURRENT) | referenced_names()
    entries = sorted(os.listdir(MAPS))
    moved, kept = [], []

    for name in entries:
        if name.startswith(".") or name in KEEP_DIRS or KEEP_DIR_RE.match(name):
            continue
        src = os.path.join(MAPS, name)
        if name in keep:
            kept.append(name)
            continue
        moved.append(name)
        if apply:
            os.makedirs(ARCHIVE, exist_ok=True)
            shutil.move(src, os.path.join(ARCHIVE, name))

    print(f"KEEP ({len(kept)}):")
    for n in kept:
        print("   ", n)
    print(f"\n{'MOVED' if apply else 'WOULD MOVE'} ({len(moved)})")
    if not apply:
        for n in moved:
            print("   ", n)


if __name__ == "__main__":
    main("--apply" in sys.argv)

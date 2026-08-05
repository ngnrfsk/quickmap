"""Gather the example maps that belong to concepts, and put them beside the
concept documents in dev/concepts/examples/.

A concept's examples are the only evidence that it was ever built and worked;
left in aq_maps they are indistinguishable from working output, and aq_maps is
not kept in the repository, so they were one tidy-up away from being lost.

Nothing is deleted. Run with --apply to move; without it, only reports.
"""
import os
import shutil
import sys

ROOT = "/Users/iarla/Coding/quickmap"
MAPS = os.path.join(ROOT, "aq_maps")
DEST = os.path.join(ROOT, "dev", "concepts", "examples")

# demonstration files, by the concept they belong to
CONCEPT_FILES = {
    # the retired zero-to-value bar (dev/archive/260731_indicator_bar-style_v1.R)
    "indicator_bar-animated_v2.html": "",
    "indicator_bar-annual_v2.html": "archived",
    "indicator_bar-print_v2.html": "archived",
    "indicator_bar-print_v2_2025.jpg": "archived",
    # the retired standalone track, and the pair that shows why it went
    # (dev/archive/260730_indicator_track-style_v1.R)
    "indicator_uneven-track_v1.html": "archived",
    "indicator_uneven-ramp_v1.html": "archived",
    "indicator_print-4000_v1.html": "",
    "indicator_print-900_v1.html": "",
    "indicator_merton-annual_v1.html": "",
}


def main(apply):
    moved, missing = [], []
    for name, sub in CONCEPT_FILES.items():
        src = os.path.join(MAPS, sub, name) if sub else os.path.join(MAPS, name)
        if not os.path.exists(src):
            missing.append(name)
            continue
        moved.append(name)
        if apply:
            os.makedirs(DEST, exist_ok=True)
            shutil.move(src, os.path.join(DEST, name))

    print(f"{'MOVED' if apply else 'WOULD MOVE'} ({len(moved)}) to dev/concepts/examples/")
    for n in moved:
        print("   ", n)
    if missing:
        print(f"\nnot found ({len(missing)}) — deleted or already moved:")
        for n in missing:
            print("   ", n)


if __name__ == "__main__":
    main("--apply" in sys.argv)

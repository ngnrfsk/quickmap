"""Clear aq_maps down to what cannot be rebuilt.

aq_maps is a staging area, not a store. Everything in it is output; anything
worth keeping has a proper home elsewhere in the repository:

  the manual's maps        vignettes/maps/
  concept demonstrations   dev/concepts/examples/
  what Iarla signed off    the dated baseline folders, kept here
  the current examples     rebuilt by scripts/examples_current_v1.R

So this keeps the baselines, the shareable print set, the prepared source
data and the current examples, and deletes the rest — including the archived/
folder, which was the same problem one level down.

DELETES. Run with --apply; without it, only reports.
"""
import os
import re
import shutil
import sys

MAPS = "/Users/iarla/Coding/quickmap/aq_maps"

KEEP_DIRS = {
    # Both signed-off baselines (260705, 260707) were cleared on 5 August at
    # the user's request. Any future baseline_*_signed_off folder is kept by
    # the pattern rule below, so this set does not need editing again.
    "print_260804",                 # the shareable Merton set
    "prepared",                     # source data the examples are built from
}
KEEP_PREFIX = "example_"            # rebuilt by scripts/examples_current_v1.R
# Any signed-off baseline, named or not: what the user approved is never
# reproducible, so it is kept by shape rather than by being listed here.
KEEP_RE = re.compile(r"^baseline_.*_signed_off$")


def keep(name):
    return (name.startswith(".") or name in KEEP_DIRS
            or name.startswith(KEEP_PREFIX) or KEEP_RE.match(name))


def main(apply):
    freed = 0
    removed = []
    for name in sorted(os.listdir(MAPS)):
        if keep(name):
            continue
        p = os.path.join(MAPS, name)
        size = sum(
            os.path.getsize(os.path.join(dp, f))
            for dp, _, fs in os.walk(p) for f in fs
        ) if os.path.isdir(p) else os.path.getsize(p)
        freed += size
        removed.append(name)
        if apply:
            shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)

    print(f"{'DELETED' if apply else 'WOULD DELETE'}: {len(removed)} entries, "
          f"{freed / 1024 / 1024:.0f} MB")
    for n in removed[:12]:
        print("   ", n)
    if len(removed) > 12:
        print(f"    ... and {len(removed) - 12} more")

    kept = [n for n in sorted(os.listdir(MAPS)) if not n.startswith(".")]
    print(f"\nKEPT ({len(kept)}):")
    for n in kept:
        print("   ", n)


if __name__ == "__main__":
    main("--apply" in sys.argv)

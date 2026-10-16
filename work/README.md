# work

Pieces of work done **with** quickmap: maps built for a council, a website or
a report. Created 2026-10-16.

`dev/` is for developing the package (plans, demos for roadmap items,
prototypes); `scripts/` holds the package's own demo, manual and maintenance
scripts. A job that uses the package to produce something for someone goes
here instead.

## Rules

- One folder per piece of work, named for it.
- Each folder is its own project, usually its own git repository. quickmap's
  git ignores everything in `work/` except this README, and the package build
  excludes the folder, so data and outputs never enter the package.
- A folder uses the installed quickmap (`library(quickmap)`), not `R/`
  sourced directly, so it records which version built its outputs.
- Input data stays under `DATA_PATH` (`~/Coding/Library/data`) where it is
  shared; data belonging to one job only may live in its folder.
- Each folder has a README saying what it builds, how to run it and where the
  outputs go.

## Contents

| Folder | What it is |
|---|---|
| `swlonrsp-maps-build/` | Builds the maps on swlonrsp.github.io (quickmap item 16) and the per-council tube tables (item 19). Own git repository, no remote. Moved here from `~/Coding/swlonrsp-maps-build` on 2026-10-16 |

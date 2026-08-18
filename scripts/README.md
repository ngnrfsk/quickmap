# scripts

One-off scripts, split by what they are for (7 August 2026). None of this ships:
`.Rbuildignore` excludes the whole folder.

All of them expect to be run **from the repository root**, e.g.
`Rscript scripts/demos/examples_current_v1.R`.

| Folder | What is in it |
|---|---|
| `demos/` | Scripts that render something for a human to look at: the current examples, the worked API examples, the speed-control and wind demos, the symbol sampler |
| `manual/` | Builds the pkgdown user manual. `manual_data_v3.R` stages the teaching fixtures under `DATA_PATH`, `manual_assets_v6.R` renders the 17 example maps into `vignettes/maps/`, `manual_run-chunks_v1.R` runs every code example in the chapters against real data |
| `tools/` | Maintenance. Two tidy `aq_maps/`, one tidies `dev/concepts/`, one screenshots a saved map at a chosen width |

## Where the rest went

- **Chart and table scripts** are in `quickplot/` — a separate thing from
  QuickMap, which is a mapping tool.
- **The indicator design chain** is in `dev/concepts/indicator/code/`, with the
  other set-aside ideas under `dev/concepts/`.
- **Superseded versions and demos for merged roadmap items** were deleted on
  6 August. Git history keeps them.
- **The LB Merton print set** moved to its own working folder on 15 August,
  with the `clients/` folder it lived in.

The demo scripts under `demos/` are records of the item they were written for
and have not been rerun since item 9 changed where output goes: each names a
bare `output_file` and expects `aq_maps/`, and each still says `marker_labels`.
Rerunning one means giving it an `output_dir` first.

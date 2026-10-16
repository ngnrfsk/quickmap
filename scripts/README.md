# scripts

One-off scripts, split by what they are for (7 August 2026). None of this ships:
`.Rbuildignore` excludes the whole folder.

All of them expect to be run **from the repository root**, e.g.
`Rscript scripts/demos/examples_current_v1.R`.

| Folder | What is in it |
|---|---|
| `demos/` | Scripts that render something for a human to look at: the current examples, the worked API examples, the speed-control and wind demos, the symbol sampler |
| `manual/` | Builds the pkgdown user manual — its data, its assets and its chunk runner |
| `tools/` | Maintenance. Two tidy `aq_maps/`, one tidies `dev/concepts/`, one screenshots a saved map at a chosen width |

## Where the rest went

- **Work for a real job** (maps for a council or website) goes in `work/`,
  one folder per job; see `work/README.md`. The LB Merton AQAP print set
  that was in `clients/` moved to
  `~/Coding/260814 Merton AQAP maps and figures refresh/` on 15 August.

- **Chart and table scripts** are in `quickplot/` — a separate thing from
  QuickMap, which is a mapping tool.
- **The indicator design chain** is in `dev/concepts/indicator/code/`, with the
  other set-aside ideas under `dev/concepts/`.
- **Superseded versions and demos for merged roadmap items** were deleted on
  6 August. Git history keeps them.

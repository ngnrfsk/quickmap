# The indicator script chain — summary for review

Date: 2026-08-06. Written so a keep/drop decision can be made on the eight
`indicator_*` scripts in `/Users/iarla/Coding/quickmap/scripts/`.

The legend indicator shipped in v0.9.9.9 (PR #38, merged 5 August). These eight
scripts are the design chain that got it there: prototypes, comparisons and
review renders made between 29 July and 5 August.

## They all still run

Every one reads a single input, `aq_maps/prepared/merton_no2_2019_2025.csv`,
which is still present. None depends on the signed-off baselines or the item 10
mock-up outputs that were cleared on 5–6 August — that is what separated them
from the twelve scripts deleted on 6 August.

None of their outputs remain in `aq_maps/`; re-running regenerates them.

## What each one is

| Script | What it shows | Status of the idea |
|---|---|---|
| `indicator_demo-maps_v1.R` | The five cases for sign-off: annual pre-built path, lazy path, 4000px print, 900px print, indicator switched off | **Shipped** |
| `indicator_ramp-variant_v1.R` | The "ramp" style — a bar above the legend ramp running zero to the mean | **Retired**, kept as `dev/archive/260730_indicator_track-style_v1.R` |
| `indicator_refinements_v2.R` | Thicker bar, dark cap at the value, colour chip beside the figure | **Retired**, kept as `dev/archive/260731_indicator_bar-style_v1.R` |
| `indicator_animations_v2.R` | Both styles animated 2019–2025, autoplaying, to judge the marker in motion | Comparison for a settled choice |
| `indicator_max-and-lead_v3.R` | Two proposals of 31 July: the maximum as a diamond beside the mean, and the figures moved under the legend title | **Both shipped** (`indicator.show_max`, `indicator.placement`) |
| `indicator_placement_v4.R` | The two desktop placements side by side, proving they do not overwrite each other | **Shipped** |
| `indicator_collision-demo_v1.R` | The measured collision rule, on a synthetic fixture — Merton's own network never triggers it | **Shipped**; the only demonstration of that rule |
| `indicator_titlerow_v5.R` | The final `title_row` placement across print, small print and interactive | **Shipped**, this is the set signed off |

## What is worth keeping, and why

Three groups, and they are not the same case:

**The retired alternatives** (`ramp-variant`, `refinements`) are already
duplicated in `dev/archive/`, which CLAUDE.md names as the home for
"archived alternatives, coded and retired, wakeable with instructions". Keeping
them in `scripts/` as well means two copies of a dead idea.

**The collision demo** is the only thing that demonstrates a live rule that
Merton's own data cannot show. `scripts/tidy_aq_maps_v1.py` already special-cases
its outputs because the filenames are built dynamically and its scan misses
them. Deleting it removes the only way to see that rule work.

**The rest** (`demo-maps`, `animations`, `max-and-lead`, `placement`,
`titlerow`) are review renders for a merged feature. Their value is
regenerating the pictures if the indicator is ever changed again — `titlerow_v5`
is the closest thing to a current demo, being the set that was signed off.

## Options

1. **Keep all eight.** No work. Two copies of the retired pair persist.
2. **Delete the retired pair, keep six.** They survive in `dev/archive/`.
3. **Keep two — `titlerow_v5` and `collision-demo`.** The signed-off render and
   the one rule nothing else shows; the other six are recoverable from git.
4. **Delete all eight.** Git history keeps them; `dev/archive/` keeps the two
   retired designs.

## Recommendation

Option 3. It leaves one script that regenerates the approved appearance and one
that demonstrates a rule no real dataset triggers, and drops six that exist to
support decisions already taken.

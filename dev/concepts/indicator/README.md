# Legend indicator — design chain

The network mean (and optionally maximum) marked on the legend's own colour
ramp. **Shipped** in v0.9.9.9, merged 5 August 2026 as PR #38.

Everything here is in one folder — shipped and retired together — because the
retired styles only make sense beside what shipped instead of them.

## Paths inside these scripts are wrong

Every script here was written to run from the repository root as
`Rscript scripts/indicator_*.R`, and they now live in `code/`. They also write
to `aq_maps/`, which is cleared periodically, and some read back files they
have just written. To run one:

```
Rscript dev/concepts/indicator/code/indicator_titlerow_v5.R
```

The one input they all need, `aq_maps/prepared/merton_no2_2019_2025.csv`, is
still present. Nothing else about them was changed when they moved, so treat
the paths in their comments as historical.

## What shipped

| File | What it shows |
|---|---|
| `code/indicator_titlerow_v5.R` | The final `title_row` placement across print, small print and interactive — the set that was signed off |
| `code/indicator_demo-maps_v1.R` | The five sign-off cases: pre-built path, lazy path, 4000px print, 900px print, switched off |
| `code/indicator_max-and-lead_v3.R` | The maximum as a diamond, and the figures moved under the legend title. Both shipped as `indicator.show_max` and `indicator.placement` |
| `code/indicator_placement_v4.R` | The two desktop placements side by side |
| `code/indicator_collision-demo_v1.R` | The measured collision rule, on a synthetic fixture. Merton's own network never triggers it, so this is the only demonstration of that rule working |
| `examples/indicator_merton-annual_v1.html`, `indicator_print-4000_v1.html`, `indicator_print-900_v1.html` | Rendered output of the sign-off set |

## Tested, not used

| File | The idea | Why it was set aside |
|---|---|---|
| `code/260730_indicator_track-style_v1.R` | A standalone track below the ramp | Drew a second scale beside the legend's own |
| `code/260731_indicator_bar-style_v1.R` | A zero-to-value bar over the ramp | Read as a quantity bar rather than a position |
| `code/indicator_ramp-variant_v1.R` | The bar prototype as first proposed (30 July) | Superseded by the roundel |
| `code/indicator_refinements_v2.R` | Thicker bar, dark cap, colour chip beside the figure | Refinements to an idea that was then dropped |
| `code/indicator_animations_v2.R` | Both styles animated, to judge the marker in motion | Comparison for a choice now settled |
| `examples/indicator_bar-*` (4 files) | Rendered bar style | — |
| `examples/indicator_uneven-ramp_v1.html`, `indicator_uneven-track_v1.html` | Both styles on an uneven ramp | — |

## Related, still open

`260730_limit-centred-indicator.md` — distance above or below a chosen target
instead of position on the scale. Needs a decision on which target sits at the
centre. Listed under "Tested ideas, but need more work" in CLAUDE.md.

## Documents

- `260729_overlays_feasibility.md` — the feasibility study the indicator came from
- `260730_indicator_ramp_variant.md` — the ramp proposal
- `260806_indicator_script-chain_v1.md` — the review summary that led to this folder

# Plan: LB Merton AQAP print set

Date: 2026-08-05. Brief from Iarla, with five decisions settled by MCQ before
any code was written. The output is going into the London Borough of Merton
Air Quality Action Plan, a legal document, so wording is part of the work
rather than a detail of it.

## The decisions, and why

| Question | Chosen | Note |
|---|---|---|
| Banner | Solid `#2a75d4` bar, white text | Matches the AQAP's own banner rather than merely accenting a white strip |
| Ramp colours | Unchanged from `lbm_no2` | The printed maps must agree with every Merton map already circulated |
| Pills | Kept; footnote symbols dropped | Each pill carries its band's colour, which is the link back to the ramp |
| Bands | All ten retained in the YAML | The legend still auto-trims to the data, so most years show seven |
| 20 µg/m³ target | Named from **both** sides | See below — this was the one real trap |

### The target-labelling trap

The brief asked for the 20 µg/m³ target on "the yellow pill". But the scale's
existing labels follow a consistent convention: each band is named for the
target it *meets*, so `10-19: WHO Int 3` sits below 20, `20-29: WHO Int 2` sits
below 30, and so on. Under that convention a 20 µg/m³ target is met by the
**green** 10-19 band, not the yellow one — putting "LB Merton target" on yellow
alone would have implied the opposite of the truth in a statutory document.

Resolved by naming the boundary from both sides: green reads "meets LB Merton
target", yellow reads "above LB Merton target". The 20 µg/m³ line is then
unambiguous whichever pill the reader looks at.

### One label reverted

`30-39` was briefly relabelled "below UK limit". True, but it reads as
reassurance about a band half again above Merton's own target, which is not a
thing for the AQAP to imply about itself. Reverted to the neutral
`UK/WHO interim 1`, matching `lbm_no2`. A test asserts no band claims
compliance with the UK limit.

## What was built

- `generate_legend_html()` honours `footnote_symbols` on a scale (default TRUE,
  so every existing scale is untouched)
- `inst/config/scales/lbm_aqap_no2.yaml`
- `scripts/clients/merton_print-set_v5.R` → `aq_maps/print_aqap_260805/`, seven images
  2019-2025 at 4000 × 3000
- `tests/testthat/test-aqap-print-scale-v1.R`, which asserts the wording and
  the 20 µg/m³ boundary, not just the mechanism

## Verification

Full suite 443 pass. All seven images confirmed 4000 × 3000. Legend, banner and
year label inspected at full resolution on both the lowest year (2024, mean
25.6, five bands) and the highest (2019, mean 44.1, max 65.0, seven bands).

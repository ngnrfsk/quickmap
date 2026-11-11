# Fix the deltas scale: colour assignment and legend overflow — plan

Issue: dev/261111_deltas_issue.md. Branch: `fix/deltas-scale`. Roadmap item 11
(open defects). Touches rendering (legend CSS), so the PR blocks on visual
sign-off.

## Findings before the fix

- Defect 1 reproduces as stated: `findInterval()` rejects the descending
  thresholds.
- The reorder alone would break two further places, both of which assume the
  lowest threshold is finite:
  - `build_lazy_payload()` drops every infinite threshold *and its colour*. With
    `-Inf` first, values below -8 (rise over 8) would draw in the no-data
    colour on maps above 50 steps.
  - `ramp_position()` computes `(v + Inf) / Inf` = NaN in a `-Inf` lower band,
    so an indicator marker in that band has no position.
- Defect 2 cause: `.ramp-label { flex: 1; white-space: nowrap; }` in both
  legend CSS files. A flex item cannot shrink below its unbroken text, so a
  label wider than its block (1/n of the ramp) pushes the label row past the
  ramp; labels have no gap, so they run together.
- Other scales are affected. Measured in headless Chrome, every scale, both
  CSS variants (script: scratchpad `measure_legends.R`, to be copied to
  `dev/deltas_legend-measure_v1.R`):

  | Viewport | Scales with a label wider than its block | Label row past the page edge |
  |---|---|---|
  | 1200 px | deltas (5 labels); 9 others (1 label, the trailing "Insufficient data") | none |
  | 600 px | deltas (6); lbm_no2, lbrut_no2, lbw_no2, who_no2 (5–6); 6 others (1–2) | deltas, lbm_no2, lbrut_no2, lbw_no2, who_no2, stripes_pm25 (12–42 px) |

## Changes

1. `inst/config/scales/deltas.yaml`
   - Thresholds ascending: `-.Inf, -8, -6, -4, -2, 0, 2, 4, 6, 8, .Inf`.
   - The 10 band colours and labels reversed to match; "Site not in use" /
     white stays last, as the missing-value entry every scale ends with
     (`assign_colour()` returns white for NA; the lazy payload's `naColour` is
     the last colour).
   - Labels state the closed end (bands include their lower bound; values are
     falls, so a rise's closed end is its upper figure):
     `Rise >8`, `Rise >6 to 8`, `Rise >4 to 6`, `Rise >2 to 4`, `Rise >0 to 2`,
     `Fall 0 to <2`, `Fall 2 to <4`, `Fall 4 to <6`, `Fall 6 to <8`, `Fall ≥8`.
   - New key `legend_order: descending` keeps the legend reading largest fall
     first.
2. `load_colour_scale()`: stop with
   `Colour scale 'x': thresholds must be in ascending order` when
   `is.unsorted(thresholds)`. Placed here rather than in `assign_colour()` so
   the legend, indicator and lazy path get the same error; `assign_colour()`
   reaches it on its first call. CLAUDE.md's "It does not validate" is
   corrected in the same change.
3. `legend_order: descending` (optional scale key, default ascending):
   `generate_legend_html()` reverses the band blocks and labels, not the
   trailing missing-value entry; `ramp_position()` takes `descending` and
   mirrors the position within the band region, so indicator markers stay on
   their band. Documented in CLAUDE.md "Colour scales" and
   vignettes/styling.Rmd if scales are covered there.
4. `build_lazy_payload()`: drop only `+Inf`; send a leading `-Inf` as
   `-1e300` (JSON has no infinity), so the bottom band keeps its colour.
5. `ramp_position()`: a band with an infinite bound sits at its midpoint
   (already the rule for the top band).
6. Legend CSS, both variants: `.ramp-label` gets `flex: 1 1 0; min-width: 0;
   white-space: normal; overflow-wrap: break-word;` so each label stays
   inside its block's width and wraps onto a second line when longer. A range
   like "40-49" breaks at its hyphen only when the block is narrower than the
   range text.

## Tests — `tests/testthat/test-deltas-scale-v1.R`

- `assign_colour()` on deltas: one value inside each of the 10 bands; every
  finite boundary (-8, -6, -4, -2, 0, 2, 4, 6, 8) gets the band above it;
  `NA` → white (the "Site not in use" colour).
- Descending thresholds stop with the ascending-order error (scale mocked via
  `local_mocked_bindings(load_yaml_config = ...)`).
- `generate_legend_html("deltas")` has one `.ramp-label` and one
  `.ramp-block` per label (11 each); first label is `Fall ≥8`, last is
  `Site not in use`.
- `ramp_position()` mirrors under `descending = TRUE` and returns a finite
  number in a `-Inf` band.
- `build_lazy_payload()` colours for deltas include the bottom band colour.
- Both legend CSS files: `.ramp-label` has `min-width: 0` and no `nowrap`.

## Verification

- Automated gate (testthat, `tests/test_quickmap.R`, DATA_PATH).
- Re-run the measurement script after the fix: 0 labels wider than their
  block and no row past the page edge, every scale, 1200 and 600 px.
- Demo maps (`output_dir = "aq_maps"`), script `dev/deltas_demo-maps_v1.R`:
  annual multi-year, sub-annual, schools with labels (all who_no2 or
  lbrut_no2, to show the CSS change on existing scales) and one deltas map
  built from year-on-year differences of a tube CSV, with a static JPG.

## Documentation

NEWS.md entry (v0.9.9.16, DESCRIPTION bumped); issue status line → fixed with
branch/PR; dev/PROJECT_STATUS.md open-defects and recent-work entries.

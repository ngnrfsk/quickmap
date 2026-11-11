# Scale "deltas": colour assignment fails, legend overflows — 2026-11-11

Status: fixed on `fix/deltas-scale` (v0.9.9.16, PR #60), awaiting visual sign-off — defects 20 and 21 in dev/PROJECT_STATUS.md; plan dev/261111_deltas_scale_fix_plan.md. Found with installed quickmap 0.9.9.15. No quickmap R code uses this scale.

## Defect 1: `assign_colour()` stops

`inst/config/scales/deltas.yaml` lists thresholds high to low (`.Inf, 8, 6, … , -8, -.Inf`). `assign_colour()` passes them to `findInterval()`, which requires ascending order:

```
Error in findInterval(value, thresholds, left.open = FALSE) :
  'vec' must be sorted non-decreasingly and not contain NAs
```

Every other scale lists thresholds in ascending order.

The 11 thresholds bound 10 bands. The 11th colour and label (white, "Site not in use") are a missing-value category, not a band. A full reversal of the three lists would therefore colour the "increase over 8" band white.

Required:
- Put the thresholds in ascending order.
- Reverse the 10 band colours and labels to match.
- Treat "Site not in use" as the NA colour.
- `assign_colour()` stops with a clear error on descending thresholds.

Bands include their lower bound: a fall of exactly 8 is ">8", and 0 is "0-2" fall. The labels should state this.

## Defect 2: legend overflows

With `build_legend_css(image_mode = TRUE)`, `generate_legend_html("deltas", collapsed_mobile = FALSE)` renders the labels as one unbroken string wider than the page. Cause not investigated.

Check:
- whether other scales are affected;
- that the legend order (largest fall first) survives the YAML reorder.

## Reproduce

```r
library(quickmap)
quickmap:::assign_colour(3, scale = "deltas")                              # defect 1
html <- quickmap:::generate_legend_html("deltas", collapsed_mobile = FALSE) # defect 2: render with build_legend_css(image_mode = TRUE)
```

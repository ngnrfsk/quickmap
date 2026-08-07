# quickplot — seed of a separate package

**Not part of QuickMap.** QuickMap is a mapping tool. These are charts and
tables that borrow its page furniture (banner, legend, colour scales) so that
figures and maps read as one document. They live here, in their own folder, so
it is obvious they are the start of something separate rather than part of the
package. `.Rbuildignore` excludes this folder, so nothing here ships.

Dependency runs one way: quickplot uses quickmap, never the reverse.

## Where this is going (decision, 2026-08-06)

This repo stays named `quickmap` until QuickMap 1.0 ships — the repo name
should match the package being published. When quickplot is real it gets its
own repo, rather than this one becoming an umbrella over both. The shared
chrome moves into a third package only if maintaining it in two places starts
to hurt; until then quickplot depends on quickmap for it.

The repo was briefly renamed `quickplot` on 6 August and reverted the same day.

## The three functions, named

| Name | What it is | Prototype |
|---|---|---|
| **Heatmap** | Colour-coded table, one row per site, one column per year | `ecs_trends-table_v2.R` |
| **Trend** | Time series over the colour ramp as background bands | `merton_pm10-charts_v2.R`, chart 1 |
| **Exceedance** | Counts against a permitted allowance | `merton_pm10-charts_v2.R`, chart 2 |

## Running them

From the repo root:

```
Rscript quickplot/merton_pm10-charts_v2.R
Rscript quickplot/ecs_trends-table_v2.R
```

All three export at 4000 x 3000 to `aq_maps/`, matching the AQAP maps.

## What they share with QuickMap

`build_banner_css()`, `build_legend_css()`, `generate_legend_html()`,
`load_colour_scale()`, `assign_colour()`, `get_contrast_text_color()`, and the
colour scales in `inst/config/scales/`. That shared chrome is why a fork is
cheap and why the figures match the maps.

Colour scales stay in QuickMap: `lbm_aqap_no2.yaml` (also used by the maps) and
`lbm_aqap_pm10.yaml`.

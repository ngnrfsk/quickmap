# Canonical comparison test set: LB Merton AQAP scripts

Real, multi-layer, previously-delivered client workload, used to regression-test
`quickmap()` changes beyond what testthat's synthetic fixtures cover. Established
2026-08-18 after item 9 shipped with only structural unit tests and no real-data
check.

## Where it lives — deliberately outside this repo

- **Baseline (never modified)**: `/Users/iarla/Coding/260814 Merton AQAP maps and
  figures refresh/`. The original, already-delivered output plus the five scripts
  that made it (`scripts/merton_animation_v1.R`, `scripts/merton_print-set_v6.R`,
  plus `v5`, and two non-`quickmap()` quickplot prototypes). Its own `README.md`
  documents the folder in full.
- Kept external, not committed: it's ~real client data and ~30MB of generated
  HTML/JPG, both reasons the repo already gitignores `aq_maps/` and `docs/`. Item
  9.5 also plans moving client scripts out of the package entirely — copying this
  set back into `tests/` would run against that decision. The comparison tool
  below takes external paths as arguments instead.

## Procedure: regression-test a change against this set

1. Reinstall `quickmap` from the branch under test (`devtools::install()`).
2. Duplicate the whole baseline folder to a fresh, dated sibling —
   `cp -R "260814 Merton AQAP maps and figures refresh" "<date> Merton AQAP
   <label>"`. Never edit the baseline itself.
3. In the duplicate, `merton_animation_v1.R` and `merton_print-set_v6.R` both
   hardcode the pre-installable-library `aq_maps/` convention (reading/writing
   `aq_maps/prepared/...`; `print-set_v6.R` also sweeps `aq_maps/` afterward via
   `list.files()` + `file.rename()`). The duplicate's actual layout is
   `prepared/`, `animations/`, `print_packs/` at top level, so both scripts need:
   - `aq_maps/prepared/...` → `prepared/...` (unconditional, unrelated to the API
     under test).
   - An explicit `output_dir` matching each script's real output folder
     (`"animations"` for the animation script; `"print_packs"` for the print
     set, replacing every `"aq_maps"` string in its sweep/`out` logic too).
4. Run each script. `merton_print-set_v6.R` only needs the `nobg` and `nolabels`
   variants (the two actually delivered); `plate` and `v5` are superseded.
5. Compare: `python3 dev/260818_html_dom_compare_v1.py <baseline-dir>
   <duplicate-dir>` for the animation HTML (structural DOM + payload diff — see
   that script's docstring). No automated equivalent exists yet for the print
   pack's JPGs; compare those by eye against `samples/` (no full 7-year `nobg`/
   `nolabels` set existed before this procedure was first run, only single-year
   samples — see the baseline's own `README.md`).
6. Record the outcome in `dev/PROJECT_STATUS.md`.

## First run (2026-08-18, `feature/item9-output-paths`)

Found and confirmed a real regression before fixing it: `merton_print-set_v6.R`
run unmodified (path-fixed only, `output_dir` fix not yet applied) reported
`nobg : 0 images` — item 9 removed the implicit `aq_maps/` default the script's
sweep relied on. Fixed per step 3 above, re-run produced 7 JPGs × 2 variants as
expected. `merton_animation_v1.R` needed no such fix (no sweep), just the
`output_dir` addition for tidiness. `dev/260818_html_dom_compare_v1.py` confirmed
all three animation HTML files structurally identical to the baseline (banner,
legend, time-slider chrome, and the embedded leaflet payload's call sequence and
marker counts). Iarla confirmed all outputs pass visual inspection.

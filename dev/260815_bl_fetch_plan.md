# Breathe London fetch plan (with roadmap additions and tidy-up record)

Canonical copy of the plan drafted 2026-08-15 (originally in the Claude Code
plan-mode scratchpad; moved here per the dev/ plan convention). Part 0 is
done and recorded below; Parts A and B execute on branch
`feature/breathe-london-fetch`, each ending at a STOP.

## Context

The Breathe London API has been replaced (terms effective 23 June 2025): new
gateway URL, `X-API-KEY` header auth, `/ListSensors` + `/SensorData` endpoints
with query parameters, pollutant names `NO2`/`PM25`, hourly-only responses,
366-day request window. Existing fetch functions (in
`/Users/iarla/Coding/Library/R/api.R`, `openair_breathe_london_1_0.R`, and the
iCloud `Breathe_London_package_v1_0.R`) target the old API. The A02 download
scripts state a 75% data-capture rule for period means but do not apply it;
`convert_openair_to_spatial()` (`R/quickmap.R`, aggregation around line 350)
also aggregates with `mean(na.rm = TRUE)` and no capture threshold.

User decisions (2026-08-15, by MCQ): fetch code lives in the quickmap package;
fetch is **pre-1.0**, reconciliation of the old copies is **post-1.0**; the
old API gets a **probe first**, not a maintained legacy path.

## Part 0 — tidy-up of the 4–14 August Merton work — DONE 2026-08-15

As executed (the drafted version cited "PR #37" from a stale memory; the
open PRs were #47 print set and #48 manual):

- Created `/Users/iarla/Coding/260814 Merton AQAP maps and figures refresh/`
  and MOVED into it: the five client scripts (print-set v5/v6, animation,
  two quickplot figures) and everything in `aq_maps/` except the manual
  examples (`example_*_260805.*`) and speed demos (`speed_*_v3.html`),
  organised as scripts/ print_packs/ animations/ figures/ samples/
  prepared/, with a README recording provenance and the two caveats
  (CLDP0239 2021 = 93 µg/m³; BL attribution required on published maps).
- Deleted `debug_0926b_*` and `quickmap.html` from `aq_maps/`.
- **PR #49** (fix/school-legend-labels): v0.9.9.12 — banner key displays the
  scale's `labels`; schools.yaml reads "Primary School / Secondary School";
  issue 14 recorded in PROJECT_STATUS; v5 + quickplot scripts removed from
  the repo.
- **PR #47 closed unmerged** (client scripts leave the package repo; the
  package-code bugs found during that work were already merged via #44/#42).
  v6 also removed from PR #48's branch, whose PROJECT_STATUS checklist was
  brought up to date. Merge order: **#49 before #48** (both touch
  PROJECT_STATUS).
- **PR #50** (chore/merge-approval-hook): merging now requires formal
  human approval at a permission prompt (`confirm-merge.sh`), replacing the
  prose-only "never merge" rule.
- Remaining user actions: review/merge #49, #48, #50; upload the three
  `LBM_*_latest.html` maps to swlonrsp.github.io with the BL attribution;
  run `dev/260705_permissions_pretest.md` before the next autonomous
  session (permissions changed in #50).

## Part A — roadmap edits (documentation only)

**File: `CLAUDE.md`** (run `tests/testthat/test-consistency.R` after editing):

1. Insert a new pre-1.0 roadmap item, executed after item 9 and before
   item 11, following the existing dated-insertion convention:
   **"Breathe London fetch for the new (2025) API"** — summary of the design
   in Part B, noting it is blocked on an approved API key.
2. Add a **post-1.0** entry: **"Fetch-code reconciliation"** — mark the
   superseded Breathe London fetch/processing copies as historical
   (`Library/R/api.R`, `Library/R/openair_breathe_london_1_0.R`, the iCloud
   `Breathe_London_package_v1_0.R`, `ScriptArchive` A-scripts,
   `250120_RSP_BL_download` scripts), with quickmap's `from_*()` family as
   the sole maintained fetch surface. Move the API/Stadia keys hardcoded in
   `A01_startup_250417_RSP_BL_download.R:43-44` to `.Renviron` during that
   cleanup.
3. Add a third entry, **"Package/workspace separation"**, pre-1.0 under
   item 9 (CRAN compliance in substance): the repo is currently half
   package, half the user's production workspace, and the two must part
   before release: (a) `quickmap()`'s default output location becomes an
   explicit `output_file` path or `tempdir()` — a package auto-creating
   `aq_maps/` in the working directory is a CRAN policy violation;
   (b) client production scripts (`scripts/clients/`) and their
   prepared-data pattern move to a separate workspace repo, keeping only
   generic examples in `inst/examples/`; (c) the demonstration-map and
   baseline sign-off conventions are re-stated against the workspace, not
   the package repo. The workspace move itself can complete post-1.0
   provided the package no longer depends on it.

**File: `dev/PROJECT_STATUS.md`**: matching entries, one line each, in the
current-state sections.

**STOP — end of Part A.** Show the user the roadmap text as added (all three
entries), confirm `test-consistency.R` is green, then stop and wait for
approval before starting Part B.

## Part B — the fetch work (design; NO CODING until user approves)

### Step 0 — probes (before any code)
- One-off probe of the old API (single `ListSensors` call with the key from
  `A01_startup_250417`): record alive/dead in the dev doc. Either way, no
  legacy code path is built; saved Rdata files remain the historical-data
  source.
- User registers for a new API key via breathelondon.org/developers
  (GLA approval required — the live steps below wait on this).
- With the key: probe `/ListSensors?Borough=Merton` and one `/SensorData`
  site-week to confirm response fields — in particular whether `CLDP0xxx`
  codes are retained or replaced by `BL0xxx`, and the `RatificationStatus`
  values.

**STOP — end of Step 0.** Report the probe results (old API alive/dead, new
API response fields, site-code scheme), then stop and wait for the user
before writing any code.

### Step 1 — new file `R/breathe_london.R` (three exported functions)

Follow the `from_worldmet()` pattern (`R/wind.R:25`) — fetch + convert in one
family:

- `bl_sensors(borough = NULL, site = NULL, ...,
  key = Sys.getenv("BREATHE_LONDON_KEY"))` — wraps `/ListSensors`, returns
  the metadata tibble. The key is a parameter defaulting to the env var
  (standard CRAN API-package idiom: explicit override possible, `.Renviron`
  for regular use, no keys in scripts); `bl_data()` takes the same argument.
- `bl_data(sites | borough, start, end, species = c("NO2", "PM25"))` — wraps
  `/SensorData`; chunks requests to the 366-day window (one request per
  site-year where needed); retries with backoff on 429/5xx (retry loop shape
  as in `get_bl_measurements_new`); returns an hourly long-format tibble with
  quickmap's contract columns (`siteCode`, `date`, `no2`, `pm25`, `lat`,
  `lon`).
- `from_breathelondon(...)` — `qm_layer` wrapper: calls the two above,
  applies QA + aggregation (Step 2), returns a `qm_layer` with
  `shape = "diamond"`, parallel to `from_openair()` (`R/qm_layer.R:410`).

Dependencies: `httr` (or base `curl`) + `jsonlite` at Suggests level, as for
`openair`/`worldmet`, with a `requireNamespace()` guard.

**STOP — end of Step 1.** Show the three function signatures as implemented
and the result of a live `bl_sensors()`/`bl_data()` call, then stop and wait
for the user before Step 2.

### Step 2 — QA and aggregation (shared functions)

- Hourly plausibility screen as an internal function: NO2 ≥ 500 → NA,
  PM2.5 ≥ 130 → NA (the A02 thresholds, applied before averaging).
- Completeness-aware aggregation: annual/monthly means require ≥ 75% capture,
  else NA. Implement once; wire into both the new BL path and
  `convert_openair_to_spatial()` (parameter `data_capture = 0.75`, applied by
  default). Flag in the PR that annual means computed through this path can
  differ from previously published values.

**STOP — end of Step 2.** Show a before/after comparison of Merton annual
means with the 75% rule applied (naming any sites/years that become NA or
change), then stop and wait for the user before Step 3.

### Step 3 — tests

- `tests/testthat/test-breathe-london-v1.R`: unit tests with canned JSON
  fixtures (no network): URL/parameter construction, 366-day chunking,
  header auth, QA thresholds, the 75% rule (a year at 60% capture → NA),
  and `from_breathelondon()` returning a valid `qm_layer`.
- Live smoke test behind `skip_if(Sys.getenv("BREATHE_LONDON_KEY") == "")`.

**STOP — end of Step 3.** Report the test results (full suite green), then
stop and wait for the user before Step 4.

### Step 4 — attribution

The API terms require the statement "Contains Breathe London data licensed
under the Open Government Licence v3.0", linked to breathelondon.org, on
published outputs. Add it to the map chrome when a BL layer is present
(candidate position: legend or banner footer, smallest text; settled at
implementation). The already-published site maps need the same statement,
independent of this work.

**STOP — end of Step 4.** Show the attribution placement on a rendered map
for visual sign-off, then stop and wait for the user before the final
verification/PR stage.

### Out of scope
- Rewriting the Library repo / ScriptArchive copies (post-1.0 reconciliation).
- Met-data join, polar plots, exceedance statistics from A02/A03.
- Re-verifying the existing `bl_imperial_annualised_*` files.

## Verification

1. `Rscript -e 'library(quickmap); testthat::test_dir("tests/testthat")'` —
   green, including the new fixture tests.
2. `tests/testthat/test-consistency.R` green after the CLAUDE.md edits.
3. With a key: a demo script fetches Merton sensors for one recent year and
   builds a map via `quickmap(from_breathelondon(borough = "Merton", ...))`;
   compare marker counts and values against the map built 2026-08-14 from
   `bl_imperial_annualised_2021_2025_to_250422.Rdata` (archived in the AQAP
   working folder's `animations/`), accounting for the 75% rule and any
   data differences between the APIs.
4. Human visual check of the demo map (rendering-touching → blocks on
   sign-off per the autonomous rules).

## Execution notes

- Branch: `feature/breathe-london-fetch`; the Part A roadmap edits and this
  plan file are its first commit.
- Blocked on: the new API key (Step 0). Part A and the fixture-tested code
  skeleton can proceed without it; the live probe, smoke test and demo map
  cannot.

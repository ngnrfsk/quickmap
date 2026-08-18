---
editor_options:
  markdown:
    wrap: 80
---

# QuickMap Project Status

**Last Updated**: 2026-08-17 **Current Version**: v0.9.9.13

Version history: NEWS.md. History before 2026-08-16:
dev/archive/PROJECT_STATUS_history_to_260816.md.

--------------------------------------------------------------------------------

## Where the project stands

- Close to v1.0. Roadmap items 9, 11, 12, 13 and 14 remain. Item 9 is in
  progress: 9.1, 9.3 and 9.8 done on `feature/item9-output-paths`, awaiting
  visual sign-off; 9.2 and 9.4 to 9.7 remain.
- Four PRs open, three waiting on Iarla, plus the item 9 branch to raise.

## Waiting on Iarla

1.  **Review the manual** on `feature/item9-output-paths`, built at
    file:///Users/iarla/Coding/quickmap/docs/index.html. It now carries PR
    #48's chapters, PR #52's example maps and item 9's API, so **PRs #48 and
    #52 are superseded by that branch** — close them when it merges, or say
    if you would rather they stayed separate.
2.  **Review PR #50** — merging now asks for approval at a prompt.
3.  **Switch on GitHub Pages**: settings → Pages → main branch, `/docs`. The
    chapters embed their maps from the hosted site (12.6 MB of maps against
    CRAN's 5 MB, so they cannot ship inside the package), which means the
    embeds are blank anywhere but the local build until Pages answers.
    Turning it on also needs `docs/` committed — that is PR #52's change, and
    the item 9 branch deliberately does not carry it.
4.  **Get a Breathe London API key** at breathelondon.org/developers. Put it in
    `~/.Renviron` as `BREATHE_LONDON_KEY`. Unblocks PR #51.
5.  **Upload three maps** to swlonrsp.github.io from
    `/Users/iarla/Coding/260814 Merton AQAP maps and figures refresh/animations/`.

--------------------------------------------------------------------------------

## Roadmap

Items are never renumbered; other documents cite these numbers.

**Done:** 1 packaging (v0.9.5), 2 characterization tests, 3 qm_layer, 4
`quickmap()` API (v0.9.6), 5 backend decision, 6 lazy loading (v0.9.7), 7 wind
(v0.9.8), 8 examples, 10 UI polish (v0.9.9.5).

### 9. CRAN compliance and internal consistency — in progress

1.  **Done (v0.9.9.13).** Output paths: no auto `aq_maps/`; the user names the
    file. `output_file` required, `output_dir` and `quickmap.output_dir` added.
    dev/260816_output_paths_decision.md.
2.  `R CMD CHECK` clean: dev/260708_item9_check-baseline_v1.md.
3.  **Done (v0.9.9.13).** Renamed `marker_labels` to `symbol_labels`; the old
    name works with a warning, at the API and in a theme file's
    `map.marker_labels`.
4.  Defects and roadmap to GitHub Issues, plus DESCRIPTION `URL:`/`BugReports:`.
    Steps 2 and 3 of dev/260816_item9_status_restructure_plan.md.
5.  Client scripts move to a workspace repo; `inst/examples/` keeps generic
    ones. May finish post-1.0 if the package no longer depends on them.
6.  Four `sapply()` calls to `vapply()`; the live one is in
    `create_generic_icons()`, around R/quickmap.R:3092.
7.  Audit docs against code; mark dev docs current or historical.
8.  **Done (v0.9.9.13).** `shorten_school_names()` brought into the package
    from the Merton print script, as `qm_layer(shorten_labels =)` and
    `from_csv(shorten_labels =)`, defaulting FALSE. Schools only; the
    vocabulary for other place types is post-1.0. Added 2026-08-17 after the
    demonstration map showed full school names — the shortening had never been
    in the package.

### 11. Clear the open defects — last item before release

1.  The list is "Open defects" below. Not to be picked off piecemeal.
2.  Marker/text scaling was done early on 2026-08-05.

### 12. Breathe London fetch for the 2025 API — after 9, before 11

1.  `bl_sensors()`, `bl_data()`, `from_breathelondon()` built and fixture-tested
    on PR #51 (draft). Blocked on the API key.
2.  The 75% capture rule voids 117 of 345 Merton site-years, including every raw
    mean above 60 µg/m³. Survivors differ from published values by up to 16.5
    µg/m³, unexplained.
3.  Remaining: live probes, and licence attribution in the chrome (needs visual
    sign-off). dev/260815_bl_fetch_plan.md.

### 13. Retest the alternative stacks

1.  README and the "For R users" vignette state July 2026 conclusions publicly.
    tmap v4 now builds on mapgl.
2.  Three grounds must be re-tested, not assumed: self-contained animated HTML; per-layer
    symbols on one scale in both outputs; one emailable file.
3.  dev/260706_atomic_unit_recommendation.md. The July benchmark document
    was deleted on 2026-08-17: its conclusions survive in
    dev/archive/PROJECT_STATUS_history_to_260816.md, and the numbers behind
    them in `git show 4b4d0d4:dev/item5_backend-comparison_v1.md`. The retest
    reruns the measurements rather than reading them off, so nothing is
    blocked by the deletion.

### 14. Rename the dev/ documents by date

1.  Three naming conventions coexist, so the folder cannot be read in order.
2.  Rename to `YYMMDD_name_vN.md`, update references, grep for old names.
3.  Known stale reference: dev/260816_output_paths_decision.md:67.

### 15. Squash the repo: scrub personal email history — in progress 2026-08-18

1.  209 commits across every branch, including `main`, carried
    `iarla.kilbane-dawe@merton.gov.uk` (a workplace address that should never
    have been used) or `iarlakd@gmail.com` in the commit author field. Fixed
    by rewriting every commit's author/committer identity via `git
    filter-repo` with a mailmap, to `ngnrfsk@users.noreply.github.com`, then
    force-pushing every branch — `main` included, overriding the standing
    "never push to main" rule with Iarla's explicit sign-off, since `main`
    carries no GitHub branch-protection rule.
2.  Not covered: `DESCRIPTION`'s `Authors@R` still names `iarlakd@gmail.com`
    as file content, not commit metadata — untouched by the rewrite, and
    outside GitHub's control if published to CRAN. Flagged, not yet decided.
3.  Every commit SHA in the repo changed. The two SHAs cited elsewhere in
    project docs (`4b4d0d4`, `686e174`) were captured before the rewrite;
    anything else citing an old SHA is now stale.
4.  Of 13 non-`main` branches, only 3 have live purpose (open PRs #50, #51,
    plus `feature/item9-output-paths`); the other 10 have no open PR and are
    candidates for deletion once confirmed merged or abandoned.

### Numbering history

Items 2 and 5 inserted 2026-07-05; item 10 on 07-06, renumbering UI defects to
11; items 12–14 on 08-15/16. Earlier dev docs use the old numbering.

--------------------------------------------------------------------------------

## Post-1.0

- **quickplot**: Heatmap, Trend, Exceedance figures on QuickMap's chrome. Own
  repo after 1.0. `quickplot/README.md`.
- **Ecosystem integrations**: ERA5 via ecmwfr, saqgetr, OpenAQ, Mazama
  AirMonitor, stars/terra underlays. Each a `from_*()` wrapper.
  dev/260707_v2_integration_candidates.md.
- **Fetch-code reconciliation**: superseded BL copies outside this repo marked
  historical; hardcoded keys in `250120_RSP_BL_download` move to `.Renviron`.
- **Wind styling presets**: preset ramps, speed-scaled width and opacity, per
  theme. Theme YAML only.
- **Place types beyond schools**: extend the label shortening to hospitals, GP
  surgeries and similar. Each has its own vocabulary ("NHS Foundation Trust",
  "Surgery", "Medical Centre"), so it wants a YAML place-type config carrying
  the column gate, the category vocabulary and the suffix list. That also
  absorbs the four places where `School` is hardcoded as the duck-typing gate
  (R/qm_layer.R:223, 342, 364; R/quickmap.R:3410). Decided 2026-08-17 to keep
  1.0 schools-only rather than widen the data format mid-item 9.
- **Tile-dependent particle density**: 1/300 suits OSM; CartoDB.Positron needs
  about 0.00125. Default should follow the tiles.

--------------------------------------------------------------------------------

## Open defects

Cleared at item 11. Ids provisional until migrated to GitHub Issues.

- **8. Subfolder generation.** Static export leaves leaflet JS subfolders.
- **9. Marker, text and legend sizing.** No unified scaling system; marker
  labels fixed 2026-08-05.
- **10. Label consistency.** Ward and marker labels differ between static and
  interactive.
- **11. Background CPU and memory.** Maps animate when hidden. Pause particles,
  crossfades and autoplay on `visibilitychange` and off-viewport.
- **12. Image export unreliable.** chromote startup times out mid-batch; retry
  each webshot call.
- **13. Sub-annual limit values.** The indicator hides below annual resolution;
  needs resolution-aware targets in the YAML. Post-1.0.
- **14. Fixed panel unexplained.** "Network mean, N sites" counts fewer sites
  than are on screen; add a tooltip.
- **15. Split import from map creation.**
- **16. Automate label placement**, clustering and spread. Includes reducing
  label clashes and overlaps generally (added 2026-08-17); shortening school
  names (item 9.8) buys width but does not place anything.
- **LCA-1/2/3.** Collapsible radio buttons bottom-left; open at a zoom filling
  the screen; choose the layer visible on load.

--------------------------------------------------------------------------------

## Concepts — recorded, not scheduled

Index, documents, code and demonstration maps: dev/concepts/README.md.

- **Limit-centred indicator**: distance above or below a target, not position on
  the scale. Needs a decision on which target centres it.
- **Change-over-time graph**: sparkline of the network mean. Overlaps
  quickplot's Trend; settle ownership. 1.5–2 days.
- **Thermometer on the map**: vertical indicator over the map. Only if it
  restates the legend's bands.
- **Context polygon layer**: deprivation under the vignette, labelled 1–10. \~2
  days.
- **Retired indicator styles**, with restoration instructions in the files:
  zero-to-value bar (`260731_indicator_bar-style_v1.R`), standalone track
  (`260730_indicator_track-style_v1.R`).

--------------------------------------------------------------------------------

## Recent work

- **17 August (later)**: the manual folded onto `feature/item9-output-paths` —
  PR #48's five rewritten chapters and front page, PR #52's 17 example maps and
  README, and item 9's `output_file`/`symbol_labels` reconciled across them.
  Fixed while doing it: `generate_legend_html()` had no roxygen block, which
  stops pkgdown building the reference index at all; three chunks called
  `quickmap()` with no `output_file`, which has been an error since 9.1;
  `test-item9-school-labels-v1.R` called an internal function unqualified, so
  six tests errored; and the chunk harness wrote its maps into the repository
  root, which PR #52's narrower `.gitignore` no longer hides. 526 tests pass,
  the chunk harness is ALL OK, and the built site has no broken local link.
- **17 August**: items 9.1 and 9.3 built on `feature/item9-output-paths`
  (v0.9.9.13). Two filename defects fixed in passing: the per-step JPG loop
  dropped any directory the caller gave, and put the raw time step in the
  filename, so a sub-annual step wrote spaces and colons into a path. PR #48
  (the manual) is released for review once this merges; PR #51 needs a rebase.
- **16 August**: project record split by content type — history to NEWS.md and
  the archive, roadmap and defects here, decisions to dev/ citations. Output
  paths decided (dev/260816_output_paths_decision.md), which holds PR #48.
- **15 August**: v0.9.9.12 merged (PR #49, banner key reads `labels`). Item 12
  fetch code built on PR #51. Items 13 and 14 added. Merton AQAP work moved out
  of the repo.
- **5 August**: speed control (PR #42) and legend indicator (PR #38) merged,
  both signed off. `.gitignore` was excluding `inst/controls/time-slider.html`,
  so a fresh clone could not build a map.
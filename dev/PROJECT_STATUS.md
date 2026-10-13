---
editor_options:
  markdown:
    wrap: 80
---

# QuickMap Project Status

**Last Updated**: 2026-10-13 **Current Version**: v0.9.9.13

Version history: NEWS.md. History before 2026-08-16:
dev/archive/PROJECT_STATUS_history_to_260816.md.

--------------------------------------------------------------------------------

## Where the project stands

- Close to v1.0. Roadmap items 9, 11, 12, 13 and 14 remain. Item 9 is in
  progress: 9.1, 9.3, 9.8 and 9.9 done on `feature/item9-output-paths`, 9.9's
  real-data visual sign-off given 2026-08-18; 9.2 and 9.4 to 9.7 remain.
- Two PRs open (#53, #51), both waiting on Iarla. PR #50 (merge-approval hook)
  merged 2026-08-19. PRs #48 and #52 closed; their content is on
  `docs/manual-v2`, not in #53.

- **Urgent, added 2026-10-13: items 16 and 17.** Order of work: PR #53 conflict
  → 16 → 17 → 12 → 11 → 18. Neither is stacked on another unreviewed item: 16
  changes no package code, 17 branches from `main` once #53 has merged.

## Steer

- 2026-10-13: items 16 (rebuild the swlonrsp.github.io maps) and 17 (GIF
  export) go ahead of items 12 and 11, as urgent.
- 2026-10-13: copyright holder stays Iarla Kilbane-Dawe for now. Iarla owns
  the code and intends to sell it to Par Hill Research Ltd; the working-tree
  edits naming the company were reverted. At the sale, in its own PR: add
  `person("Par Hill Research Ltd", role = "cph")` to `Authors@R` in
  `DESCRIPTION`, set `COPYRIGHT HOLDER` in `LICENSE` to the company, and
  regenerate `man/quickmap-package.Rd`.
- 2026-10-13: the v0.9.9.7 API catalogue is archived, not deleted, at
  dev/archive/260712_api_catalogue_v1.md, marked historical. A new API guide
  is item 18.
- 2026-10-13: the lone rename of dev/20250118_geojson_option_d_design.md was
  undone; item 14 renames every dev/ document in one PR.
- 2026-10-13: architecture diagrams (dev/archviz_*) go on their own branch,
  `docs/architecture-diagrams`: scripts, plan and README tracked, rendered
  outputs ignored. Their ten documentation findings are open defects DOC-1 to
  DOC-10.
- 2026-10-13: dev/260819_status_checklist_v1.md deleted; its task-to-PR table
  is under "Which PR each open task belongs to" below.
- 2026-10-13: the manual leaves PR #53. There is no time for the full
  read-through and the text is out of date. It is held on `docs/manual-v2`
  (PR #53's tip before the split, d0c52db). PR #53 keeps the code, tests, help
  pages, dev/ documents and the chapter edits from its first two commits that
  keep code chunks matching the API. Item 9.2 also leaves #53 for its own PR.
- 2026-10-13: PR #53 must be squash-merged. Its branch history still holds the
  17 example maps (12.6 MB), added then removed; a merge commit would put them
  in `main`'s history.

## Waiting on Iarla

1.  **Review PR #53, then name it for merging (squash)** — output paths,
    `symbol_labels` rename, `shorten_labels`. Code only since 2026-10-13; the
    visual sign-off is the one given on 2026-08-18 for item 9.9.
2.  **Read the manual**, on `docs/manual-v2`, after it has been brought up to
    date. No deadline. It carries PR #48's chapters, PR #52's example maps and
    README.md, which `main` does not have.
3.  **Switch on GitHub Pages**, after the manual merges: settings → Pages → main branch, `/docs`. The
    chapters embed their maps from the hosted site (12.6 MB of maps against
    CRAN's 5 MB, so they cannot ship inside the package), which means the embeds
    are blank anywhere but the local build until Pages answers. Turning it on
    also needs `docs/` committed — that was PR #52's change; no open branch
    currently carries it.
4.  **Get a Breathe London API key** at breathelondon.org/developers. Put it in
    `~/.Renviron` as `BREATHE_LONDON_KEY`. Unblocks PR #51.

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
8.  **Done (v0.9.9.13).** `shorten_school_names()` brought into the package from
    the Merton print script, as `qm_layer(shorten_labels =)` and
    `from_csv(shorten_labels =)`, defaulting FALSE. Schools only; the vocabulary
    for other place types is post-1.0. Added 2026-08-17 after the demonstration
    map showed full school names — the shortening had never been in the package.
9.   **DONE (PR#53)** Retested API changes to correct paths against real client
    scripts (LB Merton AQAP maps), not just synthetic tests. Found and fixed a
    real bug: `merton_print-set_v6.R` relied on the removed automatic `aq_maps/`
    folder, silently producing zero output. Built a structural HTML comparison
    tool to verify the fix; confirmed regenerated maps visually. *This was
    rolled into PR #53 ("Require output_file, rename marker_labels, merge
    shorten_labels; manual corrected to match") along with the rest of the work
    of `9 CRAN Compliance`*

### 11. Last before release: clear open defects, add some trivial, but essential features

1.  **Create a small set of routines to extract a table of diffusion tube data**
    from a standard Defra Excel template sheet \[\*\*stretch goal\*\* and from a
    historic ASR PDF or Word document\].
2.  Check whether removing the symbols from the legend pills is a simple to use
    flag
3.  **Create a simple selector when outputting images** for print quality (e.g.
    something like an A4 shaped rectangle with 300dpi) or email quality (e.g. 72
    dpi).
4.  The quickmap default data directory is a poor choice - that needs to be an
    ENV selection for standing situations, or else just defaulting to pickup up
    the data in the working directory.
5.  Clear the list of "Open defects" below. Not to be picked off piecemeal.
6.  Marker/text scaling was done early on 2026-08-05.

### 12. Breathe London fetch for the 2025 API — after 9, before 11

1.  `bl_sensors()`, `bl_data()`, `from_breathelondon()` built and fixture-tested
    on PR #51 (draft). Blocked on the API key.
2.  The 75% capture rule voids 117 of 345 Merton site-years, including every raw
    mean above 60 µg/m³. Survivors differ from published values by up to 16.5
    µg/m³, unexplained.
3.  **Attribution and credit approved by Iarla, 2026-08-15**, on the demo map
    (`scripts/demos/bl-attribution_demo_v1.R` →
    `aq_maps/item12_bl-attribution_v1.html`) — recorded in PR #51's description,
    not previously here. Three credits: the Breathe London licence statement
    under the legend key; a software credit ("QuickMap \| Leaflet") via the new
    `map.credit` theme key, default `TRUE`; source metadata naming the installed
    version. Remaining: only the live-API probes, blocked on the API key.
    dev/260815_bl_fetch_plan.md.

### 13. Retest the alternative stacks

1.  README and the "For R users" vignette state July 2026 conclusions publicly.
    tmap v4 now builds on mapgl.
2.  Three grounds must be re-tested, not assumed: self-contained animated HTML;
    per-layer symbols on one scale in both outputs; one emailable file.
3.  dev/260706_atomic_unit_recommendation.md. The July benchmark document was
    deleted on 2026-08-17: its conclusions survive in
    dev/archive/PROJECT_STATUS_history_to_260816.md, and the numbers behind them
    in `git show 4b4d0d4:dev/item5_backend-comparison_v1.md`. The retest reruns
    the measurements rather than reading them off, so nothing is blocked by the
    deletion.

### 14. Rename the dev/ documents by date

1.  Three naming conventions coexist, so the folder cannot be read in order.
2.  Rename to `YYMMDD_name_vN.md`, update references, grep for old names.
3.  Known stale reference: dev/260816_output_paths_decision.md:67.
4.  `20250118_geojson_option_d_design.md` becomes `250118_…`: its header gives
    the date as 2025-01-18. Cited at CLAUDE.md:227 and
    dev/260705_rendering_backend_candidates.md:66. Its header also says "not
    implemented"; lazy rendering shipped in v0.9.7, so correct that line in the
    same change.

### 15. Squash the repo: scrub personal email history — in progress 2026-08-18

1.  209 commits across every branch, including `main`, carried
    `iarla.kilbane-dawe@merton.gov.uk` (a workplace address that should never
    have been used) or `iarlakd@gmail.com` in the commit author field. Fixed by
    rewriting every commit's author/committer identity via `git filter-repo`
    with a mailmap, to `ngnrfsk@users.noreply.github.com`, then force-pushing
    every branch — `main` included, overriding the standing "never push to main"
    rule with Iarla's explicit sign-off, since `main` carries no GitHub
    branch-protection rule.
2.  `DESCRIPTION`'s `Authors@R` named `iarlakd@gmail.com` as file content, which
    the rewrite did not touch. Changed to the noreply address in commit
    "Maintainer email to the GitHub noreply address".
3.  Every commit SHA in the repo changed. The two SHAs cited elsewhere in
    project docs (`4b4d0d4`, `686e174`) were captured before the rewrite;
    anything else citing an old SHA is now stale.
4.  Of 13 non-`main` branches, only 3 have live purpose (open PRs #50, #51, plus
    `feature/item9-output-paths`); the other 10 have no open PR and are
    candidates for deletion once confirmed merged or abandoned.

### 16. Rebuild the swlonrsp.github.io maps with current code — urgent, next after PR #53's conflict

1.  Target folder:
    `/Users/iarla/Library/Mobile Documents/com~apple~CloudDocs/0 - Projects/swlonrsp.github.io`
    (its own git repo). 13 maps plus `index.html`: Croydon NO2 (1), Merton (5,
    three of them `*_latest`), Richmond (2), Wandsworth (3), the PM2.5 episode
    of 15–20 January 2024 (1), Wandsworth sensor locations (1). The oldest
    files date from October 2025 to January 2026 and predate v0.9.9.13.
2.  Deliverable: one generating script per map, or one per borough, written
    against the current API (`output_file` required, `symbol_labels`), so the
    whole folder regenerates from one command.
3.  No branch in this repo and no package code: client scripts live outside
    the package (item 9.5). Where the scripts are kept is undecided — the
    swlonrsp.github.io repo itself, or the workspace repo item 9.5 creates.
4.  Not yet known: which scripts built the current files, and whether the
    Breathe London layers can be rebuilt from RData already held or need the
    API key that blocks item 12.
5.  Depends on PR #53's code, not on its merge: install from
    `feature/item9-output-paths`.

### 17. GIF export of the animation — urgent, after PR #53 merges

1.  Does not exist: no `gif`, `gifski`, `magick` or `av` anywhere in R/,
    DESCRIPTION or NEWS.md (checked 2026-10-13).
2.  Builds on the per-step JPG loop that `export_image` already drives; a GIF
    is those frames assembled. The encoder goes in `Suggests`.
3.  Branch `feature/item17-gif-export` from `main` after #53 merges. PR #53
    rewrote the same per-step loop (filenames and directories), so a branch cut
    earlier would conflict with it.
4.  Rendering-touching: blocks on visual sign-off.
5.  Overlaps item 11.3 (print/email quality selector — the GIF needs a pixel
    size and frame delay) and open defect 12 (chromote times out mid-batch; a
    GIF needs every frame, so the retry may have to come first).

### 18. Create a new API guide — after items 17, 12 and 11, before the v1.0 tag

1.  Replaces dev/archive/260712_api_catalogue_v1.md, which describes v0.9.9.7.
    Same method: every exported function and argument traced to where the code
    reads it, grouped as the pkgdown reference index groups them.
2.  Placed after the last three items that change the public API: 17 adds a
    GIF export argument, 12 adds `bl_sensors()`, `bl_data()` and
    `from_breathelondon()`, 11 adds the image-quality selector and changes the
    data directory default. Written earlier, it is out of date at each merge.
3.  Its discrepancies against the roxygen text are the last docs-vs-code check
    before `R CMD CHECK` (9.2) is declared clean for release.
4.  Open: whether it stays a dev/ document or becomes a manual chapter.

### Which PR each open task belongs to

| Task | PR |
|---|---|
| 9.2 `R CMD CHECK` clean | new PR, after #53 merges |
| Manual: chapters, example maps, README.md, pkgdown config | new PR from `docs/manual-v2`, after #53 merges |
| 9.4 GitHub Issues, `URL:`/`BugReports:` | new small PR |
| 9.6 `sapply()` to `vapply()` | new small PR |
| Built `docs/` site for GitHub Pages | new PR from `docs/package-rationale`, carrying only the `docs/` commit; PR #52 is not reopened |
| 11 defects and features | new PR, after #53 and #51 merge |
| 13 stack retest | new PR, not urgent |
| 14 dev/ rename | new PR, low priority |
| 17 GIF export | new PR, after #53 merges |
| Architecture diagrams | new PR from `docs/architecture-diagrams` |

### Numbering history

Items 16 and 17 added 2026-10-13; item 18 the same day.

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

### Documentation that contradicts the code

Found 2026-10-05 by a source read at v0.9.9.13 (diagram 8 of
`dev/archviz_build_v1.py`, on branch `docs/architecture-diagrams`). Line
numbers are from that date. DOC-3 and DOC-4 re-checked 2026-10-13; the other
eight were not, and DOC-5 was found by grep only. Q: is R/quickmap.R, W: is
R/wind.R.

- **DOC-1. Pipeline order in CLAUDE.md.** `quickmap()` passes sf layers, so
  `load_data_file()` is not reached on that path. `generate_map_layers()` is
  the outer driver: it calls `prepare_generic_layer_data()` and `add_layer()`,
  and `add_layer()` calls `create_generic_icons()`. Q:3823, Q:3674.
- **DOC-2. "One loop emits HTML and static exports".** `generate_map_layers()`
  only draws markers; static frames use `add_year_and_static_layers()` in the
  shared loop. Q:2309, Q:4279.
- **DOC-3. Fixed 2026-10-13.** The first `quickmap()` example in CLAUDE.md had
  no `output_file`, so it errored.
- **DOC-4. The `who_no2` YAML example in CLAUDE.md** shows 5 bands with `name`
  and `pollutant` keys. The real file has no `name` or `pollutant` key, and 11
  bands by the diagram's count.
- **DOC-5. Theme keys not read anywhere in R/quickmap.R**: `legend.show`,
  `legend.background`, `banner.text_color`, `controls.background`,
  `controls.text_color`. Q:1274-1344.
- **DOC-6. "A missing placeholder is a hard error".** Only a `{{key}}` absent
  from the template errors; a template placeholder left unfilled passes
  silently. Q:72-88.
- **DOC-7. "Two timer-start sites must read `currentInterval`".** One
  `startTimer()` reads it; the lazy fade reads `window.quickmapPlayInterval`.
  inst/controls/time-slider.js:143-148.
- **DOC-8. "Wind comes from one worldmet station".** Any data frame with
  `date`, `ws`, `wd` is accepted. W:25-58.
- **DOC-9. `indicator.placement` default.** `title_row` in
  `get_default_theme()`, but function fallbacks use `right`. Q:4216, Q:2937.
- **DOC-10. Comments in inst/controls/wind-controller.js:4** describe the
  roller menu and `switchToYear`, both replaced by the time slider.

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
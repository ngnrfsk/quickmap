---
editor_options:
  markdown:
    wrap: 80
---

# QuickMap Project Status

**Last Updated**: 2026-10-13 **Current Version**: v0.9.9.14

Version history: NEWS.md. History before 2026-08-16:
dev/archive/PROJECT_STATUS_history_to_260816.md.

--------------------------------------------------------------------------------

## Where the project stands

- Close to v1.0. Roadmap items 9, 11, 12, 13 and 14 remain, plus 16, 17 and
  18. Item 9: 9.1, 9.3, 9.7, 9.8 and 9.9 merged as PR #53 on 2026-10-13
  (v0.9.9.13); 9.2, 9.4, 9.5 and 9.6 remain.
- PR #51 (Breathe London, draft) is open, waiting on the API key. PRs #48 and
  #52 are closed; their content is on `docs/manual-v2`.

- **Order of work, set 2026-10-13:** PR #53 (merged) → September styling
  (PR #54, merged) → 16 → 17 → 12 → rest of 11 → 18. One item
  is in review at a time: each branches from `main` after the one before has
  merged. Item 16 changes no package code.

- **September styling work**, `feature/item11-tiles-legend` (v0.9.9.14),
  rebased onto `main` on 2026-10-13 after PR #53 merged. Detail under items
  11.7 and 11.8. It contains all of `feature/item11-defra-tubes`. The manual's
  17 example maps predate it and are regenerated after it merges.

## Steer

- 2026-10-13: items 16 (rebuild the swlonrsp.github.io maps) and 17 (GIF
  export) go ahead of items 12 and 11, as urgent.
- 2026-10-13: the September styling branch merges before items 16 and 17, so
  the operational maps are rebuilt once, with the new tiles and legend.
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

1.  **Repoint the six Squarespace lightbox links** to the `_latest` names
    (item 16.5; maps live since 2026-10-14). Open points are in
    `/Users/iarla/Coding/swlonrsp-maps-build/STATUS.md`.
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
7.  **Done (PR #53).** Audit docs against code; mark dev docs current or
    historical.
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
7.  **Defra workbook reader (11.1), drafted 2026-09-11** as
    dev/item11_defra-tubes-xlsx_v1.R, with a bundled Croydon theme
    (`inst/themes/croydon.yaml`). Test files live outside the repo in
    `/Users/iarla/Coding/260911 Croydon LCA maps/`. Still to do, from the
    Croydon live-data test of 11 to 22 September:

    *Reader, script to package function:*
    - [ ] Move the four functions to R/ as `from_defra_xlsx()`, with roxygen,
          returning a `qm_layer` that carries site metadata; no CSV round-trip.
    - [ ] `readxl` to Suggests behind `requireNamespace()`.
    - [ ] Fixture workbook and `test-item11-defra-xlsx-v1.R` covering: two-row
          header with "(m)"/"(Y/N)" fragments; spacer columns and rows;
          relocation suffix (CY55a vs CY55); year headers as text and as
          2022.00; flagged values ("42.77 c", "25.06c"); a site on one sheet
          only, each way.
    - [ ] Flags kept as `attr(, "flags")`; whether the map marks flagged
          values (the workbook does not define "c") is post-1.0 unless cheap.
    - [ ] Unmatched sites attached as `attr(, "unmatched")`, not only messaged.
    - [ ] Header-to-column regex map to a YAML under inst/config/.
    - [ ] Stretch: same table from an ASR PDF or Word document. Not started.
    - [ ] vignettes/your-data.Rmd section on the workbook layout.

    *Extensions the data exposed:*
    - [ ] `from_csv()` to accept `latitude`/`longitude` (and `lat`/`lon`) as
          the coordinate pair; council schools scrapes arrive that way and
          the Croydon script had to convert through sf.
    - [ ] `shorten_school_names()`: strip trust suffixes ("- The Pegasus
          Academy Trust", "- FACT Academy", "- The Inspire Partnership"),
          parentheticals, and "and Nursery"/", Nursery and Children's
          Centre" tails. Croydon's 115 names as the test; one legitimate
          duplicate across levels (Oasis Academy Shirley Park).
    - [ ] `import_csv_data()` drops rows missing Easting/Northing/Label with
          no message (CY114 vanished silently). Message count and ids.
    - [ ] `generate_symbol_labels()` treats an unknown `symbol_labels` value
          as FALSE: `"Labels"` gives no labels and no error. Stop with the
          accepted values.
8.  **Tiles, legend and banner fixes (v0.9.9.14)** on
    `feature/item11-tiles-legend`: defects 17 and 18 as decided 2026-09-22,
    `bar` reading `banner.text_color`, `check_chrome_contrast()` and
    `check_tiles_from_disk()`. Rebased onto `main` on 2026-10-13 after PR #53;
    conflicts resolved in R/quickmap.R (the two new arguments added to main's
    single save call), DESCRIPTION, NEWS.md and CLAUDE.md. Gate 2026-10-13:
    full run 567 passed, 1 failed, 2 CRAN skips; the failure was the
    consistency test, because this file still stated v0.9.9.13, and that test
    file passes since the correction. tests/test_quickmap.R completed. **All three demo maps signed
    off by Iarla, 2026-10-13; merged as PR #54.** Demo maps regenerated 2026-10-13 from
    dev/item11_tiles-legend_demo-maps_v2.R into
    `/Users/iarla/Coding/260911 Croydon LCA maps/aq_maps/`:
    - item11_merton-annual_v2.html — streets visible when opened from disk;
      legend panel lavender from merton.yaml with a white heading pill. v1
      signed off 2026-09-22: the lavender legend, white banner and purple rule
      are merton.yaml's own settings, and "strip" stays the default banner.
    - item11_episode-subannual_v3.html — same tiles on the hourly animation,
      airstat theme on `Esri.WorldGrayCanvas`. v1 failed sign-off 2026-09-22
      (`CartoDB.Positron` watermarks from disk); **v2 was never signed off.**
    - item11_croydon-schools-labels_v2.html — purple bar banner, white text
      from the theme, pale-purple legend panel, school crosses and key. v1
      signed off 2026-09-22.
    The v1 and v2 maps of 22 September are kept in the same folder for
    comparison. After it merges, regenerate the hosted LBM/LBRUT/LBW maps
    (item 16): sent as files, they show the blocked tile.

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

### 16. Rebuild the swlonrsp.github.io maps with current code — live 2026-10-14

1.  Target folder:
    `/Users/iarla/Library/Mobile Documents/com~apple~CloudDocs/0 - Projects/swlonrsp.github.io`
    (its own git repo). 12 maps plus `index.html` (an earlier count of 13 was
    wrong): Croydon NO2 (1), Merton (5, three of them `*_latest`), Richmond
    (2), Wandsworth (2), Wandsworth sensor locations (1), the PM2.5 episode of
    15–20 January 2024 (1).
2.  **Done.** Scripts are in a new local repo,
    `/Users/iarla/Coding/swlonrsp-maps-build` (first commit 20e76d6, no GitHub
    remote yet): one script per borough plus the episode, run by
    `Rscript build_all.R`. All 12 rebuild with v0.9.9.14 into its `build/`.
3.  Sources of each map's method: `inst/examples/quickmap_create_RSP_maps.R`
    (six `*_Map_*` files), the Merton AQAP `merton_animation_v1.R` (three
    `*_latest`), the Croydon `croydon_maps_v4.R`, `inst/examples/
    episode_example.R` and `inst/examples/
    quickmap_create_wandsworth_new_sensors.R`. All inputs were already held;
    the Breathe London API key was not needed.
4.  Compared with the hosted copies by title, time steps and legend bands:
    titles and steps match on all 12. Ten differences are listed in that
    repo's README.md; its STATUS.md holds the open points. The main ones:
    tiles now openstreetmap.de; Breathe London sensors clipped to the borough;
    the faulty 786 µg/m³ reading blanked; the Wandsworth sites map's
    location-only style not reproduced.
5.  **Reworked the same day to rules agreed with Iarla** (that repo's
    RULES.md, commit a368659): 8 maps replace 12. One map per borough per
    pollutant on the latest data, under a permanent `_latest` name; uniform
    symbols and generated banner text; the legend mean and maximum on every
    annual map. The six file names linked from
    lovecleanair.org/air-quality-in-my-area, and Croydon's, stay as temporary
    copies until Iarla repoints the Squarespace links. Deprecated and removed
    at deploy: `LBM_NO2_DT_BL_latest.html` and the Wandsworth sites map.
    2026-10-14 (Iarla): every map built on the lazy path
    (`options(quickmap.lazy_step_threshold = 0)`, files 15–29% smaller), and
    deployed with `--remove` to the site folder, commit 01db370. Approved by
    Iarla and live 2026-10-14 (site commit 4ef9e09). Remaining, not blocking
    other items: Iarla repoints the six Squarespace links to `_latest`, then
    the copies retire; Wandsworth banner contrast (2.7:1, fix in
    `inst/themes/wandsworth.yaml`); open points in
    `/Users/iarla/Coding/swlonrsp-maps-build/STATUS.md`.
6.  Found while building, for item 11: `from_rdata()` prepends `DATA_PATH`
    to an absolute path, so a prepared `.Rdata` outside `DATA_PATH` cannot be
    passed by path (same subject as 11.4).

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
| September styling (11.8) and Defra reader draft (11.7) | PR from `feature/item11-tiles-legend`, opened 2026-10-13 |
| Rest of 11, defects and features | new PR, after #51 merges |
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
  needs resolution-aware targets in the YAML. Post-1.0. When resolved,
  rebuild the hosted episode map with the mean and maximum on:
  `/Users/iarla/Coding/swlonrsp-maps-build/RULES.md`, rule 21.
- **14. Fixed panel unexplained.** "Network mean, N sites" counts fewer sites
  than are on screen; add a tooltip.
- **15. Split import from map creation.**
- **16. Automate label placement**, clustering and spread. Includes reducing
  label clashes and overlaps generally (added 2026-08-17); shortening school
  names (item 9.8) buys width but does not place anything.
- **LCA-1/2/3.** Collapsible radio buttons bottom-left; open at a zoom filling
  the screen; choose the layer visible on load.
- **17. Theme `legend: background` was read by nothing.** Item 10 fixed the
  legend white and left the key in every bundled theme. Found 2026-09-11.
  **Decided 2026-09-22 (user): honour the key; item 10's fixed white was an
  error.** Fixed on `feature/item11-tiles-legend` (v0.9.9.14): the panel
  takes `legend.background`, the heading pill stays white. With it, `banner:
  text_color` reaches the "bar" style (it was hard-coded white) and
  `check_chrome_contrast()` warns below 3:1 for banner text on its
  background and for the legend's `#333333` text on `legend.background`.
  Signed off 2026-10-13, PR #54.
- **18. OSM tiles blocked for maps opened from disk.** tile.openstreetmap.org
  serves a 403 "Access blocked" tile to any browser request without a
  Referer (osm.wiki/Blocked), and a `file://` page cannot send one. Found at
  visual sign-off 2026-09-22. Headless-Chrome check from file:// that day:
  Carto watermarks "API KEY REQUIRED"; openstreetmap.de, openstreetmap.fr,
  Esri WorldStreetMap and WorldGrayCanvas, and OpenTopoMap all render.
  **Decided 2026-09-22 (user): default to openstreetmap.de.** Fixed on
  `feature/item11-tiles-legend` (v0.9.9.14): `get_default_theme()` sets
  `base_tiles = "OpenStreetMap.DE"`; NULL still means osm.org for hosted-only
  maps. Signed off 2026-10-13, PR #54.
- **19. Lazy path ignores the label theme keys; lazy as default undecided.**
  Found 2026-10-14 (item 16). `build_lazy_payload()` carries no
  `label_scale` or `label_background`, and `lazy-time-controller.js`
  hard-codes its tooltip style with no font size, so labels on lazy maps are
  not sized by `label_font_size()`. Its `colourFor()` reads `thresholds`
  only, so a temporal layer on a categorical (`domain`) scale is untested.
  Forcing lazy on the seven site annual maps cut them 15–29%. Making it the
  default needs these fixed first, and means interactive maps and static
  exports always render through different code (exports stay pre-built).

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
  `controls.text_color`. Q:1274-1344. `legend.background` and
  `banner.text_color` are read once item 11.8 merges (defect 17).
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
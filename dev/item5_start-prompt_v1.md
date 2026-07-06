# Start prompt — roadmap item 5: rendering backend comparison (autonomous session)

Copy everything below the line into a fresh autonomous Claude Code session in
`/Users/iarla/Coding/quickmap`.

---

Begin autonomous work on QuickMap roadmap item 5 (rendering backend
comparison) per the "Autonomous Agent Instructions" section of CLAUDE.md.
Read that section in full first — it is the approved plan and overrides
general instincts.

**Your mandate** is the user-approved comparison brief:
`dev/260705_rendering_backend_candidates.md`. Read it in full before
anything else. It fixes the invariants — candidates (Leaflet+Option D
Canvas, MapLibre/mapgl, deck.gl via a CRAN wrapper, plotly), the two shared
datasets, the measurement set, the minimal prototype scope, the gating order
(offline sharing test first; 500×200 only for finalists), and a
per-candidate timebox. It deliberately does not prescribe per-stack
implementation methods — discover those from current documentation.

**Mandatory pre-reading, in order:**
1. `dev/260705_rendering_backend_candidates.md` (the mandate)
2. `versions/quickmap_0_9_5_failed_svgicon_experiment.R` (prior failed
   attempt at the file-size problem — do not repeat it)
3. `dev/20250118_geojson_option_d_design.md` (Option D design)
4. `dev/maplibre.R` + `dev/maplibre_template.html` (existing MapLibre
   experiment; sample input `dev/data.csv`, tarball `dev/mapgl_0.4.4.tgz`)

**Setup and ground rules:**
- Verify `Sys.getenv("DATA_PATH")` points to `~/Coding/Library/data` and that
  `episodeJan15-20_2024_sf_all.Rdata` exists there; if not, STOP and report.
- The installed `quickmap` package (v0.9.6) provides `from_rdata()` to load
  the episode fixture and `quickmap()` to regenerate the Leaflet reference
  output. Reinstall with `devtools::install()` only if the package is missing.
- Create branch `feature/item5-backend-comparison` before writing anything.
  Never commit to `main`; never merge your own PRs.
- Put prototypes in `dev/item5_prototypes/<candidate>/`; name any generated
  maps and scripts per the CLAUDE.md naming convention
  (`[item]_[short description]_[version]`, e.g. `item5_deckgl-episode_v1.html`).
- Do NOT modify package code (`R/`), the characterization tests, or rendering
  paths — this item is research; item 6 implements. The testthat suite must
  remain green (run it before your final commit to prove you left the package
  untouched in behaviour).
- Follow the permission-safe command style exactly (no cd, no inline env
  assignments, no `$()`, no loops/redirects — put multi-step work in script
  files run via `Rscript`/`python3`). WebFetch is domain-allowlisted
  (cran.r-project.org, github.com, r-spatial.*, bookdown.org, openair/
  davidcarslaw docs); most JS library documentation is mirrored on GitHub —
  prefer that or WebSearch when a docs domain is blocked. Installing CRAN
  packages inside an Rscript file is fine.
- Honour the timebox: roughly half a day per candidate prototype. If a
  candidate exceeds it, record the blocker and partial findings, mark it
  "not evaluated to completion", and move on.

**Deliverable:** `dev/item5_backend-comparison_v1.md` containing, per the
brief's method: sharing-mode results, benchmark table (both datasets,
finalists), feature-checklist scores (criteria 1–10), migration-cost and
CRAN-readiness assessment, and a single justified recommendation. Open a PR
with the comparison doc and prototypes; the PR description must list the
generated demonstration files (with the branch they live on) and what the
human should inspect.

**STOP condition:** after opening the PR, STOP and wait for explicit user
approval of the recommendation. Do not begin any item-6 (lazy loading)
implementation, and do not fold decision and implementation into one PR.

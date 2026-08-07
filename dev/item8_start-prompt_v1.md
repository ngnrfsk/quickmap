# Item-8 kick-off prompt (fresh autonomous session)

Copy-paste the block below as the starting prompt for the item-8 session.
Precondition: PR #26 (item-7 wind layer) merged to main — done 2026-07-07.

---

Begin autonomous work on QuickMap roadmap item 8 (migrate and validate all
examples) per the "Autonomous Agent Instructions" section of CLAUDE.md. Read
that section in full first — it is the approved plan.

**Goal:** every example script, vignette, and living test script speaks the
v0.9.8 `quickmap()` API (file paths / `qm_layer()` units / data frames;
per-layer properties on the layer, map properties as `quickmap()` arguments),
runs clean against the installed package, and produces output the human can
verify against the current signed-off look. `create_pollution_map()` remains
a supported compatibility wrapper — migrating a script means preferring
`quickmap()` where it reads better, not mechanically rewriting every call;
where an example exists precisely to document the legacy signature, say so
in a comment instead of converting it.

Mandatory pre-reading, in order:
1. R/quickmap_api.R (the quickmap() contract + wind param) and R/qm_layer.R
   (from_csv/from_rdata/from_openair wrappers)
2. dev/PROJECT_STATUS.md items 4–7 (what changed under the API: qm_layer,
   lazy loading >50 steps, 200-step cap, wind layer)
3. vignettes/quickmap_reference.md (already partially migrated at item 4 —
   the model for tone)
4. tests/testthat/test-characterization.R (the regression net that must not
   move)

Scope — the migration inventory:
- **inst/examples/**: episode_example.R (canonical animation example — also
  the source of the characterization episode fixture, so its rendered output
  must stay byte-stable), quickmap_create_RSP_maps.R,
  quickmap_create_wandsworth_new_sensors.R, test_episode_example.R,
  missing_data_stats.R, prepare_bl_data_with_missing.R (the last two are
  data-prep, likely no API calls — verify and leave or annotate)
- **vignettes/**: quickmap_reference.md (verify current), 
  251123_theme_system_guide.md and 251126_CONFIGS.md (update API calls,
  keep content), 251029_MIGRATION_EXAMPLE_v0.9.0.md (historical — mark as
  historical rather than rewrite)
- **CLAUDE.md examples** (Creating Maps section) — verify against the
  installed package; run tests/testthat/test-consistency.R after any edit
- **tests/test_*.R one-off scripts**: NOT a migration target (CLAUDE.md:
  historical, not a gate). Only tests/test_quickmap.R (the smoke test) must
  keep working; touch others only if trivially broken by nothing more than
  a renamed argument, otherwise leave and list them in the PR as historical
- A new demo script scripts/demos/item8_worked-examples_v1.R exercising the
  quickmap() API end-to-end: two-line map, multi-layer + theme, episode
  animation (lazy path), wind layer — the runnable "documentation of record"

Validation bar (this is the "validate" half of the item):
- Each migrated script is actually RUN against DATA_PATH fixtures where its
  data exists; scripts needing absent data get a header comment naming the
  missing file and are listed in the PR
- episode_example.R output must match the characterization expectations
  (the episode fixture pins it); other rendered outputs go to aq_maps/ as
  item8_[desc]_v1.html for the human eyeball
- Full automated gate after every change: testthat::test_dir
  ("tests/testthat") with zero failures + source("tests/test_quickmap.R");
  reinstall via devtools::install() after any R/ edit (expect none — this
  item should not touch R/ code; if a migration exposes a genuine API bug,
  fix it in a separate flagged commit)

Ground rules:
- Verify Sys.getenv("DATA_PATH") and fixtures exist; STOP if not
- Branch feature/item8-examples off main; no R/quickmap.R archive needed
  unless R/ code changes (then archive first)
- This item is expected to be **non-rendering** (docs + scripts): the merge
  bar is green automated tests plus visually unchanged outputs. But if any
  rendered output changes at all, reclassify as rendering-touching and
  block the PR on human visual sign-off per CLAUDE.md
- Copy the current signed-off aq_maps set to a dated baseline folder before
  regenerating anything (most recent baseline: baseline_260705_signed_off/;
  item6/item7 demo maps are the signed-off comparison set for animations)
- Naming convention: item8_[desc]_[version] for all new artefacts
- Permission-safe command style per CLAUDE.md (no cd, no $(), no inline env
  assignments, no loops/redirects; multi-step work in Rscript files)
- Version: this item is docs/examples only — bump to v0.9.9 (DESCRIPTION +
  CLAUDE.md Current Version + history line) only if R/ code changes;
  otherwise leave the version at 0.9.8 and say so in the PR
- Update dev/PROJECT_STATUS.md; STOP at PR: never merge; never push to main

---

## Handover notes (context the prompt above compresses)

- Items 6+7 landed Canvas/JSON lazy rendering (>50 steps or >~5 MB est.)
  and the wind layer (`wind =` on quickmap()/create_pollution_map();
  `from_worldmet(station, year)` fetches NOAA, or pass a date/ws/wd data
  frame). Examples showcasing animation should mention both; the episode
  example is the natural place to add a commented-out wind variant
  (Heathrow "037720-99999").
- The characterization episode fixture is generated through
  create_pollution_map() in helper-characterization.R — do not migrate the
  helper; it pins the compatibility wrapper on purpose.
- worldmet is Suggests; examples using wind must guard with
  requireNamespace("worldmet") or pass a local data frame.
- Known stale docs to expect (internal-consistency warning in CLAUDE.md):
  vignettes may reference removed parameters (styling_type variants,
  data_ids semantics). The code is the source of truth; fix docs to match
  code, never the reverse, and leave the full sweep to item 9.
- gh CLI is authenticated; PR template: list migrated files, run/not-run
  status per script, outputs for eyeball, and the rendering/non-rendering
  classification argument.

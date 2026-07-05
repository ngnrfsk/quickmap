# Risk Handlers — 260705

Follow-up to the 2026-07-05 refactor viability assessment. That assessment ranked
four risks against the v1.0 roadmap. Risks 1 and 2 are now handled structurally as
roadmap amendments in CLAUDE.md (items 2 and 5, inserted 2026-07-05):

- **Risk 1 (no test safety net)** → roadmap item 2: characterization tests against
  rendered HTML, written after packaging and before any API/rendering change.
- **Risk 2 (Leaflet vs. MapLibre fork)** → roadmap item 5: explicit backend
  decision with user-approval STOP before lazy loading.

This plan drafts handlers for the remaining risks. Each handler notes when in the
roadmap it should run.

**Execution status (2026-07-05, branch `chore/risk-handlers`):**
- Human visual sign-off received 2026-07-05 on the smoke-test outputs
  (visually unchanged) — the branch has met its approval bar for merge. The
  signed-off set is preserved in `aq_maps/baseline_260705_signed_off/`.
- Risk 3.1 (fail-loud anchors): **executed** — anchor checks in
  `inject_banner_legend_controls()`, strict `{{placeholder}}` matching in
  `apply_template_replacements()`. The image-mode numeric rescale list at the
  same call site was found to be silently inert (escaped patterns vs
  `fixed = TRUE`) and order-broken; per the "do not fix UI defects piecemeal"
  rule it is documented in PROJECT_STATUS.md under UI defect #9 (roadmap
  item 10), not fixed here, and is deliberately excluded from the strict check.
- Risk 3.2 (injection assertions in characterization tests): pending — lands
  inside roadmap item 2 by design.
- Risk 3.3 (dependency floors): **executed** — `leaflet (>= 2.2.2)`,
  `htmlwidgets (>= 1.6.2)` added to DESCRIPTION on the in-flight
  `feature/packaging` worktree.
- Risk 4 (_gem archival + root cleanup): **executed** — see commit on
  `chore/risk-handlers`.
- CRAN checklist: recorded only; executes with roadmap items 8–9 by design.

---

## Risk 3: HTML post-processing fragility

**The risk.** Banner, legend, and year-control injection works by string
substitution on the HTML that `htmlwidgets::saveWidget()` emits
(`save_html_and_style()`, `inject_banner_legend_controls()`,
`apply_custom_layout_in_html()`). The substitutions are anchored to the exact
markup leaflet/htmlwidgets currently produce. A version bump of either package —
likely during CRAN prep — can change that markup, and a `gsub()` whose pattern no
longer matches does not error: it silently emits a map with no banner, legend, or
controls. No automated test currently detects this.

**Handler (three parts):**

1. **Fail loudly on missed anchors** — small code change, can ride along with
   roadmap item 2 or any earlier PR touching these functions. In each injection
   function, after every anchor-dependent substitution, verify the substitution
   actually happened (output differs from input, or `grepl()` the anchor before
   substituting) and `stop()` with the anchor name if not. This converts silent
   visual regressions into hard errors. Keep it minimal — one check per anchor,
   no new abstraction; this is consistent with the Code Minimalism policy because
   these are operations that *should* fail but currently can't.

2. **Characterization coverage** — part of roadmap item 2, no extra work beyond
   scoping. The item-2 test list already includes "presence of the injected
   banner/legend/year-control blocks". Make sure those assertions target the
   *injected* markup (e.g. the banner div, legend container, roller-menu HTML and
   its populated year entries), not just saveWidget output, so a dependency bump
   that breaks injection turns the suite red.

3. **Declare minimum dependency versions** — part of roadmap item 1 (packaging),
   one line each. Record the currently-installed `leaflet` and `htmlwidgets`
   versions as minimums in DESCRIPTION (`leaflet (>= x.y.z)`). This doesn't
   prevent future breakage but pins the tested floor and documents what the
   injection code was written against.

**Explicitly deferred:** any structural rework of the injection system (e.g.
consolidating anchors into one function). If roadmap item 5 chooses MapLibre, the
post-processing layer gets ported anyway; if it chooses Leaflet + Option D, the
lazy-loading JS controller work is the natural time to consolidate. Doing it
earlier is wasted motion.

## Risk 4: Documentation divergence (`_gem` variants)

**The risk.** `CLAUDE_gem.md` and `PROJECT_STATUS_gem.md` are parallel,
alternative versions of the two governing documents (Gemini-generated
consolidations). They already disagree with reality — e.g. `CLAUDE_gem.md` says
quickmap.R is ~2,200 lines; it is ~2,900. For an agent-driven project the
instruction files are the spec; two diverging specs is how an agent ends up
following the wrong one.

**Handler — one-time cleanup, suitable for the next housekeeping PR (or ride
along with roadmap item 1's branch):**

1. Diff each `_gem` file against its canonical counterpart and harvest anything
   worth keeping. Known candidate: `CLAUDE_gem.md`'s positioning statement
   ("production-ready temporal animation of monitoring network data with
   self-contained HTML/JPG output... not intended to compete with mapview/tmap")
   is a good scope clarifier that could be merged into CLAUDE.md's
   Scope/Philosophy section — user to confirm.
2. Move both `_gem` files to `dev/archive/` (do not delete — they are the only
   record of that consolidation pass).
3. While housekeeping: the repo root also holds working files that belong
   elsewhere or in `.Rbuildignore` — `data.csv`, `.RDataTmp`, loose YAMLs
   (`airstat_no2.yaml`, `richmond.yaml`, `stripes_no2.yaml`, `boundaries.yaml`,
   `boundary-styles.yaml`, `vignette-style.yaml`), `mapgl_0.4.4.tgz`,
   `maplibre.R`, `maplibre_template.html`, `template.html`,
   `symbols_sampler.html`, `251029_README.md`, `260119_Airstat_Styling_Reference.md`.
   **Do not move the maplibre files yet** — they are evidence for roadmap item 5;
   move them to `dev/` (not archive) so the backend decision can reference them.
   The rest: YAMLs that duplicate `inst/` copies get deleted, one-offs go to
   `dev/archive/` or `scripts/`, and whatever must stay at root goes in
   `.Rbuildignore` (item 1's branch already touches `.Rbuildignore`).

## Also noted: CRAN friction pre-staging (not a risk, a checklist)

These were flagged in the viability assessment as grind within roadmap items 8–9.
Recorded here so they aren't rediscovered from scratch when those items start:

- `webshot2` moves from `Imports` to `Suggests` (needs Chrome; static export is
  optional functionality). Guard its use with `requireNamespace()`.
- Examples/tests cannot depend on `DATA_PATH` or `~/Coding/Library/data`. Bundle
  small anonymised sample datasets in `inst/extdata` (one diffusion-tube CSV, one
  schools CSV, one small RData) and point examples at them via `system.file()`.
  Heavy examples get `\donttest{}`.
- `geocode_uk_postcodes()` calls postcodes.io — CRAN requires graceful failure
  when offline (informative message, no error, no test dependency on the API).
- `.Rbuildignore` must exclude `dev/`, `versions/`, `aq_maps/`, `tests/test_*.R`
  one-offs, and remaining root clutter (overlaps with Risk 4 handler step 3).

---

## Suggested sequencing

| Handler | When |
|---------|------|
| Risk 3.3 (dependency version floors) | Roadmap item 1 (in flight on `feature/packaging`) |
| Risk 4 (archive `_gem` files, root cleanup) | Next housekeeping PR / item 1 branch |
| Risk 3.1 (fail-loud anchors) | With roadmap item 2 |
| Risk 3.2 (injection assertions) | Inside roadmap item 2 |
| CRAN checklist | Roadmap items 8–9 (recorded now, executed then) |

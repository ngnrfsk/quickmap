# Review guide: manual phase 1 (pkgdown skeleton + first two chapters)

**PR:** https://github.com/ngnrfsk/quickmap/pull/33 (v2 — supersedes the
closed PR #31; same content plus the approved shape corrections)
**Branch:** `feature/manual-phase1-v2` · **Scope:** docs/config/scripts only —
no R/ code changed, version stays 0.9.8.1.

Everything below is already on your disk on the PR branch; the site is
already built. No setup needed unless a link fails (see "If a link is
stale" at the end).

---

## 1. What you are reviewing

Phase 1 of the approved manual plan (dev/260707_manual_prospectus_v1.md):
the pkgdown site skeleton plus the two tone-setting chapters. The question
to answer: **is this the right voice and shape for the whole manual?**
Later phases copy this template.

## 2. The review, in order (~15 minutes)

### Step 1 — the built site (the actual deliverable)

Open in a browser:

- **Site front page:** `docs/index.html`
- **"Get started" chapter:** `docs/articles/quickmap.html`
- **"Layers" chapter:** `docs/articles/layers.html`
- **Reference index:** `docs/reference/index.html`

Check:

- [ ] Get started reads as a genuine five-minute path for a nervous R
      beginner — no options, no jargon, nothing to decide.
- [ ] Layers follows the approved template principles
      (dev/260708_page_template_review_v1.md): opening teaches the
      concept with no "this page…" meta-text and flows unheaded into the
      first example; every example says in one sentence what its input
      must contain; each heading is an assertion naming the API element;
      each of the six reveals adds exactly one idea.
      You should feel the point where you could stop reading.
- [ ] The two screenshots look right (default purple banner, WHO legend;
      the multi-layer map shows circles + diamonds + crosses).
- [ ] OpenAir links appear where data enters (your amendment): the live
      `importUKAQ()` example on Layers, OpenAir book links in see-also.
- [ ] Reference index groups make sense (Making maps / Layers / Styling /
      OpenAir interoperability); internal helpers are hidden.
- [ ] Navbar: "Get started" and "Articles" behave as you expect.

### Step 2 — the two chapter sources (only if you want to comment line-by-line)

- `vignettes/quickmap.Rmd`
- `vignettes/layers.Rmd`

### Step 3 — the supporting machinery (skim)

- `_pkgdown.yml` — site structure; note the hidden `internal` reference
  section (11 helpers missing `@keywords internal`, deferred to item 9).
- `scripts/manual_run-chunks_v1.R` — runs every code example in the manual
  against DATA_PATH; network examples skip offline. Already run: ALL OK.
- `scripts/manual_screenshots_v1.R` — regenerates the screenshots.
- `.gitignore` / `DESCRIPTION` — docs/ ignored; figures un-ignored;
  knitr/rmarkdown/pkgdown Suggests + VignetteBuilder.

### Step 4 — verification already done (nothing to rerun)

- Chunk harness: all chunks pass, including the live AURN fetch.
- Full test gate: 244 pass / 0 fail / 0 skip; smoke test OK.
- The harness caught and fixed one wrong example before you saw it
  (`from_openair()` needed `source = "aurn"`).

## 3. Decisions attached to this review

1. **Merge PR #31?** Approve or list amendments.
2. **`qm_layer(shape = )` is inert** (discovered writing Layers): the
   parameter is recorded but `quickmap()` never uses it — shapes come from
   an automatic cycle or the map-level `data_symbols`. Choose: fix the
   code / remove the parameter / defer to item 9. The manual currently
   documents the real behaviour.

## 4. If a link is stale

The `docs/` folder is generated (and gitignored). To rebuild it:

```
Rscript -e 'pkgdown::build_site()'
```

then reopen `docs/index.html`.

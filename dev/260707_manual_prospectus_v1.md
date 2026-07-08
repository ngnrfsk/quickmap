# QuickMap Manual — Prospectus (v1)

**Date:** 2026-07-07 · **Status:** APPROVED (user, 2026-07-07) with one
amendment, folded in below: explicit OpenAir-ecosystem links and worked
data-extraction examples in the Your Data article, and OpenAir cross-links
maintained throughout the manual (§2a, §5).
**Decisions already taken (user, 2026-07-07):** pkgdown as primary format;
scope = current v0.9.8 API (rework accepted at v1.0); interleaved audience
structure per feature page; prospectus approved before any chapter is written.

---

## 1. Purpose

A user manual for QuickMap that makes the package's philosophy tangible: a
reader who has never enjoyed R produces a map in their first five minutes,
and the same document carries them — only as far as they choose to go — to
themes, animation, wind overlays, and hand-built `qm_layer()` objects.
It consolidates the existing scattered materials (vignettes, worked-example
scripts, roxygen) into one navigable, buildable site.

## 2. The didactic approach — check requested by user

**Proposed structure (user):** each core-feature page is interleaved —
a two-line intro for non-experts at the top, usage examples of gradually
growing complexity in the middle, and full technical API detail for
competent R users at the bottom.

**Verdict: sound, with three adjustments.** How it sits against
established practice:

- **What it matches.** The dominant framework for technical docs (Diátaxis)
  separates tutorial / how-to / reference into *different documents*. But the
  most-liked real-world API docs (Stripe; the tidyverse "vignette + details"
  pattern, e.g. dplyr's `colwise` articles) do exactly what you propose:
  one page per capability, layered shallow→deep. For a package whose core
  promise is a *gentle gradient*, the page structure itself demonstrating
  that gradient is a feature, not a compromise. The "worked example effect"
  in instructional design also supports leading every page with a complete,
  runnable, minimal example rather than concepts.
- **Adjustment 1 — one global quick start stays separate.** Layered feature
  pages serve readers who already know which feature they want. The true
  beginner needs a single linear "Get started" page (install → two-line map →
  what you're looking at → where to go next) that never mentions options.
  Diátaxis is right about this one separation; everything else can interleave.
- **Adjustment 2 — the bottom layer links, it doesn't restate.** pkgdown
  auto-builds a reference section from roxygen. If each page's "API details"
  section hand-copies signatures, it will rot (the project's known failure
  mode — internal consistency). So the bottom layer is: a curated table of
  the relevant functions/parameters *linking* to the auto-generated reference,
  plus only the cross-cutting behaviour that no single roxygen page can hold
  (e.g. theme-vs-parameter precedence, duck-typing rules, when the lazy path
  engages). Single source of truth stays in the code.
- **Adjustment 3 — a fixed page template.** The gradient only reads as a
  gradient if every page has the same shape, so the reader learns where to
  stop. Template below (§4).

## 2a. OpenAir integration thread (user amendment, 2026-07-07)

QuickMap positions itself as the spatial companion to OpenAir, so the manual
treats the OpenAir ecosystem as the *data acquisition layer* and links to it
wherever data enters the picture:

- **Your Data (article 1)** gets a dedicated "Fetching data with OpenAir"
  section with worked, runnable extraction examples for each relevant tool:
  `openair::importUKAQ()` / `importAURN()` (AURN reference monitors),
  `openair::importImperial()` (LAQN / Breathe London), and
  `worldmet::importNOAA()` (met data for the wind layer) — each ending in
  the `from_openair()` / `from_worldmet()` handoff into `quickmap()`, i.e.
  fetch → convert → map in one visible pipeline.
- **Standing links, not one-off mentions.** Every article links out at the
  point of contact: Layers (art. 2) where `from_openair()` appears; Time
  and animation (art. 4) where `avg.time` mirrors OpenAir's aggregation
  vocabulary; Wind (art. 5) to worldmet station lookup
  (`worldmet::getMeta()`); Recipes (art. 7) includes at least one
  fetch-to-map recipe built on a live OpenAir pull. Link targets are the
  OpenAir book (openair-project.github.io/book) and package reference pages.
- **Consistency guard:** the §7 chunk harness runs the OpenAir extraction
  examples too, guarded by `requireNamespace()` + network availability
  (skip, don't fail, when offline — same pattern as the item-8 wind demo).

## 3. Format: pkgdown site

- **Vignettes → articles.** Each manual chapter is a `vignettes/*.Rmd`;
  pkgdown renders them as "Articles" with navbar ordering = the learning
  path. The same files ship in the package, so CRAN users get the manual
  offline. (Current `.md` vignettes get converted to `.Rmd` as they are
  absorbed; superseded ones retire to `vignettes/archive/` or stay marked
  historical.)
- **Reference section for free.** Roxygen already carries `@family` tags
  (map, atomic unit); `_pkgdown.yml` groups the reference index to mirror
  the manual's feature pages.
- **Build:** `pkgdown::build_site()`; hosting via GitHub Pages
  (`ngnrfsk.github.io/quickmap`) — satisfies sharing mode (b) for the docs
  themselves. New Suggests: `pkgdown`, `knitr`, `rmarkdown`.
- **Chunk evaluation policy:** chunks that render maps are `eval = FALSE`
  by default (they need DATA_PATH fixtures and are slow); each page instead
  embeds 1–2 pre-rendered screenshots, and the page's code is kept runnable
  by the validation harness (§7). This keeps `R CMD build` fast and
  CRAN-safe. Revisit selective evaluation at v1.0.

## 4. Page template (every feature chapter)

1. **In two lines** — minimal complete call + one screenshot. No options.
2. **Worked examples, rising complexity** — 3–5 examples, each adding *one*
   idea, each with a sentence saying what was added and why you'd want it.
3. **How it works** *(optional, short)* — the mental model (e.g. "layers own
   layer properties; the map owns map properties").
4. **Full detail** — curated parameter/function table linking into the
   reference; cross-cutting rules; edge cases and gotchas (e.g. the `Label`
   silent-drop).
5. **See also** — adjacent pages, plus OpenAir-ecosystem links at every
   data touchpoint (§2a).

## 5. Chapter map (articles, in navbar order)

| # | Article | Sources absorbed |
|---|---------|------------------|
| 0 | **Get started** (linear quick start: install, DATA_PATH, two-line map, reading the map) | CLAUDE.md Creating Maps; item8 worked-examples §1 |
| 1 | **Your data** (CSV tubes, RData sensors, schools/contextual, data frames; duck-typing rules; coordinate systems; **"Fetching data with OpenAir" section: worked importUKAQ/importAURN/importImperial/importNOAA extractions ending in from_openair()/from_worldmet(), per §2a**) | quickmap_reference.md data-format tables; CONFIGS network reference material; OpenAir book links |
| 2 | **Layers** (multi-layer maps; `from_csv`/`from_rdata`/`from_openair`; `qm_layer()` for hand-built data; shapes, names, labels) | qm_layer roxygen; item8 worked-examples §2; RSP maps example |
| 3 | **Styling and themes** (colour scales incl. YAML anatomy; themes; banner/legend; precedence rules) | 251123 theme guide; scales section of quickmap_reference.md |
| 4 | **Time and animation** (display_times, resolutions, roller menu, autoplay; 200-step cap and the lazy path as a "how it works" note) | episode_example.R; item6 facts |
| 5 | **Wind** (from_worldmet, data-frame input, station choice; interactive-only caveat) | R/wind.R roxygen; item7/item8 demos |
| 6 | **Sharing and export** (self-contained HTML, email constraints, JPG export, hosting a link) | export params; sharing-constraint text |
| 7 | **Recipes** (short how-tos: borough report set, sub-annual episode, proposed-sites map, missing-data styling, **live OpenAir fetch-to-map**) | RSP maps, wandsworth sensors, item8 script |
| 8 | **Reference for R users** (the atomic unit contract, time grammar, `create_pollution_map()` migration note) | qm_layer.R design doc distillate; quickmap_reference.md |
| — | *(kept, linked, marked historical: 251029 migration example; CONFIGS historical half)* | |

Pages 0–3 are the beginner path; 4–6 the production path; 7–8 the expert
path. `quickmap_reference.md` largely dissolves into pages 1/3/8; the theme
guide into 3.

## 6. What is deliberately out of scope (v0.9.8 edition)

- No UI-polish screenshots effort beyond current look (item 10 will change
  the chrome; screenshots regenerate then).
- No CRAN-facing `pkgdown` deployment automation (a plain local build +
  Pages push is enough until item 9).
- No rewrite of roxygen reference text (item 9's audit owns that).

## 7. Validation (same bar as item 8)

Every code chunk in every article is extracted and run against DATA_PATH
fixtures by a `scripts/manual_run-chunks_v1.R` harness before each PR
(knitr `purl()` + run). Screenshots regenerate from those runs. The
consistency test gains a check that every article named in `_pkgdown.yml`
exists.

## 8. Sequencing and effort

(Naming, clarified 2026-07-08: these are **manual phases 1–3** — the
manual is user-directed work adjacent to the roadmap, not a roadmap item,
so its phases are named "manual phase N" to avoid colliding with roadmap
item numbers or GitHub PR numbers. Earlier drafts said "PR A/B/C"; phase 1
landed as GitHub PR #31.)

1. **Phase 1 — skeleton:** `_pkgdown.yml`, navbar, Get started + Layers pages
   (the tone-setting pair), chunk-runner harness. *~1 session.*
2. **Phase 2 — core:** Data, Styling/themes, Time/animation. *~1 session.*
3. **Phase 3 — completion:** Wind, Sharing, Recipes, R-users page; absorb/retire
   old vignettes; Pages deployment. *~1 session.*

Each PR: green gate + chunk harness + human eyeball of the built site.

## 8a. Pre-drafting decisions (user, 2026-07-07)

- **Base:** manual phase 1 branches off main after PRs #29 (item 8) and #30 (this
  prospectus) merge — no stacking.
- **Install story (Get started):** `devtools::install_github()` with a
  one-line PAT note (repo currently private); reword at v1.0/CRAN.
- **Hosting:** local `pkgdown::build_site()` only, `docs/` gitignored;
  reviewer opens `docs/index.html`. Pages deployment deferred until the
  repo is public (private-repo Pages needs a paid plan) — supersedes the
  §3 GitHub Pages line for now.
- **Screenshots:** package defaults (OSM tiles, who_no2) everywhere except
  the Styling page, which shows themes.

## 9. Approval record

Approved by user 2026-07-07, with the OpenAir-integration amendment (§2a)
folded in. Writing may begin per the §8 sequencing.

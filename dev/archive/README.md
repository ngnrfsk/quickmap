# dev/archive

Project history, cleared out on 7 August 2026: 66 files down to 16.

This is **not** where set-aside ideas live — those are in `dev/concepts/`, one
folder per idea, listed as "Tested ideas, but need more work" in `CLAUDE.md`.
What remains here is reference material and a few documents other historical
notes point at.

Everything deleted is in git history. The cut list and the reasoning are in
`dev/260807_archive-cut-list_v1.md`; the headings digest that informed it is
`dev/260807_archive-digest_v1.md`.

## What is here and why

**OpenAir reference (4).** QuickMap's stated v2 direction is to be OpenAir's
spatial companion, and the post-1.0 ecosystem wrappers depend on this being
right.
`251123_OA_vs_QM_style_guide.md`, `251123_OpenAir_Integration_Style_Guide.md`,
`ANALYSIS_openair_structure.md`, `ANALYSIS_openair_essentials.md`,
plus `251126_Implementation_v093_OpenAir_Converter.md`, cited by PROJECT_STATUS.

**Live reasoning behind live behaviour (2).**
`260113_rdata_duck_typing_options.md` explains why RData duck typing works as it
does — CLAUDE.md documents the behaviour but not the why.
`ANALYSIS_local_data_caching.md` holds AURN and LAQN data volumes and three
costed caching options; its "disk cache at v0.9.4+ if repeated queries become a
bottleneck" decision is still open and was never revisited.

**Cited by other documents (5).** `251029_README.md`, `CLAUDE_gem.md`,
`PROJECT_STATUS_gem.md`, `PROJECT_STATUS_technical_260707-13.md`,
`260119_Airstat_Styling_Reference.md`.

**Assets and one bug record (4).** `symbols_sampler.html` (483 KB, the output of
`scripts/demos/symbols_chart.R` — most of this folder's weight),
`template.html`, `PLAN_ACCESSIBILITY.md`, `mislabelled_deltas_scale.yaml`.

## What was taken out and put somewhere better

- The two indicator style prototypes went to `dev/concepts/indicator/code/`.
- The one live item in `OPTIONS_MODERN_R_REMAINING.md` — replace the remaining
  `sapply()` calls with `vapply()` — was written into roadmap item 9 in
  CLAUDE.md before that file was deleted.

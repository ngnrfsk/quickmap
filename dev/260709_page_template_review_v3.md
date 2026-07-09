# Page-template review v3 — principles inferred from the user's sub-edit

**Date:** 2026-07-09 · **Source:** user's sub-edited Get started page
(iCloud dev/pr31_manual_review/quickmap_v3.Rmd) compared against the
original (vignettes/quickmap.Rmd on feature/manual-phase1-v2).
**Status:** inferred principles P8–P15 below, awaiting user approval;
no pages redrafted yet. Extends P1–P6 (approved, v1 doc) and the codified
P3′–P7 (v2 doc, also awaiting approval).

The sub-edit used three marks — `[[fluff]]`, `{{will date}}`,
`((instruction))` — plus systematic inline commenting of code. Each mark
generalises to a principle:

## The inferred principles

**P8 — Every code line explains itself with an inline comment.** Every
parameter in every chunk carries a short `# comment` ("# diffusion tube
data", "# folder where your data lives"), including `library()` calls.
This *implements* P3″ (no unexplained parameter) in the code itself,
where the reader's eye is, instead of in following prose.

**P9 — No product pitch.** Sentences flagged `[[...]]`: "No deep R
knowledge required… Five minutes from here you will have made your first
map", "That's it." — enthusiasm and promises about the product/manual are
fluff. Replace with explanation of what the command just did ("To make a
map, quickmap needs one input — the measurement data…"). The product's
ease should be *demonstrated*, never asserted.

**P10 — No silently-rotting statements.** "{{QuickMap is not yet on
CRAN}}" will become false without anyone noticing. Phrase durably
("Install from GitHub:") or, where a temporal statement is unavoidable,
isolate it in the already-temporal PAT note. Candidate mechanical check
for the chunk harness/consistency test: a small denylist of rot-prone
phrasings ("not yet", "currently", "coming soon").

**P11 — Order sections by necessity, not setup chronology.** The
DATA_PATH section ("((is this the right opening if it's optional?
3 would be better))") is optional convenience and must not stand between
install and the first map. New Get started order: Install → First map
(with a full path) → the DATA_PATH shortcut afterwards.

**P12 — Headings name the concrete task.** "One step further" →
"Add a title to your map". Sharpens P4′: not just instruction-first, but
naming the *user's goal*, never the manual's structure.

**P13 — Motivate before showing options.** Before an options example,
one sentence on why you'd want them ("Maps usually have a title
banner…"), not "each argument does one visible thing".

**P14 — Show the input as a small table.** "((just show a table, caption
says what are the minimums))" — the first-map explanation shows the CSV's
first rows as a rendered table whose caption states the minimum required
columns. Sharpens P3′ (head() dumps) into: table + minimums-caption.

**P15 — One vocabulary.** "((shouldn't this be Symbols))" on "Markers".
Pick one word for the coloured shapes and use it in every page, legend
and help file. Recommendation: **symbols** (matches `data_symbols`, the
symbol chart, and the user's instinct); "marker" survives only inside
API names that already use it (`marker_labels`) until item 9 review.

## Two findings that go beyond wording

**F1 — The user annotated `boroughs` as "(optional)" — today it is
required.** `quickmap()` has no default for `boroughs`; a call without it
fails. The sub-edit reveals the natural expectation: a true one-argument
call `quickmap("data.csv")` that auto-fits to the data with no boundary.
Making `boroughs` optional is an API change (philosophy-aligned:
progressive disclosure) — needs a user decision and belongs with the
item-9 stabilisation work, not a docs edit.

**F2 — Honesty caveat adopted:** "self-contained" pages still download
background map tiles online; the user's edit states this plainly
("though it does need an internet connection to download the background
maps"). Fold into every page that claims self-containedness.

## Application (after approval)

Apply P8–P15 + F2 to both existing pages (Get started using the user's
v3 text as the base, Layers by inference), rebuild, refresh the iCloud
pack, and fold the principles into the prospectus §4 list alongside
P1–P7. F1 goes to the roadmap as an item-9 decision.

# Page-template review v2 — codifying the second round of user comments

**Date:** 2026-07-08 · **Status:** comments codified, NO redrafting done
(user instruction). User sub-edited versions of the example pages are
expected 2026-07-09 for tone analysis; these principles are applied only
after that.
**Supersedes/extends:** dev/260708_page_template_review_v1.md (P1–P6,
approved and applied earlier today).

## The comments (Layers page, post-P1–P6 rework)

1. The opening example's parameters are not all explained — `boroughs`
   in particular is never explained, and the file contents get prose
   when a trivial explanation would do.
2. Prose descriptions of file contents should be replaced by a standard
   R data dump — the printed header of the tibble/CSV (`head()` output)
   — so the reader *sees* the required columns instead of reading about
   them.
3. The demo filenames are wrong for teaching
   (`bl_imperial_annualised_2021_2025_with_missing.Rdata` teaches
   nothing and intimidates). We need friendly canonical example files.
4. The first worked example is more complex than needed: adding
   *schools* (one simple CSV) is a better first reveal than adding a
   sensor network (a new file format + new columns).
5. Titles still not right: "Stack any number of sources — the `layers`
   list" should read as a plain instruction, "Use the `layers` list to
   add sources". And the `layers` parameter itself is never actually
   explained anywhere before being used.

## Codified: amendments to the principles

**P3′ (extends P3 — inputs shown, not described):** wherever an example
depends on a file's structure, show a `head()`/tibble dump of the first
rows instead of (or before) prose. The dump is itself a runnable chunk,
so the chunk harness keeps it truthful. Prose is reserved for what the
dump cannot show (units, coordinate system).

**P3″ (new — no unexplained parameter):** every parameter visible in an
example is explained at or before its first appearance, even trivially
("`boroughs` names the boundary to draw and fit the map to"). A page's
opening example explains *all* of its parameters. The check: read each
code block cold and ask "could the reader say what each argument does?"

**P4′ (amends P4 — instruction-first headings):** headings are plain
imperative instructions with the API element inside the sentence, not
appended: "Use the `layers` list to add sources", "Choose each layer's
symbol with `qm_layer(shape = )`". Same information, natural word order.

**P5′ (amends P5 — smallest increment first):** the first reveal is the
*smallest possible* step up from the opening (schools CSV before sensor
RData: one familiar format, one new concept). Order reveals by size of
step, not by importance of feature.

**P7 (new — teaching data):** the manual needs friendly bundled example
files with self-explanatory names (e.g. `tubes.csv`, `schools.csv`,
`sensors.RData`) shipped with the package (inst/extdata) so every
example reads cleanly and runs for any user, not just against the
private DATA_PATH. **This is an infrastructure decision, not a page
edit**: it touches the package contents and the chunk harness, and it is
the CRAN-correct way to make examples runnable (R CMD CHECK runs
examples). Proposed: small anonymised extracts of the existing fixtures.
Needs user approval; natural home is manual phase 2 alongside the "Your
data" chapter.

## What was deliberately NOT done

No page was redrafted. The user is sub-editing the current pages for
tone; P3′–P7 get applied together with the conclusions of that analysis.

## Open decisions for the user

1. Approve P3′/P3″/P4′/P5′ as template amendments (applied after the
   sub-edit round).
2. Approve pursuing P7 (bundled teaching data) in manual phase 2 —
   includes choosing extract sizes and names.

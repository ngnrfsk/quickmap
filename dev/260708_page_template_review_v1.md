# Page-template review v1 — against software-didactics best practice

**Date:** 2026-07-08 · **Status:** awaiting user approval, then folded into
the manual plan (dev/260707_manual_prospectus_v1.md §4) and applied to the
existing pages.
**Trigger:** user comments on the Layers page (PR #33), generalised here
into template rules, tested against the didactics literature, and fed back
for approval.

## 1. The user's comments, distilled

From the Layers page review:

1. The opening's first sentence carries real information ("a map is a
   stack of layers") but the follow-on describes *the page* ("this page
   takes you from…") — low-value meta-text. A useful elaboration of the
   concept should replace it, flowing straight into the first example
   **without a header**.
2. The two-line example shows no insight into what the files must
   contain, so it is not a meaningful start. A cross-reference alone is
   not enough; the minimum data requirement must be stated at the point
   of use.
3. Worked-example titles are information-light ("Add a sensor network")
   and don't visibly build on each other. A title should be pithy but
   carry the teaching point — the capability *and* the API element
   involved. Each section is a **reveal** that builds incrementally.

## 2. The principles, encoded

**P1 — Key information first; zero meta-text.** The page opens with the
concept in one or two substantive sentences (what a layer *is*, why
stacking matters), never with a description of the page. Structure
signposts; prose teaches. (Didactics: "inverted pyramid"; Nielsen's
scanning research; Carroll's minimalism — cut everything that is not the
user's task.)

**P2 — The first example is part of the opening, not a section.** Concept
flows directly into the minimal runnable call, unheaded. The two-line
promise is the *demonstration of the concept just stated*, not a separate
exhibit. (Worked-example effect, Sweller: lead with a complete example;
Carroll: get the user acting immediately.)

**P3 — Every example is self-sufficient at the point of reading.** Each
example states, in one sentence beside the code, what its input must
contain (e.g. "a CSV with Easting, Northing and one column per year"),
with the deep link for more. Never make the reader leave the page to
understand the line they are looking at. (Cognitive-load theory:
split-attention effect; Baker's "Every Page is Page One": assume arrival
with no prior page read.)

**P4 — Headings are assertions that name the API element.** Not "Add a
sensor network" but "Stack layers by listing them — `list()` in the first
argument"; not "Choose a marker shape" but "Each layer carries its own
symbol — `qm_layer(shape =)`". A reader scanning only headings should
come away knowing what the API can do and what each piece is called.
(Minimalism's "information-carrying headings"; news-graphics "assertion
headline" convention.)

**P5 — Strict incremental reveal, one concept per example, order
declared by the headings.** Example N uses only ideas introduced in
examples 1..N-1 plus exactly one new idea, which is the one its heading
asserts. The sequence covers: more layers → naming → per-layer options →
external data (OpenAir) → hand-built data → appearance. (Scaffolding /
gradual release of responsibility.)

**P6 — Two audiences, one page, three reading depths.** Beginner reads
prose top-down and stops when satisfied (P1–P3 serve them); practitioner
scans headings (P4 serves them); expert jumps to "Full detail" (existing
template §4 unchanged). This preserves the approved interleaved design —
these principles refine its execution, they don't change its shape.

## 3. Critical test — where the principles strain, and the compromises

- **P4 headings get long.** Assertion + API element can exceed a
  sidebar-TOC line. Compromise: assertion ≤ ~8 words, API element in
  code font at the end; drop the API element from the heading when it is
  the same as the previous heading's.
- **P2 (unheaded first example) vs navigation.** The first example gets
  no TOC entry. Acceptable: it is the page's opening, and the TOC's job
  is the reveals. Tested against pkgdown: rendering is fine; anchors
  unaffected.
- **P3 inline data requirements vs bloat.** One sentence only, formulaic
  ("needs: X, Y, one column per year — full spec: Your data"). If it
  can't be said in one sentence, the example is doing too much (split it).
- **P3 vs DRY / consistency risk.** Repeating column lists across pages
  can rot. Mitigation: keep them to the minimum-viable facts (column
  names only, no semantics) and let the item-9 consistency audit grep
  them; the chunk harness already proves the examples themselves run.
- **P5 strictness vs real pages.** The current Layers page violates P5
  once (the OpenAir example introduces both "external fetch" and
  "avg.time"). Acceptable cost — fixing it needs either two examples or
  one sentence flagging the second idea; choose per case, favour the
  sentence.

## 4. What changes concretely if approved

1. **Prospectus §4 template** rewritten to five parts with P1–P6 attached
   as normative rules (the "page shape" reviewers check against).
2. **Layers page** (PR #33) reworked to comply: opening elaborated (what
   a layer is; solid = measurements, outline = context), page-description
   sentence deleted, first example unheaded with its one-sentence data
   requirement, all six headings rewritten as assertions naming API
   elements, OpenAir example's second idea flagged in prose.
3. **Get started page**: minor — delete its one meta-sentence ("This
   page is the five-minute path…" becomes a single flowing opening),
   add the one-sentence data requirement beside the first map call.
4. **All future pages (phases 2–3)** are written to this template from
   the start; the review guide checklist gains a line per principle.

## 5. Approval

Options: approve as-is ("approve template"), amend specific principles,
or approve principles but defer the PR #33 rework to phase 2.

# Page-template review v4 — principles from the 2026-07-11 restructure

**Date:** 2026-07-11 · **Source:** user's review of the iframe-enabled
Get started page ("the quickmap.html file is good. Change: …").
**Status:** applied to both pages in the same change; principles below
generalise the instructions for all future pages. Extends P1–P15.

**P16 — Grouped progressive builds.** Worked examples are organised into
*parts*; each part uses one dataset and grows ONE call — every example
repeats the previous call and adds a line, and the added line is flagged
`# NEW:` in its inline comment. (Get started: Part 1 grows the Wandsworth
report map through boundary → vignette → DATA_PATH → export → title →
networks; Part 2 grows the episode animation → wind.)

**P17 — Every step shows its result.** Each example is followed
immediately by its actual output — the live interactive map as an iframe,
or the exported JPG as an image. Steps that had code but no visible
result (vignette, title, export) get one.

**P18 — The banner doubles as the symbol key.** When a map carries more
than one symbol type, the glyphs go into the title
("Merton NO2: ● tubes ◆ sensors ✖ schools") so the banner keys the map.
This is now the house style for multi-network examples and demo maps.

**P19 — Breathing space above headings.** Section headings get generous
top margin so numbered steps read as separate blocks — implemented once,
site-wide, in pkgdown/extra.css (never per-page inline styles).

**P20 — Features are indexed in context, not listed.** No standalone
"more features" section: each capability is mentioned inside the worked
example where it naturally arises, as a one-line italic pointer naming
the chapter and, where useful, the exact section ("the Layers chapter —
start at 'Use the `layers` list to add sources'"). The Get started page
thereby works as an index to the rest of the manual. Mapping applied:
colour scales → first map + animation; themes → vignette + title;
marker_labels → reading-the-map; display_times → export; data_symbols +
qm_layer → networks; 50-step compact format → animation; worldmet/wind
styling → wind step.

**Layout parity:** all manual pages use numbered `##` section headings
(Layers renumbered 1–8 in this change), so cross-references can cite
step numbers.

## Addendum 2026-07-11 (second round)

**P21 — Situational correctness.** Every statement adjacent to an example
must describe the behaviour of *that example as shown*. A capability the
example does not exercise is phrased as a possibility with a pointer:
not "Hover for details" (false for a map with labels off) but "Labels can
be added that appear on hover — step 8". Before publishing a page, read
each claim against its embedded map: would a reader trying it see exactly
that? Violations found and fixed in this sweep: the hover claim (step 2)
and "press play" on an autoplaying animation (step 10 → "pause it…").

**P22 — The page-worthiness test** (generalised from the labels case at
the user's direction, 2026-07-11). A feature earns its **own page** when
it meets at least TWO of these four criteria; exactly one criterion →
a **section** inside an existing chapter; none → an inline pointer at
the point of use is enough:

1. **Multiple user-facing modes or options** the reader must choose
   between (labels: five modes).
2. **Invisible inference** — behaviour decided by duck typing or
   defaults the user must be able to predict (labels: values vs `Label`
   vs `School` content).
3. **Documented gotchas / sharp edges** (labels: the empty-`Label`
   silent-drop).
4. **An anchor for planned work** that will need a documentation home
   (labels: the item-11 label-consistency fixes).

Audit of current features against P22 (validates the chapter map):

| Feature | Criteria met | Verdict |
|---|---|---|
| Labels | 1,2,3,4 | **own page (NEW — added to chapter map)** |
| Data input formats | 2,3 | own page ✓ (Your data, planned) |
| Themes + colour scales | 1,2 | own page ✓ (Styling, planned) |
| Time/animation (display_times, cap, lazy) | 1,2 | own page ✓ (Time, planned) |
| Wind | 1,4 (post-1.0 presets) | own page ✓ (Wind, planned) |
| Layer system (from_*, qm_layer) | 1,2 | own page ✓ (Layers, exists) |
| Static export | 1 (sizes/modes), 4 (item-11 subfolder defect) | own page — folded into planned Sharing & export ✓ |
| Symbols/shapes | 1 | section ✓ (inside Layers) |
| Boundaries/vignette | 1, 4 — RESCORED 2026-07-11: options family (names / "All" / boundary_labels / vignette) plus the item-11 ward-and-marker labelling work needing a home | **own page (NEW — added to chapter map, phase 2)** |

**Re-audit note (2026-07-11 third round):** the user found the boundary
step silent on `boundary_labels` — the gap-sweep that followed also added
per-step-JPG and default-size facts to the export step and
`banner_colour` to the title step. Re-running P22 with the fuller feature
picture moved Boundaries from "section" to "own page" (criteria 1 + 4).
Lesson folded into practice: run the P22 audit only AFTER listing every
parameter a feature owns — under-enumeration under-scores.

A labels step (marker_labels = TRUE with a live hover map) was added to
Get started in this change; the Labels page joins the phase-2 chapter
map.

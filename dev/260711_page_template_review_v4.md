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

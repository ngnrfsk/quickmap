# QuickMap — all open to-do lists, consolidated

**Date:** 13 July 2026 · **Version:** v0.9.9.8 · Compiled from
dev/PROJECT_STATUS.md, CLAUDE.md (roadmap), and
dev/260708_item9_check-baseline_v1.md. Those files remain the live
sources; this is a snapshot for reading.

---

## 1. Waiting on Iarla (the live ledger)

- [ ] **Review and approve the complete manual** — PR #37
      (https://github.com/ngnrfsk/quickmap/pull/37).
      Read at file:///Users/iarla/Coding/quickmap/docs/index.html
      or iCloud Drive → dev → pr31_manual_review.

*(Only item. The symbol-rename decision was made 13 July: rename with
the old name kept working, during item 9.)*

---

## 2. The roadmap (items 1–11)

| Item | What | Status |
|---|---|---|
| 1–8 | Packaging, safety-net tests, layer unit, quickmap() interface, backend decision, small animations, wind overlay, examples refresh | ✅ done, merged |
| 9 | Final tidy-up before release (list 3 below) | 🔶 started |
| 10 | The new look (strip banner, ramp legend, time slider) | ✅ signed off, merged |
| 11 | Screen-defect list (list 4 below) | ☐ deliberately last |

---

## 3. Item 9 — final tidy-up worklist

- [ ] Make the package pass R's formal check:
  - [ ] failing help-page example (reads a file that only exists on this
        machine — best fixed by the teaching-data item below)
  - [ ] the consistency test errors when run outside the project folder
        (should skip instead)
  - [ ] non-English characters (µ, °) in code need portable escapes
  - [ ] one internal function missing documentation for five arguments
  - [ ] build-folder exclusions (docs/ flagged as non-standard)
- [ ] Ship small teaching-data files inside the package so every manual
      and help-page example runs on any machine
- [ ] Tag 11 internal helper functions as internal (removes the website
      workaround that currently hides them)
- [ ] Exclude CLAUDE.md from the built website before any public
      deployment
- [x] DECIDED 13 July: rename `marker_labels` → `symbol_labels`, old
      name kept working (implement here: parameter, help pages, manual
      chapters, theme key, tests)
- [ ] Full documentation-versus-code audit — worklist is the traced API
      catalogue (dev/260712_api_catalogue_v1.md)

---

## 4. Item 11 — screen defects (final item before v1.0)

**From the LCA site review:**
- [ ] Collapsible controls, moved to the bottom-left corner
- [ ] Opening zoom should fill the screen with the data, no empty border
- [ ] Let the user choose which layer is visible when the map opens
- [ ] Re-check legend sizes across screen sizes

**High priority:**
- [ ] Static image export creates unwanted subfolders
- [ ] One unified size system for symbols, text and legend
- [ ] Ward and symbol labels consistent between still and interactive maps
- [ ] **New (Iarla, 12 July):** maps must stop consuming CPU and memory
      when their tab is in the background or the map is scrolled
      off-screen; resume seamlessly on return

**Low priority (kept on the list):**
- [ ] Separate data loading from map creation
- [ ] Automate label placement/clustering
- [ ] (packaging prep — largely superseded by items 1 and 9)

---

## 5. The manual

- [x] All thirteen pages built (Get started + Layers + nine chapters +
      reference), live example maps embedded, every code example
      machine-verified
- [ ] Nothing outstanding except the review in list 1

---

## 6. After v1.0 (decided and parked)

- Wind styling presets (muted, high-contrast, custom ramps as theme
  choices)
- Multi-station and gridded (ERA5) wind fields; automatic nearest-station
  choice
- Five ecosystem integrations, in suggested order: ERA5 wind, European
  data (saqgetr), worldwide data (OpenAQ), US networks + PurpleAir,
  raster underlays for modelled surfaces
  (survey: dev/260707_v2_integration_candidates.md)

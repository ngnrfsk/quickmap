# Roadmap item 10 (UI visual polish → v0.9.9.5): interface review + user MCQs

**Date:** 2026-07-08 · **Status:** STOPPED awaiting user answers to the
MCQs in §3. Per the roadmap, item 10 starts with an analysis of
design-template options ending in a recommended direction with mock-ups
for user approval before implementation — the MCQs below scope that
recommendation; mock-ups follow the answers.

## 1. What the interface is today (element review)

Grounded in inst/banner/*.css, inst/legend/*.css,
inst/controls/roller-menu.css, inst/controls/wind-controller.js and the
current signed-off maps (aq_maps/item9_*.html).

| Element | Today | Assessment |
|---|---|---|
| **Banner** | Full-width solid brand-colour bar, centred white Arial 1.3rem, 1.25rem padding | Functional but heavy: a thick colour slab in 2010s style; the title competes with the map for ~8% of viewport |
| **Legend** | Full-width bottom bar, light-grey; value ranges printed *inside* coloured monospace chips; footnote symbols (†‡§¶*) with a separate key row; collapsible via a header pill | Information-rich but visually loud — monospace chips read as code; the footnote-key convention is scholarly but obscure on first contact; occupies full map width |
| **Time control** | Top-right round play button + rounded dropdown ("2024 ▾"), brand-coloured, slide-in list, keyboard accessible | Solid interaction design; visual weight and 2rem offset feel bolted-on; dropdown hides the timeline (no sense of position within the period) |
| **Typography** | Arial everywhere; monospace in legend | Arial is the dated default; no typographic hierarchy beyond bold |
| **Colour of chrome** | Everything themed to the borough brand colour (banner, buttons, hovers, legend header tint) | Cohesive but saturating: brand colour dominates banner + controls + legend header simultaneously |
| **Markers/tooltips** | Canvas/SVG symbols (good); default Leaflet white tooltips | Tooltips unstyled relative to the rest |
| **Base tiles** | OSM default (busy roads/labels); CartoDB Positron available via theme but not default | Busy tiles fight the data layer |
| **Vignette** | Dark overlay outside boundary | Effective; opacity/colour not theme-exposed |
| **Wind particles** | Slate ramp, density 1/500, lineWidth 1 — **hardcoded** in wind-controller.js | Roadmap mandates exposing these through theme YAML in this item |
| **Static export** | Same chrome scaled — but the image-mode CSS text scaling is silently inert (bug logged 2026-07-05, folded into this item) | Broken; part of item-10 scope |
| **Mobile** | Breakpoint 480px: legend auto-collapse, rem sizing | Works; untuned |

## 2. Design-template options (roadmap-mandated analysis, summary)

- **A. News-graphics chrome (FT/Economist/BBC).** Muted warm neutrals,
  hairline rules instead of filled bars, small-caps/kicker titles, thin
  horizontal colour-ramp legend, understated controls. Best fit for
  "professional report" output; CSS-only; excellent print/static export.
- **B. GOV.UK design system conventions.** Black-on-white, strong focus
  states, large legible sans, no decorative colour; brand colour as thin
  accent only. Credible for the local-government audience; austere.
- **C. Modern product/dashboard.** System-ui/Inter stack, soft shadows,
  rounded floating cards over the map (legend and controls as overlays,
  banner as slim strip). Closest evolution of the current look.
- **D. Minimal cartographic.** Chrome recedes to near-invisible; Positron
  tiles default; typography does the identity work. Most "map-forward".

All four are achievable with the existing {{placeholder}} template/theme
system, self-contained (no framework runtime); fonts are the only asset
question (see MCQ 2). Themes stay user-configurable regardless.

## 3. The MCQs — answer with letters (e.g. "1A, 2B, …"); every question
also accepts "other: …"

**1. Overall design direction?**
A. News-graphics (FT/Economist-style report chrome) ← *recommended: matches the reporting use case and exports beautifully*
B. GOV.UK-style civic plainness
C. Modern dashboard (floating cards, evolution of current)
D. Minimal cartographic (chrome disappears)

**2. Typography?**
A. System font stack (SF/Segoe/Roboto via `system-ui` — zero file-size cost, modern, varies slightly by device) ← *recommended*
B. Bundled webfont (one look everywhere; ~30–80 KB added to every self-contained HTML)
C. Keep Arial

**3. Banner?**
A. Slim title strip: smaller type, left-aligned, thin brand-colour rule under it ← *recommended*
B. Keep full-width colour bar, refined (less padding, better type)
C. Floating title card overlaid on the map corner
D. No banner by default (title in browser tab only)

**4. Legend form?**
A. Thin horizontal colour-ramp bar with labels outside the colours (news-graphics convention) ← *recommended*
B. Keep chip row, restyled (proportional font, lighter chips)
C. Floating card on the map (collapsible)

**5. Legend footnote symbols (†‡§¶*) explaining bands?**
A. Replace with plain-language sub-labels under the ramp ← *recommended*
B. Keep footnote-symbol system, restyled
C. Move explanations into hover tooltips on the legend

**6. Time control?**
A. Compact stepper: ‹ 2024 › + play, with a thin progress underline showing position in the period ← *recommended*
B. Keep dropdown roller, restyled
C. Full slider along the bottom (scrubbing, biggest change)

**7. Brand colour usage?**
A. Neutral chrome; brand colour only as accents (title rule, selected states, play button) ← *recommended*
B. Keep fully brand-themed chrome (current), refined

**8. Base tiles default?**
A. CartoDB Positron (pale, data-forward) as the new default; OSM via theme ← *recommended*
B. Keep OSM default

**9. Wind-particle styling (exposed in theme YAML per roadmap — which defaults)?**
A. Keep current slate/1-per-500/width-1 as defaults, expose density, width, colour ramp, velocity scale ← *recommended*
B. Speed-coloured ramp default (particles coloured by wind speed)
C. Higher-contrast white particles default

**10. Mock-up format for the approval round (after these answers)?**
A. 2–3 real rendered maps with the new CSS applied (one direction, variants) ← *recommended*
B. Static image mock-ups of several directions side-by-side first
C. Skip mock-ups, iterate live on one map with feedback rounds

## 4. After the answers

Mock-ups per MCQ 10 → user approval → implementation through the
{{placeholder}}/theme system, including the wind-styling YAML exposure
and the image-mode scaling repair (logged bug), each behind the
characterization net and visual sign-off.

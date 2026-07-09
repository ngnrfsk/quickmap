# Roadmap item 10 (UI visual polish → v0.9.9.5): interface review + user MCQs

**Date:** 2026-07-08 · **Status:** answers received 2026-07-09 —
**settled: Q1 = UKHSA/BBC/OWID-inspired direction, Q2 = A (system
fonts), Q5 = B (keep footnote symbols, restyled), Q7 = A (neutral chrome,
brand accents), Q10 = real-data mock-ups.** Q3/Q4/Q6/Q8/Q9 answered
"show examples": rendered mock-ups built by
scripts/item10_mock-base-maps_v1.R + item10_mockups_v1.py +
item10_wind-mockups_v1.py → aq_maps/item10_*_v1.html, copied with a
choice README to iCloud dev/item10_ui_review/mockups/. Awaiting the
user's picks. Per the roadmap, item 10 starts with an analysis of
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

### 2a. Live examples of each direction (added 2026-07-09, user request)

Look at each on the device you'd review maps on. What to notice is the
*chrome* — titles, legends, controls — not the data.

**A. News-graphics:**
- FT Visual & Data Journalism gallery: https://ig.ft.com/ — kicker-style
  titles, hairline rules, muted palette; the Covid tracker
  (https://ig.ft.com/coronavirus-chart/) is the canonical free example
- The Economist Graphic Detail: https://www.economist.com/graphic-detail —
  thin ramp legends, small-caps headers, restrained red accent
- BBC News visual journalism, e.g. election maps at
  https://www.bbc.co.uk/news/election/2024/uk/results — plain sans,
  labels-outside-colour legends
  *(FT/Economist article pages may be paywalled; the chrome is visible
  before any paywall interstitial.)*

**B. GOV.UK civic:**
- Check for flooding live map: https://check-for-flooding.service.gov.uk/?v=map-live
  — black-on-white, thin accent, big focus states, map as a service
- UKHSA (ex-coronavirus) dashboard interactive map:
  https://coronavirus.data.gov.uk/details/interactive-map — the civic
  dashboard idiom
- DEFRA UK-AIR monitoring map: https://uk-air.defra.gov.uk/interactive-map
  — your own domain's incumbent look (dated; useful as the thing QuickMap
  outclasses)

**C. Modern product/dashboard:**
- PurpleAir map: https://map.purpleair.com — floating rounded cards over
  the map, system fonts, soft shadows
- IQAir world map: https://www.iqair.com/air-quality-map — polished
  commercial AQ chrome, pill-shaped legend
- Windy: https://www.windy.com — controls-as-overlays taken to the
  maximum (also relevant to wind-particle styling, MCQ 9)

**D. Minimal cartographic:**
- Our World in Data grapher maps, e.g.
  https://ourworldindata.org/grapher/death-rates-from-air-pollution —
  chrome nearly invisible, typography does the work, thin ramp legend
- Felt: https://felt.com/gallery — pale basemaps, data-forward, minimal
  floating UI
- Electricity Maps: https://app.electricitymaps.com — dark-minimal
  variant; shows how far "map dominates" can go

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

## 3a. Decisions round 2 (user, 2026-07-09) and the slider rationality test

- **Q3 banner: A and B as XOR theme options** — slim strip and refined
  colour bar both implemented, selectable per theme; strip proposed as
  default.
- **Q4 legend: A (thin ramp)** — chosen for mobile.
- **Q6 time control: bottom slider**, subject to the rationality test the
  user requested. **Verdict: rational, adopt with three design guards.**
  Reasoning: at the real scale (108–200 hourly steps) the alternatives
  fail structurally — a dropdown becomes a 200-item scroll list, a
  stepper needs up to 200 taps for random access; only a slider gives
  position-in-period, direct random access and scrubbing, and it is the
  video-player convention every user already knows. Touch feasibility:
  marker restyling measures 0.9–2.8 ms/step so live scrubbing is well
  within budget. The genuine weakness is thumb precision — at 108 steps
  on a ~24rem track each step is ~3 px. Guards: (1) fine-step ‹ ›
  buttons flank the track (drag = coarse, arrows = exact); (2) the
  current step label sits above the thumb at all times; (3) the 250 ms
  colour crossfade is suppressed during drag. Degrades gracefully to
  detents for 3-year annual maps.
- **Q8 tiles: A and B as XOR theme options** (Positron proposed default;
  any Leaflet provider name remains usable via `map.base_tiles`).
- **Q9 wind: speed-ramp default** (visibility rises with wind speed),
  implemented so ramps are swappable — see the post-1.0 note added to
  CLAUDE.md (wind styling presets as optional future development).

**Assembled design mocks** (scripts/item10_assembled-mockups_v1.py):
aq_maps/item10_assembled-annual_v1.html and
item10_assembled-episode-wind_v1.html — the complete look on real data,
awaiting final design sign-off before implementation. Slider remains a
visual mock until implementation.

## 4. After the answers

Mock-ups per MCQ 10 → user approval → implementation through the
{{placeholder}}/theme system, including the wind-styling YAML exposure
and the image-mode scaling repair (logged bug), each behind the
characterization net and visual sign-off.

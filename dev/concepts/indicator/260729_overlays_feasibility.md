# Aggregate indicator and change-over-time graph — feasibility study

Date: 2026-07-29. Status: study only, nothing implemented.
All claims below were checked against the code on branch `feature/manual-phase2`.

## What I found

Both features are buildable with the machinery already in the package, with no
new R or JavaScript dependencies and no charting library. Hand-drawn inline SVG
is the right route; a charting library would add 45 KB–3.5 MB to a file that is
emailed, for no gain.

The one real cost is plumbing. The per-step aggregate numbers do not exist
anywhere today. They have to be computed in R and threaded through four function
signatures — exactly the path `data_max` already takes, so the route is proven,
just tedious.

The genuinely hard part is not code, it is measurement. Merton's site network
changes between years, so "the network mean" is not comparable year to year
unless you fix the rule. That is your decision, not mine, and it should be
settled before any code is written.

Neither feature is on the roadmap, so both need your approval to schedule at all.

## Recommendation

1. **Build A (the indicator) first**, placed **in the legend block**. It is the
   smallest change, it reuses the existing threshold data, and it is the only
   placement that appears correctly in the static JPG exports without new
   layout work. Roughly 2–3 days.
2. **Build B (the change-over-time graph) second, as a separate piece of work**,
   and only if A lands cleanly. It is a further 1.5–2 days and it shares A's
   data plumbing, so it is cheap *after* A and expensive *instead of* A.
3. **Drop the banner placement** for A. The banner is a slim strip whose whole
   design point (v0.9.9.5) is that it is quiet; a thermometer in it fights the
   title, and on mobile the banner already shrinks.
4. **Defer the floating-card-on-map placement** for both. It collides with the
   bottom time slider and the legend collapse behaviour, and it does not
   appear in static exports without extra work.
5. **Schedule both after v1.0.** Neither is in the roadmap; inserting them
   before roadmap items 9 and 11 would stack unreviewed rendering changes,
   which CLAUDE.md explicitly forbids.

---

## 1. Where the code change lands

Everything named here was read; line numbers are as of today.

### The chrome is built in one place

All banner/legend/control HTML is added *after* the Leaflet widget is saved, by
rewriting the file:

- `/Users/iarla/Coding/quickmap/R/quickmap.R`, `inject_banner_legend_controls()`
  (line 2093). It reads the saved HTML, checks that `</head>`, `<body` and
  `</body>` are present (hard error if not), and injects CSS before `</head>`,
  the banner and `<div class="map-container">` after `<body>`, and the time
  control plus legend before `</body>`.

So both features are injected here, or in a helper called from here. Nothing
else needs to move.

### Feature A — indicator, in the legend

- New builder function, e.g. `generate_indicator_html()`, alongside
  `generate_legend_html()` in `/Users/iarla/Coding/quickmap/R/quickmap.R`
  (line 1417). It emits inline SVG.
- Template file `/Users/iarla/Coding/quickmap/inst/legend/indicator.html` plus
  styles added to `/Users/iarla/Coding/quickmap/inst/legend/legend-interactive.css`
  and `/Users/iarla/Coding/quickmap/inst/legend/legend-image.css`.
- **Hazard:** `/Users/iarla/Coding/quickmap/inst/legend/legend.html` is filled
  by `sprintf()` with four bare `%s` slots (see `generate_legend_html()`, line
  1518), *not* by the `{{placeholder}}` pattern. CLAUDE.md's "Named Placeholder
  Pattern" section is only true of the CSS builders. Adding a fifth slot means
  adding a fifth `sprintf` argument in the right position, and any literal `%`
  in injected content (e.g. a percentage sign in a label) will break the call.
  I would convert this template to `apply_template_replacements()`
  (`/Users/iarla/Coding/quickmap/R/quickmap.R` line 72) as part of the work —
  it is a five-line change and removes a real footgun.
- CSS colours are threaded by `build_legend_css()` (line 1614) via
  `{{legend_header_bg}}` / `{{legend_header_hover}}`; a brand-accent variable
  for the indicator arrow follows the same pattern.
- The threshold marks come free: `load_colour_scale()` (line 1096) already
  returns the thresholds, and
  `/Users/iarla/Coding/quickmap/inst/config/scales/who_no2.yaml` already carries
  `[0, 10, 20, 30, 40, ...]` with the WHO/UK labels. **No new configuration is
  needed to know where the target lines go.**

### Feature B — change-over-time graph

- Second builder, e.g. `generate_trend_html()`, same file, emitting an inline
  SVG polyline plus dots, with the current step marked by a `<circle>` the
  JavaScript moves.
- Placement: in the legend block next to the indicator (recommended), or as its
  own absolutely-positioned card inside `.map-container`. `.map-container` is
  `position: relative` (`/Users/iarla/Coding/quickmap/inst/banner/banner-interactive.css`
  line 19), so a card can be positioned against it — but note line 20,
  `.map-container > div:not(#yearControl) { height: 100% !important; }`, which
  would stretch any new direct child to full height. A new card must therefore
  be excluded from that rule or nested, or it will fill the map.

### Making them move with the time step

- `/Users/iarla/Coding/quickmap/inst/controls/time-slider.js` is the single
  place where a step change happens: `setIndex()` (line 111) calls `render()`
  and then `switchToTime()` (line 20). `switchToTime()` already fans out to
  `window.quickmapWindController` and `window.quickmapTimeController`.
- The clean hook is to add one more optional global in the same style, e.g.
  `if (window.quickmapIndicatorController) window.quickmapIndicatorController.setTime(selected);`
  placed at the top of `switchToTime()` **before** the early `return` on
  line 28 — that `return` is why the wind call sits above it, and a naive
  insertion below it would silently never fire on the lazy path.
- Roughly 6 lines of change in `time-slider.js`, plus a small new
  `/Users/iarla/Coding/quickmap/inst/controls/indicator.js`.

## 2. The two rendering paths

Both paths are decided in `render_pollution_map()`
(`/Users/iarla/Coding/quickmap/R/quickmap.R` line 3186) at lines 3309–3335 via
`use_lazy_rendering()` (line 1955).

**One implementation serves both, cleanly.** The reason:

- The pre-built path installs `window.quickmapLayerCache` keyed by time step
  (`/Users/iarla/Coding/quickmap/inst/controls/layer-cache.js` line 23).
- The lazy path installs `window.quickmapTimeController` *and* a stub
  `window.quickmapLayerCache` with the same keys
  (`/Users/iarla/Coding/quickmap/inst/controls/lazy-time-controller.js`
  lines 224–227) precisely so the slider's initialisation
  (`time-slider.js` line 52, which waits for the cache) works identically.

So the slider drives both paths through the same `switchToTime()` call, and an
indicator hooked there is path-agnostic. The aggregate values themselves should
be emitted as a small standalone JSON blob in the injected `<script>` — **not**
folded into the lazy payload, because the lazy payload does not exist on the
pre-built path at all (`lazy_payload` is `NULL` there, line 3317).

Do not try to compute the aggregate in JavaScript from the lazy payload. It
would work on the lazy path and be impossible on the other one.

## 3. Static JPG export

The export loop is lines 3340–3391 of `render_pollution_map()`: one complete
map per time step, saved and screenshotted by `webshot2::webshot()` in
`finalize_and_save_map()` (line 1752), then the intermediate HTML deleted.

- In image mode the interactive time slider is replaced by a plain label pill
  built in R by `load_time_slider_control()` (lines 1840–1855) — **no
  JavaScript is injected**. So an indicator in a JPG must be rendered
  server-side, as static SVG for that one step. That is straightforward: the
  export loop already calls the whole injection chain once per step `yr`, so
  the per-step value just has to be selected in R rather than in the browser.
- **Scaling: these overlays would NOT inherit the known defect**, provided they
  are written in `rem` units. `inject_banner_legend_controls()` lines 2134–2149
  set `html { font-size: 16 * scale_factor px }`, where `scale_factor` is the
  geometric mean of the export size against the 1200x1200 baseline. Every
  image-mode chrome file is already rem-based (see
  `/Users/iarla/Coding/quickmap/inst/legend/legend-image.css`). At 4000x3000
  the factor is about 2.9 and the whole legend block, including a rem-based
  indicator, scales with it.
- The residual part of defect 9 is elsewhere: **marker label text** is sized in
  `add_layer()` at line 2506 as `12 * label_sizing`, and
  `generate_map_layers()` hardcodes `label_sizing = 1.0` at lines 2849 and 2869
  while passing the real `image_scale_factor` on to the icons. So marker labels
  stay at 12 px at any export size. An SVG overlay does not touch that code and
  would not be affected — but if the SVG is given fixed pixel sizes it will
  reproduce the same bug by hand. Use `rem` and `viewBox`, never `px`.
- Related open risk: PROJECT_STATUS issue 12 (added 2026-07-29) records that
  webshot2/chromote fails intermittently. More chrome to render slightly
  lengthens each screenshot; it does not cause the failure, but a longer batch
  meets it more often.

## 4. Self-contained constraint

Output is written with `htmlwidgets::saveWidget(selfcontained = TRUE)` in
`save_html_and_style()` (line 1796) and then rewritten in place, so anything
injected is literally inside the file. Both features can be built entirely from
inline SVG, inline CSS and vanilla JavaScript — no fonts, no images, no network.

Rough size cost added to every output HTML:

| Option | Added size |
|---|---|
| A, hand-rolled inline SVG + CSS + JS | ~3–5 KB |
| B, hand-rolled inline SVG sparkline | ~4–6 KB |
| Per-step aggregate values as JSON, 200 steps | under 3 KB |
| uPlot (smallest credible chart library) | ~45 KB minified |
| Chart.js | ~200 KB minified |
| Plotly | ~3.5 MB |

For context the widget base is roughly 520 KB–1 MB. A hand-rolled overlay is
under 1% of the file; Chart.js would be a fifth of it, for two static-looking
graphics. **A charting library is not justified here.** A thermometer bar with
tick marks and an arrow, and a 6–8 point line with a highlighted dot, are each
a few dozen lines of SVG. Hand-rolled is also the lower-risk route for the
static export, because there is no library initialisation for webshot to race.

## 5. Where the aggregate number comes from

**It does not exist today and must be computed and threaded through.** Honest
assessment: this is the bulk of the work.

The closest precedent is `data_max`, and it shows the exact route:

- computed in `render_pollution_map()` at line 3293 by `get_data_maximum()`
  (line 751), which loops the enabled non-static layers in
  `spatial_data$all_data`, filters to `display_times`, and takes a max;
- passed to `finalize_and_save_map()` (line 1698, argument `data_max`);
- passed on to `save_html_and_style()` (line 1779);
- passed on to `inject_banner_legend_controls()` (line 2093);
- finally used by `generate_legend_html()` (line 1417) to trim the legend.

Four signatures, plus both call sites of `finalize_and_save_map()` (lines 3367
and 3412). A new argument follows the same path.

The difference the brief anticipates is real: `data_max` is **one number for the
whole map**, an aggregate is **one number per time step** — a named vector. That
changes three things:

1. The interactive map needs the whole vector embedded (all steps), because the
   user can scrub to any of them.
2. The static export needs only the single value for the step being drawn, and
   the loop already has `yr` in hand, so it can subset.
3. The aggregation itself is a `tapply`-style summary over `year_str`, over
   possibly several layers at once — genuinely new code, though small
   (roughly 30 lines, mirroring the structure of `get_data_maximum()`).

One convenience: `build_lazy_payload()` (line 1978) already builds exactly the
sites-by-times matrix an aggregate wants (lines 2029–2031). It is tempting to
reuse it, but it only runs on the lazy path. Write the aggregate against
`spatial_data$all_data` like `get_data_maximum()` does, so one code path serves
both. Note also that `get_data_maximum()` prints `message()` chatter; a new
aggregate function should stay quiet, per the code-minimalism rule in CLAUDE.md.

## 6. Statistical honesty — decide before building

These are the issues I would not want shipped without a deliberate choice.

- **Changing site network.** Three Merton sites opened partway through
  2019–2025. A mean over "all sites present in that year" will move because the
  network changed, not because the air did. Options: (a) **fixed panel** —
  restrict to sites with data in every displayed step, which is comparable but
  discards sites and can collapse to very few; (b) **all sites, with a caveat**
  printed next to the figure and the site count shown per step. Your call.
- **Mixing measurement types.** A map can carry diffusion tubes and Breathe
  London sensors in the same aggregate. Those have different biases and
  different siting. A single "network mean" across both is defensible only if
  you say so explicitly, and per-layer figures may be more honest.
- **Mean or median.** Diffusion tube surveys are usually skewed by a few
  roadside sites; a mean overstates typical exposure, a median hides the worst.
- **Not a population exposure figure.** A mean over monitoring sites is a mean
  over *where people chose to monitor*, which is deliberately biased toward
  hotspots. Comparing it to the WHO guideline of 10 invites a reader to conclude
  something about the borough's air that the number does not support. Whatever
  label sits above the thermometer needs to say "network mean of N monitoring
  sites", not "Merton NO2".
- **Sub-annual maps.** The annual-mean thresholds in the WHO/UK scales do not
  apply to a monthly or hourly step. Showing a 40 µg/m³ "UK limit" line against
  an hourly mean is wrong. The indicator should either be suppressed for
  sub-annual resolutions or carry a different target set.
- **Missing data.** A site absent in one step must not be silently treated as
  zero. `build_lazy_payload()` leaves gaps as `NA` (line 2029) and the aggregate
  must too.

## 7. Theme configurability

`load_theme()` (line 1214) merges the user YAML over `get_default_theme()`
(line 1167) with `modifyList()`, so new keys are added to `get_default_theme()`
and are then overridable. `render_pollution_map()` reads theme values at lines
3218–3239. Suggested keys:

```yaml
indicator:
  show: false            # off by default; opt-in feature
  statistic: mean        # mean | median
  sites: all             # all | fixed_panel  (see section 6)
  placement: legend      # legend | map
  label: "Network mean"  # text above the scale
  targets: null          # null = take the colour scale's thresholds
trend:
  show: false
  placement: legend      # legend | map
  statistic: mean        # normally inherits `indicator.statistic`
  height: 3              # rem
```

Colours should not be new keys: reuse the brand accent already threaded as
`banner_colour` into `build_legend_css()` and `load_time_slider_control()`, so
existing themes look right with no edits. The five files in
`/Users/iarla/Coding/quickmap/inst/themes/` need no changes if the defaults are
`show: false`.

## 8. Effort and risk

**A, indicator in the legend — 2–3 days.**
Breakdown: aggregate computation and four-signature threading (1 day); SVG and
CSS for both interactive and image modes (0.5–1 day); JS hook and slider change
(0.5 day); tests, demo maps and docs (0.5 day).
Most likely to go wrong:
- The `sprintf` legend template silently mangling content containing `%`.
- The image-mode legend is a **horizontal flex row**
  (`legend-image.css` lines 10–16); adding a thermometer changes the width
  balance and can push the colour-ramp labels into overlap at small export
  sizes. Expect layout iteration and a human eyeball round.
- Forgetting `rem` somewhere and reinventing defect 9.
- Placing the new call after the early `return` in `switchToTime()`, giving an
  indicator that works on small maps and freezes on large ones — a bug that
  only shows above 50 time steps.

**B, trend graph — a further 1.5–2 days** if built after A (it reuses A's
aggregate vector), or 3–4 days if built alone.
Most likely to go wrong:
- Space. The legend block is already title + ramp + labels + pill key; a
  sparkline is a fourth element competing on a slim strip, and the mobile
  collapse rules in `/Users/iarla/Coding/quickmap/inst/legend/mobile.css` will
  need extending.
- Axis honesty: an unlabelled sparkline with an auto-scaled y axis can make a
  1 µg/m³ drift look like a collapse. It needs a zero baseline or explicit
  end labels, which costs more space again.
- Many time steps. At 200 steps a sparkline in a 20 rem box is 0.1 rem per
  point — legible as a shape, useless as a reading. Consider showing it only
  when steps are few (say 20 or fewer), which is the annual-map case the user
  actually described.

**Overall risk that matters most:** neither feature is on the roadmap. CLAUDE.md
requires human visual sign-off for anything touching the legend or HTML
post-processing, and forbids stacking unreviewed rendering items. Inserting
these ahead of roadmap items 9 (CRAN compliance) and 11 (UI defects) would do
exactly that.

---

## Decisions — ANSWERED by the user, 2026-07-29

All eight were put to Iarla as multiple choice and answered. The answers are
binding for implementation; the options are kept below for the record.

1. **When?** → **(c) Now, ahead of roadmap items 9 and 11.** The stacking risk
   is accepted knowingly. Consequence: this is a rendering-touching change, so
   it blocks on human visual sign-off before merge, and no second unreviewed
   rendering item may be started until it is signed off.
2. **Which features?** → **(b) Indicator now, trend graph later** as separate
   work.
3. **Where?** → **(a) Inside the legend block.**
4. **Which sites?** → **(a) Fixed panel** — only sites with data in every
   displayed step. The figure is comparable across years; the site count and
   the exclusion must be stated somewhere visible.
5. **Mean or median?** → **(a) Mean**, matching the "annual mean" language of
   the reports this feeds.
6. **One figure or one per layer?** → **(b) A single combined figure always**,
   across every measurement layer. Noted for the record: on a map carrying both
   diffusion tubes and reference-grade sensors this averages two measurement
   methods into one number. The user chose this with that caveat stated.
7. **Sub-annual maps?** → **(a) Hide the indicator automatically** — with a
   backlog item raised for a future resolution-appropriate target set (daily,
   hourly limit values). See issue 13 in
   `/Users/iarla/Coding/quickmap/dev/PROJECT_STATUS.md`.
8. **Trend graph at many time steps?** → deferred; the graph itself is deferred,
   so this is decided when it is built.

### The options as originally put

1. **When?** Options: (a) after v1.0 as a post-1.0 item, which is what the
   roadmap rules imply; (b) folded into roadmap item 11 (UI defects) as new
   scope; (c) now, ahead of items 9 and 11, accepting the stacking risk.
2. **Which features?** Options: (a) indicator only; (b) indicator now, trend
   graph later as a separate piece of work; (c) both together; (d) trend graph
   only. My recommendation is (b).
3. **Where does the indicator sit?** Options: (a) inside the legend block —
   scales correctly, appears in JPGs, cheapest; (b) in the banner strip;
   (c) a floating card on the map. My recommendation is (a); (b) and (c) both
   cost extra and (c) collides with the time slider.
4. **Which sites go into the aggregate?** Options: (a) fixed panel — only sites
   with data in every displayed step, comparable across years but discards
   sites; (b) all sites present in each step, with the site count shown and a
   caveat in the label. This is the decision I most want from you before code
   is written.
5. **Mean or median?** Options: (a) mean, familiar and matches "annual mean"
   language; (b) median, more robust to a few roadside hotspots; (c) offer both
   via `indicator.statistic` and default to one.
6. **One figure or one per layer?** Options: (a) a single combined figure
   across diffusion tubes and sensors; (b) one indicator per data layer;
   (c) combined, but only when the map has a single measurement layer, and
   suppressed otherwise.
7. **What happens on sub-annual maps** (monthly, daily, hourly), where the
   annual-mean thresholds do not apply? Options: (a) hide the indicator
   automatically; (b) show it with no target lines; (c) show it with a
   different, resolution-appropriate target set that you supply.
8. **Should the trend graph appear when there are many time steps?** Options:
   (a) always; (b) only at or below a step count you choose (20 is a sensible
   default); (c) always, but thinned to a fixed number of plotted points.

---

## What I could not verify

- I did not run any map generation for this study, so the size figures for the
  injected SVG and JSON are estimates from the template sizes on disk
  (for scale: `/Users/iarla/Coding/quickmap/inst/controls/time-slider.js` is
  8.1 KB and `time-slider.css` is 2.9 KB), not measurements of a built file.
- The third-party library sizes in section 4 are from general knowledge, not
  from anything in this repository.
- I did not test how a widened legend block behaves at 4000x3000; the claim
  that rem-based chrome scales is read from the code
  (`inject_banner_legend_controls()` lines 2143–2148) and from the fact that
  every image-mode CSS file uses rem, not from a rendered image.

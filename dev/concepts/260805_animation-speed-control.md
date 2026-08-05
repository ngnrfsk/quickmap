# Concept: an animation speed control on the map

Status: **agreed, not built.** Specified with Iarla on 5 August 2026; approved
in principle, scheduled to start after the legend indicator merged (it did, on
5 August, as PR #38). Roughly half a day.

## What it is

A small button in the time-slider card showing the current playback
multiplier. Pressing it cycles through the speeds; the label always says which
one you are on.

## The agreed settings

- **Multipliers:** 0.25 → 0.5 → 1 → 2 → 4 → 8, wrapping back to 0.25
- **Default:** 1×. Iarla originally proposed a 0.5× baseline; changed on the
  argument that `play_speed` in the theme is already the author's chosen pace,
  so opening at half of it would make the theme setting misleading. 0.5× and
  0.25× remain available for anyone who wants slower.
- **Hidden below 480px**, matching the breakpoint the legend already uses. A
  phone keeps the theme's speed and loses only the control.
- Iarla's ordering (1, 2, 4, 8, 0.25, 0.5) and this one differ only in where
  the cycle starts: both contain exactly one large jump, at 8× back to 0.25×.

## Default timing, which changes too

The current default is a flat 500ms per step, which is too fast for an annual
map: the 250ms colour crossfade is then half the interval, so the map is in
motion as much as it is still.

| Steps | Default |
|---|---|
| ≤ 12 (annual) | 1200ms |
| 13–60 (monthly) | 800ms |
| > 60 (daily/hourly) | 450ms |

At 1200ms the fade is 21% of the step, leaving about 950ms settled — enough to
read the year and scan the markers. Seven Merton years then run in 8.4 seconds.

## The crossfade must become proportional

`FADE_MS` is fixed at 250ms in
`/Users/iarla/Coding/quickmap/inst/controls/lazy-time-controller.js`. Divide a
1200ms step by 8 and you get 175ms — shorter than the fade, so steps overlap
and the animation looks mushy. On a 500ms episode map even 4× breaks it.

Fix: make the fade a proportion of the interval — 40%, capped at 250ms. That
keeps it right at every speed and every multiplier, and removes the need to
special-case fast playback.

## Where the work lands

- `/Users/iarla/Coding/quickmap/inst/controls/time-slider.html` — one more
  button in the card
- `.css` — its styling and the below-480px rule
- `.js` — the speed already lives in `config.playSpeed`, read by two
  `setInterval` calls; **both** must be updated or the speed will change on
  play but not after a drag
- `/Users/iarla/Coding/quickmap/R/quickmap.R` — the step-count-based default
- `lazy-time-controller.js` — the proportional fade

No new R plumbing: `play_speed` already flows to the browser as
`window.quickmapConfig`.

## Open question

Six speeds means up to five presses to reach the one you want. R knows the step
count when it builds the map, so it could ship a shorter set (0.5, 1, 2, 4) for
short animations and the full set only where 8× is worth having. Not decided.

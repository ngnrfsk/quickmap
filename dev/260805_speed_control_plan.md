# Plan: animation speed control

Date: 2026-08-05. Concept and rationale:
`/Users/iarla/Coding/quickmap/dev/concepts/260805_animation-speed-control.md`.
Estimated half a day plus a visual round. Branch off main.

## What is being built

A button in the time-slider card showing the playback multiplier. Pressing it
cycles 0.25 → 0.5 → 1 → 2 → 4 → 8 and wraps. Default 1×. Hidden below 480px.

Two settings change at the same time, because the control exposes a problem
that is already there:

- the default step timing becomes step-count based — 1200ms for ≤12 steps,
  800ms for 13–60, 450ms above that — instead of a flat 500ms
- the colour crossfade becomes 40% of the step interval, capped at 250ms,
  instead of a fixed 250ms

## Steps

1. **Crossfade first, on its own.** `FADE_MS` in
   `inst/controls/lazy-time-controller.js` becomes a proportion of the
   interval. Verify at the current speeds before anything else moves: the
   annual map should look unchanged, the 108-step episode map smoother.
2. **Step-count defaults.** In `R/quickmap.R`, where `play_speed` is read from
   the theme in `render_pollution_map()`, fall back to the table above rather
   than to a constant. An explicit theme value still wins.
3. **The button.** One element in `inst/controls/time-slider.html`, styled in
   `.css` with the below-480px rule, wired in `.js`.
4. **Both timers.** `config.playSpeed` is read by two `setInterval` calls in
   `time-slider.js`. Change one and the speed will apply on play but not after
   a drag — this is the likeliest bug in the whole job.
5. **Keyboard and labels.** Match the existing buttons: `aria-label` that
   states the current speed, focusable, activates on Enter and Space.

## Tests

- the multiplier cycles and wraps, and the interval is the theme speed divided
  by it
- both `setInterval` sites use the same source of truth
- the crossfade never exceeds 250ms and never exceeds 40% of the interval
- the step-count defaults produce 1200/800/450 at 7, 30 and 108 steps
- the control is absent from a static export (image mode has no controls)

## Verification

Two demonstration maps: the Merton annual set (7 steps) and the episode map
(108 steps), each played at 0.25× and 8×, checked for dropped or smeared
frames. Static exports must be unchanged — this is interactive-only, so any
difference in an exported JPG is a bug.

## Open question, to settle during the work

Six speeds means up to five presses. R knows the step count at build time and
could ship a shorter set (0.5, 1, 2, 4) for short animations, keeping 8× only
where there is enough to fast-forward through. Decide once the button exists
and can be felt.

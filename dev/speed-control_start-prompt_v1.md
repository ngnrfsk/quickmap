# Kick-off prompt: animation speed control

Paste the block below into a fresh session. Everything it needs is on main.

---

Build the animation speed control.

Read these two first, in this order:

- `/Users/iarla/Coding/quickmap/dev/260805_speed_control_plan.md` — the work
  plan: five steps, the tests, and the bug most likely to bite
- `/Users/iarla/Coding/quickmap/dev/concepts/260805_animation-speed-control.md`
  — why each setting is what it is, including the ones I argued Iarla out of

Then read CLAUDE.md as usual, in particular the automated gate and the
permission-safe command style.

Branch off main. This is a rendering change, so it blocks on Iarla's visual
sign-off before merge, and nothing else rendering-related starts until it
lands.

## What you are building, in one paragraph

A button in the time-slider card showing the playback multiplier, cycling
0.25 → 0.5 → 1 → 2 → 4 → 8 and wrapping, defaulting to 1×, hidden below 480px.
Two related settings change at the same time because the control exposes a
problem already present: the default step timing becomes step-count based
(1200ms for ≤12 steps, 800ms for 13–60, 450ms above), and the colour crossfade
becomes 40% of the interval capped at 250ms instead of a flat 250ms.

## Things that will save you a day

- **Do the crossfade change first and on its own**, and check the existing maps
  look unchanged before anything else moves. If you change the speed and the
  fade together, you will not know which one caused what you are looking at.
- **`config.playSpeed` is read by two `setInterval` calls** in
  `inst/controls/time-slider.js`. Change one and playback will be correct until
  the first drag, then wrong. This is the likeliest bug in the job.
- **Verify by rendering, not by reasoning.** Every layout claim made from
  reading CSS during the indicator work turned out wrong when screenshotted;
  every claim made from a screenshot held. `scripts/legend_width-sweep_v2.R`
  shows the pattern — render at several sizes, then look.
- **Static exports must be byte-for-byte unaffected.** Image mode has no
  controls at all, so any difference in an exported JPG is a bug, not a
  side effect.

## Demonstration maps Iarla will want

Two, both animated: the Merton annual set (7 steps) and the episode map
(108 steps), each playable at 0.25× and 8×. Name them for the item and version,
and do not reuse filenames from an earlier round — the previous session lost a
set of examples that way and had to rebuild them.

## The open question

Six speeds means up to five presses to reach the one you want. R knows the step
count when it builds the map, so it could ship a shorter set (0.5, 1, 2, 4) for
short animations and the full set only where there is enough to fast-forward
through. Decide once the button exists and can be felt, and put the question to
Iarla rather than choosing silently.

## House style for replies

Short. Around ten lines unless depth is asked for. Recommendation first, plain
language, absolute file paths in `file:///` form, and any decision for Iarla in
its own block at the end of the message — never buried mid-paragraph.

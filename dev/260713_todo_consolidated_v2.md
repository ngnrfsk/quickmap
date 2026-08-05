# QuickMap — everything still to do, in one self-contained list

**Date:** 13 July 2026 · **Version:** v0.9.9.8
Every open item is written out in full here; nothing requires opening
another document. (Provenance, for the record only: these items were
gathered from the project status file, the roadmap, and the release
worklist, all in this folder.)

---

## A. Waiting on Iarla — one item

- [ ] **Review and approve the complete user manual.**
      Open file:///Users/iarla/Coding/quickmap/docs/index.html (or on
      the iPad: iCloud Drive → dev → pr31_manual_review), read the
      thirteen pages, then say "approve complete manual" or send
      amendments. Merging PR #37
      (https://github.com/ngnrfsk/quickmap/pull/37) follows approval.

---

## B. Release tidy-up (roadmap item 9) — do after the manual merges

**B1. Make the package pass R's formal check (currently 2 errors,
2 warnings, 2 real notes):**

- [ ] The help page for the old map function runs an example that reads
      a file that only exists on this machine, so the check crashes.
      Fix by pointing examples at packaged data (B2) or marking them
      not-run.
- [ ] The internal-consistency test crashes when the package is checked
      outside the project folder; it should quietly skip there instead.
- [ ] The main code file contains µ and ° characters, which R requires
      to be written as portable escape codes.
- [ ] One internal function (the HTML injector) has five undocumented
      arguments; write their one-line descriptions.
- [ ] Tell the package builder to ignore the docs/ website folder (it is
      flagged as non-standard content).
- [ ] Declare two standard-library functions (median, complete.cases)
      and thirteen data-column names so the checker stops warning about
      "undefined variables".

**B2. Package the teaching data.** Put small extracts of the example
files (tubes, schools, sensors, episode, wind) inside the package
itself, so every example in the manual and the help pages runs on any
machine — today they need Iarla's local data folder.

**B3. Tag the 11 internal helper functions as internal** (their help
pages currently leak into the public reference; a website workaround
hides them, which can then be removed): the boundary drawer, legend
builder, colour converters, label parsers, scaling helpers, the postcode
geocoder, and friends.

**B4. Keep CLAUDE.md out of the built website.** The site generator
currently renders the internal instructions file into the site; exclude
it before the site is ever published.

**B5. Rename `marker_labels` to `symbol_labels`** (decided by Iarla,
13 July; old name keeps working forever). Touch: the parameter on both
map functions, the help pages, the manual chapters that mention it, the
theme file key, and add tests proving both names work.

**B6. Final documentation sweep.** Read every one of the fourteen public
help pages against the traced true behaviour (the API catalogue in this
folder is the crib sheet) and fix any remaining claim that doesn't match
the code; refresh the architecture section of CLAUDE.md the same way.

---

## C. Screen defects (roadmap item 11) — the last item before v1.0

**From the LCA website review:**

- [ ] Map controls should collapse and sit in the bottom-left corner.
- [ ] A map should open zoomed so the data fills the screen — no wide
      empty margins.
- [ ] Let the map maker choose which layer is showing when the map first
      opens.
- [ ] Re-check that the legend sizes correctly on small screens.

**High priority:**

- [ ] Static image export leaves behind junk subfolders of web libraries;
      stop that.
- [ ] One unified sizing system for symbols, text and legend (today each
      scales by its own rules; this also covers the old image-text-size
      bug properly).
- [ ] Ward labels and symbol labels should look the same on still
      exports as on interactive maps.
- [ ] **Background CPU (Iarla, 12 July):** an open map keeps animating
      when its tab is hidden or it is scrolled off screen, hogging CPU
      and memory — pause the wind particles, colour fades and autoplay
      whenever not visible, resume seamlessly on return.

**Low priority (long-standing wishes, keep or cut at v1.0):**

- [ ] Separate "load the data" from "draw the map" as two steps.
- [ ] Automatic label placement so labels don't overlap.

---

## D. Parked until after v1.0 (all decided, none started)

- [ ] Wind styling presets — ready-made particle looks (muted,
      high-contrast, custom colour ramps) selectable per theme.
- [ ] Real wind fields — automatic nearest-weather-station choice,
      several stations blended, or full gridded forecasts (ERA5), so
      wind varies across the map instead of being uniform.
- [ ] Data-source integrations, in the agreed order:
  - [ ] ERA5 gridded wind (completes the wind-field work above)
  - [ ] European monitoring data (the saqgetr package — same format as
        openair, opens the EU market)
  - [ ] Worldwide data (the OpenAQ platform — any city on earth)
  - [ ] US networks and PurpleAir community sensors (the Mazama R suite)
  - [ ] Raster underlays — modelled pollution surfaces displayed under
        the measured points (via the terra/stars packages)

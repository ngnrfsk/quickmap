# ARCHIVED CODE — not loaded, not tested, kept as a possible future feature.
#
# The "bar" indicator style: a bar above the legend's colour ramp running from
# zero to the network mean, capped at its end, with a matching colour chip
# beside the figure. Built 2026-07-30 as one of two refinements; the roundel
# was chosen 2026-07-31 and this was retired the same day.
#
# It is NOT retired for being wrong — it works, it is measured against the
# legend ramp exactly as the roundel is (ramp_position(), still live), and it
# renders correctly in interactive and static output. It lost on readability:
# the roundel carries its own figure at its own position, so there is no
# eye-travel between the number and the place it refers to.
#
# WHEN IT MIGHT BE WOKEN:
#  - if a future design wants magnitude read as length rather than position
#    (a bar answers "how much of the scale" at a glance; a roundel answers
#    "where on the scale")
#  - if markers on the ramp become crowded — e.g. once a maximum marker is
#    added alongside the mean — a bar plus one marker may read more clearly
#    than two markers side by side
#
# TO WAKE IT:
#  1. paste the branch below back into generate_indicator_bar() in
#     R/quickmap.R, before the roundel branch, switching on style == "bar"
#  2. restore the .legend-indicator-bar / .qm-bar-fill / .qm-ind-chip-bar
#     rules in inst/legend/legend-interactive.css and legend-image.css
#     (see the git history of this file's removal commit)
#  3. inst/controls/indicator.js already branches on the marker's class, so
#     the "else" arm that sets style.width is all a bar needs — check it is
#     still present
#  4. re-add "bar" to the documented values of the indicator.style theme key
#
# The tests that covered it are in the same removal commit.

# --- the branch removed from generate_indicator_bar() -----------------------
#
#   sprintf(
#     paste0(
#       '      <div class="legend-indicator-bar">\n',
#       '        <div class="qm-bar-fill" id="qmIndicatorBar" ',
#       'style="width: %s%%; background: %s;"></div>\n',
#       '      </div>\n'
#     ),
#     format(position, trim = TRUE), colour
#   )
#
# --- the CSS removed from legend-interactive.css ----------------------------
#
#   .legend-indicator-bar {
#     height: 0.7rem;
#     margin-bottom: 0.25rem;
#     background: #f2f2f2;
#     border-radius: 3px;
#     overflow: hidden;
#   }
#
#   .qm-bar-fill {
#     height: 100%;
#     border-radius: 3px;
#     border-right: 0.2rem solid rgba(0, 0, 0, 0.5);
#     box-sizing: border-box;
#     transition: width 0.3s ease, background-color 0.3s ease;
#   }
#
#   .qm-ind-chip-bar {
#     width: 0.9rem;
#     height: 0.55rem;
#     border-radius: 2px;
#   }
#
# legend-image.css carried the same rules at slightly larger sizes
# (height 0.75rem, chip 1rem x 0.6rem).
#
# --- demonstration output produced while it was live ------------------------
#
#   aq_maps/indicator_bar-print_v2_2019.jpg  (and _2025)
#   aq_maps/indicator_bar-animated_v2.html
#   built by scripts/indicator_refinements_v2.R and
#   scripts/indicator_animations_v2.R, both of which still name the style

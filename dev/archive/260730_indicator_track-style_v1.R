# ARCHIVED CODE — not loaded, not tested, kept so it can be woken later.
#
# The "track" indicator style: a standalone scale drawn beside the legend, with
# its own tick marks and a pointer at the network mean. Shipped in v0.9.9.9,
# retired 2026-07-30 in favour of the "ramp" style (a marker measured against
# the legend's own colour ramp).
#
# WHY IT WAS RETIRED, so the reason is not lost with the code:
# the legend ramp gives every band equal width whatever its span
# (.ramp-block { flex: 1 }), so it is not linear in concentration. This track
# IS linear. The two therefore put the same threshold in different places, a
# few centimetres apart on the same page. Evidence:
# aq_maps/indicator_uneven-track_v1_2025.jpg against
# aq_maps/indicator_uneven-ramp_v1_2025.jpg (gla_pm25, uneven bands).
# Comparison written up in dev/260730_indicator_ramp_variant.md.
#
# WHEN IT MIGHT BE WOKEN: a map with the legend switched off
# (theme legend.show: false, or styling_type = "none") has no ramp to measure
# against, so an indicator there needs a scale of its own. That is the case
# this code exists for.
#
# TO WAKE IT:
#  1. paste generate_indicator_track() back into R/quickmap.R, section 5
#     (Legend and banner)
#  2. restore the "track" branch in generate_indicator_html(): the style
#     argument still exists and still switches, so only the drawing function
#     and its call are missing
#  3. restore the .qm-ind-svg / .qm-ind-track / .qm-ind-tick / .qm-ind-ticklabel
#     rules in inst/legend/legend-interactive.css and legend-image.css
#     (see git history of this file's removal commit)
#  4. restore the "x" array in the indicator payload and the pointer branch in
#     inst/controls/indicator.js
#
# The tests that covered it are in the same removal commit.

#' Draw the aggregate indicator as a standalone SVG track (ARCHIVED)
#'
#' A track running from zero to the top of the colour scale, tick marks at the
#' scale's thresholds, and a pointer at the network mean for the displayed
#' step. rem/viewBox units only, so it scales with the static export.
#'
#' @param indicator Result of build_indicator_data()
#' @param scale_name Name of the colour scale supplying the thresholds
#' @param value The figure to point at
#' @return SVG string
#' @keywords internal
generate_indicator_track <- function(indicator, scale_name, value) {
  scale_data <- load_colour_scale(scale_name)
  thresholds <- scale_data$thresholds
  ticks <- thresholds[is.finite(thresholds) & thresholds > 0]

  vmax <- max(c(ticks, indicator$values), na.rm = TRUE)
  if (!is.finite(vmax) || vmax <= 0) return("")
  vmax <- vmax * 1.08 # headroom so a pointer at the maximum is not clipped

  # viewBox units, not pixels: the SVG scales with its rem-sized box
  w <- 200
  pad <- 4
  x_of <- function(v) pad + (v / vmax) * (w - 2 * pad)

  tick_marks <- vapply(ticks, function(t) {
    sprintf(
      paste0('<line x1="%.1f" y1="9" x2="%.1f" y2="20" class="qm-ind-tick"/>',
             '<text x="%.1f" y="29" class="qm-ind-ticklabel">%s</text>'),
      x_of(t), x_of(t), x_of(t), format(t, trim = TRUE)
    )
  }, "")

  pointer_colour <- convert_colors_to_hex(assign_colour(value, scale_name))

  sprintf(
    paste0(
      '<svg class="qm-ind-svg" viewBox="0 0 %d 32" ',
      'preserveAspectRatio="none" aria-hidden="true">',
      '<rect x="%.1f" y="12" width="%.1f" height="5" rx="2.5" ',
      'class="qm-ind-track"/>',
      '%s',
      '<g id="qmIndicatorPointer" transform="translate(%.1f 0)">',
      '<path d="M -4 4 L 4 4 L 0 11 Z" fill="%s" stroke="#333" ',
      'stroke-width="0.6"/>',
      '</g></svg>'
    ),
    w, pad, w - 2 * pad, paste(tick_marks, collapse = ""),
    x_of(value), pointer_colour
  )
}

# The matching JavaScript, removed from inst/controls/indicator.js:
#
#   var pointer = document.getElementById("qmIndicatorPointer");
#   if (pointer) {
#     pointer.setAttribute("transform", "translate(" + data.x[i] + " 0)");
#     var head = pointer.querySelector("path");
#     if (head) head.setAttribute("fill", data.colours[i]);
#   }

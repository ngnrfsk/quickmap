# PM10 charts for the LB Merton Air Quality Action Plan.
#
# The companion to the NO2 print maps. They share the page furniture rather
# than merely resembling it: the same banner CSS, the same legend, the same
# colour-scale YAML, all pulled from the installed package. Only the middle of
# the page differs — a plot where the map goes.
#
# Two charts, because Tables G and H answer different questions:
#
#   1. Annual mean PM10 (Table G). The plot background IS the colour ramp:
#      horizontal bands at the PM10 thresholds, in the scale's own colours, so
#      a point's height reads its band with no legend lookup. This is the
#      trope that carries over from the maps, where colour does the same job.
#   2. Days above the 24-hour mean of 50 µg/m³ (Table H). A count is not a
#      concentration, so it gets no ramp — plain ground and one rule at the
#      35-day objective.
#
# What the data actually is, and why the charts say so:
#   - ME2 runs 2019-2025 with 2023 missing ("Insufficient Data"). The gap is
#     left open rather than interpolated.
#   - MEB was installed for 2025 only, so it is one point, not a series.
#   - Bracketed figures in the workbook are annualised values (Table G) and
#     90.4th percentiles (Table H). The plotted value is the primary figure;
#     the footnote says so.
#   - 2025 is provisional and unratified in the source. Marked hollow.
#
# Deferred (2026-08-06, user): WHO's 2021 24-hour PM10 guideline is 45 ug/m3,
# not to be exceeded more than 3-4 days a year. That is a comparable benchmark
# for chart 2, but this table counts days above 50, so it cannot simply be
# ruled on: the count would have to be recomputed from the raw series against
# 45. Left off rather than imply an equivalence that does not hold.
#
# Run from the project root:  Rscript quickplot/merton_pm10-charts_v2.R
#
# Uses quickmap::: internals deliberately: this is a companion script, not a
# package feature. v1.0 scope is maps, and charts should not widen the API.

library(quickmap)
library(readxl)

SRC <- "/Users/iarla/Coding/Library/data/LBM_ASR_Tables_2019_2025.xlsx"
BRAND <- "#2a75d4"
YEARS <- as.character(2019:2025)
OUT <- "aq_maps"

stopifnot(file.exists(SRC))

# -- Reading the workbook ------------------------------------------------------
# Cells carry text as well as numbers: "23 (21.9)", "Insufficient Data",
# "Not Installed". Return the primary figure, the bracketed one, and a status.
parse_cell <- function(x) {
  x <- trimws(as.character(x))
  if (is.na(x) || x == "") return(list(value = NA, bracket = NA, status = "none"))
  if (grepl("Not Installed", x, ignore.case = TRUE))
    return(list(value = NA, bracket = NA, status = "not installed"))
  if (grepl("Insufficient", x, ignore.case = TRUE))
    return(list(value = NA, bracket = NA, status = "insufficient"))
  br <- suppressWarnings(as.numeric(
    sub(".*\\(([0-9.]+)\\).*", "\\1", regmatches(x, regexpr("\\([0-9.]+\\)", x))[1])
  ))
  main <- suppressWarnings(as.numeric(sub("\\s*\\(.*", "", x)))
  list(value = main, bracket = if (length(br)) br else NA, status = "ok")
}

read_table <- function(sheet) {
  d <- suppressMessages(read_excel(SRC, sheet = sheet))
  d <- d[!is.na(d[[1]]) & d[[1]] %in% c("ME2", "MEB"), ]
  out <- lapply(seq_len(nrow(d)), function(i) {
    cells <- lapply(YEARS, function(y) parse_cell(d[[y]][i]))
    data.frame(
      site = as.character(d[[1]][i]),
      year = YEARS,
      value = vapply(cells, function(c) as.numeric(c$value), 0),
      bracket = vapply(cells, function(c) as.numeric(c$bracket), 0),
      status = vapply(cells, function(c) c$status, ""),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

annual <- read_table("PM10 annual (automatic)")
days <- read_table("PM10 24h (auto)")

# -- SVG helpers ---------------------------------------------------------------
# Plain string building: the chart is small and explicit beats a dependency.
VB_W <- 1000; VB_H <- 460
PAD <- list(l = 78, r = 210, t = 26, b = 54)

sv <- function(...) paste0(..., collapse = "")
esc <- function(x) gsub("&", "&amp;", gsub("<", "&lt;", x))

# Points sit on the axis ends; bars sit in the middle of a year's slot. Using
# point positions for bars pushed the first bar left of the vertical axis.
x_of <- function(i, n) PAD$l + (i - 1) / max(1, n - 1) *
  (VB_W - PAD$l - PAD$r)
x_band <- function(i, n) PAD$l + (i - 0.5) / n * (VB_W - PAD$l - PAD$r)
y_of <- function(v, ymax) VB_H - PAD$b - (v / ymax) * (VB_H - PAD$t - PAD$b)

# Two sites, so they need naming somewhere. A small key in the plot's top
# corner, echoing the banner key the maps use for school levels.
site_key <- function(shape = c("line", "bar")) {
  shape <- match.arg(shape)
  mark <- function(x, cls) if (shape == "line") sprintf(
    '<line class="%s" x1="%s" y1="%s" x2="%s" y2="%s"/><circle class="dot %s" cx="%s" cy="%s" r="6"/>',
    paste0("line-", cls), x, PAD$t + 8, x + 34, PAD$t + 8,
    paste0("dot-", cls), x + 17, PAD$t + 8
  ) else sprintf('<rect class="bar-%s" x="%s" y="%s" width="26" height="14"/>',
                 cls, x, PAD$t + 1)
  sv(
    mark(VB_W - PAD$r - 250, "me2"),
    sprintf('<text class="key-label" x="%s" y="%s">ME2</text>',
            VB_W - PAD$r - 208, PAD$t + 13),
    mark(VB_W - PAD$r - 150, "meb"),
    sprintf('<text class="key-label" x="%s" y="%s">MEB</text>',
            VB_W - PAD$r - 108, PAD$t + 13)
  )
}

axes <- function(ymax, ystep, ylab, xfun = x_of) {
  ticks <- seq(0, ymax, by = ystep)
  sv(
    sprintf('<line class="axis" x1="%s" y1="%s" x2="%s" y2="%s"/>',
            PAD$l, VB_H - PAD$b, VB_W - PAD$r, VB_H - PAD$b),
    sv(vapply(ticks, function(t) sprintf(
      '<text class="tick" x="%s" y="%s" text-anchor="end">%s</text>',
      PAD$l - 10, round(y_of(t, ymax) + 5, 1), t), "")),
    sv(vapply(seq_along(YEARS), function(i) sprintf(
      '<text class="tick" x="%s" y="%s" text-anchor="middle">%s</text>',
      round(xfun(i, length(YEARS)), 1), VB_H - PAD$b + 26, YEARS[i]), "")),
    sprintf('<text class="axis-title" transform="rotate(-90 18 %s)" x="18" y="%s">%s</text>',
            round(VB_H / 2), round(VB_H / 2), esc(ylab))
  )
}

# -- Chart 1: annual mean, on the ramp ----------------------------------------
chart_annual <- function() {
  scale <- quickmap:::load_colour_scale("lbm_aqap_pm10")
  th <- scale$thresholds
  cols <- quickmap:::convert_colors_to_hex(scale$colours)
  ymax <- 45; ystep <- 5

  # the ramp as background bands, the chart's whole point
  bands <- sv(vapply(seq_len(length(th) - 1), function(i) {
    lo <- th[i]; hi <- min(th[i + 1], ymax)
    if (lo >= ymax) return("")
    sprintf('<rect class="band" x="%s" y="%s" width="%s" height="%s" fill="%s"/>',
            PAD$l, round(y_of(hi, ymax), 1), VB_W - PAD$l - PAD$r,
            round(y_of(lo, ymax) - y_of(hi, ymax), 1), cols[i])
  }, ""))

  # threshold rules, named in the margin
  named <- data.frame(
    v = c(15, 20, 40),
    lab = c("WHO guideline 15", "WHO interim 4  20", "UK objective 40"),
    stringsAsFactors = FALSE
  )
  rules <- sv(vapply(seq_len(nrow(named)), function(i) sprintf(
    '<line class="rule" x1="%s" y1="%s" x2="%s" y2="%s"/><text class="rule-label" x="%s" y="%s">%s</text>',
    PAD$l, round(y_of(named$v[i], ymax), 1), VB_W - PAD$r,
    round(y_of(named$v[i], ymax), 1), VB_W - PAD$r + 12,
    round(y_of(named$v[i], ymax) + 4, 1), esc(named$lab[i])), ""))

  # ME2 and MEB both report 2025 and their values are barely a unit apart, so
  # the labels are pushed to opposite sides rather than left to overlap.
  series <- function(site, cls, dy) {
    d <- annual[annual$site == site, ]
    pts <- which(!is.na(d$value))
    # runs of consecutive years only, so the 2023 hole stays a hole
    segs <- split(pts, cumsum(c(1, diff(pts) != 1)))
    line <- sv(vapply(segs, function(g) {
      if (length(g) < 2) return("")
      sprintf('<polyline class="line-%s" points="%s"/>', cls,
              paste(sprintf("%s,%s", round(x_of(g, length(YEARS)), 1),
                            round(y_of(d$value[g], ymax), 1)), collapse = " "))
    }, ""))
    dots <- sv(vapply(pts, function(i) sprintf(
      '<circle class="dot dot-%s %s" cx="%s" cy="%s" r="7"/><text class="val" x="%s" y="%s" text-anchor="middle">%s</text>',
      cls, if (d$year[i] == "2025") "provisional" else "",
      round(x_of(i, length(YEARS)), 1), round(y_of(d$value[i], ymax), 1),
      round(x_of(i, length(YEARS)), 1), round(y_of(d$value[i], ymax) + dy, 1),
      d$value[i]), ""))
    paste0(line, dots)
  }

  gaps <- sv(vapply(which(annual$site == "ME2" & annual$status == "insufficient"),
    function(i) {
      k <- match(annual$year[i], YEARS)
      sprintf('<text class="gap" x="%s" y="%s" text-anchor="middle">no valid data</text>',
              round(x_of(k, length(YEARS)), 1), round(y_of(24, ymax)))
    }, ""))

  paste0(
    sprintf('<svg viewBox="0 0 %s %s" class="chart">', VB_W, VB_H),
    bands, rules, axes(ymax, ystep, "Annual mean PM10 (µg/m³)"),
    series("ME2", "me2", -16), series("MEB", "meb", 26), gaps,
    site_key("line"),
    "</svg>"
  )
}

# -- Chart 2: 24-hour exceedance days -----------------------------------------
chart_days <- function() {
  ymax <- 40; ystep <- 5
  bw <- 36
  objective <- 35

  # There is no WHO band structure for a COUNT of exceedance days, so none is
  # invented. Colour encodes the one standard that does exist: how much of the
  # 35-day allowance the year used. Same five ramp colours as the maps, so the
  # page still reads as one document, but the quantity is stated in the key as
  # a share of the allowance and cannot be mistaken for a concentration band.
  ALLOWANCE <- data.frame(
    upto = c(0.10, 0.25, 0.50, 1.00, Inf),
    colour = c("blue", "green", "yellow", "orange", "#FF4500"),
    label = c("under 10%", "10-25%", "25-50%", "50-100%", "over the objective"),
    stringsAsFactors = FALSE
  )
  band_colour <- function(v) {
    hex <- quickmap:::convert_colors_to_hex(ALLOWANCE$colour)
    hex[which(v / objective <= ALLOWANCE$upto)[1]]
  }

  bars <- function(site, dx) {
    d <- days[days$site == site, ]
    sv(vapply(which(!is.na(d$value)), function(i) {
      x <- x_band(i, length(YEARS)) + dx - bw / 2
      y <- y_of(d$value[i], ymax)
      # A zero is a result, not an absence: give it a visible stub so it is
      # not confused with a year that was never monitored.
      h <- max(3, VB_H - PAD$b - y)
      y <- VB_H - PAD$b - h
      sprintf(paste0('<rect class="bar%s" x="%s" y="%s" width="%s" height="%s" fill="%s"/>',
                     '<text class="val" x="%s" y="%s" text-anchor="middle">%s</text>',
                     '<text class="site-under" x="%s" y="%s" text-anchor="middle">%s</text>'),
              if (d$year[i] == "2025") " provisional" else "",
              round(x, 1), round(y, 1), bw, round(h, 1), band_colour(d$value[i]),
              round(x + bw / 2, 1), round(y - 10, 1), d$value[i],
              round(x + bw / 2, 1), VB_H - PAD$b + 44, site)
    }, ""))
  }

  key <- sv(vapply(seq_len(nrow(ALLOWANCE)), function(i) {
    x <- PAD$l + 8 + (i - 1) * 138
    sprintf(paste0('<rect class="key-swatch" x="%s" y="%s" width="22" height="14" fill="%s"/>',
                   '<text class="key-label" x="%s" y="%s">%s</text>'),
            x, PAD$t + 1, quickmap:::convert_colors_to_hex(ALLOWANCE$colour)[i],
            x + 28, PAD$t + 13, ALLOWANCE$label[i])
  }, ""))

  gaps <- sv(vapply(which(days$site == "ME2" & days$status == "insufficient"),
    function(i) {
      k <- match(days$year[i], YEARS)
      sprintf('<text class="gap" x="%s" y="%s" text-anchor="middle">no valid data</text>',
              round(x_band(k, length(YEARS)), 1), round(y_of(12, ymax)))
    }, ""))

  paste0(
    sprintf('<svg viewBox="0 0 %s %s" class="chart">', VB_W, VB_H),
    sprintf('<line class="rule objective" x1="%s" y1="%s" x2="%s" y2="%s"/>',
            PAD$l, round(y_of(objective, ymax), 1), VB_W - PAD$r,
            round(y_of(objective, ymax), 1)),
    sprintf('<text class="rule-label" x="%s" y="%s">UK objective\n35 days</text>',
            VB_W - PAD$r + 12, round(y_of(objective, ymax) + 4, 1)),
    axes(ymax, ystep, "Days above 50 µg/m³ (24-hour mean)", x_band),
    bars("ME2", -20), bars("MEB", 20), gaps,
    key,
    sprintf('<text class="key-caption" x="%s" y="%s">share of the 35-day allowance used</text>',
            PAD$l + 8, PAD$t + 34),
    "</svg>"
  )
}

# -- The page ------------------------------------------------------------------
chart_css <- '
.chart-container { flex: 1; display: flex; align-items: center;
  justify-content: center; padding: 0.8rem 1.4rem; min-height: 0;
  background: #ffffff; }
.chart { width: 100%; height: 100%; }
.band { opacity: 0.30; }
.axis { stroke: #333; stroke-width: 1.5; }
.tick { font-size: 15px; fill: #444; }
.axis-title { font-size: 17px; fill: #222; font-weight: 600;
  text-anchor: middle; }
.rule { stroke: #222; stroke-width: 1.6; stroke-dasharray: 7 5; }
.rule.objective { stroke-dasharray: none; stroke-width: 2.4; }
.rule-label { font-size: 14px; fill: #222; font-weight: 600; }
.line-me2 { fill: none; stroke: #14213d; stroke-width: 3.4; }
.line-meb { fill: none; stroke: #7a5195; stroke-width: 3.4; }
.dot { stroke: #ffffff; stroke-width: 2.5; }
.dot-me2 { fill: #14213d; }
.dot-meb { fill: #7a5195; }
.dot.provisional { fill: #ffffff; stroke-width: 3; }
.dot-me2.provisional { stroke: #14213d; }
.dot-meb.provisional { stroke: #7a5195; }
.key-label { font-size: 15px; font-weight: 650; fill: #222; }
.key-caption { font-size: 13px; fill: #555; }
.key-swatch { stroke: rgba(0,0,0,0.25); stroke-width: 1; }
.site-under { font-size: 13px; fill: #666; font-weight: 600; }
.bar { stroke: rgba(0,0,0,0.3); stroke-width: 1; }
.bar-me2 { fill: #14213d; }
.bar-meb { fill: #7a5195; }
.bar.provisional { fill-opacity: 0.45; stroke: #14213d; stroke-width: 2; }
.val { font-size: 15px; fill: #111; font-weight: 650; }
.gap { font-size: 13px; fill: #777; font-style: italic; }
.site-tag { font-size: 16px; font-weight: 700; fill: #14213d; }
.chart-note { font-size: 0.72rem; color: #555; padding: 0 1.4rem 0.5rem; }
.credit { font-size: 0.55rem; color: #888; text-align: right;
  padding: 0.1rem 1.4rem 0.4rem; }
'

# -- Export size ---------------------------------------------------------------
# 4000 x 3000, matching the AQAP maps so the charts sit in the same pack.
#
# Reached by zoom rather than by widening the viewport. Zoom is a device pixel
# ratio: the same page, more pixels, so the layout tuned and approved at 2000px
# is exactly what comes out at 4000. The viewport is set to the export's own
# 4:3 — it was 10:7 before — so the chart is not letterboxed.
# Sits at the very foot of the figure, after the legend. Quiet enough not to
# compete with the note above it, present enough to travel with the image once
# it is lifted into a report.
CREDIT <-
  '<div class="credit">Created using parhillresearch.com/quickplot</div>'

EXPORT_W <- 4000
EXPORT_H <- 3000
VIEW_W <- 2000
VIEW_H <- VIEW_W * EXPORT_H / EXPORT_W
ZOOM <- EXPORT_W / VIEW_W

page <- function(title, svg, note, scale_name, file) {
  banner_css <- quickmap:::build_banner_css(BRAND, image_mode = TRUE,
                                            banner_style = "bar")
  legend_css <- quickmap:::build_legend_css(BRAND, image_mode = TRUE)
  legend <- if (is.null(scale_name)) "" else
    quickmap:::generate_legend_html(scale_name, collapsed_mobile = FALSE)

  html <- paste0(
    "<!DOCTYPE html>\n<html><head><meta charset='utf-8'>",
    banner_css, legend_css,
    "<style>html { font-size: 26px; }", chart_css, "</style></head><body>",
    sprintf('<div class="banner"><span class="banner-title">%s</span></div>',
            esc(title)),
    '<div class="chart-container">', svg, "</div>",
    sprintf('<div class="chart-note">%s</div>', note),
    legend,
    CREDIT,
    "</body></html>"
  )
  path <- file.path(OUT, file)
  writeLines(html, path)
  webshot2::webshot(paste0("file://", normalizePath(path)),
                    sub("[.]html$", ".jpg", path),
                    vwidth = VIEW_W, vheight = VIEW_H, delay = 1.5,
                    zoom = ZOOM)
  cat("wrote", path, sprintf("(%d x %d)\n", EXPORT_W, EXPORT_H))
}

dir.create(OUT, showWarnings = FALSE)

page(
  "Merton PM₁₀ annual mean concentrations (µg/m³)",
  chart_annual(),
  paste("ME2 and MEB, automatic monitoring.",
        "MEB was installed in 2025. ME2 2023 excluded for insufficient",
        "data capture. 2025 is provisional and unratified."),
  "lbm_aqap_pm10",
  "merton_pm10_annual_v2.html"
)

page(
  "Merton PM₁₀: days above the 24-hour mean of 50 µg/m³",
  chart_days(),
  paste("ME2 and MEB, automatic monitoring.",
        "The objective permits 35 such days a year.",
        "MEB was installed in 2025. ME2 2023 excluded for insufficient",
        "data capture. 2025 is provisional and unratified."),
  NULL,
  "merton_pm10_days_v2.html"
)

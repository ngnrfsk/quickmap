# ECS diffusion-tube trends table.
#
# A colour-coded table of NO2 by site and year, styled to sit beside the
# Merton AQAP maps and PM10 charts: the same banner, the same legend pills,
# the same colour ramp, all pulled from the installed package. Where a map
# colours a marker and a chart colours a band behind a point, this colours the
# cell itself — the same idea with the geometry taken away.
#
# Source: '/Users/iarla/Coding/260710 ecs/ECS.xlsx', sheet "Trends analysis
# 2025", columns A:O (ID, Location, Average, 2012-2023), U:V (2024, 2025).
# Column AD holds an eight-row key block, not per-site data; it is the source
# of the band wording in inst/config/scales/ecs_no2.yaml. Column AC (Max NO2)
# is ignored — it holds one value in thirty rows.
#
# Decisions taken with Iarla, 2026-08-06:
#   - 2024r and 2025r are ratified measured data, so the "r" is dropped and
#     they sit in the row with every other measured year, uncaveated
#   - sorted by overall average, lowest first
#   - missing cells are cross-hatched. 2012 is absent for 24 of 30 sites and
#     2013-2016 for 15-17, so the early columns are mostly empty; hatching
#     says "not monitored" where blank would read as a broken table
#   - the pills go underneath the table
#
# Run from the project root:  Rscript scripts/ecs_trends-table_v2.R
#
# Companion script, not a package feature — see the quickplot note in
# CLAUDE.md's post-1.0 roadmap.

library(quickmap)
library(readxl)

SRC <- "/Users/iarla/Coding/260710 ecs/ECS.xlsx"
SHEET <- "Trends analysis 2025"
BRAND <- "#2a75d4"
OUT <- "aq_maps"
# The same scale as the AQAP maps, deliberately: 29 of these 30 tube IDs are
# Merton tubes, so this is the same network the maps show and the pills must
# say the same words. An earlier draft built a separate ecs_no2 scale from the
# workbook's own key block; it was a near-duplicate of this one and was
# dropped once the IDs were checked.
SCALE <- "lbm_aqap_no2"

# The average is what the rows are sorted by, but it is not shown: it is a
# derived figure sitting in a table of measurements. The code that renders it
# stays, unused, because it belongs in quickplot when the table moves there.
SHOW_AVERAGE <- FALSE

stopifnot(file.exists(SRC))

# -- Read ---------------------------------------------------------------------
raw <- suppressMessages(
  read_excel(SRC, sheet = SHEET, col_names = FALSE, skip = 1)
)
hdr <- as.character(unlist(raw[1, ]))
raw <- raw[-1, ]
raw <- raw[!is.na(raw[[1]]), ]

YEAR_COLS <- c(4:15, 21, 22)                    # D:O then U:V
years <- sub("r$", "", hdr[YEAR_COLS])          # 2024r -> 2024, ratified data

tbl <- data.frame(
  location = trimws(as.character(raw[[2]])),
  average = as.numeric(raw[[3]]),
  stringsAsFactors = FALSE
)
values <- vapply(YEAR_COLS, function(i) suppressWarnings(as.numeric(raw[[i]])),
                 numeric(nrow(raw)))
colnames(values) <- years

ord <- order(tbl$average)                        # lowest first
tbl <- tbl[ord, ]
values <- values[ord, , drop = FALSE]

cat(nrow(tbl), "sites,", length(years), "years,",
    sum(is.na(values)), "missing cells\n")

# -- Cells ---------------------------------------------------------------------
scale <- quickmap:::load_colour_scale(SCALE)

cell <- function(v) {
  if (is.na(v)) return('<td class="miss"></td>')
  # assign_colour() returns R colour NAMES for the low bands, and R and CSS do
  # not agree on them: R's "green" is #00FF00, CSS's is #008000. Dropped
  # straight into a style attribute the cells came out dark and muddy while
  # the legend ramp, which converts to hex, came out bright. Convert here so
  # the table and the ramp are the same colours by construction.
  bg <- quickmap:::convert_colors_to_hex(
    quickmap:::assign_colour(v, scale = SCALE)
  )
  sprintf('<td style="background:%s;color:%s">%s</td>',
          bg, quickmap:::get_contrast_text_color(bg),
          format(round(v, 1), nsmall = 0, trim = TRUE))
}

rows <- vapply(seq_len(nrow(tbl)), function(i) {
  paste0(
    "<tr><th class='site'>", tbl$location[i], "</th>",
    if (SHOW_AVERAGE) cell(tbl$average[i]) else "",
    paste(vapply(values[i, ], cell, ""), collapse = ""),
    "</tr>"
  )
}, "")

head_row <- paste0(
  "<tr><th class='site'></th>",
  if (SHOW_AVERAGE) "<th class='avg'>Average</th>" else "",
  paste(sprintf("<th>%s</th>", years), collapse = ""),
  "</tr>"
)

table_html <- paste0(
  "<table class='trends'><thead>", head_row, "</thead><tbody>",
  paste(rows, collapse = ""), "</tbody></table>"
)

# -- Page ----------------------------------------------------------------------
# The hatch is an SVG pattern rather than a flat grey so that "not monitored"
# cannot be mistaken for a measured value near the bottom of the scale.
table_css <- "
.table-wrap { flex: 1; overflow: hidden; padding: 0.5rem 1rem 0.2rem;
  background: #ffffff; }
table.trends { border-collapse: collapse; width: 100%;
  font-variant-numeric: tabular-nums; }
table.trends th, table.trends td { border: 1px solid #ffffff;
  padding: 0.12rem 0.18rem; text-align: center; font-size: 0.52rem;
  line-height: 1.25; }
table.trends thead th { background: #f2f2f2; color: #111; font-weight: 700;
  border-bottom: 2px solid #999; }
table.trends th.site { text-align: left; background: #f8f8f8; color: #111;
  font-weight: 600; white-space: nowrap; padding-right: 0.4rem; }
table.trends th.avg { }
table.trends td { font-weight: 600; }
td.miss {
  background-image: repeating-linear-gradient(45deg,
    #d8d8d8 0, #d8d8d8 1.5px, #ffffff 1.5px, #ffffff 5px);
}
.table-note { font-size: 0.42rem; color: #555; padding: 0 1rem 0.35rem; }
"

banner_css <- quickmap:::build_banner_css(BRAND, image_mode = TRUE,
                                          banner_style = "bar")
legend_css <- quickmap:::build_legend_css(BRAND, image_mode = TRUE)
# Trim the ramp to the data: Merton's scale runs to 90-100 plus an
# "insufficient data" band, and this table tops out at 72.6, so a third of the
# key would name bands that appear nowhere in the table.
legend <- quickmap:::generate_legend_html(
  SCALE, collapsed_mobile = FALSE, data_max = max(values, na.rm = TRUE)
)

note <- paste(
  "Diffusion tube NO2, annual means (µg/m³), sorted by each site's overall",
  "average, lowest first. Cross-hatched cells were not monitored that year.",
  "All years shown are ratified measured data."
)

html <- paste0(
  "<!DOCTYPE html>\n<html><head><meta charset='utf-8'>",
  banner_css, legend_css,
  "<style>html { font-size: 30px; }", table_css, "</style></head><body>",
  sprintf('<div class="banner"><span class="banner-title">%s</span></div>',
          "NO₂ diffusion tube annual mean trends (µg/m³)"),
  '<div class="table-wrap">', table_html, "</div>",
  sprintf('<div class="table-note">%s</div>', note),
  legend,
  "</body></html>"
)

# -- Export --------------------------------------------------------------------
# 4000 x 3000, matching the AQAP maps so the table can sit in the same pack.
#
# Reached by zoom rather than by widening the viewport. The layout was tuned at
# 1800px — column widths, the 0.52rem cell text, the 30px root — and rendering
# at 4000 directly would reflow all of it. Zoom is a device pixel ratio: the
# same page, more pixels, so what was approved at 1800 is what comes out at
# 4000. The viewport is set to the export's own 4:3 so nothing is cropped or
# letterboxed.
EXPORT_W <- 4000
EXPORT_H <- 3000
VIEW_W <- 1800
VIEW_H <- VIEW_W * EXPORT_H / EXPORT_W
ZOOM <- EXPORT_W / VIEW_W

dir.create(OUT, showWarnings = FALSE)
path <- file.path(OUT, "ecs_trends-table_v2.html")
writeLines(html, path)
webshot2::webshot(paste0("file://", normalizePath(path)),
                  sub("[.]html$", ".jpg", path),
                  vwidth = VIEW_W, vheight = VIEW_H, delay = 1.5, zoom = ZOOM)
cat("wrote", path, sprintf("(%d x %d)\n", EXPORT_W, EXPORT_H))

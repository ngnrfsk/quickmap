# Feasibility prototype: the "ramp" indicator style (user proposal 2026-07-30).
# The legend's own colour ramp is the scale; the indicator is a bar above it
# running from zero to the network mean, filled with the mean's band colour.
#
# Produces the same views as the "track" style so the two can be compared.
# Run from the project root:  Rscript scripts/indicator_ramp-variant_v1.R

library(quickmap)

prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))
years <- as.character(2019:2025)

ramp_theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:",
  '  background: "#5F3E94"',
  "indicator:",
  '  style: "ramp"'
), ramp_theme)

# 1. Interactive, ramp style
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = years,
  colour_scale = "lbm_no2",
  theme_file = ramp_theme,
  title = "Ramp variant — Merton NO₂ annual mean",
  output_file = "indicator_ramp-annual_v1.html"
)

# 2. Print export, ramp style, at both sizes
quickmap(
  prepared,
  boroughs = "Merton",
  display_times = c("2019", "2025"),
  colour_scale = "lbm_no2",
  theme_file = ramp_theme,
  title = "Ramp variant — print export",
  export_image = c(4000, 3000),
  output_file = "indicator_ramp-print-4000_v1.html"
)

quickmap(
  prepared,
  boroughs = "Merton",
  display_times = "2025",
  colour_scale = "lbm_no2",
  theme_file = ramp_theme,
  title = "Ramp variant — small export",
  export_image = c(900, 700),
  output_file = "indicator_ramp-print-900_v1.html"
)

# 3. The uneven-band case. gla_pm25's bands are 5, 2.5, 2.5, 2.5, 2.5, 5, 5
#    units wide and all draw the same width, so this is where a bar measured
#    against the ramp and a bar measured linearly diverge. Rendered under both
#    styles on the same data for comparison.
for (style in c("ramp", "track")) {
  theme <- tempfile(fileext = ".yaml")
  writeLines(c("indicator:", paste0('  style: "', style, '"')), theme)
  quickmap(
    prepared,
    boroughs = "Merton",
    display_times = "2025",
    colour_scale = "gla_pm25", # deliberately mismatched scale: uneven bands
    theme_file = theme,
    title = paste("Uneven bands —", style, "style"),
    export_image = c(1600, 1200),
    output_file = paste0("indicator_uneven-", style, "_v1.html")
  )
}

# The print set for the LB Merton Air Quality Action Plan.
#
# Merton NO2, one image per year 2019-2025, 4000 x 3000 px, with the legend
# indicator (network mean and maximum) switched on.
#
# v5 (2026-08-05):
#   - labels sized to 7pt on the page. 18pt was asked for; it cannot be done
#     while every one of the 62 sites and 53 schools is labelled. At 18pt an
#     average label box is about 35 x 6.3mm, so 115 of them need ~25,000mm2
#     on a map measuring 190 x 142mm — 94% of its area. 12pt needs 41% and is
#     still unreadable; 8pt is visibly over-full. To actually reach 18pt,
#     either print the image much larger (across A3 the same pixels are 13pt
#     without changing anything) or label far fewer features.
#   - FIXES A LONG-STANDING BUG uncovered while doing it: labelOptions puts
#     textsize straight into a CSS font-size, and the code passed a bare
#     number, which is invalid CSS. Every value was silently dropped and the
#     labels fell back to the inherited root size. label_scale in v3 and v4
#     therefore did nothing at all — those sets rendered at about 6.2pt.
#   - a primary and a secondary school may now share a short name, because
#     the cross colour already tells them apart. Two schools of the SAME
#     level still keep their full names: there the colour cannot separate
#     them and the document would be merging two real schools
#
# v4: school types dropped from labels, banner key, 12pt, thicker crosses.
#
# v3: schools and value labels. v2: AQAP banner and colour scale. v1: original.
#
# Run from the project root:  Rscript scripts/merton_print-set_v4.R

library(quickmap)

STAMP <- "260805"

# -- Label size ---------------------------------------------------------------
# Worked from the page rather than guessed. The image fills most of an A4
# width; at 4000px across that is PRINT_WIDTH_MM of paper, so one millimetre
# is 4000/PRINT_WIDTH_MM pixels. A TARGET_PT label is TARGET_PT/72 inch tall.
# The renderer's base label is 12px, already multiplied by the export factor
# sqrt(4000*3000 / 1200^2); label_scale supplies what is still missing.
PRINT_WIDTH_MM <- 190      # A4 portrait, 210mm less ~10mm margins each side
          # 18pt was asked for and is not possible at this label count: see
          # the note below. 7 is the largest that leaves the map readable.
TARGET_PT <- 7

px_per_mm <- 4000 / PRINT_WIDTH_MM
target_px <- TARGET_PT / 72 * 25.4 * px_per_mm
export_factor <- sqrt(4000 * 3000 / 1200^2)
LABEL_SCALE <- round(target_px / (12 * export_factor), 3)

cat(sprintf("labels: %.0fpt on a %dmm-wide page = %.0fpx, label_scale %.3f\n",
            TARGET_PT, PRINT_WIDTH_MM, target_px, LABEL_SCALE))

# -- School names -------------------------------------------------------------
# The type is dropped from every label because the banner key now carries it.
# Denominational words (CofE, RC, Catholic) stay: they are part of a school's
# identity, not its type.
#
# Two schools may share a short name only when their crosses differ: the
# banner key makes blue primary and green secondary, so the colour separates
# them and "Harris Academy Merton" appearing twice is unambiguous on the page.
# Where a clash falls within one level the colour cannot do that work, so that
# group keeps its full names rather than merging two real schools.
shorten_school <- function(name, level) {
  short <- gsub("\\b(Primary|Secondary|Infant|Junior)\\b", "", name)
  short <- sub("\\s*\\b(High|Community)?\\s*(School|Academy|College)\\s*$", "",
               short)
  short <- trimws(gsub("\\s+", " ", short))
  short[short == ""] <- name[short == ""]

  for (dup in unique(short[duplicated(short)])) {
    grp <- which(short == dup)
    if (anyDuplicated(level[grp])) short[grp] <- name[grp]
  }
  short
}

schools_src <- file.path(Sys.getenv("DATA_PATH"), "schools_Merton.csv")
stopifnot(nzchar(Sys.getenv("DATA_PATH")), file.exists(schools_src))

schools <- read.csv(schools_src, check.names = FALSE)
full_names <- schools$School
schools$School <- shorten_school(full_names, schools$Level)

changed <- schools$School != full_names
cat(sum(changed), "school names shortened,", sum(!changed),
    "kept in full\n")
shared <- unique(schools$School[duplicated(schools$School)])
if (length(shared)) {
  cat("shared short names, separated by cross colour:",
      paste(shared, collapse = "; "), "\n")
}

schools_short <- "aq_maps/prepared/merton_schools_short.csv"
write.csv(schools, schools_short, row.names = FALSE)

# -- The map ------------------------------------------------------------------
prepared <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
stopifnot(file.exists(prepared))

theme <- tempfile(fileext = ".yaml")
writeLines(c(
  "banner:",
  '  style: "bar"',
  '  background: "#2a75d4"',
  "indicator:",
  "  show_max: true",
  "map:",
  paste("  label_scale:", LABEL_SCALE)
), theme)

quickmap(
  list(prepared, file.path(getwd(), schools_short)),
  boroughs = "Merton",
  display_times = as.character(2019:2025),
  colour_scale = "lbm_aqap_no2",
  theme_file = theme,
  title = "Merton NO₂ annual mean concentrations (µg/m³)",
  marker_labels = "values_on",
  export_image = c(4000, 3000),
  output_file = "merton_no2_aqap.html"
)

out <- file.path("aq_maps", paste0("print_aqap_", STAMP))
dir.create(out, showWarnings = FALSE)
jpgs <- list.files("aq_maps", pattern = "^merton_no2_aqap_20\\d\\d\\.jpg$",
                   full.names = TRUE)
file.rename(jpgs, file.path(out, basename(jpgs)))

sizes <- file.size(list.files(out, full.names = TRUE))
cat("wrote", length(jpgs), "images to", out,
    sprintf("(%.1f MB)\n", sum(sizes) / 1e6))

# The print set for the LB Merton Air Quality Action Plan.
#
# Merton NO2, one image per year 2019-2025, 4000 x 3000 px, with the legend
# indicator (network mean and maximum) switched on.
#
# v4 (2026-08-05):
#   - school labels drop the school type ("Abbotsbury Primary School" ->
#     "Abbotsbury"); the type now appears once, as a colour key in the banner,
#     instead of 53 times across the map
#   - labels sized to 12pt on the page rather than the 8.9pt of v3
#   - crosses drawn with a stroke that scales with the export
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
TARGET_PT <- 12

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
# Any two schools whose short names would collide keep their full names —
# "Harris Primary Academy Merton" and "Harris Academy Merton" are different
# schools, and this document must not merge them.
shorten_school <- function(x) {
  short <- x
  short <- gsub("\\b(Primary|Secondary|Infant|Junior)\\b", "", short)
  short <- sub("\\s*\\b(High|Community)?\\s*(School|Academy|College)\\s*$", "",
               short)
  short <- trimws(gsub("\\s+", " ", short))
  short[short == ""] <- x[short == ""]

  clash <- short %in% short[duplicated(short)]
  short[clash] <- x[clash]
  short
}

schools_src <- file.path(Sys.getenv("DATA_PATH"), "schools_Merton.csv")
stopifnot(nzchar(Sys.getenv("DATA_PATH")), file.exists(schools_src))

schools <- read.csv(schools_src, check.names = FALSE)
schools$School <- shorten_school(schools$School)

kept_full <- schools$School %in%
  read.csv(schools_src, check.names = FALSE)$School
cat(sum(!kept_full), "school names shortened,", sum(kept_full),
    "kept in full to stay unambiguous\n")

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

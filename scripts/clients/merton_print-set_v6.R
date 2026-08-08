# The print set for the LB Merton Air Quality Action Plan.
#
# Merton NO2, one image per year 2019-2025, 4000 x 3000 px, with the legend
# indicator (network mean and maximum) switched on.
#
# v6 (2026-08-08): three label variants, chosen with VARIANT below.
#
#   "nobg"     labels, no white plate behind them   <- in the AQAP pack
#   "nolabels" no marker labels at all              <- in the AQAP pack
#   "plate"    labels on the translucent plate      (what v5 produced)
#
#   The first two were rendered as samples on 6 August by throwaway scripts
#   and then chosen for the pack, which left the deliverable with no script
#   behind it. This is that script. Output filenames carry the variant, so
#   the three sets cannot overwrite each other.
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
# Run from the project root, one variant per run:
#   Rscript scripts/clients/merton_print-set_v6.R nobg
#   Rscript scripts/clients/merton_print-set_v6.R nolabels
#   Rscript scripts/clients/merton_print-set_v6.R plate
# With no argument it builds every variant in turn.

library(quickmap)

STAMP <- "260808"

VARIANTS <- list(
  nobg     = list(labels = "values_on", background = FALSE),
  nolabels = list(labels = FALSE,       background = TRUE),
  plate    = list(labels = "values_on", background = TRUE)
)

args <- commandArgs(trailingOnly = TRUE)
wanted <- if (length(args)) args else names(VARIANTS)
unknown <- setdiff(wanted, names(VARIANTS))
if (length(unknown)) {
  stop("unknown variant: ", paste(unknown, collapse = ", "),
       ". Use one of: ", paste(names(VARIANTS), collapse = ", "))
}

# -- Label size ---------------------------------------------------------------
# Nothing to set. Marker labels sit on MARKER_LABEL_REM, the same size as the
# smallest text in the legend, and the export scales the root font size, so
# they stay in proportion with the banner, legend and year label at any output
# size. Chasing a point size on the page was the wrong frame: it produced
# labels at half the smallest legend text at one end and text covering the map
# at the other. The theme's map.label_scale is there to depart from this
# deliberately; the print set has no reason to.

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

out <- file.path("aq_maps", paste0("print_aqap_", STAMP))
dir.create(out, showWarnings = FALSE)

build <- function(name) {
  v <- VARIANTS[[name]]

  theme <- tempfile(fileext = ".yaml")
  writeLines(c(
    "banner:",
    '  style: "bar"',
    '  background: "#2a75d4"',
    "indicator:",
    "  show_max: true",
    "map:",
    paste("  label_background:", tolower(as.character(v$background)))
  ), theme)

  # Render under a build- name, never the final one. quickmap writes into
  # aq_maps/ root, so rendering straight to merton_no2_<variant>_YYYY.jpg
  # overwrites any finished image of that name already sitting there — and
  # then the tidy-up sweeps it into the output folder as if it were new.
  # That destroyed two approved images on 8 August. The build- prefix cannot
  # collide with a delivered file, and the final name is applied on the move.
  build_stem <- paste0("build_", name)
  quickmap(
    list(prepared, file.path(getwd(), schools_short)),
    boroughs = "Merton",
    display_times = as.character(2019:2025),
    colour_scale = "lbm_aqap_no2",
    theme_file = theme,
    title = "Merton NO₂ annual mean concentrations (µg/m³)",
    marker_labels = v$labels,
    export_image = c(4000, 3000),
    output_file = paste0(build_stem, ".html")
  )

  jpgs <- list.files("aq_maps",
                     pattern = paste0("^", build_stem, "_20\\d\\d\\.jpg$"),
                     full.names = TRUE)
  final <- sub(paste0("^", build_stem), paste0("merton_no2_", name),
               basename(jpgs))
  file.rename(jpgs, file.path(out, final))
  unlink(file.path("aq_maps", paste0(build_stem, ".html")))
  cat(name, ":", length(jpgs), "images\n")
  length(jpgs)
}

n <- sum(vapply(wanted, build, numeric(1)))
sizes <- file.size(list.files(out, full.names = TRUE))
cat("wrote", n, "images to", out, sprintf("(%.1f MB)\n", sum(sizes) / 1e6))

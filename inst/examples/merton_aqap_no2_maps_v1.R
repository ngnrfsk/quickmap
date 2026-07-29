# Merton Air Quality Action Plan — NO2 diffusion tube network, 2019-2025
#
# Produces two deliverables from LBM_ASR_Table_8_NO2_2019_2025.csv:
#
#   1. aq_maps/merton_no2_annual_2019_2025.html
#      Animated map for the Merton website. Seven annual steps, play button,
#      site names on hover.
#
#   2. aq_maps/merton_no2_print_<year>.jpg  (seven files, 4000 x 3000 px)
#      Print maps for the Action Plan document. Concentrations printed beside
#      every site, since a reader of a printed page cannot hover.
#
# Run with:  Rscript inst/examples/merton_aqap_no2_maps_v1.R
# Requires DATA_PATH to point at the folder holding the source CSV.

library(quickmap)

# -- Source data -------------------------------------------------------------
# The survey table as issued: one row per site, one column per year, with
# "not open" where a site had not yet been installed.
source_csv <- file.path(
  Sys.getenv("DATA_PATH"),
  "LBM_ASR_Table_8_NO2_2019_2025.csv"
)
stopifnot(file.exists(source_csv))

# -- Prepare a working copy --------------------------------------------------
# Two changes are needed, and both are made to a copy so that the borough's
# own file is never touched:
#   - "not open" is read as a missing value, so those sites simply do not
#     appear in the years before they were installed
#   - the site names are in a column called "Site Name"; QuickMap looks for a
#     column called "Label", so the column is renamed
tubes <- read.csv(
  source_csv,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  na.strings = c("", " ", "NA", "NaN", "not open")
)
names(tubes)[1] <- "ID" # the file begins with a byte-order mark
names(tubes)[names(tubes) == "Site Name"] <- "Label"

if (!dir.exists("aq_maps/prepared")) {
  dir.create("aq_maps/prepared", recursive = TRUE)
}
prepared_csv <- file.path(getwd(), "aq_maps/prepared/merton_no2_2019_2025.csv")
write.csv(tubes, prepared_csv, row.names = FALSE)

years <- as.character(2019:2025)
merton_theme <- system.file("themes/merton.yaml", package = "quickmap")

# -- 1. Animated map for the website -----------------------------------------
# Autoplay is on so the trend is visible without the visitor working out that
# the map is interactive; 1200 ms a year is slow enough to read each step.
# Site names appear on hover, which keeps the map itself uncluttered.
quickmap(
  prepared_csv,
  boroughs = "Merton",
  display_times = years,
  colour_scale = "lbm_no2",
  theme_file = merton_theme,
  title = "Merton NO₂ annual mean, diffusion tube network 2019–2025",
  marker_labels = "labels",
  autoplay = TRUE,
  play_speed = 1200,
  output_file = "merton_no2_annual_2019_2025.html"
)

# -- 2. Print maps for the Action Plan ---------------------------------------
# One image per year at 4000 x 3000 px — about 340 dpi across a full A4
# landscape page, comfortably above the 300 dpi print standard.
#
# All seven years are requested in a single call on purpose: the legend is
# scaled to the highest value across the whole set, so the colours mean the
# same thing in every image and the maps can be compared year to year.
#
# The year is printed in the corner of each image, so the title carries no
# year of its own.
quickmap(
  prepared_csv,
  boroughs = "Merton",
  display_times = years,
  colour_scale = "lbm_no2",
  theme_file = merton_theme,
  title = "Merton NO₂ annual mean concentrations (µg/m³)",
  marker_labels = "values_on",
  export_image = c(4000, 3000),
  output_file = "merton_no2_print.html"
)

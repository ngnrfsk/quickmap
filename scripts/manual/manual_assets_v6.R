# Manual assets: generates the LIVE maps embedded as iframes in the manual
# pages, into vignettes/maps/, plus the one static JPG the manual shows.
# Run from the repo root: Rscript scripts/manual/manual_assets_v6.R
#
# v6 (2026-08-17, item 9): v5 wrote with a bare output_file and copied the
# result out of aq_maps/. Item 9.1 stopped quickmap() choosing a directory, so
# v5's maps landed in the working directory and every copy silently failed.
# The maps are now written straight to vignettes/maps with output_dir, each
# write is checked, and marker_labels is symbol_labels.
#
# The maps are committed (they are the manual's examples and pkgdown copies
# them into the built site), so regenerate them only when the rendering or the
# teaching data changes, and look at what changed before committing.
library(quickmap)

# Set QUICKMAP_MANUAL_MAPS to write somewhere else — how this script is
# checked without overwriting the committed maps.
MAPS <- Sys.getenv("QUICKMAP_MANUAL_MAPS", "vignettes/maps")
dir.create(MAPS, showWarnings = FALSE, recursive = TRUE)

# quickmap() returns the widget, not the path, so each map is confirmed by
# looking for the file it was told to write. A silent miss is what v5 did.
wrote <- function(f) {
  path <- file.path(MAPS, f)
  if (!file.exists(path)) stop("not written: ", path, call. = FALSE)
  cat(f, file.size(path), "bytes\n")
}

# Part 1 base: Wandsworth diffusion tubes ------------------------------------

# 2. one argument, no boundary
quickmap("tubes_wandsworth.csv",
         output_file = "getstarted-first.html", output_dir = MAPS)
wrote("getstarted-first.html")

# 3. + boundary (vignette on by default)
quickmap("tubes_wandsworth.csv",
         boroughs = "Wandsworth",
         output_file = "getstarted-boundary.html", output_dir = MAPS)
wrote("getstarted-boundary.html")

# 4. vignette off, for contrast
quickmap("tubes_wandsworth.csv",
         boroughs = "Wandsworth",
         vignette = FALSE,
         output_file = "getstarted-vignette-off.html", output_dir = MAPS)
wrote("getstarted-vignette-off.html")

# 6. static export (one year -> one JPG). An export writes a pair per step,
# named <file>_<step>, so it goes to a scratch directory and only the JPG the
# manual embeds is kept.
scratch <- file.path(tempdir(), "manual-export")
dir.create(scratch, showWarnings = FALSE)
quickmap("tubes_wandsworth.csv",
         boroughs = "Wandsworth",
         display_times = "2024",
         export_image = c(1200, 900),
         output_file = "getstarted-export.html", output_dir = scratch)
stopifnot(file.copy(file.path(scratch, "getstarted-export_2024.jpg"),
                    file.path(MAPS, "getstarted-export.jpg"),
                    overwrite = TRUE))
cat("getstarted-export.jpg",
    file.size(file.path(MAPS, "getstarted-export.jpg")), "bytes\n")

# 7. + title and file name
quickmap("tubes_wandsworth.csv",
         boroughs    = "Wandsworth",
         title       = "Wandsworth NO2, 2017-2024",
         output_file = "getstarted-titled.html", output_dir = MAPS)
wrote("getstarted-titled.html")

# 8. + hover labels
quickmap("tubes_wandsworth.csv",
         boroughs      = "Wandsworth",
         title         = "Wandsworth NO2, 2017-2024",
         symbol_labels = TRUE,
         output_file   = "getstarted-labels.html", output_dir = MAPS)
wrote("getstarted-labels.html")

# 9. several measurement networks; symbol glyphs in the banner title
suppressWarnings(quickmap(
  list(
    "tubes_merton.csv",
    "sensors_london.RData",
    "schools_merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: ● tubes ◆ sensors ✖ schools",
  output_file = "getstarted-networks.html", output_dir = MAPS
))
wrote("getstarted-networks.html")

# Part 2 base: the hourly episode ---------------------------------------------

# 10. animation
quickmap(
  from_rdata("episode_london.RData", "pm25", name = "Sensors"),
  boroughs     = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  title        = "PM2.5 Episode: Jan 15-20, 2024",
  output_file  = "getstarted-episode.html", output_dir = MAPS,
  autoplay     = TRUE,
  play_speed   = 500
)
wrote("getstarted-episode.html")

# 11. + wind overlay (needs worldmet + network; skipped cleanly offline)
if (requireNamespace("worldmet", quietly = TRUE)) {
  heathrow <- tryCatch(
    from_worldmet(station = "037720-99999", year = 2024),
    error = function(e) NULL
  )
  if (is.null(heathrow)) {
    cat("getstarted-wind.html SKIPPED (no NOAA fetch)\n")
  } else {
    heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]
    quickmap(
      from_rdata("episode_london.RData", "pm25",
                 name = "Sensors"),
      boroughs     = c("Wandsworth", "Richmond"),
      colour_scale = "stripes_pm25",
      title        = "PM2.5 Episode with wind: Jan 15-20, 2024",
      output_file  = "getstarted-wind.html", output_dir = MAPS,
      autoplay     = TRUE,
      play_speed   = 500,
      wind         = heathrow
    )
    wrote("getstarted-wind.html")
  }
}

# Labels chapter ---------------------------------------------------------------
quickmap("tubes_wandsworth.csv",
         boroughs = "Wandsworth", symbol_labels = TRUE,
         output_file = "labels-hover.html", output_dir = MAPS)
wrote("labels-hover.html")

quickmap("tubes_wandsworth.csv",
         boroughs = "Wandsworth", symbol_labels = "values_on",
         output_file = "labels-values-on.html", output_dir = MAPS)
wrote("labels-values-on.html")

quickmap(
  list("tubes_wandsworth_labelled.csv", "schools_wandsworth.csv"),
  boroughs = "Wandsworth", symbol_labels = "labels",
  output_file = "labels-names.html", output_dir = MAPS
)
wrote("labels-names.html")

# Boundaries chapter ------------------------------------------------------------
quickmap(
  from_rdata("sensors_london.RData", "no2",
             name = "Sensors"),
  boroughs = c("Merton", "Wandsworth"),
  output_file = "boundaries-two.html", output_dir = MAPS
)
wrote("boundaries-two.html")

quickmap(
  from_rdata("sensors_london.RData", "no2",
             name = "Sensors"),
  boroughs = c("Merton", "Wandsworth"),
  boundary_labels = TRUE,
  output_file = "boundaries-labelled.html", output_dir = MAPS
)
wrote("boundaries-labelled.html")

# Styling chapter ---------------------------------------------------------------
quickmap(
  from_rdata("sensors_london.RData", "pm25",
             name = "Sensors"),
  boroughs = "Merton",
  colour_scale = "gla_pm25",
  output_file = "styling-scale.html", output_dir = MAPS
)
wrote("styling-scale.html")

quickmap(
  "tubes_merton.csv",
  boroughs = "Merton",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  output_file = "styling-theme.html", output_dir = MAPS
)
wrote("styling-theme.html")

# Layers page: the three-layer example (symbol glyphs in the title) -----------
suppressWarnings(quickmap(
  list(
    "tubes_merton.csv",
    "sensors_london.RData",
    "schools_merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: ● tubes ◆ sensors ✖ schools",
  output_file = "layers-multilayer.html", output_dir = MAPS
))
wrote("layers-multilayer.html")

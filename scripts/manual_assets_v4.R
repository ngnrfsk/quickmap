# Manual assets: generates the LIVE maps embedded as iframes in the manual
# pages (into vignettes/maps/, gitignored — regenerate before
# pkgdown::build_site()) plus static assets.
# v2 (2026-07-11 restructure): adds the vignette-off, static-export and
# titled examples; symbol glyphs in multi-symbol banner titles.
# v3: adds the labels example (marker_labels = TRUE, hover values).
# v4 (phase 2/3): maps for the Labels, Boundaries and Styling chapters.
# Run from the repo root: Rscript scripts/manual_assets_v4.R
library(quickmap)

dir.create("vignettes/maps", showWarnings = FALSE)

emit <- function(f) {
  file.copy(file.path("aq_maps", f), file.path("vignettes/maps", f),
            overwrite = TRUE)
  cat(f, file.size(file.path("vignettes/maps", f)), "bytes\n")
}

# Part 1 base: Wandsworth diffusion tubes ------------------------------------

# 2. one argument, no boundary
quickmap("wandsworth_2017_2024_csv.csv",
         output_file = "getstarted-first.html")
emit("getstarted-first.html")

# 3. + boundary (vignette on by default)
quickmap("wandsworth_2017_2024_csv.csv",
         boroughs = "Wandsworth",
         output_file = "getstarted-boundary.html")
emit("getstarted-boundary.html")

# 4. vignette off, for contrast
quickmap("wandsworth_2017_2024_csv.csv",
         boroughs = "Wandsworth",
         vignette = FALSE,
         output_file = "getstarted-vignette-off.html")
emit("getstarted-vignette-off.html")

# 6. static export (one year -> one JPG)
quickmap("wandsworth_2017_2024_csv.csv",
         boroughs = "Wandsworth",
         display_times = "2024",
         export_image = c(1200, 900),
         output_file = "getstarted-export.html")
file.copy("aq_maps/getstarted-export_2024.jpg",
          "vignettes/maps/getstarted-export.jpg", overwrite = TRUE)
cat("getstarted-export.jpg",
    file.size("vignettes/maps/getstarted-export.jpg"), "bytes\n")

# 8. + title and file name
quickmap("wandsworth_2017_2024_csv.csv",
         boroughs    = "Wandsworth",
         title       = "Wandsworth NO2, 2017-2024",
         output_file = "getstarted-titled.html")
emit("getstarted-titled.html")

# 8. + hover labels
quickmap("wandsworth_2017_2024_csv.csv",
         boroughs      = "Wandsworth",
         title         = "Wandsworth NO2, 2017-2024",
         marker_labels = TRUE,
         output_file   = "getstarted-labels.html")
emit("getstarted-labels.html")

# 9. several measurement networks; symbol glyphs in the banner title
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: ● tubes ◆ sensors ✖ schools",
  output_file = "getstarted-networks.html"
))
emit("getstarted-networks.html")

# Part 2 base: the hourly episode ---------------------------------------------

# 10. animation
quickmap(
  from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25", name = "Sensors"),
  boroughs     = c("Wandsworth", "Richmond"),
  colour_scale = "stripes_pm25",
  title        = "PM2.5 Episode: Jan 15-20, 2024",
  output_file  = "getstarted-episode.html",
  autoplay     = TRUE,
  play_speed   = 500
)
emit("getstarted-episode.html")

# 11. + wind overlay (needs worldmet + network; skipped cleanly offline)
if (requireNamespace("worldmet", quietly = TRUE)) {
  heathrow <- tryCatch(
    from_worldmet(station = "037720-99999", year = 2024),
    error = function(e) NULL
  )
  if (!is.null(heathrow)) {
    heathrow <- heathrow[format(heathrow$date, "%Y-%m") == "2024-01", ]
    quickmap(
      from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25",
                 name = "Sensors"),
      boroughs     = c("Wandsworth", "Richmond"),
      colour_scale = "stripes_pm25",
      title        = "PM2.5 Episode with wind: Jan 15-20, 2024",
      output_file  = "getstarted-wind.html",
      autoplay     = TRUE,
      play_speed   = 500,
      wind         = heathrow
    )
    emit("getstarted-wind.html")
  }
}

# Labels chapter ---------------------------------------------------------------
quickmap("wandsworth_2017_2024_csv.csv",
         boroughs = "Wandsworth", marker_labels = TRUE,
         output_file = "labels-hover.html")
emit("labels-hover.html")

quickmap("wandsworth_2017_2024_csv.csv",
         boroughs = "Wandsworth", marker_labels = "values_on",
         output_file = "labels-values-on.html")
emit("labels-values-on.html")

quickmap(
  list("wandsworth_2017_2024_csv_full_labels.csv", "schools_wandsworth.csv"),
  boroughs = "Wandsworth", marker_labels = "labels",
  output_file = "labels-names.html"
)
emit("labels-names.html")

# Boundaries chapter ------------------------------------------------------------
quickmap(
  from_rdata("bl_imperial_annualised_2021_2025_with_missing.Rdata", "no2",
             name = "Sensors"),
  boroughs = c("Merton", "Wandsworth"),
  output_file = "boundaries-two.html"
)
emit("boundaries-two.html")

quickmap(
  from_rdata("bl_imperial_annualised_2021_2025_with_missing.Rdata", "no2",
             name = "Sensors"),
  boroughs = c("Merton", "Wandsworth"),
  boundary_labels = TRUE,
  output_file = "boundaries-labelled.html"
)
emit("boundaries-labelled.html")

# Styling chapter ---------------------------------------------------------------
quickmap(
  from_rdata("bl_imperial_annualised_2021_2025_with_missing.Rdata", "pm25",
             name = "Sensors"),
  boroughs = "Merton",
  colour_scale = "gla_pm25",
  output_file = "styling-scale.html"
)
emit("styling-scale.html")

quickmap(
  "merton_dt_2018_2024.csv",
  boroughs = "Merton",
  theme_file = system.file("themes", "merton.yaml", package = "quickmap"),
  output_file = "styling-theme.html"
)
emit("styling-theme.html")

# Layers page: the three-layer example (symbol glyphs in the title) -----------
suppressWarnings(quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  title = "Merton NO2: ● tubes ◆ sensors ✖ schools",
  output_file = "layers-multilayer.html"
))
emit("layers-multilayer.html")

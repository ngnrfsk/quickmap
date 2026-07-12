# Manual teaching data (template principle P7, activated 2026-07-12):
# short, self-explanatory copies of the demo fixtures, created in
# DATA_PATH so every manual example reads cleanly. (Shipping extracts
# inside the package for CRAN-runnable examples remains an item-9 task.)
# Run from the repo root: Rscript scripts/manual_data_v1.R
dp <- Sys.getenv("DATA_PATH")

mapping <- c(
  "wandsworth_2017_2024_csv.csv"                        = "tubes.csv",
  "wandsworth_2017_2024_csv_full_labels.csv"            = "tubes_labelled.csv",
  "merton_dt_2018_2024.csv"                             = "tubes_merton.csv",
  "schools_Merton.csv"                                  = "schools.csv",
  "bl_imperial_annualised_2021_2025_with_missing.Rdata" = "sensors.RData",
  "episodeJan15-20_2024_sf_all.Rdata"                   = "episode.RData",
  "wandsworth_proposed_sensors.csv"                     = "proposed_sites.csv"
)

for (long in names(mapping)) {
  ok <- file.copy(file.path(dp, long), file.path(dp, mapping[[long]]),
                  overwrite = TRUE)
  cat(mapping[[long]], if (ok) "created" else "FAILED", "\n")
}

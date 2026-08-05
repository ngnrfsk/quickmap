# Manual teaching data (template principle P7; v2 2026-07-12 added the
# borough to every name — user correction; v3 adds the CASE-COLLISION
# GUARD after v2 destroyed schools_Merton.csv: on macOS's
# case-insensitive filesystem, file.copy("schools_Merton.csv",
# "schools_merton.csv") opens the SAME file for writing and truncates it
# to zero bytes. Never copy when source and target differ only by case —
# the existing file already answers to both spellings here.
# (The fixture was restored 2026-07-13 from
# "241122 quickmap/Raw input files/your_schools_Merton copy.csv" and
# verified by the characterization suite's 53-school pin.)
# Run from the repo root: Rscript scripts/manual_data_v3.R
dp <- Sys.getenv("DATA_PATH")

mapping <- c(
  "wandsworth_2017_2024_csv.csv"                        = "tubes_wandsworth.csv",
  "wandsworth_2017_2024_csv_full_labels.csv"            = "tubes_wandsworth_labelled.csv",
  "merton_dt_2018_2024.csv"                             = "tubes_merton.csv",
  "schools_Merton.csv"                                  = "schools_merton.csv",
  "bl_imperial_annualised_2021_2025_with_missing.Rdata" = "sensors_london.RData",
  "episodeJan15-20_2024_sf_all.Rdata"                   = "episode_london.RData",
  "wandsworth_proposed_sensors.csv"                     = "proposed_sites_wandsworth.csv"
)

for (long in names(mapping)) {
  short <- mapping[[long]]
  if (tolower(long) == tolower(short)) {
    cat(short, " SKIPPED (case-insensitive filesystem: same file as ",
        long, ")\n", sep = "")
    next
  }
  ok <- file.copy(file.path(dp, long), file.path(dp, short),
                  overwrite = TRUE)
  cat(short, if (ok) "created" else "FAILED", "\n")
}

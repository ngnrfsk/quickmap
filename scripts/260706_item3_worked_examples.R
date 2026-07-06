# Worked examples for roadmap item 3: the qm_layer atomic unit.
# Run from the repo root: Rscript scripts/260706_item3_worked_examples.R
# Requires DATA_PATH (set in .claude/settings.json / your environment).
#
# qm_layer does not render maps — that is roadmap item 4. These examples show
# what each wrapper produces and how the inference contract behaves.
library(quickmap)

cat("---- 1. Diffusion-tube CSV (wide year columns -> long temporal layer)\n")
tubes <- from_csv("merton_dt_2018_2024.csv")
print(tubes, n = 3)

cat("\n---- 2. Schools CSV (School column -> static cross layer, School labels)\n")
schools <- from_csv("schools_Merton.csv")
print(schools, n = 3)

cat("\n---- 3. Sensor RData (duck-typed load; legacy names normalised)\n")
bl <- from_rdata("bl_imperial_annualised_2021_2025_with_missing.Rdata", "no2")
print(bl, n = 3)

cat("\n---- 4. Sub-annual episode RData (hourly resolution auto-detected)\n")
episode <- from_rdata("episodeJan15-20_2024_sf_all.Rdata", "pm25")
print(episode, n = 3)

cat("\n---- 5. Hand-built layer from any data.frame (expert path)\n")
d <- data.frame(
  code = c("A", "A", "B", "B"),
  date = c("2023-01", "2023-02", "2023-01", "2023-02"),
  pm25 = c(10, 12, 14, 9),
  lat = c(51.50, 51.50, 51.51, 51.51),
  lon = c(-0.12, -0.12, -0.13, -0.13)
)
print(qm_layer(d, name = "my_data"), n = 2)

cat("\n---- 6. Metadata accessor\n")
str(qm_meta(episode))

cat("\n---- 7. The contract fails loudly and helpfully\n")
try(qm_layer(data.frame(x = 1, lat = 51.5, lon = -0.1)))
try(qm_layer(data.frame(code = "A", date = "Q1-2023", v = 1,
                        lat = 51.5, lon = -0.1)))

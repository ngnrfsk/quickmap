# test_missing_data_filter.R
#
# Quick test to verify missing data filtering is working
#
# Author: Claude Code
# Date: 2025-10-15

library(dplyr)

# Load the enriched data to verify structure
cat("Loading enriched data file...\n")
load("~/Coding/R projects/Library/data/bl_imperial_annualised_2021_2025_with_missing.Rdata")

cat("\nData structure:\n")
cat("  Rows:", nrow(dataOAformat), "\n")
cat("  Columns:", ncol(dataOAformat), "\n")
cat("  Column names:", paste(names(dataOAformat), collapse = ", "), "\n")

# Check missing data columns exist
cat("\n--- Missing Data Columns Check ---\n")
if ("missing_no2" %in% names(dataOAformat)) {
  cat("✓ missing_no2 column exists\n")
} else {
  cat("✗ missing_no2 column NOT FOUND\n")
}

if ("missing_pm25" %in% names(dataOAformat)) {
  cat("✓ missing_pm25 column exists\n")
} else {
  cat("✗ missing_pm25 column NOT FOUND\n")
}

# Summary statistics
cat("\n--- Summary Statistics ---\n")
cat("\nNO2 missing data:\n")
print(summary(dataOAformat$missing_no2))

cat("\nPM2.5 missing data:\n")
print(summary(dataOAformat$missing_pm25))

# Count how many would be filtered
cat("\n--- Filtering Simulation (20% threshold) ---\n")
n_no2_filtered <- sum(dataOAformat$missing_no2 > 20, na.rm = TRUE)
n_pm25_filtered <- sum(dataOAformat$missing_pm25 > 20, na.rm = TRUE)

cat("NO2: Would filter out", n_no2_filtered, "site-years (",
    round(100 * n_no2_filtered / nrow(dataOAformat), 1), "% of total)\n")
cat("PM2.5: Would filter out", n_pm25_filtered, "site-years (",
    round(100 * n_pm25_filtered / nrow(dataOAformat), 1), "% of total)\n")

# Show examples
cat("\n--- Examples of Data That Will Be Filtered (NO2) ---\n")
examples_no2 <- dataOAformat %>%
  filter(missing_no2 > 20) %>%
  select(siteCode, yr, no2, missing_no2) %>%
  arrange(desc(missing_no2)) %>%
  head(3)
print(examples_no2)

cat("\n--- Examples of Data That Will Be Filtered (PM2.5) ---\n")
examples_pm25 <- dataOAformat %>%
  filter(missing_pm25 > 20) %>%
  select(siteCode, yr, pm25, missing_pm25) %>%
  arrange(desc(missing_pm25)) %>%
  head(3)
print(examples_pm25)

cat("\n✓ Test complete - enriched data file is ready for use in quickmap\n")

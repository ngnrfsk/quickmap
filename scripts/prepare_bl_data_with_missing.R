# prepare_bl_data_with_missing.R
#
# Purpose: Calculate missing data percentages for NO2 and PM2.5 from hourly data
#          and add missing_no2 and missing_pm25 columns to BL annual statistics
#
# Input files:
#   - bl_imperial_210122-250422.Rdata (hourly data in long format)
#   - bl_imperial_annualised_2021_2025_to_250422.Rdata (annual data)
#
# Output file:
#   - bl_imperial_annualised_2021_2025_with_missing.Rdata
#
# Author: Claude Code
# Date: 2025-10-15
# Version: 1.0

# Load required libraries
library(tidyr)
library(dplyr)
library(lubridate)

# Define paths
library_path <- "~/Coding/R projects/Library/data"
project_path_name <- "~/Coding/quickmap/241122-quickmap"

# Change to project directory
setwd(project_path_name)

cat("\n==== Breathe London Data Quality Preparation ====\n\n")

# 1. Load hourly data ----
cat("Step 1: Loading hourly data...\n")
load(file.path(library_path, "bl_imperial_210122-250422.Rdata"))
cat("  - Loaded hourly data file\n")
cat("  - Hourly data (dataOAformat) dimensions:", dim(dataOAformat)[1], "rows x", dim(dataOAformat)[2], "columns\n")
cat("  - Date range:", format(range(dataOAformat$date, na.rm = TRUE), "%Y-%m-%d"), "\n")

# Store hourly data separately
hourly_data <- dataOAformat

# 2. Load annual data ----
cat("\nStep 2: Loading annual data...\n")
load(file.path(library_path, "bl_imperial_annualised_2021_2025_to_250422.Rdata"))
cat("  - Loaded annual data file\n")
cat("  - dataOAformat dimensions:", dim(dataOAformat)[1], "rows x", dim(dataOAformat)[2], "columns\n")

# 3. Process PM2.5 missing data ----
cat("\nStep 3: Calculating PM2.5 missing data percentages...\n")

# Data is already in long format - extract year from date column
# Calculate percent MISSING by site and year for PM2.5
# NOTE: Missing % = (hours missing or not yet measured) / (hours in full year)
# This includes both NA values AND hours not yet in the dataset
percent_missing_pm25 <- hourly_data |>
  mutate(year = year(date)) |>
  group_by(siteCode, year) |>
  summarise(
    hours_present = n(),
    hours_na = sum(is.na(pm25)),
    .groups = "drop"
  ) |>
  mutate(
    hours_in_year = ifelse(year == 2020, 366 * 24, 365 * 24),  # Account for leap years
    hours_missing = hours_in_year - hours_present + hours_na,
    PercentMissing = (hours_missing / hours_in_year) * 100
  ) |>
  select(siteCode, year, PercentMissing) |>
  rename(missing_pm25 = PercentMissing)

cat("  - Calculated missing data for",
    length(unique(percent_missing_pm25$siteCode)),
    "sites\n")
cat("  - Years covered:",
    paste(sort(unique(percent_missing_pm25$year)), collapse = ", "),
    "\n")

# 4. Process NO2 missing data ----
cat("\nStep 4: Calculating NO2 missing data percentages...\n")

# Calculate percent MISSING by site and year for NO2
# NOTE: Missing % = (hours missing or not yet measured) / (hours in full year)
# This includes both NA values AND hours not yet in the dataset
percent_missing_no2 <- hourly_data |>
  mutate(year = year(date)) |>
  group_by(siteCode, year) |>
  summarise(
    hours_present = n(),
    hours_na = sum(is.na(no2)),
    .groups = "drop"
  ) |>
  mutate(
    hours_in_year = ifelse(year == 2020, 366 * 24, 365 * 24),  # Account for leap years
    hours_missing = hours_in_year - hours_present + hours_na,
    PercentMissing = (hours_missing / hours_in_year) * 100
  ) |>
  select(siteCode, year, PercentMissing) |>
  rename(missing_no2 = PercentMissing)

cat("  - Calculated missing data for",
    length(unique(percent_missing_no2$siteCode)),
    "sites\n")
cat("  - Years covered:",
    paste(sort(unique(percent_missing_no2$year)), collapse = ", "),
    "\n")

# 5. Merge with dataOAformat ----
cat("\nStep 5: Merging missing data with annual statistics...\n")

# Convert year to character for join (dataOAformat has yr as character)
percent_missing_pm25$year <- as.character(percent_missing_pm25$year)
percent_missing_no2$year <- as.character(percent_missing_no2$year)

# Left join to preserve all dataOAformat rows
# Match on BOTH siteCode AND year since dataOAformat is one row per site-year
dataOAformat_enriched <- dataOAformat |>
  left_join(
    percent_missing_pm25,
    by = c("siteCode" = "siteCode", "yr" = "year")
  ) |>
  left_join(
    percent_missing_no2,
    by = c("siteCode" = "siteCode", "yr" = "year")
  )

cat("  - Joined PM2.5 missing data\n")
cat("  - Joined NO2 missing data\n")
cat("  - Final dimensions:", dim(dataOAformat_enriched)[1], "rows x",
    dim(dataOAformat_enriched)[2], "columns\n")

# 6. Save enriched data ----
cat("\nStep 6: Saving enriched data...\n")
dataOAformat <- dataOAformat_enriched
save(
  dataOAformat,
  file = file.path(library_path, "bl_imperial_annualised_2021_2025_with_missing.Rdata")
)
cat("  - Saved to:", file.path(library_path, "bl_imperial_annualised_2021_2025_with_missing.Rdata"), "\n")

# 7. Print summary statistics ----
cat("\n==== Missing Data Summary ====\n\n")

cat("Total rows:", nrow(dataOAformat), "\n")

cat("\n--- PM2.5 Missing Data ---\n")
cat("  Rows with PM2.5 missing data info:",
    sum(!is.na(dataOAformat$missing_pm25)), "\n")
cat("  Rows with >20% missing PM2.5:",
    sum(dataOAformat$missing_pm25 > 20, na.rm = TRUE), "\n")
cat("  PM2.5 missing data statistics:\n")
print(summary(dataOAformat$missing_pm25))

cat("\n--- NO2 Missing Data ---\n")
cat("  Rows with NO2 missing data info:",
    sum(!is.na(dataOAformat$missing_no2)), "\n")
cat("  Rows with >20% missing NO2:",
    sum(dataOAformat$missing_no2 > 20, na.rm = TRUE), "\n")
cat("  NO2 missing data statistics:\n")
print(summary(dataOAformat$missing_no2))

# 8. Show examples of low-quality data ----
cat("\n==== Examples of Low-Quality Data (>20% missing) ====\n\n")

# PM2.5 examples
low_quality_pm25 <- dataOAformat |>
  filter(missing_pm25 > 20) |>
  select(siteCode, yr, pm25, missing_pm25) |>
  arrange(desc(missing_pm25)) |>
  head(5)

if (nrow(low_quality_pm25) > 0) {
  cat("--- Low-Quality PM2.5 Site-Years ---\n")
  print(low_quality_pm25, n = 5)
} else {
  cat("--- Low-Quality PM2.5 Site-Years ---\n")
  cat("  No PM2.5 site-years with >20% missing data\n")
}

# NO2 examples
low_quality_no2 <- dataOAformat |>
  filter(missing_no2 > 20) |>
  select(siteCode, yr, no2, missing_no2) |>
  arrange(desc(missing_no2)) |>
  head(5)

cat("\n")
if (nrow(low_quality_no2) > 0) {
  cat("--- Low-Quality NO2 Site-Years ---\n")
  print(low_quality_no2, n = 5)
} else {
  cat("--- Low-Quality NO2 Site-Years ---\n")
  cat("  No NO2 site-years with >20% missing data\n")
}

# 9. Cross-pollutant quality comparison ----
cat("\n==== Cross-Pollutant Quality Comparison ====\n\n")

# Sites with different quality for different pollutants
different_quality <- dataOAformat |>
  filter(
    (!is.na(missing_pm25) & !is.na(missing_no2)) &
    ((missing_pm25 > 20 & missing_no2 <= 20) | (missing_no2 > 20 & missing_pm25 <= 20))
  ) |>
  select(siteCode, yr, missing_no2, missing_pm25) |>
  arrange(siteCode, yr)

if (nrow(different_quality) > 0) {
  cat("Sites with different quality for NO2 vs PM2.5 (first 10):\n")
  cat("(One pollutant >20% missing, the other <=20%)\n\n")
  print(head(different_quality, 10))
} else {
  cat("No sites found with significantly different quality between pollutants\n")
}

cat("\n==== Data Preparation Complete ====\n")
cat("\nNext steps:\n")
cat("  1. Review the summary statistics above\n")
cat("  2. Proceed with Phase 2: Modify quickmap.R functions\n")
cat("  3. Use the enriched data file in your mapping workflow\n\n")

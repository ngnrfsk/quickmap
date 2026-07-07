# Data-prep/reporting script — contains no QuickMap API calls, so it was not
# migrated at roadmap item 8 (v0.9.8). Note: its hardcoded library_path and
# project_path_name predate the current layout and need editing before use.
#
# 2025 data summaries generation script Notes its clear that
# openair_breathe_london_1_0.R doesn't work properly. Doesn't even load its
# libraries FFS Found a solution to turning the disastrously structured
# siteDetails data table of lists of lists into a normal data table.

library(data.table)
library(tidyr)
library(dplyr)
library(officer)
library(lubridate)
# library(renv)

# data loading
library_path <- "~/Coding/R projects/Library/data"
project_path_name <- "~/Coding/quickmap/241122-quickmap"
setwd(project_path_name)

load(
  file.path(
    library_path,
    "bl_imperial_annualised_2021_2025_to_250422.Rdata"
  )
)

annualised_data_oa_format <- dataOAformat

load(
  file.path(
    library_path,
    "bl_complete_Merton_Richmond_Wandsworth_250114.Rdata"
  ),
  verbose = TRUE
)


# Process the siteDetails data
# Convert to data.table if not already
siteDetails_long <- rbindlist(
  lapply(siteDetails, as.data.table),
  fill = TRUE,
  idcol = "SiteCode"
)
# Remove the second column (inner SiteCode)
siteDetails_long <- siteDetails_long[, -2, with = FALSE] # remove the SiteCode.1 column that was created by rbindlist
setnames(siteDetails_long, "SiteCode", "siteCode")
# drop unneeded columns in siteDetails_long except siteCode, SiteName", LocalAuthorityID, ward, SiteClassification, HeadHeight,ToRoad, SiteLocationType, lat and long
siteDetails_long <- siteDetails_long[, .(
  siteCode,
  SiteName,
  LocalAuthorityID,
  ward,
  SiteClassification,
  HeadHeight,
  ToRoad,
  Longitude,
  Latitude,
  SiteLocationType
)]


# TO DO after everything else: get this working in openair_breathe_london_1_0.R using modern logic
# result <- classifySitesByBorough(
#   listOfSensors = listOfSensors,
#   library_path = library_path,
#   listOfBoroughs = "all"
# )

# Part 1 - the missing percentages table for PM25, with coordinates ####

# 1. Add year column
PM25Hourly <- PM25Hourly |> mutate(year = year(date))

# 2. Pivot to long format
PM25_long <- PM25Hourly |>
  pivot_longer(-c(date, year), names_to = "Site", values_to = "Value")

# 3. Calculate percent non-NA by site and year
percent_non_na <- PM25_long |>
  group_by(Site, year) |>
  summarise(PercentNonNA = mean(!is.na(Value)) * 100, .groups = "drop")


# following code can be ignored for merging with quickmap

# 4. Filter to site-years with >=80% completeness
filtered <- PM25_long |>
  inner_join(percent_non_na, by = c("Site", "year")) |>
  filter(PercentNonNA >= 80)

# 5. Calculate average value for filtered site-years
avg_by_site_year <- filtered |>
  group_by(Site, year) |>
  summarise(AverageValue = mean(Value, na.rm = TRUE), .groups = "drop")

# 6. Combine percent completeness and average value
result <- percent_non_na |>
  left_join(avg_by_site_year, by = c("Site", "year"))

# 7. Pivot wider for reporting
final_table <- result |>
  pivot_wider(
    id_cols = Site,
    names_from = year,
    values_from = c(PercentNonNA, AverageValue),
    names_sep = "_"
  )

# 8. add in the site details, such as borough

pm25_hourly_details <- final_table |>
  left_join(
    siteDetails_long |>
      select(siteCode, Longitude, Latitude, LocalAuthorityID),
    by = c("Site" = "siteCode")
  )

borough <- "Richmond upon Thames"

# filter pm25_hourly_details for LocalAuthorityID == borough put into table for_export
for_export <- pm25_hourly_details %>%
  filter(LocalAuthorityID == borough) %>%
  select(
    Site,
    Longitude,
    Latitude,
    PercentNonNA_2021,
    PercentNonNA_2022,
    PercentNonNA_2023,
    PercentNonNA_2024,
    AverageValue_2021,
    AverageValue_2022,
    AverageValue_2023,
    AverageValue_2024
  ) %>%
  mutate(across(
    c(
      Longitude,
      Latitude,
      PercentNonNA_2021,
      PercentNonNA_2022,
      PercentNonNA_2023,
      PercentNonNA_2024,
      AverageValue_2021,
      AverageValue_2022,
      AverageValue_2023,
      AverageValue_2024
    ),
    ~ ifelse(
      is.na(.) | . == 0,
      "",
      sub("\\.?0+$", "", format(signif(., 3), trim = TRUE, scientific = FALSE))
    )
  ))


# rename columns for clarity
for_export <- for_export |>
  rename_with(
    ~ gsub("^PercentNonNA_", "% data ", .),
    .cols = starts_with("PercentNonNA_")
  ) |>
  rename_with(
    ~ gsub("^AverageValue_", "Mean ", .),
    .cols = starts_with("AverageValue_")
  )

# Part 2 - annualised data ####
# Annualised data cleansing & reclassification

# join siteDetails_long with the dataOAformat with siteDetails_long:SiteCode and
# dataOAformat:siteCode keeping
annual_data_site_info <- merge(
  dataOAformat,
  siteDetails_long,
  by.x = "siteCode",
  by.y = "siteCode",
  all.x = TRUE
)


# data processing and reclassification ####
# Reclassify SiteClassification based on ToRoad distances
annual_data_site_info <- annual_data_site_info |>
  mutate(
    SiteClassification_reclass = case_when(
      ToRoad < 1.0 ~ "Kerbside",
      ToRoad >= 1.0 & ToRoad <= 5.0 ~ "Roadside",
      ToRoad > 10.0 ~ "Urban background",
      TRUE ~ "Other"
    )
  )

# summarise pm25 values in annual_data_site_info where LocalAuthoridyID ==
# borough, categorised by year and SiteClassification, excluding data with
# more than 20% missing values

# Identify qualifying site-years (≥80% non-NA), renaming
qualifying_site_years <- percent_non_na %>%
  filter(PercentNonNA >= 80.0) |>
  rename(siteCode = Site, yr = year)

# Filter for site-years with < 20% missing, and only for the borough
annual_data_site_info$yr <- as.integer(annual_data_site_info$yr)
filtered_data <- annual_data_site_info %>%
  inner_join(qualifying_site_years, by = c("yr", "siteCode")) %>%
  filter(LocalAuthorityID == borough)

# 4. Summarise by year and SiteClassification, sites with >= 80% data in year
summary_long <- filtered_data %>%
  group_by(yr, SiteClassification_reclass) %>%
  summarise(
    mean_pm25 = mean(pm25, na.rm = TRUE),
    sd_pm25 = sd(pm25, na.rm = TRUE),
    n = n_distinct(siteCode),
    .groups = "drop"
  )

# 5. Add "All" row for each year, using sites with >= 80% data in year
all_summary <- filtered_data %>%
  group_by(yr) %>%
  summarise(
    SiteClassification_reclass = "All",
    mean_pm25 = mean(pm25, na.rm = TRUE),
    sd_pm25 = sd(pm25, na.rm = TRUE),
    n = n_distinct(siteCode),
    .groups = "drop"
  )


# 6. Combine summaries
summary_long <- bind_rows(summary_long, all_summary)


# Pivot and add combined column
annual_pm25_summary_by_class <- summary_long |>
  pivot_wider(
    names_from = yr,
    values_from = c(mean_pm25, sd_pm25, n),
    names_sep = "_"
  ) |>
  arrange(SiteClassification_reclass)

for (yr in gsub(
  "mean_pm25_",
  "",
  grep("^mean_pm25_", names(annual_pm25_summary_by_class), value = TRUE)
)) {
  mean_vals <- round(
    annual_pm25_summary_by_class[[paste0("mean_pm25_", yr)]],
    2
  )
  sd_vals <- round(annual_pm25_summary_by_class[[paste0("sd_pm25_", yr)]], 2)
  annual_pm25_summary_by_class[[paste0("mean_sd_", yr)]] <-
    ifelse(
      is.na(mean_vals),
      "",
      ifelse(
        is.na(sd_vals),
        as.character(mean_vals),
        paste0(mean_vals, " ± ", sd_vals)
      )
    )
}


# Remove original mean and sd columns, rename n as count
annual_pm25_summary_by_class <- annual_pm25_summary_by_class |>
  select(-starts_with("mean_pm25_"), -starts_with("sd_pm25_")) |>
  rename_with(~ gsub("n_", "n ", .), .cols = starts_with("n_")) |>
  mutate(across(starts_with("n "), as.integer))

# Assemble the Word document
# initialise document object
doc <- read_docx()

doc <- doc |>
  body_add_par(paste0(
    borough,
    "Annual PM2.5, where > 80% Breathe London data, by site type "
  )) |>
  body_add_table(value = annual_pm25_summary_by_class)

doc <- doc |>
  body_add_par(paste0(
    borough,
    "Annual mean PM2.5, where > 80% Breathe London data"
  )) |>
  body_add_table(value = for_export)

# Finally, save the Word document ####

print(doc, target = paste0(borough, "_BL_pm25_analysis.docx"))
# End of the asr_summaries_generation script

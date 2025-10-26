# Bug 2: Missing Data Filter Integration - Implementation Plan

**Created**: 2025-10-15
**Priority**: CRITICAL
**Estimated Effort**: 2-3 hours
**Blocks**: Website launch

---

## OVERVIEW

Integrate data completeness filtering so that Breathe London sites with <80% data coverage in a given year display as white disk markers (no value shown) instead of colored pollution values. This prevents misleading data from being prominently displayed on maps.

---

## REQUIREMENTS SUMMARY

Based on clarifying questions:

1. **Data Source**: Load hourly data from separate RData files (e.g., `bl_complete_Merton_Richmond_Wandsworth_250114.Rdata`)
2. **Filtering Behavior**: Sites with >20% missing data show as white disks with no value
3. **User Control**: Parameter-based (`max_missing_data = 20`)
4. **Scope**: Breathe London RData files only (design extensible for CSV later)
5. **Icon Rendering**: White disks already defined in `colour_scales` (last color in each scale)
6. **Data Preparation**: One-time manual step to create enriched RData file with missing data percentages
7. **Column Naming**: Use `missing` as the column name (percent missing data 0-100)

---

## DATA STRUCTURE SPECIFICATIONS

### Input: Hourly Data File
**File**: `bl_complete_Merton_Richmond_Wandsworth_250114.Rdata`
**Object**: `PM25Hourly` (or `NO2Hourly` for NO2 data)
**Structure**:
```r
# Wide format data frame:
# 'data.frame': 35365 obs. of 152 variables:
# $ date    : POSIXct, format: "2021-01-01 00:00:00" "2021-01-01 01:00:00" ...
# $ CLDP0577: num  NA NA NA NA NA NA NA NA NA NA ...
# $ CLDP0001: num  12.3 13.1 11.8 ...
# ... (one column per site)
```

### Existing dataOAformat Structure (Long Format)
**File**: `bl_imperial_annualised_2021_2025_to_250422.Rdata`
**Object**: `dataOAformat`
**Structure**:
```r
# tibble [1,876 × 7] (S3: tbl_df/tbl/data.frame)
# $ siteCode: chr [1:1876] "CLDP0001" "CLDP0001" "CLDP0001" "CLDP0001" ...
# $ year    : Factor w/ 6 levels "2020","2021",..: 2 3 4 5 2 3 4 5 2 3 ...
# $ no2     : num [1:1876] 22.7 21.7 19.7 18.3 26.4 ...
# $ pm25    : num [1:1876] 10.24 9.31 8.53 8.22 10.26 ...
# $ lat     : num [1:1876] 51.5 51.5 51.5 51.5 51.6 ...
# $ lon     : num [1:1876] -0.0595 -0.0595 -0.0595 -0.0595 -0.0754 ...
# $ yr      : chr [1:1876] "2021" "2022" "2023" "2024" ...
```
**Key characteristic**: ONE ROW per site-year combination (long format)

### Output: Enriched Annual Data
**File**: `bl_imperial_annualised_2021_2025_with_missing.Rdata` (new)
**Object**: `dataOAformat` (enhanced)
**New Columns to Add**:
```r
# Add TWO missing data percentage columns (one per pollutant)
dataOAformat$missing_no2   # numeric, 0-100 (% missing NO2 for that site-year)
dataOAformat$missing_pm25  # numeric, 0-100 (% missing PM2.5 for that site-year)

# Example enhanced structure:
# tibble [1,876 × 9] (S3: tbl_df/tbl/data.frame)
# $ siteCode    : chr "CLDP0001" "CLDP0001" "CLDP0001" ...
# $ year        : Factor "2021" "2022" "2023" ...
# $ no2         : num 22.7 21.7 19.7 ...
# $ pm25        : num 10.24 9.31 8.53 ...
# $ lat         : num 51.5 51.5 51.5 ...
# $ lon         : num -0.0595 -0.0595 -0.0595 ...
# $ yr          : chr "2021" "2022" "2023" ...
# $ missing_no2 : num 4.8 12.7 27.9 ...  # NEW COLUMN (% missing NO2 data)
# $ missing_pm25: num 6.1 8.3 15.2 ...   # NEW COLUMN (% missing PM2.5 data)
#
# Examples:
# - missing_no2 = 4.8  means 95.2% completeness (GOOD - colored marker)
# - missing_pm25 = 27.9 means 72.1% completeness (BAD - white disk, >20% missing)
#
# NOTE: Columns named "missing_no2" and "missing_pm25" for CSV compatibility
# Each pollutant has its own data quality metric
```

---

## IMPLEMENTATION WORKFLOW

### Phase 1: Data Preparation Script (30-45 minutes)

Create a standalone R script to pre-process Breathe London data with completeness metrics.

**Script**: `prepare_bl_data_with_completeness.R`

**Input**:
- Hourly data RData file (e.g., `bl_complete_...Rdata` with `PM25Hourly`)
- Annual data RData file (e.g., `bl_imperial_annualised_...Rdata` with `dataOAformat`)

**Process**:
```r
# 1. Load hourly data
load("bl_complete_Merton_Richmond_Wandsworth_250114.Rdata")
# Contains: PM25Hourly, NO2Hourly

# 2. Load annual data
load("bl_imperial_annualised_2021_2025_to_250422.Rdata")
# Contains: dataOAformat (long format: one row per site-year)

# 3. Calculate missing data percentage by site-year (from missing_data_stats.R logic)
library(tidyr)
library(dplyr)
library(lubridate)

# ---- Process PM2.5 ----
# Add year column to hourly data
PM25Hourly <- PM25Hourly |> mutate(year = year(date))

# Pivot hourly data to long format
PM25_long <- PM25Hourly |>
  pivot_longer(-c(date, year), names_to = "Site", values_to = "Value")

# Calculate percent MISSING by site and year for PM2.5
percent_missing_pm25 <- PM25_long |>
  group_by(Site, year) |>
  summarise(PercentMissing = mean(is.na(Value)) * 100, .groups = "drop") |>
  rename(
    siteCode = Site,
    missing_pm25 = PercentMissing
  )

# ---- Process NO2 ----
# Add year column to NO2 hourly data
NO2Hourly <- NO2Hourly |> mutate(year = year(date))

# Pivot NO2 hourly data to long format
NO2_long <- NO2Hourly |>
  pivot_longer(-c(date, year), names_to = "Site", values_to = "Value")

# Calculate percent MISSING by site and year for NO2
percent_missing_no2 <- NO2_long |>
  group_by(Site, year) |>
  summarise(PercentMissing = mean(is.na(Value)) * 100, .groups = "drop") |>
  rename(
    siteCode = Site,
    missing_no2 = PercentMissing
  )

# 4. Merge with dataOAformat (all are now in long format)
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

# 5. Save enriched data
dataOAformat <- dataOAformat_enriched
save(
  dataOAformat,
  file = "bl_imperial_annualised_2021_2025_with_missing.Rdata"
)

# 6. Print summary for verification
cat("\nMissing Data Summary:\n")
cat("Total rows:", nrow(dataOAformat), "\n")
cat("\nPM2.5 Missing Data:\n")
cat("  Rows with PM2.5 missing data info:",
    sum(!is.na(dataOAformat$missing_pm25)), "\n")
cat("  Rows with >20% missing PM2.5:",
    sum(dataOAformat$missing_pm25 > 20, na.rm = TRUE), "\n")
print(summary(dataOAformat$missing_pm25))

cat("\nNO2 Missing Data:\n")
cat("  Rows with NO2 missing data info:",
    sum(!is.na(dataOAformat$missing_no2)), "\n")
cat("  Rows with >20% missing NO2:",
    sum(dataOAformat$missing_no2 > 20, na.rm = TRUE), "\n")
print(summary(dataOAformat$missing_no2))

# 7. Show example of low-quality data (>20% missing)
low_quality_pm25 <- dataOAformat |>
  filter(missing_pm25 > 20) |>
  select(siteCode, yr, pm25, missing_pm25) |>
  arrange(desc(missing_pm25)) |>
  head(5)

low_quality_no2 <- dataOAformat |>
  filter(missing_no2 > 20) |>
  select(siteCode, yr, no2, missing_no2) |>
  arrange(desc(missing_no2)) |>
  head(5)

cat("\nExample of low-quality PM2.5 site-years (>20% missing):\n")
print(low_quality_pm25)

cat("\nExample of low-quality NO2 site-years (>20% missing):\n")
print(low_quality_no2)
```

**Output**: New RData file with completeness columns added

---

### Phase 2: Modify quickmap.R Functions (1-1.5 hours)

#### 2A. Add Parameter to Main Function

**Location**: `create_pollution_map()` function (around line 1500)

**Change**:
```r
create_pollution_map <- function(
  csv_data_file = NULL,
  oa_data_file = NULL,
  boroughs = NULL,  # TODO: add default
  output_file = "pollution_map.html",
  image_export = FALSE,
  scale_to_use = "who_no2",
  show_schools = FALSE,
  school_data_file = NULL,
  show_banner = FALSE,
  banner_text = NULL,
  border_color = "#063F5C",
  map_width_px = 1200,
  map_height_px = 1200,
  max_missing_data = 20  # NEW PARAMETER (percent missing data threshold)
) {
  # ... function body
}
```

---

#### 2B. Modify Data Processing Logic

**Location**: `process_oa_data()` function (around line 340)

**Current Code**:
```r
process_oa_data <- function(data, pollutant) {
  # Validation and processing...
  return(data)
}
```

**New Code**:
```r
process_oa_data <- function(data, pollutant, max_missing = 20) {
  # Existing validation...

  # NEW: Check if pollutant-specific missing data column exists
  missing_col <- paste0("missing_", pollutant)  # e.g., "missing_no2" or "missing_pm25"
  has_missing <- missing_col %in% names(data)

  if (has_missing) {
    message(paste(
      "Missing data filtering enabled for", pollutant, ":",
      max_missing,
      "% threshold"
    ))

    # Add flag for low-quality data (simple comparison since data is long format)
    # Each row already has its own missing data % for that site-year-pollutant
    # If missing > threshold, mark as low quality
    data$low_quality <- ifelse(
      !is.na(data[[missing_col]]) & data[[missing_col]] > max_missing,
      TRUE,
      FALSE
    )

    n_low_quality <- sum(data$low_quality, na.rm = TRUE)
    message(paste(
      "Marked",
      n_low_quality,
      "site-years as low quality for", pollutant, "(>",
      max_missing,
      "% missing data)"
    ))
  } else {
    message(paste(
      "No", missing_col, "column found - skipping quality filtering"
    ))
    data$low_quality <- FALSE
  }

  return(data)
}
```

---

#### 2C. Modify Color Assignment Logic

**Location**: `assign_colour()` function (around line 670)

**Current Code**:
```r
assign_colour <- function(value, scale = "lbrut_no2") {
  if (is.na(value) || !is.numeric(value)) return("white")
  # ... rest of function
}
```

**New Code**:
```r
assign_colour <- function(
  value,
  scale = "lbrut_no2",
  low_quality = FALSE  # NEW PARAMETER
) {
  # NEW: Override color for low-quality data
  if (low_quality) {
    return("white")  # White disk for <80% completeness
  }

  if (is.na(value) || !is.numeric(value)) return("white")
  if (!scale %in% names(colour_scales)) stop("Invalid scale specified.")

  thresholds <- colour_scales[[scale]]$thresholds
  colours <- colour_scales[[scale]]$colours
  index <- findInterval(value, thresholds, left.open = FALSE)
  return(colours[index])
}
```

---

#### 2D. Update Layer Generation

**Location 1**: `create_generic_icons()` function (around line 1039-1086)

The icon creation function calls `assign_colour()` for bl_nodes. Update it to pass the low_quality flag:

```r
# CURRENT CODE (line ~1069-1072):
"bl_nodes" = {
  # Use assign_colour for continuous pollution data
  sapply(data[[pollutant]], assign_colour, scale = scale_to_use)
}

# NEW CODE:
"bl_nodes" = {
  # Use assign_colour with low_quality awareness
  mapply(
    assign_colour,
    value = data[[pollutant]],
    low_quality = if("low_quality" %in% names(data)) data$low_quality else FALSE,
    MoreArgs = list(scale = scale_to_use),
    SIMPLIFY = TRUE
  )
}
```

**Location 2**: `prepare_bl_layer_data()` function (around line 1216-1228)

Update the label generation to show data quality warnings:

```r
# CURRENT CODE:
prepare_bl_layer_data <- function(oa_subset, pollutant, scale_to_use) {
  if (nrow(oa_subset) == 0) return(NULL)
  labels <- paste(round(oa_subset[[pollutant]], 0), "ug/m3")
  list(
    data = oa_subset,
    labels = labels
  )
}

# NEW CODE:
prepare_bl_layer_data <- function(oa_subset, pollutant, scale_to_use) {
  if (nrow(oa_subset) == 0) return(NULL)

  # Generate labels based on data quality
  has_low_quality <- "low_quality" %in% names(oa_subset)

  if (has_low_quality) {
    labels <- ifelse(
      oa_subset$low_quality,
      "Insufficient data",  # White disk shows no value
      paste(round(oa_subset[[pollutant]], 0), "ug/m3")
    )
  } else {
    labels <- paste(round(oa_subset[[pollutant]], 0), "ug/m3")
  }

  list(
    data = oa_subset,
    labels = labels
  )
}
```

---

#### 2E. Thread Parameter Through Function Calls

**Locations**: Multiple function calls need to pass `max_missing_data`

1. **In `create_pollution_map()`** when calling `load_data_file()`:
```r
bl_annual_means_sf <- load_data_file(
  oa_data_file,
  "rdata",
  pollutant = pollutant,
  max_missing = max_missing_data  # NEW
)
```

2. **In `load_data_file()`** signature:
```r
load_data_file <- function(
  file_path,
  file_type,
  coord_cols = NULL,
  pollutant = NULL,
  max_missing = 20  # NEW (default 20% missing threshold)
) {
  # ...
  "rdata" = load_rdata_file(file_path, pollutant, max_missing)  # NEW
}
```

3. **In `load_rdata_file()`** signature:
```r
load_rdata_file <- function(file_path, pollutant, max_missing = 20) {
  # ...
  return(process_oa_data(dataOAformat, pollutant, max_missing))  # NEW
}
```

---

### Phase 3: Update Legend Documentation (15 minutes)

**Location**: Legend generation in `colour_scales` definitions

**Update the white disk label** to clarify it includes low-quality data (>20% missing):

```r
# Example for who_no2 scale (line ~494):
labels = c(
  "< 10: WHO guideline",
  "10-19: WHO Interim 3",
  # ... other labels ...
  "90-100: 9x WHO guideline",
  "Site not in use that year or >20% missing data"  # UPDATED
),
```

Repeat for all relevant scales:
- `stripes_no2` (line ~431)
- `who_no2` (line ~494)
- `lbrut_no2` (line ~525)
- `lbw_no2` (line ~555)
- `lbm_no2` (line ~585)
- `gla_pm25` (line ~611)
- `deltas` (line ~641)

---

### Phase 4: Testing (30 minutes)

#### Test Cases

**Test 1: Data with missing data column**
```r
source("quickmap.R")

map <- create_pollution_map(
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  boroughs = c("Wandsworth", "Merton"),
  output_file = "test_missing_filter.html",
  scale_to_use = "who_no2",
  max_missing_data = 20
)

# Expected: White disks for sites with >20% missing data
# Console should show: "Marked X site-years as low quality (>20% missing data)"
```

**Test 2: Data without missing column (backward compatibility)**
```r
map <- create_pollution_map(
  oa_data_file = "bl_imperial_annualised_2021_2025_to_250422.Rdata",
  boroughs = "Richmond upon Thames",
  output_file = "test_no_missing.html",
  scale_to_use = "lbrut_no2"
)

# Expected: Works normally, shows message about no 'missing' column
# All sites display with colored values as before
```

**Test 3: Different threshold values**
```r
map <- create_pollution_map(
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  boroughs = "Wandsworth",
  output_file = "test_30_percent_missing.html",
  max_missing_data = 30  # Higher threshold (more lenient)
)

# Expected: Fewer white disks (only >30% missing data shown as white)
```

**Test 4: Static image export**
```r
map <- create_pollution_map(
  oa_data_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  boroughs = c("Wandsworth", "Merton"),
  output_file = "test_static_missing.html",
  image_export = TRUE,
  scale_to_use = "gla_pm25",
  max_missing_data = 20
)

# Expected: JPG files show white disks for low-quality data (>20% missing)
```

#### Validation Checks

1. **Visual inspection**: Open HTML maps and verify white disks appear
2. **Popup verification**: Click white disk markers - should show "Insufficient data" message
3. **Console messages**: Verify informative messages about filtering
4. **Legend accuracy**: Check legend shows updated white disk description
5. **Backward compatibility**: Confirm old RData files work without errors

---

## FILES TO MODIFY

### New Files
1. **`prepare_bl_data_with_missing.R`** - Data preparation script (NEW)
2. **`tasks/bug_2_missing_data_filter_implementation_plan.md`** - This document (NEW)

### Modified Files
1. **`quickmap.R`** - Main code file
   - Line ~1500: Add `max_missing_data` parameter to `create_pollution_map()`
   - Line ~340: Modify `process_oa_data()` to add low-quality flagging (missing > threshold)
   - Line ~670: Modify `assign_colour()` to handle low-quality flag
   - Line ~1039-1086: Update `create_generic_icons()` to pass low-quality flag
   - Line ~1216-1228: Update `prepare_bl_layer_data()` for data quality labels
   - Line ~400-650: Update legend labels in `colour_scales` (">20% missing data")
   - Multiple locations: Thread `max_missing` parameter through function calls

---

## IMPLEMENTATION SEQUENCE

### Step 1: Data Preparation (Do First)
1. Create `prepare_bl_data_with_missing.R`
2. Run script to generate enriched RData file with `missing_no2` and `missing_pm25` columns
3. Verify both columns exist and have reasonable values (0-100 range)

### Step 2: Core Function Modifications
1. Add `max_missing_data` parameter to `create_pollution_map()`
2. Modify `assign_colour()` to accept and use `low_quality` flag
3. Update `process_oa_data()` to calculate pollutant-specific low-quality flags (missing_no2 or missing_pm25 > threshold)
4. Thread parameter through `load_data_file()` and `load_rdata_file()`

### Step 3: Layer Generation Updates
1. Modify `create_generic_icons()` to use low-quality aware color assignment
2. Update `prepare_bl_layer_data()` to show "Insufficient data" labels
3. Test with sample data

### Step 4: Legend and Documentation
1. Update all `colour_scales` legend labels for white disks (">20% missing data")
2. Add code comments explaining the filtering logic

### Step 5: Testing and Validation
1. Run all test cases for both NO2 and PM2.5 maps
2. Visual verification of maps (white disks for >20% missing for each pollutant)
3. Check backward compatibility (files without `missing_no2`/`missing_pm25` columns)

---

## EXPECTED OUTCOMES

### Functional
- ✅ Sites with >20% missing data show as white disks (pollutant-specific)
- ✅ White disk markers show "Insufficient data" label (no pollution value)
- ✅ Filtering threshold is configurable via `max_missing_data` parameter
- ✅ Backward compatible with old RData files (no `missing_no2`/`missing_pm25` columns)
- ✅ Logic: `if (missing_no2 > 20) then white disk` for NO2 maps
- ✅ Logic: `if (missing_pm25 > 20) then white disk` for PM2.5 maps
- ✅ Independent filtering: NO2 and PM2.5 have separate data quality thresholds

### User Experience
- ✅ Clear visual distinction between good (colored) and poor quality (white) data
- ✅ Legend explains white disk meaning (">20% missing data")
- ✅ Informative console messages about filtering
- ✅ No breaking changes to existing workflows

### Code Quality
- ✅ Clean parameter threading through functions
- ✅ Reusable data preparation script covering both pollutants
- ✅ Columns named "missing_no2" and "missing_pm25" for CSV extensibility
- ✅ Simple comparison logic (missing_pollutant > threshold)
- ✅ Pollutant-aware filtering (dynamically selects correct column)
- ✅ Well-documented implementation

---

## FUTURE ENHANCEMENTS (Out of Scope)

### For CSV Files (Deferred)
- Add support for `missing_no2` and `missing_pm25` columns in CSV format
- Column names: `missing_no2` and `missing_pm25` (percent missing data 0-100, same as RData)
- Extend filtering logic to diffusion tube data

### UI Improvements (Deferred)
- Interactive toggle to show/hide low-quality data
- Slider to adjust missing data threshold on the fly
- Summary statistics showing % of data filtered

### Advanced Features (Deferred)
- Color gradient for data quality (e.g., 15-20% = light gray, >20% = white)
- Separate layer for low-quality data
- Export data quality report alongside maps
- Show missing data percentage in tooltips/popups

---

## NOTES

- White disk color already exists in all `colour_scales` (last color in array)
- No new icon shapes needed - reuse existing diamond markers for BL nodes
- `missing_data_stats.R` provides reference implementation for missing data calculation (PM2.5 only)
- Hourly data file: `bl_complete_Merton_Richmond_Wandsworth_250114.Rdata` (contains both PM25Hourly and NO2Hourly)
- Column naming: `missing_no2` and `missing_pm25` (percent missing data 0-100) for CSV compatibility
- Pollutant-specific: Each pollutant has its own missing data metric
- Logic inversion: missing > 20 (not completeness < 80) for clearer semantics
- Design allows for easy extension to CSV files in future tasks

---

## RISK ASSESSMENT

**Risk Level**: Low-Medium

**Risks**:
1. **Data structure mismatch**: Hourly and annual data may have different site codes
   - *Mitigation*: Use left join to preserve all annual data rows
2. **Performance impact**: Additional column checks and filtering logic
   - *Mitigation*: Minimal - just conditional checks, no heavy computation
3. **Backward compatibility**: Existing scripts may break
   - *Mitigation*: Default parameter value + graceful handling of missing columns

**Dependencies**:
- Requires access to hourly data files for completeness calculation
- Users must run data preparation script before using new feature
- All testing depends on having sample data with known completeness issues

---

## SUCCESS CRITERIA

✅ **Complete** when:
1. Data preparation script successfully generates enriched RData files with `missing_no2` and `missing_pm25` columns
2. White disk markers appear for sites with >20% missing data (pollutant-specific)
3. All test cases pass without errors for both NO2 and PM2.5 maps
4. Backward compatibility confirmed with old RData files (no missing columns)
5. Legend labels updated to reflect new behavior (">20% missing data")
6. Console messages show correct filtering statistics for each pollutant
7. Verification that NO2 and PM2.5 filter independently (different sites may be low-quality for different pollutants)
8. Code committed to repository with clear commit message
9. Task log updated to mark Bug 2 and Bug 2a as COMPLETED

---

**End of Implementation Plan**

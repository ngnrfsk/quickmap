# OpenAir Integration Style Guide
## Functional-Level Code Integration for Extensions

**Version:** 1.0  
**Target:** Developers extending OpenAir functionality  
**Integration Level:** Functional (not source code modification)

---

## Table of Contents

1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Data Structure Requirements](#data-structure-requirements)
4. [Naming Conventions](#naming-conventions)
5. [Parameter Patterns](#parameter-patterns)
6. [Time Interval Selection](#time-interval-selection)
7. [Function Architecture](#function-architecture)
8. [Integration Routes](#integration-routes)
9. [Code Examples](#code-examples)
10. [Testing and Validation](#testing-and-validation)

---

## Overview

### Purpose

This guide enables developers to create code that integrates seamlessly with OpenAir at the **functional level**—using OpenAir functions as building blocks and working with OpenAir data structures without modifying the core package.

### Integration Philosophy

- **Use, don't modify:** Call OpenAir functions; don't alter their source
- **Extend, don't replace:** Add new capabilities alongside existing ones
- **Conform to conventions:** Match OpenAir's style for consistency
- **Maintain compatibility:** Ensure your code works with OpenAir outputs

---

## Core Principles

### 1. Data-Centric Design

All OpenAir functions operate on data frames with specific requirements:

```r
# MANDATORY: 'date' column (POSIXct or Date format)
# RECOMMENDED: Standard column names for meteorological data
mydata <- data.frame(
  date = seq(as.POSIXct("2020-01-01"), by = "hour", length.out = 8760),
  ws = numeric(8760),      # wind speed
  wd = numeric(8760),      # wind direction
  nox = numeric(8760),     # pollutant
  pm10 = numeric(8760)     # pollutant
)
```

### 2. Function Composition

Build workflows by chaining OpenAir functions:

```r
# Standard pattern
mydata %>%
  selectByDate(year = 2020:2023) %>%
  timeAverage(avg.time = "day") %>%
  yourCustomFunction() %>%
  timePlot(pollutant = "nox")
```

### 3. Consistent Return Types

Functions should return either:
- **Data frames/tibbles** for further processing
- **openair objects** (list with `plot`, `data`, `call` components)

---

## Data Structure Requirements

### Mandatory Columns

**Every data frame MUST include:**

```r
date  # POSIXct or Date class - REQUIRED
```

### Standard Column Names

**Use these names for consistency:**

| Variable | Name | Units | Notes |
|----------|------|-------|-------|
| Date/time | `date` | POSIXct/Date | Mandatory |
| Wind speed | `ws` | m/s | Numeric |
| Wind direction | `wd` | degrees | Numeric, 0-360 |
| Site identifier | `site` | character | Multiple sites |
| Site code | `code` | character | Official codes |

### Pollutant Naming

**Lowercase, simple names:**

```r
nox, no2, o3, pm10, pm25, pm2.5, so2, co
```

### Data Frame Validation

**Use OpenAir's validation:**

```r
# Your function should validate inputs
myCustomFunction <- function(mydata, pollutant, ...) {
  # Use OpenAir's checkPrep
  vars <- c("date", pollutant, "ws", "wd")
  mydata <- checkPrep(mydata, vars, type = "default", 
                      remove.calm = FALSE)
  
  # Your code here
  ...
}
```

---

## Naming Conventions

### Function Names

**Exported Functions:**
- **lowerCamelCase** for user-facing functions
- Descriptive, action-oriented names

```r
# Good examples
calculateEmissions <- function(mydata, ...) { }
plotTimeSeries <- function(mydata, ...) { }
analyzeCorrelation <- function(mydata, ...) { }

# Bad examples
calc_emissions <- function(mydata, ...) { }  # snake_case
CalcEmissions <- function(mydata, ...) { }   # PascalCase
ce <- function(mydata, ...) { }              # unclear
```

**Internal Functions:**
- **lowercase.with.dots** for helpers
- Prefix with package name to avoid conflicts

```r
# Internal utilities
mypackage.validate.data <- function(x) { }
mypackage.calculate.mean <- function(x) { }
```

### Parameter Names

**Use dot separation for multi-word parameters:**

```r
myFunction <- function(
  mydata,              # Primary data input
  avg.time = "day",    # Multi-word: dots
  data.thresh = 0,     # Multi-word: dots
  pollutant = "nox",   # Single word: no dots
  plot = TRUE          # Single word: no dots
)
```

**Standard Parameter Names (match OpenAir):**

| Parameter | Purpose | Default |
|-----------|---------|---------|
| `mydata` | Input data frame | Required |
| `pollutant` | Pollutant name(s) | Required |
| `type` | Conditioning variable | `"default"` |
| `avg.time` | Averaging period | `"day"` |
| `data.thresh` | Data capture threshold (%) | `0` |
| `statistic` | Statistical operation | `"mean"` |
| `plot` | Generate plot? | `TRUE` |
| `cols` | Color scheme | `"default"` |

### Variable Names

**Internal Variables:**

```r
# Use dots for compound names
start.date <- as.POSIXct("2020-01-01")
end.date <- as.POSIXct("2020-12-31")
all.dates <- seq(start.date, end.date, by = "day")

# Statistical results: Capitalized
Mean <- mean(mydata$nox, na.rm = TRUE)
Max <- max(mydata$nox, na.rm = TRUE)
Percentile <- quantile(mydata$nox, 0.95, na.rm = TRUE)
```

---

## Parameter Patterns

### Function Signature Template

```r
myFunction <- function(
  # 1. Data input (FIRST)
  mydata,
  
  # 2. Core parameters
  pollutant = "nox",
  type = "default",
  
  # 3. Time/aggregation parameters
  avg.time = "day",
  statistic = "mean",
  
  # 4. Threshold parameters
  data.thresh = 0,
  min.bin = 1,
  
  # 5. Plotting parameters
  cols = "default",
  key = TRUE,
  
  # 6. Control flags
  plot = TRUE,
  
  # 7. Pass-through for lattice/ggplot2
  ...
) {
  # Function body
}
```

### Parameter Ordering Rules

1. **Data first:** `mydata` always first parameter
2. **Required next:** Essential parameters (e.g., `pollutant`)
3. **Logical grouping:** Related parameters together
4. **Defaults last:** Parameters with sensible defaults
5. **Ellipsis last:** `...` always final

### Default Value Patterns

```r
# Strings: quoted
type = "default"
statistic = "mean"
cols = "jet"

# Numerics: unquoted
data.thresh = 0
k = 100
percentile = 95

# Booleans: unquoted
plot = TRUE
smooth = FALSE
normalise = FALSE

# NULL for optional features
windflow = NULL
ref.x = NULL
```

---

## Time Interval Selection

### The OpenAir Approach

**OpenAir uses preprocessing for time filtering, NOT parameters in plotting functions.**

### Primary Tool: `selectByDate()`

**Use this utility function to filter data BEFORE plotting:**

```r
selectByDate(
  mydata,
  start = "1/1/2008",      # British or ISO format
  end = "31/12/2008",      # British or ISO format
  year = 2008,             # Single year or range
  month = 1,               # Numeric or named
  day = "weekday",         # Day names or numbers
  hour = 1                 # Hour range (0-23)
)
```

### Date Format Support

**Two formats accepted:**

```r
# British format (day/month/year)
start = "1/2/1999"       # 1 February 1999
start = "01/02/1999"     # Same

# ISO format (year-month-day)
start = "1999-02-01"     # 1 February 1999
```

### Common Selection Patterns

**1. Year Ranges (2010-2025):**

```r
# Simple range
data <- selectByDate(mydata, year = 2010:2025)

# Specific years only
data <- selectByDate(mydata, year = c(2010, 2015, 2020, 2025))
```

**2. Specific Date Range (Feb 2023 to May 2025):**

```r
# British format
data <- selectByDate(mydata, 
                     start = "1/2/2023", 
                     end = "31/5/2025")

# ISO format (recommended for scripts)
data <- selectByDate(mydata, 
                     start = "2023-02-01", 
                     end = "2025-05-31")
```

**3. Month Range Across Years:**

```r
# February to May, any year
data <- selectByDate(mydata, month = 2:5)

# Winter months by name
data <- selectByDate(mydata, 
                     month = c("dec", "jan", "feb"))
```

**4. Complex Combinations:**

```r
# Weekdays only, specific hours, specific months
data <- selectByDate(mydata,
                     year = 2020:2023,
                     month = 6:9,
                     day = "weekday",
                     hour = 7:19)
```

### Integration Pattern

**Always filter BEFORE your function:**

```r
# Pattern 1: Pre-filter, then process
filtered_data <- selectByDate(mydata, year = 2010:2025)
result <- yourFunction(filtered_data, pollutant = "nox")

# Pattern 2: Inline filtering
result <- yourFunction(
  selectByDate(mydata, start = "2023-02-01", end = "2025-05-31"),
  pollutant = "nox"
)

# Pattern 3: Pipe workflow
mydata %>%
  selectByDate(year = 2020:2023, month = 2:5) %>%
  yourFunction(pollutant = "nox") %>%
  timePlot()
```

### Your Function Should NOT Include Date Filtering

**Don't do this:**

```r
# BAD - Don't add date filtering parameters
myFunction <- function(mydata, start.year, end.year, ...) {
  # Don't filter here
  mydata <- mydata[year(mydata$date) >= start.year & 
                   year(mydata$date) <= end.year, ]
  ...
}
```

**Do this instead:**

```r
# GOOD - Assume pre-filtered data
myFunction <- function(mydata, pollutant, ...) {
  # Expect data already filtered by selectByDate()
  # Focus on your analysis/visualization
  ...
}
```

### Important Notes

1. **Inclusive filtering:** Start date includes hour 00:00, end date includes 23:59
2. **Sequential application:** All filters applied in order (start, end, year, month, day, hour)
3. **`timeAverage()` note:** `start.date` and `end.date` in `timeAverage()` are for padding, NOT filtering
4. **Validation:** Always use `head()` and `tail()` to verify date filters worked correctly

---

## Function Architecture

### Standard Function Template

```r
myCustomFunction <- function(
  mydata,
  pollutant = "nox",
  type = "default",
  plot = TRUE,
  ...
) {
  
  # 1. VALIDATE INPUTS
  # Use OpenAir's validation
  vars <- c("date", pollutant)
  mydata <- checkPrep(mydata, vars, type, remove.calm = FALSE)
  
  # 2. PREPARE DATA
  # Use OpenAir utilities where possible
  mydata <- cutData(mydata, type = type)
  
  # 3. YOUR CORE LOGIC
  # Perform your analysis
  results <- your_analysis(mydata, pollutant)
  
  # 4. CREATE OUTPUT
  if (plot) {
    # Generate visualization
    plt <- create_plot(results, ...)
    print(plt)
  }
  
  # 5. RETURN STRUCTURE
  # Match OpenAir's return pattern
  output <- list(
    plot = if (plot) plt else NULL,
    data = results,
    call = match.call()
  )
  class(output) <- "openair"
  
  return(output)
}
```

### Key OpenAir Utilities to Use

**Data Validation:**
```r
checkPrep(mydata, vars, type, remove.calm = FALSE)
```

**Data Conditioning:**
```r
cutData(mydata, type = "default")  # Split by type
```

**Time Averaging:**
```r
timeAverage(mydata, avg.time = "day", statistic = "mean")
```

**Date Selection:**
```r
selectByDate(mydata, year = 2020, month = 1:6)
```

**Date Padding:**
```r
date.pad(mydata)  # Fill missing dates
```

---

## Integration Routes

### Route 1: Wrapper Functions

**Create functions that call OpenAir functions with your defaults:**

```r
myQuickPlot <- function(mydata, pollutant, period = "2020/2023") {
  # Parse period
  years <- as.numeric(strsplit(period, "/")[[1]])
  
  # Filter data
  data <- selectByDate(mydata, year = years[1]:years[2])
  
  # Call OpenAir function
  timePlot(data, 
           pollutant = pollutant,
           avg.time = "month",
           cols = "viridis")
}
```

### Route 2: Pre/Post Processing

**Add analysis before or after OpenAir functions:**

```r
analyzeAndPlot <- function(mydata, pollutant) {
  # Pre-process: Your custom analysis
  stats <- data.frame(
    mean = mean(mydata[[pollutant]], na.rm = TRUE),
    median = median(mydata[[pollutant]], na.rm = TRUE),
    p95 = quantile(mydata[[pollutant]], 0.95, na.rm = TRUE)
  )
  
  print(stats)
  
  # Use OpenAir for visualization
  plt <- timePlot(mydata, pollutant = pollutant, plot = FALSE)
  
  # Post-process: Add custom annotations
  # (modify plt object or create new visualization)
  
  return(list(statistics = stats, plot = plt$plot))
}
```

### Route 3: Data Transformation Pipeline

**Transform data, then pass to OpenAir:**

```r
myDataPipeline <- function(raw_data, ...) {
  # Your custom transformations
  processed <- raw_data %>%
    mutate(
      date = as.POSIXct(timestamp),
      nox = no + no2,
      ratio = no2 / nox
    ) %>%
    select(date, nox, no2, ratio, ws, wd)
  
  # Pass to OpenAir functions
  timeAverage(processed, avg.time = "day")
}

# Usage
clean_data <- myDataPipeline(raw_data)
polarPlot(clean_data, pollutant = "ratio")
```

### Route 4: Extract and Extend OpenAir Outputs

**Work with data from OpenAir objects:**

```r
enhancedAnalysis <- function(mydata, pollutant) {
  # Get OpenAir output
  polar_result <- polarPlot(mydata, 
                            pollutant = pollutant, 
                            plot = FALSE)
  
  # Extract data
  polar_data <- polar_result$data
  
  # Your custom analysis on polar data
  max_concentration <- polar_data %>%
    filter(z == max(z, na.rm = TRUE))
  
  # Create enhanced output
  list(
    original_plot = polar_result$plot,
    polar_data = polar_data,
    hotspot = max_concentration,
    summary = your_summary_function(polar_data)
  )
}
```

### Route 5: Parallel Functions (Same Interface)

**Create functions with OpenAir-compatible interfaces:**

```r
# Your function with OpenAir-style interface
myPolarAnalysis <- function(
  mydata,
  pollutant = "nox",
  type = "default",
  statistic = "mean",
  plot = TRUE,
  ...
) {
  # Validate using OpenAir utilities
  vars <- c("date", pollutant, "ws", "wd")
  mydata <- checkPrep(mydata, vars, type)
  mydata <- cutData(mydata, type = type)
  
  # Your custom polar analysis
  results <- your_polar_algorithm(mydata, pollutant, statistic)
  
  # Return OpenAir-style object
  output <- list(
    plot = if(plot) create_plot(results) else NULL,
    data = results,
    call = match.call()
  )
  class(output) <- "openair"
  
  return(output)
}

# Can now be used alongside OpenAir functions
polarPlot(mydata, pollutant = "nox")      # OpenAir
myPolarAnalysis(mydata, pollutant = "nox")  # Your function
```

### Route 6: Package Extension

**Create a separate package that depends on OpenAir:**

```r
# In your package DESCRIPTION
Imports:
    openair (>= 2.0),
    dplyr (>= 1.0),
    ...

# In your package NAMESPACE
import(openair)

# Your functions
#' @importFrom openair checkPrep cutData timeAverage
#' @export
myExtension <- function(mydata, ...) {
  # Use OpenAir functions
  mydata <- checkPrep(mydata, ...)
  ...
}
```

**Package structure:**
```
myOpenAirExtension/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── data_processing.R
│   ├── analysis.R
│   └── visualization.R
├── man/
└── tests/
```

---

## Code Examples

### Example 1: Simple Wrapper

```r
quickAirQualitySummary <- function(mydata, site_name) {
  # Filter to recent year
  recent <- selectByDate(mydata, year = year(Sys.Date()) - 1)
  
  # Generate multiple OpenAir plots
  summary <- summaryPlot(recent)
  time <- timePlot(recent, pollutant = "nox")
  polar <- polarPlot(recent, pollutant = "nox")
  
  # Return organized output
  list(
    site = site_name,
    summary = summary,
    timeseries = time,
    polar = polar
  )
}
```

### Example 2: Custom Analysis with OpenAir Integration

```r
exceedanceAnalysis <- function(
  mydata, 
  pollutant = "pm10",
  threshold = 50,
  reporting.year = 2023
) {
  # Filter to reporting year
  data <- selectByDate(mydata, year = reporting.year)
  
  # Calculate daily means using OpenAir
  daily <- timeAverage(data, 
                       avg.time = "day",
                       statistic = "mean",
                       data.thresh = 75)
  
  # Your custom exceedance analysis
  exceedances <- daily %>%
    filter(.data[[pollutant]] > threshold) %>%
    mutate(
      month = month(date, label = TRUE),
      weekday = wday(date, label = TRUE)
    )
  
  # Summary statistics
  stats <- list(
    n_exceedances = nrow(exceedances),
    max_value = max(exceedances[[pollutant]], na.rm = TRUE),
    dates = exceedances$date
  )
  
  # Visualize using OpenAir
  cal_plot <- calendarPlot(
    data,
    pollutant = pollutant,
    year = reporting.year,
    breaks = c(0, threshold/2, threshold, threshold*2, 1000),
    labels = c("Low", "Moderate", "High", "Very High"),
    cols = c("green", "yellow", "orange", "red")
  )
  
  # Return comprehensive output
  list(
    statistics = stats,
    exceedance_dates = exceedances,
    calendar_plot = cal_plot,
    data = daily
  )
}
```

### Example 3: Multi-Site Comparison

```r
compareSites <- function(mydata, pollutant = "nox", sites = NULL) {
  # Validate site column exists
  if (!"site" %in% names(mydata)) {
    stop("Data must contain 'site' column for multi-site comparison")
  }
  
  # Filter to specified sites if provided
  if (!is.null(sites)) {
    mydata <- mydata %>% filter(site %in% sites)
  }
  
  # Use OpenAir's type option for site conditioning
  time_comparison <- timePlot(mydata,
                              pollutant = pollutant,
                              type = "site",
                              avg.time = "month")
  
  # Calculate site statistics
  site_stats <- mydata %>%
    group_by(site) %>%
    summarise(
      mean = mean(.data[[pollutant]], na.rm = TRUE),
      median = median(.data[[pollutant]], na.rm = TRUE),
      p95 = quantile(.data[[pollutant]], 0.95, na.rm = TRUE),
      n = sum(!is.na(.data[[pollutant]]))
    )
  
  # Polar plots by site
  polar_comparison <- polarPlot(mydata,
                                pollutant = pollutant,
                                type = "site")
  
  list(
    timeseries = time_comparison,
    statistics = site_stats,
    polar = polar_comparison
  )
}
```

### Example 4: Export Data in OpenAir Format

```r
prepareForOpenAir <- function(raw_data, source_format = "custom") {
  # Convert your data format to OpenAir format
  openair_data <- raw_data %>%
    mutate(
      # REQUIRED: date column as POSIXct
      date = as.POSIXct(timestamp, tz = "UTC"),
      
      # Standard meteorological names
      ws = wind_speed_mps,
      wd = wind_direction_deg,
      
      # Pollutants: lowercase
      nox = NOx_ppb,
      no2 = NO2_ppb,
      o3 = O3_ppb,
      pm10 = PM10_ugm3,
      pm25 = PM25_ugm3
    ) %>%
    select(date, ws, wd, nox, no2, o3, pm10, pm25) %>%
    arrange(date)
  
  # Validate
  if (!inherits(openair_data$date, "POSIXct")) {
    stop("Date conversion failed")
  }
  
  return(openair_data)
}

# Usage
my_data <- read.csv("raw_data.csv")
openair_format <- prepareForOpenAir(my_data)

# Now compatible with all OpenAir functions
timePlot(openair_format, pollutant = "nox")
polarPlot(openair_format, pollutant = "pm10")
```

---

## Testing and Validation

### Unit Testing

**Test with OpenAir's example data:**

```r
library(testthat)

test_that("myFunction works with OpenAir data", {
  # Use OpenAir's built-in data
  data(mydata, package = "openair")
  
  # Test your function
  result <- myFunction(mydata, pollutant = "nox")
  
  # Validate output structure
  expect_true("data" %in% names(result))
  expect_s3_class(result, "openair")
})
```

### Compatibility Testing

**Verify data flow:**

```r
# Test pipeline compatibility
test_data <- mydata %>%
  selectByDate(year = 1998) %>%
  yourFunction() %>%
  timeAverage(avg.time = "month")

# Should work without errors
expect_true(nrow(test_data) > 0)
expect_true("date" %in% names(test_data))
```

### Validation Checklist

- [ ] Function accepts data frames with `date` column
- [ ] Function respects standard column names (`ws`, `wd`, etc.)
- [ ] Function returns appropriate structure (data frame or openair object)
- [ ] Function works with `selectByDate()` preprocessing
- [ ] Function works with `timeAverage()` preprocessing
- [ ] Function handles missing data appropriately
- [ ] Function documentation follows OpenAir style
- [ ] Examples use OpenAir's `mydata` or similar

---

## Documentation Standards

### Function Documentation Template

```r
#' Custom Analysis Function
#'
#' Extended description of what your function does and how it relates
#' to OpenAir functionality.
#'
#' @param mydata A data frame containing a \code{date} field and at least
#'   one numeric variable. Compatible with OpenAir data structures.
#' @param pollutant Name of the pollutant to analyze. Must correspond to a
#'   column in \code{mydata}.
#' @param type Conditioning variable for splitting data. See \code{\link[openair]{cutData}}
#'   for available options. Default is \code{"default"}.
#' @param plot Should a plot be produced? Default is \code{TRUE}.
#' @param ... Additional arguments passed to plotting functions.
#'
#' @return An object of class \code{"openair"} containing:
#'   \item{plot}{A plot object if \code{plot = TRUE}}
#'   \item{data}{A data frame with analysis results}
#'   \item{call}{The function call}
#'
#' @export
#' @seealso \code{\link[openair]{timePlot}}, \code{\link[openair]{polarPlot}}
#' @examples
#' # Using OpenAir's example data
#' data(mydata, package = "openair")
#' 
#' # Basic usage
#' result <- myFunction(mydata, pollutant = "nox")
#' 
#' # With date filtering
#' filtered <- selectByDate(mydata, year = 1998)
#' result <- myFunction(filtered, pollutant = "nox")
#' 
#' # With conditioning
#' result <- myFunction(mydata, pollutant = "nox", type = "season")
```

---

## Best Practices Summary

### DO:
✅ Use `selectByDate()` for time filtering  
✅ Match OpenAir naming conventions (lowerCamelCase, dots for parameters)  
✅ Validate data using `checkPrep()`  
✅ Return data frames or openair objects  
✅ Document compatibility with OpenAir  
✅ Test with OpenAir's example data  
✅ Use OpenAir utilities (`timeAverage`, `cutData`, etc.)  
✅ Maintain the `date` column in POSIXct format  
✅ Follow parameter ordering (data first, plot last)  

### DON'T:
❌ Modify OpenAir source code  
❌ Add date filtering parameters to your functions  
❌ Use snake_case or PascalCase for function names  
❌ Ignore OpenAir's data validation  
❌ Return incompatible data structures  
❌ Rename standard columns (`ws`, `wd`, `date`)  
❌ Assume data is pre-filtered  
❌ Mix naming conventions  

---

## Resources

### OpenAir Documentation
- Package website: https://openair-project.github.io/openair/
- Manual/Book: https://openair-project.github.io/book/
- GitHub: https://github.com/openair-project/openair
- CRAN: https://cran.r-project.org/package=openair

### Key References
- Carslaw, D.C. and K. Ropkins (2012). openair — An R package for air quality data analysis. *Environmental Modelling & Software* 27-28: 52-61.

### Example Packages Extending OpenAir
- `openairmaps`: Mapping air quality data
- `worldmet`: Meteorological data access
- `deweather`: Weather normalization

---

## Appendix: Quick Reference

### Essential OpenAir Functions for Integration

| Function | Purpose |
|----------|---------|
| `checkPrep()` | Validate and prepare data |
| `selectByDate()` | Filter data by date/time |
| `timeAverage()` | Aggregate time series |
| `cutData()` | Split data by conditioning variable |
| `date.pad()` | Fill missing dates |
| `importAURN()` | Import UK air quality data |
| `timePlot()` | Time series visualization |
| `polarPlot()` | Polar plot visualization |
| `calendarPlot()` | Calendar visualization |

### Standard Data Frame Structure

```r
# Minimal structure
data.frame(
  date = POSIXct,      # REQUIRED
  pollutant = numeric  # At least one
)

# Full structure
data.frame(
  date = POSIXct,      # REQUIRED
  ws = numeric,        # Wind speed (m/s)
  wd = numeric,        # Wind direction (degrees)
  nox = numeric,       # Pollutant
  no2 = numeric,       # Pollutant
  o3 = numeric,        # Pollutant
  pm10 = numeric,      # Pollutant
  site = character,    # Site ID (optional)
  code = character     # Site code (optional)
)
```

---

**Document Version:** 1.0  
**Last Updated:** 2025  
**Maintainer:** Integration Team  
**License:** MIT (compatible with OpenAir)

# Future Enhancements

## Issue 1: Display Insufficient Data Sites
**Location:** `R/quickmap_clean.R:51`
**Description:** Could display sites with >20% missing data as white disks with "Insufficient data" labels instead of filtering them out entirely.
**Priority:** Low
**Impact:** Better visualization of data coverage

## Issue 2: Add Input Validation for Boundary Names
**Location:** `R/quickmap_clean.R:258-259`
**Description:** Add input validation for boundary_names parameter to handle NULL, missing, or invalid input gracefully. Currently assumes input is always valid.
**Priority:** Medium
**Impact:** Better error handling and user experience

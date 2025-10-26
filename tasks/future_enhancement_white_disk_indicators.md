# Future Enhancement: White Disk Indicators for Low-Quality Data

**Created**: 2025-10-15
**Category**: UI Enhancement
**Priority**: LOW
**Estimated Effort**: 2-3 hours

---

## Current Implementation (v0.8.7.1+)

**Approach**: Sites with >20% missing data are **filtered out completely** and do not appear on maps.

**Location**: `quickmap.R` line ~124 in `process_oa_data()` function

**Rationale**:
- Simplest implementation (minimal code changes)
- Avoids potential issues with NA handling in label generation
- Clean, predictable behavior

**Limitations**:
- Users cannot see that sites existed but had poor data quality
- No visual indication of data quality issues
- Sites simply disappear from the map

---

## Proposed Enhancement: White Disk Display

### Concept
Instead of filtering out low-quality data completely, display these sites as **white disk markers** with "Insufficient data" labels.

### Benefits
- ✅ Users see that monitoring sites exist at those locations
- ✅ Visual indication of data quality issues
- ✅ More transparent about data availability
- ✅ Helps identify areas needing better monitoring coverage

### Implementation Approach (Option B from design phase)

**Three code changes required:**

#### 1. Modify `process_oa_data()` to set NA values
**Location**: Line ~124

**Current code (filters out rows)**:
```r
data <- data[is.na(data[[missing_col]]) | data[[missing_col]] <= MISSING_DATA_THRESHOLD, ]
```

**Proposed code (sets values to NA)**:
```r
# Set pollutant value to NA where missing data exceeds threshold
# This will trigger white disk display in downstream rendering
data[[pollutant]] <- ifelse(
  !is.na(data[[missing_col]]) & data[[missing_col]] > MISSING_DATA_THRESHOLD,
  NA,
  data[[pollutant]]
)
```

#### 2. Remove NA filter in layer generation
**Location**: Line ~1552

**Current code (removes NA values)**:
```r
year_data <- dplyr::filter(year_data, !is.na(.data[[pollutant]]))
```

**Proposed code (comment out filter)**:
```r
# Don't filter NA values - they will display as white disks
# year_data <- dplyr::filter(year_data, !is.na(.data[[pollutant]]))
```

#### 3. Fix label generation for NA values
**Location**: Line ~1221 in `prepare_bl_layer_data()`

**Current code**:
```r
labels <- paste(round(oa_subset[[pollutant]], 0), "ug/m3")
```

**Proposed code**:
```r
labels <- ifelse(
  is.na(oa_subset[[pollutant]]),
  "Insufficient data",
  paste(round(oa_subset[[pollutant]], 0), "ug/m3")
)
```

---

## Why This Works

1. **`assign_colour()` already handles NA** (line 671):
   ```r
   if (is.na(value) || !is.numeric(value)) return("white")
   ```
   - Returns white color automatically for NA values
   - No changes needed to color assignment logic

2. **Legend already updated**: All colour scales now say "Insufficient data" for white disks

3. **Minimal changes**: Only 3 code locations need modification

---

## Testing Requirements

When implementing this enhancement:

1. **Verify white disks appear** for sites with >20% missing data
2. **Check label display**: Should show "Insufficient data" not "NA ug/m3"
3. **Test both pollutants**: NO2 and PM2.5 should work independently
4. **Backward compatibility**: Old data files without missing columns should still work
5. **Visual verification**: Check that white disks appear on both interactive and static maps

---

## Related Files

- **Implementation plan**: `tasks/bug_2_missing_data_filter_implementation_plan.md`
- **Data preparation script**: `prepare_bl_data_with_missing.R`
- **Main code file**: `quickmap.R`

---

## Notes

- This enhancement was considered during initial implementation but deferred for simplicity
- Current approach (filtering out rows) is working well and should not be changed unless this enhancement is explicitly requested
- Estimated effort is low because the infrastructure is already in place (NA handling, white disk colors, updated legends)
- No new dependencies or complex logic required

---

**Status**: DOCUMENTED for future consideration

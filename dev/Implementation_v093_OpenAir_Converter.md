# v0.9.3 OpenAir Converter: Step-by-Step Implementation Plan

## Context

OpenAir networks (AURN, LAQN) accessible via `importAURN()`, `importKCL()` return temporal data.frames, not sf objects - no direct path to quickmap visualization.

## Final Objective

Generic converter transforms OpenAir data.frames to sf objects compatible with v0.9.2 layer system, enabling AURN/LAQN overlay on existing networks.

## Approach

Incremental steps, commit-test-approve workflow, code review checkpoints.

## Scope

**Must Include:** - Full temporal aggregation support (year/month/day/hour via `avg.time`) - Sub-annual data infrastructure ready for v0.9.4 UI controls

**Must Exclude:** - Sub-annual UI controls (temporal menus deferred to v0.9.4) - sftime objects (v0.9.4) - Automatic integration into create_pollution_map() (thin wrapper is future work) - Changes to existing CSV/RData loaders

**Design Decisions:** - Metadata cache: Implementation choice (environment vs data.table) left to agent - Performance benchmarking: API download logged separately, conversion performance isolated - Column duplication (lat/lon + Longitude/Latitude): Implemented as specified for v0.9.2 compatibility

## Lessons from v0.9.2

-   **Avoid line numbers** - brittle after edits
-   **Design schemas upfront** - converter output format must match existing sf structure exactly
-   **Avoid prescribing names** - let Claude choose function parameters
-   **State "what" not "how"** - outcomes, not implementation steps

------------------------------------------------------------------------

## STEP 0: Architecture Discovery

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Document OpenAir API, data structure, metadata formats, and coordinate requirements

**What to do:** - checkout a new branch for v093 based on latest commit to main- Check current OpenAir API function names (importUKAQ vs importAURN, importKCL vs alternatives) - Examine OpenAir metadata formats from importMeta() - what fields available, how structured - Test if metadata already embedded in OpenAir data or requires separate fetch - Examine OpenAir data.frame structure (columns, types, conventions) - Grep for coordinate handling in existing code - Document expected sf output format (must match `process_oa_data()` output) - Evaluate: should metadata be stored in data_source YAML configs vs cache, or is this duplicating OpenAir functionality - Write findings to dev/ANALYSIS_openair_structure.md

**User will test:** Review analysis, confirm approach doesn't reinvent OpenAir functionality

------------------------------------------------------------------------

## STEPS 1-N: Implementation Steps

### STEP 1: Create Metadata Cache System

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Session-level cache stores site coordinates from `importMeta()`

\*\*Begin by:\*\* create new branch from last commits

**What must exist:** - In-memory cache stores source → metadata mapping (agent chooses environment vs data.table) - Function to fetch/cache metadata: checks cache first, calls `importMeta()` if missing - Cache persists within R session, not across sessions - Returns data.frame with columns: site, code, latitude, longitude - If `importMeta()` fails: return informative error, don't cache NULL - Manual cache invalidation function available if needed

**User will test:** Call fetch function twice for same source, verify second call uses cache (no API call)

------------------------------------------------------------------------

### STEP 2: Create Core Converter Function

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** `convert_openair_to_spatial()` transforms OpenAir data.frame to sf object

**What must exist:** - Function accepts: data (OpenAir data.frame), source (e.g., "aurn"), pollutant, avg.time (default "year") - Calls `timeAverage(data, avg.time)` for temporal aggregation - Fetches coordinates from metadata cache - Joins data with coordinates by site code - Converts to sf object with WGS84 (EPSG:4326) - Output columns match `process_oa_data()`: siteCode, year, pollutant, lat, lon, Longitude, Latitude, year_str, geometry - Filters sites without coordinates, warns user

**User will test:** Convert mock OpenAir data (3 sites, 2 years), verify sf structure matches existing

------------------------------------------------------------------------

### STEP 3: Handle Missing Data and Edge Cases

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Converter handles sites without coordinates, missing data gracefully

**What must exist:** - Sites in data but not in metadata: filtered out with warning listing site codes - Sites with missing coordinates (NA lat/lon): filtered out with warning - Empty result (all sites filtered): returns empty sf with correct structure, warns user - Missing pollutant column: clear error message - Invalid `avg.time` values: clear error message with valid options listed

**User will test:** Convert data with missing coordinates, verify warnings and filtered output

------------------------------------------------------------------------

### STEP 4: Add Variable Time Interval Aggregation Support

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Converter supports multiple aggregation periods via `avg.time`

**What must exist:** - avg.time parameter passed to `timeAverage()`: "year", "month", "day", "hour" - For annual (avg.time="year"): output has `year` and `year_str` columns (existing format) - For sub-annual: output has `date` column (POSIXct) + `year_str` (formatted string) - year_str format adapts: annual="2023", monthly="2023-01", daily="2023-01-15", hourly="2023-01-15 08:00" - Maintains compatibility with existing annual-only workflow

**Note:** This implements full temporal aggregation infrastructure. Sub-annual data will be available for rendering once v0.9.4 adds temporal UI controls. Until then, maps display aggregated data without time-series interaction.

**User will test:** Convert with avg.time="year" (annual) and avg.time="month", verify date formatting

------------------------------------------------------------------------

## MID-POINT: Code Review Checkpoint

**After Step 4:** - Run automated code review agent - Address critical/major issues before proceeding - Verify converter output matches existing sf structure exactly

------------------------------------------------------------------------

## STEP 5: Create AURN Test Script

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Test script downloads AURN data, converts, maps with existing networks

**What must exist:** - Script `tests/test_aurn_converter.R` that: - Downloads AURN data for 2-3 London sites, 2 years using current OpenAir API (e.g., `importUKAQ()` or `importAURN()`) - Converts using `convert_openair_to_spatial()` - Creates AURN config YAML (square icon, no2 pollutant) - Maps AURN + existing dt_sites + schools using v0.9.2 API - Map renders with 3 distinct icon shapes

**User will test:** Run script, verify AURN sites appear with square icons, coordinates accurate (spot-check)

------------------------------------------------------------------------

## STEP 6: Create LAQN Test Script

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Test script downloads LAQN data, converts, overlays with AURN

**What must exist:** - Script `tests/test_laqn_converter.R` that: - Downloads LAQN data for 2-3 sites, 2 years using current OpenAir API (e.g., `importKCL()` or alternative) - Converts using `convert_openair_to_spatial()` - Creates LAQN config YAML (triangle icon, no2 pollutant) - Maps AURN + LAQN + dt_sites + schools (4 networks) - Map renders with 4 distinct icon shapes

**User will test:** Run script, verify 4-network overlay with correct icons

------------------------------------------------------------------------

## STEP 7: Performance Validation

**Scope:** Work only on objectives stated, check errors/dependencies, no elaboration

**Outcome:** Verify converter handles realistic data volumes efficiently

**What must exist:** - Test with 50 sites × 5 years = 250 features - Performance metrics: - API download time: logged but not benchmarked (network-dependent) - Conversion: < 5 seconds for 250 features - Rendering: uses existing baseline (~25s, no regression) - Memory profile: peak usage documented - No performance regression vs existing CSV/RData loaders

**User will test:** Run performance test, confirm conversion < 5s, no rendering regression

------------------------------------------------------------------------

## FINAL STEPS

### Code Cleanup

**Outcome:** Remove dead code, add minimal docs

**What must exist:** - Roxygen2 documentation for `convert_openair_to_spatial()` and cache functions - 5-line change note in dev/change_notes/ - Example usage in function docs

### Validation

**Outcome:** All tests pass, coordinate accuracy verified

**User will test:** - All existing test scripts pass (regression check) - AURN test renders correctly - LAQN test renders correctly - 4-network overlay works - Spot-check 3 AURN site coordinates against Google Maps

------------------------------------------------------------------------

## After Each Step

1.  Claude confirms: "Step X complete. Changed: \[files\]. Tests: \[passed/failed\]. Proceed to Step Y?"
2.  Claude commits + pushes to branch
3.  User pulls, tests locally, responds: "proceed" or "fix X"

------------------------------------------------------------------------

## Notes for Agent

**What to do:** - Reuse existing patterns from `process_oa_data()` for sf conversion - Focus only on step objective - Run smoke test after each step (`Rscript tests/test_quickmap.R`) - Stop and wait for user approval before next step - Explicitly confirm current step number - Keep all documentation concise, describe only essentials

**What NOT to do:** - Prescribe parameter/function names unless critical - Reference line numbers (brittle) - Implement sub-annual UI controls (deferred to v0.9.4) - Combine steps even if related - Integrate into create_pollution_map() wrapper (future work)
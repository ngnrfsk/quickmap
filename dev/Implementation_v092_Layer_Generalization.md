# v0.9.2 Layer Generalization: Step-by-Step Implementation Plan

## Context

QuickMap v0.9.1 has three hardcoded layer types (dt_sites, bl_nodes, schools) with coupled parameters throughout R/quickmap.R lines 1249-1634. Adding new monitoring networks, data sources like the AURN, LAQN, requires modifying 15+ code locations. This doesn't scale. A generalized layer system is needed before OpenAir integration (v0.9.3).

## Final Objective

Refactor layer system to data-driven configuration where adding a new data source requires only a YAML config file, not code modification. System must support unlimited data sources with distinct visual identities (5+ icon shapes/colors) while maintaining 100% backward compatibility with v0.9.1 behavior.

## Approach: Incremental, Testable Steps

-   Each step will be executed one at a time
-   Identify any dependency issues or other problems identified to the user at the end of each step
-   After each step, code will be committed and pushed to feature branch
-   User will pull locally and test
-   Only proceed to next step when user confirms current step passes
-   If step fails, fix in same chat before proceeding

## Scope

**Must Include:** Work only on code objectives stated in each step, checking for errors or dependencies, but NO elaboration on instructions.

**Must Exclude:** - Do NOT modify temporal controls (year-only display unchanged) - Do NOT break existing `create_pollution_map()` API (backward compatible additions allowed) - Do NOT modify existing data loaders (`load_data_file()`, `process_oa_data()`) - Do NOT add new dependencies or packages

------------------------------------------------------------------------

## STEP 0: Starting Point

**Branch:** Create branch `feature/v092-layer-generalization` from commit `90c0b83`

**Base code locations:** - Layer configuration: `get_measurement_layers()` (R/quickmap.R:1249-1278) - Layer processing: `generate_map_layers()` (R/quickmap.R:1561-1634) - Icon generation: `create_generic_icons()` (R/quickmap.R:\~1400) - Data loading: `load_data_file()` (R/quickmap.R:\~50-150)

**Reference existing pattern:** Config-based styling already exists for color scales (inst/config/scales/) and themes (inst/themes/)—reuse this approach for layer configs.

------------------------------------------------------------------------

## STEP 1: Add Flexible Multi-data source Data Loading

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** `create_pollution_map()` accepts flexible data sources via parallel vectors instead of 3 hardcoded file parameters.

**What must change:** - Add new parameters to `create_pollution_map()` (R/quickmap.R:\~1776-1778): - `data_sources` (list): file paths (strings) or data tables (sf objects) - `data_configs` (character vector): config names parallel to `data_sources` - Keep existing parameters for backward compatibility: `diffusion_tube_file`, `sensor_file`, `school_file` - Internal logic: if old parameters used, convert to new format - Modify data loading pipeline to iterate `data_sources`, loading files or using sf objects directly - Update `get_measurement_layers()` to accept data objects + config names instead of file parameters

**Why:** Enables unlimited data sources without API bloat. Step 6 can test 4th data source via production API, not test-only hack.

**User will test:** - Old API still works: `create_pollution_map(diffusion_tube_file="dt.csv", sensor_file="bl.Rdata", school_file="schools.csv")` - New API works: `create_pollution_map(data_sources=list("dt.csv", "bl.Rdata", "schools.csv"), data_configs=c("dt_sites", "bl_nodes", "schools"))` - Generated maps visually identical to v0.9.1 - No errors, no warnings

------------------------------------------------------------------------

## STEP 2: Extract Icon Shape Definitions

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Icon shape mappings moved from switch statements to data-driven lookup.

**What must exist:** - Mechanism to map shape names ("circle", "diamond", "cross", "square", "triangle") to icon parameters - `create_generic_icons()` (R/quickmap.R:\~1400) uses data-driven lookup instead of hardcoded switch statements - Color assignment unchanged: pollution data uses colour_scale (dynamic), schools use categorical colors - Existing three shapes (circle, diamond, cross) work identically

**Why:** Enables arbitrary icon shapes while preserving existing color logic.

**User will test:** - Existing maps render with correct icons (circles, diamonds, crosses) - No visual changes from v0.9.1

------------------------------------------------------------------------

## STEP 3: Refactor generate_map_layers() to Remove Hardcoded Layer Types

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** `generate_map_layers()` reads config fields generically instead of switching on `layer_type`.

**What must change:** - `generate_map_layers()` (R/quickmap.R:1561-1634) removes hardcoded logic: `if (layer_config$layer_type %in% c("dt_sites", "bl_nodes"))` - Read config fields: `pollutant_col` (column name containing pollution data), `icon_shape` - Filter missing data using `config$pollutant_col` instead of layer_type check - All layer types handled identically via config fields - Leaflet group names use `config$id` instead of `layer_config$layer_type` - Color assignment remains dynamic (from colour_scale or categorical), not stored in configs

**Why:** Defines the config contract—what fields must exist. Eliminates 15+ hardcoded modification points.

**User will test:** - Pass test_quickmap.R - Existing maps (diffusion tubes + BL sensors + schools) render correctly - No errors during map generation

------------------------------------------------------------------------

## STEP 4: Update get_measurement_layers() to Match New Config Contract

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** `get_measurement_layers()` returns configs with fields required by Step 3.

**What must change:** - `get_measurement_layers()` (R/quickmap.R:1249-1278) adds new fields to existing list structure: - `id`: "dt_sites", "bl_nodes", "schools" - `pollutant_col`: column name for pollution data (e.g., "no2", "pm25", or NULL for schools) - `icon_shape`: "circle", "diamond", "cross" - Keep existing fields: `enabled`, `data_source`, `temporal`, `options$marker_labels` - Remove `layer_type` field (replaced by `id`) - Color logic determined at render time from colour_scale parameter, not stored in config

**Why:** Provides configs matching Step 3's contract without changing behavior.

**User will test:** - Existing test scripts (test_quickmap.R) run unchanged - Generated maps visually identical to v0.9.1 - No errors when calling `get_measurement_layers()`

------------------------------------------------------------------------

## STEP 5: Create data source Config Infrastructure and Replace Hardcoded Configs

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** YAML-based data source configs replace hardcoded config values in `get_measurement_layers()`.

**What must exist after this step:** - Config storage: `inst/config/data_sources/` - YAML files for existing data sources: `dt_sites.yaml`, `bl_nodes.yaml`, `schools.yaml` - YAML structure includes: id, label, icon_shape, pollutant_col, temporal (fields from Step 3/4) - Loader function `load_data_source_config(name)` analogous to `load_colour_scale()` - Optional: Writer utility for programmatic YAML creation - Refactor `get_measurement_layers()`: replace hardcoded field values with `load_data_source_config()` calls - Config names from `data_configs` parameter (Step 1) used to load YAMLs

**Constraints:** - Must follow existing YAML pattern from inst/config/scales/ and inst/themes/ - Loading mechanism returns R list matching Step 3/4 config structure - No color specification in YAML (color logic remains in rendering code)

**Why:** Completes transition to data-driven configs. Existing 3 networks now loaded from YAML, not hardcoded.

**User will test:** - Directory `inst/config/data_sources/` contains dt_sites.yaml, bl_nodes.yaml, schools.yaml - `load_data_source_config("dt_sites")` returns valid config list - Existing test scripts pass unchanged (maps identical to v0.9.1) - Config changes (e.g., edit dt_sites.yaml to use square icon) reflect in rendered map without code changes

------------------------------------------------------------------------

## STEP 6: Add Mock 4th data_source for Testing

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Demonstrate extensibility by adding mock AURN network via new `data_sources`/`data_configs` API.

**What must exist:** - Test script `tests/test_4network_mock.R` that: - Loads existing diffusion tube + BL sensor + school files - Creates mock AURN data (5 sites, 3 years) matching bl_annual_means_sf structure (columns: siteCode, year, no2, geometry) - Creates AURN config YAML: `aurn.yaml` with square icon, pollutant_col="no2", temporal=TRUE - Calls `create_pollution_map()` using new API with 4 networks - Map renders with 4 distinct icon shapes - NO changes to core rendering code

**Why:** Validates production API supports unlimited networks via config, not code modification.

**User will test:** - Run `tests/test_4network_mock.R` - Map displays 4 network types with distinct icon shapes: - Diffusion tubes: circles (colored by NO2 value using selected colour scale from inst/config/scales/) - BL sensors: diamonds (colored by NO2 value using selected colour scale) - Schools: crosses (colored by school level using schools.yaml categorical scale) - Mock AURN: squares (colored by NO2 value using selected colour scale) - All layers toggle on/off independently - Icon colors determined by `colour_scale` parameter (e.g., "who_no2", "lbrut_no2"), not hardcoded - Colour scale loaded via `load_colour_scale()` from YAML configs

------------------------------------------------------------------------

## STEP 7: Code Cleanup and Documentation

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Remove dead code, add roxygen2 documentation, verify complexity reduction, provide minimum essential documentation

**What must be done:** - Remove old `layer_type` switch statements and hardcoded checks - Add minimalist roxygen2 documentation for new config infrastructure functions - Update internal comments explaining config-based architecture - Verify: Reduced number of `switch()` and `if (layer_type == ...)` statements

**Why:** Clean code, document architecture sufficient for future maintainers but including only necessary and essential information, confirm complexity reduction goal met.

**User will test:** - All existing tests still pass - Code is readable and documented - No unused/dead code remains

------------------------------------------------------------------------

## STEP 8: Regression Testing and Validation

**Scope:** Work only on the code objectives stated in this step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome:** Comprehensive testing confirms v0.9.2 achieves success criteria.

**What must be validated:** - \[ \] All 14 existing test scripts pass unchanged - \[ \] Mock 4th network renders via YAML config (count actual lines) - \[ \] `create_pollution_map()` signature unchanged (no new required parameters) - \[ \] Visual comparison: v0.9.1 vs v0.9.2 maps identical for same input data - \[ \] Performance benchmark: No regression (same render times as v0.9.1) - \[ \] Code metrics: Count switch statements before/after, confirm reduction

**Testing checklist:** 1. Run `test_quickmap.R` → PASS 2. Run `do_maps_with_v0.8.3_LBM_PM25.R` → PASS 3. Run all 14 scripts in `tests/` directory → ALL PASS 4. Run `tests/test_4network_mock.R` → 4 networks render distinctly 5. Side-by-side visual check: Wandsworth 2023 map (v0.9.1 vs v0.9.2) → IDENTICAL 6. Performance: 100 sites × 5 years benchmark → \<30 seconds (same as v0.9.1)

**User will test:** - Complete testing checklist - Report any failures or visual differences - Confirm v0.9.2 ready for merge to main

------------------------------------------------------------------------

## After Each Step

1.  Agent commits changes with minimum descriptive message
2.  Agent pushes to `origin/feature/v092-layer-generalization`
3.  Agent tells user: "Step X complete, pushed to origin/feature/v092-layer-generalization"
4.  User pulls code locally, runs tests described in step
5.  User reports: "Step X passes" or describes specific issue
6.  If pass: user says "Proceed to Step X+1"
7.  If fail: agent fixes in same chat, re-tests, re-pushes

------------------------------------------------------------------------

## Notes for Agent

**Reuse existing patterns:** - Config-based approach: Follow inst/config/scales/ and inst/themes/ patterns - Functional style: quickmap uses named lists and helper functions, not R6 classes - Error handling: Use existing `tryCatch()` and warning patterns from codebase

**Keep workings and documents concise and minimal:** - Be as brief as possible, document only the essentials - protect context headroom - ensure intermediate workings and output are concise and human readable

**Keep changes focused:** - Each step modifies minimal code needed for that step's outcome - Don't refactor unrelated code - Don't add features beyond step scope

**Preserve critical behavior:** - Two-pass rendering: `generate_map_layers(year)` then `generate_map_layers("static_only")` - `temporal` flag: TRUE for pollution data, FALSE for schools - Data passing: maintain existing architecture (Step 1 handles both file paths and sf objects)

**Base all work on:** - Commit: 90c0b83 (current main branch HEAD) - Branch: feature/v092-layer-generalization (create from 90c0b83)

**Testing priority:** - Regression: Existing functionality must work identically - Visual: Maps must look the same as v0.9.1 - Performance: No slowdowns introduced

**Stop after each step:** - Wait for explicit user approval before proceeding - Don't combine steps even if they seem related - User needs to validate each increment works
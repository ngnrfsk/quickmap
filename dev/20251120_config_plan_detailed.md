# Configuration System Implementation Plan - Detailed Steps

**Date**: 2025-11-20
**Based on**: dev/20251120_config_plan_outline.md
**Status**: Planning Phase - Ready for Execution

---

## Context

QuickMap has inline CSS/JS code with fragile positional sprintf placeholders and hardcoded color scales in R. The roller menu control demonstrates a better pattern (external files in inst/controls/), but banner/legend CSS remains embedded inline with 14+ positional parameters. The working files are in folder R/, dev/, inst/.

---

## Final Objective

Modernize QuickMap's configuration and styling system by:
1. Extracting all banner/legend CSS/HTML to external files in inst/ subfolders
2. Migrating to named placeholders (gsub pattern) for self-documenting code
3. Implementing a flexible color scale loader with YAML support and R list fallback
4. (Optional) Adding external theme file system for user customization

All changes maintain backward compatibility and follow the roller menu control pattern.

---

## Approach: Take small, testable incremental steps towards goal

- Intermediate tasks will be executed one step at a time
- At the end of each Step, push code, ask user to pull/download locally to test code
- Wait for user feedback on Step
- Only proceed to next step when instructed to do so by user

---

## Scope within each step

- Work only on the code objectives stated in each Step
- Check for errors, 
- Check for dependencies, including past or future steps
- NO elaboration on instructions

**Strictly Limited To:**
- Material described in dev/20251120_config_plan_outline.md
- CSS/JS extraction (Phase 1)
- Configuration system with YAML support (Phase 2-3)
- Theme system (Phase 4)

**Out of Scope:**
- Code simplification (separate plan)
- Database integration (future)
- Legend layout redesign (separate legend refactor plan)

---

## STEPS

### STEP 0: Starting Point

**Branch:** Create branch `claude/config-system-implementation-[session-id]` from main (commit 2afa972)

**Base code includes legend refactor work:**
- Banner/legend already extracted to `inst/banner/banner.css` and `inst/legend/legend.css`
- Legend HTML template at `inst/legend/legend.html` with dynamic trimming and horizontal layout
- Color scales: `R/quickmap.R` lines 524-774 (colour_scales list)
- Reference patterns: `load_banner_css()`, `load_legend_css()`, `load_roller_menu_control()` functions

**Dependencies identified:**
- ✅ Banner/legend extraction COMPLETE (legend refactor branch merged to main)
- ⚠️ Named placeholders: Banner/legend use sprintf; roller menu needs migration to gsub pattern
- Config loader must exist before YAML conversion
- Theme system depends on config system patterns

**Note:** Steps 1-2 from original plan already complete via legend refactor. Start config work at Step 3 (verify placeholder pattern) or Step 4 (colour scale loader).

---

### STEP 1: Extract Banner CSS to inst/banner/

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Banner CSS code moved from inline in R file to separate reusable file with named placeholders

**What must exist after this step:**
- Directory: `inst/banner/`
- File: `inst/banner/banner.css` containing:
  - Banner-related CSS rules extracted from apply_custom_layout_in_html()
  - Named placeholders for colors: `{{banner_bg}}`, `{{text_color}}`
  - Both interactive and image_mode variants in single file (use CSS comments to mark sections)
- Modified `R/quickmap.R` with new helper function `load_banner_css()` that:
  - Reads `inst/banner/banner.css` content
  - Accepts `banner_colour` and `image_mode` parameters
  - Uses `gsub()` to replace named placeholders: `gsub("{{banner_bg}}", banner_colour, css_content)`
  - Returns CSS string wrapped in `<style>` tags
- Modified `apply_custom_layout_in_html()` to:
  - Call `load_banner_css()` instead of inline CSS generation
  - Remove old banner CSS code from function
- Preserve image dimension scaling logic in R function (if any gsub operations needed on returned CSS)

**Why**: Follows roller menu pattern, makes banner CSS maintainable and testable, eliminates positional sprintf

**User will test:**
- Generate map with banner (styling_type = "html")
- Banner displays with correct colors, fonts, spacing
- Test both interactive HTML and static image exports
- Verify banner looks identical to previous version

---

### STEP 2: Extract Legend CSS to inst/legend/

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Legend CSS code moved from inline in R file to separate reusable file with named placeholders

**What must exist after this step:**
- Directory: `inst/legend/` (may already exist from legend refactor)
- File: `inst/legend/legend.css` containing:
  - Legend-related CSS rules extracted from apply_custom_layout_in_html()
  - Named placeholders for colors: `{{legend_bg}}`, `{{legend_header_bg}}`, `{{legend_header_hover_bg}}`, `{{border_color}}`
  - Both interactive and image_mode variants
  - Mobile responsive CSS (@media queries) preserved
- Modified `R/quickmap.R` with helper function `load_legend_css()` that:
  - Reads `inst/legend/legend.css` content
  - Accepts `banner_colour` and `image_mode` parameters
  - Calculates legend header colors using existing `lighten_color()` function
  - Uses `gsub()` to replace all named placeholders
  - Returns CSS string wrapped in `<style>` tags
- Modified `apply_custom_layout_in_html()` to:
  - Call `load_legend_css()` instead of inline CSS generation
  - Remove old legend CSS code from function
- Preserve image dimension scaling logic in R function

**Why**: Completes CSS extraction pattern, consistency with banner and roller menu approaches

**User will test:**
- Generate map with legend (styling_type = "html")
- Legend displays with correct colors, collapsible behavior works
- Test on desktop and mobile screen sizes (responsive CSS)
- Verify legend looks identical to previous version

---

### STEP 3: Verify Named Placeholder Pattern and Documentation

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: All CSS loading functions verified for consistency, pattern documented

**What must exist after this step:**
- Review all CSS/JS loading functions:
  - `load_banner_css()` (Step 1)
  - `load_legend_css()` (Step 2)
  - `load_roller_menu_control()` (existing)
- Verify no function uses sprintf with >3 positional parameters for CSS injection
- If any remaining positional sprintf found, migrate to named placeholders
- Add code comment header to each loader function documenting:
  - Named placeholders used (list them)
  - Pattern rationale (self-documenting, maintainable)
  - Reference to roller menu as established pattern
- Update existing inline comments to note the gsub/named placeholder approach

**Why**: Ensures consistency across all controls, prevents regression to positional sprintf

**User will test:**
- Generate complete map with banner, legend, and year control
- All three controls display correctly with coordinated colors
- No CSS injection errors in browser console
- Visual inspection confirms professional appearance

---

### STEP 4: Implement Colour Scale Loader with Fallback

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: New function to load color scales from YAML files with automatic fallback to hardcoded R lists

**What must exist after this step:**
- New function `load_colour_scale()` in `R/quickmap.R` that:
  - Takes `scale_name` parameter (character string like "who_no2")
  - Constructs path: `system.file("config/scales", paste0(scale_name, ".yaml"), package = "quickmap")`
  - Checks if YAML file exists
  - If exists: loads using `yaml::read_yaml()` and returns result
  - If not exists: returns `colour_scales[[scale_name]]` (fallback to hardcoded R list)
  - Handles errors gracefully (file exists but malformed YAML → warning + fallback)
- Add dependency check: if yaml package not installed, always use fallback
- Modified usage in `create_pollution_map()` or relevant functions:
  - Replace direct access `colour_scales[[colour_scale]]` with `load_colour_scale(colour_scale)`
  - Store result in variable: `scale <- load_colour_scale(colour_scale)`
  - Use `scale$colours`, `scale$thresholds`, `scale$labels`, `scale$title`
- No YAML files created yet (test fallback path only)
- Preserve all existing color scale functionality

**Why**: Establishes infrastructure for external config files while maintaining 100% backward compatibility

**User will test:**
- Generate maps with various color scales (who_no2, lbw_no2, schools, gla_pm25)
- All scales render correctly (using R list fallback since no YAML exists yet)
- No errors or warnings about missing YAML files
- Verify scale colors, thresholds, labels all work as before

---

### STEP 5: Convert 3 Scales to YAML as Proof of Concept

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Three color scales available as YAML files, loader retrieves them successfully

**What must exist after this step:**
- Directory: `inst/config/scales/`
- File: `inst/config/scales/who_no2.yaml` containing:
  - All fields from R list: name, title, pollutant, shape, thresholds, colours, labels
  - Proper YAML syntax (validated)
  - Equivalent to existing who_no2 scale
- File: `inst/config/scales/lbw_no2.yaml` (Wandsworth NO2 scale)
  - Same structure as who_no2
- File: `inst/config/scales/schools.yaml` (Schools categorical scale)
  - Same structure, adapted for categorical data
- Keep original R list definitions in place (for now, backward compatibility)
- Update `load_colour_scale()` if any adjustments needed based on YAML structure
- Test YAML loading path works

**Why**: Validates YAML approach with diverse scale types (WHO-based, borough-specific, categorical)

**User will test:**
- Generate map with colour_scale = "who_no2" (should load from YAML)
- Generate map with colour_scale = "lbw_no2" (should load from YAML)
- Generate map with colour_scale = "schools" (should load from YAML)
- Generate map with colour_scale = "gla_pm25" (should fallback to R list)
- Verify all maps render identically to previous versions
- Check that YAML-loaded scales produce exact same colors as R lists

---

### STEP 6: Evaluate YAML Approach and Gather User Feedback

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Decision point on whether to proceed with full YAML migration

**What must happen:**
- User tests maps with YAML scales extensively:
  - Performance (loading speed)
  - Correctness (colors, thresholds, labels)
  - Ease of modification (edit YAML file directly)
  - Error handling (try malformed YAML)
- Document findings in testing notes
- User decides on one of three paths:
  - **Option A**: Proceed with full YAML migration (convert remaining 6+ scales)
  - **Option B**: Keep hybrid approach (3 scales in YAML, others in R lists, loader supports both)
  - **Option C**: Abandon YAML (remove 3 YAML files, keep only R lists)
- Decision documented in code comment and/or CLAUDE.md

**Why**: Evidence-based decision making, avoid over-engineering if YAML doesn't provide clear value

**User will test:**
- Edit `inst/config/scales/who_no2.yaml` directly (change a threshold or color)
- Regenerate map, verify change appears
- Test with intentionally malformed YAML (syntax error), verify graceful fallback
- Assess ease of use vs R list editing
- Make migration decision based on experience

**Note**: If decision is Option C (abandon YAML), skip Step 7 and proceed to Step 8.

---

### STEP 7: Convert Remaining Scales to YAML (CONDITIONAL)

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: All color scales available as YAML files

**What must exist after this step:**
- Additional YAML files in `inst/config/scales/`:
  - `stripes_no2.yaml`
  - `stripes_pm25.yaml`
  - `lbrut_no2.yaml` (Richmond)
  - `lbm_no2.yaml` (Merton)
  - `gla_pm25.yaml`
  - `deltas.yaml`
- All scales tested with `load_colour_scale()`
- (Optional) Add YAML schema validation function to check structure
- (Optional) Consider deprecating hardcoded R lists in future version (document intent)

**Why**: Completes YAML migration for consistent external configuration

**Conditions**: Only execute this step if Step 6 decision was Option A (proceed with full migration)

**User will test:**
- Generate maps with each color scale
- Verify all 9 scales load correctly from YAML
- Spot check several scales for correctness
- Confirm no regression from R list versions

---

### STEP 8: Implement Theme Loader Functions

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Infrastructure for loading external theme files with graceful defaults

**What must exist after this step:**
- New function `get_default_theme()` in `R/quickmap.R` that:
  - Returns R list with default theme settings
  - Structure matches outline specification (banner, legend, map, controls sections)
  - Values match current hardcoded defaults
- New function `load_theme()` in `R/quickmap.R` that:
  - Takes `theme_file` parameter (character string path or NULL)
  - If NULL: returns `get_default_theme()`
  - If not NULL and file doesn't exist: warning + return `get_default_theme()`
  - If file exists: loads using `yaml::read_yaml(theme_file)`
  - Merges loaded theme with defaults using `modifyList(default_theme, theme)`
  - Returns complete theme list
- Error handling for malformed theme files
- No integration with create_pollution_map() yet (just function exists)
- No example theme files yet (will be Step 9)

**Why**: Establishes theme loading infrastructure before creating example themes and integrating

**User will test:**
- Call `get_default_theme()` in R console, inspect structure
- Call `load_theme()` with NULL, verify returns defaults
- Call `load_theme("nonexistent.yaml")`, verify warning and defaults returned
- No user-facing functionality yet (internal functions only)

---

### STEP 9: Create Example Theme Files

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: 2-3 example theme files demonstrating customization capabilities

**What must exist after this step:**
- Directory: `inst/themes/` (for example themes)
- File: `inst/themes/merton_purple.yaml` containing:
  - Banner section with Merton purple (#8b4789)
  - Legend styling
  - Map preferences
  - Control colors (year menu)
  - Complete example from outline specification
- File: `inst/themes/wandsworth_blue.yaml` containing:
  - Banner section with Wandsworth blue
  - Different styling choices
- File: `inst/themes/high_contrast.yaml` containing:
  - Accessibility-focused theme
  - High contrast colors
- Test each theme loads successfully with `load_theme()`
- Verify merged themes have all required fields (no missing values)

**Why**: Provides concrete examples for users, validates theme structure

**User will test:**
- Load each theme file: `theme <- load_theme("inst/themes/merton_purple.yaml")`
- Inspect theme structure, verify all sections present
- Check that merging with defaults works (missing fields filled in)
- No visual changes yet (theme not applied to maps)

---

### STEP 10: Integrate Theme System into create_pollution_map()

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Users can pass theme_file parameter to apply custom themes

**What must exist after this step:**
- Modified `create_pollution_map()` function signature:
  - Add parameter: `theme_file = NULL` (optional, character string)
  - Add to parameter documentation
- Early in create_pollution_map() execution:
  - Call `theme <- load_theme(theme_file)`
  - Extract values: `banner_bg <- theme$banner$background`
  - Override parameter defaults with theme values where applicable
- Modified banner/legend/control loading:
  - Pass theme-derived colors to `load_banner_css()`, `load_legend_css()`, `load_roller_menu_control()`
  - If theme$map$base_tiles specified, use that for base map
  - If theme$map$zoom_level specified, set initial zoom
- Ensure theme_file = NULL maintains current behavior (backward compatible)

**Why**: Activates theme system for user-facing functionality

**User will test:**
- Generate map without theme_file (default behavior, should be unchanged)
- Generate map with theme_file = "inst/themes/merton_purple.yaml"
  - Verify banner is Merton purple
  - Verify legend/controls styled accordingly
- Generate map with theme_file = "inst/themes/wandsworth_blue.yaml"
  - Verify different styling applied
- Test with malformed theme file, verify graceful fallback

---

### STEP 11: Add Tests and Update Documentation

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Testing suite and documentation complete, version incremented

**What must exist after this step:**
- File: `tests/testthat/test-css-extraction.R` containing:
  - Tests for `load_banner_css()` (placeholder replacement)
  - Tests for `load_legend_css()` (placeholder replacement)
  - Verify no sprintf with >3 positional params
- File: `tests/testthat/test-config.R` containing:
  - Tests for `load_colour_scale()` (YAML and fallback paths)
  - Tests for scale structure validation
- File: `tests/testthat/test-themes.R` containing:
  - Tests for `load_theme()` (loading, fallback, merging)
  - Tests for `get_default_theme()`
- Updated `CLAUDE.md`:
  - Document new inst/ structure (banner/, legend/, config/scales/, themes/)
  - Explain named placeholder pattern
  - Describe YAML color scales (if implemented)
  - Show theme file usage examples
- Updated version number in `R/quickmap.R` header
- Version history entry describing all changes
- Run all test scripts in tests/ directory successfully
- Archive version to versions/ subfolder

**Why**: Ensures changes are tested, documented, and properly versioned

**User will test:**
- Run testthat test suite: `devtools::test()` or `testthat::test_dir("tests/testthat")`
- Verify all tests pass
- Run existing test scripts (test-styling.R, test-parameters.R, test-export.R)
- Review documentation updates for clarity
- Confirm version increment is appropriate

---

## After Each Step

1. Agent commits changes with descriptive message
2. Agent pushes to `origin/claude/config-system-implementation-[session-id]`
3. Agent tells user: "Step X complete, pushed to origin/[branch name]"
4. User pulls code locally, tests functionality, reports results
5. If pass: user says "proceed to step X+1" or "next step"
6. If fail: user describes issue, agent fixes in same chat before proceeding

---

## Notes for Agent

**Key Principles:**
- Reuse existing code patterns wherever possible (especially roller menu as template)
- Keep changes small and focused on the step objective
- Stop after completing each step and wait for user feedback
- Base the code on working code at current HEAD
- Preserve all existing functionality - only change structure and add features
- Follow the roller menu control pattern for all CSS/JS loading

**Critical Patterns to Follow:**
- Named placeholders: Use `{{placeholder_name}}` in external files, `gsub()` for replacement
- Fallback approach: Always provide R list fallback for YAML loading
- Graceful degradation: Missing theme files, malformed YAML should warn but not error
- Testing: Each step must produce testable, demonstrable changes

**Dependencies to Remember:**
- Step 1-2 must complete before Step 3 (CSS extraction prerequisite)
- Step 4 must complete before Step 5 (loader before YAML files)
- Step 6 is a decision point (may skip Step 7)
- Step 8-9 must complete before Step 10 (theme infrastructure before integration)
- Step 11 is final cleanup (all functionality must be working)

**Existing Code References:**
- Roller menu pattern: `load_roller_menu_control()` at lines 973-1031 in R/quickmap.R
- Color utility: `lighten_color()` already exists, reuse for legend header colors
- Inline CSS: `apply_custom_layout_in_html()` at lines 1076-1349 in R/quickmap.R
- Color scales: Lines 524-774 in R/quickmap.R

**Testing Considerations:**
- Always test both interactive HTML and static image exports
- Test mobile responsive behavior (legend especially)
- Test fallback paths (missing YAML, missing theme files)
- Verify backward compatibility (existing code still works)

**Version Control:**
- Commit after each step with clear message
- Push to remote branch after each step
- Wait for user testing before proceeding
- Be prepared to fix issues before moving forward

---

## Success Metrics

**Phase 1 (Steps 1-3): CSS/JS Extraction**
- [ ] No sprintf with >3 positional parameters in codebase
- [ ] All styling files in inst/ subfolders (banner/, legend/, controls/)
- [ ] Named placeholders used consistently across all loaders
- [ ] Banner/legend/controls display identically to previous version

**Phase 2 (Steps 4-5): Configuration System**
- [ ] `load_colour_scale()` function works with both YAML and R list fallback
- [ ] 3 scales successfully converted to YAML
- [ ] Maps render identically with YAML-loaded scales

**Phase 3 (Step 6-7): Configuration Decision**
- [ ] User feedback collected on YAML approach
- [ ] Migration decision made and documented
- [ ] If full migration: all scales converted to YAML

**Phase 4 (Steps 8-10): Theme System**
- [ ] `load_theme()` and `get_default_theme()` functions operational
- [ ] 2-3 example themes created and tested
- [ ] `theme_file` parameter integrated into `create_pollution_map()`
- [ ] Maps styled correctly with custom themes

**Final (Step 11): Documentation & Testing**
- [ ] Test coverage for all new functions
- [ ] Documentation updated (CLAUDE.md)
- [ ] Version incremented and archived
- [ ] All existing tests still pass

---

## Estimated Timeline

- **Steps 0-3** (CSS/JS Extraction): 3-4 hours
- **Steps 4-5** (Config System): 2-3 hours
- **Step 6** (Decision): 0.5 hours (user evaluation)
- **Step 7** (Full Migration, conditional): 2-3 hours
- **Steps 8-10** (Theme System): 3-4 hours
- **Step 11** (Testing/Docs): 1-2 hours

**Total**: 12-17 hours depending on Step 6 decision and Step 7 execution

---

**End of Plan - Ready for Execution**

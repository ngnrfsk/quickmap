# Legend Refactoring Plan

## Context

Leaflet-based mapping software has been developed with an HTML banner and legend system. Currently, the banner and legend HTML/CSS code is embedded inline within R functions (`apply_custom_layout_in_html()` and `generate_legend_html()`), while the year control (roller menu) is already properly encapsulated in `inst/controls/` as separate HTML/CSS/JS files.

## Final Objective

Refactor the legend system to:
1. Encapsulate all banner and legend HTML5/CSS code into `inst/` subfolders (matching the roller menu pattern)
2. Optimize legend to show only the color range needed for actual data values
3. Redesign legend layout to display elements horizontally (inline with header text)
4. Replace disk-and-text format with text-on-colored-background format using high-contrast text colors

## Set out approach as follows: Take small, testable incremental steps towards goal

- Intermediate tasks will be executed one step at a time
- At the end of each Step, push code, asks user to pull/download locally to test code
- Wait for user feedback on Step
- Only proceed to next step when instructed to do so by user.

## Scope

**Must Include:** Work only on the code objectives stated in each Step, checking for errors or dependencies, but NO elaboration on instructions.

---

## STEPS

### STEP 0: Starting Point

- **Branch**: Create branch `claude/plan-legend-refactor-01QoKtrdVJRjTa456thkHXZh` from current commit `dfaee9f`
- **Base code**:
  - Banner/legend CSS in `R/quickmap.R` lines 1076-1349 within `apply_custom_layout_in_html()` function
  - Legend HTML generation in `R/quickmap.R` lines 868-933 within `generate_legend_html()` function
  - Reference pattern: Roller menu at `inst/controls/roller-menu.{html,css,js}` and `load_roller_menu_control()` function (lines 973-1031)

---

### STEP 1: Extract Banner CSS to inst/banner/

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Banner CSS code moved from inline in R file to separate reusable file

**What must exist after this step:**
- Directory: `inst/banner/`
- File: `inst/banner/banner.css` containing banner-related CSS with color placeholders (like `%s` in roller-menu.css)
- Modified `R/quickmap.R` with new helper function `load_banner_css()` that:
  - Reads `inst/banner/banner.css`
  - Accepts `banner_colour` parameter
  - Injects color using `sprintf()` (similar to `load_roller_menu_control()`)
  - Returns CSS string wrapped in `<style>` tags
- Modified `apply_custom_layout_in_html()` to call `load_banner_css()` instead of inline CSS
- Banner styling includes both interactive and image_mode variants (use conditional logic in R, not separate files)
- Image dimension scaling logic preserved in R function (gsub operations on returned CSS)

**User will test**: Map displays with banner exactly as before (same colors, fonts, spacing)

---

### STEP 2: Extract Legend CSS to inst/legend/

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Legend CSS code moved from inline in R file to separate reusable file

**What must exist after this step:**
- Directory: `inst/legend/`
- File: `inst/legend/legend.css` containing legend-related CSS with color placeholders
- Modified helper function (or new function `load_legend_css()`) that:
  - Reads `inst/legend/legend.css`
  - Accepts `banner_colour` parameter
  - Calculates legend header colors using `lighten_color()` function
  - Injects colors using `sprintf()`
  - Returns CSS string wrapped in `<style>` tags
- Modified `apply_custom_layout_in_html()` to call legend CSS loader instead of inline CSS
- Legend styling includes both interactive and image_mode variants
- Mobile responsive CSS (@media queries) preserved
- Image dimension scaling logic preserved in R function

**User will test**: Map displays with legend exactly as before (collapsible, mobile-responsive, correct colors)

---

### STEP 3: Extract Legend HTML Template to inst/legend/

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Legend HTML structure moved from R function to separate template file

**What must exist after this step:**
- File: `inst/legend/legend.html` containing HTML structure template with placeholders:
  - `%s` for legend title (scale$title)
  - `%s` for legend items HTML (generated dynamically)
  - `%s` for mobile collapse JavaScript (conditional)
- Modified `generate_legend_html()` function to:
  - Read template from `inst/legend/legend.html`
  - Generate legend items HTML (loop through colors/labels as currently done)
  - Use `sprintf()` to inject title, items, and script into template
  - Return complete HTML string
- Template preserves existing structure: header with toggle arrow, collapsible items container
- No changes to legend functionality or appearance

**User will test**: Legend displays and collapses exactly as before, shows correct colors and labels

---

### STEP 4: Add Dynamic Legend Trimming Based on Data Maximum

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Legend automatically shows only color ranges up to the highest value present in the data

**What must exist after this step:**
- New parameter added to `generate_legend_html()`: `data_max` (numeric value representing highest data value across all layers)
- New function `get_data_maximum()` that:
  - Accepts `measurement_layers` and `data_env` parameters
  - Iterates through all enabled layers (both temporal and static)
  - For pollution layers (dt_sites, bl_nodes): finds maximum pollutant value across all years
  - Returns single numeric value representing the maximum
- Modified `generate_legend_html()` logic to:
  - Compare `data_max` against scale thresholds
  - Filter `legend_scale$colours` and `legend_scale$labels` to include only entries up to and including the threshold that contains `data_max`
  - Always include at least 2 legend items (minimum and next threshold)
- Modified `create_pollution_map()` to:
  - Call `get_data_maximum()` after loading data but before generating maps
  - Pass `data_max` parameter to `generate_legend_html()`
- Logic handles edge cases: missing data, single threshold, data_max exceeds all thresholds

**Why**: Avoids showing irrelevant high-value color ranges that don't appear in the actual data (e.g., don't show red if max value is only yellow-range)

**User will test**:
- Load dataset with max NO2 = 35 μg/m³ and verify legend only shows ranges up to ~40 μg/m³, not the full WHO scale up to 200+
- Verify at least 2 legend items always display
- Test with multiple years to ensure maximum is found across all years

---

### STEP 5: Redesign Legend Layout - Horizontal Elements

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Legend items display inline to the right of the legend header text, instead of below it

**What must exist after this step:**
- Modified `inst/legend/legend.html` structure to:
  - Wrap header text and items in a flex container
  - Place header text (title + toggle arrow) as left element
  - Place legend items as right element
- Modified `inst/legend/legend.css` to:
  - `.legend-header`: change from vertical stacking to horizontal flex layout
  - `.legend-items`: remain as flex container but positioned inline (not below)
  - Adjust padding, gaps, and spacing for horizontal layout
  - Maintain collapsible behavior (items hide when collapsed, but collapse direction changes)
- Updated mobile responsive CSS to handle horizontal layout on small screens
- Toggle arrow behavior preserved (rotates to indicate collapsed/expanded state)

**What about dropdown behavior**: After implementation, present 3 options to user for collapsed state:
1. **Option A**: Items hidden, header shows "Click to expand legend" message
2. **Option B**: Items shrink to icons/color boxes only (no text), expand shows full text
3. **Option C**: First N items visible, expand shows all items
User will select preferred option for next step.

**User will test**:
- Legend displays horizontally across the bottom
- Header and items are side-by-side
- Toggle arrow still works to collapse/expand
- Review dropdown options and select preferred behavior

---

### STEP 6: Implement Selected Dropdown Behavior

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Collapsed legend state behaves according to user's selected option from Step 5

**What must change:**
- CSS and/or HTML modified based on user selection:
  - **If Option A**: Add "Click to expand" text that shows/hides, items completely hidden when collapsed
  - **If Option B**: Items visible as colored boxes without text labels when collapsed, text appears on expand
  - **If Option C**: CSS limits visible items to N (use overflow:hidden + max-width), expand shows all
- Smooth transitions preserved (CSS transitions for expand/collapse animation)
- Mobile behavior adapted if needed for selected option

**User will test**:
- Start with legend collapsed (on mobile or by default)
- Verify selected behavior works correctly
- Expand legend and verify full display
- Test on mobile screen widths (320px, 480px, 768px)

---

### STEP 7: Replace Disk Format with Text-on-Colored-Background Format

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Legend items change from [colored disk + text] to [text with colored background]

**What must exist after this step:**
- New utility function `get_contrast_text_color()` that:
  - Accepts hex color as input
  - Calculates luminance using standard formula: `(0.299*R + 0.587*G + 0.114*B) / 255`
  - Returns `"white"` for dark backgrounds (luminance < 0.5)
  - Returns `"black"` for light backgrounds (luminance >= 0.5)
- Modified legend item generation in `generate_legend_html()` to:
  - Remove `<div class="legend-symbol">` element
  - Create `<span>` with inline styles: `background: [legend-color]; color: [contrast-color]; padding: 0.25rem 0.625rem; border-radius: 0.25rem;`
  - Text content is the label (e.g., "0-10 μg/m³")
- Modified `inst/legend/legend.css` to:
  - Remove `.legend-symbol` styles (no longer used)
  - Update `.legend-item` styles for new format (may need adjusted gaps/alignment)
  - Ensure text is readable (adequate padding, border-radius for pill shape)
- Maintain mobile responsive sizing

**User will test**:
- Legend displays text labels with colored backgrounds
- Text color automatically adjusts for readability (white on dark blue, black on yellow, etc.)
- All legend items are readable and visually distinct
- Works on mobile screens

---

### STEP 8: Final Testing and Cleanup

**Scope**: Work only on the code objectives stated in this Step, checking for errors or dependencies, but NO elaboration on instructions.

**Outcome**: Code cleanup, version increment, documentation update

**What must exist after this step:**
- All old commented-out code removed from `R/quickmap.R`
- Version number incremented to `0.9.1` in file header
- Version history entry added describing legend refactoring
- Updated `CLAUDE.md` to reflect new `inst/legend/` and `inst/banner/` structure
- Updated `dev/PROJECT_STATUS.md` to mark legend refactoring as completed
- File `versions/quickmap_0_9_1.R` created (archived copy)
- All test scripts in `tests/` directory run successfully
- Verification that maps generate correctly with all refactored components

**User will test**:
- Run test scripts to verify functionality
- Generate maps with different color scales, data files, and parameters
- Verify HTML and JPG exports work correctly
- Check that legend trimming works with different datasets

---

## After Each Step

1. Agent commits changes with descriptive message
2. Agent pushes to `origin/claude/plan-legend-refactor-01QoKtrdVJRjTa456thkHXZh`
3. Agent tells user: "Step X complete, pushed to origin/claude/plan-legend-refactor-01QoKtrdVJRjTa456thkHXZh"
4. User pulls code locally, tests functionality, reports results
5. If pass: user says "proceed to step X+1" or "next step"
6. If fail: user describes issue, agent fixes in same chat before proceeding

---

## Notes for Agent

- Reuse existing code patterns wherever possible (especially `load_roller_menu_control()` as template for banner/legend loaders)
- Keep changes small and focused on the step objective
- Stop after completing each step and wait for user feedback
- Base the code on working code at commit `dfaee9f` (current stable v0.9.0.2)
- Preserve all existing functionality - only change structure and legend appearance
- Do not modify roller menu control code (already properly encapsulated)
- Pay attention to sprintf placeholder order when injecting multiple colors
- Test mobile responsive behavior at each step (especially Steps 5-7)
- The `lighten_color()` utility function already exists and works correctly - reuse it
- Image dimension scaling uses geometric mean calculation - preserve this logic
- Legend colors are derived from banner_colour using `lighten_color()` - maintain this pattern

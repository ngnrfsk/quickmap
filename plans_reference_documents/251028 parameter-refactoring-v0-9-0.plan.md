<!-- 5f25ec1a-4052-455c-9760-6f58d2c845bb 4a3ee025-a772-4d51-a53e-ae951cb509f5 -->
# Parameter Refactoring to v0.9.0

## Objective

Simplify `create_pollution_map()` interface from 23 to 17 core parameters, following OpenAir R package design patterns. Focus on describing WHAT user wants (not HOW it's implemented), with sensible defaults and clear naming.

## Target: Version 0.9.0

**Current:** 0.8.11 (23 parameters)

**Target:** 0.9.0 (17 parameters with clearer intent-based design)

---

## STEP 1: Remove Dead Code (5 min) [USER CAN CODE]

**Action:** Delete unused `border_width` parameter entirely

**Files to modify:**

- `quickmap.R` line 2177: Remove from function signature
- `quickmap.R` lines 2480, 2508: Delete commented-out code references

**Test:** Source file, ensure no errors

---

## STEP 2: Fix Redundant Banner Color (10 min) [USER CAN CODE]

**Action:** Remove `banner_color` (unused), keep `border_color` which actually controls banner

**Current behavior:**

- `banner_color` is defined but never used
- `border_color` controls both banner background AND borders (lines 2393, 2448)

**Files to modify:**

- `quickmap.R` line 2175: Remove `banner_color` from signature
- `quickmap.R` line 1218: Remove reference (uses `border_color` anyway)

**Test:** Source file, create simple map, verify banner color works

---

## STEP 3: Simple Renames for Clarity (30 min) [USER CAN CODE]

**Action:** Rename 4 parameters with find/replace

| Old Name | New Name | Reason |
|----------|----------|--------|
| `scale_to_use` | `color_scale` | Clearer intent |
| `years_to_plot` | `years` | Shorter, context is clear |
| `vignette_overlay_on` | `vignette` | Shorter, "_on" redundant |
| `csv_data_file` | `diffusion_tube_file` | Self-documenting |
| `oa_data_file` | `sensor_file` | Self-documenting |

**Implementation:**

- Use find/replace in `quickmap.R` for each rename
- Update function signature
- Update all internal references
- Update roxygen2 documentation

**Test:** Source file, run existing test script with new param names

---

## STEP 4: Document Current State (15 min) [LLM TASK]

**Action:** Update PARAMETER_REFERENCE.md with changes from Steps 1-3

**Content to add:**

- Note parameters removed (border_width, banner_color)
- Update all renamed parameters
- Add version history note about 0.9.0 changes

---

## STEP 5: Merge Title Parameters (45 min) [LLM TASK]

**Current:** Two separate parameters

```r
html_page_title = "Air pollution map"  # Browser tab
banner_text = "Air Quality Map"        # Banner on map
```

**Target:** Single parameter

```r
title = "Air Quality Map"  # Used for both contexts
```

**Changes required:**

1. Function signature (lines 2165-2166): Replace both with single `title` param
2. Browser title usage (lines 2384, 2439): Use `title` for `saveWidget()`
3. Banner text usage (lines 2392, 2447): Use `title` for banner display
4. Update roxygen2 docs

**Default value:** `"Air Quality Map"`

**Test:** Generate map with custom title, verify appears in both browser tab and banner

---

## STEP 6: Boolean to Multi-Value - Legend (30 min) [LLM TASK]

**Current:** Boolean toggle

```r
show_legend = FALSE  # TRUE/FALSE
```

**Target:** Multi-value following leaflet conventions

```r
legend = FALSE  # FALSE | TRUE | "topright" | "bottomleft" | "topleft" | "bottomright"
```

**Behavior:**

- `FALSE` → no legend
- `TRUE` → legend at default position (topright)
- Position string → legend at that position

**Changes required:**

1. Function signature (line 2173): Rename and update default
2. Legend control logic (lines 1812-1838): 

   - Check `if (legend != FALSE)` instead of `if (show_legend)`
   - If string, use as position; if TRUE use "topright"

3. Static map handling (line 2369): Set to FALSE
4. HTML map handling (line 2424): Pass through

**Test:** Create maps with `legend = FALSE`, `legend = TRUE`, `legend = "bottomleft"`

---

## STEP 7: Boolean to Multi-Value - Title Display (1 hour) [LLM TASK]

**Current:** Multiple boolean controls

```r
show_banner = FALSE  # HTML banner above map
show_title = FALSE   # Leaflet overlay on map
title_prefix = ""    # Text for title
```

**Target:** Single multi-value parameter

```r
title_position = "none"  # "none" | "overlay" | "banner"
title = "Air Quality Map"  # Text content (from Step 5)
```

**Behavior:**

- `"none"` → no title displayed
- `"overlay"` → Leaflet control inside map (current `show_title = TRUE`)
- `"banner"` → HTML div above map (current `show_banner = TRUE`)

**Changes required:**

1. Function signature: Replace `show_banner`, `show_title`, `title_prefix` with `title_position`
2. Title overlay logic (lines 1841-1845):

   - Check `if (title_position == "overlay")`
   - Use `title` as text content

3. Banner logic (lines 2392, 2447):

   - Check `if (title_position == "banner")`
   - Pass `title` as banner text

4. Static vs HTML handling (lines 2368, 2423): Set appropriately
5. Remove all `title_prefix` references

**Test:** Create maps with each position option, verify display

---

## STEP 8: Update Documentation - Breaking Changes (30 min) [LLM TASK]

**Action:** Document all breaking changes in quickmap.R header

**Add to version history:**

```r
# v0.9.0: Parameter refactoring following OpenAir design patterns
#         BREAKING CHANGES (see migration guide below):
#         - Removed: border_width (unused), banner_color (redundant)
#         - Renamed: scale_to_use → color_scale, years_to_plot → years,
#                   vignette_overlay_on → vignette, csv_data_file → diffusion_tube_file,
#                   oa_data_file → sensor_file
#         - Merged: html_page_title + banner_text → title
#         - Replaced: show_legend → legend (multi-value), show_banner + show_title + 
#                    title_prefix → title_position (multi-value)
```

**Add migration guide section:**

```r
# Migration Guide v0.8.x → v0.9.0:
#   OLD: scale_to_use = "who_no2"
#   NEW: color_scale = "who_no2"
#
#   OLD: show_legend = TRUE
#   NEW: legend = TRUE  (or legend = "bottomleft" for custom position)
#
#   OLD: show_banner = TRUE, banner_text = "My Title"
#   NEW: title_position = "banner", title = "My Title"
#
#   OLD: show_title = TRUE, title_prefix = "My Title"
#   NEW: title_position = "overlay", title = "My Title"
```

**Update roxygen2 documentation** with all parameter changes

---

## STEP 9: Expand - Boundary Labels Multi-Value (45 min) [LLM TASK - EXPANSION]

**Current:** Boolean only

```r
show_boundary_labels = FALSE
```

**Target:** Multi-value for flexibility

```r
boundary_labels = FALSE  # FALSE | TRUE | "always" | "hover"
```

**Behavior:**

- `FALSE` → no labels
- `TRUE` or `"always"` → always-visible labels (current behavior)
- `"hover"` → labels appear on hover only

**Changes required:**

1. Function signature: Rename parameter
2. Label logic (lines 1720-1738):

   - Check `if (boundary_labels != FALSE)`
   - Set `noHide` based on mode: TRUE for "always"/TRUE, FALSE for "hover"

3. Update callers (lines 2372, 2427)

**Test:** Create maps with each mode, verify label behavior

---

## STEP 10: Expand - Shorten Remaining Boolean (15 min) [USER CAN CODE - EXPANSION]

**Action:** Remove "show_" prefix from last remaining parameter

**Rename:**

- `show_marker_labels` → `marker_labels` (more concise, consistent with others)

**Implementation:**

- Find/replace in `quickmap.R`
- Update documentation

**Note:** Keep the multi-value behavior (FALSE | TRUE | "values_on" | "labels" | "labels_on")

Just add `"off"` as explicit alias for FALSE for consistency

**Test:** Create map with marker labels, verify works

---

## STEP 11: Final Documentation Update (20 min) [LLM TASK]

**Actions:**

1. Update PARAMETER_REFERENCE.md completely with all v0.9.0 changes
2. Create comparison table: v0.8.11 vs v0.9.0 parameter list
3. Update style_guide.md with examples from this refactoring
4. Update version number in quickmap.R to 0.9.0

**Test:** Review all documentation for consistency

---

## STEP 12: Create Version Backup (5 min) [USER TASK]

**Actions:**

1. Update version number to 0.9.0 in line 2
2. Copy to `versions/quickmap_0_9_0.R`
3. Git commit as "Refactor parameters to v0.9.0 - OpenAir design patterns"

---

## Summary of Changes

**Removed (2):** `border_width`, `banner_color`

**Renamed (7):**

- `scale_to_use` → `color_scale`
- `years_to_plot` → `years`
- `vignette_overlay_on` → `vignette`
- `csv_data_file` → `diffusion_tube_file`
- `oa_data_file` → `sensor_file`
- `show_legend` → `legend` (enhanced to multi-value)
- `show_boundary_labels` → `boundary_labels` (enhanced to multi-value)
- `show_marker_labels` → `marker_labels`

**Merged (2→1):** `html_page_title` + `banner_text` → `title`

**Replaced (3→1):** `show_banner` + `show_title` + `title_prefix` → `title_position` (multi-value)

**Final count:** 17 parameters (down from 23)

**Key improvement:** Parameters now describe user intent (WHAT) not implementation (HOW)

---

## Testing Strategy

After each step:

1. Source `quickmap.R` - verify no syntax errors
2. Run relevant test from `tests/` folder
3. Create simple test map to verify functionality
4. If step fails, fix before proceeding

Create one comprehensive test at end that exercises all new parameter options.

### To-dos

- [ ] Remove unused border_width parameter (5 min, USER can code)
- [ ] Remove redundant banner_color parameter (10 min, USER can code)
- [ ] Rename 5 parameters for clarity using find/replace (30 min, USER can code)
- [ ] Update PARAMETER_REFERENCE.md with Steps 1-3 changes (15 min)
- [ ] Merge html_page_title and banner_text into single title parameter (45 min)
- [ ] Convert show_legend boolean to legend multi-value with position support (30 min)
- [ ] Replace show_banner/show_title/title_prefix with title_position multi-value (1 hour)
- [ ] Document breaking changes in quickmap.R header with migration guide (30 min)
- [ ] EXPANSION: Convert show_boundary_labels to boundary_labels multi-value with hover option (45 min)
- [ ] EXPANSION: Rename show_marker_labels to marker_labels (15 min, USER can code)
- [ ] Complete documentation update: PARAMETER_REFERENCE.md, style_guide.md, comparison table (20 min)
- [ ] Update to v0.9.0, create version backup, git commit (5 min, USER task)


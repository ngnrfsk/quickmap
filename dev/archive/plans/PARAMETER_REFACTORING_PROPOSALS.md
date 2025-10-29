# Parameter Refactoring Proposals for `create_pollution_map()`

Based on analysis of the current 23 parameters in `create_pollution_map()`, these proposals aim to simplify the function interface while maintaining all functionality and following R best practices.

## Proposal 1: Remove Unused/Broken Parameters

### 1.1 Delete `border_width`
- **Current Status:** Defined but completely unused (only appears in commented-out code)
- **Action:** Remove from function signature
- **Impact:** None - no functionality lost
- **Lines affected:** 2177, 2480, 2508

### 1.2 Delete `banner_color`
- **Current Status:** Defined but never actually used; `border_color` controls banner appearance
- **Action:** Remove `banner_color` from function signature
- **Impact:** None - `border_color` already does this job (lines 2393, 2448)
- **Alternative:** Keep `banner_color` and delete `border_color` if you prefer the name
- **Lines affected:** 2175, 1218

---

## Proposal 2: Merge Related Text Parameters

### 2.1 Merge `html_page_title` and `banner_text`
**Current:**
```r
html_page_title = "Air pollution map"  # Browser tab title
banner_text = "Air Quality Map"       # Banner text on map
```

**Proposed:**
```r
title = "Air Quality Map"  # Used for both browser tab and banner
```

**Benefits:**
- Reduces confusion about which title appears where
- Ensures consistency between page title and banner
- Reduces parameter count by 1
- R precedent: `plot()` uses `main` for single title

**Implementation Details:**
- Lines 2165-2166 → single `title` parameter
- Lines 2384, 2439: use `title` for `saveWidget()`
- Lines 2392, 2447: use `title` for banner text

### 2.2 Alternative: Use `title` with Optional `subtitle`
```r
title = "Air Quality Map"        # Browser page title
subtitle = NULL                   # Banner text (uses title if NULL)
```
- More flexible but adds complexity
- Use if users need different text in different places

---

## Proposal 3: Simplify Boolean Toggles with Config List

### 3.1 Group Display Toggles into Single List
**Current:** 4 separate boolean parameters
```r
show_banner = FALSE
show_legend = FALSE
show_title = FALSE
show_boundary_labels = FALSE
```

**Proposed:** Single `display` list parameter
```r
display = list(
  banner = FALSE,
  legend = FALSE,
  title = FALSE,
  boundary_labels = FALSE
)
```

**Benefits:**
- Clearer grouping of related options
- Easier to set multiple at once
- Follows R precedent: `par()` for graphics parameters
- Reduces top-level parameter count by 3

**Implementation:**
- Update lines 2172-2178
- Access as `display$banner` instead of `show_banner`
- Add validation to ensure all list elements are logical

### 3.2 Alternative: Keep Separate but Rename (Simpler Migration)
Remove "show_" prefix for brevity:
```r
banner = FALSE                    # was: show_banner
legend = FALSE                    # was: show_legend
title_overlay = FALSE             # was: show_title (renamed to avoid conflict)
boundary_labels = FALSE           # was: show_boundary_labels
```

**Benefits:**
- Shorter, still clear
- Easier migration path (simpler find/replace)
- No list structure to validate

---

## Proposal 4: Consolidate Color Parameters

### 4.1 Single Color Configuration List
**Current:** Two redundant parameters
```r
banner_color = borough_palettes$merton$purple
border_color = borough_palettes$merton$green  # Actually controls banner
```

**Proposed:**
```r
colors = list(
  banner = borough_palettes$merton$purple,
  vignette = "grey"  # Currently hardcoded at line 395
)
```

**Benefits:**
- All color configuration in one place
- Eliminates confusion about which parameter does what
- Allows future expansion (boundary colors, label colors, etc.)
- Makes vignette color customizable

### 4.2 Simpler Alternative: Single Parameter
```r
banner_color = borough_palettes$merton$purple
```
- Delete `border_color` completely
- Use `banner_color` for all UI chrome
- Simplest fix for the current confusion

---

## Proposal 5: Rename for Clarity and Consistency

### 5.1 File Parameters - Consistent Naming
**Current:** Mixed naming styles
```r
csv_data_file = "none"
oa_data_file = "none"
school_file = "none"
```

**Proposed Option A:** Descriptive names
```r
diffusion_tube_file = "none"  # Clear what csv_data means
sensor_file = "none"           # Clear what oa_data means
school_file = "none"           # Unchanged
```

**Proposed Option B:** Group in list
```r
data_files = list(
  diffusion_tubes = "none",
  sensors = "none",
  schools = "none"
)
```

**Benefits:**
- Option A: Self-documenting parameter names
- Option B: Clearer grouping, easier to pass around
- Reduces confusion about what "csv_data" and "oa_data" mean

### 5.2 Output Parameters - Group Related Items
**Current:** Multiple related parameters scattered
```r
output_file = "pollution_map.html"
image_export = FALSE
map_width_px = 1920
map_height_px = 1080
html_page_title = "Air pollution map"
```

**Proposed:**
```r
output_file = "pollution_map.html"
title = "Air Quality Map"
export = list(
  images = FALSE,
  width = 1920,
  height = 1080
)
```

**Benefits:**
- Clear that width/height only matter for image export
- Reduces top-level parameter count by 2
- Makes relationship between parameters explicit

### 5.3 Rename Ambiguous Parameters
**Current → Proposed:**
- `scale_to_use` → `color_scale` (clearer purpose)
- `years_to_plot` → `years` (shorter, context makes it clear)
- `vignette_overlay_on` → `vignette` (shorter, "_on" is redundant)
- `show_marker_labels` → `marker_labels` (consistent with other removals of "show_")

**Benefits:**
- Shorter, more idiomatic R
- Less typing without losing clarity
- More consistent naming pattern

---

## Proposal 6: Comprehensive Reorganization

### Full Parameter List with All Improvements
```r
create_pollution_map(
  # Data sources (required)
  boroughs,

  # Data files (optional)
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",

  # Data selection
  pollutant = "no2",
  years = NULL,

  # Output
  output_file = "pollution_map.html",
  title = "Air Quality Map",

  # Visual style
  color_scale = "who_no2",
  vignette = TRUE,
  banner_color = borough_palettes$merton$purple,

  # Display options
  banner = FALSE,
  legend = FALSE,
  title_overlay = FALSE,
  boundary_labels = FALSE,
  marker_labels = FALSE,  # FALSE | TRUE | "values_on" | "labels" | "labels_on"

  # Image export
  export_images = FALSE,
  image_width = 1920,
  image_height = 1080
)
```

**Summary:**
- 20 parameters (down from 23)
- Removed: `border_width`, `border_color`, `html_page_title`, merged into `title`
- Renamed: 8 parameters for clarity
- All functionality preserved

---

## Proposal 7: Two-Tier Simplification (RECOMMENDED)

### Approach: Simple Interface + Advanced Options

**Tier 1: Essential Parameters (9 core parameters)**
```r
create_pollution_map(
  boroughs,                       # Required
  diffusion_tube_file = "none",
  sensor_file = "none",
  school_file = "none",
  pollutant = "no2",
  years = NULL,
  output_file = "pollution_map.html",
  color_scale = "who_no2",
  vignette = TRUE
)
```

**Tier 2: Advanced Customization via `options` List**
```r
options = list(
  # Display toggles
  banner = FALSE,
  legend = FALSE,
  title_overlay = FALSE,
  boundary_labels = FALSE,
  marker_labels = FALSE,

  # Text content
  title = "Air Quality Map",

  # Colors
  banner_color = borough_palettes$merton$purple,

  # Image export
  export_images = FALSE,
  image_width = 1920,
  image_height = 1080
)
```

**Full Call Example:**
```r
create_pollution_map(
  boroughs = "Merton",
  diffusion_tube_file = "merton_dt.csv",
  sensor_file = "merton_bl.Rdata",
  options = list(
    banner = TRUE,
    title = "Merton Air Quality 2024",
    export_images = TRUE,
    image_width = 1200,
    image_height = 1200
  )
)
```

**Benefits:**
- Simple interface for 90% of use cases (9 parameters)
- All advanced features still accessible
- Follows R best practice (e.g., `plot()`, `lm()` with control arguments)
- Easy to add new options without cluttering main signature
- Backward compatible via default options list

**Implementation Notes:**
- Default options defined at function level
- User options merged with defaults using `modifyList()`
- Extract options like: `show_banner <- options$banner`

---

## Summary by Implementation Difficulty

### Quick Wins (Low Risk, High Value)
1. **Delete `border_width`** - unused parameter (5 min)
2. **Delete `banner_color`** - redundant with `border_color` (5 min)
3. **Rename `scale_to_use` → `color_scale`** - simple find/replace (10 min)
4. **Rename `years_to_plot` → `years`** - simple find/replace (10 min)
5. **Rename `vignette_overlay_on` → `vignette`** - simple find/replace (10 min)

### Medium Effort (Moderate Risk, Good Value)
6. **Merge `html_page_title` + `banner_text` → `title`** (30 min)
7. **Rename file parameters** for consistency (30 min)
8. **Shorten boolean names** (remove "show_" prefix) (45 min)
9. **Group image export parameters** into list (1 hour)

### Major Refactoring (Higher Risk, Long-term Value)
10. **Two-tier system** (main params + options list) (2-3 hours)
11. **Group display toggles** into single list (1.5 hours)
12. **Consolidate colors** into config object (1 hour)

---

## Recommended Implementation Strategy

### Phase 1: Immediate Improvements (1 hour)
- Delete `border_width` and `banner_color`
- Rename ambiguous parameters (`scale_to_use`, `years_to_plot`, `vignette_overlay_on`)
- Update documentation

### Phase 2: Consolidation (2-3 hours)
- Merge `html_page_title` and `banner_text` → `title`
- Rename file parameters for consistency
- Shorten boolean parameter names

### Phase 3: Advanced (Optional, 3-4 hours)
- Implement two-tier system with `options` list
- Group related parameters (display, colors, export)
- Add validation and helpful error messages

---

## Breaking Changes & Migration

### Deprecation Strategy
For any renamed/removed parameters:

1. **Keep old parameter names temporarily** with deprecation warnings
2. **Map old → new internally** for backward compatibility
3. **Update all examples and documentation**
4. **Provide migration guide** in NEWS/changelog

Example implementation:
```r
if (!missing(html_page_title)) {
  warning("html_page_title is deprecated; use 'title' instead", call. = FALSE)
  title <- html_page_title
}
```

### Version Recommendation
- Phase 1 changes: Version 0.8.12 (patch - internal cleanup)
- Phase 2 changes: Version 0.9.0 (minor - renamed parameters with deprecation)
- Phase 3 changes: Version 1.0.0 (major - new options system)

---

## Questions for User Decision

1. **Which phase do you want to implement?**
   - a) Phase 1 only (quick wins, 1 hour)
   - b) Phases 1+2 (comprehensive cleanup, 3-4 hours)
   - c) All phases (full refactor, 6-8 hours)

2. **Parameter naming preference for data files?**
   - a) Keep current names (`csv_data_file`, `oa_data_file`)
   - b) Descriptive names (`diffusion_tube_file`, `sensor_file`)
   - c) Group in list (`data_files = list(...)`)

3. **Boolean naming preference?**
   - a) Keep "show_" prefix (`show_banner`, `show_legend`)
   - b) Remove prefix (`banner`, `legend`, `title_overlay`)
   - c) Group in list (`display = list(banner = FALSE, ...)`)

4. **Color parameters?**
   - a) Keep `border_color`, delete `banner_color`
   - b) Keep `banner_color`, delete `border_color`
   - c) Single color list (`colors = list(banner = ..., vignette = ...)`)

5. **Title parameters?**
   - a) Merge to single `title`
   - b) Keep separate with `title` + `subtitle`
   - c) Keep current separate names


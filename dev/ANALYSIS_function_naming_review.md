# Function Naming Review - Single-Use Helper Functions

**Date:** 2025-11-26
**Version:** QuickMap v0.9.2
**Purpose:** Review function names for clarity, given they exist primarily to document code flow

## Naming Analysis

Since these functions exist as inline documentation (single-use helpers), their names should precisely describe what they do. Let's review each:

---

### 1. `save_styled_map()` ❌ MISLEADING

**Current name:** `save_styled_map()`

**What it actually does:**
1. Saves HTML widget
2. **Conditionally** applies styling (only if `styling_type == "html"`)
3. Cleans up temp folders

**Problem:** Name implies the map is ALWAYS styled, but styling is optional based on `styling_type` parameter.

**What it should be called:**
- **`save_map_html()`** - Simple, describes primary action
- **`save_html_and_style()`** - Indicates save + optional styling
- **`save_and_postprocess_html()`** - More technical but accurate

**Recommendation:** `save_html_and_style()` or `save_map_html()`

**Severity:** Minor - function works correctly, but name suggests styling always happens

---

### 2. `build_static_map_for_year()` ⚠️ PARTIALLY UNCLEAR

**Current name:** `build_static_map_for_year()`

**What it actually does:**
```r
template |>
  generate_map_layers(measurement_layers, year, ...) |>
  generate_map_layers(measurement_layers, "static_only", ...)
```

Adds temporal layers for the year, THEN adds static overlay layers.

**Problem:** "static map" could mean:
1. A map for static export (JPG) - TRUE, this is for image export
2. A map with only static layers - FALSE, includes temporal layers
3. A non-interactive map - Not really, it's still a leaflet object

**What it should be called:**
- **`add_year_and_static_layers()`** - Describes the two-step process
- **`build_map_layers_for_year()`** - Generic, focuses on "build for this year"
- **`add_temporal_and_static_layers()`** - More semantic

**Recommendation:** `add_year_and_static_layers()`

**Severity:** Minor - "static" is ambiguous but context makes it clear

---

### 3. `parse_export_params()` ✅ CLEAR

**Current name:** `parse_export_params()`

**What it does:**
- Normalizes `export_image` parameter (NULL / TRUE / numeric vector)
- Returns list with enabled/width/height

**Analysis:** Name perfectly describes the action. "Parse" = interpret input, "export params" = parameters for image export.

**Recommendation:** Keep as-is

---

### 4. `apply_custom_layout_in_html()` ⚠️ VAGUE

**Current name:** `apply_custom_layout_in_html()`

**What it actually does:**
1. Reads HTML file
2. Injects viewport meta tag
3. Injects banner CSS + legend CSS
4. Adds banner div
5. Adds year control menu
6. Adds legend
7. Writes modified HTML

**Problem:** "custom layout" is vague. What layout? The function actually **injects banner/legend/controls into HTML**.

**What it should be called:**
- **`inject_banner_legend_controls()`** - Specific about what's added
- **`postprocess_html_with_ui()`** - Indicates UI injection
- **`add_ui_components_to_html()`** - Clear about adding UI
- **`inject_ui_into_html()`** - Concise and specific

**Recommendation:** `inject_banner_legend_controls()`

**Severity:** Moderate - "custom layout" doesn't communicate what the function does

---

### 5. `load_roller_menu_control()` ✅ CLEAR

**Current name:** `load_roller_menu_control()`

**What it does:**
- Loads roller menu HTML/CSS/JS templates
- Applies theming
- Returns combined HTML block

**Analysis:** Name is clear. "Load" = read and prepare, "roller menu control" = specific UI component.

**Recommendation:** Keep as-is

**Alternative:** `build_roller_menu_control()` (since it's not just loading, but also theming and combining)

---

### 6. `load_layer_cache_js()` ✅ CLEAR

**Current name:** `load_layer_cache_js()`

**What it does:**
- Loads layer-cache.js template file
- Returns JavaScript content

**Analysis:** Perfectly clear. "Load" + specific filename reference.

**Recommendation:** Keep as-is

---

### 7. `load_banner_css()` ⚠️ INCOMPLETE

**Current name:** `load_banner_css()`

**What it actually does:**
1. Loads banner CSS template
2. **Applies color theming** (banner_colour)
3. **Conditionally loads mobile CSS**
4. Returns styled CSS block wrapped in `<style>` tags

**Problem:** "load" suggests just reading a file, but function does template replacement and color theming.

**What it should be called:**
- **`build_banner_css()`** - Indicates construction, not just loading
- **`generate_banner_css()`** - Emphasizes creation from template
- **`render_banner_css()`** - Template + data → output

**Recommendation:** `build_banner_css()`

**Severity:** Minor - "load" is common in codebase but technically inaccurate

---

### 8. `load_legend_css()` ⚠️ INCOMPLETE

**Current name:** `load_legend_css()`

**What it actually does:**
1. Loads legend CSS template
2. **Calculates derived colors** (lighten_color)
3. **Conditionally loads mobile CSS**
4. Applies template replacements
5. Returns styled CSS block wrapped in `<style>` tags

**Problem:** Same as `load_banner_css()` - does more than "load".

**What it should be called:**
- **`build_legend_css()`** - Parallel with banner
- **`generate_legend_css()`**
- **`render_legend_css()`**

**Recommendation:** `build_legend_css()`

**Severity:** Minor - consistency issue with "load" vs actual behavior

---

## Summary Table

| Current Name | Clarity | Suggested Name | Reason |
|-------------|---------|----------------|--------|
| `save_styled_map()` | ❌ Misleading | `save_html_and_style()` | Styling is conditional, not guaranteed |
| `build_static_map_for_year()` | ⚠️ Ambiguous | `add_year_and_static_layers()` | "static map" is unclear |
| `parse_export_params()` | ✅ Clear | Keep as-is | Name matches behavior perfectly |
| `apply_custom_layout_in_html()` | ⚠️ Vague | `inject_banner_legend_controls()` | "custom layout" too generic |
| `load_roller_menu_control()` | ✅ Clear | Keep as-is (or `build_*`) | Clear purpose |
| `load_layer_cache_js()` | ✅ Clear | Keep as-is | Clear and specific |
| `load_banner_css()` | ⚠️ Incomplete | `build_banner_css()` | Does theming, not just loading |
| `load_legend_css()` | ⚠️ Incomplete | `build_legend_css()` | Does theming, not just loading |

---

## Recommended Changes (Priority Order)

### High Priority

**1. `apply_custom_layout_in_html()` → `inject_banner_legend_controls()`**

Most important change - current name doesn't communicate what the function does.

```r
# Before
apply_custom_layout_in_html(html_file, title, ...)

# After
inject_banner_legend_controls(html_file, title, ...)
```

**Impact:** 1 function definition + 1 call site

---

### Medium Priority

**2. `save_styled_map()` → `save_html_and_style()`**

Current name implies styling always happens, but it's conditional.

```r
# Before
save_styled_map(map, html_file, title, styling_type, ...)

# After
save_html_and_style(map, html_file, title, styling_type, ...)
```

**Impact:** 1 function definition + 1 call site

---

**3. `build_static_map_for_year()` → `add_year_and_static_layers()`**

"static map" is ambiguous - clarify it's about layer addition.

```r
# Before
static_map <- build_static_map_for_year(template, yr, ...)

# After
static_map <- add_year_and_static_layers(template, yr, ...)
```

**Impact:** 1 function definition + 1 call site (inside loop)

---

### Low Priority (Consistency)

**4. `load_banner_css()` → `build_banner_css()`**
**5. `load_legend_css()` → `build_legend_css()`**

Changes "load" to "build" to reflect template processing and theming.

```r
# Before
banner_css <- load_banner_css(banner_colour, image_mode)
legend_css <- load_legend_css(banner_colour, image_mode)

# After
banner_css <- build_banner_css(banner_colour, image_mode)
legend_css <- build_legend_css(banner_colour, image_mode)
```

**Impact:** 2 function definitions + 2 call sites

**Alternative:** Keep as-is since "load" is an established pattern in the codebase, and the functions do primarily load templates (theming is secondary).

---

## Pattern Analysis

### Current naming patterns in codebase:

- **`load_*`**: Used for reading YAML configs, templates, and data files
- **`generate_*`**: Used for creating map layers, legends, HTML
- **`build_*`**: Used sparingly (only `build_static_map_for_year`)
- **`create_*`**: Used for high-level constructors (create_pollution_map, create_generic_icons)
- **`apply_*`**: Used for modifications (apply_custom_layout_in_html, apply_template_replacements)

### Recommendation: Use `build_*` for template processing

Functions that load templates AND apply transformations should use `build_*`:
- `build_banner_css()` - loads + themes
- `build_legend_css()` - loads + themes
- `build_roller_menu_control()` - loads + themes (optional rename)

Functions that just load should keep `load_*`:
- `load_layer_cache_js()` - just loads file
- `load_data_source_config()` - just loads YAML

---

## Implementation Impact

### Breaking Changes: **NONE**

All functions are internal (`@keywords internal` or not exported). Renaming has zero impact on package users.

### Code Changes Required:

| Function Rename | Definition | Call Sites |
|----------------|------------|------------|
| `apply_custom_layout_in_html` → `inject_banner_legend_controls` | Line 1203 | Line 1054 |
| `save_styled_map` → `save_html_and_style` | Line 1040 | Line 1023 |
| `build_static_map_for_year` → `add_year_and_static_layers` | Line 1003 | Line 2070 |
| `load_banner_css` → `build_banner_css` | Line 961 | Line 1225 |
| `load_legend_css` → `build_legend_css` | Line 979 | Line 1227 |

**Total:** 5 function definitions + 5 call sites = **10 line changes**

---

## Conclusion

**Primary Goal:** Since these functions exist to document code flow, names should be:
1. **Specific** about what they do
2. **Accurate** (not misleading about conditional behavior)
3. **Consistent** with codebase patterns

**Top 3 changes for clarity:**
1. ✅ `apply_custom_layout_in_html()` → `inject_banner_legend_controls()` (HIGH)
2. ✅ `save_styled_map()` → `save_html_and_style()` (MEDIUM)
3. ✅ `build_static_map_for_year()` → `add_year_and_static_layers()` (MEDIUM)

**Optional consistency changes:**
4. `load_banner_css()` → `build_banner_css()` (LOW)
5. `load_legend_css()` → `build_legend_css()` (LOW)

All changes are internal refactoring with zero user impact.

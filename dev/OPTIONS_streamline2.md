# Streamline Phase 2: Options Analysis

**Date:** 2025-01-22
**Current State:** R/quickmap_clean.R (2,295 lines, 59 functions)
**Analysis Scope:** Complete codebase review for consolidation opportunities

---

## Executive Summary

Four streamlining options ranging from conservative to aggressive, with potential reductions of 9.6% to 30%.

| Option | Lines Saved | Risk | Effort | When to Choose |
|--------|-------------|------|--------|----------------|
| **Option 1** | 220 (9.6%) | LOW | 4-6h | Want quick wins, minimal testing burden |
| **Option 2** | 275 (12%) | MEDIUM | 8-12h | Balanced approach, moderate testing available |
| **Option 3** | 475 (20.7%) | MED-HIGH | 16-22h | Have good test coverage, want to externalize embedded content |
| **Option 4** | 600-700 (26-30%) | HIGH | 30-40h | Long-term investment, comprehensive test suite exists |

**Key opportunities identified:**
- Consolidate 3 CSS loaders into 1 (~150 lines)
- Extract 128 lines of inline CSS to external files
- Merge 2 YAML loaders (~35 lines)
- Inline 3 layer preparation functions (~35 lines)
- Extract map finalization helper (~30 lines)

---

## Recommendations

### Conservative Path (Recommended)
1. **Start with Option 1** - Safe wins, 4-6 hours, minimal risk
2. **User completes manual tasks first** - Remove dead code (O1.3), remove unused dependency (O3.7) - <5 minutes
3. **Assess code stability** after Option 1 completion
4. **Proceed to Option 2** if tests pass and stability confirmed
5. **Re-evaluate before Option 3+** - requires good test coverage

### Aggressive Path (Requires Preparation)
1. **Pause feature development**
2. **Build comprehensive test suite** (testthat coverage >80%)
3. **Implement Option 1-2 as warmup** - validate approach
4. **Branch for Option 4** - parallel development
5. **Parallel testing over 2-4 weeks**

---

## Task Assignment Summary

### 👤 User Manual Tasks (Quick Wins)
These are trivial edits faster for user to complete manually:

| Task | Location | Why Manual |
|------|----------|------------|
| O1.3: Remove dead code | Lines 1498-1502 | 5-line deletion, instant verification |
| O3.7: Remove unused dependency | Line 11 | Grep for stringr usage + delete 1 line |

**Combined effort:** <5 minutes

### 🤖 Claude Delegation Tasks (Complex Refactoring)
These require code analysis, pattern extraction, or architectural design:

| Task | Complexity | Lines Saved | Risk |
|------|------------|-------------|------|
| O1.1: Consolidate CSS loaders | Medium | ~150 | Low |
| O1.2: Merge YAML loaders | Medium | ~35 | Low |
| O1.4: Extract map finalization | Medium | ~30 | Low |
| O2.5: Inline layer prep functions | Medium | ~35 | Medium |
| O2.6: Simplify label hierarchy | High | ~20 | Medium |
| O3.8: Restructure map pipeline | High | ~35 | Med-High |
| **O3.10: Extract inline CSS to files** | **Medium** | **~130** | **Medium** |
| O3.11: Extract inline HTML | Medium | ~15 | Low |
| O4.13-16: Architectural patterns | Very High | ~200 | High |

### ⚖️ Flexible Tasks (User Choice)
| Task | If User Does | If Claude Does |
|------|--------------|----------------|
| O3.9: Parameterize image mode | Simple find/replace in 3 functions | Automated extraction + testing |
| O3.12: Consolidate sprintf/paste0 | Manual refactoring of 40+ calls | Pattern-based automation |

---

## Next Steps

1. **Choose option** based on risk tolerance and available testing resources
2. **Complete user manual tasks first** (O1.3, O3.7) - takes <5 minutes
3. **Delegate complex tasks to Claude** with clear acceptance criteria
4. **If Option 1-2:** Create feature branch `streamline2` and proceed
5. **If Option 3-4:** First create comprehensive test suite, then proceed
6. **Update STREAMLINE_SUMMARY.md** after completion with actual metrics

---

# Detailed Analysis

## HTML/IMAGE Loop Analysis

### Current Structure

The year loop (lines 2221-2311) processes HTML and IMAGE exports differently:

- **HTML map:** Accumulates layers across all years in single loop pass
- **Static maps:** Recreates map from template for each year inside conditional

**Duplication identified:**
- `generate_map_layers()` called 3x per year when `image_export=TRUE`
- `apply_custom_layout_in_html()` called 2x per year (HTML + static)
- Two nearly identical map templates created upfront (lines 2178, 2205)

**Merge feasibility:** PARTIAL
- Templates could be unified
- Map finalization logic can be extracted to helper function
- Full loop merge would require restructuring temporal layer handling

**Recommendation:** Extract `finalize_map()` helper rather than full merge (see Option 1.4)

---

## Option 1: Safe Consolidation (Conservative)

**Target:** Low-hanging fruit with minimal risk
**Effort:** 4-6 hours
**Testing:** Light - existing tests cover functionality
**Lines Saved:** ~220 lines (9.6% reduction)

### Changes

**1. Consolidate CSS Loading Functions (3 → 1)** 🤖 **DELEGATE TO CLAUDE**
- Merge `load_banner_css()`, `load_legend_css()`, `load_roller_menu_control()` into `load_component_css(component, ...)`
- All three follow identical pattern: get directory → read template → conditional image_mode → apply replacements
- **Lines:** 260 → ~110 (saves ~150 lines)
- **Why delegate:** Complex refactoring requiring analysis of 3 functions, extracting common pattern, handling edge cases

**2. Merge YAML Loaders (2 → 1)** 🤖 **DELEGATE TO CLAUDE**
- Combine `load_colour_scale()` and `load_config()` into `load_yaml_config(type, name, ...)`
- 95% code duplication between these functions
- **Lines:** 66 → ~30 (saves ~35 lines)
- **Why delegate:** Requires careful parameter design to handle both use cases, preserve error messages

**3. Remove Dead Code** 👤 **USER MANUAL TASK**
- Delete unused `colors` calculation in `prepare_dt_layer_data()` (lines 1498-1502)
- Colors are recalculated in `create_generic_icons()` - this is redundant
- **Lines:** 5 saved
- **Why manual:** Trivial 5-line deletion, faster for user to verify and delete than to delegate

**4. Extract Map Finalization Helper** 🤖 **DELEGATE TO CLAUDE**
- Create `finalize_map(map, file, type, ...)` to deduplicate saveWidget + layout + webshot pattern
- Addresses HTML/IMAGE duplication without risky loop merge
- **Lines:** ~30 saved
- **Why delegate:** Requires extracting pattern from 2 locations, determining correct parameter list, handling conditionals

### Impact
- **Code reduction:** 2,295 → 2,075 lines
- **Functions removed:** 4
- **Risk level:** LOW - pure refactoring, no behavior change
- **User testing needed:** Run existing test suite

---

## Option 2: Function Hierarchy Simplification (Moderate)

**Target:** Reduce excessive function fragmentation
**Effort:** 8-12 hours
**Testing:** Moderate - label generation needs careful validation
**Lines Saved:** ~275 lines (12% reduction)

### Changes

**All Option 1 changes PLUS:**

**5. Inline Layer Preparation Functions** 🤖 **DELEGATE TO CLAUDE**
- Remove `prepare_bl_layer_data()`, `prepare_dt_layer_data()`, `prepare_static_layer_data()`
- Inline their 20-25 line bodies into `prepare_generic_layer_data()` switch statement
- Already partially implemented (generic function exists), finish consolidation
- **Lines:** ~35 saved
- **Why delegate:** Moderate complexity - requires analyzing 3 functions, inlining into switch cases, preserving logic

**6. Simplify Label Generation Hierarchy** 🤖 **DELEGATE TO CLAUDE**
- Inline `get_school_labels()`, `get_value_labels()`, `get_custom_labels_with_fallback()` into `generate_marker_labels()`
- Reduce 4-level call stack to single decision tree
- **Lines:** ~20 saved
- **Why delegate:** Complex control flow restructuring, requires careful testing of all label modes

### Impact
- **Code reduction:** 2,295 → 2,020 lines
- **Functions removed:** 9 total
- **Risk level:** MEDIUM - changes control flow in layer/label logic
- **User testing needed:** Verify all label modes (schools, values, custom) and layer types (BL, DT, static)

---

## Option 3: Dependency Cleanup + Pattern Extraction (Moderate-Aggressive)

**Target:** Remove technical debt and establish reusable patterns
**Effort:** 16-22 hours
**Testing:** Comprehensive - affects core rendering flow
**Lines Saved:** ~475 lines (20.7% reduction)

### Changes

**All Option 2 changes PLUS:**

**7. Remove Unused Dependencies** 👤 **USER MANUAL TASK**
- Audit and remove `stringr` from package list (line 11) if unused
- Verify no stringr functions are called anywhere
- **Lines:** 0 saved, but cleaner dependency graph
- **Why manual:** Simple grep + single line deletion, user can verify in seconds

**8. Restructure Map Generation Pipeline** 🤖 **DELEGATE TO CLAUDE**
- Extract common "create base → add layers → add controls → finalize" pattern
- Create `build_map_pipeline(spec)` that handles both HTML and static generation
- Unify template creation (currently 2 templates at lines 2178, 2205)
- **Lines:** ~35 saved
- **Why delegate:** High complexity - requires analyzing entire rendering flow, designing new abstraction

**9. Parameterize Image Mode Conditionals** ⚖️ **USER OR CLAUDE**
- Many functions have `if (image_mode)` branches with hardcoded values
- Extract to configuration object: `get_sizing_params(image_mode)`
- Affects: `load_banner_css()`, `load_legend_css()`, `apply_custom_layout_in_html()`
- **Lines:** ~0 saved, but improves maintainability
- **Why flexible:** Simple pattern extraction (user could do), but touches multiple functions (Claude more efficient)

**10. Extract Inline CSS to External Files** 🤖 **DELEGATE TO CLAUDE**
- Move `mobile_css` strings from R code to external CSS files (lines 913-939, 1012-1112)
- Banner mobile CSS: 27 lines inline → `inst/banner/mobile.css`
- Legend mobile CSS: 101 lines inline → `inst/legend/mobile.css`
- **Approach:** Direct CSS extraction (NOT YAML config - CSS is already a config language)
- Create conditional file loader: `load_mobile_css_file(component, enabled)` that reads CSS file
- **Lines:** ~130 saved
- **Why delegate:** Requires extracting CSS blocks, creating new files, updating template system
- **Why CSS not YAML:** Mobile breakpoints are presentation rules, not user settings; CSS syntax highlighting/linting; standard web practice

**11. Extract Inline HTML Snippets** 🤖 **DELEGATE TO CLAUDE**
- Move HTML string literals to external templates
- Banner container HTML (lines 1324-1330) → `inst/banner/container.html`
- Other inline HTML fragments throughout
- **Lines:** ~15 saved
- **Why delegate:** Need to identify all HTML strings, extract patterns, update callers

**12. Consolidate sprintf/paste0 Multi-line Patterns** ⚖️ **USER OR CLAUDE**
- 40+ sprintf/paste0 calls, some with complex formatting
- Extract reusable HTML/CSS builders: `build_html_tag(tag, content, attrs)`
- Especially for repeated patterns like sprintf('<div class="%s">%s</div>', ...)
- **Lines:** ~20 saved
- **Why flexible:** Pattern is simple but widespread - user judgment call on value

### Impact
- **Code reduction:** 2,295 → 1,820 lines (~20.7% reduction)
- **Functions removed:** 9, new helpers: 2-4
- **External files created:** 2 CSS files (mobile.css), HTML template fragments
- **Risk level:** MEDIUM-HIGH - changes core rendering pipeline, externalizes embedded content
- **User testing needed:** Full regression testing - all map types, both HTML and image export, all themes, mobile responsive behavior

---

## Option 4: Architectural Refactoring (Aggressive)

**Target:** Major simplification through design patterns
**Effort:** 30-40 hours
**Testing:** Extensive - requires comprehensive test coverage first
**Lines Saved:** ~600-700 lines (26-30% reduction)

### Changes

**All Option 3 changes PLUS:**

**13. Introduce Map Builder Pattern** 🤖 **DELEGATE TO CLAUDE**
- Replace procedural layer accumulation with builder: `MapBuilder$new()$add_layers()$add_controls()$render()`
- Encapsulates HTML vs static differences in builder methods
- Eliminates separate template creation and conditional branches
- **Lines:** ~80 saved
- **Why delegate:** Major architectural change requiring R6 class design, extensive refactoring

**14. Strategy Pattern for Layer Types** 🤖 **DELEGATE TO CLAUDE**
- Create layer strategy classes: `BLLayerStrategy`, `DTLayerStrategy`, `SchoolLayerStrategy`
- Each implements `prepare_data()`, `create_icons()`, `generate_labels()`
- Replace switch statements in `prepare_generic_layer_data()` and related functions
- **Lines:** ~40 saved (net - adds structure but removes duplication)
- **Why delegate:** Design pattern implementation, requires creating multiple R6 classes and refactoring callers

**15. Template Engine Consolidation** 🤖 **DELEGATE TO CLAUDE**
- Unify all template replacement logic into single engine
- Replace multiple `apply_template_replacements()` calls with template registry
- Currently: banner, legend, roller-menu each handle own templates
- **Lines:** ~30 saved
- **Why delegate:** Complex abstraction design, affects multiple subsystems

**16. Configuration Registry** 🤖 **DELEGATE TO CLAUDE**
- Centralize all `load_*()` functions into single registry pattern
- `ConfigRegistry$get("theme", "merton")`, `ConfigRegistry$get("scale", "who_no2")`
- Eliminates 5+ separate loader functions
- **Lines:** ~50 saved
- **Why delegate:** Architectural pattern requiring R6 class, caching logic, error handling

### Impact
- **Code reduction:** 2,295 → 1,595-1,695 lines (~26-30% reduction)
- **Functions removed:** ~15
- **New architecture:** Builder + Strategy + Registry patterns
- **External files created:** Mobile CSS files, HTML template fragments
- **Risk level:** HIGH - fundamental architectural change
- **User testing needed:** Complete rewrite of test suite, extensive manual testing of all features, parallel development with feature freeze

### Prerequisites for Option 4
1. **Establish test coverage FIRST** - current test suite is minimal
2. **Feature freeze** - no new features during refactoring
3. **Parallel branch** - keep streamline1 working while developing streamline2
4. **Staged rollout** - merge in phases (builder → strategy → registry)

---

## Detailed Function Analysis

### Functions Targeted for Removal/Consolidation

| Function | Lines | Status in Each Option | Reason |
|----------|-------|----------------------|--------|
| `load_banner_css()` | 59 | O1: merge → `load_component_css()` | 80% duplicate of other CSS loaders |
| `load_legend_css()` | 152 | O1: merge → `load_component_css()` | Same template pattern |
| `load_roller_menu_control()` | 68 | O1: merge → `load_component_css()` | Same template pattern |
| `load_colour_scale()` | 44 | O1: merge → `load_yaml_config()` | 95% duplicate of load_config() |
| `load_config()` | 22 | O1: merge → `load_yaml_config()` | Same YAML loading pattern |
| `prepare_bl_layer_data()` | 20 | O2: inline into generic | Called only from switch statement |
| `prepare_dt_layer_data()` | 25 | O2: inline into generic | Called only from switch statement |
| `prepare_static_layer_data()` | 14 | O2: inline into generic | Called only from switch statement |
| `get_school_labels()` | 7 | O2: inline into parent | Single use, simple logic |
| `get_value_labels()` | 11 | O2: inline into parent | Single use, simple logic |
| `get_custom_labels_with_fallback()` | 31 | O2: inline into parent | Creates unnecessary nesting |

### New Functions Created

| Option | New Function | Purpose | Lines |
|--------|-------------|---------|-------|
| O1 | `load_component_css()` | Unified CSS loading for banner/legend/controls | ~110 |
| O1 | `load_yaml_config()` | Generic YAML loader for scales/configs | ~30 |
| O1 | `finalize_map()` | Deduplicate saveWidget + layout + webshot | ~25 |
| O3 | `build_map_pipeline()` | Unified HTML/static generation flow | ~40 |
| O3 | `load_mobile_css_file()` | Load mobile CSS from external files | ~10 |
| O3 | `get_sizing_params()` | Extract image_mode sizing config | ~15 |
| O4 | `MapBuilder` (R6 class) | Builder pattern for map construction | ~120 |
| O4 | `*LayerStrategy` (R6 classes) | Strategy pattern for layer types | ~80 |
| O4 | `ConfigRegistry` (R6 class) | Centralized config management | ~60 |

---

## CSS Extraction Design Decision

**Question:** Should mobile CSS be extracted to CSS files or YAML config?

**Decision:** Extract to CSS files (NOT YAML)

**Rationale:**
1. **CSS is already a config language** - no need to wrap it in YAML
2. **Fewer lines of R code** - simple file load (~10 lines) vs generation logic (~50-80 lines)
3. **Standard practice** - separating CSS from application code is normal web development
4. **Not actually user configuration** - these are presentation rules, not customizable settings
5. **Maintainability** - web developers can edit CSS directly with syntax highlighting
6. **Debugging** - browser dev tools show actual CSS, not generated output

**When YAML config makes sense:**
- Theme settings (colors, titles) ✅ Currently using
- Scale definitions (thresholds, labels) ✅ Currently using
- Data source paths ✅ Currently using
- **CSS styling rules** ❌ Should stay as CSS

**Implementation:**
```r
load_mobile_css_file <- function(component, enabled) {
  if (!enabled) return("")

  css_dir <- get_package_dir(component)
  css_file <- file.path(css_dir, "mobile.css")

  if (file.exists(css_file)) {
    return(read_template_file(css_file))
  }
  return("")
}
```

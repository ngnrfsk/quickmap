# Modern R & Tidyverse Best Practices Analysis
## quickmap_clean.R (v0.9.0.4)

**Date:** 2025-01-22
**Scope:** Complete codebase review for tidyverse and modern R opportunities

---

## Executive Summary

The codebase is **already quite modern** with extensive dplyr/tidyr usage and native pipe `|>`. Recommendations focus on targeted improvements with real value: dependency cleanup, NULL handling, and consistency.

**Overall Assessment:** Well-structured code following modern R patterns. No wholesale rewrites needed.

---

## ✅ What This Codebase Does Well

- **Extensive dplyr/tidyr usage** - already follows tidyverse patterns
- **Native pipe `|>` throughout** - modern R 4.1+
- **No `class() ==` anti-patterns** - uses `inherits()` correctly
- **Proper NULL checking** - explicit `is.null()` guards
- **Good use of switch() statements** - right tool for type routing
- **Well-named functions and parameters**
- **Appropriate for-loops where stateful iteration makes sense** - map-building, HTML generation

---

## 🔧 Recommended Improvements (ADOPT)

### 1. Remove stringr Dependency

**Current usage:** 1 function call in 2,295 lines

```r
# Line 168 - ONLY usage in entire file
stringr::str_extract(time_col, time_pattern)
```

**Replacement:**
```r
sub("^.*(\\d{4}).*$", "\\1", time_col)
```

**Impact:**
- Remove entire dependency for trivial 4-digit year extraction
- Lines saved: 0, but cleaner dependencies
- Risk: VERY LOW

**Recommendation:** **ADOPT** - included in Option 1, task O1.5

---

### 2. Use `%||%` for NULL Coalescing

**Current pattern (lines 2076-2096): 21 lines**

```r
if (is.null(title)) {
  title <- theme$banner$title
}
if (is.null(vignette)) {
  vignette <- theme$map$vignette
}
if (is.null(banner_colour)) {
  banner_colour <- theme$banner$background
}
if (is.null(boundary_labels)) {
  boundary_labels <- theme$map$boundary_labels
}
if (is.null(marker_labels)) {
  marker_labels <- theme$map$marker_labels
}
if (is.null(autoplay)) {
  autoplay <- theme$controls$autoplay
}
if (is.null(play_speed)) {
  play_speed <- theme$controls$play_speed
}
```

**Replacement: 8 lines (define operator + 7 assignments)**

```r
`%||%` <- function(x, y) if (is.null(x)) y else x

title <- title %||% theme$banner$title
vignette <- vignette %||% theme$map$vignette
banner_colour <- banner_colour %||% theme$banner$background
boundary_labels <- boundary_labels %||% theme$map$boundary_labels
marker_labels <- marker_labels %||% theme$map$marker_labels
autoplay <- autoplay %||% theme$controls$autoplay
play_speed <- play_speed %||% theme$controls$play_speed
```

**Impact:**
- Lines saved: 14
- Idiomatic R (used in ggplot2, tidyverse packages)
- Risk: VERY LOW

**Recommendation:** **ADOPT** - included in Option 1, task O1.7

---

### 3. Standardize on Native Pipe `|>`

**Current:** Mix of `|>` and `%>%` throughout file

**Replacement:** Global find/replace `%>%` → `|>`

**Impact:**
- Consistency across codebase
- Base R (no magrittr dependency)
- Slightly faster
- Lines saved: 0, improved consistency
- Risk: VERY LOW (test afterwards for edge cases)

**Recommendation:** **ADOPT** - included in Option 1, task O1.6

---

### 4. Fix `lapply()` for Side Effects

**Current (line 23):**

```r
lapply(packages, library, character.only = TRUE)
```

**Replacement options:**

```r
# Option A: Make discarded result explicit
invisible(lapply(packages, library, character.only = TRUE))

# Option B: Use for-loop for clarity
for (pkg in packages) {
  library(pkg, character.only = TRUE)
}

# Option C: Use purrr::walk() if adopting purrr
purrr::walk(packages, library, character.only = TRUE)
```

**Impact:**
- Makes side-effect nature explicit
- Lines saved: 0, clearer intent
- Risk: VERY LOW

**Recommendation:** **ADOPT** invisible(lapply(...)) - minimal change, clear intent

---

## ⚖️ Optional Improvements (CONSIDER)

### 5. Type-Safe Color Mapping

**Current (lines 608, 1384, 1387, 1498):**

```r
sapply(data[[pollutant]], assign_colour, scale = colour_scale)
```

**Problem:** `sapply()` returns unpredictable types (list vs vector depending on results)

**Option A - vapply (base R, type-safe):**

```r
vapply(
  data[[pollutant]],
  assign_colour,
  FUN.VALUE = character(1),
  scale = colour_scale
)
```

**Option B - purrr (if adopting purrr elsewhere):**

```r
purrr::map_chr(data[[pollutant]], assign_colour, scale = colour_scale)
```

**Impact:**
- Type safety: guarantees character vector, fails fast with clear error
- Lines saved: 0 (same line count, just more verbose)
- Risk: MEDIUM (functions always return characters, but prevents future bugs)

**Recommendation:** **CONSIDER**
- Use `vapply()` if staying with base R (no new dependency)
- Use `purrr::map_chr()` only if adopting purrr for other reasons
- Current `sapply()` works but lacks type safety

---

### 6. `purrr::iwalk()` for Palette Display

**Current (lines 418-420):**

```r
for (name in names(theme$palette)) {
  cat("  ", name, ": ", theme$palette[[name]], "\n", sep = "")
}
```

**Alternative:**

```r
purrr::iwalk(theme$palette, ~ cat("  ", .y, ": ", .x, "\n", sep = ""))
```

**Impact:**
- Lines saved: 2
- `iwalk()` is DESIGNED for this exact use case (side-effects with names)
- More idiomatic for "iterate with side effects"
- Risk: VERY LOW

**Recommendation:** **CONSIDER** - ADOPT if using purrr elsewhere, otherwise SKIP

---

## ❌ What NOT to Change (Keep Current Approach)

### 1. Template Replacement For-Loop (KEEP)

**Lines 48-56: `apply_template_replacements()`**

**Current approach:**
```r
apply_template_replacements <- function(template, replacements) {
  result <- template
  for (placeholder in names(replacements)) {
    result <- gsub(placeholder, replacements[[placeholder]], result, fixed = TRUE)
  }
  return(result)
}
```

**Why NOT change:**
- For-loop with mutable `result` is CLEARER than `purrr::reduce()` or `Reduce()`
- Sequential string replacement is inherently stateful
- The loop makes this explicit and readable
- Functional alternatives (`reduce2`) use confusing syntax (`..2`, `..3`)

**Verdict:** **SKIP** - current approach is optimal

---

### 2. Legend HTML Generation Loop (KEEP)

**Lines 769-802**

**Why NOT change:**
- For-loop with mutable `symbol_index` and conditional list building
- purrr alternative would require `<<-` super-assignment (anti-pattern!)
- This is a PERFECT example where a for-loop is the right tool
- The mutable state makes the logic clear and debuggable

**Verdict:** **SKIP** - for-loop is more honest about stateful logic

---

### 3. Layer/Year Iteration Loops (KEEP)

**Lines 1901-1961, 2221-2311**

**Why NOT change:**
- Map-building is inherently stateful (Leaflet layers stack)
- `purrr::reduce()` would obscure intent and make debugging harder
- For-loops make mutation explicit, easier to step through with debugger
- Textbook case of "use for-loops for stateful iteration"

**Verdict:** **SKIP** - for-loops are more debuggable for stateful operations

---

### 4. String Manipulation with paste0() (KEEP)

**43 instances of `paste()` or `paste0()` throughout**

**Why NOT change:**
- `stringr::str_c()` is just paste0() with different name (no benefit)
- `stringr::str_glue()` adds complexity for marginal template benefit
- Since we're REMOVING stringr entirely, this is moot
- Base R `paste0()` is fast, clear, universally understood

**Verdict:** **SKIP** - keep using paste0()

---

## 📊 Impact Summary

| Change | Lines Saved | Dependency Impact | Risk | Recommendation | Option |
|--------|-------------|-------------------|------|----------------|--------|
| Remove stringr | 0 | -1 dependency | VERY LOW | **ADOPT** | O1.5 |
| `%||%` operator | -14 | None (define locally) | VERY LOW | **ADOPT** | O1.7 |
| Standardize `\|>` | 0 | Remove magrittr | VERY LOW | **ADOPT** | O1.6 |
| Fix lapply | 0 | None | VERY LOW | **ADOPT** | (minor) |
| vapply/map_chr | 0 | 0 or +1 (purrr) | MEDIUM | **CONSIDER** | - |
| purrr::iwalk | -2 | +1 (purrr) | LOW | **CONSIDER** | - |
| **TOTAL ADOPT** | **-14** | **-1 dependency** | | | |

---

## 🎯 Final Verdict

This is a **well-written, modern R codebase** that already follows tidyverse principles where appropriate.

**Key findings:**
1. ✅ Already uses dplyr, tidyr, native pipe extensively
2. ✅ For-loops are used appropriately for stateful operations
3. ✅ No anti-patterns found (no `class() ==`, proper switch usage)
4. 🔧 Targeted improvements available: dependency cleanup, NULL handling, consistency

**Recommendations are incremental improvements**, not wholesale rewrites:
- **Dependency reduction** - remove stringr (99% unused)
- **Code clarity** - `%||%` operator, native pipe consistency
- **Optional type safety** - vapply() for sapply() calls

**Do NOT adopt "tidyverse for tidyverse's sake"** patterns that make code less readable. The for-loops for stateful operations (map-building, HTML generation) are CORRECT and should be kept.

**Total benefit:** ~14 lines saved, 1 dependency removed, improved consistency, very low risk.

---

## Integration with Streamline Options

Modern R improvements are integrated into **Option 1** (Safe Consolidation):

- **O1.5:** Replace stringr usage (user manual task)
- **O1.6:** Standardize on native pipe (user manual task)
- **O1.7:** Add `%||%` operator (Claude delegation)

These changes complement the other Option 1 improvements:
- O1.1: Consolidate CSS loaders (~150 lines)
- O1.2: Merge YAML loaders (~35 lines)
- O1.3: Remove dead code (~5 lines)
- O1.4: Extract map finalization (~30 lines)

**Option 1 total:** 244 lines saved (10.6% reduction), 1 dependency removed, LOW risk

---

## Detailed Examples

### Example 1: Removing stringr (O1.5)

**Before:**
```r
year = lubridate::as_datetime(paste0(
  stringr::str_extract(time_col, time_pattern),
  "-01-01"
))
```

**After:**
```r
year = lubridate::as_datetime(paste0(
  sub("^.*(\\d{4}).*$", "\\1", time_col),  # Base R regex
  "-01-01"
))
```

---

### Example 2: NULL Coalescing (O1.7)

**Before (21 lines):**
```r
if (is.null(title)) {
  title <- theme$banner$title
}
if (is.null(vignette)) {
  vignette <- theme$map$vignette
}
if (is.null(banner_colour)) {
  banner_colour <- theme$banner$background
}
# ... 4 more blocks ...
```

**After (8 lines):**
```r
`%||%` <- function(x, y) if (is.null(x)) y else x

title <- title %||% theme$banner$title
vignette <- vignette %||% theme$map$vignette
banner_colour <- banner_colour %||% theme$banner$background
boundary_labels <- boundary_labels %||% theme$map$boundary_labels
marker_labels <- marker_labels %||% theme$map$marker_labels
autoplay <- autoplay %||% theme$controls$autoplay
play_speed <- play_speed %||% theme$controls$play_speed
```

**Lines saved:** 14

---

### Example 3: Type-Safe Color Mapping (OPTIONAL)

**Before:**
```r
colors <- sapply(data[[pollutant]], assign_colour, scale = colour_scale)
```

**After (base R option):**
```r
colors <- vapply(
  data[[pollutant]],
  assign_colour,
  FUN.VALUE = character(1),
  scale = colour_scale
)
```

**After (purrr option):**
```r
colors <- purrr::map_chr(data[[pollutant]], assign_colour, scale = colour_scale)
```

**Benefit:** Type safety - fails fast if function doesn't return character
**Trade-off:** Verbose (vapply) vs new dependency (purrr)

---

## When to Use For-Loops vs purrr

This codebase demonstrates excellent judgment on loop usage. Here's the pattern:

### ✅ Use for-loops when:
- Building stateful objects (Leaflet maps, HTML fragments)
- Multiple mutable variables (`symbol_index`, `legend_items`)
- Early exit/skip logic (`next`, `break`)
- Complex conditional logic within loop
- **Examples:** Lines 769-802, 1901-1961, 2221-2311

### ✅ Use purrr when:
- Pure transformations (input → output, no mutation)
- Side effects with clear intent (`walk()`, `iwalk()`)
- Type safety matters (`map_chr()` vs `sapply()`)
- **Examples:** Consider for lines 418-420 if using purrr

### ❌ Don't force purrr when:
- Requires `<<-` super-assignment
- `reduce()` is less clear than for-loop
- Template/string building with mutable accumulator

**This codebase gets it RIGHT** - for-loops are used where they're the best tool.

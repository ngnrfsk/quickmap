# M2: Redundant `static` Field - User Identified Issue

**Date:** 2025-11-26
**Source:** User feedback during code review
**Status:** Logged for v0.9.3

## User's Observation

> "Log this issue - we have built inconsistent code, using both static and pollutant values in CONFIG when only pollutant is required (no pollutants = static)"

## Analysis

The user correctly identified that the `static` field in YAML configs is redundant given the `pollutants` array field.

### Current Design

```yaml
# dt_sites.yaml
static: false
pollutants: [no2]

# schools.yaml
static: true
pollutants: []
```

### Logic Duplication

Both fields encode the same information:
- `static: true` ≡ `pollutants: []` (empty array)
- `static: false` ≡ `pollutants: [...]` (non-empty array)

## Proposed Simplification

### Option A: Eliminate `static` Field
```yaml
# dt_sites.yaml
pollutants: [no2]  # Non-empty = temporal layer

# schools.yaml
pollutants: []     # Empty = static layer
```

**Code changes:**
```r
# Replace: if (config$static)
# With:    if (length(config$pollutants) == 0)

# Or add helper:
is_static_layer <- function(config) {
  length(config$pollutants) == 0
}
```

### Option B: Keep `static`, Make `pollutants` Optional
```yaml
# dt_sites.yaml
static: false

# schools.yaml
static: true
```

Remove `pollutants` field entirely, treat as documentation only.

## Recommendation

**Prefer Option A** - use `pollutants` array as single source of truth:

**Advantages:**
1. Single field determines layer type
2. `pollutants` already provides validation capability (can check if requested pollutant is available)
3. More semantic - "static" is implementation detail, "pollutants measured" is domain concept
4. Aligns with OpenAir metadata structure

**Migration Path:**
1. v0.9.3: Add helper `is_static_layer()` that checks both fields (backward compat)
2. v0.9.4: Deprecate `static` field, emit warning if used
3. v1.0.0: Remove `static` field entirely

## Related Code Locations

Functions that check `config$static`:
- `load_spatial_data_sources()` line 1813
- `get_data_maximum()` line 201
- `generate_map_layers()` line 1725, 1761
- `determine_years_and_viewport()` (checks for `year_str` column, equivalent to !static)

## Impact

**Breaking Change:** Yes - requires YAML config updates
**Complexity:** Low - straightforward refactor
**Benefit:** High - eliminates redundancy, clearer semantics

---

**Decision:** Deferred to v0.9.3 per user feedback. Current implementation works correctly, this is a cleanup/simplification issue.

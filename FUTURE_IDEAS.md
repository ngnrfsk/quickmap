# QuickMap Future Ideas
**Status**: Low Priority / Future Consideration
**Purpose**: Ideas that may or may not be implemented, depending on needs

---

## CSS Preprocessor Approach

**Target Version**: v1.0+ (if at all)
**Effort**: 2-3 hours
**Impact**: LOW
**Priority**: LOW

### Current Pattern

R generates CSS dynamically via sprintf:

```r
# R generates CSS dynamically via sprintf
custom_css <- "\n<style>
.banner {
  background: %s;
  font-size: 1.3rem;
}
</style>\n"
```

### Alternative: SCSS-like Template

**(Not recommended for R package)**

```scss
/* inst/styles/banner.scss.template */
.banner {
  background: {{banner_colour}};
  font-size: $font-size-base * 1.3;
  padding: $spacing-unit;
}
```

### Assessment

**Reasons NOT to implement:**
- **Adds build complexity** - Requires preprocessing step
- **R's sprintf/gsub approach is adequate** - Current solution works well
- **SCSS compilation requires external dependencies** - sass, node, etc.
- **Overkill for this use case** - Not generating complex CSS

**Recommendation:**
- **Keep current approach** but use named placeholders (gsub instead of sprintf)
- SCSS would be appropriate if:
  - Generating very complex CSS with many variables
  - Using CSS mixins and functions extensively
  - Building a CSS framework
  - None of these apply to quickmap

### If Implemented (Not Recommended)

**Would require:**
1. sass R package or external preprocessor
2. Build step in package installation
3. Template syntax decisions
4. Error handling for compilation failures
5. Documentation for maintainers who may not know SCSS

**Alternatives that are better:**
- Named placeholders with gsub (simple, clear)
- CSS custom properties (--banner-bg: #8b4789)
- Keep inline CSS generation (current approach works)

---

## Other Future Ideas

### Idea: Animation Export
**Description**: Export animated GIFs showing year-by-year changes
**Effort**: 6-8 hours
**User Demand**: Unknown

### Idea: Standalone Legend Package
**Description**: Extract legend engine as separate R package (quicklegend)
**Effort**: 8-12 hours
**User Demand**: Low (currently)
**See**: Modernization plan Section 2.4

### Idea: Database Backend
**Description**: DuckDB integration for larger datasets
**Effort**: 8-12 hours
**User Demand**: None currently
**See**: Modernization plan Section 3.5

### Idea: Web API
**Description**: REST API for generating maps on-demand
**Effort**: 16-24 hours
**User Demand**: Unknown

---

**Note**: Ideas in this file should remain here until:
1. Clear user demand emerges
2. Technical requirements justify the complexity
3. Team has bandwidth for implementation and support

Keep it simple. Implement only what's needed.

# Note: Future Refactoring - Config File System

**Date**: 2025-11-16
**Context**: Accessibility enhancement work revealed maintenance issues with current color configuration

## Current Issue

The roller-menu CSS color configuration uses `sprintf()` with 14 positional arguments:
- `R/quickmap.R` lines 1000-1004
- Easy to introduce bugs (e.g., "too few arguments" error in Step 3)
- Hard to maintain as new features require more colors
- No clear documentation of which placeholder maps to which element

## Current Implementation

```r
css_content <- sprintf(css_content,
  banner_colour, banner_colour, accent_light, accent_light,  # Play button
  banner_colour, banner_colour, accent_light, accent_light,  # Year button
  banner_colour, hover_tint, accent_light, hover_tint,       # Menu items
  hover_tint, banner_colour)                                 # Keyboard focus
```

## Proposed Solution

Replace sprintf with a named configuration system:
- Define color scheme in a list/config object
- Use string replacement with named tokens (e.g., `{{PLAY_BG}}`, `{{PLAY_BORDER}}`)
- More maintainable and self-documenting
- Easier to add new colors without breaking existing code

## Next Steps

1. Analyze implementation difficulty
2. Consider impact on existing code
3. Determine if this should be part of broader configuration refactor (see `dev/future_plans/configuration_system.md`)

## Related Files

- `R/quickmap.R` (lines 995-1004)
- `inst/controls/roller-menu.css`
- `dev/future_plans/configuration_system.md`

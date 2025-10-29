---
editor_options: 
  markdown: 
    wrap: 72
---

# Style Guide for quickmap Parameter Design

Based on analysis of OpenAir R package and R graphics conventions

## OpenAir Parameter Design Patterns

### Multi-Value Categorical Parameters

**Pattern**: Use categorical parameters instead of multiple boolean
flags

**Example from OpenAir**: - `type = "site" | "season" | "weekday"`
instead of `show_type`, `is_seasonal`, etc. -
`data_type = "hourly" | "daily" | "monthly"` for data granularity

**Best Practice**: Parameter describes WHAT the user wants, not HOW it's
implemented

**Applied to quickmap**: - Current success:
`marker_labels = FALSE | TRUE | "values_on" | "labels" | "labels_on"` -
Proposed: `banner = "none" | "html" | "leaflet"` instead of
`show_banner = TRUE/FALSE` - Proposed:
`legend = "none" | TRUE | "topright" | "bottomleft"` following leaflet
position conventions

### Flat Parameter Structure

**Pattern**: Keep parameters at top level, avoid deep nesting

**OpenAir Approach**: - Main parameters at function level - Group
related advanced parameters in simple lists when needed - Don't create
complex nested hierarchies

**Applied to quickmap**: - Avoid:
`options = list(display = list(title = list(text = "...")))` - Prefer:
`options = list(banner_color = "...", export_images = FALSE)`

### Sensible Defaults

**Pattern**: Most parameters optional with intelligent defaults

**OpenAir Approach**: - Provide reasonable defaults for common use
cases - Allow users to override when needed - Defaults should work for
90% of use cases

### Clear Naming Conventions

**Pattern**: Self-documenting parameter names

**OpenAir Approach**: - Descriptive names: `data_type` not `dt`,
`pollutant_name` not `poll` - Common patterns: `*_file`, `*_position`,
`*_mode`

## R Graphics Conventions (ggplot2, lattice)

### Options Lists

**Pattern**: Group related parameters in configuration lists

**ggplot2 example**: `theme(element_line = ..., element_rect = ...)`

**Applied to quickmap**: - Advanced parameters grouped in `options`
list - Common parameters remain at function level

### Position Parameters

**Pattern**: Use position strings like leaflet conventions

**Leaflet positions**: "topright", "bottomleft", "bottomright",
"topleft"

**Applied to quickmap**: - Legend positioning: `legend = "topright"`
instead of `legend_position = "topright"`

## Quickmap-Specific Patterns

### Title/Banner Distinction

-   **HTML banner**: Appears above the map (wrapper div, static visible)
-   **Leaflet overlay**: Control inside the map (positioned, can be
    hidden)
-   Use different parameters for different implementation contexts

### Auto-Generation Helpers

-   Generate descriptive titles from components (borough + pollutant +
    year)
-   User provides base title, system appends context
-   Empty title triggers full auto-generation

### UK English Preference

-   Use "colour" not "color" for UK context
-   Add US aliases in future versions if needed

## Anti-Patterns to Avoid

1.  **Boolean explosion**: Don't create many `show_*` boolean parameters
2.  **Deep nesting**: Don't create `options$display$title$text`
    hierarchies
3.  **Implementation details in names**: Don't expose "html" vs
    "leaflet" in parameter values
4.  **Over-engineering**: Keep it simple, don't add complexity before
    it's needed

## Principles

1.  **User intent over implementation**: Parameters should describe what
    user wants
2.  **Progressive disclosure**: Common parameters at top level, advanced
    in options
3.  **Context-aware defaults**: Smart defaults that work in different
    contexts
4.  **Multi-value over boolean**: Prefer categorical states over binary
    toggles

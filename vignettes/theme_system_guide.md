# QuickMap Theme System Guide

**Date:** 2025-01-22
**Version:** 0.9.0.4+
**Feature:** YAML-based theme configuration system

---

## Summary

The theme system provides centralized configuration for map styling via YAML files in `inst/themes/`. Each theme file contains 5 sections controlling all visual aspects of pollution maps, with an optional `palette` section for borough brand colors.

---

## Theme File Structure

Each YAML theme file contains these sections:

```yaml
banner:                    # Top banner styling
  background: "#5F3E94"
  text_color: "white"
  title: "Merton Air Quality"

legend:                    # Legend appearance
  show: true
  background: "#DED4E9"

map:                       # Map display settings
  vignette: true
  base_tiles: null         # null = default OSM tiles
  zoom_level: null         # null = auto-fit to data
  boundary_labels: false
  marker_labels: false

controls:                  # Year control menu
  autoplay: false
  play_speed: 500
  background: "#5F3E94"    # Inherits from banner if null
  text_color: "white"

palette:                   # Borough brand colors (optional)
  purple: "#5F3E94"
  green: "#078141"
  lavender: "#DED4E9"
  # ... additional colors
```

---

## Available Themes

Current themes in `inst/themes/`:

| Theme File | Borough | Primary Color | Palette Colors |
|------------|---------|---------------|----------------|
| `merton_purple.yaml` | Merton | Purple #5F3E94 | 8 colors |
| `wandsworth_blue.yaml` | Wandsworth | Blue #01a7f5 | 7 colors |
| `richmond_blue.yaml` | Richmond | Blue #005794 | 5 colors |
| `high_contrast.yaml` | Accessibility | Purple #5F3E94 | None |

---

## Usage Patterns

### Pattern 1: Discovery

List available themes and view their colors:

```r
# List all available themes
show_borough_colours()
# Output: Available borough themes: high_contrast, merton_purple,
#         richmond_blue, wandsworth_blue

# View a specific theme's palette
show_borough_colours("merton_purple")
# Output:
# Colours for merton_purple:
#   purple: #5F3E94
#   green: #078141
#   black: #000000
#   white: #ffffff
#   cream: #f5f7e3
#   lavender: #DED4E9
#   lime: #39b54a
#   pink: #b94090
#
# Usage: load_theme('inst/themes/merton_purple.yaml')$palette$purple
```

### Pattern 2: Load Theme Data

Access theme settings programmatically:

```r
# Load entire theme
theme <- load_theme("inst/themes/merton_purple.yaml")

# Access theme components
theme$banner$background     # "#5F3E94"
theme$legend$background     # "#DED4E9"
theme$palette$purple        # "#5F3E94"
theme$palette$lavender      # "#DED4E9"
theme$map$vignette          # TRUE
theme$controls$autoplay     # FALSE
```

### Pattern 3: Use Complete Theme

Apply all theme settings to a map:

```r
create_pollution_map(
  diffusion_tube_file = "data.csv",
  boroughs = "Merton",
  theme_file = "inst/themes/merton_purple.yaml"
  # All styling automatically applied from theme:
  #   - banner background/text/title
  #   - legend visibility/background
  #   - vignette on/off
  #   - boundary/marker labels
  #   - autoplay/speed settings
)
```

### Pattern 4: Selective Overrides

Use theme with parameter overrides:

```r
theme <- load_theme("inst/themes/merton_purple.yaml")

create_pollution_map(
  diffusion_tube_file = "data.csv",
  boroughs = "Merton",
  theme_file = "inst/themes/merton_purple.yaml",
  banner_colour = theme$palette$green,  # Override to green
  vignette = FALSE,                      # Override vignette
  autoplay = TRUE                        # Override autoplay
)
```

### Pattern 5: Manual Colors (No Theme File)

Use palette colors without applying full theme:

```r
theme <- load_theme("inst/themes/wandsworth_blue.yaml")

create_pollution_map(
  diffusion_tube_file = "data.csv",
  boroughs = "Wandsworth",
  banner_colour = theme$palette$orange,
  title = "Custom Title",
  vignette = TRUE,
  marker_labels = "values_on"
  # No theme_file parameter = only use extracted colors
)
```

### Pattern 6: Custom Visualizations

Use palette colors in ggplot2:

```r
theme <- load_theme("inst/themes/merton_purple.yaml")

ggplot(data, aes(x = year, y = no2)) +
  geom_line(color = theme$palette$purple) +
  geom_point(color = theme$palette$green) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = theme$palette$lavender)
  )
```

---

## Parameter Override Priority

When calling `create_pollution_map()`, parameters are resolved in this order:

1. **Explicit parameters** (highest) - values passed directly to function
2. **Theme file values** (medium) - values from YAML if `theme_file` specified
3. **Function defaults** (lowest) - hardcoded fallback values

**Example:**

```r
create_pollution_map(
  theme_file = "inst/themes/merton_purple.yaml",  # Sets banner_colour = "#5F3E94"
  banner_colour = "#078141"                        # OVERRIDES to green
)
# Result: banner is GREEN (explicit parameter wins)
```

**Implementation** (R/quickmap_clean.R:2008-2030):

```r
theme <- load_theme(theme_file)

if (is.null(banner_colour)) {
  banner_colour <- theme$banner$background
}
if (is.null(vignette)) {
  vignette <- theme$map$vignette
}
# ... similar logic for all theme-controlled parameters
```

---

## Key Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `load_theme(path)` | Load complete theme from YAML file | List with 5 sections (banner, legend, map, controls, palette) |
| `get_default_theme()` | Get hardcoded fallback defaults | Default theme list |
| `show_borough_colours(name)` | Display palette colors interactively | Prints to console with usage examples |

---

## Creating a New Theme

To create a custom borough theme:

**Step 1:** Copy existing theme template

```bash
cp inst/themes/merton_purple.yaml inst/themes/my_borough.yaml
```

**Step 2:** Edit the 5 required sections

```yaml
banner:
  background: "#YOUR_PRIMARY_COLOR"
  text_color: "white"
  title: "Your Borough Air Quality"

legend:
  show: true
  background: "#YOUR_LIGHT_COLOR"

map:
  vignette: true
  base_tiles: null
  zoom_level: null
  boundary_labels: false
  marker_labels: false

controls:
  autoplay: false
  play_speed: 500
  background: "#YOUR_PRIMARY_COLOR"
  text_color: "white"

palette:
  primary: "#YOUR_PRIMARY_COLOR"
  secondary: "#YOUR_SECONDARY_COLOR"
  accent: "#YOUR_ACCENT_COLOR"
  # Add more brand colors as needed
```

**Step 3:** Test the theme

```r
# Verify it loads
theme <- load_theme("inst/themes/my_borough.yaml")
print(theme)

# View palette
show_borough_colours("my_borough")

# Test in map
create_pollution_map(
  diffusion_tube_file = "test_data.csv",
  boroughs = "Your Borough",
  theme_file = "inst/themes/my_borough.yaml"
)
```

---

## Migration from v0.9.0.3

The palette system replaced the old `borough_palettes` nested list in v0.9.0.4.

### Before (v0.9.0.3)

```r
# Hardcoded nested list in R code
borough_palettes <- list(
  merton = list(
    purple = "#5F3E94",
    green = "#078141"
  )
)

# Access colors
banner_colour <- borough_palettes[["merton"]][["purple"]]
```

### After (v0.9.0.4+)

```r
# YAML theme file: inst/themes/merton_purple.yaml
# palette:
#   purple: "#5F3E94"
#   green: "#078141"

# Access colors
theme <- load_theme("inst/themes/merton_purple.yaml")
banner_colour <- theme$palette$purple
```

### Why the Change?

| Benefit | Description |
|---------|-------------|
| **Single source of truth** | Palette is part of complete theme (banner + legend + map + palette) |
| **Consistency** | All styling in one YAML file, not split across R code |
| **Discoverability** | `show_borough_colours()` lists themes and shows usage |
| **Maintainability** | YAML files easier to edit than nested R lists |
| **Extensibility** | Add new themes without modifying code |

---

## Advanced: Programmatic Access

For scripts that process multiple themes:

```r
# Get all theme files
themes_dir <- system.file("themes", package = "quickmap")
if (themes_dir == "") themes_dir <- "inst/themes"
theme_files <- list.files(themes_dir, pattern = "\\.yaml$", full.names = TRUE)

# Load all themes into a named list
all_themes <- lapply(theme_files, load_theme)
names(all_themes) <- gsub("\\.yaml$", "", basename(theme_files))

# Access specific theme
merton_colors <- all_themes$merton_purple$palette
wandsworth_banner <- all_themes$wandsworth_blue$banner$background

# Generate maps for all themes
for (theme_name in names(all_themes)) {
  theme_file <- file.path(themes_dir, paste0(theme_name, ".yaml"))
  create_pollution_map(
    diffusion_tube_file = "data.csv",
    boroughs = "All",
    theme_file = theme_file,
    output_file = paste0("map_", theme_name, ".html")
  )
}
```

---

## Troubleshooting

### Theme file not found

```r
# Check if file exists
file.exists("inst/themes/my_theme.yaml")

# List available themes
list.files("inst/themes", pattern = "\\.yaml$")

# Use show_borough_colours() to see available themes
show_borough_colours()
```

### Palette section missing

```r
theme <- load_theme("inst/themes/high_contrast.yaml")

if (is.null(theme$palette)) {
  message("This theme has no palette section")
  # Use banner background color as fallback
  color <- theme$banner$background
}
```

### Color not applying to map

```r
# Verify theme loads correctly
theme <- load_theme("inst/themes/merton_purple.yaml")
print(theme$banner$background)  # Should print hex color like "#5F3E94"

# Check parameter override order
# Explicit parameters ALWAYS override theme values
create_pollution_map(
  theme_file = "inst/themes/merton_purple.yaml",  # Sets purple banner
  banner_colour = "#FF0000"                        # OVERRIDES to red
)
```

### Invalid YAML syntax

```r
# If load_theme() returns defaults with warning, check YAML syntax
theme <- load_theme("inst/themes/my_theme.yaml")
# Warning: Failed to load theme file: <error details>

# Validate YAML manually
yaml::read_yaml("inst/themes/my_theme.yaml")
# Fix indentation, colons, quotes, etc.
```

---

## See Also

- `vignettes/v0.9.0_parameter_changes.md` - Parameter simplification in v0.9.0
- `dev/STREAMLINE_SUMMARY.md` - Complete refactoring summary (streamline branch)
- `inst/config/scales/` - YAML color scale definitions for pollution thresholds

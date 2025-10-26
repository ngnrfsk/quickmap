# Task 1E Execution Plan: Unify Banner and Legend System

## Overview
Detailed implementation plan to extend the HTML banner/legend system to static image maps, eliminating the current inconsistency between interactive and static output.

## Pre-Implementation Analysis

### Current Code Structure
- **Lines 834-1036**: `apply_custom_layout_in_html()` - HTML post-processing function
- **Lines 1754-1810**: Static map generation loop
- **Lines 1850-1864**: Interactive map HTML processing
- **Lines 1779-1791**: Static map controls (legacy approach)

### Target Files
- `quickmap.R` - Primary implementation
- Test with existing example scripts to verify functionality

## Phase 1: Extend apply_custom_layout_in_html() Function (1 hour)

### Step 1.1: Add Image Mode Parameters (15 minutes)
**Location**: Line 834 - Function signature

**What we're doing:**
Adding new optional parameters to the function signature without breaking existing functionality.

**Current function call:**
```r
apply_custom_layout_in_html(
  html_file = "map.html",
  banner_text = "My Banner",
  banner_color = "#078141",
  scale_name = "who_no2",
  collapsed_mobile = TRUE
)
```

**New function signature:**
```r
apply_custom_layout_in_html <- function(
  html_file,
  banner_text = NULL,
  banner_color = "#2c3e50",
  scale_name,
  collapsed_mobile = TRUE,
  image_mode = FALSE,           # NEW: FALSE = interactive, TRUE = static image
  image_dimensions = c(1200, 1200)  # NEW: [width, height] for scaling
)
```

**Why these parameters:**
- `image_mode = FALSE`: Defaults to current behavior, opt-in for static images
- `image_dimensions`: Needed because static images have known dimensions, unlike responsive HTML

**Backwards Compatibility:**
- All existing function calls continue working unchanged
- `image_mode = FALSE` by default preserves current behavior

### Step 1.2: Create Image-Optimized CSS (30 minutes)
**Location**: Lines 855-1000 - CSS generation section

**The Problem:**
Current CSS is designed for responsive web viewing with small fonts and symbols. When converted to JPG:
- Text becomes unreadable at typical image sizes
- Legend symbols are too small
- Mobile breakpoints don't make sense for static images

**The Solution:**
Create separate CSS for image mode with larger, print-friendly styling.

**Current CSS example (lines 860-870):**
```css
.banner {
  padding: 1.25rem;      /* Too small for images */
  font-size: 1.3rem;     /* Unreadable when converted to JPG */
}
.legend-symbol {
  width: 1.25rem;        /* Tiny in image exports */
  height: 1.25rem;
}
```

**Implementation approach:**
```r
if (image_mode) {
  # Use image-optimized CSS with larger fonts/symbols
} else {
  # Use existing responsive CSS (current behavior)
}
```

**Add conditional CSS generation:**
```r
# Custom CSS for banner/legend layout
if (image_mode) {
  # Image-optimized CSS with larger fonts and symbols
  custom_css <- "\n<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { height: 100%%; font-family: Arial, sans-serif; overflow: hidden; }
  body { display: flex; flex-direction: column; }

  .banner {
    background: %s;
    color: white;
    padding: 2rem;
    text-align: center;
    font-size: 1.8rem;        /* Larger for image clarity */
    line-height: 1.3em;
    flex-shrink: 0;
    font-weight: bold;
  }

  .map-container { flex: 1; position: relative; min-height: 0; }
  .map-container > div { height: 100%% !important; }

  .legend {
    background: #f8f9fa;
    border-top: 3px solid #dee2e6;  /* Thicker border for images */
    flex-shrink: 0;
  }

  .legend-header {
    padding: 1.5rem 2rem;          /* Larger padding */
    cursor: pointer;
    user-select: none;
    display: flex;
    gap: 1rem;
    align-items: center;
    font-weight: bold;
    font-size: 1.2rem;             /* Larger font */
    background: #e9ecef;
  }

  .legend-items {
    padding: 1rem;
    display: flex;
    gap: 1rem;
    justify-content: center;
    flex-wrap: wrap;
    font-size: 1rem;                /* Larger legend text */
  }

  .legend-item { display: flex; align-items: center; gap: 1rem; }

  .legend-symbol {
    width: 2rem;                    /* Larger symbols */
    height: 2rem;
    border-radius: 50%%;
    border: 2px solid rgba(0,0,0,0.3);
  }
  </style>\n"
} else {
  # Existing interactive CSS (lines 855-1000)
  custom_css <- # ... existing code
}
```

### Step 1.3: Add Image Dimension Awareness (15 minutes)
**Location**: After CSS generation

**The Problem:**
A 800x600 image needs different sizing than a 2400x1800 poster. Fixed CSS sizes don't scale appropriately.

**The Solution:**
Calculate scaling factors based on image dimensions and adjust CSS accordingly.

**Scaling logic:**
```r
if (image_mode) {
  width <- image_dimensions[1]   # e.g., 1920
  height <- image_dimensions[2]  # e.g., 1080

  # Calculate scale factor (1200px = baseline)
  scale_factor <- min(width / 1200, height / 1200)
  # For 1920x1080: min(1.6, 0.9) = 0.9 (use height as limiting factor)

  # Apply scaling to CSS values
  banner_font_size <- 1.8 * scale_factor  # 1.62rem for 1920x1080
  symbol_size <- 2 * scale_factor          # 1.8rem for 1920x1080
}
```

**Dynamic CSS replacement:**
```r
# Replace fixed sizes with calculated ones
custom_css <- gsub("1.8rem", paste0(banner_font_size, "rem"), custom_css)
custom_css <- gsub("2rem", paste0(symbol_size, "rem"), custom_css)
```

**Why this approach works:**
- **Proportional scaling**: Maintains design ratios across all image sizes
- **Baseline reference**: 1200px serves as design standard
- **Limiting factor**: Uses smaller dimension to prevent overflow

## Phase 1 Expected Outcome

**Before Phase 1:**
- Function only works for interactive HTML maps
- Static images get basic Leaflet styling only

**After Phase 1:**
- Same function works for both interactive and static
- Static images get professional banner/legend styling
- Automatic scaling for different image dimensions

**Function call for static images:**
```r
apply_custom_layout_in_html(
  html_file = "static_map_2024.html",
  banner_text = "Air Quality Report 2024",
  banner_color = "#078141",
  scale_name = "who_no2",
  collapsed_mobile = FALSE,    # Keep legends expanded in images
  image_mode = TRUE,           # NEW: Enable image optimizations
  image_dimensions = c(1920, 1080)  # NEW: Scale for HD display
)
```

**Key Benefits:**
- **Backwards Compatible**: All existing calls work unchanged
- **Future-Proof**: Easy to add more image optimizations later
- **Maintainable**: Single function handles both use cases

## Phase 2: Modify Static Map Generation (30 minutes)

### Step 2.1: Update Static Map Loop (20 minutes)
**Location**: Lines 1798-1810 - Static map saving

**Current:**
```r
saveWidget(
  static_map,
  file = html_file,
  selfcontained = TRUE,
  title = html_page_title
)
webshot2::webshot(
  url = html_file,
  file = img_file,
  vwidth = map_width_px,
  vheight = map_height_px
)
```

**New:**
```r
saveWidget(
  static_map,
  file = html_file,
  selfcontained = TRUE,
  title = html_page_title
)

# Apply HTML banner/legend processing for static images
tryCatch({
  apply_custom_layout_in_html(
    html_file = html_file,
    banner_text = if (show_banner) banner_text else NULL,
    banner_color = border_color,
    scale_name = scale_to_use,
    collapsed_mobile = FALSE,  # Keep expanded for static images
    image_mode = TRUE,         # NEW: Enable image optimization
    image_dimensions = c(map_width_px, map_height_px)  # NEW
  )
}, error = function(e) {
  warning("Failed to apply static image layout: ", e$message)
})

webshot2::webshot(
  url = html_file,
  file = img_file,
  vwidth = map_width_px,
  vheight = map_height_px
)
```

### Step 2.2: Update Function Documentation (10 minutes)
**Location**: Lines 1589-1592 - TODO comments

**Remove resolved TODO:**
```r
# TODO: work out the correct the use of the show_banner and show_legend parameters now that HTML is used to correctly display these
# TODO: Add default value for boroughs parameter to improve usability. Currently required with no default, causing "argument 'boroughs' is missing" error
# TODO: do error trap for colour scale and invalid pollutants
# COMPLETED: TODO: unify HTML map creations and the static map creation functions so static maps can use the HTML banners and legends
```

## Phase 3: Remove Legacy Legend Code (1 hour)

### Step 3.1: Simplify add_map_controls() (40 minutes)
**Location**: Lines 1431-1524 - `add_map_controls()` function

**Current approach:** Has complex `interactive = TRUE/FALSE` branching
**New approach:** Remove static-specific legend code since HTML processing handles it

**Modify legend section (lines 1475-1502):**
```r
# Legend - only add for interactive maps, static maps use HTML legends
if (show_legend && interactive) {
  if (is.null(legend_info))
    stop("legend_info is required when show_legend = TRUE")
  color_symbols <- Map(
    f = makeSymbol,
    shape = 'rect',
    fillColor = legend_info$colors,
    color = 'black',
    width = LEGEND_STYLE$symbol_size$width,
    height = LEGEND_STYLE$symbol_size$height,
    opacity = 1,
    fillOpacity = 1
  )
  map <- map |>
    addLegendImage(
      images = color_symbols,
      labels = legend_info$labels,
      title = htmltools::tags$div(
        legend_info$title,
        style = LEGEND_STYLE$title
      ),
      labelStyle = LEGEND_STYLE$labels,
      width = LEGEND_STYLE$display_size$width,
      height = LEGEND_STYLE$display_size$height,
      position = "bottomright"
    )
}
```

### Step 3.2: Update Static Map Controls Call (20 minutes)
**Location**: Lines 1779-1791 - Static map controls

**Current:**
```r
static_map <- add_map_controls(
  static_map,
  legend_info,
  title_prefix,
  borough_sf,
  vignette_overlay,
  vignette_overlay_on,
  bbox,
  show_title = show_title,
  show_legend = show_legend,     # This now does nothing for static
  interactive = FALSE,
  years = yr
)
```

**New:**
```r
static_map <- add_map_controls(
  static_map,
  legend_info = NULL,           # Don't pass legend_info for static
  title_prefix,
  borough_sf,
  vignette_overlay,
  vignette_overlay_on,
  bbox,
  show_title = FALSE,           # Titles handled by HTML banner
  show_legend = FALSE,          # Legends handled by HTML processing
  interactive = FALSE,
  years = yr
)
```

## Phase 4: Testing and Validation (1 hour)

### Step 4.1: Test Different Image Sizes (30 minutes)
Create test script to verify scaling:

```r
# Test different image dimensions
test_dimensions <- list(
  small = c(800, 600),
  standard = c(1200, 1200),
  large = c(1920, 1080),
  poster = c(2400, 1800)
)

for (size_name in names(test_dimensions)) {
  create_pollution_map(
    csv_data_file = "test_data.csv",
    boroughs = "Wandsworth",
    output_file = paste0("test_", size_name, ".html"),
    image_export = TRUE,
    map_width_px = test_dimensions[[size_name]][1],
    map_height_px = test_dimensions[[size_name]][2],
    show_banner = TRUE,
    banner_text = paste("Test", size_name, "size"),
    show_legend = TRUE
  )
}
```

### Step 4.2: Verify Consistency (30 minutes)
Compare interactive HTML vs static JPG outputs:
- Banner text and positioning
- Legend completeness and readability
- Mobile responsiveness (for HTML)
- Image clarity (for JPG)

## Risk Mitigation

### Backup Strategy
1. **Git branch**: Create feature branch before implementation
2. **Copy function**: Keep original `apply_custom_layout_in_html()` as backup
3. **Parameter backwards compatibility**: Default `image_mode = FALSE`

### Error Handling
1. **Graceful degradation**: Wrap HTML processing in `tryCatch()`
2. **Validation**: Check file existence before processing
3. **User feedback**: Clear warning messages if processing fails

## Success Criteria
- [ ] Static images show banners identical to interactive maps
- [ ] Static images show rich HTML legends instead of basic Leaflet legends
- [ ] All image sizes scale appropriately
- [ ] No regression in interactive map functionality
- [ ] Code is cleaner with less duplication

## Post-Implementation
1. Update CLAUDE.md documentation
2. Remove TODO comment about unifying systems
3. Test with production data sets
4. Consider extending to other output formats (PNG, PDF)

**Total Estimated Time: 3.5 hours**
**Complexity: Medium**
**Risk Level: Low** (extends existing proven system)
# Task 1E: Unify Banner and Legend System for Static Images

## Overview
Simplify static image map generation by using the same HTML banner/legend system that works for interactive maps. Currently, static maps use old Leaflet-based controls while interactive maps use the modern HTML post-processing approach, creating inconsistency and missed functionality.

## Current Implementation Analysis

### Interactive Maps (HTML Output)
**Modern Approach** - Uses `apply_custom_layout_in_html()`:
1. Creates standard Leaflet map with `add_map_controls()`
2. Saves as HTML file with `saveWidget()`
3. **Post-processes HTML** with `apply_custom_layout_in_html()`:
   - Injects viewport meta tag for mobile compatibility
   - Adds flexbox CSS for banner/map/legend layout
   - Inserts HTML banner above map container
   - Generates external legend below map from `colour_scales`
   - Applies mobile-responsive styling

### Static Maps (Image Export)
**Legacy Approach** - Limited to Leaflet controls:
1. Creates Leaflet map with same `add_map_controls()` but `interactive = FALSE`
2. Uses basic Leaflet `addLegendImage()` for legend (limited styling)
3. Uses `title_prefix` for basic titles (no banner support)
4. Saves as HTML → converts to JPG with `webshot2::webshot()`
5. **No HTML post-processing** - misses banner/legend system entirely

## Problem Identification

### Missing Functionality in Static Maps
- **No HTML banners**: Static maps can't use modern banner system
- **Basic legends only**: Limited to simple Leaflet legend styling vs rich HTML legends
- **No mobile optimization**: Lacks responsive design for different image sizes
- **Inconsistent styling**: Different visual appearance from interactive maps

### Code Duplication Issues
- Two separate legend systems maintained
- Different parameter handling for similar functionality
- Inconsistent visual branding between output types

## Proposed Solution

### Extend HTML Post-Processing to Static Maps
Modify the static map workflow to apply the same HTML enhancements before image conversion:

```r
# Current static workflow:
static_map → saveWidget() → webshot() → JPG

# Proposed unified workflow:
static_map → saveWidget() → apply_custom_layout_in_html() → webshot() → JPG
```

## Implementation Strategy

### Phase 1: Extend apply_custom_layout_in_html()
Add support for static image considerations:
- **Image-optimized CSS**: Larger text/symbols for JPG clarity
- **Fixed dimensions**: Optimize layout for known image dimensions
- **Print-friendly styling**: High contrast, bold text for image export

### Phase 2: Modify Static Map Generation
Update the static map loop (lines 1754-1810):
```r
# Current approach:
saveWidget(static_map, html_file)
webshot2::webshot(html_file, img_file)

# New unified approach:
saveWidget(static_map, html_file)
apply_custom_layout_in_html(
  html_file = html_file,
  banner_text = if (show_banner) banner_text else NULL,
  banner_color = border_color,
  scale_name = scale_to_use,
  image_mode = TRUE,  # NEW: optimizes for static export
  image_dimensions = c(map_width_px, map_height_px)  # NEW
)
webshot2::webshot(html_file, img_file)
```

### Phase 3: Remove Legacy Legend Code
Simplify `add_map_controls()` by removing duplicate legend handling:
- Remove `addLegendImage()` calls for static maps
- Standardize on HTML legend system for all output types
- Remove `interactive = FALSE` branch complexity

## Expected Benefits

### Consistency
- **Unified visual design**: Same banner/legend appearance across all outputs
- **Single code path**: One system for banner/legend generation
- **Consistent parameters**: Same `show_banner`/`banner_text` behavior

### Enhanced Functionality
- **Static image banners**: Professional branded headers on JPG exports
- **Rich static legends**: Mobile-responsive legends even in image format
- **Better mobile images**: Optimized layouts for different screen sizes

### Code Simplification
- **Reduced complexity**: Eliminate `interactive = TRUE/FALSE` branching
- **Less maintenance**: Single banner/legend system to maintain
- **Cleaner functions**: Remove duplicate legend generation code

## Technical Considerations

### Image Quality Optimization
- Increase font sizes and symbol sizes for static export
- Use high contrast colors for better JPG compression
- Optimize spacing for print/presentation use

### Performance Impact
- Minimal: Same HTML post-processing, just applied to more files
- File cleanup still works (remove temporary HTML files)
- Slight increase in static generation time due to HTML processing

## Implementation Plan

1. **Extend `apply_custom_layout_in_html()`** - Add `image_mode` parameter (1 hour)
2. **Modify static map loop** - Apply HTML processing before webshot (30 minutes)
3. **Remove legacy legend code** - Clean up `add_map_controls()` (1 hour)
4. **Test with different image sizes** - Ensure scaling works properly (1 hour)

## Expected Outcomes
- **Unified output system**: Same banner/legend quality for HTML and JPG
- **Professional static images**: Branded headers and rich legends in exports
- **Simplified codebase**: Single banner/legend system eliminates duplication
- **Better mobile support**: Responsive designs work for all image dimensions

## Estimated Effort
**3.5 hours** - Moderate complexity due to need to extend existing system rather than replace it

**Risk Level**: Low - Extends proven HTML system rather than creating new functionality
# Bug 0: Marker Scaling Inconsistency Fix Plan

**Bug**: Markers are too small in static maps compared to HTML maps  
**Priority**: CRITICAL  
**Status**: NOT STARTED  
**Estimated Effort**: 2-3 hours

## Problem Analysis

### Current Behavior
- **HTML maps**: Use fixed `image_scale_factor = 1.0` (no scaling)
- **Static maps**: Use `marker_scale_factor = sqrt((map_width_px * map_height_px) / (1200 * 1200))`
- **Result**: Static maps have significantly smaller markers than HTML maps

### Root Causes
1. **Inconsistent scaling approaches** between HTML and static maps
2. **Base marker sizes too small** for intended 1200x1200 reference
3. **Geometric mean scaling** may not be appropriate for marker visibility
4. **Under-scaling** for images smaller than 1200x1200 makes markers nearly invisible

## Solution Strategy

### Option 1: Unify Scaling Approach (Recommended)
- Apply same scaling logic to both HTML and static maps
- Use consistent base sizes and scaling factors
- Ensure markers remain visible across all image dimensions

### Option 2: Adjust Base Sizes and Scaling Formula
- Increase base marker sizes for better visibility
- Modify scaling formula to prevent under-scaling
- Maintain current dual approach but fix the scaling

## Implementation Plan

### Phase 1: Analysis and Testing (30 minutes)
1. **Document current marker sizes** across different image dimensions
2. **Test visibility thresholds** - determine minimum viable marker size
3. **Compare HTML vs static** marker appearance side-by-side
4. **Identify optimal base sizes** for 1200x1200 reference

### Phase 2: Implement Unified Scaling (90 minutes)
1. **Modify `create_generic_icons()` function**:
   - Increase base marker sizes (schools: 8→12, dt_sites/bl_nodes: 15→20)
   - Add minimum size constraint to prevent under-scaling
   - Ensure consistent scaling formula

2. **Update scaling calculation**:
   ```r
   # Current problematic formula:
   marker_scale_factor <- sqrt((map_width_px * map_height_px) / (1200 * 1200))
   
   # Proposed improved formula:
   marker_scale_factor <- max(0.7, sqrt((map_width_px * map_height_px) / (1200 * 1200)))
   ```

3. **Apply scaling to HTML maps**:
   - Remove fixed `image_scale_factor = 1.0` for HTML maps
   - Calculate appropriate scale factor for HTML maps based on viewport
   - Ensure HTML maps use same scaling logic as static maps

### Phase 3: Testing and Validation (30 minutes)
1. **Test across multiple image dimensions**:
   - 600x600 (small)
   - 1200x1200 (reference)
   - 1920x1080 (widescreen)
   - 2400x2400 (large)

2. **Verify marker visibility**:
   - Markers clearly visible at all sizes
   - Consistent appearance between HTML and static maps
   - No overlap or crowding issues

3. **Performance testing**:
   - Ensure scaling doesn't impact map generation speed
   - Verify file sizes remain reasonable

## Code Changes Required

### Files to Modify
- `quickmap_0_8_7_3.R` (primary)
- `quickmap.R` (if changes need to be backported)

### Key Functions to Update
1. **`create_generic_icons()`** (lines 1230-1284):
   - Update base marker sizes
   - Add minimum scaling constraint
   - Improve scaling logic

2. **`generate_map_layers()`** (lines 1727-1797):
   - Ensure consistent scale factor application
   - Remove hardcoded scale factors

3. **Main map generation loop** (lines 1957-2053):
   - Apply consistent scaling to both HTML and static maps
   - Calculate appropriate scale factors for HTML maps

### Configuration Updates
- Update `VIGNETTE_STYLE` if needed for consistency
- Consider adding `MARKER_SCALING_CONFIG` constant

## Success Criteria
- [ ] Markers in static maps are same size as HTML maps
- [ ] Markers remain visible across all image dimensions (600x600 to 2400x2400)
- [ ] No performance degradation
- [ ] Consistent user experience between HTML and static outputs
- [ ] All existing functionality preserved

## Risk Assessment
- **Low Risk**: Changes are isolated to marker scaling logic
- **Testing Required**: Extensive testing across different image dimensions
- **Rollback Plan**: Keep current version as backup, implement as new version

## Dependencies
- None (self-contained bug fix)
- May inform future scaling improvements in Task 1E.2

## Notes
- This fix addresses the core inconsistency identified in Bug 0
- May also resolve related UX issues with marker visibility
- Should be implemented before website launch
- Consider documenting scaling approach for future maintenance


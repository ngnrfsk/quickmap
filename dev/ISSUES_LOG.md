# Known Issues Log

### Export Image Parameter Validation (FIXED in config branch)
- **Issue**: `export_image = TRUE` failed with baseSize error; only accepted c(width, height) format
- **Fix**: Added validation to accept NULL/FALSE/TRUE/c(width,height); TRUE uses default 1920x1080

### Year Display Missing on Exported Images (DOCUMENTED)
- **Issue**: Static JPG exports don't show year value in year control menu location
- **Details**: See dev/ISSUES_year_not_showing_on_export_image.md for full analysis and workarounds

### Error in load_colour_scale(scale)  - no graceful exit or fallback

  Scale 'pants' not found. Available: stripes_no2, stripes_pm25_, who_no2, lbrut_no2, lbw_no2, lbm_no2, gla_pm25, deltas, schools

## Code Simplification:**

- Main opportunities: the 200+ line `create_pollution_map()` could split into smaller focused functions
- Layer generation loop could abstract to `map_reduce` pattern
- Many inline comments could move to roxygen2 function docs

**Prep for v0.9.1+:**

- Consider functional programming patterns (purrr) for layer iteration
- Potential to extract "legend engine" as standalone module
- Database integration (duckdb as mentioned) could drive next architecture



## TODO

- make all the WHO guideline bottom colours the same blue
- make the legend and marker colours the same
- make +- same colour as banner
- modernise all the CSS into a control block?
- remove guff and fluff in the commentary and excess comments and files
- clean up directory structure



## Feedback to Anthropic

- Use the feedback button in the Claude interface
- Email their support team
- Share your story on social media tagging @AnthropicAI

Your story combines public service, learning, and real-world impact - exactly what they love to hear about.


# Issue: VoiceOver Screen Reader - Listbox Items Not Speaking

**Date**: 2025-11-16
**Status**: Known Issue
**Severity**: Medium
**Affected Component**: Year selection dropdown (roller-menu)

## Description

VoiceOver does not correctly select or speak the year items in the listbox dropdown. While the ARIA roles and attributes are properly implemented (`role="listbox"`, `role="option"`, `aria-selected`), VoiceOver is not announcing the items when navigating through them.

## Implementation Details

Current implementation follows WAI-ARIA listbox pattern:
- Container: `<div role="listbox">`
- Items: `<div role="option" aria-selected="true/false">`
- Button: `aria-expanded="true/false"`

## Possible Causes

1. **Missing aria-activedescendant**: The listbox pattern may require `aria-activedescendant` on the container to track which option has focus
2. **Focus management**: VoiceOver may require actual focus on items, not just CSS highlighting
3. **Keyboard navigation pattern**: VoiceOver expects specific keyboard patterns for listbox interaction
4. **Browser compatibility**: Safari/VoiceOver specific implementation differences

## Testing Status

- ✅ Keyboard navigation works (arrows, enter, escape)
- ✅ Visual feedback works (focus indicators, selection highlighting)
- ✅ ARIA attributes update correctly (verified in inspector)
- ❌ VoiceOver does not announce options when navigating
- ⚠️ Other screen readers not yet tested (NVDA, JAWS)

## Workarounds

Current accessibility features that DO work:
- Full keyboard navigation without mouse
- Visual focus indicators
- Play/pause button announces correctly
- Year button announces state correctly
- All functionality accessible via keyboard

## Next Steps

1. Test with other screen readers (NVDA on Windows, JAWS)
2. Research VoiceOver-specific listbox implementation requirements
3. Consider implementing `aria-activedescendant` pattern
4. Consider alternative ARIA patterns (menu, radiogroup)
5. Add `tabindex="-1"` to options for direct focus management

## References

- WAI-ARIA Listbox Pattern: https://www.w3.org/WAI/ARIA/apg/patterns/listbox/
- VoiceOver Testing: https://developer.apple.com/library/archive/technotes/TestingAccessibilityOfiOSApps/TestAccessibilityonYourDevicewithVoiceOver/TestAccessibilityonYourDevicewithVoiceOver.html

## Related Files

- `inst/controls/roller-menu.html`
- `inst/controls/roller-menu.js`
- `dev/PLAN_ACCESSIBILITY.md`


# Edge Case Analysis - Play/Pause Control

**Date**: 2025-11-16
**Status**: Analysis Complete, Implementation Pending
**Context**: Steps 1-6 complete, animation working, analyzing edge cases for robustness

---

## Currently Unhandled Edge Cases

### 1. **Non-Numeric Year Categories**
**Scenario:** Layer keys are strings like "Primary", "Secondary" or dates like "2024-01-01"
**Current Behavior:** `parseInt()` fails, sorting breaks
**Impact:** HIGH if used for non-year data, LOW for year-only use
**Likelihood:** LOW (designed for years)
**Fix Complexity:** LOW (change to `parseFloat()` or alphanumeric sort)
**Recommendation:** ⚠️ **Worth addressing** - Simple fix, enables broader use cases

**Fix:**
```javascript
var years = Object.keys(window.quickmapLayerCache).sort(function(a, b) {
  return parseFloat(a) - parseFloat(b); // Changed from parseInt
});
```

---

### 2. **Very Large Year Ranges (30+ years)**
**Scenario:** Dataset spans 1990-2024 (35 years)
**Current Behavior:** Dropdown becomes very long, slower scrolling
**Impact:** MEDIUM - UX degraded but functional
**Likelihood:** MEDIUM - historical pollution data often spans decades
**Fix Complexity:** MEDIUM (add virtual scrolling or year groups)
**Recommendation:** ⏸️ **Not urgent** - Current max-height scrolling works, address if users complain

---

### 3. **Rapid Click Spam on Play Button**
**Scenario:** User clicks play button 5 times rapidly
**Current Behavior:** `togglePlayPause()` flips state each time, intervals cleared/restarted
**Impact:** LOW - Might skip frames or stutter briefly
**Likelihood:** MEDIUM - impatient users
**Fix Complexity:** LOW (add debouncing)
**Recommendation:** ✅ **Worth addressing** - Easy fix, better UX

**Fix:**
```javascript
var lastToggleTime = 0;
playPauseButton.addEventListener('click', function(e) {
  e.stopPropagation();
  var now = Date.now();
  if (now - lastToggleTime < 300) return; // Ignore rapid clicks
  lastToggleTime = now;
  togglePlayPause();
});
```

---

### 4. **Invalid Configuration Values**
**Scenario:** `play_speed = 0`, `play_speed = -100`, `play_speed = "fast"`
**Current Behavior:**
- `0`: `setInterval(fn, 0)` - runs as fast as possible, locks browser
- Negative: Same as 0
- String: `NaN`, animation breaks
**Impact:** HIGH - Can crash/freeze browser
**Likelihood:** LOW - requires user error in R
**Fix Complexity:** LOW (validate in R or JS)
**Recommendation:** ✅ **Worth addressing** - Critical for robustness

**Fix:**
```javascript
// Validate and clamp play speed
var playSpeed = Math.max(50, Math.min(5000, parseFloat(config.playSpeed) || 500));
```

---

### 5. **Animation During Dropdown Open**
**Scenario:** User opens dropdown while animation is running
**Current Behavior:** Dropdown shows, selected item highlights update during animation
**Impact:** LOW - Slightly confusing but functional
**Likelihood:** MEDIUM
**Fix Complexity:** LOW (auto-close dropdown when playing)
**Recommendation:** ⏸️ **Not urgent** - Current behavior is acceptable

---

### 6. **Extremely Fast Animation (<100ms)**
**Scenario:** `play_speed = 10`
**Current Behavior:** Animation runs extremely fast, may skip visual frames, hard to see
**Impact:** MEDIUM - Poor UX, hard to click pause
**Likelihood:** LOW - requires deliberate misconfiguration
**Fix Complexity:** LOW (clamp minimum)
**Recommendation:** ✅ **Worth addressing** - Same fix as #4

---

### 7. **Keyboard Accessibility**
**Scenario:** User navigates with Tab/Enter/Space
**Current Behavior:** Can tab to buttons, Enter works, Space doesn't (on custom button)
**Impact:** MEDIUM - Accessibility issue
**Likelihood:** MEDIUM - power users, accessibility needs
**Fix Complexity:** MEDIUM (add keyboard handlers, ARIA labels)
**Recommendation:** ⚠️ **Worth addressing** - Important for accessibility compliance

**Fix:**
```javascript
playPauseButton.addEventListener('keydown', function(e) {
  if (e.key === ' ' || e.key === 'Spacebar') {
    e.preventDefault();
    togglePlayPause();
  }
});

yearButton.addEventListener('keydown', function(e) {
  if (e.key === ' ' || e.key === 'Spacebar') {
    e.preventDefault();
    // Toggle dropdown
  }
  if (e.key === 'Escape') {
    // Close dropdown
  }
});
```

---

### 8. **Screen Reader Support**
**Scenario:** Visually impaired user with screen reader
**Current Behavior:** Buttons not labeled, state changes not announced
**Impact:** HIGH - Completely unusable for screen readers
**Likelihood:** LOW - depends on user base
**Fix Complexity:** MEDIUM (add ARIA attributes)
**Recommendation:** ⚠️ **Worth addressing** - Accessibility best practice

**Fix:**
```html
<!-- roller-menu.html -->
<button id="playPauseButton"
        class="play-pause-button"
        aria-label="Play animation"
        aria-pressed="false">▶</button>

<button id="yearButton"
        class="year-button"
        aria-label="Select year"
        aria-expanded="false"
        aria-haspopup="listbox">
  <span id="selectedYear"></span>
  <span class="arrow">▼</span>
</button>

<div id="yearList"
     class="year-list"
     role="listbox"
     aria-label="Year selection">
  <!-- Years populated here with role="option" -->
</div>
```

```javascript
// Update ARIA states dynamically
function togglePlayPause() {
  isPlaying = !isPlaying;
  playPauseButton.textContent = isPlaying ? '⏸' : '▶';
  playPauseButton.setAttribute('aria-pressed', isPlaying);
  playPauseButton.setAttribute('aria-label', isPlaying ? 'Pause animation' : 'Play animation');
  // ... rest of logic
}
```

---

### 9. **Multiple Maps on Same Page**
**Scenario:** Two maps in same HTML document
**Current Behavior:** Both controls use same global `window.quickmapConfig`, may conflict
**Impact:** HIGH if used, but LOW likelihood
**Likelihood:** VERY LOW - rare use case
**Fix Complexity:** HIGH (namespace configs by map ID)
**Recommendation:** ❌ **Skip** - Edge case too rare, major refactor required

---

### 10. **Browser Back Button During Animation**
**Scenario:** Animation playing, user clicks browser back
**Current Behavior:** Page navigates away, `beforeunload` cleanup fires
**Impact:** NONE - Already handled
**Likelihood:** MEDIUM
**Fix Complexity:** N/A - Already working
**Recommendation:** ✅ **Already handled** - No action needed

---

### 11. **Touch Device Interactions**
**Scenario:** User on iPad/iPhone
**Current Behavior:** Buttons are 2.5rem (40px), may be small for touch
**Impact:** MEDIUM - Harder to tap accurately
**Likelihood:** HIGH - mobile usage common
**Fix Complexity:** LOW (increase button size or touch target)
**Recommendation:** ⏸️ **Monitor** - Test with users, adjust if complaints

**Potential Fix:**
```css
/* Increase touch target size on mobile */
@media (max-width: 768px) {
  .play-pause-button {
    width: 3rem;
    height: 3rem;
    font-size: 1.2rem;
  }
}
```

---

### 12. **Years Load After Control Initializes (Race Condition)**
**Scenario:** Layer cache populates slowly due to large dataset
**Current Behavior:** Polling mechanism handles this (checks every 100ms)
**Impact:** NONE - Already handled
**Likelihood:** MEDIUM
**Fix Complexity:** N/A - Already working
**Recommendation:** ✅ **Already handled** - No action needed

---

### 13. **Fractional/Decimal Years**
**Scenario:** Monthly data as `2024.083` (January), `2024.166` (February)
**Current Behavior:** `parseInt()` truncates to `2024`, all months treated as same year
**Impact:** HIGH for monthly data, N/A for annual
**Likelihood:** MEDIUM - if expanded to monthly pollution monitoring
**Fix Complexity:** LOW (use `parseFloat()`)
**Recommendation:** ⚠️ **Worth addressing** - Same fix as #1, enables monthly data

---

## Priority Summary

### ✅ **High Priority (Worth Addressing Now)**

**Estimated Total Effort:** 30 minutes

1. **Input Validation** (#4, #6) - 5 minutes
   - Clamp `play_speed` to safe range (50-5000ms)
   - Prevents browser freeze/crash

2. **Numeric Sorting Fix** (#1, #13) - 5 minutes
   - Change `parseInt()` to `parseFloat()`
   - Enables decimal years and broader use cases

3. **Button Debouncing** (#3) - 15 minutes
   - Prevent rapid-click issues
   - Smoother UX

**Implementation:**
```javascript
// In roller-menu.js, after reading config:

// 1. Validate and clamp play speed
var playSpeed = Math.max(50, Math.min(5000, parseFloat(config.playSpeed) || 500));

// 2. Fix sorting for decimals
var years = Object.keys(window.quickmapLayerCache).sort(function(a, b) {
  return parseFloat(a) - parseFloat(b);
});

// 3. Debounce play button
var lastToggleTime = 0;
function debouncedToggle() {
  var now = Date.now();
  if (now - lastToggleTime < 300) return;
  lastToggleTime = now;
  togglePlayPause();
}
playPauseButton.addEventListener('click', function(e) {
  e.stopPropagation();
  debouncedToggle();
});
```

---

### ⚠️ **Medium Priority (Address if Time Permits)**

**Estimated Total Effort:** 2 hours

4. **Keyboard Accessibility** (#7) - 1 hour
   - Add Space bar support for play/pause
   - Add Escape to close dropdown
   - Arrow keys for year navigation
   - **Impact:** Accessibility compliance

5. **ARIA Labels** (#8) - 1 hour
   - `aria-label`, `aria-pressed` on buttons
   - `role="listbox"` on dropdown
   - Dynamic state announcements
   - **Impact:** Screen reader support

---

### ⏸️ **Low Priority (Monitor, Address on Demand)**

6. **Large Year Ranges** (#2)
   - Wait for user feedback on 30+ year datasets
   - Consider year grouping or virtual scrolling

7. **Touch Targets** (#11)
   - Test with real users on mobile devices first
   - Increase button size if complaints

8. **Animation During Dropdown** (#5)
   - Current behavior acceptable
   - Could auto-close dropdown on play if needed

---

### ❌ **Skip (Not Worth Addressing)**

9. **Multiple Maps** (#9)
   - Too rare (single map per page is standard)
   - Too complex (major architectural refactor)
   - No user demand

---

## Recommended Implementation Order

### Phase 1: Quick Wins (Next Session)
- Input validation + sorting fix + debouncing
- **Time:** 30 minutes
- **Impact:** Prevents crashes, enables broader use

### Phase 2: Accessibility (Future)
- Keyboard support + ARIA labels
- **Time:** 2 hours
- **Impact:** WCAG compliance, broader audience

### Phase 3: Polish (On Demand)
- Touch targets, large year ranges
- **Time:** Variable
- **Impact:** UX refinements based on user feedback

---

## Testing Checklist (After Quick Wins)

- [ ] Test with `play_speed = 0` - should clamp to 50ms
- [ ] Test with `play_speed = -100` - should clamp to 50ms
- [ ] Test with `play_speed = "fast"` - should default to 500ms
- [ ] Test with `play_speed = 10000` - should clamp to 5000ms
- [ ] Test with decimal years (2024.083, 2024.166) - should sort correctly
- [ ] Test rapid-clicking play button - should debounce smoothly
- [ ] Test with 35 years (1990-2024) - should scroll correctly
- [ ] Verify no console errors in Chrome, Firefox, Safari

---

## Notes

- Debug console.log statements should be removed/reduced before production
- Consider adding user-facing error messages for invalid config
- May want to add R-side validation in addition to JS validation


------------------------------------------------------------------------

## Fix #4: Legend Size Recheck (Priority: MEDIUM)

### Issue

Legend sizing was fixed in v0.8.7.3 but needs validation across
different screen sizes to ensure scaling works correctly.

### Previous Fix (v0.8.7.3)

``` r
# Reduced legend marker sizes relative to map markers
# Improved gaps and padding in legend layout
```

### Test Matrix

| Screen Size | Resolution | Test Scenario | Expected Behavior |
|-----------------|-----------------|-----------------|----------------------|
| Mobile | 375x667 (iPhone SE) | Portrait | Legend auto-collapses, readable when expanded |
| Mobile | 414x896 (iPhone 11) | Portrait | Legend readable, proportional spacing |
| Tablet | 768x1024 (iPad) | Portrait | Legend visible, markers sized correctly |
| Tablet | 1024x768 (iPad) | Landscape | Legend fits, no overflow |
| Desktop | 1280x720 (HD) | Landscape | Legend sized appropriately |
| Desktop | 1920x1080 (FHD) | Landscape | Legend scaled correctly |
| Desktop | 2560x1440 (QHD) | Landscape | Legend not too small |

### Areas to Validate

**1. Legend Marker Sizes**

``` r
# Check in generate_legend_html()
# Markers should be ~60% of map marker size
marker_size <- 12  # Map markers
legend_marker_size <- 8  # Legend (should be ~60-70%)
```

**2. Text Sizing**

``` r
# Proportional to screen
font-size: 14px;  # Desktop
font-size: 12px;  # Tablet
font-size: 11px;  # Mobile
```

**3. Spacing/Padding**

``` r
# Check gaps between legend items
.legend-item {
  margin-bottom: 4px;  # Desktop
  margin-bottom: 3px;  # Mobile
}
```

**4. Mobile Collapse Behavior**

``` css
/* Existing from v0.8.7.3 */
@media (max-width: 480px) {
  .external-legend {
    max-height: 50vh;
    overflow-y: auto;
  }
}
```

### Implementation Steps

1.  **Create** test HTML files for each screen size
2.  **Open** in browser DevTools with responsive mode
3.  **Measure** legend elements at each breakpoint
4.  **Document** any sizing issues
5.  **Adjust** CSS if needed (only if issues found)
6.  **Retest** after adjustments

### Files to Review

-   `R/quickmap.R` - `generate_legend_html()` function (\~line 856-950)
-   `R/quickmap.R` - CSS in legend generation (\~line 900-1000)
-   Test output: `aq_maps/*.html` files

### Potential Issues to Check

-   Legend markers too small on high-DPI screens
-   Text overlapping on narrow viewports
-   Legend height exceeding viewport (scroll needed?)
-   Padding/spacing inconsistent across sizes
-   Color contrast issues on mobile

### Test Cases

-   [x] Generate map at 1920x1080 - legend proportional
-   [x] Resize to 1280x720 - legend scales correctly
-   [x] Resize to 768x1024 - legend readable
-   [x] Resize to 414x896 - legend fits, collapsed if needed
-   [x] High-DPI (retina) - markers crisp, not pixelated
-   [x] All color scales - text readable on all backgrounds

### Success Criteria

-   Legend readable at all tested screen sizes
-   Markers proportional to map markers (60-70% size)
-   Text doesn't overflow or truncate unexpectedly
-   Spacing consistent and visually balanced
-   No CSS changes needed (validates v0.8.7.3 fix)
-   If changes needed: document and implement minimal adjustments

------------------------------------------------------------------------

## Implementation Order

**Session 1: Core Functionality** (1.5-2 hours) 1. Fix #1: Zoom Level
(30-45 min) 2. Fix #2: Start Layer (45-60 min)

**Session 2: UI Polish** (1.5-2 hours) 3. Fix #3: Collapsible Radio
Buttons (60-75 min) 4. Fix #4: Legend Size Testing (30-45 min)

------------------------------------------------------------------------

## Testing Strategy

### Manual Testing Checklist

**For Each Fix**: - [ ] Create test script in `tests/` - [ ] Generate
actual map output - [ ] Open in browser (Chrome, Firefox, Safari) - [ ]
Test on mobile device or DevTools responsive mode - [ ] Verify no
JavaScript console errors - [ ] Verify no breaking changes to existing
functionality

### Example Test Script Template

``` r
# tests/test_ui_fix_zoom_level.R
source("R/quickmap.R")

# Test 1: Single borough with DT data only
map1 <- create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  sensor_file = "none",
  boroughs = "Wandsworth",
  years = 2024,
  output_file = "test_zoom_wandsworth.html"
)

# Test 2: Multiple years, check initial year
map2 <- create_pollution_map(
  diffusion_tube_file = "wandsworth_2017_2024_no_labels.csv",
  sensor_file = "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  boroughs = "Wandsworth",
  years = c(2022, 2023, 2024),
  initial_year = 2024,  # NEW parameter
  output_file = "test_initial_year.html"
)

cat("✓ Tests complete. Check aq_maps/ for outputs.\n")
```

### Regression Testing

After all fixes, run existing tests to ensure no breaks:

``` r
source("tests/test_v0_9_0_step4_styling_type.R")
# Should still pass
```

------------------------------------------------------------------------

## Version Control Strategy

### Branch Strategy

-   Work in `main` branch (current practice)
-   Each fix gets its own commit
-   Test files committed alongside code changes

### Commit Messages Format

```         
Fix #1: Optimize initial map zoom to fit markers

- Add calculate_optimal_bounds() helper function
- Calculate bounds from all active layer coordinates
- Apply fitBounds() with 1% padding
- Test with various data combinations

Fixes: Issue #13 (Zoom Level on Map Open)
```

### Version Bump

After all 4 fixes complete: - Update version in `R/quickmap.R` header:
`v0.9.0` → `v0.9.1` - Update `dev/PROJECT_STATUS.md` with completion
notes - Update `NEWS.md` with fix descriptions

------------------------------------------------------------------------

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|----------------|-------------------|----------------|---------------------|
| fitBounds() breaks on empty data | Medium | Low | Add null checks, fallback to borough bounds |
| initial_year conflicts with existing code | Low | Medium | Test thoroughly with all year combinations |
| CSS positioning breaks other controls | Medium | Medium | Test with all leaflet controls enabled |
| Legend changes needed (breaking v0.8.7.3) | Low | Low | Only adjust if clear issues found |
| Mobile responsiveness issues | Medium | Medium | Test on actual devices, multiple browsers |

------------------------------------------------------------------------

## Rollback Plan

If any fix causes issues: 1. Individual fix rollback:
`git revert <commit-hash>` 2. Each fix is separate commit for easy
isolation 3. Keep `versions/quickmap_0_9_0.R` as stable fallback 4.
Document any issues in `dev/PROJECT_STATUS.md`

------------------------------------------------------------------------

## Success Metrics

**Fix #1 (Zoom)**: - [ ] Maps open with \<5% empty border space - [ ]
All markers visible on initial load

**Fix #2 (Start Layer)**: - [ ] `initial_year` parameter functional - [
] Specified year visible, others hidden on load - [ ] Radio buttons
allow year switching

**Fix #3 (Radio Buttons)**: - [ ] Control in bottom-left corner - [ ]
Collapsed by default - [ ] Expands on click - [ ] No overlap with other
UI elements

**Fix #4 (Legend)**: - [ ] Legend readable on all tested screen sizes -
[ ] Markers and text properly sized - [ ] No overflow or truncation
issues

------------------------------------------------------------------------

## Post-Implementation

### Documentation Updates

-   Update `R/quickmap.R` header with v0.9.1 changes
-   Update `NEWS.md` with fix descriptions
-   Update `dev/PROJECT_STATUS.md` - mark issues complete
-   Update `README.md` if new parameters added

### User Communication

-   Document `initial_year` parameter in examples
-   Note UI improvements in release notes
-   Provide before/after screenshots if helpful

------------------------------------------------------------------------

## Questions for User Review

1.  **Fix #2 (initial_year)**: Should this parameter also support:
    -   `"all"` - show all years initially?
    -   Date range syntax like `"2022-2024"`?
    -   Or keep simple (single year, NULL, "latest", "earliest")?
2.  **Fix #3 (Radio Buttons)**: Bottom-left position confirmed?
    -   Alternative: bottom-right?
    -   Should icon be customized or use default?
3.  **Fix #4 (Legend)**: If issues found during testing:
    -   Make minimal adjustments and document?
    -   Or defer to later version if complex?
4.  **Testing**: Do you have access to actual mobile devices for
    testing?
    -   Or rely on browser DevTools responsive mode?
5.  **Priority**: Tackle all 4 in this session or split across sessions?

------------------------------------------------------------------------

**Ready for Review**: Please review plan and provide feedback before
implementation begins.


 # Future Enhancements

## Issue 1: Display Insufficient Data Sites
**Location:** `R/quickmap_clean.R:51`
**Description:** Could display sites with >20% missing data as white disks with "Insufficient data" labels instead of filtering them out entirely.
**Priority:** Low
**Impact:** Better visualization of data coverage

## Issue 2: Add Input Validation for Boundary Names
**Location:** `R/quickmap_clean.R:258-259`
**Description:** Add input validation for boundary_names parameter to handle NULL, missing, or invalid input gracefully. Currently assumes input is always valid.
**Priority:** Medium
**Impact:** Better error handling and user experience

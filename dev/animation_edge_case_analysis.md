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

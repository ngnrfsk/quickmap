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

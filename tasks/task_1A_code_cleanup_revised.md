# Task 1A: Complete Code Cleanup and TODO Resolution (Revised)

## Overview
Remove technical debt and resolve critical maintenance issues in quickmap.R (1,939 lines) to improve code readability and prevent user-facing bugs. Analysis reveals ~150 lines of dead code (8% of file) and several critical TODOs that cause crashes.

## Priority-Ranked TODO Resolution

### 🔴 CRITICAL (Must Fix - Prevents Crashes)
1. **Line 1590**: Add default value for `boroughs` parameter
   - **Impact**: Currently causes "argument 'boroughs' is missing" crashes
   - **Solution**: Add `boroughs = NULL` with helpful error message

2. **Line 1591**: Add error trapping for color scales and invalid pollutants
   - **Impact**: Silent failures with incorrect parameters
   - **Solution**: Validate `scale_to_use` against `colour_scales` names, check pollutant compatibility

3. **Line 1592**: Unify HTML and static map creation for banner/legend consistency
   - **Impact**: Static maps don't use new HTML banner/legend system
   - **Solution**: Extend `apply_custom_layout_in_html()` to static map workflow

### 🟡 HIGH PRIORITY (Should Fix - Quality Issues)
4. **Line 1581**: Remove debug print statement
   - **Code**: `print(paste("Setting visible layer:", layer_name))`
   - **Impact**: Console pollution in production

5. **Line 229**: Add comprehensive input validation for `boundary_names` parameter
   - **Impact**: Poor error messages for invalid borough names
   - **Solution**: Enhanced validation with suggestions for typos

6. **Lines 31-61**: Move extensive version history to CHANGELOG.md
   - **Impact**: 31 lines of comment bloat in main code
   - **Solution**: Create separate CHANGELOG.md file

### 🟢 MEDIUM PRIORITY (Nice to Have - Configuration)
7. **Line 396**: Make `noHide = TRUE` configurable in `LABEL_OPTIONS`
   - **Impact**: Hardcoded label behavior
   - **Solution**: Add parameter to relevant functions

8. **Line 1045**: Make icon sizes configurable
   - **Impact**: Hardcoded `size = 8`, `size = 15` values
   - **Solution**: Add icon sizing parameters or config object

## Dead Code Removal (125+ Lines)

### Deprecated Functions (60 lines)
- **Lines 1119-1162**: `add_full_width_banner_control()` - 44 lines
- **Lines 1164-1179**: `add_map_styling()` - 16 lines
- **Line 1827**: Deprecated comment marker

### Legacy Code Blocks (64+ lines)
- **Lines 1872-1935**: Old border styling system completely replaced by new HTML layout
- **Line 1589**: TODO about banner/legend parameters (now resolved)

### Development Artifacts
- Debug comments like "### END OF NEW CODE"
- Redundant function signatures and parameter lists
- Old "Force cleanup" comments with outdated bug references

## Code Quality Improvements

### Documentation Standardization
- Convert all function comments to consistent roxygen2 format
- Remove redundant comments that duplicate obvious code functionality
- Organize remaining comments into logical sections with clear headers
- Create proper parameter documentation for all functions

### Error Handling Enhancement
- Standardize error message formats across all 21 error handling blocks
- Add input sanitization for file paths and user inputs
- Implement graceful degradation for optional features
- Add environment variable validation at startup

## Expected Outcomes
- **File size reduction**: ~150 lines (8% smaller, from 1,939 to ~1,790 lines)
- **Zero critical TODOs**: All crash-causing issues resolved
- **Professional codebase**: No development artifacts or debug statements
- **Better user experience**: Clear error messages and parameter validation
- **Maintainable foundation**: Clean, documented code ready for future enhancements

## Implementation Strategy
1. **Phase 1**: Fix critical TODOs (boroughs default, validation) - 1 hour
2. **Phase 2**: Remove all dead code blocks - 1.5 hours
3. **Phase 3**: Clean up development artifacts and comments - 1 hour
4. **Phase 4**: Standardize documentation and error handling - 1.5 hours

## Estimated Effort
**Revised: 4-5 hours** (increased from original 3-4 hours due to more extensive dead code discovery and critical bug fixes needed)

**Risk Level**: Low-Medium (mostly removing unused code, but some critical parameter changes required)
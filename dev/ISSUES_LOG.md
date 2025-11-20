# Known Issues Log

## Export Image Parameter Validation (FIXED in config branch)
- **Issue**: `export_image = TRUE` failed with baseSize error; only accepted c(width, height) format
- **Fix**: Added validation to accept NULL/FALSE/TRUE/c(width,height); TRUE uses default 1920x1080

## Year Display Missing on Exported Images (DOCUMENTED)
- **Issue**: Static JPG exports don't show year value in year control menu location
- **Details**: See dev/ISSUES_year_not_showing_on_export_image.md for full analysis and workarounds

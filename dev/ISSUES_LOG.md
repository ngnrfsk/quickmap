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

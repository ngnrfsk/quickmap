# QuickMap v0.9.1 → v0.9.5: Implementation Plan

## OpenAir Integration + Multi-Network Support

**Date:** 2025-11-24 **Status:** Problem-oriented implementation roadmap **Timeline:** 8 weeks (2 weeks per version)

------------------------------------------------------------------------

## Strategic Context

### QuickMap's Niche

**Production-ready temporal animation of monitoring network data with self-contained HTML/JPG output.**

No other R-spatial tool combines:

\- Temporal animation of point data (year-by-year progression, potentially finer)

\- Self-contained HTML files (no server dependencies)

\- Static JPG export for same temporal data

\- Production polish (themes, branding) out-of-the-box

Not competing with: mapview (exploration), tmap (general mapping), openairmaps (spatial analysis viz).

### R-Spatial Ecosystem Facts

-   **sf** (1.0-23): Universal spatial vector format
-   **sftime** (0.3.1): Irregular spatiotemporal points, CRAN-stable, actively maintained (1 open issue, 125 commits). Pre-v1.0 but production-ready.
-   **stars** (0.7-0): Regular spatiotemporal arrays (not applicable—quickmap handles point networks, not grids)
-   **openairmaps**: Uses sf + temporal columns, NOT sftime. No temporal animation, no JPG export.
-   **leaflet/leaflet.extras2**: TimeDimension, addTimeslider plugins **don't work with POSIX dates**—quickmap uses custom JS/CSS controls for this reason

### Technical Constraints

-   **Temporal controls**: Current roller menu displays 4-digit years only. Extending to months/days/hours requires redesign of text display format.
-   **Leaflet performance**: Degrades \>10,000 markers. Daily (365 × 100 sites = 36k) and hourly (8760 × 100 = 876k) require progressive disclosure.
-   **POSIX date handling**: Standard leaflet temporal plugins incompatible—custom controls required.

------------------------------------------------------------------------

## v0.9.2: Layer Generalization (Weeks 1-2)

### Problem Statement

Adding new monitoring networks (AURN, LAQN, future sensors) currently requires modifying 15+ locations in R/quickmap.R (lines 1249-1634). Layer types hardcoded (dt_sites, bl_nodes, schools) with coupled: file parameter → layer name → icon shape → pollutant column. Doesn't scale to 5+ networks. Overlaying OpenAir data on existing layers (immediate requirement) needs architectural fix first.

### Goals

1.  Enable unlimited networks with distinct visual identities
2.  New network = configuration entry, not code modification
3.  Maintain 100% backward compatibility with existing v0.9.1 behavior

### Requirements

**Functional**:
- New API parameters: `data_sources` (files or sf objects), `data_configs` (config names) as parallel vectors
- Each network configurable via YAML: icon shape, pollutant column, temporal flag
- Support 5+ icon shapes (circle, diamond, cross, square, triangle)
- Icon colors remain dynamic: pollution data uses colour_scale, schools use categorical
- Handle 5 networks × 100 sites × 5 years = 2,500 features

**Technical**:
- YAML configs in `inst/config/networks/` following inst/config/scales/ pattern
- Layer rendering loop iterates configs generically, no hardcoded layer_type switches
- Icon generation uses data-driven shape lookup
- Config loading via `load_network_config()` analogous to `load_colour_scale()`
- Backward compatibility: old file parameters map to new data_sources/data_configs

**Non-functional**:
- Backward compatible API (new parameters optional)
- All existing tests pass unchanged
- Existing three data sources render identically
- No performance regression

### Constraints

-   Must work with existing sf objects from current loaders (don't break `load_data_file()`, `process_oa_data()`)
-   Keep current rendering pipeline (leaflet + layer groups + year controls)
-   Preserve existing icons for dt_sites (circles), bl_nodes (diamonds), schools (crosses)
-   Reuse existing styling approach using config files in inst/ directory
-   Don't touch temporal controls in v0.9.2 (year-only display remains)

### Success Criteria

-   [ ] Mock 4th network added via YAML config, renders with square icon
-   [ ] New API tested: `data_sources` + `data_configs` parameters work with 4 networks
-   [ ] Backward compatibility: Old 3-file API still works
-   [ ] All 14 existing test scripts pass unchanged
-   [ ] Visual regression: v0.9.1 vs v0.9.2 maps identical for same data
-   [ ] Code metrics: Reduced switch statements, layer_type checks eliminated

### Dependencies

-   **Blocks**: v0.9.3 (OpenAir converter needs generalized layer system)
-   **Requires**: None (refactors existing code in place)

### Investigation Questions for Engineer

1.  **Icon shape lookup**: How to map shape names to icon parameters efficiently? Lookup table vs closure?
2.  **Data passing**: How to integrate new data_sources parameter with existing get_measurement_layers() signature?
3.  **YAML structure**: What additional fields (beyond id, icon_shape, pollutant_col, temporal) are needed for edge cases?
4.  **Config validation**: Where to validate configs—at load time or render time?

### Testing Strategy

-   **Unit**: Layer config creation functions (inputs: sf + metadata → output: valid config)
-   **Integration**: 4-network map (existing 3 + mock AURN data with fake `network` column)
-   **Regression**: All 14 test scripts in `tests/` directory pass
-   **Visual**: Side-by-side comparison v0.9.1 vs v0.9.2 output for sample borough

### Reference Code Locations

-   Current layer system: `get_measurement_layers()` (R/quickmap.R:1249-1278)
-   Layer processing: `generate_map_layers()` (R/quickmap.R:1561-1634)
-   Icon generation: `create_generic_icons()` (R/quickmap.R:\~1400)
-   Data loading: `load_data_file()` (R/quickmap.R:\~50-150)

------------------------------------------------------------------------

## v0.9.3: OpenAir Data Converter (Weeks 3-4)

### Problem Statement

AURN and LAQN networks accessible via `openair::importAURN()` and `openair::importKCL()` but return temporal data.frames (date + site + pollutant columns), not spatial sf objects. No direct path from OpenAir import → quickmap visualization. Need converter handling coordinate lookup, temporal aggregation, spatial conversion—generic for all OpenAir network imports.

### Goals

1.  Enable workflow: `importAURN() → convertOpenAirToSpatial() → create_pollution_map(data_sources, data_configs)`
2.  Overlay AURN + LAQN on existing diffusion tubes + BL sensors using v0.9.2 flexible API
3.  Support multiple temporal resolutions via OpenAir's `timeAverage()` (annual default, monthly/daily/hourly optional)

### Requirements

**Functional**: - Convert OpenAir temporal data.frame → sf object matching quickmap's sensor_file format - Auto-fetch site coordinates via `openair::importMeta(source)` if not provided - Temporal aggregation via `openair::timeAverage(avg.time)` (delegate to OpenAir's proven logic) - Return sf for annual aggregations (`avg.time="year"`), optionally sftime for sub-annual (future) - Handle all OpenAir networks identically (AURN, LAQN, SAQN, WAQN, European—same converter)

**Technical**: - Input: OpenAir data.frame with `date` (POSIXct), `site`, `code`, pollutant columns - Output: sf object with columns: siteCode, year (or date), pollutant, lat, lon, geometry (WGS84) - Coordinate system: Output WGS84 (EPSG:4326) universally (AURN native WGS84, converter ensures consistency) - Missing data: Filter out sites without coordinates, warn user

**Data sources**: - AURN: \~300 sites UK-wide, hourly data, high quality - LAQN: \~100 sites Greater London, hourly data, managed by Imperial College - Metadata: `importMeta(source, all=TRUE)` provides site, code, latitude, longitude, site_type, local_authority

### Constraints

-   Must use OpenAir's `timeAverage()` for aggregation (don't reimplement—maintains data quality standards like `data.thresh`)
-   Don't force sftime dependency in v0.9.3 (annual sf objects only)
-   Converter must work with v0.9.2 generalized layer system (slots in as config entry)
-   Network-specific icons: AURN = square/green, LAQN = triangle/orange (distinct from existing)

### Success Criteria

-   [ ] AURN London sites (5 years annual) converted and mapped correctly
-   [ ] LAQN sites (5 years annual) converted and mapped correctly
-   [ ] 4-network overlay renders with distinct icons: diffusion tubes (circle/blue), BL sensors (diamond/purple), AURN (square/green), LAQN (triangle/orange), schools (cross/red)
-   [ ] Coordinate accuracy validated (spot-check 3 sites against Google Maps)
-   [ ] Converter handles missing sites gracefully (warns, filters out)
-   [ ] Performance: 100 sites × 5 years converts + renders \<30 seconds

### Dependencies

-   **Requires**: v0.9.2 (generalized layer system must exist first)
-   **Blocks**: v0.9.4 (sftime integration builds on converter)

### Investigation Questions for Engineer

1.  **Memory efficiency**: Should converter aggregate before spatial conversion (reduce 8760 hourly → 1 annual per site/year) or convert then aggregate? What's memory profile for 300 sites × 10 years × 8760 hours?
2.  **Metadata caching**: `importMeta()` makes API call—cache results within session? Where to store?
3.  **Error handling**: What if site in data but not in metadata (no coordinates)? Warn per-site or summarize at end?
4.  **Column naming**: OpenAir uses lowercase (`no2`), quickmap uses... what? Check existing conventions in `process_oa_data()`.
5.  **Network differentiation**: If user combines `importAURN()` + `importKCL()` into single data.frame, how to assign different icons? Add `network` column? Or keep separate?

### Testing Strategy

-   **Unit**: Converter with mock OpenAir data (3 sites, 2 years, known coordinates)
-   **Integration**: Real AURN download (2 sites, 1 year) → converter → map
-   **Integration**: AURN + LAQN combined (4 sites each) → 8-site map with 2 icon types
-   **Regression**: Existing CSV/RData loaders still work
-   **Performance**: Benchmark 100 sites × 5 years (should be \<30s total)

### Reference Materials

-   OpenAir data structure: [importAURN docs](https://openair-project.github.io/openair/reference/importAURN.html)
-   OpenAir metadata: [importMeta docs](https://openair-project.github.io/openair/reference/importMeta.html)
-   OpenAir aggregation: `?openair::timeAverage` (handles missing data, data capture thresholds)
-   Existing spatial conversion: `process_oa_data()` (R/quickmap.R:75-117) as template

------------------------------------------------------------------------

## v0.9.4: Sub-Annual Temporal Resolution (Weeks 5-6)

### Problem Statement

Current system displays annual aggregations only (one value per site per year). Use cases require finer temporal resolution: episode analysis (48-hour pollution events), seasonal patterns (monthly averages), real-time dashboards (hourly). Current roller menu displays "2023" (4 digits)—incompatible with "2023-12" (month) or "2023-12-15" (day). Leaflet temporal plugins don't work with POSIX dates (known limitation—why quickmap uses custom controls). Need: temporal resolution detection, adaptive UI controls, performance safeguards for large feature counts.

### Goals

1.  Support monthly, daily, hourly temporal resolutions (not just annual)
2.  Extend temporal controls to handle finer resolutions (month/day/hour display)
3.  Validate sub-annual performance and feasibility before full commitment
4.  Maintain backward compatibility (annual-only maps work unchanged)

### Requirements

**Functional**: - Converter (`v0.9.3`) returns sftime objects for sub-annual data (optional—falls back to sf if sftime unavailable) - Temporal resolution detection: Inspect data for time column, infer resolution (year/month/day/hour) - UI controls adapt to resolution: Year-only (current) vs "2023-12" (month) vs "2023-12-15 08:00" (hour) - Performance limits: Warn if daily \>1000 features, block hourly \>500 features (unless user overrides)

**Technical**: - sftime as **suggested** dependency (not required)—graceful degradation to sf if unavailable - Temporal resolution field in layer configs: "year" \| "month" \| "day" \| "hour" - UI control redesign: Current roller menu assumes 4-digit years—needs format strings - Leaflet performance: Marker clustering thresholds scale with resolution (annual: 50 sites, daily: 10 sites)

**Data handling**: - Monthly: 12 months × 100 sites = 1,200 features (manageable) - Daily: 365 days × 100 sites = 36,500 features (Leaflet struggles, need warnings) - Hourly: 8,760 hours × 100 sites = 876,000 features (unusable without subsetting, block by default)

### Constraints

-   Annual maps (existing workflow) must work unchanged (sf-only, no sftime required)
-   Don't break existing roller menu for year-only data
-   Custom JS/CSS controls required (leaflet temporal plugins incompatible with POSIX dates)
-   Sub-annual features are **opt-in** (user explicitly requests via `avg.time` parameter)

### Success Criteria

-   [ ] Monthly aggregation: 12 months × 3 sites renders with month selector ("Jan 2023", "Feb 2023", ...)
-   [ ] Daily aggregation: 31 days × 3 sites renders with date selector ("2023-12-01", "2023-12-02", ...)
-   [ ] Performance: Monthly (1,200 features) renders \<10 seconds for 100 sites
-   [ ] Warning system: Daily \>1000 features shows warning, prompts user to subset temporally
-   [ ] sftime optional: If sftime not installed, converter falls back to sf + date column (with warning)
-   [ ] Backward compatibility: All existing annual maps work with zero changes

### Dependencies

-   **Requires**: v0.9.3 (converter must support `avg.time` parameter)
-   **Blocks**: v0.9.5 (performance optimization assumes sub-annual testing done)

### Investigation Questions for Engineer

1.  **UI control design**: Hierarchical (year dropdown → month dropdown) vs date range picker vs slider? What's UX for episode analysis (48-hour window)?
2.  **sftime necessity**: Is explicit time column required, or can sf + date column work? Test both approaches.
3.  **Temporal filtering**: Current system filters by `year_str` column—extend to `date` column for sub-annual? Performance implications?
4.  **Animation speed**: Current autoplay advances yearly—sub-annual needs configurable speed (1 hour per second? Adjustable?).
5.  **Feature count detection**: Check feature count before rendering and warn—where in pipeline? At converter output or map creation?

### Testing Strategy

-   **Prototype**: 3 sites × 12 months (mock data), test UI control rendering
-   **Performance**: Benchmark 100 sites × 12 months (1,200 features)—measure render time, browser memory
-   **Integration**: Episode analysis (48 hours × 3 sites, hourly data)—validate use case works end-to-end
-   **Fallback**: Test with sftime uninstalled—confirm graceful degradation to sf
-   **Regression**: Annual maps (existing tests) pass unchanged

### Reference Materials

-   Temporal control code: `inst/controls/roller-menu.html`, `.css`, `.js`
-   Current temporal filtering: `generate_map_layers()` filters by `year_str` (R/quickmap.R:1576-1581)
-   sftime documentation: [Introduction to sftime](https://r-spatial.github.io/sftime/articles/sftime.html)
-   Leaflet performance: [Leaflet marker clustering](https://github.com/Leaflet/Leaflet.markercluster)

------------------------------------------------------------------------

## v0.9.5: Performance Optimization + Production Readiness (Weeks 7-8)

### Problem Statement

Sub-annual features (v0.9.4) work in prototype but need production hardening: performance optimization (marker clustering, lazy loading), user-facing warnings (feature count limits), external validation (local authority + researcher testing), comprehensive documentation for v1.0 handoff. Current code assumes \<10k features—sub-annual exceeds this. Need progressive disclosure strategy to prevent unusable maps.

### Goals

1.  Implement performance safeguards for high feature counts
2.  External user testing validates real-world workflows
3.  Comprehensive documentation for v1.0 extraction
4.  Finalize API surface for CRAN release

### Requirements

**Performance**: - Marker clustering scales with temporal resolution: - Annual: Cluster if \>50 sites - Monthly: Cluster if \>20 sites - Daily: Cluster if \>10 sites - Hourly: Always cluster (or block entirely) - Progressive disclosure: - Daily \>1,000 features: Warning + recommend temporal subsetting - Hourly \>500 features: Block with error unless `force = TRUE` parameter - Lazy loading for large datasets (load markers on-demand as user pans/zooms)

**User testing**: - 5 external users (mix: local authority officers, academic researchers) - Test workflows: - Annual reporting (existing use case—should be unchanged) - Monthly seasonal patterns (12 months, 20 sites) - Episode analysis (48 hours, 5 sites) - Multi-network overlay (AURN + LAQN + diffusion tubes)

**Documentation**: - Updated vignettes: OpenAir integration, sub-annual temporal features - Function documentation (roxygen2) complete for all exported functions - NEWS.md: Comprehensive v0.9.1 → v0.9.5 changelog - Architecture diagram: Data flow from OpenAir import → map output

### Constraints

-   Annual workflow must remain simple (no new required parameters)
-   Sub-annual features are **advanced use**—don't complicate basic API
-   Performance optimizations shouldn't break existing maps
-   External testing limited to 2 weeks—must have clear test protocols

### Success Criteria

-   [ ] Marker clustering working for all temporal resolutions
-   [ ] Warning system tested: Daily 2,000 features shows clear warning message
-   [ ] Block system tested: Hourly 1,000 features blocked with helpful error
-   [ ] 5 external users complete test protocols, report issues
-   [ ] All 14 existing test scripts pass
-   [ ] Documentation complete: 3 vignettes, all functions documented
-   [ ] Performance benchmarks documented: 100 sites × N temporal units, render times

### Dependencies

-   **Requires**: v0.9.4 (sub-annual features must exist to optimize)
-   **Blocks**: v1.0 (production release)

### Investigation Questions for Engineer

1.  **Clustering library**: Use leaflet.markercluster plugin or custom solution? Integration path?
2.  **Feature counting**: Where to count features—converter output, layer creation, or render time? Trade-offs?
3.  **User override**: `force = TRUE` for hourly—how to document safety/risk? What's safe upper limit?
4.  **Memory profiling**: What's actual browser memory usage for 10k vs 50k features? Real limits?
5.  **Testing infrastructure**: How to automate visual regression testing (screenshot comparison)?

### Testing Strategy

-   **Performance**: Benchmark suite (50/100/200 sites × annual/monthly/daily)
-   **Load testing**: Generate 10k feature map, measure browser memory + render time
-   **User testing**: Structured protocols with specific tasks, collect feedback via survey
-   **Regression**: All existing tests + new sub-annual tests
-   **Documentation**: Test all code examples in vignettes (ensure they run)

### Deliverables

-   Working code (v0.9.5 tagged release)
-   3 vignettes: (1) Basic usage, (2) OpenAir integration, (3) Sub-annual features
-   User testing report: Summary of 5 users' feedback, issues identified
-   Performance benchmarks: Table of render times by feature count
-   NEWS.md: Complete v0.9.1 → v0.9.5 changelog
-   Architecture document: System diagram + design decisions

------------------------------------------------------------------------

## Technical Research Summary

### R-Spatial Ecosystem

-   **sf (1.0-23)**: Universal spatial vector format—proven, stable
-   **sftime (0.3.1)**: Optional for sub-annual—CRAN-stable, 125 commits, 1 open issue, production-ready despite pre-v1.0
-   **openairmaps**: Uses sf + date column (NOT sftime)—validates quickmap can work without sftime dependency
-   **leaflet.extras2**: TimeDimension plugin incompatible with POSIX dates—justifies quickmap's custom controls

### OpenAir Integration Patterns

-   **Data format**: `data.frame(date=POSIXct, site=character, code=character, pollutant=numeric)`
-   **Aggregation**: `timeAverage(avg.time="year"|"month"|"day"|"hour", data.thresh=75)` handles missing data correctly
-   **Metadata**: `importMeta(source, all=TRUE)` provides lat/lon, requires join with temporal data
-   **Networks**: AURN (sparse, national), LAQN (dense, London), SAQN (Scotland), WAQN (Wales)

### QuickMap's Differentiation

**Unique capability**: Temporal animation of monitoring network data with production-ready output.

Not: General spatial viewer (mapview), thematic mapper (tmap), analysis platform (openairmaps).

Is: Production tool for local government air quality reporting + research visualization endpoint.

------------------------------------------------------------------------

## Open Questions for Engineer

### Architecture

1.  Should layer configs be R lists (current pattern) or formalized R6 classes?
2.  Where's the right abstraction boundary: data loading vs layer creation vs rendering?
3.  sftime: Required dependency or optional enhancement? (Recommendation: optional)

### Performance

4.  Real-world Leaflet limits: What feature counts cause performance issues in testing?
5.  Marker clustering: Essential or optional? At what thresholds?

### UI/UX

6.  Sub-annual controls: Best UI pattern for month/day/hour selection?
7.  Warning vs blocking: Where's the line for "too many features"?

### Testing

8.  How to automate visual regression testing (maps look correct)?
9.  External user testing: What's realistic scope for 2-week window?

### Dependencies

10. sftime: When does sf + date column suffice vs needing explicit sftime object?

------------------------------------------------------------------------

## Success Metrics (Overall v0.9.1 → v0.9.5)

### Functional

-   [ ] AURN + LAQN data overlays on existing layers with distinct icons
-   [ ] 4+ networks render simultaneously without code changes
-   [ ] Monthly aggregations work for episode analysis use case
-   [ ] Annual maps unchanged from v0.9.1 (backward compatibility)

### Performance

-   [ ] 100 sites × 5 years (annual): \<30 seconds render
-   [ ] 100 sites × 12 months: \<10 seconds render
-   [ ] 10 sites × 365 days: \<20 seconds render (with warnings)

### Code Quality

-   [ ] Reduced code complexity (fewer switch statements)
-   [ ] All existing tests pass
-   [ ] New tests cover: layer configs, converter, sub-annual rendering

### Documentation

-   [ ] 3 comprehensive vignettes
-   [ ] All exported functions documented (roxygen2)
-   [ ] Architecture decisions recorded

### Production Readiness

-   [ ] 5 external users validate workflows
-   [ ] No breaking changes to existing user scripts
-   [ ] Clear migration path to v1.0 (CRAN release)
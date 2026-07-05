# quickmap

> Quick air quality maps for UK local authorities

QuickMap creates interactive Leaflet maps and static JPG exports showing pollution data (NO2, PM2.5) overlaid with school locations and borough boundaries. Designed for local government air quality reporting.

## Features

- **Interactive HTML maps** with year-based time controls
- **Static JPG export** for reports and presentations
- **Multiple data sources**: Diffusion tubes (CSV) + sensor networks (RData)
- **Flexible styling**: HTML banners and legends, customizable colors
- **OpenAir-compatible**: Follows OpenAir R package design patterns

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("ngnrfsk/241122-quickmap")
```

## Quick Start

```r
library(quickmap)

# Create interactive map
map <- create_pollution_map(
  diffusion_tube_file = "path/to/tubes.csv",
  sensor_file = "path/to/sensors.Rdata",
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = c(2022, 2023, 2024),
  output_file = "wandsworth_no2.html",
  styling_type = "html",
  title = "Wandsworth NO2 Annual Mean 2022-2024"
)

# Export as static image
map_image <- create_pollution_map(
  diffusion_tube_file = "path/to/tubes.csv",
  sensor_file = "path/to/sensors.Rdata",
  boroughs = "Wandsworth",
  pollutant = "no2",
  years = 2024,
  export_image = c(1920, 1080),  # Width x Height
  output_file = "wandsworth_no2.html",
  styling_type = "html"
)
```

## Documentation

- **Getting Started**: See `inst/examples/create_all_borough_maps.R` for complete examples
- **Migration Guide**: See `vignettes/MIGRATION_EXAMPLE_v0.9.0.md` for v0.8.x → v0.9.0 migration
- **Parameter Reference**: See `dev/reference/PARAMETER_REFERENCE.md`
- **Style Guide**: See `dev/reference/style_guide.md`

## Current Version: 0.9.0

**Major changes in v0.9.0** (breaking):
- Simplified from 21 to 14 parameters (33% reduction)
- OpenAir-style parameter naming (intent-based, not implementation-based)
- Merged related parameters (image export, title, styling)
- Removed leaflet controls (HTML-only styling system)

See `vignettes/v0.9.0_parameter_changes.md` for complete changelog.

## Development

```r
# Run tests
devtools::test()

# Check package
devtools::check()

# Build package
devtools::build()
```

## License

MIT

## Author

Iarla Kilbane-Dawe

# QuickMap Function Dependency Graph

## Entry Point
```
create_pollution_map()
├── load_spatial_data_sources()
│   ├── load_data_file()
│   │   ├── load_rdata_file()
│   │   │   └── process_oa_data()
│   │   │       └── validate_oa_data()
│   │   └── import_csv_data()
│   │       └── transform_to_wgs84()
│   ├── get_temporal_data()
│   │   └── transform_to_wgs84()
│   └── transform_to_wgs84()
├── get_boundary_sf()
├── load_theme()
│   ├── get_default_theme()
│   └── load_yaml_config()
├── load_colour_scale()
│   └── load_yaml_config()
├── determine_years_and_viewport()
│   └── create_vignette_overlay()
├── get_measurement_layers()
│   └── validate_and_fix_icon_shape()
├── generate_map_layers()
│   ├── create_base_map()
│   ├── add_boundary_polygons()
│   ├── get_layer_year_data()
│   ├── prepare_generic_layer_data()
│   │   └── generate_marker_labels()
│   └── add_layer()
│       ├── create_generic_icons()
│       │   ├── get_icon_shape_config()
│       │   └── assign_colour()
│       │       └── convert_colors_to_hex()
│       └── generate_marker_labels()
├── add_map_controls()
└── finalize_and_save_map()
    ├── parse_export_params()
    ├── save_html_and_style()
    │   ├── build_banner_css()
    │   │   └── lighten_color()
    │   ├── build_legend_css()
    │   │   ├── lighten_color()
    │   │   └── get_contrast_text_color()
    │   ├── load_roller_menu_control()
    │   │   └── apply_template_replacements()
    │   ├── load_layer_cache_js()
    │   ├── inject_banner_legend_controls()
    │   │   └── generate_legend_html()
    │   │       ├── get_colour_legend()
    │   │       ├── parse_legend_label()
    │   │       ├── calculate_max_range_width()
    │   │       ├── get_symbol_for_index()
    │   │       └── lighten_color()
    │   └── add_year_and_static_layers()
    └── (webshot2 for image export)
```

## OpenAir Integration Functions
```
get_openair_metadata()
└── (uses session cache .openair_metadata_cache)

clear_openair_metadata_cache()

convert_openair_to_spatial()
├── validate_oa_data()
└── process_oa_data()
```

## Utility Functions
```
get_package_dir()
read_template_file()
apply_template_replacements()
show_borough_colours()
get_data_maximum()
```

## External Dependencies

### R Packages
- **leaflet**: Interactive mapping
- **sf**: Spatial data handling
- **dplyr**: Data manipulation
- **leaflegend**: Custom legend controls (makeSymbolsSize, colorFactor)
- **tidyr**: Data reshaping (pivot_longer)
- **lubridate**: Date handling
- **webshot2**: Static image export
- **htmlwidgets**: Widget saving (saveWidget)
- **htmltools**: HTML manipulation
- **leaflet.extras**: Additional leaflet controls (vignette)
- **zeallot**: Multiple assignment (%<-%)
- **openair**: Air quality data (importKCL, importUKAQ, importMeta)

### External Files (inst/)
- **inst/config/scales/*.yaml**: Color scale definitions
- **inst/themes/*.yaml**: Theme configuration
- **inst/controls/roller-menu.{html,css,js}**: Year control UI
- **inst/banner/banner.css**: Banner template
- **inst/legend/legend.css**: Legend template

## Data Flow

### Input Sources
```
Data Sources
├── CSV Files (Diffusion Tubes)
│   ├── Temporal: Year columns (2018, 2019, etc.)
│   └── Static: No year columns (e.g., schools with Level column)
├── RData Files (Sensors, OpenAir format)
│   └── dataOAformat object (siteCode, year, pollutant, lat, lon)
└── sf Objects (Direct spatial data)
```

### Processing Pipeline
```
1. load_spatial_data_sources()
   ├── Auto-detect temporal vs static
   ├── Transform to WGS84
   └── Pivot temporal data to long format

2. get_measurement_layers()
   ├── Detect static (no year_str column)
   ├── Assign symbols (solid for temporal, non-solid for static)
   └── Build layer configs

3. generate_map_layers()
   ├── Loop through years
   ├── Filter data by year and borough
   ├── Create icons with colors
   └── Add to map with labels

4. finalize_and_save_map()
   ├── Inject banner, legend, controls
   ├── Save HTML
   └── Optional: Export image
```

## Symbol Assignment Logic

### Auto-Detection (v0.9.3+)
```
Temporal Data (has year_str column)
└── Solid Symbols: circle, rect, triangle, diamond, stadium, down-triangle, solid-circle-sm, solid-circle-md

Static Data (no year_str column)
└── Non-Solid Symbols: simple-plus, simple-cross, cross-rect, simple-star, plus-circle, plus-rect, cross-circle
```

### Color Assignment
```
Solid Symbols
├── fillColor = pollutant scale colors
└── color = "black" (stroke)

Non-Solid Symbols
├── color = categorical/pollutant colors (stroke is visible)
└── fillColor = same (but not visible)

Static with Level Column
└── Categorical colors: Primary=#32CD32, Secondary=#1E90FF
```

## Critical Code Sections

### Line Ranges
- **1-30**: Package loading and constants
- **82-187**: OpenAir metadata cache system
- **190-410**: OpenAir to spatial converter
- **413-632**: Data loading and transformation
- **634-910**: Color scales and theming
- **911-1489**: UI generation (legend, banner, controls)
- **1502-1612**: Symbol validation and icon creation
- **1614-1940**: Layer configuration and generation
- **1942-2196**: Map rendering loop
- **2200-2391**: Main entry point (create_pollution_map)

## Version History Notes
- **v0.9.2**: Layer generalization, function naming cleanup
- **v0.9.3**: OpenAir converter, YAML config removal, type-aware symbol defaults

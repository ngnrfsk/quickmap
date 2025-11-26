# Configuration Files


## Data Source Configuration Files

QuickMap v0.9.2+ uses an enhanced data source configuration meta data

## Overview

Data source configurations define monitoring network characteristics and enable:
- Icon shape selection for map markers
- Network metadata storage (temporal resolution, pollutants, providers)
- Future OpenAir API integration
- Data quality and capability validation

## Configuration File Location

```
inst/config/data_sources/
├── dt_sites.yaml       # Diffusion tubes
├── bl_nodes.yaml       # Breathe London sensors
├── schools.yaml        # Schools (static layer)
└── aurn.yaml           # AURN network
```

## Configuration Structure

### Required Fields

```yaml
id: network_id              # Unique identifier (matches filename without .yaml)
label: "Network Name"       # Human-readable display name
icon_shape: circle          # Marker shape on map
static: false               # true for static layers, false for temporal data
```

### Network Metadata Fields

```yaml
# Temporal characteristics
min_period: hourly                    # Minimum temporal resolution
available_aggregations:               # Supported time aggregations
  - hourly
  - daily
  - monthly
  - annual

# Pollutants
pollutants: [no2, pm25, pm10]        # Measured pollutants (empty for static)

# Data access
openair_import_function: importAURN   # OpenAir R function name (or null)
monitoring_type: continuous_automatic # Network classification
provider: "DEFRA/Ricardo"             # Data provider attribution
```

## Icon Shapes

Valid icon shapes (user-facing):
- **circle** - Diffusion tubes (default)
- **diamond** - Sensor networks
- **cross** - Schools, points of interest
- **square** - Reference networks (auto-converts to `rect` for leaflegend)
- **triangle** - Custom networks
- **star** - Custom networks
- **plus** - Custom networks

**Note**: "square" automatically converts to "rect" for leaflegend compatibility with a warning.

## Monitoring Types

Classification of monitoring network methodology:

| Type | Description | Typical Resolution | Examples |
|------|-------------|-------------------|----------|
| `passive` | Passive samplers, no power required | Monthly/bi-weekly | Diffusion tubes |
| `continuous_automatic` | Reference-grade continuous monitors | Hourly | AURN, LAQN |
| `low_cost_sensor` | Calibrated low-cost sensor networks | Minute to hourly | Breathe London |
| `static_poi` | Static points of interest | N/A | Schools, hospitals |

## Temporal Resolution Reference

### Diffusion Tubes
- **Min period**: Monthly (exposed for 2-4 weeks)
- **Aggregations**: Monthly, annual only
- **Use case**: Annual mean compliance assessment
- **Limitation**: Cannot assess short-term exceedances

**Sources**:
- [LAQM Diffusion Tubes Overview](https://laqm.defra.gov.uk/air-quality/air-quality-assessment/diffusion-tubes-overview/)
- [Use of passive diffusion tubes (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC2838214/)

### AURN (Automatic Urban and Rural Network)
- **Min period**: Hourly (15-minute for SO2)
- **Aggregations**: 15_min, hourly, 8_hour, 24_hour, daily, monthly, annual
- **Pollutants**: NO2, PM2.5, PM10, O3, SO2, CO
- **Data capture**: ~92% average (2024)
- **Network size**: 184 sites (2024)
- **Provider**: DEFRA/Ricardo

**Sources**:
- [AURN Network Info (UK-AIR)](https://uk-air.defra.gov.uk/networks/network-info?view=aurn)
- [AURN Technical Report 2024](https://uk-air.defra.gov.uk/assets/documents/reports/cat05/2509300426_2024_AURN_QAQC_Annual_Technical_Report_Issue_1.pdf)
- [OpenAir Book - UK Air Quality Data](https://openair-project.github.io/book/sections/data-access/UK-air-quality-data.html)

### LAQN (London Air Quality Network)
- **Min period**: ~15 minutes (sampling interval)
- **Aggregations**: Hourly averages presented publicly
- **Pollutants**: NO2, PM10, PM2.5, O3, SO2, CO (limited)
- **Network size**: 100+ sites across London boroughs
- **Provider**: Imperial College London ERG
- **OpenAir function**: `importImperial()`

**Sources**:
- [London Air Quality Network](https://www.londonair.org.uk/)
- [LAQN Report 2021](https://www.londonair.org.uk/london/reports/2021_LAQN_Report.pdf)
- [LAQN Network Info (UK-AIR)](https://uk-air.defra.gov.uk/networks/network-info?view=aln)

### Breathe London
- **Min period**: 1 minute (Airly Aura Plus sensors)
- **Original pilot**: 10-second sampling, 1-15 minute averages (AQMesh)
- **Pollutants**: NO2, PM2.5
- **Network type**: Low-cost sensor network (calibrated)
- **Provider**: EDF + Imperial College + Airly
- **OpenAir function**: `importImperial()` (via LAQN infrastructure)

**Sources**:
- [Breathe London Methodology](https://breathelondon.edf.org/methodology.html)
- [Breathe London Airly Package](https://airly.org/en/solutions/breathe-london-package/)
- [Breathe London Network (Imperial)](https://www.imperial.ac.uk/school-public-health/environmental-research-group/research/measurement/breathe-london/)

## Example Configurations

### Passive Monitoring (Diffusion Tubes)

```yaml
id: dt_sites
label: "Diffusion Tubes"
icon_shape: circle
static: false

min_period: monthly
available_aggregations: [monthly, annual]
pollutants: [no2]
openair_import_function: null
monitoring_type: passive
provider: "Local Authority"
```

### Continuous Automatic (AURN)

```yaml
id: aurn
label: "AURN Network"
icon_shape: square
static: false

min_period: hourly
available_aggregations: [hourly, daily, monthly, annual, 15_min, 8_hour, 24_hour]
pollutants: [no2, pm25, pm10, o3, so2, co]
openair_import_function: importAURN
monitoring_type: continuous_automatic
provider: "DEFRA/Ricardo"
```

### Low-Cost Sensor (Breathe London)

```yaml
id: bl_nodes
label: "Breathe London Sensors"
icon_shape: diamond
static: false

min_period: minute
available_aggregations: [minute, hourly, daily, monthly, annual]
pollutants: [no2, pm25]
openair_import_function: importImperial
monitoring_type: low_cost_sensor
provider: "EDF + Imperial College + Airly"
```

### Static Layer (Schools)

```yaml
id: schools
label: "Schools"
icon_shape: cross
static: true

min_period: null
available_aggregations: []
pollutants: []
openair_import_function: null
monitoring_type: static_poi
provider: "Local Authority"
```

## Using Configurations in Code

### Option 1: Use Config Files (Default)

```r
create_pollution_map(
  data_sources = list(dt_file, bl_file, school_file),
  data_configs = c("dt_sites", "bl_nodes", "schools"),
  boroughs = "Merton",
  pollutant = "no2"
)
```

### Option 2: Override Icon Shapes

```r
create_pollution_map(
  data_sources = list(dt_file, bl_file, school_file),
  data_configs = c("dt_sites", "bl_nodes", "schools"),
  icon_shapes = c("star", "plus", "triangle"),  # Overrides config files
  boroughs = "Merton",
  pollutant = "no2"
)
```

### Option 3: Create New Config Programmatically

```r
write_data_source_config(
  id = "laqn_sites",
  label = "LAQN Monitoring Sites",
  icon_shape = "diamond",
  static = FALSE,
  min_period = "hourly",
  available_aggregations = c("hourly", "daily", "monthly", "annual"),
  pollutants = c("no2", "pm10", "pm25", "o3"),
  openair_import_function = "importImperial",
  monitoring_type = "continuous_automatic",
  provider = "Imperial College London ERG"
)
```

## Future Capabilities

The enhanced metadata enables future features:

1. **Pollutant Validation**
   ```r
   # Warn if user requests PM2.5 from diffusion tubes
   if (pollutant == "pm25" && "pm25" %in% config$pollutants == FALSE) {
     warning("Network ", config$id, " does not measure ", pollutant)
   }
   ```

2. **Automatic Time Aggregation**
   ```r
   # Select appropriate aggregation based on network capabilities
   if (requested_period < config$min_period) {
     warning("Requested period ", requested_period,
             " exceeds minimum resolution ", config$min_period)
   }
   ```

3. **OpenAir API Integration**
   ```r
   # Direct import from OpenAir
   if (!is.null(config$openair_import_function)) {
     data <- do.call(config$openair_import_function,
                     list(site = site_code, year = year))
   }
   ```

4. **Data Quality Indicators**
   - Display network characteristics in map legends
   - Show temporal resolution limitations
   - Provider attribution

## Related Documentation

- [OpenAir Package Documentation](https://openair-project.github.io/openair/)
- [DEFRA UK-AIR](https://uk-air.defra.gov.uk/)
- [London Air Quality Network](https://www.londonair.org.uk/)
- [Breathe London](https://www.breathelondon.org/)

---

**Version**: QuickMap v0.9.2+
**Last Updated**: 2025-11-26

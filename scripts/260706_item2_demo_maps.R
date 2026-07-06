# Demonstration maps for roadmap item 2 (characterization test net).
# Run from the repo root: Rscript scripts/260706_item2_demo_maps.R
# Writes dated maps to aq_maps/ — compare against aq_maps/baseline_260705_signed_off/.
library(quickmap)

# annual multi-year with schools and labels (same fixture the tests pin)
create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "no2",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "260706_item2_annual_merton.html",
  title = "Item 2 demo: Merton NO2 2020-2022",
  styling_type = "html",
  vignette = TRUE,
  marker_labels = "labels"
)

# sub-annual (15-minute) map
create_pollution_map(
  data_sources = list("mock_15min_data.Rdata"),
  boroughs = "Westminster",
  pollutant = "no2",
  colour_scale = "who_no2",
  output_file = "260706_item2_subannual_westminster.html",
  title = "Item 2 demo: Westminster NO2 15-min",
  styling_type = "html"
)

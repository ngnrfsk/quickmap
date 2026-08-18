# Load the installed package (devtools::install() first if not installed)
if (Sys.getenv("DATA_PATH") == "") Sys.setenv(DATA_PATH = "~/Coding/Library/data")
library(quickmap)

# ==============================================================================
# MAP 1: Richmond NO2 (New API: data_sources + data_configs)
# ==============================================================================
map1_richmond_no2 <- create_pollution_map(
  data_sources = list(
    "richmond_1993_2024-1.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  data_ids = NULL,
  boroughs = "Richmond",
  pollutant = "no2",
  #  display_times = 2022:2024,
  colour_scale = "stripes_no2",
  output_file = "debug_0926b_richmond_dt_bl.html",
  output_dir = "aq_maps",
  title = "debug_0926b - Richmond full data (New API)",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  symbol_labels = TRUE, # Auto-hide labels
  boundary_labels = FALSE
)

map2_merton_pm25 <- create_pollution_map(
  data_sources = list(
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  data_ids = NULL,
  boroughs = "Merton",
  pollutant = "pm25",
  display_times = 2022:2024,
  colour_scale = "gla_pm25",
  output_file = "debug_0926b_merton_pm25_2018_2024_dt_bl.html",
  output_dir = "aq_maps",
  title = "debug_0926b LB Merton Annual Mean PM2.5 (New API)",
  theme_file = "inst/themes/wandsworth.yaml",
  styling_type = "html", # HTML banner + legend
  # vignette = TRUE,
  symbol_labels = TRUE, # Auto-hide labels
  boundary_labels = FALSE
)

theme <- load_theme("inst/themes/wandsworth.yaml")

map3_merton_no2_image <- create_pollution_map(
  data_sources = list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  data_ids = NULL,
  boroughs = "Merton",
  pollutant = "no2",
  display_times = 2020:2022,
  colour_scale = "who_no2",
  output_file = "debug_0926b_image_merton_no2_2018_2024_dt_bl.html",
  output_dir = "aq_maps",
  title = "debug_0926b LB Merton Annual Mean NO2 with Image Export (New API)",
  styling_type = "html", # HTML banner + legend
  vignette = TRUE,
  export_image = TRUE,
  symbol_labels = TRUE, # Auto-hide labels
  banner_colour = theme$palette$green,
  boundary_labels = FALSE
)

# ==============================================================================
#### stop here!!!!! PRODUCTION CODE BELOW

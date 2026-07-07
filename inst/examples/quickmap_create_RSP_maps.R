# Create maps for Merton, Richmond and Wandsworth
# NO2 maps use CSV + BL data, PM2.5 maps use BL data only
# Merton includes schools overlay
#
# Migrated to the quickmap() API (roadmap item 8, v0.9.8): layers are plain
# file paths (layer names auto-generate from filenames; shapes auto-assign
# by data type: tubes circle, sensors diamond, schools cross).

library(quickmap)

# ==============================================================================
# MAP 1: Merton NO2 (CSV + BL data with schools) 2018-2024
# ==============================================================================
map1_merton_no2 <- quickmap(
  list(
    "merton_dt_2018_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  colour_scale = "who_no2",
  theme_file = system.file("themes", "airstat.yaml", package = "quickmap"),
  output_file = "merton_no2_2018_2024_dt_bl_airstat.html",
  title = "LB Merton Annual Mean NO2, 2018-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#5F3E94", # Merton purple
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 2: Wandsworth NO2 (CSV + BL data with schools) 2017-2024
# ==============================================================================
map2_wandsworth_no2 <- quickmap(
  list(
    "wandsworth_2017_2024_no_labels.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_wandsworth.csv"
  ),
  boroughs = "Wandsworth",
  colour_scale = "lbw_no2",
  output_file = "wandsworth_no2_2017_2024_dt_bl_schools.html",
  title = "LB Wandsworth Annual Mean NO2, 2017-2024. ✖ Schools. Sensors: ● Diffusion Tubes ◆ Breathe London.",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00549F", # Wandsworth blue
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 3: Richmond NO2 (CSV + BL data) 1993-2024
# ==============================================================================
map3_richmond_no2 <- quickmap(
  list(
    "richmond_1993_2024.csv",
    "bl_imperial_annualised_2021_2025_with_missing.Rdata"
  ),
  boroughs = "Richmond",
  colour_scale = "lbrut_no2",
  output_file = "richmond_no2_1993_2024_dt_bl.html",
  title = "LB Richmond Annual Mean NO2, 1993-2024. Sensors: ● Diffusion Tubes ◆ Breathe London",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00824B", # Richmond green
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 4: Merton PM2.5 (BL data only with schools) 2021-2025
# ==============================================================================
map4_merton_pm25 <- quickmap(
  list(
    "bl_imperial_annualised_2021_2025_with_missing.Rdata",
    "schools_Merton.csv"
  ),
  boroughs = "Merton",
  pollutant = "pm25",
  colour_scale = "gla_pm25",
  output_file = "merton_pm25_2022_2024_bl.html",
  title = "LB Merton Annual Mean PM2.5, 2022-2024. ✖ Schools. Sensors: ◆ Breathe London.",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#5F3E94", # Merton purple
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 5: Wandsworth PM2.5 (BL data only) 2021-2025
# ==============================================================================
map5_wandsworth_pm25 <- quickmap(
  "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  boroughs = "Wandsworth",
  pollutant = "pm25",
  colour_scale = "gla_pm25",
  output_file = "wandsworth_pm25_2021_2025_bl.html",
  title = "LB Wandsworth Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00549F", # Wandsworth blue
  boundary_labels = FALSE
)

# ==============================================================================
# MAP 6: Richmond PM2.5 (BL data only) 2021-2025
# ==============================================================================
map6_richmond_pm25 <- quickmap(
  "bl_imperial_annualised_2021_2025_with_missing.Rdata",
  boroughs = "Richmond",
  pollutant = "pm25",
  colour_scale = "gla_pm25",
  output_file = "richmond_pm25_2022_2024_bl.html",
  title = "LB Richmond Annual Mean PM2.5, 2022-2024. Sensors: ◆ Breathe London",
  vignette = TRUE,
  marker_labels = "labels",
  banner_colour = "#00824B", # Richmond green
  boundary_labels = FALSE
)

library(tidyverse)
library(lubridate)
library(jsonlite)
library(janitor)
library(knitr)
library(terra)
library(leaflet)
library(mapview)

# This document explores the Landsat Collection 2 Level-3 Dynamic Surface Water Extent (DSWE) metadata contained in the JSON file:
# LC09_CU_002006_20251110_20251117_02_DSWE.json
# 
# Two major components:
#   
#  - TILE_METADATA: Contains metadata about this tile
# 
# - SCENE_METADATA: Details about individual observations
# 
# 
# DSWE is a Level-3 science product derived from Landsat U.S. Analysis Ready Data (ARD) Surface Reflectance. It classifies each pixel into different surface-water states (high-confidence water, moderate-confidence water, partial surface water, and non-water) and provides additional layers for masks and terrain shading. 
# 
# The JSON metadata describes:
#   
# - File names and data types for each DSWE raster layer
# 
# - Spatial reference and tile extent
# 
# - Value ranges and fill values for each DSWE band
# 
# - Processing software versions and acquisition metadata 
# 
# We then connect this to the concept of the Surface Water Index of Permanence (SWIPe), which uses a time series of DSWE rasters to quantify how often each pixel is observed as water.

json_path <- "data-raw/dswe/LC09_CU_002006_20251110_20251117_02_DSWE.json"
json_data <- fromJSON(json_path)

# Inspect top-level structure
str(json_data, max.level = 1)
names(json_data)

# Helper to explore nested components
print_component_structure <- function(data, max.level = 2) {
  if (is.list(data)) {
    for (name in names(data)) {
      cat("\n==== Component:", name, "====\n")
      print(str(data[[name]], max.level = max.level))
    }
  }
}

print_component_structure(json_data$LANDSAT_ARD_METADATA_FILE, max.level = 2)

# KEY METADATA
meta <- json_data$LANDSAT_ARD_METADATA_FILE
tile_md <- meta$TILE_METADATA
scene_md <- meta$SCENE_METADATA

# Convert TILE_METADATA tables to clean 2-column data frames
as_table <- function(x) {
  tibble(
    field = names(x),
    value = unlist(x)
  )
}

product_contents  <- as_table(tile_md$PRODUCT_CONTENTS)
image_attributes  <- as_table(tile_md$IMAGE_ATTRIBUTES)
projection_info   <- as_table(tile_md$PROJECTION_ATTRIBUTES)
dswe_parameters   <- as_table(tile_md$LEVEL3_DYNAMIC_SURFACE_WATER_EXTENT_PARAMETERS)

# View tables
kable(product_contents, caption = "Product Contents")
kable(image_attributes, caption = "Image Attributes")
kable(projection_info, caption = "Projection Information")
kable(dswe_parameters, caption = "DSWE Band Parameters")

# Also convert SCENE_METADATA
scene_tbl <- as_table(scene_md)
kable(scene_tbl, caption = "Scene Metadata")

# LOAD DSWE RASTER (INWAM) ----

prod <- tile_md$PRODUCT_CONTENTS
inwam_filename <- basename(prod$FILE_NAME_INWAM)

# Directory where TIF files live
dswe_dir <- "data-raw/dswe/"

tif_path <- file.path(dswe_dir, inwam_filename)
if (!file.exists(tif_path)) stop("INWAM raster not found: ", tif_path)

r_inwam <- rast(tif_path)
r_inwam

# REPROJECT TO WGS84 FOR LEAFLET ----
r_ll <- project(r_inwam, "EPSG:4326")

# COLOR PALETTE (CATEGORICAL)
dswe_colors <- c(
  "0"   = "white",      # Not water
  "1"   = "blue",       # High confidence water
  "2"   = "deepskyblue",
  "3"   = "lightblue",
  "4"   = "cyan",
  "9"   = "gray60",     # Cloud/shadow
  "255" = "black"       # Fill
)

pal <- colorFactor(
  palette = dswe_colors,
  domain  = as.numeric(names(dswe_colors))
)

# MAP
leaflet() |> 
  addProviderTiles("Esri.WorldImagery") |> 
  addRasterImage(r_ll, colors = pal, opacity = 0.7) |> 
  addLegend(pal = pal, values = as.numeric(names(dswe_colors)),
            title = "DSWE Classes",
            position = "bottomright")

# STATIC PLOT 
plot(r_inwam, col = dswe_colors, main = "DSWE INWAM Raster")

# GGPLOT RASTER VISUALIZATION
r_df <- as.data.frame(r_inwam, xy = TRUE)
colnames(r_df)[3] <- "class"

r_df$class <- as.factor(r_df$class)

ggplot(r_df) +
  geom_raster(aes(x = x, y = y, fill = class)) +
  scale_fill_manual(values = dswe_colors) +
  labs(title = "DSWE INWAM (Categorical Water States)",
       fill = "Class") +
  coord_equal() +
  theme_minimal()



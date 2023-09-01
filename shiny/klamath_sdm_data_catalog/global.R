library(shiny)
library(tidyverse)
library(DT)
library(sf)
library(leaflet)
library(bslib)

options(scipen=999)

rest_proj <- readxl::read_excel(here::here("shiny", "klamath_sdm_data_catalog", "data", "Preliminary Data Catalog.xlsx"), sheet = "Habitat Restoration Projects") |> 
  select(`Project Name`, `Project Benefit`, `Recovery Domains`, Category, Year, Status, Grantee, HUC, Resource) |>
  mutate(HUC = strsplit(HUC, ";\\s*")) %>%
  tidyr::unnest(HUC) |> 
  mutate(HUC = as.numeric(HUC))

hucs <- sf::read_sf(here::here("shiny", "klamath_sdm_data_catalog", "data", "shapefiles", "WBDHU8_Klamath_Rogue.shp")) |> 
  select(huc8, name) |> 
  rename(HUC = huc8) |> 
  mutate(HUC = as.numeric(HUC)) |> 
  st_transform("+proj=longlat +datum=WGS84 +no_defs") |> st_zm()

all_data <- rest_proj |> left_join(hucs) 

summary_by_watershed <- all_data |> 
  group_by(HUC, name, geometry) |> 
  summarise(n_projects = n()) |> 
  st_as_sf()

js <- function(id){ 
  c("console.log(table);",
    "table.on('click', 'tr', function(){",
    "  var index = this.rowIndex;",
    sprintf("Shiny.setInputValue('%s', index, {priority: 'event'});", id),
    "});"
  )
}


# monitoring data ---------------------------------------------------------

monitoring_data <- read_csv(here::here("shiny", "klamath_sdm_data_catalog", "data", "fish_data_synthesis.csv"))

monitoring_data_hucs <- left_join(monitoring_data, hucs, by = c("subbasin" = "name")) |> 
  filter(!is.na(data_type), !is.na(start))

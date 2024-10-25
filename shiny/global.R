library(shiny)
library(tidyverse)
library(DT)
library(sf)
library(leaflet)
library(bslib)

options(scipen=999)

rest_proj <- readxl::read_excel(here::here("shiny", "data", "Preliminary Data Catalog.xlsx"), sheet = "Habitat Restoration Projects") |> 
  select(`Project Name`, `Project Benefit`, `Recovery Domains`, Category, Year, Status, Grantee, HUC, Resource) |>
  filter(!(Category %in% c("Tribal Capacity", "Planning", "Design", "Unknown/Unspecified"))) |> 
  mutate(Category = case_when(Category == "Salmonid Habitat Restoration and Acquisition" ~ "Restoration", 
                              Category == "Culvert Replacement" ~ "Fish Passage", 
                              Category == 'NA' ~ `Project Benefit`, 
                              .default = as.character(Category)), 
         HUC = strsplit(HUC, ";\\s*"))  |> 
  mutate(Category = ifelse(`Project Name` == "Klamath Tribes Salmon Reintroduction program", "Reintroduction", Category)) |> 
  filter(Category != "NA") |> # removes one row related to off channel watering of an OWEB project 
  tidyr::unnest(HUC) |> 
  mutate(HUC = as.numeric(HUC)) 

hucs <- sf::read_sf(here::here("shiny", "data", "shapefiles", "WBDHU8_Klamath_Rogue.shp")) |> 
  select(huc8, name) |> 
  rename(HUC = huc8,
         Watershed = name) |> 
  mutate(HUC = as.numeric(HUC)) |> 
  st_transform("+proj=longlat +datum=WGS84 +no_defs") |> st_zm()

all_rest_data <- rest_proj |> left_join(hucs) 

js <- function(id){ 
  c("console.log(table);",
    "table.on('click', 'tr', function(){",
    "  var index = this.rowIndex;",
    sprintf("Shiny.setInputValue('%s', index, {priority: 'event'});", id),
    "});"
  )
}


# habitat data ------------------------------------------------------------

hab_data <- readxl::read_excel(here::here( "shiny", "data", "Preliminary Data Catalog.xlsx"), sheet = "Habitat Data") 


# monitoring data ---------------------------------------------------------

monitoring_data <- read_csv(here::here("shiny", "data", "fish_data_synthesis.csv"))

monitoring_data_hucs <- left_join(monitoring_data, hucs, by = c("subbasin" = "Watershed")) |> 
  filter(!is.na(data_type), !is.na(start))

# water data --------------------------------------------------------------
# placeholder for reading in our data needed for the water data tab
# Use the data from flow Rmd that Badhia is working on (save to shiny/data)

# TODO when we merge in temperature data, combine flow and temperature and add a column for data type
flow_data <- read_csv(here::here("shiny", "data", "flow_table.csv")) |> 
  mutate(data_type = "flow",
         value = mean_flow_cfs) |> 
  select(-mean_flow_cfs)

temp_data <- read_csv(here::here("shiny", "data", "temp_data.csv")) |> 
  mutate(data_type = "temperature",
         value = mean_temp_c) |> 
  select(-mean_temp_c)

water_data <- bind_rows(temp_data, flow_data) |> 
  glimpse()

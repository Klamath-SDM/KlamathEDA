library(shiny)
library(tidyverse)
library(DT)
library(sf)
library(leaflet)
library(bslib)

options(scipen=999)

rest_proj <- readxl::read_excel('data/Preliminary Data Catalog.xlsx', sheet = "Habitat Restoration Projects") |> 
  select(`Project Name`, `Project Benefit`, `Recovery Domains`, Category, Year, Status, Grantee, HUC, Resource) |>
  mutate(HUC = strsplit(HUC, ";\\s*")) %>%
  tidyr::unnest(HUC) |> 
  mutate(HUC = as.numeric(HUC))

hucs <- sf::read_sf('data/shapefiles/WBDHU8_Klamath_Rogue.shp') |> 
  select(huc8, name) |> 
  rename(HUC = huc8) |> 
  mutate(HUC = as.numeric(HUC)) |> 
  st_transform("+proj=longlat +datum=WGS84 +no_defs") |> st_zm()

all_data <- rest_proj |> left_join(hucs) 

summary_by_watershed <- all_data |> 
  group_by(HUC, name, geometry) |> 
  summarise(n_projects = n()) |> 
  st_as_sf()

ui <- fluidPage(
  
  theme = bs_theme(
    bootswatch = "yeti"),
  
  div(class = 'outer',
      tags$head(
        includeCSS("styles.css")
      ),
      
      titlePanel("Klamath SDM - Restoration Project Catalog"),

      fluidRow(
        
        column(12,
               leafletOutput("map", height = '500px')
        ),
        
        column(12,
               absolutePanel(
                 top = 70, left = 20, height = "90%", width = 250,
                 h4("Filter by Watershed", style = "color: white;"),
                 # Add your filter inputs here
                 selectInput("watershed", "", choices = unique(hucs$name)),
                 actionButton("apply_filter", "Apply Filter")
               )
        )
       
      ),
      
      hr(),
      
      fluidRow(
        column(12,
               div(style = "height: 400px; overflow-y: scroll;",
                   dataTableOutput("rest_table")
               )
        )
      )
  )
)



# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output$rest_table <- DT::renderDataTable(rest_proj |> select(-`Project Benefit`),
                                        options = list(scrollX = TRUE),
                                        rownames = FALSE)
  
  
  output$map <- renderLeaflet({
    
    color_palette <- colorNumeric(palette = "YlOrRd", domain = c(1, 200))
    
    leaflet(options = leafletOptions(zoomControl = FALSE)) |>
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Map") |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
      addPolygons(data = summary_by_watershed, group = "hucs", popup = ~name,
                  color = "darkgrey", fillColor = ~color_palette(n_projects),
                  fillOpacity = 0.5)  |> 
      addLegend("bottomright", pal = color_palette, values = summary_by_watershed$n_projects,
                title = "Number of Projects")
    
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

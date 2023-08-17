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
  
  titlePanel("Klamath SDM - Restoration Project Catalog"),
  h6("The following restoration projects were aggregated through literature review.
           This dataset is not complete and will be updated as watershed-specific stakeholders
           are engaged in the Klamath SDM process."),
  
  # Sidebar layout
  sidebarLayout(
    sidebarPanel(style = "background-color: #faf9f7;",
                 h4("Filter by Watershed", style = "color: black;"),
                 selectInput("watershed", "", choices = unique(hucs$name)),
                 actionButton("apply_filter", "Apply Filter"),
                 br(),
                 hr(),
                 downloadButton("downloadData", "Download")
                 
    ),
    mainPanel( 
      leafletOutput('map')
    )
  ),
  hr(),
  br(),
  fluidRow(
    column(12,
           div(style = "height: 400px; overflow-y: scroll;",
               dataTableOutput("rest_table")
           )
    )
  )
)

js <- function(id){ 
  c("console.log(table);",
    "table.on('click', 'tr', function(){",
    "  var index = this.rowIndex;",
    sprintf("Shiny.setInputValue('%s', index, {priority: 'event'});", id),
    "});"
  )
}


# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output[["rest_table"]] <- renderDT({
    datatable(rest_proj |> select(-`Project Benefit`), callback = JS(js("t1")),
              options = list(scrollX = TRUE,
                             dom = 't'),
              filter = "top",
              rownames = FALSE)
  })
  
  observeEvent(input[["t1"]], {
    showModal(
      modalDialog(
        
        rest_proj |> slice(input[['t1']]) |> pull(`Project Benefit`)
        
      )
    )
  })
  
  
  output$map <- renderLeaflet({
    
    color_palette <- colorNumeric(palette = "YlOrRd", domain = c(1, 200))
    
    leaflet() |>
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Map") |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
      addPolygons(data = summary_by_watershed, group = "hucs", popup = ~name,
                  color = "darkgrey", fillColor = ~color_palette(n_projects),
                  fillOpacity = 0.5)  |> 
      addLegend("bottomright", pal = color_palette, values = summary_by_watershed$n_projects,
                title = "Number of Projects")
    
  })
  
  
  # Downloadable csv of selected dataset ----
  output$downloadData <- downloadHandler(
    filename = function() {
      paste0('restoration_projects', ".csv")
    },
    content = function(file) {
      write_csv(rest_proj, file)
    }
  )
  
}

# Run the application 
shinyApp(ui = ui, server = server)

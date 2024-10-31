library(shiny)

fluidPage(
  
  theme = bs_theme(
    bootswatch = "yeti"),
  
  titlePanel("Klamath SDM - Data Catalog"),
  
  tabsetPanel(
    tabPanel("Restoration Data",
             titlePanel("Restoration Project Catalog"),
             h6("The following restoration projects were aggregated through literature review.
           This dataset is not complete and will be updated as watershed-specific stakeholders
           are engaged in the Klamath SDM process."), #TODO: update text here
             sidebarLayout(
               sidebarPanel(style = "background-color: #faf9f7;",
                            h4("Filter by Data Type", style = "color: black;"),
                            selectInput("rest_data_type", "", choices = c('All Types', unique(all_rest_data$Category))),
                            h4("Filter by Watershed", style = "color: black;"),
                            selectInput("watershed", "", choices = c('All Watersheds', unique(all_rest_data$Watershed))),
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
    ), 
    tabPanel("Fisheries Data",
             titlePanel("Salmon Monitoring Data Catalog"),
             h6("Data discovery targeting salmon monitoring data was conducted 
                through broad internet searches and literature review. Programs
                collecting data for fisheries population estimates were recorded.
                The majority of this data is not machine-readable and metadata including
                location, timeframe, species, data type, and source were documented.
                Available reports and documentation was downloaded and stored here (INSERT LINK)."),
           sidebarLayout(
             # filter by subbasin, data_type, species_group, timeframe
             sidebarPanel(style = "background-color: #faf9f7;",
                          h4("Filter by Data Type", style = "color: black;"),
                          selectInput("data_type", "", choices = c('All Types', unique(monitoring_data_hucs$data_type))),
                          br(),
                          h4("Filter by Species", style = "color: black;"),
                          selectInput("species", "", choices = c('All Species', unique(filter(monitoring_data_hucs, !is.na(species_group))$species_group))),
                          hr()
                          #downloadButton("downloadData", "Download")
                          
             ),
             mainPanel( 
               leafletOutput('map_monitoring')
             )
           ),
           hr(),
           br(),
           fluidRow(
             column(12,
                    div(style = "height: 400px; overflow-y: scroll;",
                        dataTableOutput("table_monitoring")
                    )
             )
           )
             ),
    tabPanel("Habitat Data",
                      titlePanel("Habitat Data Catalog"),
                      h6("TODO"), #TODO: update text here
                      sidebarLayout(
                        sidebarPanel(style = "background-color: #faf9f7;",
                                     h4("Filter by Data Type", style = "color: black;"),
                                     selectInput("hab_data_type", "", choices = c('All Types', unique(hab_data$data_collection_type))),
                                     h4("Filter by Species", style = "color: black;"),
                                     selectInput("species", "", choices = c('All Species', unique(hab_data$species))),
                                     br(),
                                     hr(),
                                     #downloadButton("downloadData", "Download")
                                     
                        ),
                        mainPanel( 
                          div(style = "height: 400px; overflow-y: scroll;",
                              dataTableOutput("hab_data")
                          )
                        )
                      ),
                      hr(),
                      br()
                      # fluidRow(
                      #   column(12,
                      #          div(style = "height: 400px; overflow-y: scroll;",
                      #              dataTableOutput("hab_data")
                      #          )
                      #   )
                      # )
             ),
    tabPanel("Water Data",
             titlePanel("Water Data Catalog"),
             h6("This catalog summarizes measured flow, temperature, and water quality data collected within the Basin. See",
                tags$a(href = 'https://github.com/Klamath-SDM/KlamathEDA/blob/add-flow-temp-shiny/data-raw/flow_data/explore_flow_gages.Rmd', 
                       "flow Rmd", target = "_blank"), 
                "and",
                tags$a(href = 'https://github.com/Klamath-SDM/KlamathEDA/blob/add-flow-temp-shiny/data-raw/temperature_data/explore_temp_gages.Rmd', 
                       "temp Rmd", target = "_blank"),
                "for more detailed data exploration."),
             sidebarLayout(
               # filter by subbasin, data_type, species_group, timeframe
               sidebarPanel(style = "background-color: #faf9f7;",
                            h4("Filter by Data Type", style = "color: black;"),
                            # TODO we should update the "choices" to use the data object - eg wnique(water_data_catalog$data_type)
                            selectInput("water_data_type", "", choices = c("All Types", unique(water_data$data_type))),
                            br(),
                            h4("Filter by Watershed", style = "color: black;"),
                            # TODO we should update the "choices" to use the data object - eg wnique(water_data_catalog$data_type)
                            selectInput("water_watershed", "", choices = c("All Watersheds", unique(water_data$stream))),
                            hr()
                            #downloadButton("downloadData", "Download")
                            
               ),
               mainPanel( 
                 # update when we have the map ready
                 leafletOutput('map_water')
               )
             ),
             hr(),
             br(),
             fluidRow(
               column(12,
                      div(style = "height: 400px; overflow-y: scroll;",
                      dataTableOutput("table_water")
                      )
               )
             )
    )
  )
)

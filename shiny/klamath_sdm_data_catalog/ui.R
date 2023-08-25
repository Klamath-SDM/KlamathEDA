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
                            h4("Filter by Watershed", style = "color: black;"),
                            selectInput("watershed", "", choices = c('All Watersheds', unique(hucs$name))),
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
    ), 
    tabPanel("Fisheries Data",
             #PLACEHOLDER
             ),
    tabPanel("Habitat Data",
             #PLACEHOLDER
             )
  )
)
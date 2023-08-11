library(shiny)
library(tidyverse)
library(DT)

rest_proj <- readxl::read_excel('data/Preliminary Data Catalog.xlsx', sheet = "Habitat Restoration Projects") |> 
  select(`Project Name`, `Recovery Domains`, Category, Year, Status, Grantee, Watershed, Resource) # `Project Benefit`

# Define UI for application that draws a histogram
ui <- fluidPage(titlePanel("Klamath SDM - habitat restoration project catalog"),
                mainPanel(width = 12,
                          DT::dataTableOutput("mytable")))

# Define server logic required to draw a histogram
server <- function(input, output) {

  output$mytable <- DT::renderDataTable(rest_proj,
                                        options = list(scrollX = TRUE),
                                        rownames = FALSE)
}

# Run the application 
shinyApp(ui = ui, server = server)

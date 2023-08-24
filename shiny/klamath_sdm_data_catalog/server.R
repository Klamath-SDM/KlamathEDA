library(shiny)

function(input, output) {
  
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

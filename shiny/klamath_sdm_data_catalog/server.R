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
  
  # Filter monitoring data based on selections
  selected_monitoring <- reactive({
    if(input$data_type == "All Types" & input$species == "All Species") {
      dat <- monitoring_data_hucs
    }
    else if(input$data_type == "All Types" & input$species != "All Species") {
      dat <- monitoring_data_hucs |> 
        filter(species_group %in% input$species)
    } else if(input$data_type != "All Types" & input$species == "All Species") {
      dat <- monitoring_data_hucs |> 
        filter(data_type %in% input$data_type)
    } else {
    dat <- monitoring_data_hucs |> 
      filter(data_type %in% input$data_type,
             species_group %in% input$species)
    }
    dat
    })
  
  # monitoring data map
  output$map_monitoring <- renderLeaflet({
    
    color_palette <- colorNumeric(palette = "YlOrRd", domain = c(1, 200))
    data <- selected_monitoring() |> 
      group_by(subbasin, HUC, geometry) |> 
      summarize(total_years = sum(n_years)) |> 
      st_as_sf()
    
    leaflet() |>
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Map") |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
      addPolygons(data = data, group = "hucs", popup = ~subbasin,
                  color = "darkgrey", fillColor = ~color_palette(total_years),
                  fillOpacity = 0.5)  |> 
      addLegend("bottomright", pal = color_palette, values = data$total_years,
                title = "Number of Data Collection Years")
    
  })
  
  output$table_monitoring <- renderDT({
    data <- selected_monitoring() |> 
      select(subbasin, data_type, species_group, source, start, end) |> 
      group_by(subbasin, data_type, species_group, source) |> 
      summarize(`Year Start` = min(start),
                `Year End` = max(end)) |> 
      rename(Watershed = subbasin,
             `Data Type` = data_type,
             Species = species_group,
             Source = source) 
    datatable(data)
  })
  
}

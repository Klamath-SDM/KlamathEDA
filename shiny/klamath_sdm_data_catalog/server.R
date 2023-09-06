library(shiny)

function(input, output) {
  
  
  # Restoration Tab: --------------------------------------------------------
  
  # Filter restoration projects 
  selected_restoration <- reactive({
    if(input$rest_data_type == "All Types" & input$watershed == "All Watersheds") {
      dat <- all_rest_data
    } else if (input$rest_data_type == "All Types" & input$watershed != "All Watersheds") {
      dat <- all_rest_data |> 
        filter(name %in% input$watershed)
    } else if (input$rest_data_type != "All Types" & input$watershed == "All Watersheds") {
      dat <- all_rest_data |> 
        filter(Category %in% input$rest_data_type)
    } else {
      dat <- all_rest_data |> 
        filter(Category %in% input$rest_data_type, 
               name %in% input$watershed)
    } 
  })
  
  output[["rest_table"]] <- renderDT({
    datatable(selected_restoration() |> select(-`Project Benefit`), callback = JS(js("t1")),
              options = list(scrollX = TRUE,
                             dom = 't'),
              filter = "top",
              rownames = FALSE)
  })
  
  observeEvent(input[["t1"]], {
    showModal(
      modalDialog(
        
        selected_restoration() |> slice(input[['t1']]) |> pull(`Project Benefit`)
        
      )
    )
  })
  
  
  output$map <- renderLeaflet({
    summary_by_watershed <- selected_restoration() |> 
      group_by(HUC, name, geometry) |> 
      summarise(n_projects = n()) |> 
      st_as_sf()
    
    color_palette <- colorNumeric(palette = "YlOrRd", domain = c(1, max(summary_by_watershed$n_projects)))
    
    leaflet() |>
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Map") |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
      addPolygons(data = summary_by_watershed, group = "hucs", popup = ~paste0("Watershed: ", name, "<br>", 
                                                                               "No. Projects: ", n_projects),
                  color = "darkgrey", fillColor = ~color_palette(n_projects),
                  fillOpacity = 0.5)  |> 
      addLegend("bottomright", pal = color_palette, values = c(1, summary_by_watershed$n_projects),
                title = "Number of Projects")
    
  })
  
  
  # Downloadable csv of selected dataset ----
  output$downloadData <- downloadHandler(
    filename = function() {
      paste0('restoration_projects', ".csv")
    },
    content = function(file) {
      write_csv(selected_restoration(), file)
    }
  )
  
  
  # Fisheries Monitoring: -------------------------------------------------------------
  
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

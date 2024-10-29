library(shiny)

function(input, output) {
  
  
  # Restoration Tab: --------------------------------------------------------
  
  # Filter restoration projects 
  selected_restoration <- reactive({
    if(input$rest_data_type == "All Types" & input$watershed == "All Watersheds") {
      dat <- all_rest_data
    } else if (input$rest_data_type == "All Types" & input$watershed != "All Watersheds") {
      dat <- all_rest_data |> 
        filter(Watershed %in% input$watershed)
    } else if (input$rest_data_type != "All Types" & input$watershed == "All Watersheds") {
      dat <- all_rest_data |> 
        filter(Category %in% input$rest_data_type)
    } else {
      dat <- all_rest_data |> 
        filter(Category %in% input$rest_data_type, 
               Watershed %in% input$watershed)
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
      group_by(HUC, Watershed, geometry) |> 
      summarise(n_projects = n()) |> 
      st_as_sf()
    
    color_palette <- colorNumeric(palette = "YlOrRd", domain = c(1, max(summary_by_watershed$n_projects)))
    
    leaflet() |>
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Map") |>
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") |>
      addPolygons(data = summary_by_watershed, group = "hucs", popup = ~paste0("Watershed: ", Watershed, "<br>", 
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
  
  
  # habitat data tab:  ------------------------------------------------------
  
  output$hab_data <- renderDT({
    datatable(hab_data)
  })
  
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
  

# water data --------------------------------------------------------------
  # Filter monitoring data based on selections
  selected_water <- reactive({
    if(input$water_data_type == "All Types" & input$water_watershed == "All Watersheds") {
      dat <- water_data
    }
    else if(input$water_data_type == "All Types" & input$water_watershed != "All Watersheds") {
      dat <- water_data |> 
        filter(stream %in% input$water_watershed)
    } else if(input$water_data_type != "All Types" & input$water_watershed == "All Watersheds") {
      dat <- water_data |> 
        filter(data_type %in% input$water_data_type)
    } else {
      dat <- water_data |> 
        filter(data_type %in% input$water_data_type,
               stream %in% input$water_watershed)
    }
    dat
  })
  
  output$table_water <- renderDT({
    data <- selected_water() |> 
      select(stream, data_type, data_source, gage_number, earliest_data, latest_data) |> 
      rename(Watershed = stream,
             `Data Type` = data_type,
             Source = data_source,
             `Gage Number` = gage_number,
             `Date Start` = earliest_data,
             `Date End` = latest_data) 
    datatable(data)
  })
  
  
  
  output$map_water <- renderLeaflet({
  
    type_palette <- colorFactor(palette = "Set1", domain = levels(water_data$data_type))
    data <- selected_water() |> 
      st_as_sf(coords = c("longitude", "latitude"), crs = 4326)
    
    leaflet(data) |> 
      addTiles() |> 
      addCircleMarkers(radius = 4, color = ~type_palette(data_type), popup = ~paste0("Stream name: ", stream, "<br>Gage Number: ", gage_number, "<br>Max Date: ", latest_data, "<br>Min Date: ", earliest_data))
    
    
  })
}

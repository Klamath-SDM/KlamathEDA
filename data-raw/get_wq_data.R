library(tidyverse)
library(dataRetrieval)
library(httr)
library(readr)
library(sf)

# largely adapted from : 
# https://github.com/DOI-USGS/ds-pipelines-targets-example-wqp/blob/main/1_inventory/src/get_wqp_inventory.R

col_select <- function(data) {
  data |> 
    janitor::clean_names() |> 
    select(organization_identifier,
           organization_formal_name,
           activity_start_date,
           activity_start_time_time,
           activity_start_time_time_zone_code,
           monitoring_location_identifier,
           characteristic_name,
           result_sample_fraction_text,
           result_measure_value,
           result_measure_measure_unit_code,
           result_status_identifier,
           result_analytical_method_method_name,
           provider_name) |> distinct()
}

hucs <- sf::read_sf('shiny/klamath_sdm_data_catalog/data/shapefiles/WBDHU8_Klamath_Rogue.shp') |> 
  select(huc8, name) |> 
  rename(HUC = huc8) |> 
  mutate(HUC = as.numeric(HUC)) |> 
  st_transform("+proj=longlat +datum=WGS84 +no_defs") |> st_zm()

dissolve_hucs <- st_union(hucs)
bbox <- sf::st_bbox(dissolve_hucs)
aoi <- sf::st_as_sf(data.frame(lon = c(as.numeric(bbox[1]), as.numeric(bbox[3])),
                               lat = c(as.numeric(bbox[2]), as.numeric(bbox[4]))),
                    coords = c("lon", "lat"), 
                    crs = "4326")

char_names <- "Temperature, water"

inventory_wqp <- function(grid, char_names, wqp_args = NULL, 
                          max_tries = 3, sleep_on_error = 0, verbose = FALSE){
  
  # First, check dataRetrieval package version and inform user if outdated
  if(packageVersion('dataRetrieval') < "2.7.6.9003"){
    stop(sprintf(paste0("dataRetrieval version %s is installed but this pipeline ",
                        "requires package 2.7.6.9003. Please update dataRetrieval."),
                 packageVersion('dataRetrieval')))
  }
  
  # Get bounding box for the grid polygon
  bbox <- sf::st_bbox(grid)
  
  # Format characteristic names
  char_names <- as.character(unlist(char_names))
  
  # Print time-specific message so user can see progress
  message(sprintf('Inventorying WQP data for grid %s, %s', 
                  grid$id, char_names))
  
  # Inventory available WQP data
  wqp_inventory <- lapply(char_names, function(x){
    # define arguments for whatWQPdata
    wqp_args_all <- c(wqp_args, 
                      list(bBox = c(bbox$xmin, bbox$ymin, bbox$xmax, bbox$ymax),
                           characteristicName = x))
    # query WQP
    dat <- retry(dataRetrieval::whatWQPdata, wqp_args_all, 
                 max_tries = max_tries,
                 sleep_on_error = sleep_on_error,
                 verbose = verbose) 
    dat_out <- mutate(dat, CharacteristicName = x, grid_id = grid$id)
    return(dat_out)
  }) %>%
    bind_rows()
  
  # Fetch missing CRS information from WQP. Note that an empty query will not
  # contain CRS information. In the event that the lines below throw an error, 
  # "Column `HorizontalCoordinateReferenceSystemDatumName` doesn't exist", return
  # an empty data frame for the site location metadata. 
  site_location_metadata <- tryCatch(
    dataRetrieval::whatWQPsites(bBox = c(bbox$xmin, bbox$ymin, bbox$xmax, bbox$ymax)) %>%
      select(MonitoringLocationIdentifier, HorizontalCoordinateReferenceSystemDatumName) %>%
      filter(MonitoringLocationIdentifier %in% wqp_inventory$MonitoringLocationIdentifier),
    error = function(e){
      data.frame(MonitoringLocationIdentifier = character(), 
                 HorizontalCoordinateReferenceSystemDatumName = character())
    }
  )
  
  # Join WQP inventory with site metadata 
  wqp_inventory_out <- wqp_inventory %>%
    left_join(site_location_metadata, by = "MonitoringLocationIdentifier")
  
  return(wqp_inventory_out)
  
}

temperature_inventory <- inventory_wqp(aoi, "Temperature, water",
              wqp_args = list(siteType = "Lake, Reservoir, Impoundment", "Stream"))


dissolved_oxygen_inventory <- inventory_wqp(aoi, "Dissolved oxygen (DO)",
                                       wqp_args = list(siteType = "Lake, Reservoir, Impoundment", "Stream"))

flow_inventory <- inventory_wqp(aoi, "Flow",
                                            wqp_args = list(siteType = "Stream"))

# get data  ---------------------------------------------------------------

pull_data_safely <- function(expr, timeout_minutes, max_tries, sleep_on_error, verbose, ...){
  
  # specify max time allowed (in seconds) to execute data pull
  httr::set_config(httr::timeout(timeout_minutes*60))
  
  # pull the data
  dat <- retry(expr, ..., 
               max_tries = max_tries, 
               sleep_on_error = sleep_on_error,
               verbose = verbose)
  
  # reset global httr configuration
  httr::reset_config()
  
  return(dat)
}

fetch_wqp_data <- function(site_counts_grouped, 
                           char_names, 
                           wqp_args = NULL, 
                           ignore_attributes = TRUE,
                           max_tries = 3, 
                           timeout_minutes_per_site = 5, 
                           sleep_on_error = 0, 
                           verbose = FALSE){
  
  message(sprintf("Retrieving WQP data for %s sites in group %s, %s",
                  nrow(site_counts_grouped), unique(site_counts_grouped$download_grp), 
                  char_names))
  
  # Define arguments for readWQPdata
  # sites with pull_by_id = FALSE cannot be queried by their site
  # identifiers because of undesired characters that will cause the WQP
  # query to fail. For those sites, query WQP by adding a small bounding
  # box around the site(s) and including bBox in the wqp_args.
  if(all(site_counts_grouped$pull_by_id)){
    wqp_args_all <- c(wqp_args, 
                      list(siteid = site_counts_grouped$site_id,
                           characteristicName = c(char_names),
                           ignore_attributes = ignore_attributes))
  } else {
    wqp_args_all <- c(wqp_args, 
                      list(bBox = create_site_bbox(site_counts_grouped),
                           characteristicName = c(char_names),
                           ignore_attributes = ignore_attributes))
  }
  
  # Pull the data, retrying up to the number of times indicated by `max_tries`.
  # For any single attempt, stop and retry if the time elapsed exceeds
  # `timeout_minutes`. Use at least 1 minute so that it doesn't error if 
  # `length(site_counts_grouped$site_ids) == 0`
  timeout_minutes <- 1 + timeout_minutes_per_site * length(site_counts_grouped$site_id)
  
  wqp_data <- pull_data_safely(dataRetrieval::readWQPdata, wqp_args_all,
                               timeout_minutes = timeout_minutes,
                               max_tries = max_tries, 
                               sleep_on_error = sleep_on_error,
                               verbose = verbose)
  
  # Throw an error if the request comes back empty
  if(is.data.frame(wqp_data) && nrow(wqp_data) == 0){
    stop(sprintf("\nThe download attempt failed after %s successive attempts", max_tries))
  }
  
  # We applied special handling for sites with pull_by_id = FALSE (see comments
  # above). Filter wqp_data to only include sites requested in site_counts_grouped
  # in case our bounding box approach picked up any additional, undesired sites. 
  # In addition, some records return character strings when we expect numeric 
  # values, e.g. when "*Non-detect" appears in the "ResultMeasureValue" field. 
  # For now, consider all columns to be character so that individual data
  # frames returned from fetch_wqp_data can be joined together. 
  wqp_data_out <- wqp_data %>%
    filter(MonitoringLocationIdentifier %in% site_counts_grouped$site_id) %>%
    mutate(across(everything(), as.character))
  
  return(wqp_data_out)
}

site_id <- unique(temperature_inventory$MonitoringLocationIdentifier)[1]
site_type <- temperature_inventory |> filter(MonitoringLocationIdentifier == site_id) |> 
  pull(ResolvedMonitoringLocationTypeName)
site_counts <- data.frame(site_id = site_id, pull_by_id = c(TRUE), site_type = site_type)

# TODO: adapt to multiple sites 
temperature_fetch <- fetch_wqp_data(site_counts, "Temperature, water", wqp_args = list(siteType = site_type)) |> 
  col_select()



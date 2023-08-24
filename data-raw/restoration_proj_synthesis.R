library(tidyverse)


# OWRI - data formatting  -------------------------------------------------
owri_db_1_proj_info <- readxl::read_excel('data-raw/OWRI_ExportToExcel_011023/OwriDbExcel_1of3.xlsx', sheet = "XlsProjectInfo") |> 
  filter(BasinActual == "Klamath")
owri_db_1_results <- readxl::read_excel('data-raw/OWRI_ExportToExcel_011023/OwriDbExcel_1of3.xlsx', sheet = "XlsResult")
owri_db_1_goal <- readxl::read_excel('data-raw/OWRI_ExportToExcel_011023/OwriDbExcel_1of3.xlsx', sheet = "XlsGoal")


owri_db_1_merge <- owri_db_1_proj_info |> 
  left_join(owri_db_1_results) |> 
  left_join(owri_db_1_goal, relationship = "many-to-many") |> 
  janitor::clean_names() |> 
  select('project_id', 'projnum', 'start_year', 'complete_year', 'stream_name', 'basin_actual',
         'county', 'drvd_huc4th_field', 'drvd_proj_desc', 'goal',
         'activity_type', 'result', 'quantity', 'unit') |> 
  mutate(status = ifelse(complete_year < 2023, 'complete', 'ongoing')) |> 
  rename(watershed = drvd_huc4th_field,
         year = start_year,
         recovery_domain = basin_actual, 
         category = activity_type, 
         project_benefit = result) |>
  mutate(grantee = 'OWEB', 
    resource = "OWRI: https://tools.oregonexplorer.info/OE_HtmlViewer/Index.html?viewer=owrt") |> 
  filter(year >= 2015) |> 
  distinct() |> 
  glimpse()

# format for google doc
owri_gdoc_format <- owri_db_1_merge |> 
  mutate(subgrantee = NA,
         project_name = NA, 
         project_lead = NA, 
         other_project_lead = NA,
         sub_category = NA) |> 
  select(project_id, grantee, subgrantee, 
         project_name, year, 
         status, project_lead, other_project_lead, 
         category, sub_category,
         recovery_domain, goal, project_benefit, 
         watershed, resource) 


# FWS data formatting -----------------------------------------------------
# https://www.fws.gov/program/klamath-basin-project-awards
dta <- readxl::read_excel('data-raw/sdm_restoration_projects.xlsx')

dta %>%
  dplyr::group_by(item) %>%
  dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
  dplyr::filter(n > 1L) 

tmp <- dta %>% 
  group_by(item) %>%
  mutate(rn = row_number()) %>%
  pivot_wider(names_from = item, values_from = variable) |> 
  separate(dollar, into = c("state", "dollar")) |> 
  ungroup() |> 
  mutate(project_id = 'Klamath Basin Project Awards',
         grantee = "USFW",
         subgrantee = NA, 
         status = "New", 
         project_lead = NA, 
         other_lead = NA, 
         category = NA, 
         subcategory = NA, 
         benefit = NA, 
         resource = "https://www.fws.gov/program/klamath-basin-project-awards",
         year = 2022) |> 
  select(project_id, grantee, subgrantee, name, year, status, project_lead, 
         other_lead, category, subcategory, state, description, benefit, resource)

write_csv(tmp, 'data-raw/sdm_klamath_usfws_restoration_projects.csv')



# ecoatlas ----------------------------------------------------------------
# counties: Siskiyou, Klamath
# https://api.ecoatlas.org/#route-projects
# https://ecoatlas.org/regions/ecoregion/statewide
library(httr)
library(jsonlite)

# Replace {region_type_key} with the actual region type key you want to use
region_type_key <-  'adminregion' #"key":84,"name":"KTAP Reporting Zone 7 - Upper Klamath"

# Construct the URL
url <- paste0("https://api.ecoatlas.org/projects/")

# Make the GET request
response <- GET(url)
content <- content(response, "text")

projects_raw <- fromJSON(rawToChar(response$content), flatten = TRUE) 
all_projects <- projects_raw$projects |> as_tibble()

all_lat_long_name <- data.frame()
for(i in 2576:length(all_projects$projectid)) {
  print(i)
  # Construct the URL
  url <- paste0("https://api.ecoatlas.org/projects/", all_projects$projectid[i])
  
  # Make the GET request
  response <- GET(url)
  content <- content(response, "text")
  
  tmp <- fromJSON(rawToChar(response$content), flatten = TRUE) 
  
  tmp_tibble <- tmp$sites |> as_tibble() 
  
  if(nrow(tmp_tibble) > 0) {  
    all_lat_long_name <- tmp_tibble |>  mutate(county = paste0(tmp$counties$name, collapse = "; "),
                                project_type = paste0(tmp$project$projecttype, collapse = "; "),
                                abstract = paste0(tmp$project$abstract, collapse = "; ")) |> 
      bind_rows(all_lat_long_name)
  }
}

write_csv(all_lat_long_name, "data-raw/ecoatlas_all_projects.csv")

eco_atlas <- all_lat_long_name |> 
  janitor::clean_names() |> 
  select(site_name, site_siteid, site_status, site_latitude, site_longitude,
         site_geom, county, abstract, project_type) |> 
  filter(county %in% c('Klamath', 'Siskiyou')) |> 
  rename(project_id = site_siteid, 
         status = site_status, 
         project_name = site_name, 
         project_descripton = abstract,
         project_benefit = project_type) |> 
  mutate(resource = 'https://ecoatlas.org/regions/ecoregion/statewide/projects',
         grantee = 'ecoatlas',
         subgrantee = NA, 
         year = NA, 
         project_lead = NA, 
         other_project_lead = NA, 
         category = NA, 
         sub_category = NA, 
         recovery_domain = NA, 
         river = NA, 
         watershed = NA, 
         HUC = NA,
         goal = NA) |> 
  select(project_id, grantee, subgrantee, 
         project_name, year, 
         status, project_lead, other_project_lead, 
         category, sub_category,
         recovery_domain, project_descripton, project_benefit, 
         watershed, resource, site_latitude, site_longitude) |> 
  glimpse()

write_csv(eco_atlas, "data-raw/eco_atlas_klamath_siskiyou.csv")

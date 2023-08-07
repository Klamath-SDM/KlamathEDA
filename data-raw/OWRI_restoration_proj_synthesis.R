library(tidyverse)

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




library(tidyverse)
# manual data discovery effort tracked here: https://docs.google.com/spreadsheets/d/142flCMdYqYSPRLVVbWoAYHMpQPboCPUDO9t3THDq7WM/edit#gid=1461998431
data_catalog_raw <- read_csv("data-raw/fisheries_preliminary_catalog.csv")

# data that will be used to summarize type, species, time of data
data_app <- data_catalog_raw |> 
  select(subbasin, data_type, species, timeframe) |> 
  filter(!timeframe %in% c("?", "two decades"),
         !grepl("-", timeframe)) |> 
  distinct()

# format entries with multiple years with start/end
data_app_format <- data_catalog_raw |> 
  select(subbasin, data_type, species, timeframe) |> 
  filter(grepl("-", timeframe)) |> 
  distinct() |> 
  mutate(start = as.numeric(substr(timeframe, 1, 4)),
         end = as.numeric(ifelse(grepl("ongoing", timeframe), 2023,
                      substr(timeframe,6,9))))
# these are the entries with missing time frame but can still be referenced
# in notes
data_app_other <- data_catalog_raw |> 
  select(subbasin, data_type, species, timeframe) |> 
  filter(timeframe %in% c("?", "two decades")) |> 
  distinct()

# combine the formatted data
data_app_all <- data_app |> 
  full_join(data_app_format |> select(-timeframe)) |> 
  mutate(within_timeframe = case_when(!is.na(timeframe) & !is.na(start) & (timeframe >= start | timeframe <= end) ~ T,
                                 T ~ F),
         species_group = case_when(species %in% c("UTKR Chinook", "Fall Chinook", "chinook") ~ "chinook",
                                   species %in% c("Coho", "coho") ~ "coho",
                                   species %in% c("All Salmon","ALL", "coho, chinook, steelhead", 
                                                  "Chinook, Coho, Steelhead", "chinook, coho, steelhead") ~ "all salmonids",
                                   species %in% c("CCC Steelhead", "Steelhead") ~ "steelhead")) 
write_csv(data_app_all, "data-raw/fish_data_synthesis.csv")

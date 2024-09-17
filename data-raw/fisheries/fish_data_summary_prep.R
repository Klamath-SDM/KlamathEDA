library(tidyverse)
# manual data discovery effort tracked here: https://docs.google.com/spreadsheets/d/142flCMdYqYSPRLVVbWoAYHMpQPboCPUDO9t3THDq7WM/edit#gid=1461998431
data_catalog_raw <- read_csv("data-raw/fisheries/fisheries_preliminary_catalog.csv")

# data that will be used to summarize type, species, time of data
data_app <- data_catalog_raw |> 
  select(subbasin, data_type, species, timeframe, source) |> 
  filter(!timeframe %in% c("?", "two decades"),
         !grepl("-", timeframe)) |> 
  distinct()

# format entries with multiple years with start/end
data_app_format <- data_catalog_raw |> 
  select(subbasin, data_type, species, timeframe, source) |> 
  filter(grepl("-", timeframe)) |> 
  distinct() |> 
  mutate(start = as.numeric(substr(timeframe, 1, 4)),
         end = as.numeric(ifelse(grepl("ongoing", timeframe), 2023,
                      substr(timeframe,6,9))))
# these are the entries with missing time frame but can still be referenced
# in notes
data_app_other <- data_catalog_raw |> 
  select(subbasin, data_type, species, timeframe, source) |> 
  filter(timeframe %in% c("?", "two decades")) |> 
  distinct()

# combine the formatted data
data_app_all <- data_app |> 
  full_join(data_app_format |> select(-timeframe)) |> 
  mutate(start = ifelse(is.na(start), as.numeric(timeframe), start),
         end = ifelse(is.na(end), as.numeric(timeframe), end),
         n_years = ifelse(start == end, 1, end-start),
         species_group = case_when(species %in% c("UTKR Chinook", "Fall Chinook", "chinook") ~ "chinook",
                                   species %in% c("Coho", "coho") ~ "coho",
                                   species %in% c("All Salmon","ALL", "coho, chinook, steelhead", 
                                                  "Chinook, Coho, Steelhead", "chinook, coho, steelhead") ~ "all salmonids",
                                   species %in% c("CCC Steelhead", "Steelhead") ~ "steelhead"),
         species_group = str_to_title(species_group),
         source = case_when(source %in% c("KUROK", "Yurok") ~ "YUROK",
                            source == "NOAA Fisheries" ~ "NOAA",
                            !source %in% c("USFWS", "USGS", "CDFW", "USBR", "USFS", "ODFW", "TNC", "NOAA", "YUROK") ~ "OTHER",
                            T ~ source),
         subbasin = case_when(subbasin %in% c("lower klamath river", "klamath", "mid klamath") ~ "lower klamath",
                              subbasin == "upper klamath river" ~ "upper klamath",
                              T ~ subbasin),
         subbasin = str_to_title(subbasin),
         data_type = str_to_title(data_type),
         data_type = ifelse(data_type %in% c("Fish Survival", "Fish Health"), "Fish Health/Survival", data_type)) |> 
  # remove the years/rows that fall within the greater timeframe so there aren't duplicates (e.g. we have 2006-2009 coho fish survival AND rows for 
  # 2006, 2007, 2009, we don't want to count these twice)
  select(-timeframe) |> 
  distinct() |> 
  filter(data_type %in% c("Escapement", "Juvenile Monitoring", "Fish Health/Survival", "Hatchery", "Fish Population Esimtates"))

unique(data_app_all$data_type)
write_csv(data_app_all, "shiny/klamath_sdm_data_catalog/data/fish_data_synthesis.csv")






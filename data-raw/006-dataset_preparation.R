# Contributor: Muhammad Aswan Syahputra
# Source: The World Bank (https://datacatalog.worldbank.org/dataset/indonesia-database-policy-and-economic-research)

library(tidyverse)
library(janitor)

temporary_dir <- tempdir()

download.file("http://databank.worldbank.org/data/download/INDODAPOER_CSV.zip", destfile = paste0(temporary_dir, "/INDODAPOER_CSV.zip"))

indodapoer_raw <- read_csv(unz(paste0(temporary_dir, "/INDODAPOER_CSV.zip"), filename = "INDODAPOERData.csv"))

glimpse(indodapoer_raw)

indodapoer_raw <- indodapoer_raw %>% 
  clean_names()

glimpse(indodapoer_raw)

indodapoer <- 
  indodapoer_raw %>% 
  select(province_or_district = country_name, indicator = indicator_name, starts_with("x"), -x46) %>% 
  gather(key = "year", value = "value", x1976:x2016) %>% 
  spread(indicator, value) %>% 
  clean_names() %>% 
  mutate(year = str_remove(year, "^x"))

indodapoer

save(indodapoer, file = "data/indodapoer.rda", compress = "bzip2", compression_level = 9)

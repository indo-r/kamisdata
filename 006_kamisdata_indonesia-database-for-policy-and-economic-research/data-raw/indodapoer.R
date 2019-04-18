library(tidyverse)
library(janitor)

download.file("http://databank.worldbank.org/data/download/INDODAPOER_CSV.zip", destfile = "006_kamisdata_indonesia-database-for-policy-and-economic-research/data-raw/")

indodapoer_raw <- read_csv(unz("006_kamisdata_indonesia-database-for-policy-and-economic-research/data-raw/INDODAPOER_CSV.zip", filename = "INDODAPOERData.csv"))

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

glimpse(indodapoer)

save(indodapoer, file = "006_kamisdata_indonesia-database-for-policy-and-economic-research/data/indodapoer.rda", compress = "bzip2", compression_level = 9)

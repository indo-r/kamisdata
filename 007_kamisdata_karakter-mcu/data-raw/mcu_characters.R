library(tidyverse)
library(furrr)
library(rvest)

plan(multiprocess)

scrape_mcu_character_in_category <- function(url) {
  url %>% 
    read_html() %>% 
    html_nodes(".category-page__member-link") %>% 
    html_attr("href") %>% 
    str_c("https://marvelcinematicuniverse.fandom.com", ., sep = "") %>% 
    future_imap_dfr(~read_html(.x) %>% 
               {
                 tibble(
                   id = .y,
                   key = html_nodes(., ".pi-data-label") %>% 
                     html_text(trim = TRUE),
                   value =  html_nodes(., ".pi-data-value") %>% 
                     html_text(trim = TRUE)
                 )
               })
}

category_urls <- c("https://marvelcinematicuniverse.fandom.com/wiki/Category:Heroes", "https://marvelcinematicuniverse.fandom.com/wiki/Category:Villains")

mcu_characters_raw <- 
  category_urls %>% 
  set_names(nm = c("Hero", "Villain")) %>% 
  future_map(possibly(~scrape_mcu_character_in_category(.x), otherwise = NULL), .progress = TRUE)

mcu_characters <-
  mcu_characters_raw %>% 
  bind_rows(.id = "category") %>% 
  complete(id, key) %>% 
  dplyr::filter(!duplicated(.)) %>% 
  dplyr::filter(id != 78) %>% 
  drop_na(category) %>% 
  spread(key, value) %>% 
  janitor::clean_names() %>% 
  mutate(
    alias_es = str_split(alias_es, "(?<=[a-z])(?=[A-Z])") %>% 
      map_chr(~str_c(.x, collapse = ", ")),
    comic = str_split(comic, "(?<=[a-z])(?=[A-Z])") %>% 
      map_chr(~str_c(.x, collapse = ", ")),
    movie = str_split(movie, "(?<=[a-z])(?=[A-Z])") %>% 
      map_chr(~str_c(.x, collapse = ", ")),
    title_s = str_split(title_s, "(?<=[a-z])(?=[A-Z])") %>% 
      map_chr(~str_c(.x, collapse = ", ")),
    portrayed_by = str_split(portrayed_by, "(?<=[a-z])(?=[A-Z])") %>% 
      map_chr(~str_c(.x, collapse = ", ")),
    voiced_by = str_split(voiced_by, "(?<=[a-z])(?=[A-Z])") %>% 
      map_chr(~str_c(.x, collapse = ", "))
  ) %>% 
  select(category, 
         real_name, 
         alias = alias_es, 
         title = title_s,
         affiliation, 
         citizenship,
         date_of_birth,
         date_of_death, 
         species,
         gender,
         status,
         everything(), 
         -id)

save(mcu_characters, file = "007_kamisdata_karakter-mcu/data/mcu_characters.rda", compress = "bzip2", compression_level = 9)

library(rvest)
library(tidyverse)
library(unglue)

filmindonesia <- read_html("http://filmindonesia.or.id/movie/viewer#.XWNJqXUzZtY")

ranking_url <-
  filmindonesia %>% 
  html_nodes(".trivia-box+ .widget .widget-content ul li a") %>% 
  {
    tibble(
      year = html_text(.),
      ranking_url = html_attr(., "href")
    )
  } %>% 
  dplyr::filter(nchar(year) == 4)
    
film_teratas_raw <- 
  ranking_url %>% 
  mutate(
    n_viewers = map(ranking_url, ~ .x %>% 
                      read_html() %>% 
                      html_node(".bo-list .widget-content table") %>% 
                      html_table() %>% 
                      mutate_all(~as.character(.x))),
    movie_url = map(ranking_url, ~ .x %>% 
                      read_html() %>% 
                      html_nodes("td:nth-child(2) a") %>% 
                      html_attr("href"))
  ) %>% 
  unnest() %>% 
  mutate(
    rating = map_chr(movie_url, ~ .x %>%
                       read_html() %>%
                       html_node(".rating-score") %>%
                       html_text()),
    details = map_chr(movie_url, ~.x %>%
                          read_html() %>%
                          html_node(".rating-box+ p") %>%
                          html_text()),
    synopsis = map_chr(movie_url, ~ .x %>% 
                           read_html() %>% 
                           html_node(".navbar-content div p") %>% 
                           html_text())
  )

details_patterns <- c("Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Rasio{others}", 
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Format{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Warna{others}")

film_teratas <- 
  film_teratas_raw %>% 
  transmute(
    ranking_year = as.numeric(year),
    title = Judul,
    ranking = as.integer(`#`),
    n_viewer = parse_number(Penonton, locale = locale(decimal_mark = ",", grouping_mark = ".")),
    gross_profit_per_viewer = case_when(
      ranking_year == 2008 ~ 13000,
      ranking_year == 2009 ~ 14000,
      ranking_year == 2012 ~ 22000,
      ranking_year == 2013 ~ 30000,
      ranking_year == 2015 ~ 35000,
      ranking_year == 2016 ~ 35000,
      ranking_year == 2017 ~ 37000,
      ranking_year == 2019 ~ 40000,
      TRUE ~ NA_real_
    ),
    rating = str_extract(rating, pattern = "\\d\\.\\d|\\d"),
    synopsis = synopsis,
    details = details
  ) %>% 
  unglue_unnest(details, patterns = details_patterns, keep = FALSE) %>% 
  mutate(
    release_date = lubridate::dmy(release_date)
  ) %>% 
  select(-others)

film_teratas

save(film_teratas, file = "009_kamisdata_film-indonesia/data/film_teratas.rda", compress = "bzip2", compression_level = 9)

write_csv(film_teratas, "009_kamisdata_film-indonesia/data/film_teratas.csv")

library(tidyverse)
library(rvest)
library(furrr)

plan(multiprocess)

movie_year_url <- 
  read_html("http://filmindonesia.or.id/movie") %>% 
  html_nodes("#year-list a") %>% 
  {
    tibble(
      year = html_text(.),
      year_url = html_attr(., "href")
    )
  } %>% 
  mutate(n_entry = map_dbl(year_url, ~ {
    n_entry <- 
      read_html(.x) %>% 
      html_nodes("h4") %>% 
      html_text() %>% 
      str_extract("(?<=-\\s)[0-9]{1,4}") %>% 
      as.numeric()
    
    if (length(n_entry) == 0) {
      n_entry <- 0
    }
    
    return(n_entry)
  })) %>% 
  dplyr::filter(n_entry > 0) %>% 
  mutate(
    subpage = map(n_entry, ~ {
      c(NA_real_, seq(from = 10, by = 10, length.out = (.x %/% 10)))
    })
  ) %>% 
  unnest() %>% 
  transmute(
    year_url = glue::glue("{year_url}/{subpage}", .na = "")
  )

complete_movie_url <- 
  movie_year_url %>% 
  mutate(
    movie = future_map(year_url, ~ {
      read_html(.x) %>% {
        tibble(
          title = html_nodes(., ".content-lead a:nth-child(1)")
          %>% html_text(),
          year = html_nodes(., ".content-lead a:nth-child(2)") %>% 
            html_text(),
          movie_url = html_nodes(., ".content-lead a:nth-child(1)") %>% 
            html_attr("href")
        )
      }
    }, .progress = TRUE)
  ) %>% 
  unnest() %>% 
  select(title, year, movie_url) %>% 
  distinct(movie_url, .keep_all = TRUE)

parse_movie <- function(x) {
  read_html(x) %>% {
    tibble(
      genre1 = html_nodes(., 'span[itemprop="genre"]') %>% 
        html_text() %>% 
        paste(collapse = ", ") %>% 
        ifelse(. == "", NA_character_, .),
      genre2 = html_node(., ".movie-meta-info p a:nth-child(2)") %>%
        html_text(),
      duration = html_node(., "time") %>%
        html_text(),
      classification = html_node(., ".classification") %>%
        html_text(),
      rating = html_node(., ".rating-score") %>%
        html_text(),
      details1 = html_node(., ".rating-box+ p") %>%
        html_text() %>%
        ifelse(. == "", NA_character_, .),
      details2 = html_node(., ".movie-general-info p:nth-child(1)") %>%
        html_text(),
      synopsis = html_node(., ".navbar-content div p") %>%
        html_text()
    )
  } %>% 
    mutate_if(is.character, ~str_squish(.x)) %>% 
    mutate_if(is.character, ~na_if(.x, ""))
}

filmindonesia_raw <- 
  complete_movie_url %>% 
  mutate(
    movie_details = future_map(movie_url, parse_movie, .progress = TRUE)
  ) %>% 
  unnest()
details_patterns <- c("Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Rasio{others}", 
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Format{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Warna{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Format{others}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}Warna{others}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}",
                      "Produser{producer}Sutradara{director}Warna{others}",
                      "Produser{producer}Pemeran{actress}Warna{others}",
                      "Produser{producer}Penulis{writer}Pemeran{actress}Warna{others}",
                      "Produser{producer}Warna{others}",
                      "Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Sutradara{director}Penulis{writer}Pemeran{actress}",
                      "Sutradara{director}Penulis{writer}Pemeran{actress}Warna{others}",
                      "Sutradara{director}Pemeran{actress}Warna{others}",
                      "Sutradara{director}Pemeran{actress}Format{others}",
                      "Sutradara{director}Pemeran{actress}",
                      "Sutradara{director}Tanggal edar{release_date}",
                      "Sutradara{director}Warna{others}",
                      "Penulis{writer}Pemeran{actress}Warna{others}",
                      "Pemeran{actress}Warna{others}",
                      "Pemeran{actress}",
                      "Tanggal edar{release_date}Warna{others}"
)

filmindonesia <-
  filmindonesia_raw %>% 
  mutate(
    year = as.integer(year),
    rating = rating %>% 
      str_extract(pattern = "\\d\\d|\\d\\.\\d|\\d") %>% 
      as.double(),
    duration = parse_number(duration),
    genre = coalesce(genre1, genre2),
    details = coalesce(details1, details2)
    ) %>% 
  unglue::unglue_unnest(details, patterns = details_patterns, keep = FALSE) %>% 
  mutate(
    release_date = str_remove_all(release_date, pattern = "(?<=\\d{4}).*") %>% 
      lubridate::dmy(),
    colour = case_when(
      str_detect(others, "Warna") ~ "Colour",
      str_detect(others, "HP") ~ "BW",
      TRUE ~ NA_character_
    )
  ) %>% 
  select(title, genre, year, release_date, colour, everything(), -movie_url, -genre1, -genre2, -details1, -details2, -others)

save(filmindonesia, file = "010_kamisdata_film-indonesia-2/data/filmindonesia.rda", compress = "bzip2", compression_level = 9)

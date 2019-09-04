library(tidyverse)
library(rvest)
library(furrr)

plan(multiprocess)

genre_url <- read_html("http://filmindonesia.or.id/movie") %>% 
  html_nodes("#genre-list li a") %>% 
  {
    tibble(
      genre = html_text(.),
      genre_url = html_attr(., "href")
    )
  } %>% 
    mutate(n_entry = map_dbl(genre_url, ~ {
      n_entry <- 
        read_html(.x) %>% 
        html_nodes("h4") %>% 
        html_text() %>% 
        str_extract("\\d+") %>% 
        as.numeric()
      
      if (length(n_entry) == 0) {
        n_entry <- 0
      }
      
      return(n_entry)
    })) %>% 
    dplyr::filter(n_entry > 0) %>% 
    mutate(
      subpage = map(n_entry, function(x) {
        c(NA_real_, seq(from = 10, by = 10, length.out = (x %/% 10)))
      })
    ) %>% 
    unnest() %>% 
    transmute(
      genre,
      genre_url = glue::glue("{genre_url}/{subpage}", .na = "")
    )

movie_url <- 
  genre_url %>% 
  mutate(
    movie = future_map(genre_url, ~ {
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
  select(genre, title, year, movie_url) %>% 
  group_by(movie_url) %>% 
  mutate(genre = paste(genre, collapse = ", ")) %>% 
  ungroup() %>% 
  distinct(movie_url, .keep_all = TRUE)

movie_details <- 
  movie_url %>% 
  mutate(
    rating = future_map_chr(movie_url, ~ .x %>%
                       read_html() %>%
                       html_node(".rating-score") %>%
                       html_text(),
                       .progress = TRUE),
    details = future_map_chr(movie_url, ~.x %>%
                        read_html() %>%
                        html_node(".rating-box+ p") %>%
                        html_text(),
                        .progress = TRUE),
    synopsis = future_map_chr(movie_url, ~ .x %>% 
                         read_html() %>% 
                         html_node(".navbar-content div p") %>% 
                         html_text(),
                         .progress = TRUE)
  )

details_patterns <- c("Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Rasio{others}", 
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}Format{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Tanggal edar {release_date}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Warna{others}",
                      "Produser{producer}Sutradara{director}Penulis{writer}Pemeran{actress}Format{others}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}Tanggal edar {release_date}Warna{others}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}Warna{others}",
                      "Produser{producer}Sutradara{director}Pemeran{actress}",
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
  movie_details %>% 
  unglue::unglue_unnest(details, patterns = details_patterns, keep = FALSE) %>% 
  mutate(
    year = as.integer(year),
    rating = rating %>% 
      str_extract(pattern = "\\d\\d|\\d\\.\\d|\\d") %>% 
      as.double(),
    release_date = str_remove_all(release_date, pattern = "(?<=\\d{4}).*") %>% 
      lubridate::dmy()
  ) %>% 
  select(title, genre, year, release_date, everything(), synopsis, -movie_url, -others)

save(filmindonesia, file = "010_kamisdata_film-indonesia-2/data/filmindonesia.rda", compress = "bzip2", compression_level = 9)


dplyr::glimpse(filmindonesia)

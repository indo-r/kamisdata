library(rvest)
library(tidyverse)
library(furrr)

plan(multiprocess)
n_pages <- 6
base_url <- "https://www.goodreads.com"

booklist_pagination <- tibble(
  page = seq_len(6),
  url = paste0(base_url, "/list/show/1572.Buku_Indonesia_Sepanjang_Masa?page=", page)
)

scrape_pagination <- function(x) {
  read_html(x) %>% {
    tibble(
      title = html_nodes(., ".bookTitle span") %>% 
        html_text(),
      author = html_nodes(., ".authorName span") %>%
        html_text(),
      rank_score = html_nodes(., ".uitext a:nth-child(1)") %>% 
        html_text(),
      rating = html_nodes(., ".minirating") %>% html_text(trim = TRUE),
      book_url = paste0(
        base_url,
        html_nodes(., ".bookTitle") %>% 
          html_attr("href")
      )
    )
  }
}

booklist <- 
  booklist_pagination %>% 
  mutate(
    books = future_map(url, scrape_pagination, .progress = TRUE)
  ) %>% 
  unnest() %>% 
  select(-page, -url)

scrape_book <- function(x) {
  res1 <- 
    read_html(x) %>% 
    {
      tibble(
        n_reviews = html_node(., ".gr-hyperlink~ .gr-hyperlink") %>% 
          html_text() %>% 
          str_remove_all("\\n") %>% 
          str_squish(),
        description = html_node(., "#description span") %>% 
          html_text() %>% 
          str_remove_all("\\n") %>% 
          str_squish(),
        pages = html_nodes(., "#details div.row:nth-child(1)") %>%
          html_text() %>% 
          str_remove_all("\\n") %>% 
          str_squish(),
        publication = html_nodes(., "#details div.row:nth-child(2)") %>%
          html_text() %>% 
          str_remove_all("\\n") %>% 
          str_squish()
      )
    }
  
  res2 <-   
    read_html(x) %>% 
    {
      tibble(
        key = html_nodes(., ".infoBoxRowTitle") %>% 
          html_text() %>% 
          str_remove_all("\\n") %>% 
          str_squish(),
        value = html_nodes(., "div.infoBoxRowItem") %>% 
          html_text() %>%
          str_remove_all("\\n") %>% 
          str_squish()
        
      )
    } %>% 
    mutate(
      key = janitor::make_clean_names(key)
    ) %>% 
    dplyr::filter(!str_detect(key, "title|isbn|url|other")) %>% 
    spread(key, value)
  
  res <- bind_cols(res1, res2)
  
  return(res)
}

bukuindonesia_raw <- 
  booklist %>% 
  mutate(
    details = future_map(book_url, safely(scrape_book), .progress = TRUE),
    status = future_map_chr(details, ~ ifelse(is.null(.x[["error"]]), "OK", "Not OK"), .progress = TRUE)
  ) %>% 
  dplyr::filter(status == "OK") %>% 
  mutate(
    details = future_map(details, "result", .progress = TRUE)
  ) %>% 
  unnest()

bukuindonesia <- 
  bukuindonesia_raw %>% 
  transmute(
    title = title,
    author = author,
    rank_score = parse_number(rank_score),
    rating = str_extract(rating, "^\\d+\\.?\\d+") %>% 
      parse_number(),
    n_reviews = parse_number(n_reviews),
    n_pages = str_extract(pages, "\\d+(?= pages)") %>% 
      parse_number(),
    year = str_extract(publication, "\\d{4}") %>% 
      as.integer(),
    first_published = str_extract(publication, "(?<=first published )\\d{4}") %>% 
      as.integer(),
    publisher = str_extract(publication, "(?<=by ).*") %>% 
      str_remove_all("\\(.*\\)") %>% 
      str_squish(),
    characters = characters,
    language = edition_language,
    series,
    setting,
    description = description
  )

glimpse(bukuindonesia)

save(bukuindonesia, file = "012_kamisdata_buku-indonesia/data/bukuindonesia.rda", compress = "bzip2", compression_level = 9)

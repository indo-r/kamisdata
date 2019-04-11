# Script scrapper ini adalah modifikasi dari script original milik Raden Muhammad Hadi, sebagai bahan untuk belajar oleh Muhammad Aswan Syahputra

library(tidyverse)
library(rvest)
library(furrr)

plan(multiprocess)

url_part1 <- "https://www.kejaksaan.go.id/infoperkara.php?idu=0&idsu=11&bln=0&thn=0&hal="
url_part2 <- "&sec=pid&pk=200383541198322594166386550&ss=c99ef3668e6861ed23f95e676ffb5727&bc=&act=search&skey=&keyw="

pages <- seq_len(1311) # jumlah halaman untuk total tabel dari laman https://www.kejaksaan.go.id/infoperkara.php?idu=0&idsu=11&sec=pid

url_perkara_pidana <- 
  future_map_dfr(pages, ~str_c(url_part1, .x, url_part2) %>% 
          read_html() %>% 
          html_nodes(".teks table[id = 'data-dakwaan'] tr[style = 'cursor: pointer;']") %>% 
          html_attr("onclick") %>% 
          str_extract("infoperkara.+=") %>% 
          str_c("https://www.kejaksaan.go.id/", .) %>% 
         enframe(name = NULL, value = "url"),
         .progress = TRUE) %>% 
  pull()

save(url_perkara_pidana, file = "005_kamisdata_Perkara-Pidana-Umum-Kejari/data/url_perkara_pidana.rda", compress = "bzip2", compression_level = 9)

perkara_pidana <- 
  future_map_dfr(all_perkara_pidana, ~read_html(.x) %>% 
                   html_node("td[class = 'teks'] table") %>% 
                   html_table(trim = TRUE) %>% 
                   as_tibble() %>% 
                   filter(X1 != "" & X1 != "DETIL DATA PERKARA TINDAK PIDANA UMUM") %>% 
                   select(-X2) %>% 
                   slice(1:8) %>% 
                   spread(X1, X3, drop = FALSE) %>% 
                   janitor::clean_names(), 
                 .progress = TRUE)

save(perkara_pidana, file = "005_kamisdata_Perkara-Pidana-Umum-Kejari/data/perkara_pidana.rda", compress = "bzip2", compression_level = 9)


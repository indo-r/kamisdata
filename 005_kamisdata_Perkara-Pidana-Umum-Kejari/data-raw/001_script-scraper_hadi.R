library(rvest)
library(tidyverse)

# placeholder
data_container <- tibble(`NO PERKARA` = character(), 
                         `WILAYAH HUKUM` = character(), 
                         `IDENTITAS TERSANGKA / TERDAKWA` = character(),
                         STATUS = character())

# scrape tabel per halaman
for (i in 1:1311) {
  print(paste0("Get page ",i))
  read_html(paste0("https://www.kejaksaan.go.id/infoperkara.php?idu=0&idsu=11&bln=0&thn=0&hal=",i,"&sec=pid&pk=188347515107341505112351555&ss=323e1cc49abc59d30a7d219f9f2b28f7&bc=&act=search&skey=&keyw=")) %>% 
    html_node(".teks table[id = 'data-dakwaan']") %>% 
    html_table(header = T) %>% 
    .[,-1] %>% 
    as_tibble() -> data_gathered
  data_container <- bind_rows(data_container, data_gathered)
  if (i%%30 == 0) {
    Sys.sleep(5)
  }
}

# placeholder untuk link
link_container <- tibble(value = character())

# dapatkan link dari tiap row tabel
for (i in 1:1311) {
  print(paste0("Get Page ", i))
  read_html(paste0("https://www.kejaksaan.go.id/infoperkara.php?idu=0&idsu=11&bln=0&thn=0&hal=",i,"&sec=pid&pk=188347515107341505112351555&ss=323e1cc49abc59d30a7d219f9f2b28f7&bc=&act=search&skey=&keyw=")) %>% 
    html_nodes(".teks table[id = 'data-dakwaan'] tr[style = 'cursor: pointer;']") %>%  
    html_attr("onclick") %>% 
    str_extract(pattern = "infoperkara\\S+[^;']") %>% 
    paste0("https://www.kejaksaan.go.id/",.) %>% 
    as_tibble() -> data_gathered
  link_container <- bind_rows(link_container, data_gathered)
  if (i %% 100 == 0) {
    Sys.sleep(5)
  }
}

data_container4 <- tibble(data = list(), 
                         id = integer(),
                         `Jenis PERKARA` = character(),
                         JPU = character(),
                         `Kasus Posisi` = character(),
                         `No. PERKARA` = character(),
                         `No. Surat` = character(),
                         `Surat Dakwaan` = character(),
                         Tuntutan = character(),
                         `Wilayah Hukum` = character())


# dapatkan data yang diperoleh dari link container
for (i in 1:nrow(link_container)) {
  print(paste0("Data ke ", i))
  link_container[i,] %>% pull() -> link_pidana
  
  repeat {
    value <- tryCatch({
      read_html(link_pidana) %>% 
        html_node("td[class = 'teks'] table") %>% 
        html_table(header = F, fill = T, trim = T) %>% 
        filter(X1 != "" & X1 != "DETIL DATA PERKARA TINDAK PIDANA UMUM")
    }, warning = function(war) {
      war <- "warning"
      return(war)
    }, error = function(err) {
      err <- "error"
      return(err)
    })
    if (value != "error" & value != "warning") {
      print("berhasil")
      break
    } else {
      print("gagal")
    }
  }
  
  
  value <- as_tibble(value[,-2])
  
  value[1:8, ] %>% 
    spread(X1, X3) -> data_gathered
  
  value[10:nrow(value),] %>% 
    mutate(id = i) %>% 
    group_by(id) %>% 
    nest() -> data_gathered2
  
  bind_cols(data_gathered, data_gathered2) -> data_collected
  
  data_container4 <- bind_rows(data_container4, data_collected)
  if (i %% 30 == 0) {
    Sys.sleep(10)
  }
}

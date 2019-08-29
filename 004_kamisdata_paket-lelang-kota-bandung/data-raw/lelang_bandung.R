library(tidyverse)
# remotes::install_github("aswansyahputra/bandungjuara")
library(bandungjuara)

lelang_bandung <- 
  cari("lelang") %>% 
  impor()

save(lelang_bandung, file = "004_kamisdata_paket-lelang-kota-bandung/data/lelang_bandung.rda", compress = "bzip2", compression_level = 9)

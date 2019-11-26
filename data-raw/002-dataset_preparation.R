# Contributor: Muhammad Aswan Syahputra
# Source: Ghilman Fatih (https://github.com/seuriously)

library(tidyverse)
library(janitor)

caleg_dpr_2019 <- read_delim("https://raw.githubusercontent.com/seuriously/caleg_dpr_2019/master/caleg_dpr.csv", delim = "|", na = c("", "NA", "-"))

caleg_dpr_2019 <-
  caleg_dpr_2019 %>%
  select(
    partai,
    provinsi,
    Dapil,
    No..Urut,
    Nama.Lengkap,
    Jenis.Kelamin,
    Gelar.Akademis.Depan,
    Gelar.Akademis.Belakang,
    Pendidikan,
    Pekerjaan,
    kota_tinggal,
    Tempat.Lahir,
    Tanggal.Lahir,
    umur,
    Agama,
    Status.Perkawinan,
    Jumlah.Anak,
    Motivasi,
    Status.Khusus
  ) %>%
  clean_names()

caleg_dpr_2019

save(caleg_dpr_2019, file = "data/caleg_dpr_2019.rda", compress = "bzip2", compression_level = 9)

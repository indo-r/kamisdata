library(tidyverse)
library(janitor)

download.file("https://raw.githubusercontent.com/seuriously/caleg_dpr_2019/master/caleg_dpr.csv", destfile = "data-raw/caleg_dpr_2019.csv")

caleg_dpr_2019 <- read_delim("data-raw/caleg_dpr_2019.csv", delim = "|", na = c("", "NA", "-"))

glimpse(caleg_dpr_2019)
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

glimpse(caleg_dpr_2019)

save(caleg_dpr_2019, file = "data/caleg_dpr_2019.rda", compress = "bzip2", compression_level = 9)

# Contributor: Muhammad Aswan Syahputra
# Source: Satu Data Indonesia (http://goodreads.com)

library(readr)

penduduk_kota <- read_csv("data-raw/ae95c6a6-f607-4ddf-922e-c74d235b182b.csv")

save(penduduk_kota, file = "data/penduduk_kota.rda", compress = "bzip2", compression_level = 9)

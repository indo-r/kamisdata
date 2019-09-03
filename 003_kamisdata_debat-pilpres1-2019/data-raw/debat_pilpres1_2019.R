# remotes::install_github("aswansyahputra/nusandata")
library(nusandata)
library(tidyverse)

data(tks_debatcapres1_2019)
tks_debatcapres1_2019

save(tks_debatcapres1_2019, file = "003_kamisdata_debat-pilpres1-2019/data/debat-pilpres1-2019.rda", compress = "bzip2", compression_level = 9)

# remotes::install_github("aswansyahputra/nusandata")
library(nusandata)
library(dplyr)

data(tks_debatcapres1_2019)
glimpse(tks_debatcapres1_2019)

save(tks_debatcapres1_2019, file = "data/debat-pilpres1-2019.rda", compress = "bzip2", compression_level = 9)

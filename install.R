# Memasang paket `pacman`
if (!require("pacman")) {
  install.packages("pacman")
}

# Memasang paket dari GitHub
pacman::p_install_gh("cttobin/ggthemr")

# Mengaktifkan paket, jika paket belum terpasang maka akan dipasang secara otomatis dari CRAN
pacman::p_load("flexdashboard",
               "ggthemr", 
               "janitor",
               "extrafont",
               "tm",
               "SnowballC",
               "wordcloud",
               "RColorBrewer")

if (!require("pacman")) {
  install.packages("pacman")
}

pacman::p_load("flexdashboard",
               "ggthemr", 
               "janitor",
               "extrafont",
               "tm",
               "SnowballC",
               "wordcloud",
               "RColorBrewer")

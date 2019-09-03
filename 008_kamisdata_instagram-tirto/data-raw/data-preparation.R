library(jsonlite)
library(tidyverse)
library(lubridate)

tirto_raw <- fromJSON("008_kamisdata_instagram-tirto/data-raw/tirtoid.json")

tirto_tbl <-
  tirto_raw %>%
  pluck(1) %>%
  jsonlite::flatten() %>%
  transpose() %>%
  enframe(name = "id", value = "post")
tirto_tbl

smart_extract <- function(.x, ...) {
  dots <- list(...)
  res <- map(.x, dots, .default = NA)
  if (all(map_int(res, length) == 1)) {
    res <- unlist(res)
  }
  return(res)
}

tirto_extracted <-
  tirto_tbl %>%
  mutate(
    post_time = smart_extract(post, "taken_at_timestamp"),
    is_video = smart_extract(post, "is_video"),
    caption = smart_extract(post, "edge_media_to_caption.edges", "node", "text"),
    tags = smart_extract(post, "tags"),
    video_view = smart_extract(post, "video_view_count"),
    media_like = smart_extract(post, "edge_media_preview_like.count"),
    comments_username = smart_extract(post, "comments.data", "owner", "username"),
    comments_time = smart_extract(post, "comments.data", "created_at"),
    comments_text = smart_extract(post, "comments.data", "text")
  )
tirto_extracted

tirto_posts <-
  tirto_extracted %>%
  mutate(
    post_time = as_datetime(post_time, tz = "Asia/Jakarta"), # straighforward processing
    caption = caption %>% str_remove_all("\\n") %>% str_trim(), # lengthly processing
    n_tags = map_int(tags, length), # map using one function with no arguments
    tags = map_chr(tags, ~ paste(.x, collapse = ", ")), # map using lamda function
    n_comments = map_int(comments_text, length)
  ) %>%
  select(id, post_time, is_video, caption, tags, n_tags, everything(), -post)
tirto_posts

save(tirto_posts, file = "008_kamisdata_instagram-tirto/data/tirto_posts.rda", compress = "bzip2", compression_level = 9)

tirto_comments <-
  tirto_posts %>%
  unnest() %>% 
  mutate_at(vars(ends_with("time")), ~ as_datetime(.x, tz = "Asia/Jakarta")) %>%
  mutate_if(is.character, ~ .x %>%
              str_remove_all("\\n") %>%
              str_trim())
tirto_comments

save(tirto_comments, file = "008_kamisdata_instagram-tirto/data/tirto_comments.rda", compress = "bzip2", compression_level = 9)

# Contributor: Muhammad Aswan Syahputra
# Source: Genius.com dan Spotify

library(geniusr)
library(spotifyr)
library(tidyverse)
library(furrr)

plan(multiprocess)

geniusr::search_artist(search_term = "Iwan")
geniusr::search_artist()
get_artist_songs("362605")

iwanfals_lyrics_raw <- 
  get_artist_songs("356464") %>%
  pull(song_id) %>% 
  future_map(safely(scrape_lyrics_id), .progress = TRUE)

iwanfals_lyrics <- 
  iwanfals_lyrics_raw %>% 
  map("result") %>% 
  compact() %>% 
  bind_rows() %>% 
  transmute(track_name = song_name, lyric = line) %>% 
  nest(lyric = lyric)

iwanfals_music_features_raw <- get_artist_audio_features("Iwan Fals", include_groups = c("album", "single")) %>% 
  as_tibble()

iwanfals <- 
  iwanfals_music_features_raw %>% 
  inner_join(iwanfals_lyrics) %>% 
  select(track_name, duration_ms, album_name, album_release_date, album_release_year, danceability:tempo, key_mode, lyric, -key)

save(iwanfals, file = "data/iwanfals.rda", compress = "bzip2", compression_level = 9)

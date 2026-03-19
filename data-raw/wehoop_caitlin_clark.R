
library(tidyverse)
library(wehoop)

## Finding games with Caitlin Clark:

seasons <- 2024:2025

wnba_gamelogs_cc <- seasons |>
  map(~(wehoop::wnba_playergamelogs(player_id = 1642286, season = .x))) |>
  map(pluck(1)) |>
  list_rbind() |>
  janitor::clean_names()

write_rds(wnba_gamelogs_cc, here::here("data/wnba_gamelogs_cc.rds"))

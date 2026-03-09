library(tidyverse)

wnba_gamelogs <- read_rds(here::here("data/wnba_gamelogs.rds"))

wnba_gamelogs_home <- wnba_gamelogs |>
  filter(!is_away)


# Add attendance to each game

wnba_attendance <- read_rds(here::here("data/wnba_attendance.rds"))

wnba_gl <- wnba_gamelogs_home |>
  left_join(
    wnba_attendance |>
      select(game_date, Team, attendance), 
    by = join_by(game_date, TEAM_NAME == Team)
  )

wnba_gl |>
  filter(is.na(attendance)) |>
  group_by(SEASON_ID, TEAM_ID) |>
  count() |>
  print(n = Inf)


# Add Caitlin Clark indicator

caitlin_clark <- read_rds(here::here("data/wnba_gamelogs_cc.rds"))

wnba_gl <- wnba_gl |>
  left_join(
    caitlin_clark |> mutate(is_cc = MIN > 0) |> select(GAME_ID, is_cc), 
    by = join_by(GAME_ID)
  ) |>
  mutate(is_cc = if_else(is.na(is_cc), 0, is_cc))






write_rds(wnba_gl, here::here("data/wnba_gl.rds"))



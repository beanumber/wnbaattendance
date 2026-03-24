library(tidyverse)

wnba_gl_elo <- read_rds(here::here("data/wnba_gl_elo.rds"))

# Add attendance to each game

wnba_attendance <- read_rds(here::here("data/wnba_attendance.rds"))

wnba_gl <- wnba_gl_elo |>
  left_join(
    wnba_attendance |>
      select(game_date, team, attendance, arena, arena_capacity), 
    by = join_by(game_date, team_name == team)
  )

wnba_gl |>
  filter(is.na(attendance)) |>
  group_by(season_id, team_id) |>
  count() |>
  print(n = Inf)

wnba_gl |>
  filter(is.na(attendance), team_id == 1611661325) |>
  group_by(team_name) |>
  count()

# San Antonio issue
wnba_gl |>
  filter(team_id == 1611661319) |>
  group_by(team_name, season_id) |>
  summarize(num_games = n(), num_missing = sum(is.na(attendance))) |>
  arrange(season_id) |>
  print(n = Inf)


# Add Caitlin Clark indicator

caitlin_clark <- read_rds(here::here("data/wnba_gamelogs_cc.rds")) |>
  janitor::clean_names()

wnba_gl <- wnba_gl |>
  left_join(
    caitlin_clark |> mutate(is_cc = min > 0) |> select(game_id, is_cc), 
    by = join_by(game_id)
  ) |>
  mutate(is_cc = if_else(is.na(is_cc), 0, is_cc))



write_rds(wnba_gl, here::here("data/wnba_gl.rds"))



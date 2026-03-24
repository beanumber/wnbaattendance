
library(tidyverse)

wnba_gamelogs <- read_rds(here::here("data/wnba_gamelogs.rds"))


## Compute active franchises

franchises <- wnba_gamelogs |>
  group_by(team_id) |>
  summarize(
    num_games = n(),
    team_names = paste(unique(team_name), collapse = "|"),
    season_first = min(season_id),
    season_last = max(season_id),
    name_current = last(team_name),
    is_active = season_last == 2025
  )

wnba_gl_active <- wnba_gamelogs |>
  left_join(franchises |> select(team_id, is_active, name_current), by = join_by(team_id))


## Rolling win counts for 44 past games (length of a wnba season)

wnba_gl_active <- wnba_gl_active |>
  group_by(team_id) |>
  mutate(
    # rolling window of PREVIOUS 44 games, so exclude current game
    rolling_wins_44 =
      slider::slide_int(
        win_flag,
        ~ sum(.x, na.rm = TRUE),
        .before = 44,
        .after = -1,      # exclude current game
        .complete = FALSE
      ),
    
    rolling_games_44 =
      slider::slide_int(
        win_flag,
        ~ length(.x),
        .before = 44,
        .after = -1,
        .complete = FALSE
      )
  ) |>
  ungroup()

## Include only home games -- eliminate duplicates

wnba_gamelogs_home <- wnba_gl_active |>
  filter(!is_away)

## Compute Elo ratings

wnba_gamelogs_home <- wnba_gamelogs_home |>
  mutate(opp_score = parse_number(pts) - parse_number(plus_minus))

library(elo)

elo <- elo.run(score(pts, opp_score) ~ team_id + opponent, data = wnba_gamelogs_home, k = 32) |>
  as.data.frame()

home_court_ad <- 12

wnba_gl_elo <- bind_cols(wnba_gamelogs_home, select(elo, contains("elo"))) |>
  mutate(
    home_win_prob = 1 / (1 + 10^((elo.B - (elo.A + home_court_ad)) / 400)),
    max_elo = pmax(elo.A, elo.B)
  )

wnba_gl_elo |>
  group_by(bin = cut(home_win_prob, breaks = 10)) |>
  summarize(
    num_games = n(),
    bin_midpoint = median(home_win_prob),
    home_win_wpct = mean(win_flag, na.rm = TRUE)
  ) |>
  mutate(diff = home_win_wpct - bin_midpoint) 
#|>
#  summarize(rmse = sqrt(mean(win_flag - home_win_prob, na.rm = TRUE)^2))



write_rds(wnba_gl_elo, here::here("data/wnba_gl_elo.rds"))

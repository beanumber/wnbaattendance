
library(tidyverse)
library(wehoop)

## Wrangling gamelog data from wehoop:

# 1. Pull league-wide gamelogs from wehoop

seasons <- 1997:2025

fetch_gamelog_season <- function(s) {
  res <- tryCatch(
    wnba_leaguegamelog(season = s, season_type = "Regular Season", league_id = "10"),
    error = function(e) {
      message(sprintf("wnba_leaguegamelog failed for season %s: %s", s, e$message))
      return(NULL)
    }
  )
  if (is.null(res)) return(NULL)
  
  as_tibble(res) |> 
    mutate(season = s)
}

gamelogs_raw <- seasons |>
  map(fetch_gamelog_season) |>
  bind_rows()

gamelogs <- gamelogs_raw$LeagueGameLog

# 2. clean gamelogs
gamelogs <- gamelogs |>
  janitor::clean_names() |>
  mutate(
    game_date = as.Date(game_date),
    win_flag = if_else(wl == "W", 1L, 0L),
    is_home    = str_detect(matchup, "vs"),
    is_away    = str_detect(matchup, "@"),
    opponent = str_extract(matchup, "[A-Z]{3}$")
  ) |>
  arrange(team_id, game_date)

# 3. rolling win counts for 44 past games (length of a wnba season)
wnba_gamelogs <- gamelogs |>
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


write_rds(wnba_gamelogs, file = "data/wnba_gamelogs.rds", compress = "xz")

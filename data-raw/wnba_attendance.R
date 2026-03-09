
library(tidyverse)

att_path <- here::here("data-raw/wnba_attendance")

att_files <- list.files(att_path, pattern = "\\.csv$", full.names = TRUE)

attendance_raw <- map_dfr(att_files, read_csv)

attendance_clean <- attendance_raw |>
  janitor::clean_names() |>
  mutate(
    game_date = as.Date(date, format = "%B %d, %Y"),
    attendance = as.integer(attendance)
  )




# They were the San Antonio Stars at home...
attendance_clean |>
  filter(str_detect(team, "San Antonio")) |>
  group_by(season = year(game_date), team) |>
  count()

# But the San Antonio Silver Stars on the road...
attendance_clean |>
  filter(str_detect(opponent, "San Antonio")) |>
  group_by(season = year(game_date), opponent) |>
  count()

attendance_clean <- attendance_clean |>
  mutate(
    team = ifelse(year(game_date) >= 2003 & year(game_date) <= 2013 & team == "San Antonio Stars", "San Antonio Silver Stars", team)
  )


write_rds(attendance_clean, file = "data/wnba_attendance.rds", compress = "xz")


library(tidyverse)

att_path <- here::here("data-raw/wnba_attendance")

att_files <- list.files(att_path, pattern = "\\.csv$", full.names = TRUE)

attendance_raw <- map_dfr(att_files, read_csv)

attendance_clean <- attendance_raw |>
  mutate(
    game_date = as.Date(Date, format = "%B %d, %Y"),
    attendance = as.integer(Attendance),
    Team = if_else(
      Team == "San Antonio Stars",
      "San Antonio Silver Stars",
      Team
    )
  )

write_csv(attendance_clean, "data/wnba_attendance.csv")

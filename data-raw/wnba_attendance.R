
library(tidyverse)

att_path <- here::here("data-raw/wnba_attendance")

att_files <- list.files(att_path, pattern = "\\.csv$", full.names = TRUE)

attendance_raw <- map_dfr(att_files, read_csv)

attendance_clean <- attendance_raw |>
  mutate(
    game_date = as.Date(Date, format = "%B %d, %Y"),
    attendance = as.integer(Attendance)
  )

write_rds(attendance_clean, file = "data/wnba_attendance.rds", compress = "xz")

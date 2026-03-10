
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



## Arena capacity

arenas <- tribble(
  ~arena, ~arena_capacity,
  "Alaska Airlines Arena", 9268,
  "Allstate Arena", 17500,
  "AmericanAirlines Arena", 19600,
  "American Airlines Center", 20409,
  "Amway Arena", 17306,
  "Angel of the Winds Arena", 8149,
  "ARCO Arena", 17317,
  "Arthur Ashe Stadium", 23000,
  "AT&T Center", 18418,
  "Bankers Life Fieldhouse", 18000,
  "Barclays Center", 17732,
  "BOK Center", 17839,
  "Capital One Arena", 20356,
  "CareFirst Arena", 4200,
  "CFG Bank Arena", 14000,
  "Chase Center", 18064,
  "Climate Pledge Arena", 18300,
  "College Park Center", 7000,
  "Compaq Center", 17071,
  "Conseco Fieldhouse", 17274,
  "Crypto.com Arena", 19079,
  "Dee Event Center", 11592,
  "EagleBank Arena", 10000,
  "EnergySolutions Arena", 18186,
  "Entertainment and Sports Arena", 4200,
  "Footprint Center", 17071,
  "Freeman Coliseum", 9800,
  "Gainbridge Fieldhouse", 18000,
  "Galen Center", 10258,
  "Gateway Center Arena @ College Park", 3500,
  "Great Western Forum", 17505,
  "Hartford Civic Center", 16294,
  "Hinkle Fieldhouse", 9100,
  "Home Depot Center Tennis Stadium", 7000,
  "Indiana Farmers Coliseum", 6500,
  "KeyArena", 17072,
  "Los Angeles Convention Center", 3500,
  "Madison Square Garden", 19812,
  "Mandalay Bay Events Center", 12000,
  "McCamish Pavilion", 8600,
  "Michelob ULTRA Arena", 12000,
  "Moda Center", 19393,
  "Mohegan Sun Arena", 10000,
  "Palace of Auburn Hills", 22076,
  "Philips Arena", 17608,
  "Phoenix Suns Arena", 17071,
  "PHX Arena", 17071,
  "Prudential Center", 18711,
  "Quicken Loans Arena", 20562,
  "Radio City Musical Hall", 5945,
  "Reliant Arena", 8000,
  "Rogers Arena", 19700,
  "Spectrum Center", 19077,
  "Spokane Arena", 11736,
  "Staples Center", 19079,
  "STAPLES Center", 19079,
  "State Farm Arena", 19050,
  "Strahan Coliseum", 7295,
  "T-Mobile Arena", 18000,
  "Talking Stick Resort Arena", 18422,
  "Target Center", 18798,
  "TD Garden", 19156,
  "Time Warner Cable Arena", 19444,
  "Toyota Center", 18055,
  "UIC Pavilion", 8000,
  "United Center", 20917,
  "US Airways Center", 17071,
  "Van Andel Arena", 11500,
  "Verizon Center", 20356,
  "Walter Pyramid at Long Beach State", 4200,
  "Westchester County Center", 2300,
  "Wintrust Arena", 10387,
  "Xcel Energy Center", 18600,
)

wnba_attendance <- attendance_clean |>
  left_join(arenas, by = "arena")

wnba_attendance |>
  filter(is.na(arena_capacity)) |>
  group_by(arena) |>
  count() |>
  arrange(desc(n))

write_rds(wnba_attendance, file = "data/wnba_attendance.rds", compress = "xz")

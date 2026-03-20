library(tidyverse)
library(tidycensus)

# Set your API key (only need to do this once)
# census_api_key("2c4b7b2488a6277854f4d4075fd50571f34882e9", overwrite = TRUE, install = TRUE)

# 1. Define the variables you want
# You can find these using load_variables(2022, "acs1", cache = TRUE)

v17 <- load_variables(2022, "acs1", cache = TRUE)
View(v17)

my_vars <- c(
  total_pop = "B01003_001",
  median_income = "B19013_001"
)


# 2. Get the list of the top 50 cities by population (using 2022 data)
cbsas <- get_acs(
  geography = "cbsa",
  variables = "B01003_001", # Total population
  year = 2022,
  survey = "acs5"
) |>
  slice_max(estimate, n = 100)

# 3. Pull data for multiple years (e.g., 2005 to 2022)
# We use map_dfr to loop through years and bind the results
years <- setdiff(2005:2023, 2020)
# Note: 2020 1-year data is missing due to the pandemic

city_history <- years |>
  map(~get_acs(geography = "cbsa", variables = my_vars, year = .x, survey = "acs1")) |>
  set_names(nm = years) |>
  list_rbind(names_to = "year")

cbsas <- city_history |>
  mutate(GEOID = parse_number(GEOID)) |>
  select(-moe) |>
  pivot_wider(names_from = variable, values_from = estimate) |> 
  group_by(GEOID) |>
  summarize(median_income = median(median_income), median_pop = median(total_pop))

cbsas <- cbsas |>
  # Vancouver, CA
  bind_rows(tibble(GEOID = 99999, median_income = 65500, median_pop = 2391252))

write_rds(cbsas, file = "data/cbsas.rds", compress = "xz")

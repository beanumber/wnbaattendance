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


# 2. Get the list of the top 100 cities by population (using 2022 data)
cbsas <- get_acs(
  geography = "cbsa",
  variables = "B01003_001", # Total population
  year = 2022,
  survey = "acs5"
) |>
  slice_max(estimate, n = 100)

# 3. Pull data for multiple years (e.g., 2005 to 2022)
# We use map_dfr to loop through years and bind the results
years <- setdiff(2005:2024, 2020)
# Note: 2020 1-year data is missing due to the pandemic

city_history <- years |>
  map(~get_acs(geography = "cbsa", variables = my_vars, year = .x, survey = "acs1")) |>
  set_names(nm = years) |>
  list_rbind(names_to = "year")

cbsas_usa <- city_history |>
  mutate(
    GEOID = parse_number(GEOID),
    year = parse_number(year)
  ) |>
  select(-moe) |>
  pivot_wider(names_from = variable, values_from = estimate)


################## Vancouver

library(cansim)

# 1. Fetch the relevant table from the StatCan API
# This returns an already tidied data frame
income_table <- get_cansim("11-10-0239-01")

# 2. Filter for Vancouver CMA and extract your target variables
vancouver_clean <- income_table |>
  filter(
    GEO == "Vancouver, British Columbia"
    Gender == "Total - Gender"
  ) |>
  filter(
    `Income concept` == "Median family total income" | 
      Characteristics == "Total population"
  ) |>
  select(
    year = REF_DATE, 
    metric = Characteristics, 
    concept = `Income concept`, 
    value = VALUE
  )

print(head(vancouver_clean))

######################## 


cbsas_all <- cbsas_usa |>
  # Vancouver, CA
  bind_rows(tibble(year = 2023, GEOID = 99999, NAME = "Vancouver, CA", median_income = 65500, total_pop = 2391252))



###############################

cbsas <- expand_grid(year = 2005:2025, cbsa_id = unique(cbsas_all$GEOID)) |>
  left_join(cbsas_all, by = join_by(year, cbsa_id == GEOID))




write_rds(cbsas, file = "data/cbsas.rds", compress = "xz")

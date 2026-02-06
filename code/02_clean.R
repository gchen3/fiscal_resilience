# 02_clean.R
# Clean raw data and create tidy datasets.

# Load intermediate files ---------------------------------------------------------------
# here::here("data", "OSC", "city_data_all.rds")), county, town, school

city_data_all <- readr::read_rds(here::here("data", "OSC", "city_data_all.rds"))
county_data_all <- readr::read_rds(here::here("data", "OSC", "county_data_all.rds"))
town_data_all <- readr::read_rds(here::here("data", "OSC", "town_data_all.rds"))
school_data_all <- readr::read_rds(here::here("data", "OSC", "school_data_all.rds"))

# Clean data -------------------------------------------------------------------------------
head(city_data_all)
city_data_clean <- city_data_all %>%
  dplyr::mutate(
    dplyr::across(where(is.character), ~ gsub("'", "", .x))
  ) %>%
  dplyr::mutate(
    year = as.numeric(year),
    calendar_year = as.numeric(calendar_year),
    amount = as.numeric(amount)
  ) %>%
  mutate(across(where(is.character), tolower))

# Define a function to get variable using filtering
generate_finance <- function(data, var_name, filter_statement) {
  results <- data |>
    filter(eval(rlang::parse_expr(filter_statement))) |>
    select(calendar_year, entity_name, municipal_code, amount) |>
    group_by(calendar_year, entity_name, municipal_code) |>
    summarize(!!var_name := sum(amount, na.rm = TRUE), .groups = 'drop')
  
  assign(var_name, results, envir = .GlobalEnv)
}

# Extract unique expenditures and revenues categories
# financial_statement_segment <- city_data_clean %>%
#   distinct(financial_statement_segment) %>%
#   arrange(financial_statement_segment)

# financial_statement_segment

# account_code_section <- city_data_clean %>%
#   distinct(account_code_section) %>%
#   arrange(account_code_section)

# account_code_section

level_1_spending <- city_data_clean %>%
  filter(financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure') %>%
  distinct(level_1_category) %>%
  arrange(level_1_category)

level_2_spending <- city_data_clean %>%
  filter(financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure') %>%
  distinct(level_2_category) %>%
  arrange(level_2_category)

level_1_revenues <- city_data_clean %>%
  filter(financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue') %>%
  distinct(level_1_category) %>%
  arrange(level_1_category)

level_2_revenues <- city_data_clean %>%
  filter(financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue') %>%
  distinct(level_2_category) %>%
  arrange(level_2_category)

# spending_objects <- city_data_clean %>%
#   filter(financial_statement_segment == 'expenditures' |
#                       financial_statement_segment == 'expenditure' |
#                        account_code_section == 'expenditures' |
#                        account_code_section == 'expenditure') %>%
#   distinct(object_of_expenditure) %>%
#   arrange(object_of_expenditure) 

# Define variables to extract
data <- city_data_clean
var_name <- "expenditures"
filter_statement <- "financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure' "
generate_finance(data, var_name, filter_statement)

var_name <- "revenues"
filter_statement <- "financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue' "
generate_finance(data, var_name, filter_statement)

# for each level 1 spending category
for (category in level_1_spending$level_1_category) {
  var_name <- paste0("exp_L1_", stringr::str_replace_all(category, " ", "_"))
  filter_statement <- paste0("(level_1_category == '", category, "') & (financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure') ")
  generate_finance(data, var_name, filter_statement)
}

# generalize to level 2 spending category 
for (category in level_2_spending$level_2_category) {
  var_name <- paste0("exp_L2_", stringr::str_replace_all(category, " ", "_"))
  filter_statement <- paste0("(level_2_category == '", category, "') & (financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure') ")
  generate_finance(data, var_name, filter_statement)
}

# for each level 1 revenue category
for (category in level_1_revenues$level_1_category) {
  var_name <- paste0("rev_L1_", stringr::str_replace_all(category, " ", "_"))
  filter_statement <- paste0("(level_1_category == '", category, "') & (financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue') ")
  generate_finance(data, var_name, filter_statement)
} 

# for each level 2 revenue category
for (category in level_2_revenues$level_2_category) {
  var_name <- paste0("rev_L2_", stringr::str_replace_all(category, " ", "_"))
  filter_statement <- paste0("(level_2_category == '", category, "') & (financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue') ")
  generate_finance(data, var_name, filter_statement)
}

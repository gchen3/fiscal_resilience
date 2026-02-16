# 02_clean.R
# Clean raw data and create tidy datasets.
# NOTE:
# - This script creates generated finance objects in .GlobalEnv.
# - Naming convention is <entity_prefix>_<variable>, e.g. city_expenditures,
#   county_exp_L1_general_government, school_rev_L2_real_property_taxes.
# - 03_merge.R depends on these generated objects, so run 02_clean.R first.

# Load intermediate files ---------------------------------------------------------------
# here::here("data", "OSC", "city_data_all.rds")), county, town, school

city_data_all <- readr::read_rds(here::here("data", "OSC", "city_data_all.rds"))
county_data_all <- readr::read_rds(here::here("data", "OSC", "county_data_all.rds"))
town_data_all <- readr::read_rds(here::here("data", "OSC", "town_data_all.rds"))
school_data_all <- readr::read_rds(here::here("data", "OSC", "school_data_all.rds"))

# Clean data -------------------------------------------------------------------------------
clean_finance_data <- function(data) {
  data %>%
  dplyr::mutate(
    dplyr::across(where(is.character), ~ gsub("'", "", .x))
  ) %>%
  dplyr::mutate(
    year = as.numeric(year),
    calendar_year = as.numeric(calendar_year),
    amount = as.numeric(amount)
  ) %>%
  mutate(across(where(is.character), tolower))
}

city_data_clean <- clean_finance_data(city_data_all)
county_data_clean <- clean_finance_data(county_data_all)
town_data_clean <- clean_finance_data(town_data_all)
school_data_clean <- clean_finance_data(school_data_all)

# Define a function to get variable using filtering
generate_finance <- function(data, var_name, filter_statement, entity_prefix = NULL) {
  results <- data |>
    filter(!!rlang::parse_expr(filter_statement)) |>
    select(calendar_year, entity_name, municipal_code, amount) |>
    group_by(calendar_year, entity_name, municipal_code) |>
    summarize(!!var_name := sum(amount, na.rm = TRUE), .groups = 'drop')

  output_name <- if (is.null(entity_prefix)) var_name else paste0(entity_prefix, "_", var_name)
  assign(output_name, results, envir = .GlobalEnv)
}

clean_var_suffix <- function(x) {
  x %>%
    stringr::str_replace_all("[^a-zA-Z0-9]+", "_") %>%
    stringr::str_replace_all("_+", "_") %>%
    stringr::str_replace_all("^_|_$", "")
}

expenditure_filter <- "financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure'"

revenue_filter <- "financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue'"

generate_entity_finance_vars <- function(data, entity_prefix) {
  # Categories are derived separately within each entity type.
  # This allows city/county/town/school to have different available categories.
  level_1_spending <- data %>%
    filter(!!rlang::parse_expr(expenditure_filter)) %>%
    distinct(level_1_category) %>%
    filter(!is.na(level_1_category), level_1_category != "") %>%
    arrange(level_1_category)

  level_2_spending <- data %>%
    filter(!!rlang::parse_expr(expenditure_filter)) %>%
    distinct(level_2_category) %>%
    filter(!is.na(level_2_category), level_2_category != "") %>%
    arrange(level_2_category)

  level_1_revenues <- data %>%
    filter(!!rlang::parse_expr(revenue_filter)) %>%
    distinct(level_1_category) %>%
    filter(!is.na(level_1_category), level_1_category != "") %>%
    arrange(level_1_category)

  level_2_revenues <- data %>%
    filter(!!rlang::parse_expr(revenue_filter)) %>%
    distinct(level_2_category) %>%
    filter(!is.na(level_2_category), level_2_category != "") %>%
    arrange(level_2_category)

  generate_finance(data, "expenditures", expenditure_filter, entity_prefix)
  generate_finance(data, "revenues", revenue_filter, entity_prefix)

  for (category in level_1_spending$level_1_category) {
    var_name <- paste0("exp_L1_", clean_var_suffix(category))
    filter_statement <- paste0("(level_1_category == '", category, "') & (", expenditure_filter, ")")
    generate_finance(data, var_name, filter_statement, entity_prefix)
  }

  for (category in level_2_spending$level_2_category) {
    var_name <- paste0("exp_L2_", clean_var_suffix(category))
    filter_statement <- paste0("(level_2_category == '", category, "') & (", expenditure_filter, ")")
    generate_finance(data, var_name, filter_statement, entity_prefix)
  }

  for (category in level_1_revenues$level_1_category) {
    var_name <- paste0("rev_L1_", clean_var_suffix(category))
    filter_statement <- paste0("(level_1_category == '", category, "') & (", revenue_filter, ")")
    generate_finance(data, var_name, filter_statement, entity_prefix)
  }

  for (category in level_2_revenues$level_2_category) {
    var_name <- paste0("rev_L2_", clean_var_suffix(category))
    filter_statement <- paste0("(level_2_category == '", category, "') & (", revenue_filter, ")")
    generate_finance(data, var_name, filter_statement, entity_prefix)
  }
}

generate_entity_finance_vars(city_data_clean, "city")
generate_entity_finance_vars(county_data_clean, "county")
generate_entity_finance_vars(town_data_clean, "town")
generate_entity_finance_vars(school_data_clean, "school")

# At this point, .GlobalEnv contains many generated objects per entity prefix.
# 03_merge.R consolidates them into one merged table per entity type.

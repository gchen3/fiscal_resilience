# functions/finance.R
# Pure helper functions for OSC finance data: cleaning, category/object extraction,
# and the generated-variable convention used by 20_clean.R and 30_merge.R.
# Definitions only — no side effects, no I/O. Sourced by 00_library.R.
# Reusable code uses explicit dplyr:: qualifiers (per AGENTS.md style).
#
# NOTE: generate_finance() and generate_entity_finance_vars() write generated objects
# into .GlobalEnv (the convention 30_merge.R relies on). This is the existing pipeline
# design; see CLAUDE.md "The .GlobalEnv generated-object convention".

# Segment predicates: tolerate OSC's singular/plural and the schema-era difference
# (financial_statement_segment pre-2013, account_code_section 2013+).
expenditure_filter <- "financial_statement_segment == 'expenditures' |
                      financial_statement_segment == 'expenditure' |
                       account_code_section == 'expenditures' |
                       account_code_section == 'expenditure'"

revenue_filter <- "financial_statement_segment == 'revenues' |
                      financial_statement_segment == 'revenue' |
                       account_code_section == 'revenues' |
                       account_code_section == 'revenue'"

# Strip apostrophes, coerce key numerics, lowercase all character columns.
clean_finance_data <- function(data) {
  data %>%
    dplyr::mutate(
      dplyr::across(tidyselect::where(is.character), ~ gsub("'", "", .x))
    ) %>%
    dplyr::mutate(
      year = as.numeric(year),
      calendar_year = as.numeric(calendar_year),
      amount = as.numeric(amount)
    ) %>%
    dplyr::mutate(dplyr::across(tidyselect::where(is.character), tolower))
}

# Filter to a subset, sum `amount` by entity-year, and assign the one-metric table
# into .GlobalEnv as <entity_prefix>_<var_name>.
generate_finance <- function(data, var_name, filter_statement, entity_prefix = NULL) {
  results <- data |>
    dplyr::filter(!!rlang::parse_expr(filter_statement)) |>
    dplyr::select(calendar_year, entity_name, municipal_code, amount) |>
    dplyr::group_by(calendar_year, entity_name, municipal_code) |>
    dplyr::summarize(!!var_name := sum(amount, na.rm = TRUE), .groups = 'drop')

  output_name <- if (is.null(entity_prefix)) var_name else paste0(entity_prefix, "_", var_name)
  assign(output_name, results, envir = .GlobalEnv)
}

# Normalize a category label into a snake_case variable suffix.
clean_var_suffix <- function(x) {
  x %>%
    stringr::str_replace_all("[^a-zA-Z0-9]+", "_") %>%
    stringr::str_replace_all("_+", "_") %>%
    stringr::str_replace_all("^_|_$", "")
}

# Generate the full set of finance variables for one entity type (totals + each
# L1/L2 revenue and expenditure category). Categories are derived separately per
# entity type, so city/county/town/school can have different available categories.
generate_entity_finance_vars <- function(data, entity_prefix) {
  level_1_spending <- data %>%
    dplyr::filter(!!rlang::parse_expr(expenditure_filter)) %>%
    dplyr::distinct(level_1_category) %>%
    dplyr::filter(!is.na(level_1_category), level_1_category != "") %>%
    dplyr::arrange(level_1_category)

  level_2_spending <- data %>%
    dplyr::filter(!!rlang::parse_expr(expenditure_filter)) %>%
    dplyr::distinct(level_2_category) %>%
    dplyr::filter(!is.na(level_2_category), level_2_category != "") %>%
    dplyr::arrange(level_2_category)

  level_1_revenues <- data %>%
    dplyr::filter(!!rlang::parse_expr(revenue_filter)) %>%
    dplyr::distinct(level_1_category) %>%
    dplyr::filter(!is.na(level_1_category), level_1_category != "") %>%
    dplyr::arrange(level_1_category)

  level_2_revenues <- data %>%
    dplyr::filter(!!rlang::parse_expr(revenue_filter)) %>%
    dplyr::distinct(level_2_category) %>%
    dplyr::filter(!is.na(level_2_category), level_2_category != "") %>%
    dplyr::arrange(level_2_category)

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

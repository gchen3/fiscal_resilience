# 60_descriptives.R
# Descriptive statistics and summary tables.

merged_dir <- here::here("data", "processed_data")

city_data_merged <- readr::read_rds(file.path(merged_dir, "city_data_merged.rds"))
county_data_merged <- readr::read_rds(file.path(merged_dir, "county_data_merged.rds"))
town_data_merged <- readr::read_rds(file.path(merged_dir, "town_data_merged.rds"))
school_data_merged <- readr::read_rds(file.path(merged_dir, "school_data_merged.rds"))

summarize_entity_data <- function(data) {
  n_entity <- data %>%
    dplyr::distinct(entity_name, municipal_code) %>%
    nrow()

  n_years <- dplyr::n_distinct(data$calendar_year)

  level_1_vars <- names(data) %>%
    stringr::str_subset("^(exp_L1_|rev_L1_)")

  purrr::map_dfr(level_1_vars, function(var_name) {
    x <- data[[var_name]]

    tibble::tibble(
      variable = var_name,
      n = sum(!is.na(x)),
      mean = mean(x, na.rm = TRUE),
      sd = stats::sd(x, na.rm = TRUE),
      min = suppressWarnings(min(x, na.rm = TRUE)),
      max = suppressWarnings(max(x, na.rm = TRUE)),
      n_entity = n_entity,
      n_years = n_years
    )
  }) %>%
    dplyr::mutate(
      min = dplyr::if_else(is.infinite(min), NA_real_, min),
      max = dplyr::if_else(is.infinite(max), NA_real_, max)
    )
}

make_summary_gt <- function(summary_data, table_title) {
  summary_data %>%
    gt::gt() %>%
    gt::tab_header(title = table_title) %>%
    gt::cols_label(
      variable = "Variable",
      n = "N",
      mean = "Mean",
      sd = "SD",
      min = "Min",
      max = "Max",
      n_entity = "N Entity",
      n_years = "N Years"
    ) %>%
    gt::fmt_number(columns = c(mean, sd, min, max), decimals = 2) %>%
    gt::fmt_number(columns = c(n, n_entity, n_years), decimals = 0)
}

city_summary_stats <- summarize_entity_data(city_data_merged)
county_summary_stats <- summarize_entity_data(county_data_merged)
town_summary_stats <- summarize_entity_data(town_data_merged)
district_summary_stats <- summarize_entity_data(school_data_merged)

city_summary_stats_gt <- make_summary_gt(city_summary_stats, "City Level-1 Variable Summary Statistics")
county_summary_stats_gt <- make_summary_gt(county_summary_stats, "County Level-1 Variable Summary Statistics")
town_summary_stats_gt <- make_summary_gt(town_summary_stats, "Town Level-1 Variable Summary Statistics")
district_summary_stats_gt <- make_summary_gt(district_summary_stats, "District Level-1 Variable Summary Statistics")

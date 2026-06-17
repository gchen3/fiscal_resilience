# 30_merge.R
# Merge datasets into analysis-ready tables.
# NOTE:
# - Run 20_clean.R before this script (same session).
# - This script expects generated objects named <entity_prefix>_<variable>
#   in .GlobalEnv and merges them by year/entity/code.
# - After merge, it removes intermediate category objects and keeps only
#   *_data_merged for each entity prefix, then writes .rds outputs.

key_cols <- c("calendar_year", "entity_name", "municipal_code")

merge_generated_entity_vars <- function(entity_prefix, clean_data) {
  # Base key table ensures every observed entity-year remains in output,
  # even when some generated variables are missing.
  base_data <- clean_data %>%
    dplyr::distinct(dplyr::across(dplyr::all_of(key_cols)))

  candidate_names <- ls(envir = .GlobalEnv, pattern = paste0("^", entity_prefix, "_"))
  excluded_names <- c(
    paste0(entity_prefix, "_data_all"),
    paste0(entity_prefix, "_data_clean")
  )

  object_names <- setdiff(candidate_names, excluded_names) %>%
    sort()

  generated_tables <- object_names %>%
    purrr::map(~ get(.x, envir = .GlobalEnv)) %>%
    purrr::keep(
      # Keep only generated one-variable finance tables:
      # key cols + one generated metric column.
      ~ is.data.frame(.x) &&
        all(key_cols %in% names(.x)) &&
        ncol(.x) == (length(key_cols) + 1)
    )

  if (length(generated_tables) == 0) {
    return(base_data %>% dplyr::arrange(dplyr::across(dplyr::all_of(key_cols))))
  }

  merged_data <- purrr::reduce(
    generated_tables,
    ~ dplyr::full_join(.x, .y, by = key_cols),
    .init = base_data
  )

  merged_data %>%
    dplyr::arrange(dplyr::across(dplyr::all_of(key_cols)))
}

city_data_merged <- merge_generated_entity_vars("city", city_data_clean)
county_data_merged <- merge_generated_entity_vars("county", county_data_clean)
town_data_merged <- merge_generated_entity_vars("town", town_data_clean)
school_data_merged <- merge_generated_entity_vars("school", school_data_clean)

cleanup_entity_objects <- function(entity_prefix) {
  # Remove all prefix-matched objects except the merged output.
  keep_name <- paste0(entity_prefix, "_data_merged")
  remove_names <- ls(envir = .GlobalEnv, pattern = paste0("^", entity_prefix, "_"))
  remove_names <- setdiff(remove_names, keep_name)

  if (length(remove_names) > 0) {
    rm(list = remove_names, envir = .GlobalEnv)
  }
}

cleanup_entity_objects("city")
cleanup_entity_objects("county")
cleanup_entity_objects("town")
cleanup_entity_objects("school")

processed_dir <- here::here("data", "processed_data")
if (!dir.exists(processed_dir)) {
  dir.create(processed_dir, recursive = TRUE)
}

readr::write_rds(city_data_merged, file.path(processed_dir, "city_data_merged.rds"))
readr::write_rds(county_data_merged, file.path(processed_dir, "county_data_merged.rds"))
readr::write_rds(town_data_merged, file.path(processed_dir, "town_data_merged.rds"))
readr::write_rds(school_data_merged, file.path(processed_dir, "school_data_merged.rds"))

# Output files:
# data/processed_data/city_data_merged.rds
# data/processed_data/county_data_merged.rds
# data/processed_data/town_data_merged.rds
# data/processed_data/school_data_merged.rds

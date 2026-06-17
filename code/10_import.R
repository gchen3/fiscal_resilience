# 10_import.R
# Import raw data and save intermediate files.

data_path <- here::here("data", "OSC", "all_classes_years")

# Load data to one large list ---------------------------------------------------------------
begin_year <- 1995 # The year indicates fiscal year
end_year <- 2025 # The year indicates fiscal year

city_data <- list()
county_data <- list()
town_data <- list()
school_data <- list()

for (year in begin_year:end_year) {
  # City
  filename_city <- paste0(year, "_City.csv")
  city_data[[as.character(year)]] <- vroom::vroom(
    here::here(data_path, filename_city),
    col_types = vroom::cols(.default = vroom::col_character())
  )
  names(city_data[[as.character(year)]]) <- tolower(names(city_data[[as.character(year)]]))

  # County
  filename_county <- paste0(year, "_County.csv")
  county_data[[as.character(year)]] <- vroom::vroom(
    here::here(data_path, filename_county),
    col_types = vroom::cols(.default = vroom::col_character())
  )
  names(county_data[[as.character(year)]]) <- tolower(names(county_data[[as.character(year)]]))

  # Town
  filename_town <- paste0(year, "_Town.csv")
  town_data[[as.character(year)]] <- vroom::vroom(
    here::here(data_path, filename_town),
    col_types = vroom::cols(.default = vroom::col_character())
  )
  names(town_data[[as.character(year)]]) <- tolower(names(town_data[[as.character(year)]]))

  # School district
  filename_school <- paste0(year, "_SchoolDistrict.csv")
  school_data[[as.character(year)]] <- vroom::vroom(
    here::here(data_path, filename_school),
    col_types = vroom::cols(.default = vroom::col_character())
  )
  names(school_data[[as.character(year)]]) <- tolower(names(school_data[[as.character(year)]]))
}

# Merge across years ---------------------------------------------------------------
merge_years <- function(data_list) {
  merged <- dplyr::bind_rows(data_list, .id = "year")
  names(merged) <- tolower(names(merged))
  merged$year <- as.integer(merged$year)

  if ("account_code" %in% names(merged)) {
    merged$account_code_letter <- stringr::str_extract(merged$account_code, "^[A-Za-z]+")
    merged$account_code_number <- stringr::str_extract(merged$account_code, "[0-9]+")
  }

  merged
}

city_data_all <- merge_years(city_data)
county_data_all <- merge_years(county_data)
town_data_all <- merge_years(town_data)
school_data_all <- merge_years(school_data)

# Save merged data ---------------------------------------------------------------
output_dir <- here::here("data", "OSC")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

saveRDS(city_data_all, file = here::here("data", "OSC", "city_data_all.rds"))
saveRDS(county_data_all, file = here::here("data", "OSC", "county_data_all.rds"))
saveRDS(town_data_all, file = here::here("data", "OSC", "town_data_all.rds"))
saveRDS(school_data_all, file = here::here("data", "OSC", "school_data_all.rds"))

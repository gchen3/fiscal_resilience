# 20_clean.R
# Clean raw data and create tidy datasets. Thin orchestration — the functions live in
# code/functions/finance.R (sourced by 00_library.R).
# NOTE:
# - This script creates generated finance objects in .GlobalEnv.
# - Naming convention is <entity_prefix>_<variable>, e.g. city_expenditures,
#   county_exp_L1_general_government, school_rev_L2_real_property_taxes.
# - 30_merge.R depends on these generated objects, so run 20_clean.R first (same session).

# Load intermediate files ---------------------------------------------------------------
city_data_all <- readr::read_rds(here::here("data", "OSC", "city_data_all.rds"))
county_data_all <- readr::read_rds(here::here("data", "OSC", "county_data_all.rds"))
town_data_all <- readr::read_rds(here::here("data", "OSC", "town_data_all.rds"))
school_data_all <- readr::read_rds(here::here("data", "OSC", "school_data_all.rds"))

# Clean -----------------------------------------------------------------------------------
city_data_clean <- clean_finance_data(city_data_all)
county_data_clean <- clean_finance_data(county_data_all)
town_data_clean <- clean_finance_data(town_data_all)
school_data_clean <- clean_finance_data(school_data_all)

# Generate finance variables into .GlobalEnv ---------------------------------------------
generate_entity_finance_vars(city_data_clean, "city")
generate_entity_finance_vars(county_data_clean, "county")
generate_entity_finance_vars(town_data_clean, "town")
generate_entity_finance_vars(school_data_clean, "school")

# At this point, .GlobalEnv contains many generated objects per entity prefix.
# 30_merge.R consolidates them into one merged table per entity type.

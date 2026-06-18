# 40_construct_resilience.R
# Variable construction (OUTCOMES): build the fiscal-resilience dependent variables.
# Spec: plan_docs/01_fiscal_resilience_dv_plan.md   Functions: code/functions/resilience.R
#
# Built here now: DV1 (General Fund balance buffer), DV2 (operating expenditure-gap
# sensitivity), DV4 (revenue-gap sensitivity: total / own-source / tax), and DV3 (shock
# recovery trajectory — drawdown + time-to-recover around 2009/2020; plan_docs/03).
#
# Reads:  data/OSC/<entity>_data_all.rds   (RAW all-years — retains object/fund/statement)
#         data/reference/price_index.csv   (CPI-U annual avg; deflates DV3 to real dollars)
# Writes: data/processed_data/<entity>_resilience.rds   (entity-year: DV1/DV2/DV4)
#         data/processed_data/<entity>_recovery.rds      (entity x shock x series: DV3)
#
# Fund scope = General Fund (account-code letter "A"). NOTE: "A = General Fund" is a
# city/county/town convention. School districts use a different chart of accounts, so
# `school` is intentionally NOT processed here until the General Fund identifier is
# verified for schools (plan §12 generalization caveat).

processed_dir <- here::here("data", "processed_data")
if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)

entities <- c("city", "county", "town")   # add "school" after verifying its General Fund code

# DV3 deflator: CPI-U annual average -> real-dollar factor, base year 2023 (plan_docs/03 §8).
# Deflating by price_index expresses every year's $ in base-year (2023) purchasing power.
cpi <- readr::read_csv(here::here("data", "reference", "price_index.csv"),
                       show_col_types = FALSE) %>%
  dplyr::mutate(price_index = .data$cpi_u / .data$cpi_u[.data$calendar_year == 2023])

# DV3 target spec + builder live in functions/resilience.R (recovery_targets_default,
# build_entity_recovery): reserves = available_fb_ratio (level depth, no deflation); revenue /
# expenditure = proportional depth on CPI-U-deflated real dollars (plan_docs/03 §3).

for (entity in entities) {
  raw_path <- here::here("data", "OSC", paste0(entity, "_data_all.rds"))
  message("Building resilience DVs for: ", entity)

  raw <- readr::read_rds(raw_path)
  res <- build_resilience(raw, entity_label = entity,
                          fund = "A", drop_years = 2025, min_years = 8, min_group = 5)

  readr::write_rds(res, file.path(processed_dir, paste0(entity, "_resilience.rds")))
  message("  wrote ", entity, "_resilience.rds  (",
          nrow(res), " entity-years, ",
          dplyr::n_distinct(res$entity_name, res$municipal_code), " entities)")

  # DV3: shock recovery trajectory (entity x shock x series).
  recov <- build_entity_recovery(res, entity, deflator = cpi)
  readr::write_rds(recov, file.path(processed_dir, paste0(entity, "_recovery.rds")))
  message("  wrote ", entity, "_recovery.rds  (", nrow(recov), " unit-shock-series rows)")
}

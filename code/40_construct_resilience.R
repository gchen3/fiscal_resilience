# 40_construct_resilience.R
# Variable construction (OUTCOMES): build the fiscal-resilience dependent variables.
# Spec: plan_docs/01_fiscal_resilience_dv_plan.md   Functions: code/functions/resilience.R
#
# Built here now: DV1 (General Fund balance buffer), DV2 (operating expenditure-gap
# sensitivity), and DV4 (revenue-gap sensitivity: total / own-source / tax). DV3 (shock
# recovery trajectory) is a planned extension.
#
# Reads:  data/OSC/<entity>_data_all.rds   (RAW all-years — retains object/fund/statement)
# Writes: data/processed_data/<entity>_resilience.rds
#
# Fund scope = General Fund (account-code letter "A"). NOTE: "A = General Fund" is a
# city/county/town convention. School districts use a different chart of accounts, so
# `school` is intentionally NOT processed here until the General Fund identifier is
# verified for schools (plan §12 generalization caveat).

processed_dir <- here::here("data", "processed_data")
if (!dir.exists(processed_dir)) dir.create(processed_dir, recursive = TRUE)

entities <- c("city", "county", "town")   # add "school" after verifying its General Fund code

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
}

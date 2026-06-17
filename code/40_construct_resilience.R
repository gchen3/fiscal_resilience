# 40_construct_resilience.R
# Variable construction (OUTCOMES): build the fiscal-resilience dependent variables
# (DV1 fund-balance buffer, DV2 expenditure-gap sensitivity, DV3 recovery, DV4 revenue gap).
# Spec: plan_docs/01_fiscal_resilience_dv_plan.md
#
# Reads:  data/OSC/<entity>_data_all.rds   (RAW all-years — retains object/fund/statement)
# Writes: data/processed_data/<entity>_resilience.rds
# Uses:   functions/resilience.R
# Note:   rebuild from RAW, not the merged tables (object_of_expenditure, fund letter,
#         and the balance sheet were dropped during 20_clean/30_merge).
#
# Prototype on cities first, then generalize (verify "General Fund = A" per entity type).

# TODO: implement per plan §6–§9.

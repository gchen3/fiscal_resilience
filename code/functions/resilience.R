# functions/resilience.R
# Pure functions to construct the fiscal-resilience dependent variables.
# See plan_docs/01_fiscal_resilience_dv_plan.md for the full specification.
# Definitions only — no side effects, no I/O. Sourced by 00_library.R.
#
# Planned helpers (see plan §6–§9):
#   - extract_general_fund_balance()  # DV1: era-aware fund-balance splice (GASB 54 adaptive rule)
#   - build_operating_base()          # DV2/DV4: object-class scoped General Fund base
#   - expenditure_gap()               # short-run + long-run (log-linear trend) gaps
#   - sensitivity()                   # relative DV: gap / (size_class x year) group mean
#   - recovery_trajectory()           # DV3: drawdown depth + time-to-recovery around shocks
#   - build_resilience()              # top-level driver, generalized across entity types

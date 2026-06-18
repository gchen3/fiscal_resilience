# Main Variable Registery: Resilience Outcomes

Focused summary of the main fiscal-resilience dependent variables constructed in
`code/40_construct_resilience.R` using helper functions in `code/functions/resilience.R`.
The longer audit trail is in `transparency/variable_registry.md`.

## Scope

- **Unit of observation:** entity-year, keyed by `calendar_year`, `entity_name`, and
  `municipal_code`.
- **Entities currently processed:** cities, counties, and towns. School districts are held
  back until the correct General Fund code is verified.
- **Fund scope:** General Fund only, identified by account-code letter `A`.
- **Source files:** `data/OSC/<entity>_data_all.rds`, created from NYS OSC annual finance
  CSVs.
- **Year handling:** FY2025 is dropped because it is incomplete in the source data.
- **Output files:** `data/processed_data/<entity>_resilience.rds`.

## Core Measurement Logic

All measures use OSC financial statement rows normalized to lowercase classification fields,
numeric `amount`, and a derived fund letter. Expenditure and revenue rows are detected across
both older and newer OSC schema conventions (`financial_statement_segment` and
`account_code_section`).

## Main Resilience Variables

| Construct | Variables | Measurement | Interpretation |
|---|---|---|---|
| Fund-balance buffer | `fb_ratio` | `total_fund_balance / gf_total_exp` | Higher values indicate a larger overall General Fund reserve buffer relative to spending. |
| Available fund-balance buffer | `available_fb_ratio` | `available_fb / gf_total_exp` | Higher values indicate more spendable or flexible reserve capacity relative to spending. |
| Short-run expenditure gap | `exp_gap_sr` | `abs(gf_operating_exp_t - gf_operating_exp_t-1) / gf_operating_exp_t-1`, only for consecutive years | Larger values mean greater year-to-year operating expenditure instability. |
| Long-run expenditure gap | `exp_gap_lr` | `abs(E - Ehat) / Ehat`, where `Ehat` comes from an entity-specific log-linear trend in operating expenditure | Larger values mean expenditure deviates more from the entity's long-run trend. |
| Relative expenditure sensitivity | `sensitivity_sr`, `sensitivity_lr` | Expenditure gap divided by the mean gap in the same `size_class x calendar_year` cell | Values above 1 mean the unit is more volatile than comparable-size peers in that year. |
| Total revenue gap | `rev_total_gap_sr`, `rev_total_gap_lr` | Same short-run and long-run gap formulas applied to `rev_total` | Larger values mean total operating revenue is less stable. |
| Own-source revenue gap | `rev_own_gap_sr`, `rev_own_gap_lr` | Same gap formulas applied to `rev_own` | Larger values mean locally controlled revenue sources are less stable. |
| Tax revenue gap | `rev_tax_gap_sr`, `rev_tax_gap_lr` | Same gap formulas applied to `rev_tax` | Larger values mean property/sales tax revenue is less stable. |
| Relative revenue sensitivity | `rev_total_sens_*`, `rev_own_sens_*`, `rev_tax_sens_*` | Revenue gap divided by the mean gap in the same `size_class x calendar_year` cell | Values above 1 mean the unit has higher revenue volatility than comparable-size peers. |

## Base Variables

| Variable | Construction |
|---|---|
| `gf_total_exp` | Sum of General Fund expenditure rows excluding interfund transfers. Used as the fund-balance denominator. |
| `gf_operating_exp` | Sum of General Fund expenditure rows whose object is `personal services`, `contractual`, or `employee benefits`. Used as the expenditure-stability base. |
| `total_fund_balance` | General Fund ending fund balance, extracted from newer `fbnp` rows or older balance-sheet equity fund-balance components. |
| `available_fb` | Broad available balance: pre-GASB 54 unreserved balance where present; otherwise unassigned plus assigned fund balance. |
| `unassigned_fb` | Narrow available balance: pre-GASB 54 unreserved balance where present; otherwise unassigned fund balance. |
| `rev_total` | General Fund operating revenue, excluding financing categories `proceeds of debt` and `other sources`. |
| `rev_own` | Own-source revenue: `rev_total` excluding `state aid`, `federal aid`, and `charges to other governments`. |
| `rev_tax` | Tax revenue from `real property taxes and assessments` plus `sales and use tax`. |
| `size_class` | Static quintile, within entity type, based on time-averaged `gf_operating_exp`. Used for peer-normalized sensitivity measures. |

## Notes and Planned Extensions

- Short-run gaps require consecutive prior-year observations and positive prior-year bases.
- Long-run gaps require at least eight positive observations for an entity-specific trend.
- Peer-relative sensitivity is suppressed when fewer than five non-missing units exist in a
  `size_class x calendar_year` cell.
- DV3, a shock recovery trajectory measure (drawdown depth + time-to-recover around the 2009 and
  2020 shocks), is built at a separate **entity × shock × series** grain in
  `<entity>_recovery.rds` — see `transparency/variable_registry.md` (DV3 section) and
  `plan_docs/03_recovery_variable_plan.md`. Target series are CPI-U-deflated to real dollars.

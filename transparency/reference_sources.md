# Reference Data Sources

External reference series used by the pipeline. The data files live under `data/reference/`
(gitignored); this file is the committed provenance so they can be re-fetched and audited.

## `data/reference/price_index.csv` — CPI-U deflator (DV3)

- **Series:** Consumer Price Index for All Urban Consumers (CPI-U), U.S. city average, all items,
  **annual average**, index base 1982-84 = 100. BLS series id `CUUR0000SA0` (not seasonally
  adjusted).
- **Coverage:** 1995–2023 (matches the DV3 usable window; `plan_docs/03` §4/§8).
- **Columns:** `calendar_year`, `cpi_u` (annual-average index). The real-dollar factor
  `price_index = cpi_u / cpi_u[2023]` (base year 2023) is computed in
  `code/40_construct_resilience.R`; deflating a nominal series by `price_index` expresses it in
  2023 purchasing power.
- **Use:** `build_recovery_trajectory()` deflates DV3 target series before computing
  drawdown/recovery, so the ARPA-driven nominal fund-balance surge and ~2-3%/yr inflation are not
  mistaken for recovery.
- **Source / retrieval:** BLS CPI-U annual averages, retrieved 2026-06-17. Values cross-checked
  against BLS reference points (2009 = 214.537; 2020 = 258.811; 2022 = 292.655; 2023 = 304.702).
  Authoritative source: U.S. Bureau of Labor Statistics, https://www.bls.gov/cpi/ (historical
  CPI-U tables). Robustness alternative noted in `plan_docs/03` §8: BEA state & local government
  consumption price deflator.

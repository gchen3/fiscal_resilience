# Plan: Descriptive Statistics for the Resilience Outcome Variables

Descriptive statistics for the **resilience outcome** only — the Lee & Chen (2022)
expenditure-sensitivity measure. Built in `code/60_descriptives.R` (helpers in
`code/functions/descriptives.R`) and presented in the Quarto report
`analysis/resilience_descriptives.qmd`. DV construction spec:
`plan_docs/01_fiscal_resilience_dv_plan.md`.

## Scope (outcome-only)

The resilience **outcome** is expenditure-side stability. This report covers **only** that:

- **Expenditure gaps (building blocks):** `exp_gap_sr`, `exp_gap_lr`.
- **Sensitivity (the DV):** `sensitivity_sr`, `sensitivity_lr` = each gap ÷ its peer-group
  (`size_class × year`) mean. *Lower = more resilient.*

**Explicitly excluded** (described later, with the predictors — `45_construct_predictors`):
- `fb_ratio`, `available_fb_ratio` — the fund-balance **resource predictor**.
- `rev_*_gap_*` — the revenue-volatility **stressor predictor**.

Also excluded: the peer-relative `$` bases and any dimensionality analysis (PCA / clustering /
scatter — those did their job earlier and are not part of this descriptive set).

## Sample

- Unit = entity-year; **cities, 1995–2023** (FY2024 partial / FY2025 dropped).
- **NYC excluded by the OSC data** (and its five boroughs); no filter needed.
- Sensitivities average ≈ 1 **by construction** → lead the read with their spread (SD, quartiles,
  max), not the mean. Tables raw; **figures winsorized 1/99**.

## The six sections (artifacts under `outputs/descriptives/`)

1. **Definitions** (`tables/01_definitions.*`) — variable, label, role, direction, plain definition.
2. **Construction** (`tables/02_construction.*`) — per-variable formula + source rows (GF operating
   object base; short-run YoY gap; long-run log-trend gap, ≥8 yrs; size-class peer reference),
   plus the `$` scale note.
3. **Descriptive stats & distribution** (`tables/03_summary_stats.*`, `figures/03_distributions.*`)
   — mean/SD/median/quartiles/%missing; winsorized histograms.
4. **Time series** (`figures/04_time_series.*`) — annual means, 2009 & 2020 marked.
5. **Correlation** (`tables/05_correlation_{pooled,between,within}.*`, `figures/05_correlation_heatmap.*`)
   — panel-aware Spearman; gap↔sensitivity is mechanical, sr↔lr is the substantive pair.
6. **Distribution by size quintile** (`tables/06_by_size_quintile.*`, `figures/06_by_size_quintile.*`).

## Deliverables (both forms)

- **Engine:** `code/60_descriptives.R` clears `outputs/descriptives/`, then writes the `01–06`
  tables (`.csv` + `gt` `.html`) and figures (`.png` + `.pdf`). Reuses `describe_vars`,
  `correlation_sets`, `winsorize`, `gt_summary_table` from `code/functions/descriptives.R`.
- **Report:** `analysis/resilience_descriptives.qmd` embeds the saved artifacts with narrative,
  rendering a self-contained `resilience_descriptives.html`.

## Decisions (resolved)

- Outcome-only (exclude fund-balance predictor + revenue stressor); cities only; 1995–2023
  headline; winsorize 1/99 for figures; mean+SD lead with median/quartiles; Spearman correlations;
  variable set = Lee & Chen sensitivity (gaps + sensitivities).
- Reference group for the sensitivity = `size_class × year` (our adaptation of Lee & Chen's single
  national-average-per-year). Strict mirroring (one all-cities annual average) would be a
  construction change in `40`, not this report.

## Status / verification

Implemented and validated: `60_descriptives.R` runs against `data/processed_data/city_resilience.rds`
producing all `01–06` artifacts (no `fb_*`/`rev_*` leakage), and the report renders via
`quarto render analysis/resilience_descriptives.qmd`. Reproduce with
`source('code/40_construct_resilience.R'); source('code/60_descriptives.R')` then the quarto render.
(The large `*_data_all.rds` segfaults under sandbox `readRDS`, so the engine was validated against
the small `city_resilience.rds`.)

# Plan: Descriptive Statistics for the Fiscal Resilience Variables

Plan for summarizing the resilience dependent variables built in
`code/40_construct_resilience.R` (functions in `code/functions/resilience.R`; variables in
`transparency/variable_registry.md`). Implemented in **`code/60_descriptives.R`**, extending the
existing `summarize_entity_data()` / `make_summary_gt()` pattern. DV construction spec:
`plan_docs/01_fiscal_resilience_dv_plan.md`.

## 1. Objective

Describe the resilience DVs before modeling: their levels, spread, missingness, time profile
(esp. the 2009 / 2020 shocks and 2021 recovery), and cross-DV relationships — enough to (a)
sanity-check the construction, (b) motivate the empirical strategy, and (c) populate the paper's
descriptive table(s).

## 2. Inputs and variables

- **Input:** `data/processed_data/city_resilience.rds` — **cities only** for this pass (the
  validated panel). County/town/school descriptives are a later pass. One row per entity-year.
- **DV families to summarize:**

| Family | Variables | Type | Direction |
|---|---|---|---|
| **DV1 buffer** | `fb_ratio`, `available_fb_ratio` | ratio (level) | higher = more resilient |
| **DV2 expenditure** | `exp_gap_sr`, `exp_gap_lr` (absolute); `sensitivity_sr`, `sensitivity_lr` (relative) | volatility | lower = more resilient |
| **DV4 revenue** | `rev_{total,own,tax}_gap_sr/lr` (absolute); `rev_{total,own,tax}_sens_sr/lr` (relative) | volatility | lower = more resilient |
| **Bases / context** | `gf_total_exp`, `gf_operating_exp`, `rev_total`, `rev_own`, `rev_tax` ($); `size_class` (1–5) | level / categorical | — |

## 3. Unit of analysis and sample

- Unit = entity-year (`calendar_year`, `entity_name`, `municipal_code`).
- **Headline window = 1995–2023** (fully reported). FY2025 is dropped in construction;
  **FY2024 is partial** (≈50/61 cities) and is **excluded from all headline tables/means** —
  shown only as a separate flagged row (or appendix) if at all.
- Report sample size as both **N entity-years** and **N distinct entities** and **N years**,
  per group (the existing `summarize_entity_data()` already returns `n_entity` / `n_years`).
- **New York City is already excluded by the OSC data** (NYC and its five boroughs are reported
  separately and are absent here): the city panel has 61 cities — all NY cities **except NYC** —
  and the county panel 57 counties (62 − the 5 NYC-borough counties). No NYC filter is needed,
  matching the standard NYS local-government convention. (When schools are added, verify the NYC
  Department of Education — a giant outlier — is likewise absent before including it.)

## 4. Statistics to report

Per variable: **N**, **% missing**, **mean**, **SD**, **min**, **p10**, **p25**, **median**,
**p75**, **p90**, **max**. Rationale and caveats:

- **Headline leads with mean + SD** (+ min/max), per the chosen layout. Because the gaps/ratios
  are right-skewed with outliers (e.g. `fb_ratio` ≈ −0.53 to +2.2 on cities), **also report
  median + p25/p75 alongside** so the skew is visible and the mean isn't read in isolation.
- **`fb_ratio` deficit share:** also report the **% of entity-years with `fb_ratio < 0`**
  (negative/deficit fund balance) — a substantively meaningful resilience indicator.
- **Sensitivity caveat:** the relative `*_sens_*` variables average ≈ 1 **by construction**
  (normalized within `size_class × year`), so their *mean* is uninformative. Summarize their
  **spread** (SD, IQR, share > 1 = below-peer resilience) and lead with the **absolute** gaps
  for level comparisons.
- Report `$` bases (`gf_*`, `rev_*`) mainly to document scale; consider log or per-capita for
  display (per-capita deferred until Census population is merged).

## 5. Breakdowns

1. **Pooled** (all city entity-years) — headline table.
2. **By year** — mean/median of each DV by `calendar_year`. **This is the key view** (the
   findings live in the time profile: revenue volatility spikes in 2020–21, operating spending
   is sticky, fund balance surges 2021–23). Drives the time-series figures (§7).
3. **By size class** (1–5) — check whether buffers/volatility vary by size; confirms the
   reference-group design.
4. **Pre/post-shock (optional)** — simple period means around 2009 and 2020 (full event-time
   analysis belongs to DV3 / the modeling stage, not here).
5. **By entity type — deferred.** The city/county/town comparison activates in the multi-entity
   pass (scope §11); not applicable to this cities-only run.

## 6. Tables (gt)

- **T1 — Headline summary:** all DVs, pooled, full stat set (§4). One row per variable.
- **T2 — By year (decade blocks):** key DVs summarized by decade (and the full annual series in
  F1). (A by-entity-type table is deferred to the multi-entity pass.)
- **T3 — Fund-balance detail:** `fb_ratio` / `available_fb_ratio` distribution + deficit share,
  by decade.
- **T4 — Volatility comparison:** absolute gaps for operating vs revenue bases side by side
  (shows revenue > expenditure volatility).
- *Correlations, dimensionality, and other inter-variable relationships are treated separately
  in §8 (tables T6–T7).*

Build with `gt`; save to `outputs/descriptives/` (e.g. `.html` + `.png`/`.tex` for the paper).

## 7. Figures

- **F1 — Time series (primary):** mean (and median) of each DV family by `calendar_year`, with
  **2009 and 2020 marked**. Separate panels for buffer (`fb_ratio`), expenditure volatility, and
  revenue volatility — visualizes the sticky-spending / revenue-shock / recovery-surge story.
- **F2 — Distributions:** histograms/densities of `fb_ratio` and the absolute gaps (show skew,
  outliers, the deficit mass below 0). Display **winsorized at 1%/99%** (§9).
- **F3 — By size class:** boxplots of key DVs across size classes.
- *Relationship figures (correlation heatmap, scatterplot matrix, dendrogram) are in §8 (F5–F7).*

Save to `outputs/descriptives/figures/` as `.png` (+ `.pdf` for the paper).

## 8. Relationships among the resilience variables

The DVs are conceptually distinct facets — **buffer** (DV1), **expenditure volatility** (DV2),
and **revenue volatility** (DV4). The question here is whether they capture **one** underlying
resilience construct or **several** distinct dimensions — which decides whether a single
composite "resilience index" is defensible or the facets are modeled as separate outcomes. A
pooled correlation matrix is the start, but is not enough for panel data; the methods below go
further.

**Guardrails (apply throughout):**
- **Drop sensitivities from cross-family analysis.** Each `*_sens_*` is its `*_gap_*` divided by
  a `size_class × year` mean, so it is *mechanically* near-collinear with its own gap. Use the
  **absolute gaps and the ratios**; report the gap↔sensitivity link separately as an artifact.
- **Skew → rank-based.** Lead with **Spearman**; use rank / normal-score transforms for any
  multivariate method.
- **Sign-align before combining.** Buffers are "higher = resilient", gaps "lower = resilient" —
  flip signs before any index/PCA so loadings are interpretable.

**Methods**
1. **Correlation matrix (T6) + heatmap (F5).** Spearman (default) and Pearson (appendix) among
   the ratios and absolute gaps. Read in blocks: within-family (expected high) vs across-family
   (the substantive question — does a thicker buffer go with lower revenue volatility?).
2. **Within vs between decomposition.** A pooled correlation conflates cross-city differences
   with over-time movement. Report both: **between** = correlate **entity means** (do
   structurally high-buffer cities run lower volatility?); **within** = correlate
   **entity-demeaned** series (when a city's own buffer rises, does its volatility fall?). These
   can differ in sign and are far more informative than one pooled coefficient.
3. **Dimensionality — PCA / exploratory factor analysis (T7).** On the sign-aligned,
   rank/normal-scored DVs: scree + loadings to see whether the ~10 DVs collapse to 2–3 factors
   (plausible prior: a *buffer* factor and a *volatility* factor, with revenue vs expenditure
   possibly splitting). Directly tests "one construct vs several" and gauges index feasibility.
4. **Variable clustering (F7).** Hierarchical clustering on `1 − |ρ|` distance → dendrogram that
   groups the DVs empirically; a visual cross-check on the PCA families.
5. **Scatterplot matrix (F6).** Pairs plot with LOESS for the key DVs (winsorized display) to
   catch nonlinearities the correlations miss.
6. **Lead–lag (dynamic) link — brief.** Cross-correlate revenue volatility at *t* with the
   **change** in `fb_ratio` at *t* and *t+1*: does a revenue shock precede a buffer drawdown?
   A teaser for DV3 (recovery) and the dynamics the models will formalize — a small table, not
   an event study.

**Outputs:** T6 (correlation: Spearman + Pearson, pooled plus within/between), T7 (PCA loadings +
variance explained); F5 correlation heatmap, F6 scatterplot matrix, F7 variable dendrogram.
**Whether to build a composite index** (first PC or sign-aligned standardized average) is a
decision (§11) — justified only if PCA/clustering show the facets cohere; else keep DVs separate.

## 9. Data-quality and methodological notes to surface

- **Missingness:** report and explain `NA` shares (short panels for `*_gap_lr` < `MIN_YEARS`;
  suppressed `*_sens_*` cells with < `MIN_GROUP` units; missing equity rows).
- **FY2012→2013 break:** note the GASB-54 / schema splice in any fund-balance time series; the
  `available_fb` adaptive rule should keep it continuous, but flag the level step.
- **FY2024 partial / FY2025 dropped** — state the effective window on every time figure/table.
- **Outliers (resolved):** **winsorize at 1%/99% for figures only**. Tables report raw stats
  (including true min/max) and the stored DVs are never winsorized.

## 10. Implementation

- **Prerequisite:** `data/processed_data/city_resilience.rds` must exist first — run
  `code/40_construct_resilience.R` in an R session (after `10_import.R`) to generate it. This
  stage reads that file; it cannot run until the DVs are built.
- Extend **`code/60_descriptives.R`**: generalize `summarize_entity_data()` to take an explicit
  variable list and grouping keys; add helpers in `code/functions/` (e.g. a `describe_vars()`
  and the `gt` formatters) so stages stay thin. PCA/clustering (§8) use base `prcomp` /
  `hclust` (no new heavy deps).
- Reads `data/processed_data/city_resilience.rds`; writes tables/figures to `outputs/descriptives/`.
- Descriptives are not registry items, but if any derived display variable is created (e.g. a
  winsorized copy), note it in `transparency/variable_registry.md`.

## 11. Decisions

**Resolved:**
- **Entity scope:** cities only (this pass).
- **Headline window:** 1995–2023; FY2024 excluded from headline (partial), FY2025 dropped.
- **Outlier handling:** winsorize 1%/99% for figures only; tables/stored DVs stay raw.
- **Central tendency:** lead with mean + SD; report median + p25/p75 alongside (skew).

**Still open:**
1. **Period grouping** for the by-time table/figure: annual (default) plus decade bins?
2. **`$` bases display:** nominal (default) vs real; per-capita deferred to the Census-population merge.
3. **Correlation method (§8):** Spearman (default, robust to the skew) vs Pearson (report both).
4. **Composite resilience index (§8):** build one (first PC / sign-aligned standardized average)
   only if PCA/clustering show the facets cohere — otherwise keep the DVs separate. Default:
   decide *after* seeing T7/F7, do not pre-commit.

## 12. Next step

These descriptives set up the resilience story (buffer levels + deficits, sticky operating
spending, revenue/recovery volatility) that the models (`70_model_main.R`) will explain, and
they confirm the DV construction before DV3 (recovery) is added.

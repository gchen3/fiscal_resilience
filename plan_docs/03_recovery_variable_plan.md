# Plan: DV3 — Shock Recovery Trajectory

Constructs the **bounce-back** resilience outcome (README's verb) that DV1/DV2/DV4 do not
capture: how deep a shock pushed a city below its pre-shock baseline and how long it took to
return. Specified in `plan_docs/01_fiscal_resilience_dv_plan.md` §8 (the `DV3` construction ID);
this document is the build-level plan. Helpers go in `code/functions/resilience.R` (the stub at
its end), driven from `code/40_construct_resilience.R`.

## 1. Why DV3 is structurally different

DV1/DV2/DV4 are **entity-year**. Recovery is an **event study**: the grain is **entity × shock**,
with its own baseline, window, and right-censoring logic. So DV3 is **not** another entity-year
column — it is a separate table (`<entity>_recovery.rds`) that joins to the modeling panel as
**event-time records** (matches the COVID/disaster framing in `plan_docs/01` §14).

DV2 (absolute expenditure gap) measures *volatility*, direction-neutral; DV3 is the **signed /
downside** home for "did services get cut, how deep, did they rebuild" — anchored to a shock and a
real baseline, *not* a raw signed year-over-year change (nominal growth would swamp it; a prudent
cut is not unambiguously a failure).

## 2. Where it slots in (no raw pass)

DV3 consumes the **already-constructed** resilience panel, not the raw `*_data_all.rds`. The bases
it needs — `available_fb`, `rev_own` / `rev_tax`, `gf_operating_exp` — are already columns in
`<entity>_resilience.rds`. This keeps DV3 cheap and avoids re-touching the large raw files (which
segfault under sandbox `readRDS`).

```
40_construct_resilience.R:
  build_resilience(raw)                         -> <entity>_resilience.rds   (entity-year, exists)
  build_recovery_trajectory(resil, series, ...) -> <entity>_recovery.rds     (entity-shock, NEW)
```

## 3. Target series `Y`

Recovery is only meaningful where there is something to recover *from*. The descriptive findings
(`plan_docs/02`) show **operating spending is sticky** — no drawdown at 2009/2020 — so a recovery
metric on `gf_operating_exp` is near-zero depth / instant recovery and uninformative on its own.

- **Lead series — `available_fb_ratio`** (reserves ÷ GF expenditure: drawn down then rebuilt — the
  clearest bounce-back). **Resolved 2026-06-17:** use the bounded *ratio* with a **level
  (ratio-point) drawdown and no deflation**, not raw `available_fb` with a proportional drawdown —
  raw fund balance is near-zero/negative for some cities and the proportional form explodes
  (validation below). A ratio is already real, so it is not deflated.
- **Channel series — `rev_own`** (own-source revenue: the tax-base shock channel; `rev_tax` as a
  sharper variant). Proportional drawdown on CPI-U-deflated real dollars.
- **Contrast series — `gf_operating_exp`** (kept only to show services were *held steady* — a low
  drawdown here against a deep revenue drawdown is itself the resilience story / pass-through).
  Proportional drawdown on deflated real dollars.

Build the function **series-agnostic** (one `series_col` argument) and run it on all three.

## 4. Decisions (resolved 2026-06-17)

All five settled; defaults below are what the build uses.

1. **Baseline `B` — pre-shock mean of `t0-3 … t0-1`** (primary). Robust, no look-ahead, short
   pre-period OK. **Robustness variant = log-trend prediction at `t0`** (reuses the DV2 log-trend
   machinery; carries the in-sample look-ahead caveat from `plan_docs/01` §7).
2. **Deflation — CPI-U (annual, national).** Deflate `Y` to real dollars **before** computing
   depth/recovery — otherwise ~2-3%/yr inflation, and the ARPA-driven 2021->2023 fund-balance
   surge (`plan_docs/01` §4), masquerade as recovery. **No price index exists in the repo
   (verified)**, so one is created; CPI-U chosen over the BEA state/local deflator for sourcing
   simplicity (the choice does not change the resilience ranking; BEA noted as a robustness
   option). See §8. Per-capita is a later refinement (Census population).
3. **Shocks — 2009 (GFC) and 2020 (COVID)**, passed as a `shocks` argument (not hard-coded to
   two) so entity-specific FEMA disaster years can extend it later.
4. **Window `W=6`, horizon `h=4`.** GFC (`t0=2009`): post-window through 2015 is clean. COVID
   (`t0=2020`): only 2021-2023 in the usable panel (FY2024 partial, FY2025 dropped — §4), so its
   recovery-time is **heavily right-censored** — lead COVID with depth + recovery-ratio (both
   observable), report recovery-time as censored.
5. **Target series — all three, `available_fb` as headline** (§3): `available_fb` (lead),
   `rev_own` (channel; `rev_tax` sharper variant), `gf_operating_exp` (contrast). Function is
   series-agnostic (`series_col` arg).

## 5. Metrics (per unit × shock, shock year `t0`)

With real `Y` and baseline `B`:

- **Drawdown depth** = `max(0, (B - min Y_t)/B)` over `t ∈ [t0, t0+W]` — deepest proportional
  shortfall (0 if it never dipped). *Observable even when recovery is censored.*
- **Trough year** = `argmin Y_t` in the window (descriptive).
- **Recovery time** = first `k ≥ 0` with `Y_{t0+k} ≥ B`; **`NA` with `censored = TRUE`** if no such
  year before the panel/window ends.
- **Recovery ratio** = `Y_{t0+h} / B` at the fixed horizon — a level even when recovery-time is
  censored.

*Resilient = shallow drawdown + short recovery time.*

## 6. Function (in `code/functions/resilience.R`, replacing the §8 stub)

```r
# raw inputs: an entity's *_resilience.rds (entity-year). deflator: data.frame(calendar_year, price_index).
build_recovery_trajectory <- function(panel, series_col,
                                      shocks = c(2009, 2020),
                                      pre = 3, window = 6, horizon = 4,
                                      deflator = NULL) {
  d <- panel %>% dplyr::select(entity_name, municipal_code, calendar_year, y = {{ series_col }})
  if (!is.null(deflator))
    d <- d %>% dplyr::left_join(deflator, by = "calendar_year") %>%
               dplyr::mutate(y = y / price_index)

  purrr::map_dfr(shocks, function(t0) {
    d %>% dplyr::group_by(entity_name, municipal_code) %>% dplyr::group_modify(~ {
      x <- .x; yr <- x$calendar_year
      B    <- mean(x$y[yr %in% (t0 - pre):(t0 - 1)], na.rm = TRUE)         # pre-shock baseline
      post <- x[yr >= t0 & yr <= t0 + window & is.finite(x$y), ]
      if (!is.finite(B) || B <= 0 || nrow(post) == 0)
        return(tibble::tibble(shock = t0, baseline = NA_real_, drawdown = NA_real_,
                              trough_year = NA_integer_, recovery_years = NA_integer_,
                              recovered = NA, censored = NA, recovery_ratio = NA_real_))
      depth  <- max(0, (B - min(post$y)) / B)
      rec_yr <- post$calendar_year[post$y >= B]
      k      <- if (length(rec_yr)) min(rec_yr) - t0 else NA_integer_
      yh     <- x$y[yr == t0 + horizon]
      tibble::tibble(
        shock = t0, baseline = B, drawdown = depth,
        trough_year   = post$calendar_year[which.min(post$y)],
        recovery_years = k,
        recovered = !is.na(k),
        censored  = is.na(k) && max(post$calendar_year) < max(yr),
        recovery_ratio = if (length(yh)) yh / B else NA_real_)
    }) %>% dplyr::ungroup()
  })
}
```

Pure, no I/O / side effects — same contract as the other `functions/resilience.R` helpers; uses
explicit `dplyr::` / `tibble::` / `purrr::` qualifiers (linter convention).

## 7. Driver and output

In `code/40_construct_resilience.R`, after `build_resilience()` writes `<entity>_resilience.rds`,
run DV3 over the three series and bind:

```r
recov <- dplyr::bind_rows(
  build_recovery_trajectory(city_resil, available_fb,      deflator = cpi) %>% dplyr::mutate(series = "available_fb"),
  build_recovery_trajectory(city_resil, rev_own,           deflator = cpi) %>% dplyr::mutate(series = "rev_own"),
  build_recovery_trajectory(city_resil, gf_operating_exp,  deflator = cpi) %>% dplyr::mutate(series = "gf_operating_exp")
)
readr::write_rds(recov, here::here("data", "processed_data", "city_recovery.rds"))
```

Output grain = `entity × shock × series`; column names follow `plan_docs/01` §10
(`recovery_drawdown_<series>`, `recovery_years_<series>`, plus `recovered` / `censored` /
`recovery_ratio_<series>`). It joins to the modeling panel as **event-time** records (entity ×
shock), not back onto entity-year.

## 8. Deflator — resolved: CPI-U

**Verified: no price index exists anywhere in the repo** (`data/`, `code/` — searched
cpi/price/deflator/index). Decision: **CPI-U, U.S. city average, all items, annual average
(BLS series `CUUR0000SA0`, base 1982-84 = 100)**. Chosen over the BEA state/local consumption
price deflator purely for sourcing simplicity; BEA is the robustness alternative. The choice does
not move the resilience ranking — it only rescales `Y` by a common annual factor.

**Build step (first thing, before the function):** create
`data/reference/price_index.csv` with columns `calendar_year, cpi_u` for 1995-2023 (annual
averages from BLS), then add a real-dollar factor (`price_index = cpi_u / cpi_u[base_year]`, base
year stated — e.g. 2023). Register the source (BLS series id + retrieval date) in
`transparency/` (a `reference_sources` note and a row in the variable registry). `data/` is
gitignored, so the CSV is local; the registry/source note is the committed provenance.

Until the CSV is populated with real BLS values, DV3 runs on **nominal** `Y` for plumbing only —
no nominal recovery numbers are reported.

## 9. Validation

- **GFC fund-balance recovery** should show a visible drawdown for at least some cities in
  2009-2011 and recovery within the window (not all instant) — if `available_fb` depth is ~0
  everywhere, the baseline/deflation is wrong.
- **COVID** rows: expect high `censored = TRUE` share on `recovery_years`; `drawdown` and
  `recovery_ratio` still populated. ARPA surge should make many `available_fb` recovery_ratios > 1
  (over-recovery) — sanity-check against the $651M->$1.25B city surge in `plan_docs/01` §4.
- **Operating-expenditure** drawdowns should be **shallow** vs revenue/fund-balance (confirms the
  sticky-spending finding and the pass-through framing).
- Report share of `NA` DV3 (too-short pre-period, missing base, zero baseline) and the
  recovered/censored split per shock.

**Validation outcome (2026-06-17, cities, against `city_resilience.rds`):** implemented and run.
`rev_own` / `gf_operating_exp` behave as expected — operating-expenditure drawdowns are **shallow**
(GFC mean ≈ 0.03, COVID ≈ 0.08) vs revenue (≈ 0.05–0.06), confirming sticky spending; COVID
recovery is mostly **censored** (e.g. 32/61 for operating exp). The earlier raw-`available_fb` proportional
drawdown **failed**: raw fund balance ranges −$29M…+$184M and some pre-shock baselines are only a
few thousand $, so `(B - min Y)/B` exploded (Long Beach COVID ≈ 800×). **Resolved:** the reserves
target is now `available_fb_ratio` with a **level (ratio-point) drawdown, undeflated** — depths
are now bounded (max ≈ 0.70 ratio points, 0% `NA`; deeper than COVID at the GFC, mean ≈ 0.13 vs
0.08). `rev_own` and `gf_operating_exp` keep the proportional form (unchanged). Descriptive output:
`code/65_recovery_descriptives.R` → `analysis/recovery_descriptives.qmd`. Substantive reads: COVID
recovery-time is heavily censored (operating exp ≈ 52%); depth↔speed is positively correlated for
every series (Spearman ≈ 0.40–0.63 — deeper drawdowns rebuild more slowly).

## 10. Scope / sequencing

Prototype on **cities**, then generalize to county/town (school deferred with the rest of DV
construction — `plan_docs/01` §12 fund-identifier caveat). DV3 is the **last** resilience-outcome
piece; DV1/DV2/DV4 are built. Build order: (1) **deflator resolved (§8: CPI-U)** — populate
`data/reference/price_index.csv` from BLS, (2) implement `build_recovery_trajectory()` + driver,
(3) validate per §9, (4) register variables, (5) add a DV3 section to the descriptive report
(entity-shock distributions, drawdown/recovery by size class).

## 11. References

- `plan_docs/01_fiscal_resilience_dv_plan.md` §8 (DV3 spec), §4 (usable window / ARPA surge), §14
  (event-time downstream link).
- Lee & Chen (2022) — resilience-as-recovery framing (PDF `resources/5.LeeChen-2022-PMR.pdf`).

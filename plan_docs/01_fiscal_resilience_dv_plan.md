# Plan: Constructing the Operating-Expenditure Resilience (Stability) Variable

Following the **sensitivity measurement** of Lee & Chen (2022), *Understanding financial
resilience from a resource-based view: Evidence from US state governments*, Public Management
Review 24(12): 1980–2003 (PDF: `resources/5.LeeChen-2022-PMR.pdf`, local/gitignored) — extended
to use the **object-class and fund detail** in the raw OSC data.

**Scope of this document.** This plan covers the **resilience OUTCOME only**: expenditure-side
**stability** — how well a government maintains stable public services (operating spending) through
shocks. It is the variable described in `analysis/resilience_descriptives.qmd`. The other resilience
constructs live in their own plans and are only cross-referenced here:

- **Shock recovery** (bounce-back: drawdown depth + time-to-recover) → `plan_docs/03_recovery_variable_plan.md`.
- **Predictors — fund-balance buffer (resource) and revenue volatility (stressor)** →
  `plan_docs/05_predictor_variables_plan.md`.
- **External-shock predictors (FEMA, recession, aid/revenue shock flags)** →
  `plan_docs/04_external_shock_predictors_plan.md`.

## 1. Objective and analytic framing

Build a fiscal **resilience** outcome for NYS local governments from the **raw** OSC files, in the
resource-based-view / dynamic-capabilities framing of Lee & Chen (2022): **resources and capacity
let a government keep public services (expenditures) stable when revenue shocks hit.**

The **resilience OUTCOME (dependent variable)** is **expenditure-side stability** — the **absolute**
General Fund operating expenditure gap and its peer-relative **sensitivity** (§5). *Lower = more
resilient* (better at maintaining services). This is the **headline** measure (Lee & Chen "maintain
status quo"; direction-neutral, so a prudent cut and an overshoot both count as instability).

**Core hypothesis / model (context).** Expenditure stability is explained by the interaction
**revenue shock × resources (buffer, capacity)** — low pass-through (stable spending despite revenue
swings) = resilient. The revenue-volatility stressor and the fund-balance-buffer moderator that sit
on the right-hand side are built and documented in `plan_docs/05`; this plan builds the left-hand
side (the outcome).

**Construction decisions locked in:** **fund scope = General Fund (account-code letter `A`) only**;
operating base defined by **object class**; long-run trend **log-linear**; reference group = **entity
type × size class × year**; prototype on **cities** then generalize. Built for cities (validated),
counties, and towns; schools pending General-Fund-code verification (§9).

## 2. Key finding: the raw data is far richer than the merged tables

`code/20_clean.R` aggregates to `level_1/2_category` and **filters to revenues/expenditures
only**, discarding the dimensions this outcome needs. Verified in
`data/OSC/all_classes_years/*.csv` (retained in `data/OSC/*_data_all.rds`):

| Raw column | What it provides | Status in merged tables |
|---|---|---|
| `object_of_expenditure` | Object class: `personal services`, `contractual`, `employee benefits`, `equipment and capital outlay`, `debt principal`, `debt interest`, `interfund transfer` | **dropped** |
| `account_code` (1st letter) | **Fund**: `A`=General, `H`=Capital Projects, `V`=Debt Service, `F`=Water, `G`=Sewer, `T`=Trust & Agency, … | **dropped** (collapsed across funds) |
| `financial_statement` (≤2012) / `account_code_section` (≥2013) | Statement type incl. balance-sheet / fund-balance rows (era-specific; used by the buffer predictor in `plan_docs/05`) | **dropped** (only rev/exp kept) |

Implications for the expenditure outcome:
- **Operating vs capital is separable at source** via `object_of_expenditure`.
- The current `expenditures` total **blends all funds**; Water (`W`) alone is $5–13B in some
  city-years and swamps the general-government signal. → restrict to **General Fund (`A`)**.

→ **The expenditure-stability outcome must be rebuilt from the raw all-years data, not the merged
tables.** (The same raw pass also yields the buffer/revenue predictors in `plan_docs/05`.)

## 3. The Lee & Chen (2022) measure (basis for the expenditure gap)

Sensitivity proxies resilience via **expenditure gaps**; lower = more resilient. (The same gap /
sensitivity machinery is reused for the revenue-volatility predictor in `plan_docs/05` §2.)

- **Short-run gap** (year-over-year): `ShortRun_ExpGap_it = | E_it - E_i,t-1 | / E_i,t-1`
- **Long-run gap** (deviation from own trend). Paper uses level-linear `E = α_i + β_i·T`; **we use
  log-linear** (NYS local expenditures grew ~5× nonlinearly over 1995–2025):
  `log(E_it) = α_i + β_i·T_t`, `Ehat_it = exp(fitted)`, `LongRun_ExpGap_it = | E_it - Ehat_it | / Ehat_it`
- **Sensitivity (relative DV)** = `ExpGap_it / mean_g(ExpGap_gt)`; `g` = reference group for year
  `t`. Paper: 50-state average. **Here: entity type × size class × year.**

Absolute values in both gaps so over- and under-spending both count as volatility.

## 4. Data inputs

- Source: `data/OSC/<entity>_data_all.rds` (raw, all years, **retains** object/fund/statement),
  starting with **cities**. (Re-extract from `all_classes_years/*.csv` if the `.rds` is unwieldy.)
- Keys: `calendar_year`, `entity_name`, `municipal_code`.
- Derive `fund = toupper(substr(account_code, 1, 1))`; unify the segment/statement field across
  the two schema eras — **verified clean schema break at FY2012→FY2013**: `financial_statement` /
  `financial_statement_segment` for ≤2012, `account_code_section` (`revenue | expenditure | gl |
  fbnp`) for ≥2013. Revenue/expenditure rows exist in both eras (the era-specific fund-balance
  source for the buffer predictor is in `plan_docs/05` §1).

**Diagnostics verified (cities):** 61–62 entities; near-balanced (median 30/31 yrs, none short);
stable `municipal_code`; `expenditures` = sum of `exp_L1_*`; ~5× nonlinear nominal growth → log
trend.

**Recent-year completeness (verified by audit, fund A):** fully reported ~1995–2023 (57–62
entities/yr), then thinning: 2024 = 50/61, **2025 = 12/61 → exclude**; treat **2024 as partial**.
Usable window ≈ 1995–2023.

## 5. Expenditure-gap sensitivity (General Fund operating)

**Operating base:** `E_op_it = Σ amount` where `fund == "A"`, segment = expenditure, and
`object_of_expenditure ∈ {personal services, contractual, employee benefits}` (excludes capital
outlay, debt principal/interest, interfund transfers). Verified populated and smooth every year.

**Steps** (per unit series `E_op`; optionally repeat for `exp_L1_*` within the General Fund):
0. **Validate years** (§4); drop FY2025, flag FY2024; set window.
1. Order by unit × `calendar_year`; require `E_op > 0`, non-missing; record coverage.
2. **Absolute short-run gap** `exp_gap_sr` on consecutive years only.
3. **Absolute long-run gap** `exp_gap_lr` via per-unit `log(E_op) ~ year` (≥ `MIN_YEARS`, default
   8; else `NA`). The `exp_gap_*` are **absolute** (retain common shocks).
4. **Size class:** within-type quintiles of each unit's time-averaged **real** GF operating
   expenditure; static per unit. (Shared with the predictor variables in `plan_docs/05`.)
5. **Reference-group means:** mean gap per `size_class × year`; suppress cells `< MIN_GROUP`
   (default 5). Robustness: median/trimmed mean.
6. **Relative sensitivity:** `sensitivity_sr = exp_gap_sr / group_mean_sr`, likewise `_lr`.

> **Why both absolute and relative:** relative sensitivity divides out the year's common shock
> (everyone hit in 2020 → nobody looks unusually sensitive) → measures *idiosyncratic* volatility
> (peer/resource comparison). The absolute gap keeps the common-shock signal the COVID/disaster
> framing needs.

> **Look-ahead caveat:** the long-run `Ehat` is fit on the whole series; note in-sample look-ahead
> if `*_lr` is later used as an outcome against lagged predictors.

## 6. Adaptation summary

| Paper (Lee & Chen 2022) | This project (expenditure outcome) |
|---|---|
| 50 US states, FY2002–2017 | NYS cities/counties/towns/school districts, FY1995–2025 |
| Unit = state | Unit = entity (`entity_name` + `municipal_code`) |
| All-fund object-class total | **General Fund (`A`)**, **current operating** via object class |
| Level-linear trend | **Log-linear** trend |
| Reference = national avg/year | **Entity type × size class × year** |

## 7. Output variables and naming

General Fund, per unit-year. Register every variable in `transparency/variable_registry.md`.

| Variable | Meaning |
|---|---|
| `gf_operating_exp` | GF current-operating expenditure base ($) |
| `gf_total_exp` | Total GF expenditures (denominator used by the buffer predictor, `plan_docs/05`) |
| `exp_gap_sr` / `exp_gap_lr` | **Absolute** — GF operating volatility (retains shocks) |
| `sensitivity_sr` / `sensitivity_lr` | **Relative** — peer-normalized (lower = resilient) |
| `size_class` | Within-type size quintile (1–5), static (shared with predictors) |

## 8. Open decisions

1. **End years (resolved by audit):** drop **FY2025**; **FY2024** partial — drop or flag-and-keep.
2. **Size proxy & bins:** real GF operating expenditures, quintiles (tertiles if sparse).
3. **`MIN_YEARS`** (default 8), **`MIN_GROUP`** (default 5).
4. **Group statistic:** mean (paper) vs median/trimmed (robust).
5. **Deflation/per-capita:** gap nominal (paper); real for size class; revisit with Census pop.
6. **Functional-category expenditure gap within General Fund:** include now or defer.

## 9. Implementation

The pipeline stages are scaffolded (banded by tens) and listed in `code/master.R`; implementation
means filling stubs, not creating files. The expenditure outcome (with the buffer/revenue
predictors of `plan_docs/05`) is built in **`code/40_construct_resilience.R`**; the joined modeling
panel in `50_assemble_panel.R`; models in `70_model_main.R` / `75_model_robustness.R`.

- **`code/40_construct_resilience.R`** runs after `30_merge.R`, reads `data/OSC/*_data_all.rds`
  (raw — retains object/fund/statement), writes `data/processed_data/<entity>_resilience.rds`.
  Helpers live in `code/functions/resilience.R`.
- Generalized function `build_resilience(raw_all, fund = "A", operating_objects = c(...),
  drop_years = 2025, trend = "log", min_years = 8, min_group = 5)`; prototype on cities then
  county/town/school.
- **Generalization caveat — "General Fund = `A`" does not transfer cleanly.** It's a
  city/county/town convention; **towns** also have `B` (general, part-town/outside-village) and
  `DA/DB` highway, and **school districts** use a different chart of accounts. **Verify the General
  Fund identifier per entity type** before generalizing, or the outcome silently breaks for schools.
- Optionally extend `10_import.R`/`20_clean.R` to retain object/fund/balance-sheet so the merged
  tables carry them too; then uncomment the relevant stages in `code/master.R`.

## 10. Validation

- `sensitivity_*` ≈ 1 per `size_class × year` cell; **absolute** `exp_gap_*` should spike in
  2009/2020 (confirms the absolute/relative distinction).
- Object-class operating base reconciles: operating + capital + debt + transfers ≈ GF total exp.
- Report share/cause of `NA` (short panels, zero base).
- (Buffer and revenue-predictor validation — incl. the FSMS cross-check and the GASB-54
  breakpoints — is in `plan_docs/05` §4.)

## 11. Downstream link

The expenditure-stability outcome is the dependent variable for the main models. The absolute gaps
(retaining common shocks) serve the COVID/disaster event-time framing; the relative sensitivities
serve peer/resource comparisons as in Lee & Chen. The revenue-volatility stressor and
fund-balance-buffer moderator (`plan_docs/05`), the recovery outcome (`plan_docs/03`), and the
external-shock indicators (`plan_docs/04`) enter as their own variables/models.

## 12. References

- Lee, S. & Chen, G. (2022). Understanding financial resilience from a resource-based view:
  Evidence from US state governments. *Public Management Review*, 24(12), 1980–2003.
- Villani (2018); Wang & Hou (2009); Marlowe (2005); Park, Kim & Chen (2020); Hou (2003); Feder &
  Mustra (2018); Martin (2011). NYS OSC Fiscal Stress Monitoring System.

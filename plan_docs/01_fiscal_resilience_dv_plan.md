# Plan: Constructing the Fiscal Resilience Dependent Variable(s)

Following the **sensitivity measurement** of Lee & Chen (2022), *Understanding financial
resilience from a resource-based view: Evidence from US state governments*, Public Management
Review 24(12): 1980–2003 (PDF: `resources/5.LeeChen-2022-PMR.pdf`, local/gitignored) — extended
to use the **object-class, fund, and balance-sheet detail** in the raw OSC data.

## 1. Objective, analytic framing, and variable roles

Build fiscal **resilience** measures for NYS local governments from the **raw** OSC files, in the
resource-based-view / dynamic-capabilities framing of Lee & Chen (2022): **resources and capacity
let a government keep public services (expenditures) stable when revenue shocks hit.**

**Analytic roles (revised 2026-06-17 — see the descriptive findings in
`plan_docs/02_descriptive_statistics_plan.md` and the PCA showing buffer ⟂ volatility).** All four
quantities below are still *constructed* in `40_construct_resilience.R` from the same raw General
Fund pass; what changed is their **role** in the analysis:

- **Resilience OUTCOME (dependent variable):**
  - **Expenditure-side stability** — the **absolute** General Fund operating expenditure gap /
    sensitivity (§7, "DV2"). *Lower = more resilient* (better at maintaining services). This is the
    **headline DV** (Lee & Chen "maintain status quo"; direction-neutral, so a prudent cut and an
    overshoot both count as instability).
  - **Shock recovery** — drawdown depth + time-to-recovery around shocks (§8, "DV3"). This is the
    **signed / downside** home for "did services get cut, how deep, did they rebuild" — done
    rigorously with a shock anchor and a real/detrended baseline, *not* a raw signed year-over-year
    change (nominal growth would swamp it; a cut is not unambiguously a failure).
- **Stressor / exposure (predictor):** **revenue volatility** — the GF revenue gaps (§9, "DV4",
  esp. own-source/tax). The revenue→expenditure link is partly mechanical (budget constraint), so
  the resilience signal is the **pass-through**: a resilient city absorbs a revenue shock *without*
  cutting spending.
- **Resource / capacity (predictor):** **fund-balance level** — `fb_ratio` / `available_fb_ratio`
  (§6, "DV1"). A *stock of slack*, used as a **resource/moderator**, not an outcome (as in Lee &
  Chen). Joins the structural predictors built in `45_construct_predictors.R`.

**Core hypothesis / model:** expenditure stability is explained by the interaction
**revenue shock × resources (buffer, capacity)** — low pass-through (stable spending despite
revenue swings) = resilient. The fund-balance buffer is a *moderator* of that pass-through.

Construction decisions locked in: **fund scope = General Fund (account-code letter `A`) only**;
operating base defined by **object class**; long-run trend **log-linear**; prototype on **cities**
then generalize. The expenditure-stability DV and the fund-balance/revenue predictors are built;
recovery (§8) is the remaining piece. The "DV1–DV4" labels below are retained as *construction*
IDs; their analytic roles are as assigned here.

## 2. Key finding: the raw data is far richer than the merged tables

`code/20_clean.R` aggregates to `level_1/2_category` and **filters to revenues/expenditures
only**, discarding three dimensions this plan needs. Verified in
`data/OSC/all_classes_years/*.csv` (retained in `data/OSC/*_data_all.rds`):

| Raw column | What it provides | Status in merged tables |
|---|---|---|
| `object_of_expenditure` | Object class: `personal services`, `contractual`, `employee benefits`, `equipment and capital outlay`, `debt principal`, `debt interest`, `interfund transfer` | **dropped** |
| `account_code` (1st letter) | **Fund**: `A`=General, `H`=Capital Projects, `V`=Debt Service, `F`=Water, `G`=Sewer, `T`=Trust & Agency, … | **dropped** (collapsed across funds) |
| `financial_statement` (≤2012) / `account_code_section` (≥2013) | Statement type incl. balance-sheet / fund-balance rows (era-specific labels, §6) | **dropped** (only rev/exp kept) |

Implications:
- **Operating vs capital is separable at source** via `object_of_expenditure`.
- The current `expenditures` total **blends all funds**; Water (`W`) alone is $5–13B in some
  city-years and swamps the general-government signal. → restrict to **General Fund (`A`)**.
- **Fund balance exists but was deleted — available for the full 1995–2025 span** (verified, §6),
  so DV1 covers COVID, with a schema change at FY2012→2013 to bridge.

→ **The resilience DVs must be rebuilt from the raw all-years data, not the merged tables.**

## 3. The Lee & Chen (2022) measure (basis for DV2 and DV4)

Sensitivity proxies resilience via **expenditure gaps**; lower = more resilient.

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
  fbnp`) for ≥2013. Revenue/expenditure rows exist in both; the fund-balance source differs (§6),
  with a **separate** GASB 54 label change ~FY2011 *within* the old schema (§6).

**Diagnostics verified (cities):** 61–62 entities; near-balanced (median 30/31 yrs, none short);
stable `municipal_code`; `expenditures` = sum of `exp_L1_*`; ~5× nonlinear nominal growth → log
trend.

**Recent-year completeness (verified by fund-balance audit, fund A):** fully reported ~1995–2023
(57–62 entities/yr), then thinning: 2024 = 50/61, **2025 = 12/61 → exclude**; treat **2024 as
partial**. Usable window ≈ 1995–2023. *Substantive note:* GF balance **surges 2021→2023**
($651M→$1.25B for cities) — consistent with **ARPA/COVID federal relief**; a real recovery signal,
not an artifact.

## 5. Adaptation summary

| Paper (Lee & Chen 2022)       | This project                                                               |
| -------------------------------| ----------------------------------------------------------------------------|
| 50 US states, FY2002–2017     | NYS cities/counties/towns/school districts, FY1995–2025                    |
| Unit = state                  | Unit = entity (`entity_name` + `municipal_code`)                           |
| All-fund object-class total   | **General Fund (`A`)**, **current operating** via object class             |
| Single relative DV            | **DV1** buffer + **DV2** exp. gap + **DV3** recovery + **DV4** revenue gap |
| Level-linear trend            | **Log-linear** trend                                                       |
| Reference = national avg/year | **Entity type × size class × year**                                        |

## 6. DV1 — Fund-balance buffer

General Fund (`fund == "A"`). Source rows differ by era (clean schema break FY2012→2013); extract
per era and stack:

| Quantity | Old era (≤2012) | New era (≥2013) |
|---|---|---|
| Statement field | `financial_statement` | `account_code_section` |
| **Total ending fund balance** | balance-sheet **stock** equity for fund A (exclude `equity in fixed assets`, `equity - contributions`, `trust equity`, and change-in-equity *flow* rows) | `account_code_section == "fbnp"` & narrative `"fund balance - end of year"` |
| **Available balance** | `equity - unreserved` (pre-54) / `equity - unassigned` (+`assigned`) (post-54) | `gl` narrative `"unassigned fund balance"` (+ `assigned appropriated/unappropriated`) |

**DV1 ratios** (higher = more buffer = more resilient):
- `fb_ratio_it = total_fund_balance_it / total_GenFund_expenditures_it`
- `available_fb_ratio_it = available_balance_it / total_GenFund_expenditures_it`

**Denominator = TOTAL General Fund expenditures** (all objects, GFOA convention; optionally +
transfers out) — *not* the operating base used for DV2. State the choice explicitly to keep the
ratio unambiguous.

**Two distinct breakpoints (verified year-by-year) — do not conflate:**
1. **GASB 54 label change (~FY2011), within the old schema.** Verified for fund A: 2009–2010 =
   `reserved`/`unreserved`; **2011 = MIXED** (both pre- and post-54 labels, staggered adoption);
   2012 = post-54 only (`unreserved` gone — a naive `== "equity - unreserved"` returns nothing).
2. **Schema-column change (FY2012→2013):** equity *segments* → `gl`/`fbnp` *narratives*.

**→ Use a per-entity-year *adaptive* available-balance rule:** take `unreserved` where present,
else `unassigned` (+`assigned`). Handles mixed 2011 and both breaks automatically. Continuity
check (clean extraction, cities): total GF balance 2012 ($536M) → 2013 ($672M) — a ~25% step
that is entity-specific (Albany, e.g., is continuous), to inspect per the validation step. A **build-time
validation** enumerates the exact labels present in *every* year before trusting the spliced series.

## 7. DV2 — Expenditure-gap sensitivity (General Fund operating)

**Operating base:** `E_op_it = Σ amount` where `fund == "A"`, segment = expenditure, and
`object_of_expenditure ∈ {personal services, contractual, employee benefits}` (excludes capital
outlay, debt principal/interest, interfund transfers). Verified populated and smooth every year.

**Steps** (per unit series `E_op`; optionally repeat for `exp_L1_*` within the General Fund):
0. **Validate years** (§4); drop FY2025, flag FY2024; set window.
1. Order by unit × `calendar_year`; require `E_op > 0`, non-missing; record coverage.
2. **Absolute short-run gap** `exp_gap_sr` on consecutive years only.
3. **Absolute long-run gap** `exp_gap_lr` via per-unit `log(E_op) ~ year` (≥ `MIN_YEARS`, default
   8; else `NA`). The `exp_gap_*` are **absolute DVs** (retain common shocks).
4. **Size class:** within-type quintiles of each unit's time-averaged **real** GF operating
   expenditure; static per unit.
5. **Reference-group means:** mean gap per `size_class × year`; suppress cells `< MIN_GROUP`
   (default 5). Robustness: median/trimmed mean.
6. **Relative sensitivity DVs:** `sensitivity_sr = exp_gap_sr / group_mean_sr`, likewise `_lr`.

> **Why both absolute and relative:** relative sensitivity divides out the year's common shock
> (everyone hit in 2020 → nobody looks unusually sensitive) → measures *idiosyncratic* volatility
> (peer/resource comparison). The absolute gap keeps the common-shock signal the COVID/disaster
> framing needs.

> **Look-ahead caveat:** the long-run `Ehat` is fit on the whole series; note in-sample look-ahead
> if `*_lr` is later used as a DV against lagged predictors.

## 8. DV3 — Shock recovery trajectory (planned)

Captures *bounce-back* (the README's verb), which DV1/DV2 do not: a unit can be volatile yet
recover fast, or stable yet never recover. Built in the analysis stage once shock dates are fixed.

**Anchor shocks:** common — 2008–09 (GFC), 2020 (COVID); extensible to entity-specific
**disaster-declaration** years (FEMA) later. **Target series** `Y` (compute per series): GF
operating expenditure, GF own-source revenue (DV4), and/or `available_fb`.

**Per unit × shock `s` (shock year `t0`):**
- **Baseline** `B` = pre-shock level/trend (e.g., log-trend prediction at `t0`, or mean of
  `t0-3..t0-1`).
- **Drawdown depth** = max proportional shortfall below `B` in `[t0, t0+W]`: `max(0, (B - Y_t)/B)`.
- **Recovery time** = first `k` with `Y_{t0+k} ≥ B`; **right-censored** if not recovered by panel
  end (flag separately — important for 2020 given the short post-window).
- Optional **recovery ratio** at fixed horizon `h`: `Y_{t0+h}/B`.

*Resilience = shallow drawdown + short recovery time.* Caveats: needs defined shock dates and
windows; censoring; works best on revenue / fund balance (clearer shock response than smoothed
spending); deflate `Y` first.

## 9. DV4 — Revenue-side resilience (planned)

The paper's mechanism is "shocks weaken the tax base → revenues fall"; the README lists **revenue
recovery**. Apply the DV2 machinery (§3, §7) to General Fund **revenue** rows.

**Bases:**
- `R_total` = total GF revenues.
- `R_own` = **own-source** = GF revenues excluding intergovernmental aid (state aid + federal aid)
  and debt proceeds/other sources — i.e., taxes + charges + local revenue. (Define precisely from
  `rev_L1_*`: keep real property taxes & assessments, sales/use tax, other non-property taxes,
  other real property tax items, charges for services, other local revenues, use & sale of
  property; exclude state aid, federal aid, proceeds of debt, other sources, charges to other
  governments.)
- `R_tax` = property + sales tax only (sharpest tax-base measure).

Produce absolute `rev_gap_sr/lr` and relative `rev_sensitivity_sr/lr` for each base, mirroring §7
(log trend, size-class reference). Lower = more resilient.

## 10. Output variables and naming

General Fund, per unit-year (DV1/DV2) or per unit-shock (DV3):

| Variable | Meaning |
|---|---|
| `fund_balance` / `available_fb` | GF ending total / available balance ($) |
| `fb_ratio` / `available_fb_ratio` | **DV1** — balance ÷ total GF expenditures (higher = resilient) |
| `exp_gap_sr` / `exp_gap_lr` | **DV2 absolute** — GF operating volatility (retains shocks) |
| `sensitivity_sr` / `sensitivity_lr` | **DV2 relative** — peer-normalized (lower = resilient) |
| `recovery_drawdown_<shock>` / `recovery_years_<shock>` | **DV3** — depth / time-to-recover (per shock) |
| `rev_gap_sr/lr` · `rev_sensitivity_sr/lr` (× `total`/`own`/`tax`) | **DV4** — revenue-side gaps/sensitivity |
| `size_class` | Within-type size quintile (1–5), static |

**Register every new variable** in `transparency/variable_registry.md` (Derived variables table)
with formula + source rows. Add a **fund-code dictionary** and the **equity-label/GASB-54
crosswalk** to `transparency/`.

## 11. Open decisions

1. **End years (resolved by audit):** drop **FY2025**; **FY2024** partial — drop or flag-and-keep.
2. **Fund-balance denominator:** total GF expenditures (default) vs revenues; ± transfers out.
3. **Available-balance breadth** (via §6 adaptive rule): narrow (`unassigned`/`unreserved`) vs
   broad (`+ assigned`). Default: both, lead broad for pre/post-2012 comparability.
4. **Size proxy & bins:** real GF operating expenditures, quintiles (tertiles if sparse).
5. **`MIN_YEARS`** (default 8), **`MIN_GROUP`** (default 5).
6. **Group statistic:** mean (paper) vs median/trimmed (robust).
7. **Deflation/per-capita:** DV gap nominal (paper); real for size class; revisit with Census pop.
8. **DV3 shock dates/windows** and **DV4 own-source definition** to finalize when those are built.
9. **Functional-category DV2 within General Fund:** include now or defer.

## 12. Implementation

The pipeline stages are already scaffolded (banded by tens) and listed in `code/master.R`;
implementation means filling the stubs, not creating files. DV1–DV4 are built in
**`code/40_construct_resilience.R`**; predictors in `45_construct_predictors.R`; the joined
modeling panel in `50_assemble_panel.R`; models in `70_model_main.R` / `75_model_robustness.R`.

- **`code/40_construct_resilience.R`** (stub) runs after `30_merge.R`, reads
  `data/OSC/*_data_all.rds` (raw — retains object/fund/statement), writes
  `data/processed_data/<entity>_resilience.rds`. Helpers live in `code/functions/resilience.R`.
- Generalized function, e.g. `build_resilience(raw_all, fund = "A", operating_objects = c(...),
  drop_years = 2025, trend = "log", min_years = 8, min_group = 5)`; prototype on cities then
  county/town/school.
- **Generalization caveat — "General Fund = `A`" does not transfer cleanly.** It's a
  city/county/town convention; **towns** also have `B` (general, part-town/outside-village) and
  `DA/DB` highway, and **school districts** use a different chart of accounts. **Verify the General
  Fund identifier per entity type** before generalizing the prototype, or DV1/DV2 silently break
  for schools.
- Optionally extend `10_import.R`/`20_clean.R` to retain object/fund/balance-sheet so the merged
  tables carry them too; then uncomment the relevant stages in `code/master.R`.

## 13. Validation

- `sensitivity_*` ≈ 1 per `size_class × year` cell; **absolute** `exp_gap_*` should spike in
  2009/2020 (confirms the absolute/relative distinction).
- `fb_ratio` plausible range (~0–0.5+; negative = deficit fund balance — real, flag it); inspect
  **both breakpoints** (GASB 54 ~FY2011 mixed adoption; schema FY2012→2013) for level shifts. The
  adaptive rule (§6) should keep `available_fb` continuous; total-FB 2012 $536M → 2013 $672M is the
  benchmark.
- **External validation vs OSC Fiscal Stress Monitoring System (FSMS).** OSC publishes
  fund-balance-% and fiscal-stress scores per local government; cross-check a handful of computed
  `fb_ratio` city-years against FSMS to validate DV1 against an authoritative source.
- **Fund-balance reconciliation (new era):** `gl` components (unassigned + committed + assigned +
  restricted + nonspendable) should sum to the `fbnp` end-of-year total; quantify any gap.
- Object-class operating base reconciles: operating + capital + debt + transfers ≈ GF total exp.
- Report share/cause of `NA` DVs (short panels, missing equity rows, zero base, censored recovery).

## 14. Downstream link

DV1 (buffer), DV2-absolute (volatility incl. common shocks), and DV3 (recovery) directly serve the
COVID/disaster framing (event-time, pre/post-shock). DV2/DV4-relative serve peer/resource
comparisons as in Lee & Chen. DV4 captures the revenue/tax-base shock channel. Shock indicators and
explanatory variables (legacy costs, vulnerability, capacity, politics) are added later and
registered as their own variables/models.

## 15. References

- Lee, S. & Chen, G. (2022). Understanding financial resilience from a resource-based view:
  Evidence from US state governments. *Public Management Review*, 24(12), 1980–2003.
- Villani (2018); Wang & Hou (2009); Marlowe (2005); Park, Kim & Chen (2020); Hou (2003); Feder &
  Mustra (2018); Martin (2011). GASB Statement No. 54 (fund balance reporting). NYS OSC Fiscal
  Stress Monitoring System.

# Plan: Predictor Variables — Fund-Balance Buffer & Revenue Volatility

These two variable families are the **predictor / right-hand side** of the resilience model. The
**outcome** — operating-expenditure stability — is in
`plan_docs/01_fiscal_resilience_dv_plan.md`. Both families are **constructed in the same raw
General Fund pass** as the expenditure outcome (`code/40_construct_resilience.R`, helpers in
`code/functions/resilience.R`), and written into `data/processed_data/<entity>_resilience.rds`;
what distinguishes them is their **analytic role** (assigned in `plan_docs/01` §1):

- **Fund-balance buffer = resource / capacity (moderator).** A *stock of slack* that lets a
  government keep services stable when revenue shocks hit (resource-based view of Lee & Chen 2022).
  Used as a **moderator**, not an outcome.
- **Revenue volatility = stressor / exposure.** The revenue→expenditure link is partly mechanical
  (budget constraint), so the resilience signal is the **pass-through**: a resilient city absorbs a
  revenue shock *without* cutting spending.

Distinct from the **external-shock** predictors (FEMA disaster, recession, aid/revenue shock flags)
in `plan_docs/04_external_shock_predictors_plan.md`, and from the **recovery** outcome in
`plan_docs/03_recovery_variable_plan.md`. Shared construction conventions — General Fund = account
letter `A`, the two-era schema (FY2012→2013 break), the log-linear trend, the entity-type × size
class × year reference group — are defined in `plan_docs/01` §2–§6 (esp. §3, the gap/sensitivity
machinery), and are not repeated here.

> *Terminology note:* the construction IDs "DV1" (buffer) and "DV4" (revenue) used in earlier
> drafts are retained only as cross-references to the variable registry; the **roles** are as
> labeled above (predictors), per `plan_docs/01` §1.

## 1. Fund-balance buffer (resource / moderator)

General Fund (`fund == "A"`). Source rows differ by era (clean schema break FY2012→2013); extract
per era and stack:

| Quantity | Old era (≤2012) | New era (≥2013) |
|---|---|---|
| Statement field | `financial_statement` | `account_code_section` |
| **Total ending fund balance** | balance-sheet **stock** equity for fund A (exclude `equity in fixed assets`, `equity - contributions`, `trust equity`, and change-in-equity *flow* rows) | `account_code_section == "fbnp"` & narrative `"fund balance - end of year"` |
| **Available balance** | `equity - unreserved` (pre-54) / `equity - unassigned` (+`assigned`) (post-54) | `gl` narrative `"unassigned fund balance"` (+ `assigned appropriated/unappropriated`) |

**Buffer ratios** (higher = more buffer = more resilient capacity):
- `fb_ratio_it = total_fund_balance_it / total_GenFund_expenditures_it`
- `available_fb_ratio_it = available_balance_it / total_GenFund_expenditures_it`

**Denominator = TOTAL General Fund expenditures** (all objects, GFOA convention; optionally +
transfers out) — *not* the operating base used for the expenditure-stability outcome
(`plan_docs/01` §5). State the choice explicitly to keep the ratio unambiguous.

**Two distinct breakpoints (verified year-by-year) — do not conflate:**
1. **GASB 54 label change (~FY2011), within the old schema.** Verified for fund A: 2009–2010 =
   `reserved`/`unreserved`; **2011 = MIXED** (both pre- and post-54 labels, staggered adoption);
   2012 = post-54 only (`unreserved` gone — a naive `== "equity - unreserved"` returns nothing).
2. **Schema-column change (FY2012→2013):** equity *segments* → `gl`/`fbnp` *narratives*.

**→ Use a per-entity-year *adaptive* available-balance rule:** take `unreserved` where present,
else `unassigned` (+`assigned`). Handles mixed 2011 and both breaks automatically. Continuity
check (clean extraction, cities): total GF balance 2012 ($536M) → 2013 ($672M) — a ~25% step
that is entity-specific (Albany, e.g., is continuous), to inspect per the validation step. A
**build-time validation** enumerates the exact labels present in *every* year before trusting the
spliced series.

*Substantive note (usable window / ARPA):* GF balance **surges 2021→2023** ($651M→$1.25B for
cities) — consistent with **ARPA/COVID federal relief**; a real recovery signal, not an artifact
(`plan_docs/01` §4 for the year-completeness audit).

## 2. Revenue volatility (stressor / exposure)

The paper's mechanism is "shocks weaken the tax base → revenues fall." Apply the same gap /
sensitivity machinery as the expenditure outcome (`plan_docs/01` §3 and §5 — log-linear trend,
size-class × year reference group) to General Fund **revenue** rows.

**Bases:**
- `R_total` = total GF revenues.
- `R_own` = **own-source** = GF revenues excluding intergovernmental aid (state aid + federal aid)
  and debt proceeds/other sources — i.e., taxes + charges + local revenue. (Define precisely from
  `rev_L1_*`: keep real property taxes & assessments, sales/use tax, other non-property taxes,
  other real property tax items, charges for services, other local revenues, use & sale of
  property; exclude state aid, federal aid, proceeds of debt, other sources, charges to other
  governments.)
- `R_tax` = property + sales tax only (sharpest tax-base measure).

Produce absolute `rev_gap_sr/lr` and relative `rev_sensitivity_sr/lr` for each base, mirroring
`plan_docs/01` §5 (log trend, size-class reference). Higher gap = more volatile = more exposed.

> The downside-only **negative-tail** of these revenue series (a sharp real decline, not two-sided
> volatility) is operationalized separately as a binary **revenue-shock flag** in
> `plan_docs/04_external_shock_predictors_plan.md` (channel A). This section is the continuous
> two-sided volatility predictor; §04 is the event flag.

## 3. Output variables and naming

General Fund, per unit-year. Register every variable in `transparency/variable_registry.md`.

| Variable | Meaning |
|---|---|
| `fund_balance` / `available_fb` | GF ending total / available balance ($) |
| `fb_ratio` / `available_fb_ratio` | Buffer — balance ÷ total GF expenditures (higher = more capacity) |
| `rev_total` / `rev_own` / `rev_tax` | GF revenue bases ($) |
| `rev_gap_sr/lr` · `rev_sensitivity_sr/lr` (× `total`/`own`/`tax`) | Revenue volatility — gaps / peer-normalized sensitivity |
| `size_class` | Within-type size quintile (1–5), static (shared with the outcome) |

Add a **fund-code dictionary** and the **equity-label / GASB-54 crosswalk** to `transparency/`.

## 4. Validation

- `fb_ratio` plausible range (~0–0.5+; negative = deficit fund balance — real, flag it); inspect
  **both breakpoints** (GASB 54 ~FY2011 mixed adoption; schema FY2012→2013) for level shifts. The
  adaptive rule (§1) should keep `available_fb` continuous; total-FB 2012 $536M → 2013 $672M is the
  benchmark.
- **External validation vs OSC Fiscal Stress Monitoring System (FSMS).** OSC publishes
  fund-balance-% and fiscal-stress scores per local government; cross-check a handful of computed
  `fb_ratio` city-years against FSMS to validate the buffer against an authoritative source.
- **Fund-balance reconciliation (new era):** `gl` components (unassigned + committed + assigned +
  restricted + nonspendable) should sum to the `fbnp` end-of-year total; quantify any gap.
- Revenue: `rev_sensitivity_*` ≈ 1 per `size_class × year` cell; **absolute** `rev_gap_*` should
  spike in 2009/2020 (the common revenue shocks).
- Report share/cause of `NA` (short panels, missing equity rows, zero base).

## 5. Open decisions

1. **Fund-balance denominator:** total GF expenditures (default) vs revenues; ± transfers out.
2. **Available-balance breadth** (via §1 adaptive rule): narrow (`unassigned`/`unreserved`) vs
   broad (`+ assigned`). Default: both, lead broad for pre/post-2012 comparability.
3. **Revenue own-source definition** (the `rev_L1_*` keep/exclude list in §2) — finalize.
4. **Deflation/per-capita:** nominal vs real for ratios/gaps; revisit with Census population.

## 6. References

- `plan_docs/01_fiscal_resilience_dv_plan.md` (expenditure outcome + shared conventions),
  `plan_docs/03` (recovery), `plan_docs/04` (external-shock predictors).
- Lee, S. & Chen, G. (2022). Understanding financial resilience from a resource-based view:
  Evidence from US state governments. *Public Management Review*, 24(12), 1980–2003.
- GASB Statement No. 54 (fund balance reporting). NYS OSC Fiscal Stress Monitoring System.

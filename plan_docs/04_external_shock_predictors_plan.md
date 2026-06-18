# Plan: External Shock Measurements (predictors / exposure)

Builds **entity-year external-shock indicators** — the *stressor / exposure* side of the
resilience model (`plan_docs/01_fiscal_resilience_dv_plan.md` §1). These are **predictors**, not
outcomes: they capture *what hit the government from outside*, against which the resilience DVs
(buffer, expenditure stability, recovery) are evaluated.

Built in **`code/45_construct_predictors.R`** (currently a stub); helpers in a new
`code/functions/shocks.R`. Output: `data/processed_data/<entity>_shocks.rds` (entity-year),
joined into the modeling panel by `code/50_assemble_panel.R`.

## 1. Scope and design decisions (resolved with project owner 2026-06-18)

| Decision | Choice |
|---|---|
| **Channels** | All four: (A) revenue shocks (own/tax), (B) state-aid shocks, (C) natural-disaster (FEMA), (D) macro/recession |
| **Form** | **Binary event flags** (0/1) per channel — primary. Continuous magnitudes computed as inputs and kept as auxiliary columns, but the modeling variable is the flag. |
| **External data** | Yes — import FEMA disaster declarations and BLS county unemployment, in addition to OSC finance data. |
| **Grain** | Entity-year (`calendar_year`, `entity_name`, `municipal_code`), matching the resilience panel. |
| **Direction** | Shocks are **adverse** events only (revenue *falls*, aid *cut*, disaster *declared*, recession/unemployment *up*) — these flags mark downside exposure. |
| **Threshold rule (A & B)** | **Fixed real-decline cutoff** (resolved): flag = 1 if real YoY decline exceeds a fixed %. Defaults **own/tax −5%**, **aid −10%**. Interpretable + comparable across entities. (Distributional/entity-relative kept only as an optional robustness variant.) |
| **Geo mapping (C & D)** | **Derived from OSC data** (resolved) — every entity already carries a populated `COUNTY` field (**verified** 1995/2005/2020, all types incl. county entities, **0 blanks**). No owner crosswalk needed. Claude adds a static county-name→FIPS lookup (62 NY counties) to join FEMA/BLS. |
| **Data provision** | Owner provides: FEMA declarations, BLS county unemployment. Claude derives entity→county from OSC `COUNTY`, builds the NY county-FIPS table, and sources NBER recession years (public, hard-coded). |
| **Scope/sequencing** | Prototype on **cities** (as the DVs did), then county/town; school deferred (`plan_docs/01` §12). |

A shock is *external* = not a direct discretionary choice of the government. Revenue and aid
declines are the **downside tail** of the (mostly exogenous) tax base / state-budget environment;
FEMA and recession/unemployment are unambiguously exogenous. We measure the **adverse realization**,
not normal two-sided volatility (that is what DV4 already does).

## 2. Why this is distinct from existing work

- **DV4 (revenue gaps)** is *absolute, two-sided volatility* — an outcome/stressor magnitude.
  A revenue **shock flag** is the *signed downside event*: real revenue fell by more than a
  threshold. (Same series, different operationalization — direction + a cut point.)
- **DV3 (recovery)** uses 2009/2020 as **common anchor years** to define an event study. These
  shock flags are **entity-specific and time-varying**, so a city with no FEMA declaration and a
  flat tax base in 2009 is *not* coded as shocked even though 2009 is the GFC anchor.
- These are **predictors** feeding `50_assemble_panel.R`; the DVs are outcomes.

## 3. Inputs

| Channel | Source | New data? | Mapping needed |
|---|---|---|---|
| A. Revenue | `<entity>_resilience.rds` (`rev_own`, `rev_tax`, `rev_total`) + `data/reference/price_index.csv` (CPI-U) | No | none |
| B. State aid | GF state + federal aid. **Quick path:** `rev_total − rev_own` (= intergov aid + charges to other govts), already in panel. **Precise path:** add `rev_state_aid` / `rev_fed_aid` bases to `extract_gf_revenue()` in `functions/resilience.R` | No (precise path = small edit) | none |
| C. FEMA | FEMA OpenFEMA "Disaster Declarations Summaries" (county-level, public API/CSV) | **Yes (owner)** | county (from OSC) → FIPS |
| D. Macro | NBER recession dating (common years; trivial) + BLS LAUS county unemployment (annual) | **Yes (owner: BLS)** | county (from OSC) → FIPS |

**Entity → county is free from the OSC data.** The raw `<entity>_data_all.rds` retains a populated
`COUNTY` column for every entity-row (verified: cities/towns/schools/counties, 1995–2020, 0 blanks).
The build derives a one-row-per-entity lookup `(municipal_code, entity_name, entity_type, county)`
and joins a static **`data/reference/ny_county_fips.csv`** (62 rows, `county_name`, `county_fips`,
built by Claude from the published NY FIPS list) to get the `county_fips` join key for FEMA/BLS.
School districts can span counties; OSC assigns one primary county — acceptable, and schools are
deferred anyway (`plan_docs/01` §12).

## 3b. Data the project owner provides (exact specs)

Only **two** CSVs are needed from the owner — entity→county is derived from OSC, and the
county-FIPS lookup is built by Claude. Files go in `data/reference/` (gitignored; provenance in
`transparency/reference_sources.md`). Column names below are what the build code expects — keep
them exact (lowercase) or tell me the mapping.

*(Built by Claude, no owner action — listed for completeness:)*
- **`ny_county_fips.csv`** — `county_name` (lowercase), `county_fips` (5-digit, e.g. `36001`).
  Static 62-row NY lookup from the published Census FIPS list; the bridge from the OSC `COUNTY`
  name to the FEMA/BLS FIPS key.
- **entity→county lookup** — derived in-build from the OSC `COUNTY` column (no file).

**1. FEMA disaster declarations** (e.g. `fema_declarations.csv`) — NY, county-level. The raw
OpenFEMA "Disaster Declarations Summaries" export is fine; I'll reduce it to a county-year table.
Minimum columns I need:

| Column | Notes |
|---|---|
| `county_fips` (or `fipsStateCode`+`fipsCountyCode`, or `designatedArea` county name) | so I can join to the crosswalk |
| declaration year (or a date I can extract the year from) | `calendar_year` of the incident/declaration |
| `declarationType` | to keep `DR` (Major Disaster); drop `EM`/`FM` unless you want them |
| `incidentType` | to exclude `Biological` (COVID) so it doesn't double-count the macro channel |

**2. BLS county unemployment** (e.g. `bls_laus_county.csv`) — NY counties, **annual average**.

| Column | Notes |
|---|---|
| `county_fips` | join key |
| `calendar_year` | year |
| `unemp_rate` | annual average unemployment rate (%) |

*Annual averages preferred. If you only have monthly, I'll average to annual.*

## 4. Channel definitions (binary flags + continuous inputs)

All real-dollar computations deflate by `price_index` (CPI-U, base 2023) first, reusing the DV3
deflator. Thresholds (`θ`) are parameters with stated defaults; report robustness at alternates.

### A. Revenue shock — `shock_rev_own`, `shock_rev_tax`
Real signed year-over-year change `g_t = (R_t − R_{t−1}) / R_{t−1}` on **consecutive years**,
real dollars, per base (`rev_own`, `rev_tax`).
- **Flag** `shock_rev_own_t = 1` if `g_t ≤ −θ_rev` (default **θ_rev = 0.05**, i.e. a ≥5% real
  decline), else 0; `NA` if no consecutive prior year.
- Auxiliary continuous: `rev_own_real_chg = g_t` (kept for sensitivity / dose-response).
- Robustness variants: θ ∈ {0.05, 0.10}; a **distributional** rule (bottom decile of pooled `g`)
  as an alternative to a fixed cut.

### B. State-aid shock — `shock_aid`
Real signed YoY change in GF intergovernmental aid (`aid_t`; quick path = `rev_total − rev_own`,
precise path = `rev_state_aid + rev_fed_aid`).
- **Flag** `shock_aid_t = 1` if real `(aid_t − aid_{t−1})/aid_{t−1} ≤ −θ_aid`
  (default **θ_aid = 0.10** — aid is lumpier than own-source, so a higher cut point).
- Auxiliary: real aid change; aid share of `rev_total`.

### C. Disaster shock — `shock_disaster`
From FEMA Major Disaster Declarations (`DR` type) intersected with the entity's county-year.
- **Flag** `shock_disaster_t = 1` if ≥1 qualifying federal disaster declaration covers the
  entity's county in calendar year `t`.
- **Incident-type filter:** include physical natural disasters (flood, severe storm, hurricane,
  snow, fire); **exclude** `Biological` (COVID-19) so it does not double-count the macro channel —
  state this explicitly.
- Auxiliary: `disaster_count_t` (number of declarations), `disaster_types_t`.
- Caveat: county-level declaration ≠ direct fiscal hit on every municipality in it; this is an
  **exposure proxy**. Note it.

### D. Macro shock — `shock_recession`, `shock_unemp`
- `shock_recession_t = 1` for **NBER recession years** (any month in recession): default
  **{2001, 2007, 2008, 2009, 2020}** (2007 included — the GFC recession began Dec 2007; pending
  owner confirmation, see §8) — a *common* (entity-invariant) dummy; collinear with year FE, so
  it is for **no-year-FE / event-time** specifications only (note this).
- `shock_unemp_t = 1` if the county's annual average unemployment rate **rose ≥ θ_u ppt** YoY
  (default **θ_u = 2.0**) — an entity-varying macro shock. Auxiliary: county unemployment level
  and YoY change.

### Composite
- `shock_any_t = max` of the (non-`NA`) channel flags (any external shock that year).
- `shock_count_t = Σ` channel flags (intensity by breadth of simultaneous shocks).
Report both; the headline modeling shock is channel-specific, with `shock_any` as a summary.

## 5. Function and driver design

New `code/functions/shocks.R` — pure, no I/O, `dplyr::`/`tibble::` qualifiers (project linter
convention), mirroring `functions/resilience.R`:

```r
# Generic adverse-decline flag on one real-deflated series (channels A, B).
flag_decline_shock <- function(panel, value_col, deflator, theta = 0.05,
                               flag = "shock", chg = NULL) { ... }   # signed real YoY <= -theta

# County-year event flag join (channels C, D), via the OSC-derived entity->county lookup
# bridged to FIPS by ny_county_fips.csv.
flag_county_event  <- function(panel, county_map, county_year_events, flag) { ... }

# Top-level: assemble all channels for one entity's resilience panel.
build_shock_predictors <- function(resil, deflator, county_map = NULL,
                                    fema = NULL, laus = NULL,
                                    nber_years = c(2001,2007,2008,2009,2020),
                                    theta_rev = 0.05, theta_aid = 0.10, theta_u = 2.0) { ... }
```

`code/45_construct_predictors.R` driver: read each `<entity>_resilience.rds` + the reference
tables, call `build_shock_predictors()`, write `data/processed_data/<entity>_shocks.rds`. When the
band grows multi-source, promote to a `45_predictors/` subfolder per the stub's own note.

## 6. Build order

1. **Channel A (revenue)** — buildable now, no new data. Implement `flag_decline_shock`, run on
   `rev_own` / `rev_tax`. *(First deliverable.)*
2. **Channel B (state aid)** — quick path (`rev_total − rev_own`) now; add precise
   `rev_state_aid`/`rev_fed_aid` bases to `extract_gf_revenue()` as a follow-up.
3. **County keys** — derive entity→county from the OSC `COUNTY` column; build static
   `ny_county_fips.csv` (no owner data needed; blocks C, D).
4. **Channel D (recession)** — NBER dummy (trivial); BLS LAUS unemployment after county keys.
5. **Channel C (FEMA)** — import OpenFEMA declarations, map to county-year, after county keys.
6. Register all variables (`transparency/variable_registry.md` + `main_variable_registery.md`),
   sources in `transparency/reference_sources.md`; add descriptives (a `66_*` band).

## 7. Validation

- **Revenue/aid flags spike at known shocks:** `shock_rev_own` / `shock_aid` rates should rise in
  2009–2011 and 2020 across cities (sanity vs the GFC/COVID anchors) — but **not** be 100%, since
  the point is entity-specific variation.
- **Threshold sensitivity:** report flag prevalence at θ ∈ {0.05, 0.10} and the distributional
  rule; the substantive ranking of shocked vs not should be stable.
- **FEMA:** spot-check known NY events (e.g. Hurricane Sandy 2012 — coastal/downstate counties;
  Irene/Lee 2011 — Mohawk/Hudson valleys) land on the right county-years.
- **County keys:** every entity's OSC `COUNTY` maps to exactly one `county_fips` via
  `ny_county_fips.csv` (0 unmatched county names); spot-check a few entity→county assignments.
- **Recession dummy** collinearity with year FE flagged; use only where appropriate.
- Report `NA` shares (no prior year for A/B; unmatched county for C/D) and flag prevalence per
  channel per year.

## 8. Open decisions

1. **State-aid base:** quick (`rev_total − rev_own`, bundles federal + charges-to-other-govts) vs
   precise (dedicated GF `state aid` extraction). Default: build quick now, precise as follow-up.
2. **Thresholds (rule resolved = fixed cutoff):** exact θ_rev (5%), θ_aid (10%), θ_u (2.0 ppt)
   are defaults — confirm/tune after viewing the real-decline distributions on the built panel.
3. **Disaster window:** flag declaration year only, or also `t+1` (recovery/cleanup spending lag)?
4. **COVID handling:** disaster flag excludes the biological declaration; COVID enters via
   recession + the 2020 DV3 anchor. Confirm no double-count.
5. **Fiscal-year vs calendar-year** alignment for FEMA/NBER/BLS (OSC `calendar_year` semantics) —
   verify the OSC year convention before joining annual external series.
6. **NBER recession year set:** proposed default **{2001, 2007, 2008, 2009, 2020}** (calendar
   years touching a US recession). Confirm, or restrict to **{2008, 2009, 2020}** (GFC + COVID).

## 9. References

- `plan_docs/01_fiscal_resilience_dv_plan.md` §1 (stressor/exposure role), §9 (revenue bases),
  §14 (downstream link); `plan_docs/03_recovery_variable_plan.md` (2009/2020 anchors, deflator).
- FEMA OpenFEMA — Disaster Declarations Summaries. BLS LAUS — county annual unemployment.
  NBER US business cycle expansions and contractions. Lee & Chen (2022).

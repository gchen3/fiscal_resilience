# Model Registry

Hand-maintained audit trail for every statistical model / estimation run in the project.
The goal is that any reported result can be traced back to its specification, sample, and
source variables without re-reading the code.

- **Maintenance:** hand-edited. Add one entry per model **specification** (not per run) when
  a model is created in `code/70_model_main.R` / `code/75_model_robustness.R`. Give each a
  stable `model_id`.
- **Trace to source:** every variable referenced below (dependent or independent) should
  exist as a row in [`variable_registry.md`](variable_registry.md), so a result traces
  result → model → variables → raw OSC data.

## Status

No models have been estimated yet. `code/60_descriptives.R` currently produces **descriptive
summary statistics only** (`*_summary_stats` tables and `gt` objects), not estimated models.
The first real entry will be the resilience model once a dependent variable is defined.

## Field definitions

| Field | Meaning |
|---|---|
| `model_id` | Stable short id, e.g. `M01`. Cite this in tables/slides. |
| Name | Human-readable description. |
| Type | OLS / fixed effects / event study / logit / descriptive, etc. |
| Dependent var | Outcome variable(s); must appear in `variable_registry.md`. |
| Independent vars | Predictors / controls; must appear in `variable_registry.md`. |
| Sample | Entity types, year range, and any row filters (e.g. towns 2005–2025, non-NA revenue). |
| Fixed effects / clustering | e.g. entity + year FE, SE clustered by entity. |
| Estimator / package | e.g. `fixest::feols`, `lm`. |
| Created in | Script + function producing it, e.g. `code/70_model_main.R`. |
| Output | Where results are written (table/figure file under `outputs/`). |
| Date added | Date the spec was registered. |
| Notes | Caveats, robustness variants, theory link (dynamic capabilities). |

## Models

<!-- Template — copy this block per model and fill it in:

### M01 — <name>

- **Type:** 
- **Dependent var:** 
- **Independent vars:** 
- **Sample:** 
- **Fixed effects / clustering:** 
- **Estimator / package:** 
- **Created in:** 
- **Output:** 
- **Date added:** YYYY-MM-DD
- **Notes:** 

-->

_No models registered yet._

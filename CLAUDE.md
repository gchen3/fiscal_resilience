# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

An R-based research pipeline analyzing fiscal resilience of New York local governments,
using detailed financial data from the NYS Office of the State Comptroller (OSC). It backs
an academic paper (see `public_docs/Abstract_ABFM2026_ChenKimLee.docx`). The unit of analysis
is an entity-year across four government types: **city, county, town, school district**.

## Running the pipeline

The pipeline is a sequence of numbered scripts in `code/`, orchestrated by `code/master.R`.
Scripts are **banded by tens** (gaps left so new stages insert without renumbering); pure
functions live in `code/functions/*.R` and are sourced by `00_library.R`. Run from the project
root so `here::here()` resolves paths correctly.

```r
# Full pipeline (uncomment the source() lines in master.R, or run stages individually):
source('code/00_library.R')               # setup: packages + source code/functions/*.R
source('code/10_import.R')                # Read OSC CSVs -> per-entity *_data_all.rds
source('code/20_clean.R')                 # Clean + generate finance variables in .GlobalEnv
source('code/30_merge.R')                 # Merge generated vars -> processed_data/*_data_merged.rds
source('code/40_construct_resilience.R')  # DV1-DV4 resilience variables          [stub]
source('code/45_construct_predictors.R')  # explanatory / control variables       [stub]
source('code/50_assemble_panel.R')        # join DVs + predictors -> analysis_panel [stub]
source('code/60_descriptives.R')          # summary stats + gt tables
source('code/70_model_main.R')            # main models                            [stub]
source('code/75_model_robustness.R')      # robustness / sensitivity checks        [stub]
source('code/90_output.R')                # tables/figures/exports                  [stub]
```

Run a single stage from a fresh session by sourcing `code/00_library.R` first, then the stage.
Stages reload their inputs from disk, so they can run independently **once the prior stage's
`.rds` outputs exist**. The one exception: **`30_merge.R` depends on the generated `.GlobalEnv`
objects created by `20_clean.R` in the same session** (see below).

## Stage dependencies and data flow

```
data/OSC/all_classes_years/<year>_<Class>.csv   (raw, gitignored)
  --10_import-->  data/OSC/<entity>_data_all.rds            (4 files: city/county/town/school)
  --20_clean-->   many <prefix>_<var> tables in .GlobalEnv  (NOT written to disk)
  --30_merge-->   data/processed_data/<entity>_data_merged.rds
  --60_descriptives--> <entity>_summary_stats / *_gt objects in session
```

The resilience DVs (40_construct_resilience.R) are rebuilt from the **raw** `*_data_all.rds`,
not the merged tables — `20_clean`/`30_merge` discard the object-class, fund, and balance-sheet
detail those DVs need. See `plan_docs/01_fiscal_resilience_dv_plan.md`.

`10_import.R` only reads `City`, `County`, `Town`, `SchoolDistrict` classes (Village and
FireDistrict CSVs exist in the raw folder but are ignored). It lowercases all column names,
binds all years (1995–2025) with a `year` column, and splits `account_code` into
`account_code_letter` / `account_code_number`.

## The .GlobalEnv generated-object convention (critical to understand 20 → 30)

`20_clean.R` does not return tidy tables — via `generate_entity_finance_vars()`
(`functions/finance.R`) it **assigns** many objects into `.GlobalEnv`, one per finance variable
per entity, named `<entity_prefix>_<variable>`:

- Prefixes: `city`, `county`, `town`, `school`.
- Variables: `expenditures`, `revenues`, and per-category `exp_L1_*`, `exp_L2_*`, `rev_L1_*`,
  `rev_L2_*` (L1/L2 = OSC `level_1_category` / `level_2_category`).
- Example object names: `city_expenditures`, `county_exp_L1_general_government`,
  `school_rev_L2_real_property_taxes`.

Each generated object is a small table keyed by `calendar_year, entity_name, municipal_code`
plus exactly one metric column. Categories are derived **separately per entity type**, so the
set of available `exp_L*`/`rev_L*` columns differs across city/county/town/school.

`30_merge.R` discovers these objects by `ls(pattern = "^<prefix>_")`, keeps only the
one-metric finance tables (key cols + 1 column), `full_join`s them onto a base key table, then
**`rm()`s every `<prefix>_*` object except `<prefix>_data_merged`**. Implications:

- Run `20_clean.R` and `30_merge.R` in the **same R session, in order**. A clean session
  cannot run `30_merge.R` alone because the generated objects only live in memory.
- Adding a new finance variable = call `generate_finance(data, var_name, filter_statement,
  entity_prefix)` inside `generate_entity_finance_vars()`; merge/cleanup pick it up
  automatically by name pattern. Keep output to key cols + one column or `30_merge.R` will
  drop it.

## Key shared functions

Pure functions live in `code/functions/` (sourced by `00_library.R`); numbered stages are thin
orchestration that call them.

- `functions/finance.R`: `clean_finance_data()` (strips `'`, lowercases, coerces numerics),
  `generate_finance()` (filters via `rlang::parse_expr()`, sums `amount` by entity-year, assigns
  to `.GlobalEnv`), `clean_var_suffix()`, `generate_entity_finance_vars()`, and the
  `expenditure_filter` / `revenue_filter` predicates (tolerate OSC singular/plural and
  `financial_statement_segment` vs `account_code_section`).
- `functions/resilience.R` (stub): DV1–DV4 construction helpers.
- `functions/models.R` (stub): model + robustness helpers.
- `merge_generated_entity_vars()` lives in `30_merge.R`; `summarize_entity_data()` /
  `make_summary_gt()` in `60_descriptives.R`.

## Committing

**Do not automatically commit.** Stage changes if helpful and suggest a commit message, but
let the project owner make the actual commit.

## Conventions

- **Paths**: always `here::here(...)` from the project root; never hardcode absolute paths.
- **Case**: column names and all character values are lowercased early — write filters and
  joins in lowercase.
- **Tables**: presentation tables use the `gt` package.
- Data is **gitignored** (`*.csv`, `*.rds`, `*.xlsx`, `*.zip`, etc. — see `.gitignore`). Raw
  OSC data and all `.rds` intermediates are local only; regenerate by re-running the pipeline.

## Data source

NYS OSC financial data for local governments (1995–2025), all government classes. See
`data/OSC/README.md` for download details and the OSC glossary link. The `code/master.R`
stage scripts and `data/OSC/all_classes_years/` raw CSVs are the ground truth for column names.

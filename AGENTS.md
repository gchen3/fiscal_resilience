# Repository Guidelines

## Project Structure & Module Organization

This repository is an R-based fiscal resilience workflow. Main scripts live in `code/`, numbered in **bands of ten** so new stages insert without renumbering: `00_library.R` (setup), `10_import.R`, `20_clean.R`, `30_merge.R`, `40_construct_resilience.R`, `45_construct_predictors.R`, `50_assemble_panel.R`, `60_descriptives.R`, `70_model_main.R`, `75_model_robustness.R`, `90_output.R`. Pure functions live in `code/functions/*.R` (`finance.R`, `resilience.R`, `models.R`), sourced by `00_library.R`; numbered stages are thin orchestration. `code/master.R` is the top-level driver (an explicit, ordered `source()` list). Raw and intermediate OSC data belong under `data/OSC/`; analysis-ready `.rds` files are written to `data/processed_data/`. Use `analysis/`, `outputs/`, `slides/`, `plan_docs/`, `public_docs/`, and `transparency/` for derived analysis, tables, decks, planning notes, public docs, and the variable/model registries.

## Build, Test, and Development Commands

- `Rscript code/master.R`: run the configured pipeline. Currently only `code/00_library.R` is active; uncomment stages in `master.R` as needed.
- `Rscript code/10_import.R`: import OSC CSV files and write entity-level `.rds` files under `data/OSC/`.
- `Rscript code/20_clean.R`: clean imported data and generate finance variables in `.GlobalEnv`.
- `Rscript code/30_merge.R`: merge generated variables and write processed entity tables (same session as `20_clean.R`).
- `Rscript code/60_descriptives.R`: load processed tables and build summary statistics/`gt` tables.

Run scripts from the repository root so `here::here()` resolves paths correctly. Each stage sources `00_library.R` (or run it first) to load packages and the `functions/` files.

## Coding Style & Naming Conventions

Use tidyverse-style R. Prefer lowercase snake_case for objects and functions, e.g. `city_data_merged` and `summarize_entity_data()`. Name stage scripts `NN_verb_noun.R` and keep them in the banded-by-ten ordering; put new stages in the appropriate band (e.g. another construct in the 40s, another model in the 70s). Put reusable functions in `code/functions/*.R`, not inline in stage scripts. Use two-space indentation inside pipes and functions where practical. Prefer explicit package calls (`readr::read_rds`, `dplyr::mutate`) in reusable code.

Generated finance variables follow `<entity_prefix>_<metric>`, such as `city_expenditures`, `county_exp_L1_general_government`, and `school_rev_L2_real_property_taxes`.

## Testing Guidelines

There is no formal test suite yet. Before committing, run the affected pipeline stages with `Rscript` and verify expected `.rds` outputs are created or refreshed. For data transformations, check row counts, key uniqueness, and representative variable summaries. If adding tests later, place them under `tests/testthat/` and name files `test-<feature>.R`.

## Commit & Pull Request Guidelines

**Do not automatically commit.** Stage changes if helpful and suggest a commit message, but let the project owner make the actual commit.

Existing commits use short, imperative summaries such as `generate summary statistics` and `import OSC data, save raw data as intermediate files.` Keep commit messages concise and focused on the workflow stage or output changed. Pull requests should describe the data source or script stage affected, list commands run, mention any regenerated files, and flag large data artifacts that remain intentionally untracked.

## Data & Configuration Notes

The `.gitignore` excludes common raw data formats (`.csv`, `.xlsx`, `.rds`, archives, and similar). Do not commit raw OSC downloads or generated data unless the project owner explicitly requests it. Keep reproducible code and lightweight documentation in git; keep bulky or sensitive data in the established `data/` folders.

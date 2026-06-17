# Repository Guidelines

## Project Structure & Module Organization

This repository is an R-based fiscal resilience workflow. Main scripts live in `code/` and are ordered by pipeline stage: `01_import.R`, `02_clean.R`, `03_merge.R`, `04_analysis.R`, and `05_outputs.R`. Shared package setup is in `code/library.R`; `code/master.R` is the top-level workflow driver. Raw and intermediate OSC data belong under `data/OSC/`; analysis-ready `.rds` files are written to `data/processed_data/`. Use `analysis/`, `outputs/`, `slides/`, `plan_docs/`, and `public_docs/` for derived analysis, tables, decks, planning notes, and public-facing documents.

## Build, Test, and Development Commands

- `Rscript code/master.R`: run the configured pipeline. Currently only `code/library.R` is active; uncomment stages in `master.R` as needed.
- `Rscript code/01_import.R`: import OSC CSV files and write entity-level `.rds` files under `data/OSC/`.
- `Rscript code/02_clean.R`: clean imported data and generate finance variables in `.GlobalEnv`.
- `Rscript code/03_merge.R`: merge generated variables and write processed entity tables.
- `Rscript code/04_analysis.R`: load processed tables and build summary statistics/`gt` tables.

Run scripts from the repository root so `here::here()` resolves paths correctly.

## Coding Style & Naming Conventions

Use tidyverse-style R. Prefer lowercase snake_case for objects and functions, e.g. `city_data_merged` and `summarize_entity_data()`. Keep numbered workflow scripts stage-specific and preserve the existing `01_` to `05_` ordering. Use two-space indentation inside pipes and functions where practical. Prefer explicit package calls (`readr::read_rds`, `dplyr::mutate`) in reusable code when clarity matters.

Generated finance variables follow `<entity_prefix>_<metric>`, such as `city_expenditures`, `county_exp_L1_general_government`, and `school_rev_L2_real_property_taxes`.

## Testing Guidelines

There is no formal test suite yet. Before committing, run the affected pipeline stages with `Rscript` and verify expected `.rds` outputs are created or refreshed. For data transformations, check row counts, key uniqueness, and representative variable summaries. If adding tests later, place them under `tests/testthat/` and name files `test-<feature>.R`.

## Commit & Pull Request Guidelines

**Do not automatically commit.** Stage changes if helpful and suggest a commit message, but let the project owner make the actual commit.

Existing commits use short, imperative summaries such as `generate summary statistics` and `import OSC data, save raw data as intermediate files.` Keep commit messages concise and focused on the workflow stage or output changed. Pull requests should describe the data source or script stage affected, list commands run, mention any regenerated files, and flag large data artifacts that remain intentionally untracked.

## Data & Configuration Notes

The `.gitignore` excludes common raw data formats (`.csv`, `.xlsx`, `.rds`, archives, and similar). Do not commit raw OSC downloads or generated data unless the project owner explicitly requests it. Keep reproducible code and lightweight documentation in git; keep bulky or sensitive data in the established `data/` folders.

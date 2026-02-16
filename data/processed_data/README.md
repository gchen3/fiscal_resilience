# Processed Merged Finance Data

This folder contains merged, analysis-ready `.rds` files created by the project cleaning and merge scripts.

## Files

- `city_data_merged.rds`
- `county_data_merged.rds`
- `town_data_merged.rds`
- `school_data_merged.rds`

## Unit of Observation

Each row represents one entity in one fiscal year, identified by:

- `calendar_year`
- `entity_name`
- `municipal_code`

## Variable Structure

Each merged file contains:

- Key columns: `calendar_year`, `entity_name`, `municipal_code`
- Generated finance totals: `expenditures`, `revenues`
- Generated category variables:
  - `exp_L1_*` and `exp_L2_*` for expenditure categories
  - `rev_L1_*` and `rev_L2_*` for revenue categories

Notes:

- Variable suffixes are cleaned from category names (non-alphanumeric characters converted to `_`).
- Category availability differs across entity types, so columns are not guaranteed to match exactly between city/county/town/school files.

## How These Files Are Created

1. `code/02_clean.R`
   - Cleans raw OSC data.
   - Generates entity-prefixed finance objects for city, county, town, and school.
2. `code/03_merge.R`
   - Merges generated variables into one wide table per entity type.
   - Removes intermediate generated objects from memory.
   - Writes the four merged `.rds` files to this folder.

## Regeneration

From project root, run scripts in order:

1. `source("code/library.R")`
2. `source("code/02_clean.R")`
3. `source("code/03_merge.R")`

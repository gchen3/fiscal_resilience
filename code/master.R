# master.R
# Top-level workflow driver. Runs the pipeline stages in order.
# Numbering is banded by tens (gaps left for inserting new stages without renumbering):
#   00 setup | 10 import | 20 clean | 30 merge | 40-50 construct | 60 descriptives |
#   70-75 model | 90 output.
# Uncomment stages as they are implemented. Each stage reads its inputs from disk and
# writes its outputs to disk, so stages can also be run individually — EXCEPT 30_merge.R,
# which depends on objects 20_clean.R creates in the same session.

# 00) Setup: packages + source code/functions/*.R
source('code/00_library.R')

# --- Cleaning -------------------------------------------------------------------
# source('code/10_import.R')        # raw OSC CSVs        -> data/OSC/*_data_all.rds
# source('code/20_clean.R')         # clean/tidy + finance vars in .GlobalEnv
# source('code/30_merge.R')         # merge               -> data/processed_data/*_data_merged.rds

# --- Construction ---------------------------------------------------------------
# source('code/40_construct_resilience.R')  # DV1-DV4     -> *_resilience.rds   [stub]
# source('code/45_construct_predictors.R')  # explanatory vars -> *_predictors.rds [stub]
# source('code/50_assemble_panel.R')        # join        -> analysis_panel.rds  [stub]

# --- Descriptives ---------------------------------------------------------------
# source('code/60_descriptives.R')  # summary stats / gt tables

# --- Models ---------------------------------------------------------------------
# source('code/70_model_main.R')        # main specifications              [stub]
# source('code/75_model_robustness.R')  # robustness / sensitivity checks  [stub]

# --- Output ---------------------------------------------------------------------
# source('code/90_output.R')        # final tables, figures, exports

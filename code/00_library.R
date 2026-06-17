# 00_library.R
# Setup: install (if missing) and load required packages, then source the
# project's pure-function files from code/functions/.

required_pkgs <- c(
  'readr',
  'vroom',
  'dplyr',
  'stringr',
  'purrr',
  'rlang',
  'tibble',
  'here',
  'tidyverse',
  'gt'
)

missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, repos = 'https://cloud.r-project.org')
}

invisible(lapply(required_pkgs, library, character.only = TRUE))

# Source reusable functions (definitions only; no side effects).
# Numbered stage scripts call these; keep stages thin and functions testable.
function_files <- list.files(here::here("code", "functions"), pattern = "[.][Rr]$", full.names = TRUE)
invisible(lapply(sort(function_files), source))

# library.R
# Install (if missing) and load required packages.

required_pkgs <- c(
  'readr',
  'dplyr',
  'stringr',
  'purrr',
  'here',
  'tidyverse',
  'gt'
)

missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, repos = 'https://cloud.r-project.org')
}

invisible(lapply(required_pkgs, library, character.only = TRUE))

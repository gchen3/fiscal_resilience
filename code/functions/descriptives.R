# functions/descriptives.R
# Pure helper functions for the resilience descriptive statistics (plan_docs/
# 02_descriptive_statistics_plan.md). Definitions only — no side effects, no I/O.
# Sourced by 00_library.R; used by 60_descriptives.R.

# Winsorize a numeric vector at the given probability bounds (figures only; never the
# stored DVs). NA-safe.
winsorize <- function(x, probs = c(0.01, 0.99)) {
  q <- stats::quantile(x, probs, na.rm = TRUE, names = FALSE)
  pmin(pmax(x, q[1]), q[2])
}

# Share of non-missing values below a threshold (default 0 -> deficit share for fb_ratio).
deficit_share <- function(x, threshold = 0) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_real_)
  mean(x < threshold)
}

# Full distribution summary for a set of variables, optionally grouped. Preserves the
# order of `vars`. Leads with mean/SD; also returns median + quartiles (skew).
describe_vars <- function(df, vars, by = NULL) {
  qn <- function(x, p) unname(stats::quantile(x, p, na.rm = TRUE))
  long <- df %>%
    dplyr::select(dplyr::all_of(c(by, vars))) %>%
    tidyr::pivot_longer(dplyr::all_of(vars), names_to = "variable", values_to = "value")
  grp <- c(by, "variable")
  long %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(grp))) %>%
    dplyr::summarise(
      n           = sum(!is.na(value)),
      pct_missing = mean(is.na(value)),
      mean        = mean(value, na.rm = TRUE),
      sd          = stats::sd(value, na.rm = TRUE),
      min         = suppressWarnings(min(value, na.rm = TRUE)),
      p25         = qn(value, 0.25),
      median      = stats::median(value, na.rm = TRUE),
      p75         = qn(value, 0.75),
      max         = suppressWarnings(max(value, na.rm = TRUE)),
      .groups = "drop"
    ) %>%
    dplyr::mutate(dplyr::across(c(min, max), ~ dplyr::if_else(is.infinite(.x), NA_real_, .x))) %>%
    dplyr::mutate(variable = factor(variable, levels = vars)) %>%
    dplyr::arrange(dplyr::across(dplyr::all_of(grp))) %>%
    dplyr::mutate(variable = as.character(variable))
}

# Pooled, between-entity, and within-entity correlation matrices (panel-aware).
# between = correlation of entity means; within = correlation of entity-demeaned series.
correlation_sets <- function(df, vars, id = c("entity_name", "municipal_code"),
                             method = "spearman") {
  d <- dplyr::select(df, dplyr::all_of(c(id, vars)))
  cm <- function(x) stats::cor(x, use = "pairwise.complete.obs", method = method)

  between <- d %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(id))) %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(vars), ~ mean(.x, na.rm = TRUE)), .groups = "drop")

  within <- d %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(id))) %>%
    dplyr::mutate(dplyr::across(dplyr::all_of(vars), ~ .x - mean(.x, na.rm = TRUE))) %>%
    dplyr::ungroup()

  list(
    pooled  = cm(d[vars]),
    between = cm(between[vars]),
    within  = cm(within[vars])
  )
}

# Van der Waerden normal-score transform (rank -> normal quantiles); skew-robust input
# for PCA. NA-preserving.
normal_score <- function(x) {
  n <- sum(!is.na(x))
  r <- rank(x, na.last = "keep")
  stats::qnorm((r - 0.5) / n)
}

# PCA on the resilience DVs. `sign` (named vector of +1/-1) sign-aligns variables so all
# point "higher = more resilient" before the normal-score transform. Listwise-deletes
# rows with any NA among `vars`. Returns prcomp object + the N used.
resilience_pca <- function(df, vars, sign = NULL) {
  m <- df[vars]
  if (!is.null(sign)) {
    for (v in names(sign)) if (v %in% names(m)) m[[v]] <- sign[[v]] * m[[v]]
  }
  z <- as.data.frame(lapply(m, normal_score))
  keep <- stats::complete.cases(z)
  z <- z[keep, , drop = FALSE]
  pr <- stats::prcomp(z, center = TRUE, scale. = TRUE)
  list(prcomp = pr, n = nrow(z), vars = vars)
}

# Tidy PCA loadings (variables x components) and variance explained.
pca_loadings <- function(pca, n_comp = NULL) {
  rot <- pca$prcomp$rotation
  if (!is.null(n_comp)) rot <- rot[, seq_len(min(n_comp, ncol(rot))), drop = FALSE]
  tibble::as_tibble(rot, rownames = "variable")
}
pca_variance <- function(pca) {
  sdev <- pca$prcomp$sdev
  tibble::tibble(
    component = paste0("PC", seq_along(sdev)),
    var_explained = sdev^2 / sum(sdev^2),
    cumulative = cumsum(sdev^2 / sum(sdev^2))
  )
}

# gt summary table from describe_vars() output. Leads with mean/SD per the chosen layout.
gt_summary_table <- function(summary_df, title, subtitle = NULL, decimals = 3) {
  num_cols <- intersect(c("mean", "sd", "min", "p25", "median", "p75", "max"), names(summary_df))
  summary_df %>%
    gt::gt() %>%
    gt::tab_header(title = title, subtitle = subtitle) %>%
    gt::fmt_number(columns = dplyr::all_of(num_cols), decimals = decimals) %>%
    gt::fmt_number(columns = dplyr::any_of("n"), decimals = 0) %>%
    gt::fmt_percent(columns = dplyr::any_of("pct_missing"), decimals = 1) %>%
    gt::cols_label(variable = "Variable")
}

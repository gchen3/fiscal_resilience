# 60_descriptives.R
# Descriptive statistics for the RESILIENCE OUTCOME variables (cities, 1995-2023).
# Spec: plan_docs/02_descriptive_statistics_plan.md   Helpers: code/functions/descriptives.R
#
# Scope: the Lee & Chen (2022) expenditure sensitivity measure ONLY — the resilience DV.
#   building blocks: exp_gap_sr, exp_gap_lr   |   DV: sensitivity_sr, sensitivity_lr
# EXCLUDES the fund-balance predictor (fb_*) and the revenue-volatility stressor (rev_*) —
# those get their own descriptives with the predictors.
#
# Reads:  data/processed_data/city_resilience.rds  (run 40_construct_resilience.R first)
# Writes: outputs/descriptives/{tables,figures}/   (01-06 sections; gt .html + .csv; .png/.pdf)
# Headline window 1995-2023 (FY2024 partial, FY2025 dropped). Figures winsorized 1/99.

suppressMessages({library(ggplot2)})

# I/O hooks (overridable by a test harness; default to the real project paths).
in_path  <- if (exists(".desc_in_path"))  get(".desc_in_path")  else here::here("data", "processed_data", "city_resilience.rds")
out_root <- if (exists(".desc_out_root")) get(".desc_out_root") else here::here("outputs", "descriptives")
tab_dir  <- file.path(out_root, "tables")
fig_dir  <- file.path(out_root, "figures")

# Start clean so stale artifacts (old T*/F*, predictor/stressor outputs) don't linger.
if (dir.exists(out_root)) unlink(out_root, recursive = TRUE)
for (d in c(tab_dir, fig_dir)) dir.create(d, recursive = TRUE)

# ---- Load & restrict sample -----------------------------------------------------------
res <- readr::read_rds(in_path) %>%
  dplyr::filter(calendar_year >= 1995, calendar_year <= 2023)        # headline window

# ---- Resilience-outcome variable set (Lee & Chen sensitivity) -------------------------
resil_vars <- c("exp_gap_sr", "exp_gap_lr", "sensitivity_sr", "sensitivity_lr")
var_labels <- c(exp_gap_sr = "Short-run expenditure gap",
                exp_gap_lr = "Long-run expenditure gap",
                sensitivity_sr = "Short-run sensitivity (DV)",
                sensitivity_lr = "Long-run sensitivity (DV)")
nice <- function(v) factor(v, levels = resil_vars, labels = var_labels[resil_vars])

# ---- Output helpers -------------------------------------------------------------------
save_table <- function(df, gt_obj, name) {
  readr::write_csv(df, file.path(tab_dir, paste0(name, ".csv")))
  try(gt::gtsave(gt_obj, file.path(tab_dir, paste0(name, ".html"))), silent = TRUE)
}
save_fig <- function(plot, name, w = 9, h = 6) {
  ggsave(file.path(fig_dir, paste0(name, ".png")), plot, width = w, height = h, dpi = 150)
  try(ggsave(file.path(fig_dir, paste0(name, ".pdf")), plot, width = w, height = h), silent = TRUE)
}

# ======================================================================================
# 01 — DEFINITIONS
# ======================================================================================
definitions <- tibble::tribble(
  ~variable,         ~label,                        ~role,               ~direction,            ~definition,
  "exp_gap_sr",      "Short-run expenditure gap",   "resilience (input)", "lower = resilient",  "Absolute year-over-year volatility of General Fund current-operating expenditure: |E_t - E_{t-1}| / E_{t-1}.",
  "exp_gap_lr",      "Long-run expenditure gap",    "resilience (input)", "lower = resilient",  "Absolute deviation of GF operating expenditure from the unit's own log-linear trend: |E - E_hat| / E_hat.",
  "sensitivity_sr",  "Short-run sensitivity",       "resilience (DV)",    "lower = resilient",  "Lee & Chen resilience DV: exp_gap_sr divided by its peer-group (size_class x year) mean. ~1 = typical; <1 more resilient.",
  "sensitivity_lr",  "Long-run sensitivity",        "resilience (DV)",    "lower = resilient",  "Lee & Chen resilience DV: exp_gap_lr divided by its peer-group (size_class x year) mean."
)
def_gt <- definitions %>% gt::gt() %>%
  gt::tab_header("01. Resilience-outcome variables — definitions",
                 "Expenditure-side stability (Lee & Chen sensitivity). Predictors (fund balance) and stressors (revenue volatility) are described separately.")
save_table(definitions, def_gt, "01_definitions")

# ======================================================================================
# 02 — CONSTRUCTION
# ======================================================================================
construction <- tibble::tribble(
  ~variable,        ~formula,                                  ~source_rows,
  "exp_gap_sr",     "|E_t - E_{t-1}| / E_{t-1} (consecutive yrs)", "GF (fund A) operating expenditure E = sum of objects {personal services, contractual, employee benefits}",
  "exp_gap_lr",     "|E - E_hat| / E_hat ; E_hat = exp(fit of log(E) ~ year), >= 8 yrs", "same GF operating base, per-unit log-linear trend",
  "sensitivity_sr", "exp_gap_sr / mean(exp_gap_sr in size_class x year), cells >= 5 units", "peer reference = size_class x year (adaptation of Lee & Chen's national-average-per-year)",
  "sensitivity_lr", "exp_gap_lr / mean(exp_gap_lr in size_class x year)", "same peer reference"
)
scale_note <- res %>%
  dplyr::summarise(median_gf_operating_exp_M = stats::median(gf_operating_exp, na.rm = TRUE) / 1e6)
con_gt <- construction %>% gt::gt() %>%
  gt::tab_header("02. Construction",
                 paste0("General Fund, cities 1995-2023, NYC excluded by data. Scale: median GF operating expenditure ~ $",
                        round(scale_note$median_gf_operating_exp_M, 1), "M."))
save_table(construction, con_gt, "02_construction")

# ======================================================================================
# 03 — DESCRIPTIVE STATS + DISTRIBUTION
# ======================================================================================
s3 <- describe_vars(res, resil_vars)
s3_gt <- gt_summary_table(
  s3, "03. Resilience-outcome variables — summary (cities, 1995-2023)",
  "Sensitivities average ~1 by construction; read their spread (SD, quartiles, max), not the mean.")
save_table(s3, s3_gt, "03_summary_stats")

f3_df <- res %>% dplyr::select(dplyr::all_of(resil_vars)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(), winsorize)) %>%
  tidyr::pivot_longer(dplyr::everything(), names_to = "variable", values_to = "value") %>%
  dplyr::mutate(variable = nice(variable))
f3 <- ggplot(f3_df, aes(value)) + geom_histogram(bins = 40) +
  facet_wrap(~ variable, scales = "free") +
  labs(title = "03. Distributions (winsorized 1/99)", x = NULL, y = "Count") + theme_minimal()
save_fig(f3, "03_distributions")

# ======================================================================================
# 04 — TIME SERIES
# ======================================================================================
f4_df <- res %>% dplyr::group_by(calendar_year) %>%
  dplyr::summarise(dplyr::across(dplyr::all_of(resil_vars), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
  tidyr::pivot_longer(dplyr::all_of(resil_vars), names_to = "variable", values_to = "mean") %>%
  dplyr::mutate(variable = nice(variable))
f4 <- ggplot(f4_df, aes(calendar_year, mean)) +
  geom_vline(xintercept = c(2009, 2020), linetype = "dashed", colour = "grey60") +
  geom_line() + geom_point(size = 0.8) +
  facet_wrap(~ variable, scales = "free_y") +
  labs(title = "04. Mean resilience-outcome variable by year (cities)",
       subtitle = "Dashed: 2009, 2020 shocks. Operating spending is sticky (gaps stay low).",
       x = NULL, y = "Annual mean") + theme_minimal()
save_fig(f4, "04_time_series")

# ======================================================================================
# 05 — CORRELATION (panel-aware: pooled / between / within)
# ======================================================================================
cor_s <- correlation_sets(res, resil_vars, method = "spearman")
for (nm in names(cor_s))
  readr::write_csv(tibble::as_tibble(round(cor_s[[nm]], 3), rownames = "variable"),
                   file.path(tab_dir, paste0("05_correlation_", nm, ".csv")))
c5_gt <- tibble::as_tibble(cor_s$pooled, rownames = "variable") %>% gt::gt() %>%
  gt::tab_header("05. Spearman correlations (pooled)",
                 "Between/within variants in 05_correlation_{between,within}.csv. gap<->sensitivity is mechanical; sr<->lr is the substantive pair.") %>%
  gt::fmt_number(columns = -variable, decimals = 2)
save_table(tibble::as_tibble(round(cor_s$pooled, 3), rownames = "variable"), c5_gt, "05_correlation_pooled")

f5_df <- as.data.frame(as.table(cor_s$pooled)); names(f5_df) <- c("v1", "v2", "rho")
f5 <- ggplot(f5_df, aes(v1, v2, fill = rho)) + geom_tile() +
  geom_text(aes(label = sprintf("%.2f", rho)), size = 3) +
  scale_fill_gradient2(limits = c(-1, 1), low = "#b2182b", mid = "white", high = "#2166ac") +
  labs(title = "05. Spearman correlations (pooled)", x = NULL, y = NULL) +
  theme_minimal() + theme(axis.text.x = element_text(angle = 30, hjust = 1))
save_fig(f5, "05_correlation_heatmap", w = 7, h = 6)

# ======================================================================================
# 06 — DISTRIBUTION BY SIZE QUINTILE
# ======================================================================================
s6 <- describe_vars(res %>% dplyr::filter(!is.na(size_class)), resil_vars, by = "size_class")
s6_gt <- gt_summary_table(s6, "06. Resilience-outcome variables by size quintile (1 = smallest)")
save_table(s6, s6_gt, "06_by_size_quintile")

f6_df <- res %>% dplyr::filter(!is.na(size_class)) %>%
  dplyr::select(size_class, dplyr::all_of(resil_vars)) %>%
  dplyr::mutate(dplyr::across(dplyr::all_of(resil_vars), winsorize)) %>%
  tidyr::pivot_longer(dplyr::all_of(resil_vars), names_to = "variable", values_to = "value") %>%
  dplyr::mutate(variable = nice(variable))
f6 <- ggplot(f6_df, aes(factor(size_class), value)) + geom_boxplot(outlier.size = 0.5) +
  facet_wrap(~ variable, scales = "free_y") +
  labs(title = "06. Resilience-outcome variables by size quintile (winsorized)",
       x = "Size class (1 = smallest)", y = NULL) + theme_minimal()
save_fig(f6, "06_by_size_quintile")

message("60_descriptives.R complete -> ", out_root)

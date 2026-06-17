# 60_descriptives.R
# Descriptive statistics for the resilience dependent variables (cities, 1995-2023).
# Spec: plan_docs/02_descriptive_statistics_plan.md   Helpers: code/functions/descriptives.R
#
# Reads:  data/processed_data/city_resilience.rds  (run 40_construct_resilience.R first)
# Writes: outputs/descriptives/{tables,figures}/   (gt .html + .csv tables; .png/.pdf figures)
#
# Headline window 1995-2023 (FY2024 partial, FY2025 dropped). Cities only this pass.
# Figures winsorized at 1/99; tables and stored DVs raw. Correlation default = Spearman.

suppressMessages({library(ggplot2)})

# I/O hooks (overridable by a test harness; default to the real project paths).
in_path  <- if (exists(".desc_in_path"))  get(".desc_in_path")  else here::here("data", "processed_data", "city_resilience.rds")
out_root <- if (exists(".desc_out_root")) get(".desc_out_root") else here::here("outputs", "descriptives")
tab_dir  <- file.path(out_root, "tables")
fig_dir  <- file.path(out_root, "figures")
for (d in c(tab_dir, fig_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# ---- Load & restrict sample -----------------------------------------------------------
res <- readr::read_rds(in_path) %>%
  dplyr::filter(calendar_year >= 1995, calendar_year <= 2023) %>%   # headline window
  dplyr::mutate(decade = paste0(floor(calendar_year / 10) * 10, "s"))

# ---- Variable groups ------------------------------------------------------------------
ratios   <- c("fb_ratio", "available_fb_ratio")
exp_abs  <- c("exp_gap_sr", "exp_gap_lr")
exp_rel  <- c("sensitivity_sr", "sensitivity_lr")
rev_abs  <- c("rev_total_gap_sr", "rev_total_gap_lr", "rev_own_gap_sr",
              "rev_own_gap_lr", "rev_tax_gap_sr", "rev_tax_gap_lr")
rev_rel  <- c("rev_total_sens_sr", "rev_total_sens_lr", "rev_own_sens_sr",
              "rev_own_sens_lr", "rev_tax_sens_sr", "rev_tax_sens_lr")
bases    <- c("gf_total_exp", "gf_operating_exp", "rev_total", "rev_own", "rev_tax")

dv_all    <- c(ratios, exp_abs, exp_rel, rev_abs, rev_rel)
corr_vars <- c(ratios, exp_abs, rev_abs)                 # exclude mechanical sensitivities
rep_vars  <- c("fb_ratio", "exp_gap_sr", "rev_total_gap_sr", "rev_own_gap_sr")  # for figures

# Sign-alignment for PCA: buffers +1 (higher = resilient), gaps -1 (lower = resilient).
pca_sign <- stats::setNames(ifelse(corr_vars %in% ratios, 1, -1), corr_vars)

# ---- Output helpers -------------------------------------------------------------------
save_table <- function(summary_df, gt_obj, name) {
  readr::write_csv(summary_df, file.path(tab_dir, paste0(name, ".csv")))
  try(gt::gtsave(gt_obj, file.path(tab_dir, paste0(name, ".html"))), silent = TRUE)
}
save_fig <- function(plot, name, w = 9, h = 6) {
  ggsave(file.path(fig_dir, paste0(name, ".png")), plot, width = w, height = h, dpi = 150)
  try(ggsave(file.path(fig_dir, paste0(name, ".pdf")), plot, width = w, height = h), silent = TRUE)
}

# ======================================================================================
# TABLES
# ======================================================================================

# T1 — headline DV summary (ratios, gaps, sensitivities).
t1 <- describe_vars(res, dv_all)
save_table(t1, gt_summary_table(
  t1, "T1. Resilience DVs — summary (cities, 1995-2023)",
  "Mean/SD lead; median + quartiles for skew. Note: *_sens_* average ~1 by construction."),
  "T1_headline_summary")

# T1b — dollar bases (in $ millions).
res_m <- res %>% dplyr::mutate(dplyr::across(dplyr::all_of(bases), ~ .x / 1e6))
t1b <- describe_vars(res_m, bases)
save_table(t1b, gt_summary_table(t1b, "T1b. General Fund $ bases ($ millions)", decimals = 1),
           "T1b_dollar_bases")

# T2 — key DVs by decade.
t2 <- describe_vars(res, rep_vars, by = "decade")
save_table(t2, gt_summary_table(t2, "T2. Key resilience DVs by decade"), "T2_by_decade")

# T3 — fund-balance detail + deficit share, overall and by decade.
t3 <- res %>%
  dplyr::group_by(decade) %>%
  dplyr::summarise(
    n              = sum(!is.na(fb_ratio)),
    mean_fb_ratio  = mean(fb_ratio, na.rm = TRUE),
    median_fb_ratio= stats::median(fb_ratio, na.rm = TRUE),
    deficit_share  = deficit_share(fb_ratio),
    mean_available = mean(available_fb_ratio, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  dplyr::bind_rows(dplyr::tibble(
    decade = "ALL", n = sum(!is.na(res$fb_ratio)),
    mean_fb_ratio = mean(res$fb_ratio, na.rm = TRUE),
    median_fb_ratio = stats::median(res$fb_ratio, na.rm = TRUE),
    deficit_share = deficit_share(res$fb_ratio),
    mean_available = mean(res$available_fb_ratio, na.rm = TRUE)))
t3_gt <- t3 %>% gt::gt() %>% gt::tab_header("T3. Fund-balance buffer & deficit share, by decade") %>%
  gt::fmt_number(c(mean_fb_ratio, median_fb_ratio, mean_available), decimals = 3) %>%
  gt::fmt_percent(deficit_share, decimals = 1) %>% gt::fmt_number(n, decimals = 0)
save_table(t3, t3_gt, "T3_fund_balance_detail")

# T4 — volatility comparison: absolute gaps, operating vs revenue bases (short-run).
t4 <- describe_vars(res, c("exp_gap_sr", "rev_total_gap_sr", "rev_own_gap_sr", "rev_tax_gap_sr"))
save_table(t4, gt_summary_table(
  t4, "T4. Volatility comparison (short-run absolute gaps): operating vs revenue"),
  "T4_volatility_comparison")

# T6 — correlations (pooled / between / within), Spearman + Pearson (pooled appendix).
cor_s <- correlation_sets(res, corr_vars, method = "spearman")
cor_p <- correlation_sets(res, corr_vars, method = "pearson")
for (nm in names(cor_s))
  readr::write_csv(tibble::as_tibble(round(cor_s[[nm]], 3), rownames = "variable"),
                   file.path(tab_dir, paste0("T6_spearman_", nm, ".csv")))
readr::write_csv(tibble::as_tibble(round(cor_p$pooled, 3), rownames = "variable"),
                 file.path(tab_dir, "T6_pearson_pooled.csv"))
t6_gt <- tibble::as_tibble(cor_s$pooled, rownames = "variable") %>% gt::gt() %>%
  gt::tab_header("T6. Spearman correlations (pooled)",
                 "Between/within variants in T6_spearman_{between,within}.csv") %>%
  gt::fmt_number(columns = -variable, decimals = 2)
save_table(tibble::as_tibble(round(cor_s$pooled, 3), rownames = "variable"), t6_gt, "T6_spearman_pooled")

# T7 — PCA loadings + variance explained (sign-aligned, normal-scored, sensitivities excluded).
pca <- resilience_pca(res, corr_vars, sign = pca_sign)
load_tbl <- pca_loadings(pca, n_comp = 4)
var_tbl  <- pca_variance(pca)
readr::write_csv(var_tbl, file.path(tab_dir, "T7_pca_variance.csv"))
t7_gt <- load_tbl %>% gt::gt() %>%
  gt::tab_header("T7. PCA loadings (first 4 PCs)",
                 paste0("N = ", pca$n, " entity-years; sign-aligned so higher = more resilient")) %>%
  gt::fmt_number(columns = -variable, decimals = 3)
save_table(load_tbl, t7_gt, "T7_pca_loadings")

# ======================================================================================
# FIGURES (winsorized display where noted)
# ======================================================================================
nice <- function(v) factor(v, levels = rep_vars)

# F1 — time series of mean DV by year, shocks marked.
f1_df <- res %>% dplyr::group_by(calendar_year) %>%
  dplyr::summarise(dplyr::across(dplyr::all_of(rep_vars), ~ mean(.x, na.rm = TRUE)), .groups = "drop") %>%
  tidyr::pivot_longer(dplyr::all_of(rep_vars), names_to = "variable", values_to = "mean") %>%
  dplyr::mutate(variable = nice(variable))
f1 <- ggplot(f1_df, aes(calendar_year, mean)) +
  geom_vline(xintercept = c(2009, 2020), linetype = "dashed", colour = "grey60") +
  geom_line() + geom_point(size = 0.8) +
  facet_wrap(~ variable, scales = "free_y") +
  labs(title = "F1. Mean resilience DV by year (cities)", subtitle = "Dashed: 2009, 2020 shocks",
       x = NULL, y = "Annual mean") + theme_minimal()
save_fig(f1, "F1_time_series")

# F2 — winsorized distributions.
f2_df <- res %>% dplyr::select(dplyr::all_of(rep_vars)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(), winsorize)) %>%
  tidyr::pivot_longer(dplyr::everything(), names_to = "variable", values_to = "value") %>%
  dplyr::mutate(variable = nice(variable))
f2 <- ggplot(f2_df, aes(value)) + geom_histogram(bins = 40) +
  facet_wrap(~ variable, scales = "free") +
  labs(title = "F2. DV distributions (winsorized 1/99)", x = NULL, y = "Count") + theme_minimal()
save_fig(f2, "F2_distributions")

# F3 — winsorized boxplots by size class.
f3_df <- res %>% dplyr::filter(!is.na(size_class)) %>%
  dplyr::select(size_class, dplyr::all_of(rep_vars)) %>%
  dplyr::mutate(dplyr::across(dplyr::all_of(rep_vars), winsorize)) %>%
  tidyr::pivot_longer(dplyr::all_of(rep_vars), names_to = "variable", values_to = "value") %>%
  dplyr::mutate(variable = nice(variable))
f3 <- ggplot(f3_df, aes(factor(size_class), value)) + geom_boxplot(outlier.size = 0.5) +
  facet_wrap(~ variable, scales = "free_y") +
  labs(title = "F3. DVs by size class (winsorized)", x = "Size class (1 = smallest)", y = NULL) +
  theme_minimal()
save_fig(f3, "F3_by_size_class")

# F5 — Spearman correlation heatmap.
f5_df <- as.data.frame(as.table(cor_s$pooled))
names(f5_df) <- c("v1", "v2", "rho")
f5 <- ggplot(f5_df, aes(v1, v2, fill = rho)) + geom_tile() +
  geom_text(aes(label = sprintf("%.2f", rho)), size = 2) +
  scale_fill_gradient2(limits = c(-1, 1), low = "#b2182b", mid = "white", high = "#2166ac") +
  labs(title = "F5. Spearman correlations (pooled)", x = NULL, y = NULL) +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
save_fig(f5, "F5_correlation_heatmap", w = 9, h = 8)

# F6 — scatterplot matrix (base graphics, winsorized).
pairs_vars <- c("fb_ratio", "exp_gap_sr", "rev_total_gap_sr", "rev_own_gap_sr", "rev_tax_gap_sr")
pm <- as.data.frame(lapply(res[pairs_vars], winsorize))
grDevices::png(file.path(fig_dir, "F6_scatter_matrix.png"), width = 1100, height = 1100, res = 130)
graphics::pairs(pm, pch = 20, cex = 0.4, col = grDevices::adjustcolor("black", 0.3),
                main = "F6. Scatterplot matrix (winsorized)")
grDevices::dev.off()

# F7 — variable dendrogram (1 - |Spearman rho|).
hc <- stats::hclust(stats::as.dist(1 - abs(cor_s$pooled)))
grDevices::png(file.path(fig_dir, "F7_variable_dendrogram.png"), width = 1000, height = 700, res = 130)
graphics::plot(hc, main = "F7. Variable clustering (1 - |Spearman|)", xlab = "", sub = "")
grDevices::dev.off()

message("60_descriptives.R complete -> ", out_root)

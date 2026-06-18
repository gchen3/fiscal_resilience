# 65_recovery_descriptives.R
# Descriptive statistics for the DV3 SHOCK-RECOVERY variables (cities; shocks 2009 & 2020).
# Spec: plan_docs/03_recovery_variable_plan.md   Helpers: code/functions/descriptives.R
#
# Grain: entity x shock x series (an event study, NOT entity-year). Targets:
#   available_fb_ratio (reserves; LEVEL / ratio-point drawdown), rev_own + gf_operating_exp
#   (dollar flows; PROPORTIONAL drawdown on CPI-U-deflated real $). Built in
#   40_construct_resilience.R via build_entity_recovery().
#
# Reads:  data/processed_data/city_recovery.rds   (run 40_construct_resilience.R first)
# Writes: outputs/recovery_descriptives/{tables,figures}/  (01-06 sections; gt .html + .csv; .png/.pdf)

suppressMessages({library(ggplot2)})

# I/O hooks (overridable by a test harness; default to the real project paths).
in_path  <- if (exists(".recov_in_path"))  get(".recov_in_path")  else here::here("data", "processed_data", "city_recovery.rds")
out_root <- if (exists(".recov_out_root")) get(".recov_out_root") else here::here("outputs", "recovery_descriptives")
tab_dir  <- file.path(out_root, "tables")
fig_dir  <- file.path(out_root, "figures")

if (dir.exists(out_root)) unlink(out_root, recursive = TRUE)
for (d in c(tab_dir, fig_dir)) dir.create(d, recursive = TRUE)

# ---- Load -----------------------------------------------------------------------------
rec <- readr::read_rds(in_path) %>%
  dplyr::mutate(shock = as.integer(shock),
                series = factor(series, levels = c("available_fb_ratio", "rev_own", "gf_operating_exp")))

series_lab <- c(available_fb_ratio = "Reserves (avail. FB / exp.)",
                rev_own = "Own-source revenue", gf_operating_exp = "Operating expenditure")
nice_series <- function(s) factor(series_lab[as.character(s)], levels = unname(series_lab))
metrics <- c("drawdown", "recovery_years", "recovery_ratio")

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
  ~variable,        ~label,                  ~role,                ~direction,            ~definition,
  "drawdown",       "Drawdown depth",        "resilience (DV)",    "lower = resilient",   "Worst shortfall of the target below its pre-shock baseline B over [t0, t0+6]. Reserves: LEVEL drop in ratio points, max(0, B - minY). Dollar flows: PROPORTIONAL, max(0, (B - minY)/B).",
  "recovery_years", "Recovery time",         "resilience (DV)",    "lower = resilient",   "First k>=0 with Y_{t0+k} >= B (years to climb back to baseline). NA if not recovered within the window.",
  "recovered",      "Recovered within window","resilience (flag)", "TRUE = resilient",    "TRUE if the target returned to its pre-shock baseline within [t0, t0+6].",
  "censored",       "Right-censored",        "data quality",       "n/a",                 "TRUE if not recovered AND the window extends past the last observed year (recovery time unknown, esp. COVID).",
  "recovery_ratio", "Recovery at horizon",   "resilience (DV)",    "higher = resilient",  "Level at t0+4 vs baseline. Dollar flows: Y_h / B (1 = fully recovered). Reserves: Y_h - B (signed ratio-point gap; 0 = recovered)."
)
def_gt <- definitions %>% gt::gt() %>%
  gt::tab_header("01. Shock-recovery (DV3) variables — definitions",
                 "Entity x shock event study. Reserves use a level (ratio-point) scale; dollar flows use a proportional scale.")
save_table(definitions, def_gt, "01_definitions")

# ======================================================================================
# 02 — CONSTRUCTION
# ======================================================================================
construction <- tibble::tribble(
  ~series,              ~scale,         ~baseline,                              ~deflation,
  "available_fb_ratio", "ratio_points", "mean available_fb_ratio over [t0-3, t0-1]", "none (already a ratio / real)",
  "rev_own",            "proportional", "mean real own-source revenue over [t0-3, t0-1]", "CPI-U annual avg (base 2023)",
  "gf_operating_exp",   "proportional", "mean real GF operating expenditure over [t0-3, t0-1]", "CPI-U annual avg (base 2023)"
)
con_gt <- construction %>% gt::gt() %>%
  gt::tab_header("02. Construction",
                 "Shocks t0 = 2009 (GFC), 2020 (COVID). Window 6 yrs; horizon 4 yrs. CPI-U source: transparency/reference_sources.md.")
save_table(construction, con_gt, "02_construction")

# ======================================================================================
# 03 — DESCRIPTIVE STATS + DISTRIBUTION
# ======================================================================================
s3 <- describe_vars(rec, metrics, by = c("series", "shock"))
s3_gt <- gt_summary_table(s3, "03. Recovery metrics — summary (cities)",
  "Drawdown scale differs by series (reserves = ratio points; flows = proportional). recovery_years summarized over recovered cases only.")
save_table(s3, s3_gt, "03_summary_stats")

# recovery-status shares per series x shock
status <- rec %>% dplyr::group_by(series, shock) %>%
  dplyr::summarise(n = dplyr::n(),
                   na_baseline    = mean(is.na(baseline)),
                   recovered_pct  = mean(recovered, na.rm = TRUE),
                   censored_pct   = mean(censored, na.rm = TRUE),
                   notrecovered_pct = mean(!recovered & !censored, na.rm = TRUE),
                   .groups = "drop")
status_gt <- status %>% gt::gt() %>%
  gt::tab_header("03b. Recovery status shares (per series x shock)",
                 "Censored = window ran past the last observed year (COVID is heavily censored).") %>%
  gt::fmt_percent(columns = c(na_baseline, recovered_pct, censored_pct, notrecovered_pct), decimals = 1)
save_table(status, status_gt, "03_recovery_status")

f3_df <- rec %>% dplyr::group_by(series) %>%
  dplyr::mutate(drawdown_w = winsorize(drawdown)) %>% dplyr::ungroup() %>%
  dplyr::mutate(series = nice_series(series), shock = factor(shock))
f3 <- ggplot(f3_df, aes(drawdown_w, fill = shock)) +
  geom_histogram(bins = 30, position = "identity", alpha = 0.6) +
  facet_wrap(~ series, scales = "free") +
  labs(title = "03. Drawdown-depth distributions (winsorized 1/99 within series)",
       subtitle = "Reserves in ratio points; revenue/expenditure proportional",
       x = "Drawdown depth", y = "Count", fill = "Shock") + theme_minimal()
save_fig(f3, "03_drawdown_distributions")

# ======================================================================================
# 04 — BY SHOCK (2009 GFC vs 2020 COVID)
# ======================================================================================
f4_df <- rec %>% dplyr::group_by(series, shock) %>%
  dplyr::summarise(mean_drawdown = mean(drawdown, na.rm = TRUE),
                   recovered_pct = mean(recovered, na.rm = TRUE), .groups = "drop") %>%
  dplyr::mutate(series = nice_series(series), shock = factor(shock))
f4 <- ggplot(f4_df, aes(series, mean_drawdown, fill = shock)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.0f%% rec.", 100 * recovered_pct)),
            position = position_dodge(width = 0.8), vjust = -0.4, size = 3) +
  labs(title = "04. Mean drawdown depth by series and shock",
       subtitle = "Labels = share recovered within the window. Operating spending barely dips.",
       x = NULL, y = "Mean drawdown depth", fill = "Shock") + theme_minimal()
save_fig(f4, "04_by_shock", w = 9, h = 5.5)
readr::write_csv(f4_df %>% dplyr::mutate(series = as.character(series)), file.path(tab_dir, "04_by_shock.csv"))

# ======================================================================================
# 05 — DEPTH vs SPEED (do deeper shocks recover slower?)
# ======================================================================================
f5_df <- rec %>% dplyr::filter(recovered) %>%
  dplyr::mutate(series = nice_series(series), shock = factor(shock))
f5 <- ggplot(f5_df, aes(drawdown, recovery_years, colour = shock)) +
  geom_jitter(width = 0, height = 0.15, alpha = 0.7, size = 1.6) +
  facet_wrap(~ series, scales = "free_x") +
  labs(title = "05. Depth vs speed (recovered cases only)",
       subtitle = "Recovery time vs drawdown depth; do deeper drawdowns take longer to rebuild?",
       x = "Drawdown depth", y = "Years to recover", colour = "Shock") + theme_minimal()
save_fig(f5, "05_depth_vs_speed")

# Spearman depth<->speed among recovered, per series.
ds <- rec %>% dplyr::filter(recovered) %>% dplyr::group_by(series) %>%
  dplyr::summarise(n = dplyr::n(),
                   rho_depth_speed = suppressWarnings(stats::cor(drawdown, recovery_years,
                                       method = "spearman", use = "complete.obs")),
                   .groups = "drop")
ds_gt <- ds %>% gt::gt() %>%
  gt::tab_header("05. Depth vs speed — Spearman correlation (recovered cases)") %>%
  gt::fmt_number(columns = "rho_depth_speed", decimals = 2)
save_table(ds, ds_gt, "05_depth_vs_speed")

# ======================================================================================
# 06 — BY SIZE QUINTILE
# ======================================================================================
s6 <- describe_vars(rec %>% dplyr::filter(!is.na(size_class)), "drawdown",
                    by = c("series", "size_class"))
s6_gt <- gt_summary_table(s6, "06. Drawdown depth by size quintile (1 = smallest)",
  "Within-entity-type quintile of time-averaged operating expenditure.")
save_table(s6, s6_gt, "06_by_size_quintile")

f6_df <- rec %>% dplyr::filter(!is.na(size_class)) %>%
  dplyr::group_by(series) %>% dplyr::mutate(drawdown_w = winsorize(drawdown)) %>% dplyr::ungroup() %>%
  dplyr::mutate(series = nice_series(series))
f6 <- ggplot(f6_df, aes(factor(size_class), drawdown_w)) +
  geom_boxplot(outlier.size = 0.5) +
  facet_wrap(~ series, scales = "free_y") +
  labs(title = "06. Drawdown depth by size quintile (winsorized within series)",
       x = "Size class (1 = smallest)", y = "Drawdown depth") + theme_minimal()
save_fig(f6, "06_by_size_quintile")

message("65_recovery_descriptives.R complete -> ", out_root)

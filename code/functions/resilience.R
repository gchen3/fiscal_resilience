# functions/resilience.R
# Pure functions to construct the fiscal-resilience dependent variables.
# See plan_docs/01_fiscal_resilience_dv_plan.md for the full specification.
# Definitions only — no side effects, no I/O. Sourced by 00_library.R.
# Built: DV1 (fund-balance buffer), DV2 (operating expenditure-gap sensitivity),
# DV4 (revenue-side gap sensitivity: total / own-source / tax).
# Planned (stub below): DV3 (shock recovery trajectory).

# Object classes that make up CURRENT OPERATING expenditure (DV2 base): excludes
# equipment & capital outlay, debt principal/interest, and interfund transfers.
operating_objects_default <- c("personal services", "contractual", "employee benefits")

# Old-era balance-sheet equity segments that are FUND-BALANCE components (exclude
# "equity in fixed assets", "equity - contributions", "trust equity", and the
# change-in-equity flow rows by requiring financial_statement == "balance sheet").
fb_equity_segments <- c(
  "equity - reserved", "equity - unreserved", "equity - restricted",
  "equity - assigned", "equity - unassigned", "equity - nonspendable",
  "equity - committed"
)

# ---- Normalization --------------------------------------------------------------------
# Raw *_data_all.rds keeps original-case values and a character `amount`. Lowercase the
# classification fields, parse `amount`, derive the fund letter, and replace NA strings
# with "" so equality tests never return NA. Harmonizes the two schema eras
# (financial_statement[_segment] pre-2013; account_code_section 2013+).
normalize_resilience_input <- function(raw) {
  col <- function(nm) if (nm %in% names(raw)) raw[[nm]] else rep(NA_character_, nrow(raw))
  lc <- function(x) {
    x <- tolower(as.character(x))
    x[is.na(x)] <- ""
    x
  }
  tibble::tibble(
    calendar_year  = as.integer(raw$calendar_year),
    entity_name    = lc(raw$entity_name),
    municipal_code = as.character(raw$municipal_code),
    fund           = toupper(ifelse(is.na(col("account_code_letter")), "",
                                    as.character(col("account_code_letter")))),
    amount         = suppressWarnings(as.numeric(gsub("'", "", as.character(raw$amount)))),
    object         = lc(col("object_of_expenditure")),
    narrative      = lc(col("account_code_narrative")),
    fin_stmt       = lc(col("financial_statement")),
    fin_seg        = lc(col("financial_statement_segment")),
    acct_section   = lc(col("account_code_section")),
    level_1        = lc(col("level_1_category"))
  )
}

# DV4 revenue classification (by level_1_category — segment is inconsistent across eras
# for financing rows). Defined by EXCLUSION so it is robust to category-string variants.
rev_financing_cats <- c("proceeds of debt", "other sources")          # exclude from all revenue
rev_intergov_cats  <- c("state aid", "federal aid", "charges to other governments")
rev_tax_cats       <- c("real property taxes and assessments", "sales and use tax")

# Unified segment helpers across eras.
.is_expenditure <- function(n) n$fin_seg %in% c("expenditure", "expenditures") |
  n$acct_section %in% c("expenditure", "expenditures")
.is_revenue <- function(n) n$fin_seg %in% c("revenue", "revenues") |
  n$acct_section %in% c("revenue", "revenues")

# ---- DV1: General Fund balance --------------------------------------------------------
# Returns entity-year: total_fund_balance, available_fb (broad), unassigned_fb (narrow).
# Era-aware extraction + per-entity-year adaptive available-balance rule (plan §6).
extract_general_fund_balance <- function(norm, fund = "A") {
  g <- norm[norm$fund == fund, , drop = FALSE]

  is_total <- (g$acct_section == "fbnp" & g$narrative == "fund balance - end of year") |
    (g$fin_stmt == "balance sheet" & g$fin_seg %in% fb_equity_segments)
  is_unreserved <- g$fin_seg == "equity - unreserved"
  is_unassigned <- g$fin_seg == "equity - unassigned" |
    (g$acct_section == "gl" & g$narrative == "unassigned fund balance")
  is_assigned <- g$fin_seg == "equity - assigned" |
    (g$acct_section == "gl" & g$narrative %in%
       c("assigned appropriated fund balance", "assigned unappropriated fund balance"))

  g$.total      <- ifelse(is_total, g$amount, 0)
  g$.unreserved <- ifelse(is_unreserved, g$amount, 0)
  g$.n_unres    <- as.integer(is_unreserved)
  g$.unassigned <- ifelse(is_unassigned, g$amount, 0)
  g$.assigned   <- ifelse(is_assigned, g$amount, 0)

  g %>%
    dplyr::group_by(calendar_year, entity_name, municipal_code) %>%
    dplyr::summarise(
      total_fund_balance = sum(.total, na.rm = TRUE),
      unreserved         = sum(.unreserved, na.rm = TRUE),
      n_unreserved       = sum(.n_unres, na.rm = TRUE),
      unassigned         = sum(.unassigned, na.rm = TRUE),
      assigned           = sum(.assigned, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      # Adaptive: pre-GASB-54 "unreserved" already ~ unassigned+assigned, so use it
      # where present (incl. mixed-adoption 2011); else use the new categories.
      unassigned_fb = dplyr::if_else(n_unreserved > 0, unreserved, unassigned),
      available_fb  = dplyr::if_else(n_unreserved > 0, unreserved, unassigned + assigned)
    ) %>%
    dplyr::select(calendar_year, entity_name, municipal_code,
                  total_fund_balance, available_fb, unassigned_fb)
}

# ---- DV2 base: General Fund expenditures ----------------------------------------------
# total = all expenditure-segment rows EXCEPT interfund transfers (consistent across eras);
# operating = personal services + contractual + employee benefits.
extract_gf_expenditure <- function(norm, fund = "A",
                                    operating_objects = operating_objects_default) {
  g <- norm[norm$fund == fund, , drop = FALSE]
  exp_core <- .is_expenditure(g) & g$object != "interfund transfer"

  g$.total <- ifelse(exp_core, g$amount, 0)
  g$.op    <- ifelse(exp_core & g$object %in% operating_objects, g$amount, 0)

  g %>%
    dplyr::group_by(calendar_year, entity_name, municipal_code) %>%
    dplyr::summarise(
      gf_total_exp     = sum(.total, na.rm = TRUE),
      gf_operating_exp = sum(.op, na.rm = TRUE),
      .groups = "drop"
    )
}

# ---- DV4 base: General Fund revenue ---------------------------------------------------
# rev_total = operating revenues (all revenue level_1 except financing: debt proceeds /
#   other sources); rev_own = own-source (also excludes intergovernmental aid + charges to
#   other governments); rev_tax = property + sales tax only. Restricted to revenue rows.
extract_gf_revenue <- function(norm, fund = "A") {
  g <- norm[norm$fund == fund, , drop = FALSE]
  is_rev <- .is_revenue(g)

  in_total <- is_rev & !(g$level_1 %in% rev_financing_cats)
  in_own   <- in_total & !(g$level_1 %in% rev_intergov_cats)
  in_tax   <- is_rev & (g$level_1 %in% rev_tax_cats)

  g$.tot <- ifelse(in_total, g$amount, 0)
  g$.own <- ifelse(in_own,   g$amount, 0)
  g$.tax <- ifelse(in_tax,   g$amount, 0)

  g %>%
    dplyr::group_by(calendar_year, entity_name, municipal_code) %>%
    dplyr::summarise(
      rev_total = sum(.tot, na.rm = TRUE),
      rev_own   = sum(.own, na.rm = TRUE),
      rev_tax   = sum(.tax, na.rm = TRUE),
      .groups = "drop"
    )
}

# ---- DV2: absolute expenditure gaps (per unit) ----------------------------------------
# Short-run: |E_t - E_{t-1}| / E_{t-1} on consecutive years only.
# Long-run:  |E - Ehat| / Ehat where Ehat = exp(fit of log(E) ~ year), per unit with
#            >= min_years positive observations (else NA).
compute_expenditure_gaps <- function(df, value_col,
                                     sr_col = "exp_gap_sr", lr_col = "exp_gap_lr",
                                     min_years = 8) {
  df %>%
    dplyr::arrange(entity_name, municipal_code, calendar_year) %>%
    dplyr::group_by(entity_name, municipal_code) %>%
    dplyr::group_modify(~ {
      d <- .x
      v <- d[[value_col]]
      lagv <- dplyr::lag(v)
      consecutive <- (d$calendar_year - dplyr::lag(d$calendar_year)) == 1
      d[[sr_col]] <- ifelse(!is.na(lagv) & consecutive & lagv > 0, abs(v - lagv) / lagv, NA_real_)

      d[[lr_col]] <- NA_real_
      ok <- is.finite(v) & v > 0
      if (sum(ok) >= min_years) {
        fit <- stats::lm(log(v[ok]) ~ d$calendar_year[ok])
        ehat <- exp(stats::coef(fit)[1] + stats::coef(fit)[2] * d$calendar_year)
        d[[lr_col]] <- ifelse(v > 0, abs(v - ehat) / ehat, NA_real_)
      }
      d
    }) %>%
    dplyr::ungroup()
}

# ---- DV2/DV4: relative sensitivity -----------------------------------------------------
# Size class (quintiles of time-averaged operating expenditure) is computed once via
# compute_size_class() below; for a (near-)balanced panel the common annual deflator
# cancels out of the ranking, so nominal averaging is used (real/per-capita deferred to
# the unbalanced-panel / Census-population extension).
# sensitivity = gap / mean(gap) within size_class x year; cells with < min_group units
# (non-NA gaps) are suppressed (NA).
add_relative_sensitivity <- function(df, gap_col, sens_col, min_group = 5) {
  df %>%
    dplyr::group_by(size_class, calendar_year) %>%
    dplyr::mutate(
      .n  = sum(!is.na(.data[[gap_col]])),
      .gm = dplyr::if_else(.n >= min_group, mean(.data[[gap_col]], na.rm = TRUE), NA_real_),
      !!sens_col := .data[[gap_col]] / .gm
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-.n, -.gm)
}

# Unit -> static size class map (quintiles of time-averaged `value_col`), shared by all DVs.
compute_size_class <- function(df, value_col, n_bins = 5) {
  df %>%
    dplyr::group_by(entity_name, municipal_code) %>%
    dplyr::summarise(.mean_size = mean(.data[[value_col]], na.rm = TRUE), .groups = "drop") %>%
    dplyr::mutate(size_class = dplyr::ntile(.mean_size, n_bins)) %>%
    dplyr::select(entity_name, municipal_code, size_class)
}

# Generic: add <prefix>_gap_sr/_gap_lr (absolute) and <prefix>_sens_sr/_sens_lr (relative,
# needs `size_class` already present) for one base column. Used for DV4 revenue bases.
add_gap_sensitivity <- function(df, value_col, prefix, min_years = 8, min_group = 5) {
  sr <- paste0(prefix, "_gap_sr"); lr <- paste0(prefix, "_gap_lr")
  df <- compute_expenditure_gaps(df, value_col, sr_col = sr, lr_col = lr, min_years = min_years)
  df <- add_relative_sensitivity(df, sr, paste0(prefix, "_sens_sr"), min_group = min_group)
  df <- add_relative_sensitivity(df, lr, paste0(prefix, "_sens_lr"), min_group = min_group)
  df
}

# ---- Top-level driver -----------------------------------------------------------------
# raw: one entity type's *_data_all.rds (raw, all years). Returns one entity-year table
# with DV1 ratios and DV2 absolute gaps + relative sensitivities.
build_resilience <- function(raw, entity_label = NA_character_, fund = "A",
                             operating_objects = operating_objects_default,
                             drop_years = 2025, min_years = 8, min_group = 5, n_bins = 5) {
  norm <- normalize_resilience_input(raw)
  if (length(drop_years)) norm <- norm[!(norm$calendar_year %in% drop_years), , drop = FALSE]

  fb  <- extract_general_fund_balance(norm, fund = fund)
  exp <- extract_gf_expenditure(norm, fund = fund, operating_objects = operating_objects)
  rev <- extract_gf_revenue(norm, fund = fund)

  # Shared static size class (quintiles of time-averaged GF operating expenditure).
  sc <- compute_size_class(exp, "gf_operating_exp", n_bins = n_bins)

  # DV2: absolute gaps + relative sensitivity on operating expenditure.
  exp <- compute_expenditure_gaps(exp, "gf_operating_exp", min_years = min_years)
  exp <- dplyr::left_join(exp, sc, by = c("entity_name", "municipal_code"))
  exp <- add_relative_sensitivity(exp, "exp_gap_sr", "sensitivity_sr", min_group = min_group)
  exp <- add_relative_sensitivity(exp, "exp_gap_lr", "sensitivity_lr", min_group = min_group)

  # DV4: same machinery on revenue bases (total / own-source / tax).
  rev <- dplyr::left_join(rev, sc, by = c("entity_name", "municipal_code"))
  for (b in c("rev_total", "rev_own", "rev_tax")) {
    rev <- add_gap_sensitivity(rev, b, b, min_years = min_years, min_group = min_group)
  }
  rev <- dplyr::select(rev, -size_class)   # avoid duplicate when joining to exp

  out <- exp %>%
    dplyr::full_join(rev, by = c("calendar_year", "entity_name", "municipal_code")) %>%
    dplyr::full_join(fb,  by = c("calendar_year", "entity_name", "municipal_code"))

  out %>%
    dplyr::mutate(
      entity_type = entity_label,
      fb_ratio            = dplyr::if_else(gf_total_exp > 0, total_fund_balance / gf_total_exp, NA_real_),
      available_fb_ratio  = dplyr::if_else(gf_total_exp > 0, available_fb / gf_total_exp, NA_real_)
    ) %>%
    dplyr::select(
      entity_type, calendar_year, entity_name, municipal_code, size_class,
      gf_total_exp, gf_operating_exp, rev_total, rev_own, rev_tax,
      total_fund_balance, available_fb, unassigned_fb,
      fb_ratio, available_fb_ratio,
      exp_gap_sr, exp_gap_lr, sensitivity_sr, sensitivity_lr,
      dplyr::starts_with("rev_total_"), dplyr::starts_with("rev_own_"), dplyr::starts_with("rev_tax_")
    ) %>%
    dplyr::arrange(entity_name, municipal_code, calendar_year)
}

# ---- DV3 (planned — see plan §8) ------------------------------------------------------
# build_recovery_trajectory(): drawdown depth + time-to-recovery around shock years
#   (2009, 2020). Needs fixed shock dates/windows and right-censoring handling.

# ==============================================================================
# 📊 05-4: Long-Short Portfolio Analysis
# ==============================================================================
#
# This script formally tests the performance of a zero-investment,
# long-short portfolio that goes long on the Upgrade (VW) portfolio and
# short on the Downgrade (VW) portfolio.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 05-4_long_short_analysis.R")


# --- 2. LOAD DATA & CREATE LONG-SHORT PORTFOLIO ---
# ==============================================================================
log_message("📂 Loading VW portfolio returns...")
upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))

log_message("� Loading Fama-French factors...")
ff_factors_clean <- readRDS(file.path(DATA_CLEAN, "factors_clean.rds"))

log_message("�🛠️ Creating Long-Short portfolio...")
long_short_returns <- full_join(
  upgrade_vw %>% select(date, port_ret_up = port_ret),
  downgrade_vw %>% select(date, port_ret_down = port_ret),
  by = "date"
) %>%
  mutate(port_ret = port_ret_up - port_ret_down) %>%
  left_join(ff_factors_clean, by = "date")

# --- 3. RUN REGRESSION ---
# ==============================================================================
log_message("⚙️ Running FF3 regression on Long-Short portfolio...")

ff3_formula <- "port_ret ~ mkt_rf + smb + hml"
model_long_short <- run_regression_model(long_short_returns, ff3_formula, se_type = "robust")

# --- 4. REPORT RESULTS ---
# ==============================================================================
log_message("📝 Generating Long-Short portfolio results...")

cat("\n--- Long-Short Portfolio (Upgrades - Downgrades) FF3 Results ---\n")
print(model_long_short)

alpha_ls <- model_long_short[1,1]
pval_ls <- model_long_short[1,4]

# Save results to table
results_output <- capture.output({
  cat("Long-Short Portfolio Analysis: Upgrades - Downgrades (Value-Weighted)\n")
  cat("============================================================\n\n")
  cat("Fama-French 3-Factor Model Results:\n")
  print(model_long_short)
  cat(sprintf("\n🎯 Key Finding: The Long-Short portfolio alpha is %.4f with a p-value of %.3f.\n", alpha_ls, pval_ls))
  cat("\nInterpretation:\n")
  if (pval_ls < 0.05) {
    cat("The alpha is statistically significant, indicating abnormal returns from the long-short strategy.\n")
  } else {
    cat("The alpha is not statistically significant, suggesting no abnormal returns from the long-short strategy.\n")
  }
})

writeLines(results_output, file.path(OUTPUT_TABLES, "supplementary", "table_long_short_analysis.txt"))

cat(sprintf("\n🎯 Key Finding: The Long-Short portfolio alpha is %.4f with a p-value of %.3f.\n", alpha_ls, pval_ls))

log_message("✅ Script 05-4 finished successfully.")
log_message("--------------------------------------------------")
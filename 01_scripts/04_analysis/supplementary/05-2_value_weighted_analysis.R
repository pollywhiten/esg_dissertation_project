# ==============================================================================
# 📊 05-2: Equal-Weighted vs. Value-Weighted Portfolio Analysis
# ==============================================================================
#
# This script formally compares the performance of equal-weighted (EW) versus
# value-weighted (VW) calendar-time portfolios. The goal is to determine if
# the observed effects of ESG rating changes are driven by smaller firms (more
# influential in EW portfolios) or larger firms (more influential in VW portfolios).
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
library(stargazer)

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 05-2_value_weighted_analysis.R")


# --- 2. LOAD ALL FOUR PORTFOLIO RETURN SERIES ---
# ==============================================================================
log_message("📂 Loading EW and VW portfolio return series...")

tryCatch({
  upgrade_ew <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_ew.rds"))
  upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
  downgrade_ew <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_ew.rds"))
  downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))
  log_message("✅ All four portfolio return series loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load portfolio files.", "ERROR"); stop(e)
})


# --- 3. RUN ALL REGRESSIONS ---
# ==============================================================================
log_message("⚙️ Running FF3 regressions on all four portfolios...")

# Define the regression formula
ff3_formula <- "port_ret ~ mkt_rf + smb + hml"

# Run the regressions using our robust function
model_up_ew <- run_regression_model(upgrade_ew, ff3_formula, se_type = "robust")
model_up_vw <- run_regression_model(upgrade_vw, ff3_formula, se_type = "robust")
model_down_ew <- run_regression_model(downgrade_ew, ff3_formula, se_type = "robust")
model_down_vw <- run_regression_model(downgrade_vw, ff3_formula, se_type = "robust")

log_message("✅ Regressions complete.")


# --- 4. CREATE COMPARISON TABLE ---
# ==============================================================================
log_message("📝 Generating comparison table using stargazer...")

# stargazer is perfect for presenting multiple models side-by-side
stargazer(
  model_up_ew, model_up_vw, model_down_ew, model_down_vw,
  type = "text",
  title = "Comparison of Equal-Weighted vs. Value-Weighted Portfolio Alphas (FF3 Model)",
  header = FALSE,
  
  # Custom labels for the models
  column.labels = c("Upgrade (EW)", "Upgrade (VW)", "Downgrade (EW)", "Downgrade (VW)"),
  
  # Specify coefficients and add a custom line for Monthly Alpha in Percent
  keep = c("mkt_rf", "smb", "hml"),
  add.lines = list(c(
    "Monthly Alpha (%)",
    sprintf("%.2f%s", model_up_ew[1,1]*100, if_else(model_up_ew[1,4] < 0.1, "*", "")),
    sprintf("%.2f%s", model_up_vw[1,1]*100, if_else(model_up_vw[1,4] < 0.1, "*", "")),
    sprintf("%.2f%s", model_down_ew[1,1]*100, if_else(model_down_ew[1,4] < 0.1, "*", "")),
    sprintf("%.2f%s", model_down_vw[1,1]*100, if_else(model_down_vw[1,4] < 0.1, "*", ""))
  )),
  
  # Provide the robust standard errors and p-values
  se = list(model_up_ew[,2], model_up_vw[,2], model_down_ew[,2], model_down_vw[,2]),
  p = list(model_up_ew[,4], model_up_vw[,4], model_down_ew[,4], model_down_vw[,4]),
  
  keep.stat = c("n", "rsq"),
  digits = 4,
  notes = "Robust (HC1) standard errors. * p<0.1",
  out = file.path(OUTPUT_TABLES, "supplementary", "table_ew_vs_vw_comparison.txt")
)

log_message("💾 Comparison table saved to 'output/tables/supplementary/'.")

# --- 5. INTERPRETATION & CONCLUSION ---
# ==============================================================================
cat("\n\n--- Analysis of EW vs. VW Results ---\n")
cat("========================================\n")

alpha_down_vw <- model_down_vw[1, 1]
pval_down_vw <- model_down_vw[1, 4]
alpha_down_ew <- model_down_ew[1, 1]
pval_down_ew <- model_down_ew[1, 4]

cat(sprintf("• The Downgrade (EW) portfolio has a monthly alpha of %.4f (p=%.3f).\n", alpha_down_ew, pval_down_ew))
cat(sprintf("• The Downgrade (VW) portfolio has a monthly alpha of %.4f (p=%.3f).\n", alpha_down_vw, pval_down_vw))

if (pval_down_vw < 0.1 && pval_down_ew >= 0.1) {
  cat("\n🎯 KEY INSIGHT: The negative abnormal return for downgrades is statistically significant ONLY in the value-weighted portfolio.\n")
  cat("   This strongly suggests the effect is driven by **larger companies**, whose performance has a greater impact on the value-weighted average.\n")
} else {
  cat("\n- The significance pattern between EW and VW portfolios is not as clear-cut.\n")
}

log_message("✅ Script 05-2 finished successfully.")
log_message("--------------------------------------------------")
# ==============================================================================
# 📈 03-5: Subsample Analysis (Post-2016) - CORRECTED
# ==============================================================================
#
# This script performs a robustness check by re-running the main value-weighted
# regressions on a subsample of the data starting from January 2017.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
library(stargazer)

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 03-5_subsample_analysis.R (Corrected Version)")


# --- 2. LOAD PORTFOLIO RETURN DATA ---
# ==============================================================================
log_message("📊 Loading value-weighted portfolio return series...")

upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))

log_message("✅ Value-weighted portfolio returns loaded.")


# --- 3. CREATE SUBSAMPLE DATA (CORRECTED) ---
# ==============================================================================
log_message(paste("🔪 Creating subsample for dates >=", SUBSAMPLE_START_DATE, "..."))

# Use dplyr::filter to correctly subset the data by date
upgrade_subsample <- upgrade_vw %>%
  filter(date >= as.Date(SUBSAMPLE_START_DATE))

downgrade_subsample <- downgrade_vw %>%
  filter(date >= as.Date(SUBSAMPLE_START_DATE))
  
cat(sprintf("  - Upgrade subsample: %d months\n", nrow(upgrade_subsample)))
cat(sprintf("  - Downgrade subsample: %d months\n", nrow(downgrade_subsample)))


# --- 4. RUN REGRESSIONS ON SUBSAMPLES ---
# ==============================================================================
log_message("⚙️ Running Fama-French 3-Factor regressions on subsamples...")

ff3_formula <- "port_ret ~ mkt_rf + smb + hml"

model_upgrade_sub <- run_regression_model(upgrade_subsample, ff3_formula, se_type = "robust")
model_downgrade_sub <- run_regression_model(downgrade_subsample, ff3_formula, se_type = "robust")

log_message("✅ Subsample regressions completed.")


# --- 5. REPORT RESULTS ---
# ==============================================================================
log_message("📝 Generating subsample regression output...")

# Print key results to console
alpha_sub_up <- model_upgrade_sub[1,1]
pval_sub_up <- model_upgrade_sub[1,4]
alpha_sub_down <- model_downgrade_sub[1,1]
pval_sub_down <- model_downgrade_sub[1,4]

cat("\n--- Subsample Analysis: Key Results (Corrected) ---\n")
cat(sprintf("• Upgrade (Post-2016): α = %.4f (p = %.3f)\n", alpha_sub_up, pval_sub_up))
cat(sprintf("• Downgrade (Post-2016): α = %.4f (p = %.3f)\n", alpha_sub_down, pval_sub_down))

log_message("✅ Script 03-5 finished successfully.")
log_message("--------------------------------------------------")
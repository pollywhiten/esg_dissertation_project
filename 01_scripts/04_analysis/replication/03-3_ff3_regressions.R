# ==============================================================================
# 📈 03-3: Fama-French 3-Factor Regressions on Portfolios
# ==============================================================================
#
# This script performs the main replication analysis. It loads the monthly
# portfolio return series and runs a Fama-French 3-factor regression
# on each to estimate the alpha (abnormal return).
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
library(stargazer) # For creating nice regression tables
library(dplyr)     # For tibble and data manipulation

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 03-3_ff3_regressions.R")


# --- 2. LOAD PORTFOLIO RETURN DATA ---
# ==============================================================================
log_message("📊 Loading all four portfolio return series...")

tryCatch({
  upgrade_ew <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_ew.rds"))
  upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
  downgrade_ew <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_ew.rds"))
  downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))
  log_message("✅ All portfolio return files loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load portfolio return files.", "ERROR"); stop(e)
})


# --- 3. RUN FAMA-FRENCH 3-FACTOR REGRESSIONS ---
# ==============================================================================
log_message("⚙️ Running Fama-French 3-Factor regressions...")

# Define the regression formula
ff3_formula <- "port_ret ~ mkt_rf + smb + hml"

# Run the regression for each portfolio using our robust function
# We use se_type = "robust" for heteroskedasticity-consistent (HC1) standard errors
model_upgrade_ew <- run_regression_model(upgrade_ew, ff3_formula, se_type = "robust")
model_upgrade_vw <- run_regression_model(upgrade_vw, ff3_formula, se_type = "robust")
model_downgrade_ew <- run_regression_model(downgrade_ew, ff3_formula, se_type = "robust")
model_downgrade_vw <- run_regression_model(downgrade_vw, ff3_formula, se_type = "robust")

log_message("✅ All four FF3 regressions completed.")


# --- 4. EXTRACT ALPHA VALUES FOR REPORTING ---
# ==============================================================================
log_message("� Extracting alpha values and statistical significance...")

# Extract coefficient values and standard errors for alpha (intercept)
alpha_upgrade_ew <- model_upgrade_ew["(Intercept)", "Estimate"]
alpha_upgrade_vw <- model_upgrade_vw["(Intercept)", "Estimate"]
alpha_downgrade_ew <- model_downgrade_ew["(Intercept)", "Estimate"]
alpha_downgrade_vw <- model_downgrade_vw["(Intercept)", "Estimate"]

# Extract p-values for alpha significance
p_upgrade_ew <- model_upgrade_ew["(Intercept)", "Pr(>|t|)"]
p_upgrade_vw <- model_upgrade_vw["(Intercept)", "Pr(>|t|)"]
p_downgrade_ew <- model_downgrade_ew["(Intercept)", "Pr(>|t|)"]
p_downgrade_vw <- model_downgrade_vw["(Intercept)", "Pr(>|t|)"]

# Create a summary table
alpha_summary <- tibble(
  Portfolio = c("Upgrade (EW)", "Upgrade (VW)", "Downgrade (EW)", "Downgrade (VW)"),
  Alpha_Monthly = c(alpha_upgrade_ew, alpha_upgrade_vw, alpha_downgrade_ew, alpha_downgrade_vw),
  Alpha_Annual_Pct = Alpha_Monthly * 12 * 100,
  P_Value = c(p_upgrade_ew, p_upgrade_vw, p_downgrade_ew, p_downgrade_vw),
  Significant = ifelse(P_Value < 0.05, "***", 
                      ifelse(P_Value < 0.10, "*", ""))
)

cat("\n--- Alpha Summary ---\n")
print(alpha_summary, digits = 4)

# --- 5. CREATE REGRESSION TABLE ---
# ==============================================================================
log_message("📝 Creating regression output table...")

# For stargazer, we need to extract the original lm objects
# Let's re-run the regressions to get lm objects for stargazer
lm_upgrade_ew <- lm(port_ret ~ mkt_rf + smb + hml, data = upgrade_ew)
lm_upgrade_vw <- lm(port_ret ~ mkt_rf + smb + hml, data = upgrade_vw)
lm_downgrade_ew <- lm(port_ret ~ mkt_rf + smb + hml, data = downgrade_ew)
lm_downgrade_vw <- lm(port_ret ~ mkt_rf + smb + hml, data = downgrade_vw)

# Create stargazer table with robust standard errors
# We use the coeftest objects to get robust SEs
stargazer(
  lm_upgrade_ew, lm_upgrade_vw, lm_downgrade_ew, lm_downgrade_vw,
  type = "text",
  title = "Fama-French 3-Factor Model Results for ESG Rating Change Portfolios",
  header = FALSE,
  column.labels = c("Upgrade (EW)", "Upgrade (VW)", "Downgrade (EW)", "Downgrade (VW)"),
  covariate.labels = c("Intercept (Alpha)", "Market Factor", "Size Factor", "Value Factor"),
  keep.stat = c("n", "rsq"),
  digits = 4,
  # Use robust standard errors from our coeftest objects
  se = list(model_upgrade_ew[, "Std. Error"], 
            model_upgrade_vw[, "Std. Error"],
            model_downgrade_ew[, "Std. Error"], 
            model_downgrade_vw[, "Std. Error"]),
  p = list(model_upgrade_ew[, "Pr(>|t|)"], 
           model_upgrade_vw[, "Pr(>|t|)"],
           model_downgrade_ew[, "Pr(>|t|)"], 
           model_downgrade_vw[, "Pr(>|t|)"]),
  out = file.path(OUTPUT_TABLES, "replication", "table_ff3_results.txt")
)

log_message("💾 Regression table saved to 'output/tables/replication/'.")

# Print alpha results to console
cat("\n--- Key Results: Monthly Alphas ---\n")
for(i in 1:nrow(alpha_summary)) {
  cat(sprintf("• %s: α = %.4f (%.2f%% annually), p = %.3f %s\n", 
              alpha_summary$Portfolio[i], 
              alpha_summary$Alpha_Monthly[i], 
              alpha_summary$Alpha_Annual_Pct[i], 
              alpha_summary$P_Value[i],
              alpha_summary$Significant[i]))
}

log_message("✅ Script 03-3 finished successfully.")
log_message("--------------------------------------------------")
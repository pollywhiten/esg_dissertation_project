# ==============================================================================
# 📈 03-4: Carhart 4-Factor Regressions (Robustness Check)
# ==============================================================================
#
# This script extends the analysis to the Carhart 4-Factor model by adding
# the momentum (MOM) factor. It tests whether the alphas found in the
# 3-factor model are robust to controlling for momentum effects.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
library(stargazer)

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 03-4_carhart4_regressions.R")


# --- 2. LOAD PORTFOLIO RETURN DATA ---
# ==============================================================================
log_message("📊 Loading all four portfolio return series...")

# We load the same files as the previous script
upgrade_ew <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_ew.rds"))
upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
downgrade_ew <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_ew.rds"))
downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))

log_message("✅ All portfolio return files loaded successfully.")


# --- 3. RUN CARHART 4-FACTOR REGRESSIONS ---
# ==============================================================================
log_message("⚙️ Running Carhart 4-Factor regressions...")

# Define the new regression formula including the momentum factor
carhart4_formula <- "port_ret ~ mkt_rf + smb + hml + mom"

# Run the regressions using our robust function
model_upgrade_vw_4f <- run_regression_model(upgrade_vw, carhart4_formula, se_type = "robust")
model_downgrade_vw_4f <- run_regression_model(downgrade_vw, carhart4_formula, se_type = "robust")

log_message("✅ 4-Factor regressions completed for value-weighted portfolios.")


# --- 4. EXTRACT ALPHA VALUES AND CREATE SUMMARY ---
# ==============================================================================
log_message("� Extracting alpha values from 4-factor models...")

# Extract coefficient values and p-values for alpha (intercept)
alpha_upgrade_vw_4f <- model_upgrade_vw_4f["(Intercept)", "Estimate"]
alpha_downgrade_vw_4f <- model_downgrade_vw_4f["(Intercept)", "Estimate"]

p_upgrade_vw_4f <- model_upgrade_vw_4f["(Intercept)", "Pr(>|t|)"]
p_downgrade_vw_4f <- model_downgrade_vw_4f["(Intercept)", "Pr(>|t|)"]

# Create a summary table comparing 3-factor vs 4-factor results
alpha_summary_4f <- tibble(
  Portfolio = c("Upgrade (VW)", "Downgrade (VW)"),
  Alpha_Monthly = c(alpha_upgrade_vw_4f, alpha_downgrade_vw_4f),
  Alpha_Annual_Pct = Alpha_Monthly * 12 * 100,
  P_Value = c(p_upgrade_vw_4f, p_downgrade_vw_4f),
  Significant = ifelse(P_Value < 0.05, "***", 
                      ifelse(P_Value < 0.10, "*", ""))
)

cat("\n--- Carhart 4-Factor Alpha Summary ---\n")
print(alpha_summary_4f, digits = 4)


# --- 5. CREATE REGRESSION TABLE AND SAVE OUTPUT ---
# ==============================================================================
log_message("📝 Creating Carhart 4-factor regression output table...")

# For stargazer, create lm objects
lm_upgrade_vw_4f <- lm(port_ret ~ mkt_rf + smb + hml + mom, data = upgrade_vw)
lm_downgrade_vw_4f <- lm(port_ret ~ mkt_rf + smb + hml + mom, data = downgrade_vw)

# Create stargazer table with robust standard errors
stargazer(
  lm_upgrade_vw_4f, lm_downgrade_vw_4f,
  type = "text",
  title = "Carhart 4-Factor Model Results for Value-Weighted ESG Portfolios",
  header = FALSE,
  column.labels = c("Upgrade (VW)", "Downgrade (VW)"),
  covariate.labels = c("Intercept (Alpha)", "Market Factor", "Size Factor", "Value Factor", "Momentum Factor"),
  keep.stat = c("n", "rsq"),
  digits = 4,
  # Use robust standard errors from our coeftest objects
  se = list(model_upgrade_vw_4f[, "Std. Error"], 
            model_downgrade_vw_4f[, "Std. Error"]),
  p = list(model_upgrade_vw_4f[, "Pr(>|t|)"], 
           model_downgrade_vw_4f[, "Pr(>|t|)"]),
  out = file.path(OUTPUT_TABLES, "replication", "table_carhart4_results.txt")
)

# Save the alpha summary as CSV
write_csv(alpha_summary_4f, file.path(OUTPUT_TABLES, "replication", "table_carhart4_summary.csv"))

log_message("💾 Regression table and summary saved to 'output/tables/replication/'.")

# Print key results to console
cat("\n--- Key Results: Carhart 4-Factor Monthly Alphas ---\n")
for(i in 1:nrow(alpha_summary_4f)) {
  cat(sprintf("• %s: α = %.4f (%.2f%% annually), p = %.3f %s\n", 
              alpha_summary_4f$Portfolio[i], 
              alpha_summary_4f$Alpha_Monthly[i], 
              alpha_summary_4f$Alpha_Annual_Pct[i], 
              alpha_summary_4f$P_Value[i],
              alpha_summary_4f$Significant[i]))
}


log_message("✅ Script 03-4 finished successfully.")
log_message("--------------------------------------------------")
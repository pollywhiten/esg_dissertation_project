# ==============================================================================
# 📊 05-3: Control Group Portfolio Analysis
# ==============================================================================
#
# This script analyzes the performance of a "control group" portfolio, which
# consists of all firms that did NOT have an ESG rating change in a given month.
# The alpha of this portfolio can be interpreted as the general "ESG premium."
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
source(file.path(FUNCTIONS_PATH, "portfolio", "weighted_average_function.R"))
library(stargazer)

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 05-3_control_group_analysis.R")


# --- 2. LOAD DATA & CREATE CONTROL GROUP ---
# ==============================================================================
log_message("📊 Loading data and creating control group...")

final_df <- readRDS(file.path(DATA_CLEAN, "final_analytical_panel.rds"))

# The control group is all firm-months where score_change is 0
control_group_firms <- final_df %>%
  filter(score_change == 0)

log_message(paste("✅ Control group created with", format(nrow(control_group_firms), big.mark=","), "observations."))


# --- 3. CALCULATE PORTFOLIO RETURNS ---
# ==============================================================================
log_message("💰 Calculating EW and VW returns for the control group...")

# Equal-Weighted
control_returns_ew <- control_group_firms %>%
  group_by(date) %>%
  summarise(port_ret = mean(ex_ret, na.rm = TRUE), .groups = "drop")

# Value-Weighted
control_returns_vw <- control_group_firms %>%
  group_by(date) %>%
  summarise(port_ret = calculate_weighted_mean(ex_ret, mktcap_lag), .groups = "drop")

log_message("✅ Control group portfolio returns calculated.")


# --- 4. ADD FACTORS AND RUN REGRESSIONS ---
# ==============================================================================
log_message("⚙️ Running FF3 and Carhart-4 regressions...")

# Get factors
monthly_factors <- final_df %>% distinct(date, mkt_rf, smb, hml, mom, rf)

# Add factors to return series
control_ew_final <- left_join(control_returns_ew, monthly_factors, by = "date")
control_vw_final <- left_join(control_returns_vw, monthly_factors, by = "date")

# Run Regressions
model_control_ew <- run_regression_model(control_ew_final, "port_ret ~ mkt_rf + smb + hml", "robust")
model_control_vw <- run_regression_model(control_vw_final, "port_ret ~ mkt_rf + smb + hml", "robust")


# --- 5. REPORT RESULTS ---
# ==============================================================================
log_message("📝 Generating results table for the control group...")

stargazer(
  model_control_ew, model_control_vw,
  type = "text",
  title = "Factor Model Results for the 'Unchanged' Control Group Portfolio",
  header = FALSE,
  column.labels = c("Control (EW)", "Control (VW)"),
  dep.var.labels.include = FALSE,
  se = list(model_control_ew[,2], model_control_vw[,2]),
  p = list(model_control_ew[,4], model_control_vw[,4]),
  keep.stat = c("n", "rsq"),
  digits = 4,
  out = file.path(OUTPUT_TABLES, "supplementary", "table_control_group_results.txt")
)

log_message("💾 Control group results table saved.")

# Print key alpha results
cat("\n--- Control Group Alphas ---\n")
cat(sprintf("• Equal-Weighted Alpha: %.4f (p=%.3f)\n", model_control_ew[1,1], model_control_ew[1,4]))
cat(sprintf("• Value-Weighted Alpha: %.4f (p=%.3f)\n", model_control_vw[1,1], model_control_vw[1,4]))

log_message("✅ Script 05-3 finished successfully.")
log_message("--------------------------------------------------")
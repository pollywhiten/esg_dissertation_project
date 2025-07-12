# ==============================================================================
# 📉 04-3: Panel Regressions with Policy Interactions
# ==============================================================================
# This script runs the main panel regressions to test whether state-level
# environmental policies moderate the stock market reaction to ESG downgrades.
# It uses firm-level clustered standard errors for inference.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
library(stargazer)
library(lmtest)
library(sandwich)

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 04-3_panel_regressions.R")
log_message("📉 Running panel regressions with policy interactions...")

# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📂 Loading enhanced regression dataset...")

regression_data <- readRDS(file.path(DATA_CLEAN, "regression_data_enhanced.rds"))
log_message(paste("✅ Loaded", format(nrow(regression_data), big.mark = ","), "observations"))

# --- 3. BASELINE SPECIFICATIONS ---
# ==============================================================================
log_message("📊 Running baseline regression specifications...")

# Model 1: Simple downgrade effect (no policy)
formula1 <- "ex_ret ~ downgrade_past_12m + mkt_rf + smb + hml + mom + log_mktcap"

model1 <- run_regression_model(
  data = regression_data,
  formula_str = formula1,
  se_type = "clustered",
  cluster_var = "cusip8"
)

cat("\n📊 Model 1: Baseline Downgrade Effect\n")
cat("=====================================\n")
print(model1[1:2, ])  # Show intercept and downgrade coefficient

# Model 2: Add policy main effect
formula2 <- "ex_ret ~ downgrade_past_12m + Strong_Policy_Top10 + mkt_rf + smb + hml + mom + log_mktcap"

model2 <- run_regression_model(
  data = regression_data,
  formula_str = formula2,
  se_type = "clustered",
  cluster_var = "cusip8"
)

# Model 3: Full interaction model (main specification)
formula3 <- "ex_ret ~ downgrade_past_12m + Strong_Policy_Top10 + downgrade_x_strong_policy + mkt_rf + smb + hml + mom + log_mktcap"

model3 <- run_regression_model(
  data = regression_data,
  formula_str = formula3,
  se_type = "clustered",
  cluster_var = "cusip8"
)

cat("\n📊 Model 3: Main Interaction Model\n")
cat("==================================\n")
print(model3[1:4, ])  # Show main coefficients

# Extract key coefficient
interaction_coef <- model3["downgrade_x_strong_policy", "Estimate"]
interaction_pval <- model3["downgrade_x_strong_policy", "Pr(>|t|)"]

cat(paste("\n🎯 Key Result: Interaction coefficient = ", 
          round(interaction_coef, 4), 
          " (p = ", round(interaction_pval, 3), ")\n", sep = ""))

# --- 4. ALTERNATIVE POLICY MEASURES ---
# ==============================================================================
log_message("🔄 Testing alternative policy measures...")

# Model 4: Continuous rank interaction
formula4 <- "ex_ret ~ downgrade_past_12m + Rank + downgrade_x_rank + mkt_rf + smb + hml + mom + log_mktcap"

model4 <- run_regression_model(
  data = regression_data,
  formula_str = formula4,
  se_type = "clustered",
  cluster_var = "cusip8"
)

# Model 5: RPS-based interaction
formula5 <- "ex_ret ~ downgrade_past_12m + has_rps + downgrade_x_has_rps + mkt_rf + smb + hml + mom + log_mktcap"

model5 <- run_regression_model(
  data = regression_data,
  formula_str = formula5,
  se_type = "clustered",
  cluster_var = "cusip8"
)

cat("\n📊 Alternative Policy Specifications:\n")
cat("====================================\n")
cat("Model 4 - Continuous rank interaction coefficient: ", 
    round(model4["downgrade_x_rank", "Estimate"], 4), "\n")
cat("Model 5 - RPS interaction coefficient: ", 
    round(model5["downgrade_x_has_rps", "Estimate"], 4), "\n")

# --- 5. CREATE REGRESSION TABLE ---
# ==============================================================================
log_message("📝 Creating main regression table...")

# Create lm objects for stargazer
lm1 <- lm(formula1, data = regression_data)
lm2 <- lm(formula2, data = regression_data)
lm3 <- lm(formula3, data = regression_data)

# Extract clustered standard errors
se_list <- list(
  model1[, "Std. Error"],
  model2[, "Std. Error"],
  model3[, "Std. Error"]
)

p_list <- list(
  model1[, "Pr(>|t|)"],
  model2[, "Pr(>|t|)"],
  model3[, "Pr(>|t|)"]
)

# Create table
stargazer(
  lm1, lm2, lm3,
  type = "text",
  title = "Panel Regressions: ESG Downgrades and State Environmental Policies",
  header = FALSE,
  column.labels = c("Baseline", "With Policy", "Interaction"),
  covariate.labels = c(
    "Downgrade (Past 12m)",
    "Strong Policy State",
    "Downgrade × Strong Policy",
    "Market Factor",
    "Size Factor", 
    "Value Factor",
    "Momentum Factor",
    "Log Market Cap"
  ),
  keep.stat = c("n", "rsq"),
  digits = 4,
  se = se_list,
  p = p_list,
  out = file.path(OUTPUT_TABLES, "extension", "table_panel_regressions.txt")
)

# --- 6. HETEROGENEITY ANALYSIS ---
# ==============================================================================
log_message("🔍 Running heterogeneity tests...")

# By firm size
formula_size <- "ex_ret ~ downgrade_past_12m * Strong_Policy_Top10 * large_firm + mkt_rf + smb + hml + mom + log_mktcap"

model_size <- run_regression_model(
  data = regression_data,
  formula_str = formula_size,
  se_type = "clustered",
  cluster_var = "cusip8"
)

# By ESG leader status
formula_leader <- "ex_ret ~ downgrade_past_12m * Strong_Policy_Top10 * esg_leader + mkt_rf + smb + hml + mom + log_mktcap"

model_leader <- run_regression_model(
  data = regression_data,
  formula_str = formula_leader,
  se_type = "clustered",
  cluster_var = "cusip8"
)

cat("\n🔍 Heterogeneity Results:\n")
cat("========================\n")
cat("Triple interaction (Size): ", 
    round(model_size["downgrade_past_12m:Strong_Policy_Top10:large_firm", "Estimate"], 4), "\n")
cat("Triple interaction (ESG Leader): ", 
    round(model_leader["downgrade_past_12m:Strong_Policy_Top10:esg_leader", "Estimate"], 4), "\n")

# --- 7. ECONOMIC SIGNIFICANCE ---
# ==============================================================================
log_message("💰 Calculating economic significance...")

# Average monthly return impact
avg_return_impact <- interaction_coef * 100  # Convert to percentage

# Annual impact
annual_impact <- avg_return_impact * 12

# Dollar impact for median firm
median_mktcap <- median(regression_data$mktcap_lag, na.rm = TRUE)
dollar_impact <- (annual_impact / 100) * median_mktcap

cat("\n💰 Economic Significance:\n")
cat("========================\n")
cat(paste("• Monthly return difference: ", round(avg_return_impact, 2), "%\n", sep = ""))
cat(paste("• Annual return difference: ", round(annual_impact, 1), "%\n", sep = ""))
cat(paste("• Dollar impact (median firm): $", 
          format(round(dollar_impact / 1e6, 1), big.mark = ","), " million\n", sep = ""))

# --- 8. ROBUSTNESS: EXCLUDE BULK UPDATES ---
# ==============================================================================
log_message("🔧 Running robustness test excluding bulk updates...")

# Filter out bulk update months
non_bulk_data <- regression_data %>%
  filter(bulk_update == 0 | is.na(bulk_update))

model_no_bulk <- run_regression_model(
  data = non_bulk_data,
  formula_str = formula3,
  se_type = "clustered",
  cluster_var = "cusip8"
)

cat("\n🔧 Robustness - Excluding Bulk Updates:\n")
cat("======================================\n")
cat("Interaction coefficient: ", 
    round(model_no_bulk["downgrade_x_strong_policy", "Estimate"], 4), "\n")
cat("Original coefficient: ", round(interaction_coef, 4), "\n")
cat("Difference: ", 
    round(model_no_bulk["downgrade_x_strong_policy", "Estimate"] - interaction_coef, 4), "\n")

# --- 9. SUMMARY STATISTICS TABLE ---
# ==============================================================================
log_message("📊 Creating summary statistics for regression sample...")

# Summary stats by treatment group
summary_by_group <- regression_data %>%
  mutate(
    treatment_group = case_when(
      downgrade_past_12m == 0 & Strong_Policy_Top10 == 0 ~ "Control",
      downgrade_past_12m == 0 & Strong_Policy_Top10 == 1 ~ "Strong Policy",
      downgrade_past_12m == 1 & Strong_Policy_Top10 == 0 ~ "Downgrade",
      downgrade_past_12m == 1 & Strong_Policy_Top10 == 1 ~ "Treatment"
    )
  ) %>%
  group_by(treatment_group) %>%
  summarise(
    n_obs = n(),
    n_firms = n_distinct(cusip8),
    avg_return = mean(ex_ret, na.rm = TRUE) * 100,
    sd_return = sd(ex_ret, na.rm = TRUE) * 100,
    avg_mktcap = mean(mktcap_lag / 1e3, na.rm = TRUE),  # In billions
    .groups = 'drop'
  )

cat("\n📊 Summary by Treatment Group:\n")
cat("=============================\n")
print(summary_by_group)

# Save summary
write.csv(summary_by_group, 
          file.path(OUTPUT_TABLES, "extension", "summary_by_treatment_group.csv"),
          row.names = FALSE)

# --- 10. SAVE REGRESSION RESULTS ---
# ==============================================================================
log_message("💾 Saving all regression results...")

# Create a list of all models
all_models <- list(
  baseline = model1,
  with_policy = model2,
  interaction = model3,
  continuous_rank = model4,
  rps_based = model5,
  size_heterogeneity = model_size,
  leader_heterogeneity = model_leader,
  no_bulk = model_no_bulk
)

saveRDS(all_models, file.path(DATA_CLEAN, "panel_regression_results.rds"))

# --- 11. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   PANEL REGRESSION ANALYSIS COMPLETE!         \n")
cat("============================================== \n")
cat("\n🎯 Main Finding:\n")
cat("----------------\n")
if (interaction_pval < 0.10) {
  cat(paste("✅ Significant interaction effect found (p = ", 
            round(interaction_pval, 3), ")\n", sep = ""))
  cat(paste("📈 Downgrades in strong policy states have ", 
            ifelse(interaction_coef > 0, "HIGHER", "LOWER"), 
            " returns\n", sep = ""))
} else {
  cat(paste("❌ No significant interaction effect (p = ", 
            round(interaction_pval, 3), ")\n", sep = ""))
}

cat("\n📊 Output Files:\n")
cat("-----------------\n")
cat("• table_panel_regressions.txt - Main regression table\n")
cat("• summary_by_treatment_group.csv - Group statistics\n")
cat("• panel_regression_results.rds - All model objects\n")

log_message("✅ Script 04-3 completed successfully!")
log_message("--------------------------------------------------")

# --- END OF SCRIPT ---
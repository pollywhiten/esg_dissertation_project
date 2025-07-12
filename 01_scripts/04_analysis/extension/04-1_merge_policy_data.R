# ==============================================================================
# 🏛️ 04-1: Merge State Policy Data for Extension Analysis
# ==============================================================================
# This script merges the state-level environmental policy data with our
# firm-level panel data. It creates policy interaction variables that will
# be used to test whether state policies moderate the ESG rating effect.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 04-1_merge_policy_data.R")
log_message("🏛️ Beginning policy extension analysis...")

# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📂 Loading analytical panel and policy data...")

# Load the main analytical panel
final_df <- readRDS(file.path(DATA_CLEAN, "final_analytical_panel.rds"))
log_message(paste("✅ Loaded analytical panel:", format(nrow(final_df), big.mark = ","), "observations"))

# Check if policy data is already merged
if ("Strong_Policy_Top10" %in% names(final_df)) {
  log_message("✅ Policy data already merged in final_df")
  
  # Summarize policy coverage
  policy_coverage <- final_df %>%
    filter(!is.na(state_abbr)) %>%
    summarise(
      total_us_obs = n(),
      has_policy_data = sum(!is.na(Strong_Policy_Top10)),
      coverage_rate = round(100 * has_policy_data / total_us_obs, 2)
    )
  
  cat("\n📊 Policy Data Coverage:\n")
  cat("=======================\n")
  cat(paste("• US firm observations:", format(policy_coverage$total_us_obs, big.mark = ","), "\n"))
  cat(paste("• With policy data:", format(policy_coverage$has_policy_data, big.mark = ","), "\n"))
  cat(paste("• Coverage rate:", policy_coverage$coverage_rate, "%\n"))
  
} else {
  # If not merged, load and merge policy data
  log_message("⚠️ Policy data not found in final_df. Loading separately...")
  
  policy_data <- readRDS(file.path(DATA_CLEAN, "policy_panel_clean.rds"))
  log_message(paste("✅ Loaded policy data:", nrow(policy_data), "state-years"))
  
  # Merge policy data
  final_df <- final_df %>%
    mutate(year = year(date)) %>%
    left_join(
      policy_data,
      by = c("state_abbr" = "State_Abbrev", "year" = "Year")
    )
}

# --- 3. ANALYZE POLICY VARIABLE DISTRIBUTION ---
# ==============================================================================
log_message("📊 Analyzing policy variable distribution...")

# Focus on US firms only
us_firms <- final_df %>%
  filter(!is.na(state_abbr))

# Policy distribution by state
state_policy_summary <- us_firms %>%
  filter(!is.na(Strong_Policy_Top10)) %>%
  group_by(state_abbr) %>%
  summarise(
    n_obs = n(),
    avg_rank = mean(Rank, na.rm = TRUE),
    pct_strong_policy = mean(Strong_Policy_Top10) * 100,
    pct_has_rps = mean(has_rps) * 100,
    .groups = 'drop'
  ) %>%
  arrange(avg_rank)

cat("\n🏛️ Top 10 States by ACEEE Ranking:\n")
cat("====================================\n")
print(state_policy_summary %>% head(10))

cat("\n🏛️ Bottom 10 States by ACEEE Ranking:\n")
cat("======================================\n")
print(state_policy_summary %>% tail(10))

# --- 4. CREATE DOWNGRADE EVENT FLAGS ---
# ==============================================================================
log_message("🚨 Creating downgrade event flags...")

# Create flags for downgrades within the past 12 months
final_df <- final_df %>%
  arrange(cusip8, date) %>%
  group_by(cusip8) %>%
  mutate(
    # Flag for current month downgrade
    downgrade_current = as.integer(score_change == 1 & score_direction == "Downgrade"),
    
    # Flag for downgrade in past 12 months (rolling window)
    downgrade_past_12m = zoo::rollapplyr(
      downgrade_current, 
      width = 12, 
      FUN = max, 
      partial = TRUE, 
      fill = 0
    )
  ) %>%
  ungroup()

# Summary of downgrade events
downgrade_summary <- final_df %>%
  summarise(
    total_downgrades = sum(downgrade_current, na.rm = TRUE),
    firms_with_downgrades = n_distinct(cusip8[downgrade_current == 1]),
    obs_in_post_downgrade = sum(downgrade_past_12m, na.rm = TRUE)
  )

cat("\n📉 Downgrade Event Summary:\n")
cat("==========================\n")
cat(paste("• Total downgrade events:", format(downgrade_summary$total_downgrades, big.mark = ","), "\n"))
cat(paste("• Firms experiencing downgrades:", downgrade_summary$firms_with_downgrades, "\n"))
cat(paste("• Observations in 12m post-downgrade:", format(downgrade_summary$obs_in_post_downgrade, big.mark = ","), "\n"))

# --- 5. CREATE INTERACTION TERMS ---
# ==============================================================================
log_message("🔧 Creating policy interaction terms...")

# Create interaction between downgrade events and policy strength
final_df <- final_df %>%
  mutate(
    # Main interaction: Downgrade × Strong Policy
    downgrade_x_strong_policy = downgrade_past_12m * Strong_Policy_Top10,
    
    # Alternative interactions for robustness
    downgrade_x_has_rps = downgrade_past_12m * has_rps,
    
    # Continuous interaction with rank (lower rank = stronger policy)
    downgrade_x_rank = downgrade_past_12m * Rank
  )

# --- 6. ANALYZE TREATMENT AND CONTROL GROUPS ---
# ==============================================================================
log_message("📊 Analyzing treatment and control groups...")

# For US firms with policy data
us_policy_firms <- final_df %>%
  filter(!is.na(state_abbr), !is.na(Strong_Policy_Top10))

# Create 2x2 table of observations
treatment_table <- us_policy_firms %>%
  mutate(
    downgrade_group = ifelse(downgrade_past_12m == 1, "Downgrade", "No Downgrade"),
    policy_group = ifelse(Strong_Policy_Top10 == 1, "Strong Policy", "Weak Policy")
  ) %>%
  count(downgrade_group, policy_group) %>%
  pivot_wider(names_from = policy_group, values_from = n, values_fill = 0)

cat("\n📊 Treatment and Control Group Distribution:\n")
cat("===========================================\n")
print(treatment_table)

# Calculate average returns by group
group_returns <- us_policy_firms %>%
  group_by(downgrade_past_12m, Strong_Policy_Top10) %>%
  summarise(
    n_obs = n(),
    avg_excess_return = mean(ex_ret, na.rm = TRUE) * 100,
    sd_return = sd(ex_ret, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  mutate(
    group_label = case_when(
      downgrade_past_12m == 0 & Strong_Policy_Top10 == 0 ~ "Control: No DG, Weak Policy",
      downgrade_past_12m == 0 & Strong_Policy_Top10 == 1 ~ "No DG, Strong Policy",
      downgrade_past_12m == 1 & Strong_Policy_Top10 == 0 ~ "DG, Weak Policy",
      downgrade_past_12m == 1 & Strong_Policy_Top10 == 1 ~ "Treatment: DG, Strong Policy"
    )
  )

cat("\n📈 Average Monthly Excess Returns by Group:\n")
cat("==========================================\n")
print(group_returns %>% select(group_label, n_obs, avg_excess_return, sd_return))

# --- 7. SAVE ENHANCED DATASET ---
# ==============================================================================
log_message("💾 Saving dataset with policy interactions...")

# Save the full dataset with policy variables
saveRDS(final_df, file.path(DATA_CLEAN, "final_panel_with_policy.rds"))

# Create focused dataset for regression analysis (US firms only)
regression_data <- us_policy_firms %>%
  filter(!is.na(ex_ret), !is.na(mkt_rf)) %>%
  select(
    # Identifiers
    cusip8, date, state_abbr,
    # Dependent variable
    ex_ret,
    # Main variables of interest
    downgrade_past_12m, Strong_Policy_Top10, downgrade_x_strong_policy,
    # Control variables
    mkt_rf, smb, hml, mom, mktcap_lag,
    # Alternative policy measures
    Rank, has_rps, downgrade_x_has_rps, downgrade_x_rank,
    # Additional info
    esg_risk_category, score_direction, bulk_update
  )

saveRDS(regression_data, file.path(DATA_CLEAN, "regression_ready_panel.rds"))

# --- 8. SUMMARY STATISTICS FOR REGRESSION SAMPLE ---
# ==============================================================================
log_message("📊 Creating summary statistics for regression sample...")

cat("\n📊 Regression Sample Summary:\n")
cat("=============================\n")
cat(paste("• Total observations:", format(nrow(regression_data), big.mark = ","), "\n"))
cat(paste("• Unique firms:", n_distinct(regression_data$cusip8), "\n"))
cat(paste("• Unique states:", n_distinct(regression_data$state_abbr), "\n"))
cat(paste("• Time period:", min(regression_data$date), "to", max(regression_data$date), "\n"))

# Variable summary
var_summary <- regression_data %>%
  summarise(
    across(
      c(ex_ret, downgrade_past_12m, Strong_Policy_Top10, downgrade_x_strong_policy),
      list(
        mean = ~mean(., na.rm = TRUE),
        sd = ~sd(., na.rm = TRUE),
        min = ~min(., na.rm = TRUE),
        max = ~max(., na.rm = TRUE)
      )
    )
  ) %>%
  pivot_longer(everything(), names_to = c("variable", ".value"), names_sep = "_(?=[^_]+$)")

cat("\n📊 Key Variable Summary:\n")
print(var_summary, n = Inf)

# --- 9. FINAL MESSAGE ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   POLICY DATA MERGE COMPLETE!                 \n")
cat("============================================== \n")
cat("\n📊 Output Files Created:\n")
cat("------------------------\n")
cat("• final_panel_with_policy.rds - Full dataset with policy variables\n")
cat("• regression_ready_panel.rds - Focused dataset for regression analysis\n")
cat("\n🔬 Key Findings:\n")
cat("-----------------\n")
cat(paste("• Downgrade events in strong policy states:", 
    sum(regression_data$downgrade_x_strong_policy), "\n"))
cat(paste("• Control group size (no DG, weak policy):", 
    nrow(regression_data %>% filter(downgrade_past_12m == 0, Strong_Policy_Top10 == 0)), "\n"))

log_message("✅ Script 04-1 completed successfully!")
log_message("--------------------------------------------------")

# --- END OF SCRIPT ---
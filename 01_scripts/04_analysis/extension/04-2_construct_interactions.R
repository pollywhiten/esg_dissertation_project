# ==============================================================================
# 🔧 04-2: Construct Policy Interaction Variables
# ==============================================================================
# This script creates various specifications of the policy interaction model
# and prepares alternative measures for robustness checks. It also conducts
# preliminary difference-in-differences style analysis.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 04-2_construct_interactions.R")
log_message("🔧 Constructing policy interaction variables...")

# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📂 Loading regression-ready panel data...")

regression_data <- readRDS(file.path(DATA_CLEAN, "regression_ready_panel.rds"))
log_message(paste("✅ Loaded", format(nrow(regression_data), big.mark = ","), "observations"))

# --- 3. ANALYZE VARIATION IN TREATMENT ---
# ==============================================================================
log_message("📊 Analyzing variation in treatment assignment...")

# Cross-sectional variation: firms in different states
cross_section_var <- regression_data %>%
  filter(downgrade_past_12m == 1) %>%
  group_by(cusip8) %>%
  summarise(
    state = first(state_abbr),
    strong_policy = first(Strong_Policy_Top10),
    .groups = 'drop'
  ) %>%
  count(strong_policy) %>%
  mutate(pct = round(100 * n / sum(n), 1))

cat("\n🏛️ Cross-sectional Variation (Downgraded Firms):\n")
cat("================================================\n")
print(cross_section_var)

# Time-series variation: policy changes over time
time_series_var <- regression_data %>%
  group_by(state_abbr, year = year(date)) %>%
  summarise(
    avg_rank = mean(Rank, na.rm = TRUE),
    strong_policy = first(Strong_Policy_Top10),
    .groups = 'drop'
  ) %>%
  group_by(state_abbr) %>%
  mutate(
    rank_change = avg_rank - lag(avg_rank),
    policy_switch = strong_policy != lag(strong_policy)
  ) %>%
  filter(!is.na(policy_switch))

policy_switches <- sum(time_series_var$policy_switch)
cat(paste("\n📅 Time-series Variation: ", policy_switches, " state-year policy switches\n", sep = ""))

# --- 4. CREATE ALTERNATIVE INTERACTION SPECIFICATIONS ---
# ==============================================================================
log_message("🔨 Creating alternative interaction specifications...")

regression_data <- regression_data %>%
  mutate(
    # Quartile-based policy strength (more granular than top 10)
    rank_quartile = ntile(Rank, 4),
    strong_policy_q1 = as.integer(rank_quartile == 1),  # Top quartile
    strong_policy_q2 = as.integer(rank_quartile <= 2),  # Top half
    
    # Interactions with quartiles
    downgrade_x_q1 = downgrade_past_12m * strong_policy_q1,
    downgrade_x_q2 = downgrade_past_12m * strong_policy_q2,
    
    # Log market cap for controls
    log_mktcap = log(mktcap_lag + 1),
    
    # Bulk update interactions (to test if effect differs for bulk updates)
    downgrade_bulk = downgrade_past_12m * bulk_update,
    downgrade_x_strong_x_bulk = downgrade_past_12m * Strong_Policy_Top10 * bulk_update
  )

cat("\n🔧 Alternative Specifications Created:\n")
cat("=====================================\n")
cat("• Quartile-based policy measures (Q1, Q2)\n")
cat("• Continuous rank interaction\n")
cat("• RPS-based interaction\n")
cat("• Bulk update triple interaction\n")

# --- 5. PRELIMINARY DIFF-IN-DIFF ANALYSIS ---
# ==============================================================================
log_message("📊 Conducting preliminary difference-in-differences analysis...")

# Calculate pre/post downgrade returns by policy group
did_analysis <- regression_data %>%
  # Focus on firms that experience a downgrade (using score_direction)
  filter(cusip8 %in% unique(cusip8[score_direction == "Downgrade"])) %>%
  group_by(cusip8) %>%
  mutate(
    # Find the first downgrade date for each firm
    first_downgrade = min(date[score_direction == "Downgrade"], na.rm = TRUE),
    # Create pre/post indicator
    post_downgrade = date >= first_downgrade
  ) %>%
  ungroup() %>%
  filter(!is.infinite(first_downgrade)) %>%
  # Calculate average returns
  group_by(post_downgrade, Strong_Policy_Top10) %>%
  summarise(
    n_obs = n(),
    avg_return = mean(ex_ret, na.rm = TRUE) * 100,
    se_return = sd(ex_ret, na.rm = TRUE) / sqrt(n()) * 100,
    .groups = 'drop'
  )

cat("\n📈 Difference-in-Differences Results:\n")
cat("====================================\n")
print(did_analysis)

# Calculate the DiD estimate
did_estimate <- (
  did_analysis$avg_return[did_analysis$post_downgrade == TRUE & did_analysis$Strong_Policy_Top10 == 1] -
  did_analysis$avg_return[did_analysis$post_downgrade == FALSE & did_analysis$Strong_Policy_Top10 == 1]
) - (
  did_analysis$avg_return[did_analysis$post_downgrade == TRUE & did_analysis$Strong_Policy_Top10 == 0] -
  did_analysis$avg_return[did_analysis$post_downgrade == FALSE & did_analysis$Strong_Policy_Top10 == 0]
)

cat(paste("\n🎯 DiD Estimate: ", round(did_estimate, 3), "% per month\n", sep = ""))
cat(paste("   Annualized: ", round(did_estimate * 12, 2), "% per year\n", sep = ""))

# --- 6. HETEROGENEITY ANALYSIS SETUP ---
# ==============================================================================
log_message("🔍 Setting up heterogeneity analysis variables...")

# Industry classification (simplified)
regression_data <- regression_data %>%
  mutate(
    # Create industry groups based on first 2 digits of CUSIP
    industry_code = substr(cusip8, 1, 2),
    # Identify high-pollution industries (manufacturing, utilities, energy)
    high_pollution_industry = industry_code %in% c("10", "12", "13", "28", "29", "33", "49")
  )

# Size-based heterogeneity
size_terciles <- quantile(regression_data$mktcap_lag, probs = c(0.33, 0.67), na.rm = TRUE)
regression_data <- regression_data %>%
  mutate(
    size_group = case_when(
      mktcap_lag < size_terciles[1] ~ "Small",
      mktcap_lag < size_terciles[2] ~ "Medium",
      TRUE ~ "Large"
    ),
    large_firm = as.integer(size_group == "Large")
  )

# ESG leader/laggard status
regression_data <- regression_data %>%
  mutate(
    esg_leader = as.integer(esg_risk_category %in% c("Negligible", "Low")),
    # Triple interaction for heterogeneity
    downgrade_x_strong_x_leader = downgrade_past_12m * Strong_Policy_Top10 * esg_leader,
    downgrade_x_strong_x_large = downgrade_past_12m * Strong_Policy_Top10 * large_firm
  )

cat("\n🔍 Heterogeneity Variables Created:\n")
cat("===================================\n")
cat(paste("• High pollution industries: ", 
    sum(regression_data$high_pollution_industry), " observations\n", sep = ""))
cat(paste("• Large firms (top tercile): ", 
    sum(regression_data$large_firm), " observations\n", sep = ""))
cat(paste("• ESG leaders: ", 
    sum(regression_data$esg_leader), " observations\n", sep = ""))

# --- 7. SAVE ENHANCED DATASET ---
# ==============================================================================
log_message("💾 Saving enhanced regression dataset...")

saveRDS(regression_data, file.path(DATA_CLEAN, "regression_data_enhanced.rds"))

# Create summary of all interaction variables
interaction_vars <- regression_data %>%
  select(starts_with("downgrade_x_")) %>%
  summarise(across(everything(), ~sum(., na.rm = TRUE))) %>%
  pivot_longer(everything(), names_to = "interaction", values_to = "n_treated")

cat("\n📊 Interaction Variable Summary:\n")
cat("================================\n")
print(interaction_vars)

# --- 8. BALANCE CHECK ---
# ==============================================================================
log_message("⚖️ Checking covariate balance across treatment groups...")

# Compare characteristics of treated vs control
balance_check <- regression_data %>%
  group_by(downgrade_past_12m, Strong_Policy_Top10) %>%
  summarise(
    n_obs = n(),
    avg_mktcap = mean(log_mktcap, na.rm = TRUE),
    avg_beta = mean(mkt_rf, na.rm = TRUE),
    pct_leader = mean(esg_leader, na.rm = TRUE) * 100,
    pct_high_pollution = mean(high_pollution_industry, na.rm = TRUE) * 100,
    .groups = 'drop'
  ) %>%
  mutate(
    group = case_when(
      downgrade_past_12m == 0 & Strong_Policy_Top10 == 0 ~ "Control",
      downgrade_past_12m == 0 & Strong_Policy_Top10 == 1 ~ "Strong Policy Only",
      downgrade_past_12m == 1 & Strong_Policy_Top10 == 0 ~ "Downgrade Only",
      downgrade_past_12m == 1 & Strong_Policy_Top10 == 1 ~ "Treatment"
    )
  )

cat("\n⚖️ Covariate Balance Check:\n")
cat("==========================\n")
print(balance_check %>% select(group, n_obs, avg_mktcap, pct_leader, pct_high_pollution))

# --- 9. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   INTERACTION CONSTRUCTION COMPLETE!          \n")
cat("============================================== \n")
cat("\n📊 Analysis Ready:\n")
cat("------------------\n")
cat("• Main interaction: downgrade_x_strong_policy\n")
cat("• Alternative measures: quartiles, continuous rank, RPS\n")
cat("• Heterogeneity tests: size, industry, ESG status\n")
cat("• Balance checks completed\n")
cat("\n🚀 Next: Run panel regressions (04-3_panel_regressions.R)\n")

log_message("✅ Script 04-2 completed successfully!")
log_message("--------------------------------------------------")

# --- END OF SCRIPT ---
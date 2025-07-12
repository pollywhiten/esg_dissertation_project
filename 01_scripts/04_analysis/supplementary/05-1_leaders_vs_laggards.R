# ==============================================================================
# 📊 05-1: Heterogeneity Analysis - ESG Leaders vs. Laggards
# ==============================================================================
#
# This script tests whether the market reaction to ESG rating changes differs
# between firms that are generally considered ESG leaders versus laggards.
# A "Leader Firm" is defined as any company that has ever achieved a 'Low' or
# 'Negligible' rating in our sample.
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
log_message("🚀 Starting script: 05-1_leaders_vs_laggards.R")


# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📂 Loading final panel and event data...")

tryCatch({
  final_df <- readRDS(file.path(DATA_CLEAN, "final_analytical_panel.rds"))
  events <- readRDS(file.path(DATA_INTER_EVT, "rating_change_events_flagged.rds"))
  ff_factors_clean <- readRDS(file.path(DATA_CLEAN, "factors_clean.rds"))
  log_message("✅ All necessary data loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load necessary .rds files.", "ERROR"); stop(e)
})


# --- 3. CLASSIFY FIRMS AS LEADERS OR LAGGARDS (REVISED METHODOLOGY) ---
# ==============================================================================
log_message("🔍 Classifying firms based on their EVER-rated status...")

# --- NEW METHOD: Identify firms that have EVER been a leader ---
leader_firm_cusips <- final_df %>%
  filter(esg_risk_category_numeric <= ESG_LEADER_THRESHOLD) %>%
  distinct(cusip8)

# Add this static 'firm_type' classification to our events data
cusip_map <- final_df %>% distinct(entity_id, cusip8)
events_with_status <- events %>%
  left_join(cusip_map, by = "entity_id") %>%
  filter(!is.na(cusip8)) %>%
  mutate(
    firm_type = if_else(cusip8 %in% leader_firm_cusips$cusip8, "Leader Firm", "Laggard Firm")
  )

cat("\n📊 Firm Classification Summary (Based on Ever-Leader Status):\n")
print(count(events_with_status, firm_type, score_direction))


# --- 4. CONSTRUCT AND ANALYZE PORTFOLIOS ---
# ==============================================================================
log_message("⚙️ Constructing and analyzing 4 separate portfolios...")

# Helper function (remains the same)
analyze_sub_portfolio <- function(event_subset, portfolio_name) {
  log_message(paste("   - Analyzing portfolio:", portfolio_name))
  cat(sprintf("     - Number of events: %d\n", nrow(event_subset)))
  if (nrow(event_subset) == 0) {
    log_message(paste("     - Event set is empty for", portfolio_name, ". Skipping."), "WARNING")
    return(NULL)
  }
  event_windows <- event_subset %>%
    rename(entry_date = field_date) %>%
    mutate(exit_date = entry_date %m+% months(HOLDING_PERIOD_MONTHS))
  portfolio_data <- final_df %>%
    inner_join(select(event_windows, cusip8, entry_date, exit_date), by = "cusip8", relationship = "many-to-many") %>%
    filter(date >= entry_date & date < exit_date) %>%
    distinct(cusip8, date, .keep_all = TRUE)
  if (nrow(portfolio_data) == 0) {
    log_message(paste("     - No firm-month observations in the portfolio for", portfolio_name, ". Skipping."), "WARNING")
    return(NULL)
  }
  portfolio_returns <- portfolio_data %>%
    group_by(date) %>%
    summarise(port_ret = calculate_weighted_mean(ex_ret, mktcap_lag), .groups = "drop") %>%
    left_join(ff_factors_clean, by = "date")
  model <- run_regression_model(portfolio_returns, "port_ret ~ mkt_rf + smb + hml", se_type = "robust")
  return(model)
}

# Run for all four groups using the new classification
model_leader_up   <- analyze_sub_portfolio(filter(events_with_status, firm_type == "Leader Firm" & score_direction == "Upgrade"), "Leader-Upgrades")
model_leader_down <- analyze_sub_portfolio(filter(events_with_status, firm_type == "Leader Firm" & score_direction == "Downgrade"), "Leader-Downgrades")
model_laggard_up  <- analyze_sub_portfolio(filter(events_with_status, firm_type == "Laggard Firm" & score_direction == "Upgrade"), "Laggard-Upgrades")
model_laggard_down<- analyze_sub_portfolio(filter(events_with_status, firm_type == "Laggard Firm" & score_direction == "Downgrade"), "Laggard-Downgrades")

log_message("✅ All Leader/Laggard portfolio regressions complete.")


# --- 5. REPORT RESULTS ---
# ==============================================================================
log_message("📝 Generating final results table...")

model_list <- list(model_leader_up, model_leader_down, model_laggard_up, model_laggard_down)
names(model_list) <- c("Leader-Upgrades", "Leader-Downgrades", "Laggard-Upgrades", "Laggard-Downgrades")
model_list <- purrr::compact(model_list) # Remove any NULL models

if(length(model_list) > 0) {
  stargazer(
    model_list,
    type = "text",
    title = "Heterogeneity Analysis: ESG Leaders vs. Laggards (Value-Weighted)",
    header = FALSE,
    column.labels = names(model_list),
    dep.var.labels.include = FALSE,
    se = map(model_list, ~ .[, "Std. Error"]),
    p = map(model_list, ~ .[, "Pr(>|t|)"]),
    keep.stat = c("n", "rsq"),
    digits = 4,
    out = file.path(OUTPUT_TABLES, "supplementary", "table_leaders_vs_laggards.txt")
  )
  log_message("💾 Results table saved successfully.")
  
  cat("\n--- Key Alphas: Leaders vs. Laggards (Revised Method) ---\n")
  for(i in 1:length(model_list)) {
      cat(sprintf("• %s: α = %.4f (p = %.3f)\n", 
                  names(model_list)[i], 
                  model_list[[i]][1,1], 
                  model_list[[i]][1,4]))
  }
  
} else {
  log_message("No models were successfully run, so no table was generated.", "WARNING")
}

log_message("✅ Script 05-1 finished successfully.")
log_message("--------------------------------------------------")
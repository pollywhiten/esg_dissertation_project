# ==============================================================================
# 📈 03-2: Construct Calendar-Time Portfolios
# ==============================================================================
#
# This script constructs the calendar-time portfolios based on ESG rating
# changes. It identifies all firm-months that fall within the 12-month
# holding period following an upgrade or a downgrade. It then calculates
# the monthly returns for four distinct portfolios:
#   1. Upgrade Portfolio (Equal-Weighted)
#   2. Upgrade Portfolio (Value-Weighted)
#   3. Downgrade Portfolio (Equal-Weighted)
#   4. Downgrade Portfolio (Value-Weighted)
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "portfolio", "weighted_average_function.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 03-2_portfolio_construction.R")


# --- 2. LOAD FINAL ANALYTICAL PANEL ---
# ==============================================================================
log_message("📊 Loading final analytical panel...")

tryCatch({
  final_df <- readRDS(file.path(DATA_CLEAN, "final_analytical_panel.rds"))
  log_message("✅ Final analytical panel loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load 'final_analytical_panel.rds'.", "ERROR")
  stop(e)
})


# --- 3. FILTER FOR PORTFOLIO OBSERVATIONS ---
# ==============================================================================
log_message("🔍 Filtering for observations within event windows...")

# The 'in_portfolio' flag was created in the feature engineering phase
portfolio_data <- final_df %>%
  filter(in_portfolio == TRUE)

log_message(paste("✅ Found", format(nrow(portfolio_data), big.mark = ","), "firm-month observations in portfolios."))


# --- 4. CREATE UPGRADE & DOWNGRADE SUBSETS ---
# ==============================================================================
log_message(" แยก Upgrade and Downgrade portfolios...") # Splitting...

upgrade_portfolio_firms <- portfolio_data %>%
  filter(portfolio_direction == "Upgrade")

downgrade_portfolio_firms <- portfolio_data %>%
  filter(portfolio_direction == "Downgrade")

cat(sprintf("  - 📈 Upgrade portfolio: %d firm-months\n", nrow(upgrade_portfolio_firms)))
cat(sprintf("  - 📉 Downgrade portfolio: %d firm-months\n", nrow(downgrade_portfolio_firms)))


# --- 5. CALCULATE MONTHLY PORTFOLIO RETURNS ---
# ==============================================================================
log_message("💰 Calculating monthly returns for each portfolio...")

# --- Equal-Weighted Portfolios ---
log_message("   - Calculating Equal-Weighted (EW) returns...")

upgrade_returns_ew <- upgrade_portfolio_firms %>%
  group_by(date) %>%
  summarise(
    port_ret = mean(ex_ret, na.rm = TRUE),
    .groups = "drop"
  )

downgrade_returns_ew <- downgrade_portfolio_firms %>%
  group_by(date) %>%
  summarise(
    port_ret = mean(ex_ret, na.rm = TRUE),
    .groups = "drop"
  )

# --- Value-Weighted Portfolios ---
log_message("   - Calculating Value-Weighted (VW) returns...")

upgrade_returns_vw <- upgrade_portfolio_firms %>%
  group_by(date) %>%
  summarise(
    # Use our robust, tested utility function
    port_ret = calculate_weighted_mean(x = ex_ret, w = mktcap_lag),
    .groups = "drop"
  )

downgrade_returns_vw <- downgrade_portfolio_firms %>%
  group_by(date) %>%
  summarise(
    port_ret = calculate_weighted_mean(x = ex_ret, w = mktcap_lag),
    .groups = "drop"
  )

log_message("✅ All four portfolio return series calculated.")


# --- 6. ADD FACTORS AND SAVE ---
# ==============================================================================
log_message("💾 Saving portfolio return series...")

# Create a helper function to add factors and save
add_factors_and_save <- function(portfolio_returns, filename) {
  
  # Get the unique factors for each month
  monthly_factors <- final_df %>%
    distinct(date, mkt_rf, smb, hml, mom, rf)
  
  # Join factors and save
  final_portfolio <- portfolio_returns %>%
    left_join(monthly_factors, by = "date")
  
  saveRDS(final_portfolio, file.path(DATA_CLEAN, filename))
  log_message(paste("   - Saved:", filename))
}

# Apply the function to all four portfolios
add_factors_and_save(upgrade_returns_ew, "port_returns_upgrade_ew.rds")
add_factors_and_save(upgrade_returns_vw, "port_returns_upgrade_vw.rds")
add_factors_and_save(downgrade_returns_ew, "port_returns_downgrade_ew.rds")
add_factors_and_save(downgrade_returns_vw, "port_returns_downgrade_vw.rds")


# --- 7. FINAL VALIDATION ---
# ==============================================================================
log_message("📋 Final validation:")

cat("\n--- Sample of Value-Weighted Upgrade Portfolio Returns ---\n")
print(head(upgrade_returns_vw))

cat("\n--- Summary of Value-Weighted Downgrade Portfolio Returns ---\n")
summary(downgrade_returns_vw$port_ret)

log_message("✅ Script 03-2 finished successfully.")
log_message("--------------------------------------------------")
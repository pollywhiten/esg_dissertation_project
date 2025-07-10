# ==============================================================================
# Test Script for Regression Utility Functions
# ==============================================================================

# Load required libraries
library(tidyverse)
# Using here::here() makes this script runnable from anywhere in the project
source(here::here("01_scripts", "01_functions", "analysis", "regression_functions.R"))

cat("\n🧪 Testing Regression Functions\n")
cat("===============================\n")

# --- Create sample data for testing ---
set.seed(123)
n_firms <- 10
n_months <- 60
n_obs <- n_firms * n_months

# Portfolio data (single time series)
portfolio_data <- tibble(
  date = seq(as.Date("2020-01-01"), by = "month", length.out = n_months),
  port_ex_ret = rnorm(n_months, 0.01, 0.05),
  mkt_rf = rnorm(n_months, 0.008, 0.04),
  smb = rnorm(n_months, 0, 0.02),
  hml = rnorm(n_months, 0, 0.02),
  mom = rnorm(n_months, 0, 0.03)
)

# Panel data (multiple firms over time)
panel_data <- tibble(
  cusip8 = rep(paste0("CUSIP_", 1:n_firms), each = n_months),
  date = rep(portfolio_data$date, n_firms),
  ex_ret = rnorm(n_obs, 0.01, 0.06),
  mkt_rf = rep(portfolio_data$mkt_rf, n_firms),
  smb = rep(portfolio_data$smb, n_firms),
  hml = rep(portfolio_data$hml, n_firms),
  mom = rep(portfolio_data$mom, n_firms),
  Downgrade_Event = rbinom(n_obs, 1, 0.1),
  Strong_Policy = rep(rbinom(n_firms, 1, 0.4), each = n_months)
) %>%
  mutate(Interaction_Term = Downgrade_Event * Strong_Policy)

# --- Test 1: Portfolio 3-Factor Model with Robust SEs ---
cat("\n🧪 Test 1: Portfolio 3-Factor Model (Robust SE)\n")
ff3_formula <- "port_ex_ret ~ mkt_rf + smb + hml"
ff3_result <- run_regression_model(portfolio_data, ff3_formula, se_type = "robust")
print(ff3_result)
stopifnot("coeftest" %in% class(ff3_result))
cat("✅ PASSED\n")

# --- Test 2: Portfolio 4-Factor Model with Robust SEs ---
cat("\n🧪 Test 2: Portfolio 4-Factor Model (Robust SE)\n")
carhart_formula <- "port_ex_ret ~ mkt_rf + smb + hml + mom"
carhart_result <- run_regression_model(portfolio_data, carhart_formula, se_type = "robust")
print(carhart_result)
stopifnot("coeftest" %in% class(carhart_result))
cat("✅ PASSED\n")

# --- Test 3: Firm-Level Panel Model with Clustered SEs ---
cat("\n🧪 Test 3: Panel Model (Clustered SE)\n")
panel_formula <- "ex_ret ~ Downgrade_Event * Strong_Policy + mkt_rf + smb + hml + mom"
panel_result <- run_regression_model(panel_data, panel_formula, se_type = "clustered", cluster_var = "cusip8")
print(panel_result)
stopifnot("coeftest" %in% class(panel_result))
cat("✅ PASSED\n")

# --- Test 4: Standard OLS (for comparison) ---
cat("\n🧪 Test 4: Standard OLS\n")
standard_result <- run_regression_model(portfolio_data, ff3_formula, se_type = "standard")
print(standard_result)
stopifnot("summary.lm" %in% class(standard_result))
cat("✅ PASSED\n")

# --- Test 5: Error Handling ---
cat("\n🧪 Test 5: Error Handling\n")
# Test missing cluster_var
test_error <- try(run_regression_model(panel_data, panel_formula, se_type = "clustered"), silent = TRUE)
stopifnot(inherits(test_error, "try-error"))
cat("✓ Correctly caught missing cluster_var error\n")

cat("\n🎉 All tests completed successfully!\n")
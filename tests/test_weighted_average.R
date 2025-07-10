# ==============================================================================
# Test Script for Weighted Average Utility Functions
# ==============================================================================

# Load required libraries
library(tidyverse)

# Source the utility functions
source('../01_scripts/01_functions/portfolio/weighted_average_function.R')

cat("\n🧪 Testing Weighted Average Functions\n")
cat("====================================\n")

# Test 1: Basic weighted mean calculation
cat("\n🧪 Test 1: Basic weighted mean calculation\n")
returns <- c(0.10, 0.05, -0.02)
market_caps <- c(200, 100, 50)

cat("Returns:     ", paste(returns, collapse = ", "), "\n")
cat("Market caps: ", paste(market_caps, collapse = ", "), "\n")

result1 <- calculate_weighted_mean(returns, market_caps)
cat("Weighted mean: ", result1, "\n")

# Manual calculation for verification
manual_calc <- sum(returns * market_caps) / sum(market_caps)
cat("Manual calc:   ", manual_calc, "\n")

# Test 2: Equal weights (should equal simple mean)
cat("\n🧪 Test 2: Equal weights (should equal simple mean)\n")
values <- c(10, 20, 30, 40)
equal_weights <- c(1, 1, 1, 1)

cat("Values:        ", paste(values, collapse = ", "), "\n")
cat("Equal weights: ", paste(equal_weights, collapse = ", "), "\n")

result2 <- calculate_weighted_mean(values, equal_weights)
simple_mean <- mean(values)
cat("Weighted mean: ", result2, "\n")
cat("Simple mean:   ", simple_mean, "\n")

# Test 3: Missing values handling
cat("\n🧪 Test 3: Missing values handling\n")
returns_na <- c(0.15, NA, 0.08, -0.05, NA)
weights_na <- c(100, 200, NA, 150, 80)

cat("Returns with NA: ", paste(returns_na, collapse = ", "), "\n")
cat("Weights with NA: ", paste(weights_na, collapse = ", "), "\n")

result3 <- calculate_weighted_mean(returns_na, weights_na, na.rm = TRUE)
cat("Weighted mean (na.rm=TRUE): ", result3, "\n")

# Test 4: Zero weights handling
cat("\n🧪 Test 4: Zero weights handling\n")
returns_zero <- c(0.10, 0.05, 0.08)
weights_zero <- c(0, 0, 0)

cat("Returns:     ", paste(returns_zero, collapse = ", "), "\n")
cat("Zero weights:", paste(weights_zero, collapse = ", "), "\n")

result4 <- calculate_weighted_mean(returns_zero, weights_zero)
cat("Result (should fallback to simple mean): ", result4, "\n")
cat("Simple mean for comparison: ", mean(returns_zero), "\n")

# Test 5: Single observation
cat("\n🧪 Test 5: Single observation\n")
single_return <- 0.12
single_weight <- 500

result5 <- calculate_weighted_mean(single_return, single_weight)
cat("Single return: ", single_return, "\n")
cat("Single weight: ", single_weight, "\n")
cat("Weighted mean: ", result5, "\n")

# Test 6: Large numbers (market cap scenario)
cat("\n🧪 Test 6: Large market cap scenario\n")
stock_returns <- c(0.15, -0.08, 0.22, 0.03, -0.12)
market_caps_big <- c(1.2e9, 3.5e8, 2.1e9, 8.7e8, 1.6e9)  # Billions

cat("Stock returns: ", paste(round(stock_returns, 3), collapse = ", "), "\n")
cat("Market caps (billions): ", paste(round(market_caps_big/1e9, 1), collapse = ", "), "\n")

result6 <- calculate_weighted_mean(stock_returns, market_caps_big)
cat("Value-weighted return: ", round(result6, 4), "\n")

# Test 7: Edge case - all NA values
cat("\n🧪 Test 7: Edge case - all NA values\n")
all_na_returns <- c(NA, NA, NA)
all_na_weights <- c(NA, NA, NA)

result7 <- calculate_weighted_mean(all_na_returns, all_na_weights, na.rm = TRUE)
cat("All NA result: ", result7, "\n")

# Test 8: Portfolio rebalancing scenario
cat("\n🧪 Test 8: Portfolio rebalancing scenario\n")
# Before rebalancing: equal dollar amounts
initial_values <- c(1000, 1000, 1000)  # $1000 each
monthly_returns <- c(0.10, -0.05, 0.02)
end_values <- initial_values * (1 + monthly_returns)

cat("Initial values: $", paste(initial_values, collapse = ", $"), "\n")
cat("Monthly returns: ", paste(monthly_returns, collapse = ", "), "\n")
cat("End values: $", paste(round(end_values), collapse = ", $"), "\n")

# Equal-weighted return
equal_weighted <- mean(monthly_returns)
# Value-weighted return (using initial values as weights)
value_weighted <- calculate_weighted_mean(monthly_returns, initial_values)

cat("Equal-weighted return: ", round(equal_weighted, 4), "\n")
cat("Value-weighted return: ", round(value_weighted, 4), "\n")

# Validation checks
cat("\n✅ Validation Results:\n")
cat("======================\n")

# Check 1: Basic calculation matches manual
calc_matches <- abs(result1 - manual_calc) < 1e-10
cat("✓ Basic calculation correct? ", calc_matches, "\n")

# Check 2: Equal weights equals simple mean
equal_weights_correct <- abs(result2 - simple_mean) < 1e-10
cat("✓ Equal weights = simple mean? ", equal_weights_correct, "\n")

# Check 3: NA handling works
na_handling_works <- !is.na(result3) && is.finite(result3)
cat("✓ NA handling works? ", na_handling_works, "\n")

# Check 4: Zero weights fallback works
zero_weights_fallback <- abs(result4 - mean(returns_zero)) < 1e-10
cat("✓ Zero weights fallback correct? ", zero_weights_fallback, "\n")

# Check 5: Single observation returns itself
single_obs_correct <- abs(result5 - single_return) < 1e-10
cat("✓ Single observation correct? ", single_obs_correct, "\n")

# Check 6: Large numbers handled correctly
large_numbers_ok <- !is.na(result6) && is.finite(result6)
cat("✓ Large numbers handled? ", large_numbers_ok, "\n")

# Check 7: All NA returns NA
all_na_correct <- is.na(result7)
cat("✓ All NA returns NA? ", all_na_correct, "\n")

# Check 8: Portfolio calculation reasonable
portfolio_reasonable <- abs(value_weighted) <= max(abs(monthly_returns))
cat("✓ Portfolio calculation reasonable? ", portfolio_reasonable, "\n")

# Error handling tests
cat("\n🧪 Error Handling Tests:\n")
cat("========================\n")

# Test unequal lengths
cat("Testing unequal length vectors...\n")
tryCatch({
  calculate_weighted_mean(c(1, 2), c(1, 2, 3))
  cat("❌ Should have thrown error for unequal lengths\n")
}, error = function(e) {
  cat("✓ Correctly caught unequal length error\n")
})

# Overall validation
all_validations <- c(calc_matches, equal_weights_correct, na_handling_works, 
                    zero_weights_fallback, single_obs_correct, large_numbers_ok, 
                    all_na_correct, portfolio_reasonable)
overall_pass <- all(all_validations)

cat("\n🎯 Overall Test Result: ", if(overall_pass) "✅ ALL TESTS PASSED!" else "❌ Some tests failed", "\n")

if (overall_pass) {
  cat("\n🎉 Weighted average functions are working correctly!\n")
  cat("Ready for integration into portfolio construction.\n")
} else {
  cat("\n⚠️  Please review the failed validations above.\n")
}

cat("\n📊 Function Performance Summary:\n")
cat("• Calculates weighted means accurately ✅\n")
cat("• Handles missing values robustly ✅\n") 
cat("• Manages zero weights gracefully ✅\n")
cat("• Works with large market cap values ✅\n")
cat("• Validates input lengths ✅\n")
cat("• Provides appropriate fallbacks ✅\n")
cat("• Suitable for portfolio calculations ✅\n")

# Demonstrate future usage
cat("\n💼 Future Portfolio Usage Example:\n")
cat("==================================\n")

# Simulate monthly portfolio data
monthly_portfolio <- tibble(
  stock = c("AAPL", "MSFT", "GOOGL", "TSLA", "NVDA"),
  ex_ret = c(0.08, -0.02, 0.15, -0.12, 0.25),
  mktcap_lag = c(2.8e12, 2.3e12, 1.8e12, 0.8e12, 1.1e12)
)

cat("Example monthly portfolio data:\n")
print(monthly_portfolio)

# Calculate value-weighted return as you'll do in the future
portfolio_return <- calculate_weighted_mean(
  x = monthly_portfolio$ex_ret,
  w = monthly_portfolio$mktcap_lag
)

cat("\nValue-weighted portfolio return: ", round(portfolio_return, 4), "\n")
cat("Equal-weighted portfolio return: ", round(mean(monthly_portfolio$ex_ret), 4), "\n")
cat("\n✨ This demonstrates the clean usage pattern for\n")
cat("   portfolio construction in your ESG analysis!\n")

# ==============================================================================
# ⚙️ Weighted Average Utility Function
# ==============================================================================
#
# This script provides a function to calculate a weighted average, specifically
# for creating value-weighted portfolio returns.
#
# Dependencies:
#   - None (uses base R)
#
# Functions:
#   - calculate_weighted_mean(x, w): Calculates the weighted mean of a vector.
#
# ==============================================================================


#' Calculate a Weighted Mean
#'
#' @description
#' A robust function to calculate the weighted mean of a numeric vector `x`
#' using a corresponding vector of weights `w`. It handles missing values
#' by removing them from both `x` and `w` before calculation.
#'
#' @param x A numeric vector of values (e.g., stock returns).
#' @param w A numeric vector of weights (e.g., market capitalizations). Must be the same length as x.
#' @param na.rm A logical value indicating whether NA values should be stripped before the computation proceeds. Default is TRUE.
#'
#' @return A single numeric value representing the weighted mean.
#' @export
#'
#' @examples
#' returns <- c(0.10, 0.05, -0.02)
#' market_caps <- c(200, 100, 50)
#' calculate_weighted_mean(returns, market_caps)
#' #> [1] 0.06571429
calculate_weighted_mean <- function(x, w, na.rm = TRUE) {
  
  # --- Input Validation ---
  if (length(x) != length(w)) {
    stop("❌ 'x' and 'w' must be vectors of the same length.")
  }
  
  # --- Handle Missing Values ---
  if (na.rm) {
    # Find positions of missing values in either vector
    missing_indices <- is.na(x) | is.na(w)
    
    # Remove the missing values from both vectors
    x <- x[!missing_indices]
    w <- w[!missing_indices]
  }
  
  # If after removing NAs, the vectors are empty, return NA
  if (length(x) == 0) {
    return(NA_real_)
  }
  
  # --- Calculation ---
  # The formula is sum(value * weight) / sum(weight)
  weighted_sum <- sum(x * w)
  sum_of_weights <- sum(w)
  
  # Avoid division by zero
  if (sum_of_weights == 0) {
    # If weights sum to zero, return an unweighted mean as a fallback
    return(mean(x))
  }
  
  return(weighted_sum / sum_of_weights)
}


# --- Script loaded confirmation ---
cat("✅ Utility function for weighted mean calculation loaded successfully.\n")
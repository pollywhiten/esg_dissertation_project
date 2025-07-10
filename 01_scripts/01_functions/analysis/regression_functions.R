# ==============================================================================
# ⚙️ Regression Utility Functions
# ==============================================================================
#
# This script provides a flexible function to run linear regressions (OLS)
# with various standard error calculations (standard, robust HC1, clustered).
# It standardizes the regression process for both portfolio-level analysis
# and firm-level panel analysis.
#
# Dependencies:
#   - lmtest (for coeftest)
#   - sandwich (for vcovHC and vcovCL)
#
# Functions:
#   - run_regression_model(data, formula_str, se_type, cluster_var): Runs OLS and calculates SEs.
#
# ==============================================================================

# Ensure necessary packages are loaded
if (!requireNamespace("lmtest", quietly = TRUE)) {
  stop("📦 Package 'lmtest' is required for robust standard errors.")
}
if (!requireNamespace("sandwich", quietly = TRUE)) {
  stop("📦 Package 'sandwich' is required for robust/clustered covariance matrices.")
}

#' Run a Linear Regression Model with Flexible Standard Errors
#'
#' @description
#' Fits an OLS model based on a formula string and calculates standard errors
#' according to the specified type (standard, robust HC1, or clustered).
#'
#' @param data The dataframe containing the regression variables.
#' @param formula_str A string representing the regression formula (e.g., "y ~ x1 + x2").
#' @param se_type Type of standard error: "standard", "robust" (HC1), or "clustered".
#' @param cluster_var (Optional) The name of the variable (string) to cluster by if se_type is "clustered".
#'
#' @return A summary object from lmtest::coeftest (or base summary if standard SE).
#' @export
run_regression_model <- function(data, formula_str, se_type = "robust", cluster_var = NULL) {
  
  # Convert the string formula to an R formula object
  formula <- as.formula(formula_str)
  
  # --- Input Validation ---
  if (!se_type %in% c("standard", "robust", "clustered")) {
    stop("❌ Invalid se_type. Choose 'standard', 'robust', or 'clustered'.")
  }
  
  if (se_type == "clustered" && is.null(cluster_var)) {
    stop("❌ se_type is 'clustered', but cluster_var is not provided.")
  }
  
  # --- Fit the OLS Model ---
  # lm() automatically handles NA values in the data frame (na.action=na.omit by default)
  model_fit <- lm(formula, data = data)
  
  # --- Calculate Standard Errors ---
  
  if (se_type == "standard") {
    # Use standard OLS summary
    model_summary <- summary(model_fit)
    
  } else if (se_type == "robust") {
    # Calculate Robust (HC1) covariance matrix
    robust_cov <- sandwich::vcovHC(model_fit, type = "HC1")
    # Apply the robust covariance matrix to get the summary
    model_summary <- lmtest::coeftest(model_fit, vcov. = robust_cov)
    
  } else if (se_type == "clustered") {
    # Ensure the cluster variable aligns with the data actually used by lm() after NA removal
    # We need to find the subset of the original data that lm used.
    
    # Get the row names (indices) used in the fitted model
    model_indices <- rownames(model.frame(model_fit))
    
    # Extract the corresponding cluster variable values from the original data
    # We use the original 'data' dataframe and match by the indices used by lm()
    cluster_data <- data[model_indices, cluster_var]
    
    # Check if we have enough clusters and observations per cluster
    n_clusters <- length(unique(cluster_data))
    if (n_clusters < 3) {
      warning("⚠️ Very few clusters (", n_clusters, "). Consider using robust SEs instead.")
    }
    
    # Calculate Clustered covariance matrix
    clustered_cov <- sandwich::vcovCL(model_fit, cluster = cluster_data)
    # Apply the clustered covariance matrix
    model_summary <- lmtest::coeftest(model_fit, vcov. = clustered_cov)
  }
  
  # Return the summary object
  return(model_summary)
}

#' Extract Regression Results in Clean Format
#'
#' @description
#' Extracts key regression results (coefficients, standard errors, t-statistics, p-values)
#' from a regression summary object and returns them in a clean tibble format.
#'
#' @param reg_summary A summary object from run_regression_model().
#' @param model_name Optional name for the model (e.g., "FF3", "Carhart", "Panel").
#'
#' @return A tibble with columns: variable, estimate, std_error, t_stat, p_value, model_name.
#' @export
extract_regression_results <- function(reg_summary, model_name = "Model") {
  
  # Handle both coeftest and summary.lm objects
  if ("coeftest" %in% class(reg_summary)) {
    # Extract from coeftest object (robust/clustered SEs)
    results_df <- tibble(
      variable = rownames(reg_summary),
      estimate = reg_summary[, "Estimate"],
      std_error = reg_summary[, "Std. Error"],
      t_stat = reg_summary[, "t value"],
      p_value = reg_summary[, "Pr(>|t|)"],
      model_name = model_name
    )
  } else if ("summary.lm" %in% class(reg_summary)) {
    # Extract from summary.lm object (standard SEs)
    coef_matrix <- reg_summary$coefficients
    results_df <- tibble(
      variable = rownames(coef_matrix),
      estimate = coef_matrix[, "Estimate"],
      std_error = coef_matrix[, "Std. Error"],
      t_stat = coef_matrix[, "t value"],
      p_value = coef_matrix[, "Pr(>|t|)"],
      model_name = model_name
    )
  } else {
    stop("❌ Unsupported summary object type.")
  }
  
  return(results_df)
}

#' Run Common ESG Regression Models
#'
#' @description
#' Convenience wrapper functions for the three main regression types used in ESG analysis.
#' These functions standardize the specific formulas and SE types for each analysis.
#'
#' @param data The dataframe containing the regression variables.
#' @param custom_controls Optional string of additional control variables to add to the formula.
#'
#' @return A summary object from run_regression_model().
#' @export

# Fama-French 3-Factor Model for Portfolio Analysis
run_ff3_model <- function(data, custom_controls = NULL) {
  base_formula <- "port_ex_ret ~ mkt_rf + smb + hml"
  if (!is.null(custom_controls)) {
    formula_str <- paste(base_formula, "+", custom_controls)
  } else {
    formula_str <- base_formula
  }
  
  return(run_regression_model(data, formula_str, se_type = "robust"))
}

# Carhart 4-Factor Model for Portfolio Analysis  
run_carhart_model <- function(data, custom_controls = NULL) {
  base_formula <- "port_ex_ret ~ mkt_rf + smb + hml + mom"
  if (!is.null(custom_controls)) {
    formula_str <- paste(base_formula, "+", custom_controls)
  } else {
    formula_str <- base_formula
  }
  
  return(run_regression_model(data, formula_str, se_type = "robust"))
}

# Panel Regression for Policy Analysis
run_panel_policy_model <- function(data, cluster_var = "cusip8", custom_controls = NULL) {
  base_formula <- "ex_ret ~ Downgrade_Event + Strong_Policy + Interaction_Term + mkt_rf + smb + hml + mom"
  if (!is.null(custom_controls)) {
    formula_str <- paste(base_formula, "+", custom_controls)
  } else {
    formula_str <- base_formula
  }
  
  return(run_regression_model(data, formula_str, se_type = "clustered", cluster_var = cluster_var))
}

# --- Script loaded confirmation ---
cat("✅ Regression utility functions loaded successfully:\n")
cat("   • run_regression_model() - Flexible regression with multiple SE types\n")
cat("   • extract_regression_results() - Clean results extraction\n")
cat("   • run_ff3_model() - Fama-French 3-Factor convenience function\n")
cat("   • run_carhart_model() - Carhart 4-Factor convenience function\n")
cat("   • run_panel_policy_model() - Panel regression convenience function\n")
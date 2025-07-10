# ==============================================================================
# ⚙️ Panel Construction Utility Function (Corrected)
# ==============================================================================
#
# This script provides a function to create a complete, dense monthly panel
# from sparse time-series data.
#
# ==============================================================================

# Source dependencies
source(here::here("01_scripts", "01_functions", "data_processing", "forward_fill_functions.R"))
source(here::here("01_scripts", "01_functions", "data_processing", "date_alignment_utils.R"))


#' Create a Dense Monthly Panel from Sparse Data (Corrected)
#'
#' @description
#' Expands a sparse dataframe to include an observation for every month
#' between the min and max date for each group, then forward-fills the data.
#' This version standardizes dates to the 1st of the month before completing.
#'
#' @param df The input sparse dataframe.
#' @param group_var The column name (string) to group by (e.g., "entityid").
#' @param date_var The column name (string) of the date variable.
#' @param cols_to_fill A character vector of column names to forward-fill.
#'
#' @return A dense monthly panel dataframe with dates on the 1st of each month.
#' @export
create_monthly_panel <- function(df, group_var, date_var, cols_to_fill) {
  
  if (!requireNamespace("dplyr", quietly = TRUE) || !requireNamespace("tidyr", quietly = TRUE)) {
    stop("📦 Packages 'dplyr' and 'tidyr' are required.")
  }

  # --- CORRECTION ---
  # Step 1: Standardize all dates to the first of the month FIRST.
  # This uses the function we already built and tested.
  df_floored <- df %>%
    dplyr::mutate({{date_var}} := floor_to_month_start(!!sym(date_var))) %>%
    # If multiple events happen in the same month, we must aggregate them.
    # We will keep the LAST observation for that month.
    dplyr::group_by(!!sym(group_var), !!sym(date_var)) %>%
    dplyr::slice_tail(n = 1) %>%
    dplyr::ungroup()

  # Step 2: Now complete the sequence using the clean, month-start dates.
  panel_df <- df_floored %>%
    dplyr::group_by(!!sym(group_var)) %>%
    tidyr::complete(
      !!sym(date_var) := seq.Date(min(!!sym(date_var)), max(!!sym(date_var)), by = "month")
    ) %>%
    dplyr::ungroup() %>%
    # Step 3: Forward-fill the data
    ffill_within_group(group_var, cols_to_fill)
    
  cat(sprintf("✓ Panel created for group '%s'. Original rows: %d, New rows: %d\n", 
              group_var, nrow(df), nrow(panel_df)))
  
  return(panel_df)
}

# --- Script loaded confirmation ---
cat("✅ Utility function for panel construction loaded successfully.\n")
# ==============================================================================
# ⚙️ Forward-Fill Utility Function
# ==============================================================================
#
# This script provides a standardized function for forward-filling (carrying the
# last observation forward) missing values (NA) within groups. This is
# essential for creating dense panels from sparse data.
#
# Dependencies:
#   - tidyverse (for dplyr's group_by and mutate)
#   - zoo (for na.locf function)
#
# Functions:
#   - ffill_within_group(df, group_var, cols_to_fill): Fills NAs within groups.
#
# ==============================================================================


#' Forward-Fill Missing Values Within a Group
#'
#' @description
#' Takes a dataframe, groups it by a specified variable (e.g., company id),
#' and then applies forward-filling to one or more specified columns.
#'
#' @param df The input dataframe.
#' @param group_var The column name (as a string) to group the data by (e.g., "entityid").
#' @param cols_to_fill A character vector of column names to be forward-filled.
#'
#' @return A dataframe with the specified columns forward-filled within each group.
#' @export
#'
#' @examples
#' test_df <- tibble::tribble(
#'   ~id, ~year, ~value,
#'   "A", 2020, 10,
#'   "A", 2021, NA,
#'   "A", 2022, 20,
#'   "B", 2020, 100,
#'   "B", 2021, NA,
#'   "B", 2022, NA
#' )
#' ffill_within_group(test_df, "id", "value")
#' #> Expected output for 'value' column: 10, 10, 20, 100, 100, 100
ffill_within_group <- function(df, group_var, cols_to_fill) {
  
  # Ensure necessary packages are available
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("📦 Package 'dplyr' is required for grouping.")
  }
  if (!requireNamespace("zoo", quietly = TRUE)) {
    stop("📦 Package 'zoo' is required for na.locf().")
  }
  
  # The 'group_by' and 'mutate' combination from dplyr is perfect for this
  # We use across() to apply the same function to multiple columns
  filled_df <- df %>%
    dplyr::group_by(!!sym(group_var)) %>%
    dplyr::mutate(
      dplyr::across(
        .cols = all_of(cols_to_fill),
        .fns = ~ zoo::na.locf(.x, na.rm = FALSE)
      )
    ) %>%
    dplyr::ungroup() # It's good practice to ungroup after the operation
  
  return(filled_df)
}

# --- Script loaded confirmation ---
cat("✅ Utility function for forward-filling loaded successfully.\n")
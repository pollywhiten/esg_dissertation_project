# ==============================================================================
# ⚙️ Date Alignment Utility Functions
# ==============================================================================
#
# This script provides standardized functions for common date operations,
# such as aligning dates to the start or end of the month. This ensures
# consistency across all data sources (e.g., CRSP, Fama-French).
#
# Dependencies:
#   - tidyverse (for lubridate)
#
# Functions:
#   - floor_to_month_start(date_vector): Floors dates to the 1st of the month.
#   - ceiling_to_month_end(date_vector): Ceilings dates to the last day of the month.
#
# ==============================================================================


#' Floor a Date Vector to the First Day of the Month
#'
#' @description
#' Takes a vector of dates and standardizes them to the first day of their
#' respective month. This is useful for aligning event dates like those in Sustainalytics.
#'
#' @param date_vector A vector of Date, POSIXct, or character objects that can be parsed as dates.
#'
#' @return A Date vector with all dates set to the first of the month.
#' @export
#'
#' @examples
#' dates <- as.Date(c("2023-01-15", "2023-02-28", "2023-03-01"))
#' floor_to_month_start(dates)
#' #> [1] "2023-01-01" "2023-02-01" "2023-03-01"
floor_to_month_start <- function(date_vector) {
  
  # Ensure lubridate is available for date functions
  if (!requireNamespace("lubridate", quietly = TRUE)) {
    stop("📦 Package 'lubridate' is required but not installed.")
  }
  
  # Parse the input to Date objects, then floor to the month start
  clean_dates <- lubridate::as_date(date_vector)
  floored_dates <- lubridate::floor_date(clean_dates, unit = "month")
  
  return(floored_dates)
}


#' Ceilings a Date Vector to the Last Day of the Month
#'
#' @description
#' Takes a vector of dates and standardizes them to the last calendar day of their
#' respective month. This is the standard convention for CRSP and Fama-French data.
#'
#' @param date_vector A vector of Date, POSIXct, or character objects that can be parsed as dates.
#'
#' @return A Date vector with all dates set to the last day of the month.
#' @export
#'
#' @examples
#' dates <- as.Date(c("2023-01-15", "2023-02-10", "2024-02-15"))
#' ceiling_to_month_end(dates)
#' #> [1] "2023-01-31" "2023-02-28" "2024-02-29"
ceiling_to_month_end <- function(date_vector) {
  
  # Ensure lubridate is available
  if (!requireNamespace("lubridate", quietly = TRUE)) {
    stop("📦 Package 'lubridate' is required but not installed.")
  }
  
  # Parse the input to Date objects
  clean_dates <- lubridate::as_date(date_vector)
  
  # Use ceiling_date to get the first day of the *next* month, then subtract one day
  # This correctly handles all month lengths, including leap years.
  ceilinged_dates <- lubridate::ceiling_date(clean_dates, unit = "month") - lubridate::days(1)
  
  return(ceilinged_dates)
}

# --- Script loaded confirmation ---
# This message will print to the console when the script is sourced successfully.
# It's a good practice for debugging and tracking progress in master scripts.
cat("✅ Utility functions for date alignment loaded successfully.\n")
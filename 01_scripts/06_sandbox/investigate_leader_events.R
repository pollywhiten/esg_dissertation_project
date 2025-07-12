# ==============================================================================
# 🕵️‍♂️ Sandbox: Investigate Why There Are No "Leader" Events
# ==============================================================================
#
# This script is for debugging and exploration. It performs a deep dive to
# understand why the Leaders vs. Laggards analysis found no events for
# firms classified as "Leaders".
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
# We don't need the full config, just the libraries.
library(tidyverse)
library(lubridate)
library(here) # To make paths work correctly

cat("--- Starting Investigation: Why no 'Leader' events? ---\n\n")


# --- 2. LOAD KEY DATASETS ---
# ==============================================================================
cat("📂 Loading final panel and raw events data...\n")

final_df <- readRDS(here("00_data", "cleaned", "final_analytical_panel.rds"))
events <- readRDS(here("00_data", "intermediate", "events", "rating_change_events_flagged.rds"))
sustainalytics_ref <- readRDS(here("00_data", "cleaned", "sustainalytics_ref_clean.rds"))

# Add cusip8 to events for joining
cusip_map <- final_df %>% distinct(entity_id, cusip8)
events <- events %>% left_join(cusip_map, by = "entity_id") %>% filter(!is.na(cusip8))

cat("✅ Data loaded.\n\n")


# --- 3. FIND A POTENTIAL "LEADER" FIRM ---
# ==============================================================================
cat("🔍 Step 1: Find a firm that is sometimes a 'Leader' and also has a rating change.\n")

# First, find firms that have at least one rating of "Low" or "Negligible"
leader_firms_cusip <- final_df %>%
  filter(esg_risk_category %in% c("Low", "Negligible")) %>%
  distinct(cusip8)

# Now, find which of these leader firms ALSO appear in our events list
leader_firms_with_events <- events %>%
  filter(cusip8 %in% leader_firms_cusip$cusip8)

if (nrow(leader_firms_with_events) == 0) {
  cat("--> ❗ No firms were found that were ever a 'Leader' AND had a rating change.\n")
  cat("--> This is the primary reason. The two populations do not overlap.\n")
} else {
  # If we found some, let's pick one to investigate
  sample_cusip <- first(leader_firms_with_events$cusip8)
  sample_event_date <- first(leader_firms_with_events$field_date)
  
  cat(sprintf("--> ✅ Found potential candidate firm! Investigating CUSIP8: %s\n", sample_cusip))
  cat(sprintf("--> This firm had a rating change on: %s\n\n", as.character(sample_event_date)))
  
  
  # --- 4. TRACE THE DATA FOR THE SAMPLE FIRM ---
  # ==============================================================================
  cat(sprintf("🕵️‍♂️ Step 2: Trace the data for CUSIP8 %s around the event date %s.\n", sample_cusip, sample_event_date))
  
  # Get the full time-series for this one firm from our final panel
  firm_data <- final_df %>%
    filter(cusip8 == sample_cusip) %>%
    arrange(date)
    
  # Manually create the lagged column just for this firm
  firm_data_with_lag <- firm_data %>%
    mutate(prev_rating_numeric = lag(esg_risk_category_numeric, 1))
    
  # Find the row for the event date and the month before it
  event_month_end <- ceiling_date(sample_event_date, "month") - days(1)
  start_window <- event_month_end %m-% months(2)
  end_window <- event_month_end %m+% months(1)
  
  event_window_df <- firm_data_with_lag %>%
    filter(date >= start_window & date <= end_window) %>%
    select(cusip8, date, esg_risk_category_numeric, prev_rating_numeric)
    
  cat("\n--- Data for the 2 months BEFORE and the month OF the event ---\n")
  print(event_window_df)
  
  cat("\n--- ANALYSIS ---\n")
  event_row <- filter(event_window_df, date == event_month_end)
  
  if (nrow(event_row) > 0) {
    pre_event_rating <- event_row$prev_rating_numeric
    cat(sprintf("On the event date (%s), the value of the PREVIOUS month's rating is: %s\n",
                event_row$date, as.character(pre_event_rating)))
                
    if(is.na(pre_event_rating)){
      cat("--> ❗ The previous month's rating is NA. This happens if there was a gap in the data before the event.\n")
      cat("--> Therefore, the firm is correctly classified as 'Laggard' by default.\n")
    } else if (pre_event_rating > 3) { # Assuming Leader threshold is 3
      cat(sprintf("--> The previous month's rating (%d) is above the Leader threshold.\n", pre_event_rating))
      cat("--> Therefore, the firm is correctly classified as 'Laggard'.\n")
    } else {
      cat(sprintf("--> The previous month's rating (%d) is within the Leader threshold!\n", pre_event_rating))
      cat("--> This would be classified as a 'Leader' event. If this isn't happening, there may be a merge issue.\n")
    }
  } else {
    cat("--> ❗ Could not find the event row in the final panel. This might indicate a data-merge issue.\n")
  }
}
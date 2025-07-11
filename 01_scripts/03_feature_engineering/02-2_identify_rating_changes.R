# ==============================================================================
# 🚨 02-2: Identify ESG Rating Changes
# ==============================================================================
# This script identifies when ESG ratings change by comparing each month's
# rating to the previous month. It creates flags for rating changes and
# determines the direction (upgrade vs downgrade).
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("🚨 Starting ESG rating change identification...")

# --- 2. LOAD MONTHLY PANEL DATA ---
# ==============================================================================
log_message("📂 Loading monthly panel data...")

sustainalytics_monthly <- readRDS(file.path(DATA_CLEAN, "sustainalytics_monthly_panel.rds"))

log_message(paste("✅ Loaded data with", format(nrow(sustainalytics_monthly), big.mark = ","), "rows"))

# --- 3. CREATE LAGGED RATING COLUMNS ---
# ==============================================================================
log_message("⏮️  Creating lagged rating columns...")

# Sort by entity and date to ensure proper lagging
sustainalytics_monthly <- sustainalytics_monthly %>%
  arrange(entity_id, field_date) %>%
  group_by(entity_id) %>%
  mutate(
    # Lag the numeric category by 1 month within each entity
    prev_risk_category_numeric = dplyr::lag(esg_risk_category_numeric, 1),
    # Also lag the score for additional analysis
    prev_risk_score = dplyr::lag(esg_risk_score, 1)
  ) %>%
  ungroup()

cat("\n📊 Lagged Variables Created:\n")
cat("===========================\n")
cat("• prev_risk_category_numeric: Previous month's risk category (1-5)\n")
cat("• prev_risk_score: Previous month's ESG risk score\n")

# Check a sample
sample_check <- sustainalytics_monthly %>%
  filter(entity_id == first(entity_id)) %>%
  select(entity_id, field_date, esg_risk_category_numeric, prev_risk_category_numeric) %>%
  head(10)

cat("\n🔍 Sample of lagged data (first entity):\n")
print(sample_check)

# --- 4. IDENTIFY RATING CHANGES ---
# ==============================================================================
log_message("🔄 Identifying rating changes...")

sustainalytics_monthly <- sustainalytics_monthly %>%
  mutate(
    # A change occurs when current != previous AND previous is not NA
    score_change = case_when(
      is.na(prev_risk_category_numeric) ~ 0,  # First observation, no change
      esg_risk_category_numeric != prev_risk_category_numeric ~ 1,
      TRUE ~ 0
    )
  )

# Count changes
total_changes <- sum(sustainalytics_monthly$score_change, na.rm = TRUE)
pct_changes <- round(100 * total_changes / nrow(sustainalytics_monthly), 2)

cat("\n📈 Rating Change Summary:\n")
cat("========================\n")
cat(paste("🔄 Total rating changes identified: ", format(total_changes, big.mark = ","), "\n", sep = ""))
cat(paste("📊 Percentage of observations with changes: ", pct_changes, "%\n", sep = ""))

# --- 5. DETERMINE CHANGE DIRECTION ---
# ==============================================================================
log_message("📈📉 Determining change directions...")

sustainalytics_monthly <- sustainalytics_monthly %>%
  mutate(
    score_direction = case_when(
      score_change == 0 ~ "No Change",
      # Higher numeric = worse rating, so increase = downgrade
      esg_risk_category_numeric > prev_risk_category_numeric ~ "Downgrade",
      esg_risk_category_numeric < prev_risk_category_numeric ~ "Upgrade",
      TRUE ~ "No Change"
    )
  )

# Summary of directions
direction_summary <- sustainalytics_monthly %>%
  count(score_direction) %>%
  mutate(percentage = round(100 * n / sum(n), 2))

cat("\n🎯 Rating Change Direction Summary:\n")
cat("==================================\n")
print(direction_summary)

# --- 6. ANALYZE CHANGE PATTERNS ---
# ==============================================================================
log_message("📊 Analyzing rating change patterns...")

# Monthly distribution of changes
monthly_changes <- sustainalytics_monthly %>%
  filter(score_change == 1) %>%
  mutate(year_month = format(field_date, "%Y-%m")) %>%
  group_by(year_month) %>%
  summarise(
    n_changes = n(),
    n_upgrades = sum(score_direction == "Upgrade"),
    n_downgrades = sum(score_direction == "Downgrade"),
    .groups = 'drop'
  )

# Only proceed with date creation if there are changes
if(nrow(monthly_changes) > 0) {
  monthly_changes <- monthly_changes %>%
    mutate(date = as.Date(paste0(year_month, "-01")))
  
  # Find months with most changes
  top_change_months <- monthly_changes %>%
    arrange(desc(n_changes)) %>%
    head(10)
  
  cat("\n📅 Top 10 Months with Most Rating Changes:\n")
  cat("==========================================\n")
  print(top_change_months %>% select(year_month, n_changes, n_upgrades, n_downgrades))
} else {
  cat("\n📅 No rating changes found in the data.\n")
}

# --- 7. CHANGE MAGNITUDE ANALYSIS ---
# ==============================================================================
log_message("📏 Analyzing change magnitudes...")

# Calculate the size of changes (in category levels)
sustainalytics_monthly <- sustainalytics_monthly %>%
  mutate(
    change_magnitude = case_when(
      score_change == 1 ~ abs(esg_risk_category_numeric - prev_risk_category_numeric),
      TRUE ~ 0
    )
  )

# Magnitude summary
magnitude_summary <- sustainalytics_monthly %>%
  filter(score_change == 1) %>%
  group_by(score_direction, change_magnitude) %>%
  summarise(count = n(), .groups = 'drop') %>%
  mutate(percentage = round(100 * count / sum(count), 2))

cat("\n📏 Change Magnitude Distribution:\n")
cat("=================================\n")
print(magnitude_summary)

# --- 8. ENTITY-LEVEL CHANGE STATISTICS ---
# ==============================================================================
log_message("🏢 Calculating entity-level change statistics...")

entity_change_stats <- sustainalytics_monthly %>%
  group_by(entity_id) %>%
  summarise(
    total_months = n(),
    total_changes = sum(score_change),
    n_upgrades = sum(score_direction == "Upgrade"),
    n_downgrades = sum(score_direction == "Downgrade"),
    change_frequency = round(100 * total_changes / total_months, 2),
    .groups = 'drop'
  )

# Summary statistics
cat("\n🏢 Entity-Level Change Statistics:\n")
cat("==================================\n")
cat(paste("• Entities with at least 1 change: ", 
          sum(entity_change_stats$total_changes > 0), " out of ",
          nrow(entity_change_stats), "\n", sep = ""))
cat(paste("• Average changes per entity: ", 
          round(mean(entity_change_stats$total_changes), 2), "\n", sep = ""))
cat(paste("• Max changes for single entity: ", 
          max(entity_change_stats$total_changes), "\n", sep = ""))

# --- 9. SAVE ENHANCED DATASET ---
# ==============================================================================
log_message("💾 Saving dataset with rating change indicators...")

# Select columns to keep (drop intermediate calculation columns)
sustainalytics_changes <- sustainalytics_monthly %>%
  select(-prev_risk_category_numeric, -prev_risk_score)  # Drop the lag columns

# Save to intermediate folder
saveRDS(sustainalytics_changes,
        file.path(DATA_INTER_ESG, "sustainalytics_with_changes.rds"))

# --- 10. CREATE CHANGE EVENT FILE ---
# ==============================================================================
log_message("📋 Creating rating change event file...")

# Extract just the change events for easy reference
rating_change_events <- sustainalytics_changes %>%
  filter(score_change == 1) %>%
  select(entity_id, field_date, esg_risk_category, esg_risk_category_numeric,
         score_direction, change_magnitude) %>%
  arrange(field_date, entity_id)

# Save the events file
saveRDS(rating_change_events,
        file.path(DATA_INTER_EVT, "rating_change_events.rds"))

cat("\n📋 Rating Change Events File Created:\n")
cat("====================================\n")
cat(paste("• Total events: ", format(nrow(rating_change_events), big.mark = ","), "\n", sep = ""))
cat(paste("• Date range: ", min(rating_change_events$field_date), " to ",
          max(rating_change_events$field_date), "\n", sep = ""))

# --- 11. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   RATING CHANGE IDENTIFICATION COMPLETE!      \n")
cat("============================================== \n")
cat("\n📊 Final Summary:\n")
cat("-----------------\n")
cat(paste("✅ Total observations processed: ", format(nrow(sustainalytics_changes), big.mark = ","), "\n", sep = ""))
cat(paste("🔄 Total rating changes: ", format(total_changes, big.mark = ","), "\n", sep = ""))
cat(paste("📈 Upgrades: ", sum(sustainalytics_changes$score_direction == "Upgrade"), "\n", sep = ""))
cat(paste("📉 Downgrades: ", sum(sustainalytics_changes$score_direction == "Downgrade"), "\n", sep = ""))
cat(paste("🏢 Entities with changes: ", sum(entity_change_stats$total_changes > 0), "\n", sep = ""))

log_message("✅ Script 02-2 completed successfully!")

# --- END OF SCRIPT ---
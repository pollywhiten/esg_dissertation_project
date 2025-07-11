# ==============================================================================
# 🎯 02-4: Create Event Windows for Portfolio Analysis
# ==============================================================================
# This script creates 12-month holding period windows for each rating change
# event. These windows define when a stock enters and exits the portfolio
# following an ESG rating change.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("🎯 Starting event window creation...")

# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📂 Loading rating change events...")

# Load the main dataset with changes and bulk flags
sustainalytics_full <- readRDS(file.path(DATA_INTER_ESG, "sustainalytics_with_bulk_flags.rds"))

# Load the events file
rating_events <- readRDS(file.path(DATA_INTER_EVT, "rating_change_events_flagged.rds"))

log_message(paste("✅ Loaded", format(nrow(rating_events), big.mark = ","), 
                  "rating change events"))

# --- 3. CREATE EVENT WINDOWS ---
# ==============================================================================
log_message("🪟 Creating event windows...")

# For each rating change event, define entry and exit dates
event_windows <- rating_events %>%
  rename(
    entry_date = field_date,
    event_direction = score_direction
  ) %>%
  mutate(
    # Exit date is 12 months after the event (as per HOLDING_PERIOD_MONTHS)
    exit_date = entry_date %m+% months(HOLDING_PERIOD_MONTHS),
    # Create a unique event ID for tracking
    event_id = row_number()
  ) %>%
  select(event_id, entity_id, entry_date, exit_date, event_direction, 
         esg_risk_category, change_magnitude, bulk_update)

# Summary of event windows
cat("\n📊 Event Window Summary:\n")
cat("=======================\n")
cat(paste("📅 Total event windows created: ", format(nrow(event_windows), big.mark = ","), "\n", sep = ""))
cat(paste("📈 Upgrade events: ", sum(event_windows$event_direction == "Upgrade"), "\n", sep = ""))
cat(paste("📉 Downgrade events: ", sum(event_windows$event_direction == "Downgrade"), "\n", sep = ""))
cat(paste("🏷️ Bulk update events: ", sum(event_windows$bulk_update == 1), "\n", sep = ""))

# --- 4. ANALYZE HOLDING PERIOD OVERLAPS ---
# ==============================================================================
log_message("🔄 Analyzing holding period overlaps...")

# Check for overlapping events within the same entity
entity_overlaps <- event_windows %>%
  group_by(entity_id) %>%
  arrange(entry_date) %>%
  mutate(
    prev_exit_date = lag(exit_date),
    has_overlap = ifelse(is.na(prev_exit_date), FALSE, entry_date < prev_exit_date)
  ) %>%
  filter(!is.na(prev_exit_date))  # Only look at events that have a previous event

n_overlaps <- sum(entity_overlaps$has_overlap, na.rm = TRUE)
entities_with_overlaps <- length(unique(entity_overlaps$entity_id[entity_overlaps$has_overlap]))

cat("\n🔄 Overlap Analysis:\n")
cat("====================\n")
cat(paste("📊 Events with overlapping periods: ", n_overlaps, "\n", sep = ""))
cat(paste("🏢 Entities with overlaps: ", entities_with_overlaps, "\n", sep = ""))
cat(paste("📈 % of events that overlap: ", 
          round(100 * n_overlaps / nrow(event_windows), 2), "%\n", sep = ""))

# --- 5. CREATE MONTHLY PORTFOLIO MEMBERSHIP ---
# ==============================================================================
log_message("📅 Creating monthly portfolio membership indicators...")

# Get all unique months in our data range
all_months <- seq(
  from = floor_date(min(sustainalytics_full$field_date), "month"),
  to = ceiling_date(max(sustainalytics_full$field_date), "month") - days(1),
  by = "month"
)

# For efficiency, we'll create a summary of active events by month
# This avoids the massive expansion of the Python approach
monthly_active_events <- map_df(all_months, function(month_date) {
  active_events <- event_windows %>%
    filter(entry_date <= month_date & exit_date > month_date) %>%
    mutate(portfolio_month = month_date)
  return(active_events)
})

# Summary by month
monthly_summary <- monthly_active_events %>%
  group_by(portfolio_month, event_direction) %>%
  summarise(
    n_stocks = n_distinct(entity_id),
    n_events = n(),
    .groups = 'drop'
  ) %>%
  pivot_wider(
    names_from = event_direction,
    values_from = c(n_stocks, n_events),
    values_fill = 0
  )

cat("\n📈 Monthly Portfolio Size Preview:\n")
cat("==================================\n")
print(monthly_summary %>% 
      tail(12) %>%
      select(portfolio_month, n_stocks_Upgrade, n_stocks_Downgrade))

# --- 6. CREATE PORTFOLIO FLAGS ---
# ==============================================================================
log_message("🚩 Creating portfolio membership flags...")

# Create a more efficient version that marks portfolio membership
# For each entity-month, check if it's in any active window
portfolio_membership <- sustainalytics_full %>%
  select(entity_id, field_date) %>%
  left_join(
    monthly_active_events %>%
      select(entity_id, portfolio_month, event_id, event_direction) %>%
      rename(field_date = portfolio_month),
    by = c("entity_id", "field_date"),
    relationship = "many-to-many"  # Handle multiple events
  ) %>%
  mutate(
    in_portfolio = !is.na(event_id),
    portfolio_direction = ifelse(is.na(event_direction), "None", event_direction)
  ) %>%
  # Handle multiple events by keeping the most recent
  group_by(entity_id, field_date) %>%
  slice_max(event_id, n = 1, with_ties = FALSE) %>%
  ungroup()

# Merge back to main dataset
sustainalytics_portfolio <- sustainalytics_full %>%
  left_join(
    portfolio_membership %>% 
      select(entity_id, field_date, in_portfolio, portfolio_direction, event_id),
    by = c("entity_id", "field_date")
  ) %>%
  mutate(
    in_portfolio = replace_na(in_portfolio, FALSE),
    portfolio_direction = replace_na(portfolio_direction, "None")
  )

# Verify portfolio creation
portfolio_stats <- sustainalytics_portfolio %>%
  filter(in_portfolio) %>%
  group_by(portfolio_direction) %>%
  summarise(
    n_observations = n(),
    n_entities = n_distinct(entity_id),
    n_months = n_distinct(field_date),
    .groups = 'drop'
  )

cat("\n📊 Portfolio Membership Statistics:\n")
cat("==================================\n")
print(portfolio_stats)

# --- 7. ANALYZE PORTFOLIO CHARACTERISTICS ---
# ==============================================================================
log_message("🔍 Analyzing portfolio characteristics...")

# Time series of portfolio sizes
portfolio_timeseries <- sustainalytics_portfolio %>%
  filter(in_portfolio) %>%
  group_by(field_date, portfolio_direction) %>%
  summarise(
    n_firms = n_distinct(entity_id),
    .groups = 'drop'
  ) %>%
  pivot_wider(
    names_from = portfolio_direction,
    values_from = n_firms,
    values_fill = 0
  )

# Recent portfolio sizes
cat("\n📊 Recent Portfolio Sizes (last 6 months):\n")
cat("==========================================\n")
print(portfolio_timeseries %>% 
      tail(6) %>%
      mutate(Total = Upgrade + Downgrade))

# --- 8. SAVE PORTFOLIO DATA ---
# ==============================================================================
log_message("💾 Saving portfolio membership data...")

# Save the full dataset with portfolio flags
saveRDS(sustainalytics_portfolio,
        file.path(DATA_INTER_ESG, "sustainalytics_with_portfolios.rds"))

# Save the event windows for reference
saveRDS(event_windows,
        file.path(DATA_INTER_EVT, "event_windows.rds"))

# Save monthly active events summary
saveRDS(monthly_active_events,
        file.path(DATA_INTER_EVT, "monthly_active_events.rds"))

# --- 9. CREATE PORTFOLIO SAMPLE ---
# ==============================================================================
log_message("🎲 Creating portfolio sample for verification...")

# Sample some entities with portfolio membership
sample_entities <- sustainalytics_portfolio %>%
  filter(in_portfolio) %>%
  distinct(entity_id) %>%
  sample_n(min(3, n()))

cat("\n🔍 Sample Portfolio Membership (3 entities):\n")
cat("============================================\n")

for (entity in sample_entities$entity_id) {
  entity_data <- sustainalytics_portfolio %>%
    filter(entity_id == entity, in_portfolio) %>%
    select(entity_id, field_date, portfolio_direction, esg_risk_category) %>%
    head(6)
  
  cat(paste("\nEntity", entity, ":\n"))
  print(entity_data)
}

# --- 10. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   EVENT WINDOW CREATION COMPLETE!             \n")
cat("============================================== \n")
cat("\n📊 Final Summary:\n")
cat("-----------------\n")
cat(paste("🎯 Total event windows: ", format(nrow(event_windows), big.mark = ","), "\n", sep = ""))
cat(paste("📅 Holding period: ", HOLDING_PERIOD_MONTHS, " months\n", sep = ""))
cat(paste("📈 Upgrade portfolios: ", sum(event_windows$event_direction == "Upgrade"), "\n", sep = ""))
cat(paste("📉 Downgrade portfolios: ", sum(event_windows$event_direction == "Downgrade"), "\n", sep = ""))
cat(paste("🔄 Events with overlaps: ", n_overlaps, "\n", sep = ""))
cat(paste("📊 Total portfolio observations: ", 
          sum(sustainalytics_portfolio$in_portfolio), "\n", sep = ""))

log_message("✅ Script 02-4 completed successfully!")

# --- END OF SCRIPT ---
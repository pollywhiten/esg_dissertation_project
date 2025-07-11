# ==============================================================================
# 🏷️ 02-3: Tag Bulk Update Months
# ==============================================================================
# This script identifies months with unusually high numbers of rating changes
# (bulk updates) and creates a flag to distinguish them from individual changes.
# This is important as bulk updates may have different market impact.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
library(ggplot2)  # For the spike visualization

log_message("🏷️ Starting bulk update identification...")

# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📂 Loading data with rating changes...")

sustainalytics_changes <- readRDS(file.path(DATA_INTER_ESG, "sustainalytics_with_changes.rds"))
rating_change_events <- readRDS(file.path(DATA_INTER_EVT, "rating_change_events.rds"))

log_message(paste("✅ Loaded", format(nrow(sustainalytics_changes), big.mark = ","), 
                  "observations with", format(nrow(rating_change_events), big.mark = ","), 
                  "rating change events"))

# --- 3. ANALYZE MONTHLY CHANGE FREQUENCY ---
# ==============================================================================
log_message("📊 Analyzing monthly change frequency...")

# Count changes by month
monthly_changes <- sustainalytics_changes %>%
  filter(score_change == 1) %>%
  group_by(field_date) %>%
  summarise(
    n_changes = n(),
    n_entities = n_distinct(entity_id),
    n_upgrades = sum(score_direction == "Upgrade"),
    n_downgrades = sum(score_direction == "Downgrade"),
    .groups = 'drop'
  ) %>%
  arrange(field_date)

# Calculate summary statistics
mean_changes <- mean(monthly_changes$n_changes)
median_changes <- median(monthly_changes$n_changes)
sd_changes <- sd(monthly_changes$n_changes)

cat("\n📊 Monthly Change Distribution Statistics:\n")
cat("=========================================\n")
cat(paste("📈 Mean changes per month: ", round(mean_changes, 1), "\n", sep = ""))
cat(paste("📊 Median changes per month: ", median_changes, "\n", sep = ""))
cat(paste("📉 Std deviation: ", round(sd_changes, 1), "\n", sep = ""))
cat(paste("🔝 Max changes in a month: ", max(monthly_changes$n_changes), "\n", sep = ""))

# --- 4. IDENTIFY SPIKE MONTHS ---
# ==============================================================================
log_message("🔍 Identifying spike months...")

# Method 1: Using the fixed threshold from config
spike_months_threshold <- monthly_changes %>%
  filter(n_changes > BULK_UPDATE_THRESHOLD) %>%
  arrange(desc(n_changes))

cat(paste("\n🎯 Months with >", BULK_UPDATE_THRESHOLD, " changes:\n", sep = ""))
cat("====================================\n")
if (nrow(spike_months_threshold) > 0) {
  print(spike_months_threshold %>% 
        select(field_date, n_changes, n_upgrades, n_downgrades) %>%
        head(10))
} else {
  cat("No months exceed the threshold.\n")
}

# Method 2: Statistical approach (mean + 2*SD)
statistical_threshold <- mean_changes + 2 * sd_changes
spike_months_statistical <- monthly_changes %>%
  filter(n_changes > statistical_threshold) %>%
  arrange(desc(n_changes))

cat(paste("\n📊 Months with changes > mean + 2*SD (", round(statistical_threshold, 0), "):\n", sep = ""))
cat("=============================================\n")
if (nrow(spike_months_statistical) > 0) {
  print(spike_months_statistical %>% 
        select(field_date, n_changes, n_upgrades, n_downgrades) %>%
        head(10))
}

# Method 3: Top N months approach (as in Python code)
top_spike_months <- monthly_changes %>%
  arrange(desc(n_changes)) %>%
  head(TOP_SPIKE_MONTHS)

cat(paste("\n🏆 Top ", TOP_SPIKE_MONTHS, " spike months:\n", sep = ""))
cat("========================\n")
print(top_spike_months %>% select(field_date, n_changes, n_upgrades, n_downgrades))

# --- 5. CREATE SPIKE VISUALIZATION ---
# ==============================================================================
log_message("📈 Creating spike visualization...")

# Create the plot
spike_plot <- ggplot(monthly_changes, aes(x = field_date, y = n_changes)) +
  geom_line(color = "royalblue", size = 1.2) +
  geom_point(data = top_spike_months, 
             aes(x = field_date, y = n_changes),
             color = "red", size = 3) +
  geom_hline(yintercept = BULK_UPDATE_THRESHOLD, 
             linetype = "dashed", color = "orange", size = 1) +
  geom_hline(yintercept = statistical_threshold,
             linetype = "dotted", color = "darkgreen", size = 1) +
  geom_text(data = top_spike_months,
            aes(x = field_date, y = n_changes, 
                label = format(field_date, "%b %Y")),
            vjust = -1, hjust = 0.5, size = 3, fontface = "bold") +
  labs(
    title = "📊 Frequency of ESG Rating Changes Over Time",
    subtitle = paste("Identifying bulk update months (Top", TOP_SPIKE_MONTHS, "highlighted)"),
    x = "Date",
    y = "Number of Rating Changes",
    caption = paste("Orange dashed line: Fixed threshold (", BULK_UPDATE_THRESHOLD, ")\n",
                   "Green dotted line: Statistical threshold (mean + 2*SD = ", 
                   round(statistical_threshold, 0), ")", sep = "")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.title = element_text(size = 12),
    legend.position = "none"
  )

# Save the plot
ggsave(
  filename = file.path(OUTPUT_FIGURES, "diagnostic", "bulk_update_spikes.png"),
  plot = spike_plot,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)

cat("\n📊 Spike visualization saved to output/figures/diagnostic/\n")

# --- 6. CREATE BULK UPDATE FLAG ---
# ==============================================================================
log_message("🏷️ Creating bulk update flags...")

# Get the list of spike months (using top N approach as in Python)
spike_month_dates <- top_spike_months$field_date

# Add bulk_update flag to main dataset
sustainalytics_changes <- sustainalytics_changes %>%
  mutate(
    bulk_update = as.integer(field_date %in% spike_month_dates)
  )

# Verify the flagging
flagged_changes <- sustainalytics_changes %>%
  filter(bulk_update == 1, score_change == 1) %>%
  nrow()

total_changes <- sum(sustainalytics_changes$score_change)
pct_bulk <- round(100 * flagged_changes / total_changes, 1)

cat("\n🏷️ Bulk Update Flagging Summary:\n")
cat("==================================\n")
cat(paste("📅 Number of bulk update months: ", length(spike_month_dates), "\n", sep = ""))
cat(paste("🔄 Changes in bulk months: ", format(flagged_changes, big.mark = ","), "\n", sep = ""))
cat(paste("📊 % of all changes that are bulk: ", pct_bulk, "%\n", sep = ""))

# --- 7. ANALYZE BULK VS NORMAL UPDATES ---
# ==============================================================================
log_message("🔍 Analyzing bulk vs normal update patterns...")

# Create comparison
update_comparison <- sustainalytics_changes %>%
  filter(score_change == 1) %>%
  group_by(bulk_update) %>%
  summarise(
    n_changes = n(),
    n_upgrades = sum(score_direction == "Upgrade"),
    n_downgrades = sum(score_direction == "Downgrade"),
    pct_upgrades = round(100 * n_upgrades / n_changes, 1),
    .groups = 'drop'
  ) %>%
  mutate(
    update_type = ifelse(bulk_update == 1, "Bulk Update", "Normal Update")
  )

cat("\n📊 Bulk vs Normal Update Comparison:\n")
cat("====================================\n")
print(update_comparison %>% select(update_type, n_changes, pct_upgrades))

# Cross-tabulation (as in Python)
crosstab <- table(sustainalytics_changes$bulk_update, sustainalytics_changes$score_change)
cat("\n📋 Cross-tabulation: Bulk Update vs Score Change:\n")
cat("=================================================\n")
print(addmargins(crosstab))

# --- 8. MONTHLY CHARACTERISTICS ---
# ==============================================================================
log_message("📅 Analyzing characteristics of bulk update months...")

# Get details for spike months
spike_details <- monthly_changes %>%
  filter(field_date %in% spike_month_dates) %>%
  mutate(
    year = lubridate::year(field_date),
    month = lubridate::month(field_date, label = TRUE),
    upgrade_ratio = round(100 * n_upgrades / n_changes, 1)
  )

cat("\n📅 Bulk Update Month Characteristics:\n")
cat("=====================================\n")
print(spike_details %>% 
      select(field_date, n_changes, n_entities, upgrade_ratio) %>%
      arrange(desc(n_changes)))

# --- 9. SAVE ENHANCED DATASET ---
# ==============================================================================
log_message("💾 Saving dataset with bulk update flags...")

# Save the updated dataset
saveRDS(sustainalytics_changes,
        file.path(DATA_INTER_ESG, "sustainalytics_with_bulk_flags.rds"))

# Also update the events file
rating_change_events_flagged <- rating_change_events %>%
  mutate(
    bulk_update = as.integer(field_date %in% spike_month_dates)
  )

saveRDS(rating_change_events_flagged,
        file.path(DATA_INTER_EVT, "rating_change_events_flagged.rds"))

# --- 10. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   BULK UPDATE IDENTIFICATION COMPLETE!        \n")
cat("============================================== \n")
cat("\n📊 Summary:\n")
cat("------------\n")
cat(paste("🏷️ Bulk update months identified: ", length(spike_month_dates), "\n", sep = ""))
cat(paste("📅 Bulk month dates: ", paste(format(spike_month_dates, "%Y-%m"), collapse = ", "), "\n", sep = ""))
cat(paste("🔄 Total changes in bulk months: ", format(flagged_changes, big.mark = ","), "\n", sep = ""))
cat(paste("📊 % of changes that are bulk: ", pct_bulk, "%\n", sep = ""))
cat("\n💡 Tip: Consider running sensitivity analysis with and without bulk updates\n")

log_message("✅ Script 02-3 completed successfully!")

# --- END OF SCRIPT ---
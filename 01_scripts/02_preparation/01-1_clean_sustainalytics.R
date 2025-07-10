# ==============================================================================
# 🧹 01-1: Clean Sustainalytics ESG Data
# ==============================================================================
#
# This script performs the initial cleaning of the raw Sustainalytics data.
# It reads the raw CSV, standardizes names and dates, filters for the
# relevant ESG metrics, and pivots the data from a long to a wide format.
#
# It saves two intermediate files:
# 1. sustainalytics_long.rds: Filtered and date-cleaned long-format data.
# 2. sustainalytics_wide.rds: Pivoted panel with one row per entity-date.
#
# ==============================================================================


# --- 1. SETUP ---
# ==============================================================================

# Source the configuration file to get project paths
source("config.R")

# Load necessary libraries from the central script
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

# Source date utility functions
source(file.path(FUNCTIONS_PATH, "data_processing", "date_alignment_utils.R"))

log_message("--------------------------------------------------")
log_message("Starting script: 01-1_clean_sustainalytics.R")


# --- 2. LOAD RAW DATA ---
# ==============================================================================

log_message("Loading raw Sustainalytics.csv data...")

# Use data.table's fread for speed on this large file
tryCatch({
  sustainalytics_raw <- data.table::fread(file.path(DATA_RAW_ESG, "Sustainalytics.csv"))
  log_message("✅ Raw Sustainalytics data loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load 'Sustainalytics.csv'. Check the file path in config.R.", "ERROR")
  stop(e)
})


# --- 3. INITIAL CLEANING & FILTERING ---
# ==============================================================================

log_message("Performing initial cleaning: standardizing names, dates, and filtering...")

# Define the ESG fields we care about
relevant_fields <- c("ESG Risk Score", "ESG Risk Category")

sustainalytics_long <- sustainalytics_raw %>%
  # Use janitor::clean_names() for consistent snake_case column names
  janitor::clean_names() %>%
  
  # Filter for only the rows with our metrics of interest
  filter(field_name %in% relevant_fields) %>%
  
  # Standardize the date to the 1st of the month using our utility function
  mutate(field_date = floor_to_month_start(field_date)) %>%
  
  # Select only the columns we need for the next step
  select(entity_id, field_date, field_name, field_value)

log_message(paste("Filtered down to", nrow(sustainalytics_long), "relevant observations."))


# --- 4. SAVE INTERMEDIATE LONG-FORMAT DATA ---
# ==============================================================================

# Save the cleaned, long-format data as an .rds file for potential future use
saveRDS(
  sustainalytics_long,
  file = file.path(DATA_INTER_ESG, "sustainalytics_long.rds")
)
log_message("💾 Intermediate file 'sustainalytics_long.rds' saved.")


# --- 5. PIVOT TO WIDE FORMAT ---
# ==============================================================================

log_message("Pivoting data from long to wide format...")

# Separate numeric and categorical data for correct aggregation
sustainalytics_numeric <- sustainalytics_long %>%
  filter(field_name == "ESG Risk Score") %>%
  mutate(field_value = as.numeric(field_value)) %>%
  group_by(entity_id, field_date) %>%
  # If multiple scores exist for a given month, take the mean
  summarise(esg_risk_score = mean(field_value, na.rm = TRUE), .groups = "drop")

sustainalytics_category <- sustainalytics_long %>%
  filter(field_name == "ESG Risk Category") %>%
  group_by(entity_id, field_date) %>%
  # If multiple categories exist, just take the first one
  summarise(esg_risk_category = first(field_value), .groups = "drop")

# Merge them back together to create the wide panel
sustainalytics_wide <- full_join(
  sustainalytics_numeric, 
  sustainalytics_category, 
  by = c("entity_id", "field_date")
)

log_message(paste("Pivoted to a wide panel with", nrow(sustainalytics_wide), "unique entity-month observations."))


# --- 6. SAVE FINAL WIDE-FORMAT DATA ---
# ==============================================================================

saveRDS(
  sustainalytics_wide,
  file = file.path(DATA_INTER_ESG, "sustainalytics_wide.rds")
)
log_message("💾 Intermediate file 'sustainalytics_wide.rds' saved.")
log_message("Script 01-1 finished successfully.")
log_message("--------------------------------------------------")
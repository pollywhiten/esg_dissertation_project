# ==============================================================================
# 📅 02-1: Create Complete Monthly Panels
# ==============================================================================
# This script transforms the sparse ESG rating data into a complete monthly panel.
# For each company, we create a row for every month from its first to last rating,
# then forward-fill the ratings to carry them forward until changed.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "data_processing", "forward_fill_functions.R"))
source(file.path(FUNCTIONS_PATH, "data_processing", "panel_construction.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 02-1_create_monthly_panels.R")
log_message("📅 Starting monthly panel creation...")

# --- 2. LOAD CLEANED DATA ---
# ==============================================================================
log_message("📂 Loading cleaned Sustainalytics data...")

sustainalytics_wide <- readRDS(file.path(DATA_INTER_ESG, "sustainalytics_wide.rds"))

log_message(paste("✅ Loaded data with", nrow(sustainalytics_wide), "rows and", 
                  length(unique(sustainalytics_wide$entity_id)), "unique entities"))

# --- 3. CREATE COMPLETE MONTHLY PANELS ---
# ==============================================================================
log_message("🔨 Creating dense monthly panels for each entity...")

# Track progress
total_entities <- length(unique(sustainalytics_wide$entity_id))
start_time <- Sys.time()

# We'll use our panel construction function to create complete monthly series
# The function handles each entity separately and creates a full monthly timeline
sustainalytics_monthly <- create_monthly_panel(
  df = sustainalytics_wide,
  group_var = "entity_id",
  date_var = "field_date",
  cols_to_fill = c("esg_risk_score", "esg_risk_category")
)

end_time <- Sys.time()
duration <- round(difftime(end_time, start_time, units = "secs"), 2)

log_message(paste("⏱️  Panel creation completed in", duration, "seconds"))

# --- 4. DATA QUALITY CHECKS ---
# ==============================================================================
log_message("🔍 Performing data quality checks...")

# Check 1: Expansion factor
original_rows <- nrow(sustainalytics_wide)
panel_rows <- nrow(sustainalytics_monthly)
expansion_factor <- round(panel_rows / original_rows, 2)

cat("\n📊 Panel Expansion Summary:\n")
cat("==========================\n")
cat(paste("Original sparse data: ", format(original_rows, big.mark = ","), " rows\n", sep = ""))
cat(paste("Complete monthly panel: ", format(panel_rows, big.mark = ","), " rows\n", sep = ""))
cat(paste("Expansion factor: ", expansion_factor, "x\n", sep = ""))

# Check 2: Coverage by entity
coverage_summary <- sustainalytics_monthly %>%
  group_by(entity_id) %>%
  summarise(
    months_covered = n(),
    first_date = min(field_date),
    last_date = max(field_date),
    has_score = sum(!is.na(esg_risk_score)),
    has_category = sum(!is.na(esg_risk_category)),
    .groups = 'drop'
  )

cat("\n📈 Entity Coverage Statistics:\n")
cat("=============================\n")
cat(paste("Entities with data: ", format(nrow(coverage_summary), big.mark = ","), "\n", sep = ""))
cat(paste("Average months per entity: ", round(mean(coverage_summary$months_covered), 1), "\n", sep = ""))
cat(paste("Min months: ", min(coverage_summary$months_covered), "\n", sep = ""))
cat(paste("Max months: ", max(coverage_summary$months_covered), "\n", sep = ""))

# Check 3: Forward-fill verification
# Sample a few entities to verify forward-filling worked correctly
sample_entities <- sample(unique(sustainalytics_monthly$entity_id), 3)

cat("\n🔍 Forward-Fill Verification (3 sample entities):\n")
cat("================================================\n")

for (entity in sample_entities) {
  entity_data <- sustainalytics_monthly %>%
    filter(entity_id == entity) %>%
    arrange(field_date) %>%
    head(6)
  
  cat(paste("\nEntity", entity, "- First 6 months:\n"))
  print(entity_data %>% select(field_date, esg_risk_score, esg_risk_category))
}

# --- 5. CONVERT CATEGORY TO NUMERIC ---
# ==============================================================================
log_message("🔢 Creating numeric ESG risk category mapping...")

# Define the mapping (same as Python)
category_mapping <- c(
  "Negligible" = 1,
  "Low" = 2,
  "Medium" = 3,
  "High" = 4,
  "Severe" = 5
)

# Apply the mapping
sustainalytics_monthly <- sustainalytics_monthly %>%
  mutate(
    esg_risk_category_numeric = category_mapping[as.character(esg_risk_category)]
  )

# Verify the mapping
cat("\n🏷️  ESG Risk Category Mapping:\n")
cat("==============================\n")
mapping_check <- sustainalytics_monthly %>%
  filter(!is.na(esg_risk_category)) %>%
  distinct(esg_risk_category, esg_risk_category_numeric) %>%
  arrange(esg_risk_category_numeric)

print(mapping_check)

# --- 6. SAVE COMPLETE MONTHLY PANEL ---
# ==============================================================================
log_message("💾 Saving complete monthly panel...")

# Save the intermediate file
saveRDS(sustainalytics_monthly, 
        file.path(DATA_INTER_ESG, "sustainalytics_monthly_panel.rds"))

# Also save a cleaned version in the main cleaned folder
saveRDS(sustainalytics_monthly,
        file.path(DATA_CLEAN, "sustainalytics_monthly_panel.rds"))

# --- 7. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ========================================== 🎉\n")
cat("   MONTHLY PANEL CREATION COMPLETE!           \n")
cat("============================================== \n")
cat("\n📊 Final Dataset Summary:\n")
cat("------------------------\n")
cat(paste("• Total rows: ", format(nrow(sustainalytics_monthly), big.mark = ","), "\n", sep = ""))
cat(paste("• Unique entities: ", format(length(unique(sustainalytics_monthly$entity_id)), big.mark = ","), "\n", sep = ""))
cat(paste("• Date range: ", min(sustainalytics_monthly$field_date), " to ", 
          max(sustainalytics_monthly$field_date), "\n", sep = ""))
cat(paste("• Columns: ", paste(names(sustainalytics_monthly), collapse = ", "), "\n", sep = ""))

# Memory usage
object_size <- format(object.size(sustainalytics_monthly), units = "MB")
cat(paste("\n💾 Memory usage: ", object_size, "\n", sep = ""))

log_message("✅ Script 02-1 completed successfully!")
log_message("--------------------------------------------------")

# --- END OF SCRIPT ---
# ==============================================================================
# 🧹 01-4: Clean Fama-French and Momentum Factors
# ==============================================================================
#
# This script loads and cleans the two separate factor files from the
# Kenneth French Data Library: the 3-factor file and the momentum factor file.
# It parses the non-standard text format, standardizes column names and dates,
# converts percentages to decimals, and merges them into a single, clean
# 4-factor dataset.
#
# ==============================================================================


# --- 1. SETUP ---
# ==============================================================================

source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "data_processing", "date_alignment_utils.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 01-4_clean_ff_factors.R")


# --- 2. CLEAN FAMA-FRENCH 3-FACTOR FILE ---
# ==============================================================================

log_message("📊 Processing Fama-French 3-Factor file...")

tryCatch({
  # Find the line where the actual data starts by looking for the first all-numeric row
  ff3_lines <- read_lines(file.path(DATA_RAW_FIN, "F-F_Research_Data_Factors.csv"))
  data_start_line <- which(str_detect(ff3_lines, "^[0-9]{6},"))[1]
  
  # Read the CSV, skipping the header rows
  ff3_raw <- read_csv(
    file.path(DATA_RAW_FIN, "F-F_Research_Data_Factors.csv"),
    skip = data_start_line - 1,
    col_names = c("yyyymm", "mkt_rf", "smb", "hml", "rf"),
    show_col_types = FALSE
  )
  
  ff3_clean <- ff3_raw %>%
    # Filter to keep only monthly data (6-digit YYYYMM format)
    filter(str_detect(yyyymm, "^[0-9]{6}$")) %>%
    # Convert factors from percent to decimal
    mutate(across(c(mkt_rf, smb, hml, rf), ~ . / 100)) %>%
    # Create the month-end date
    mutate(date = ymd(paste0(yyyymm, "01"))) %>%
    mutate(date = ceiling_to_month_end(date)) %>%
    # Remove rows with invalid dates
    filter(!is.na(date)) %>%
    select(date, mkt_rf, smb, hml, rf) %>%
    # Ensure unique dates
    distinct(date, .keep_all = TRUE)
    
  log_message("✅ Fama-French 3-Factor data cleaned.")
  
}, error = function(e) {
  log_message("❌ FAILED to process 3-Factor file.", "ERROR")
  stop(e)
})


# --- 3. CLEAN MOMENTUM FACTOR FILE ---
# ==============================================================================

log_message("📊 Processing Momentum factor file...")

tryCatch({
  mom_lines <- read_lines(file.path(DATA_RAW_FIN, "F-F_Momentum_Factor.csv"))
  data_start_line_mom <- which(str_detect(mom_lines, "^[0-9]{6},"))[1]
  
  mom_raw <- read_csv(
    file.path(DATA_RAW_FIN, "F-F_Momentum_Factor.csv"),
    skip = data_start_line_mom - 1,
    col_names = c("yyyymm", "mom"),
    show_col_types = FALSE
  )
  
  mom_clean <- mom_raw %>%
    # Filter to keep only monthly data (6-digit YYYYMM format)
    filter(str_detect(yyyymm, "^[0-9]{6}$")) %>%
    mutate(mom = mom / 100) %>%
    mutate(date = ymd(paste0(yyyymm, "01"))) %>%
    mutate(date = ceiling_to_month_end(date)) %>%
    # Remove rows with invalid dates
    filter(!is.na(date)) %>%
    select(date, mom) %>%
    # Ensure unique dates
    distinct(date, .keep_all = TRUE)
  
  log_message("✅ Momentum factor data cleaned.")
  
}, error = function(e) {
  log_message("❌ FAILED to process Momentum file.", "ERROR")
  stop(e)
})


# --- 4. MERGE AND SAVE FINAL FACTOR DATASET ---
# ==============================================================================

log_message("🔗 Merging 3-Factor and Momentum data...")

# Use a left join to combine them, ensuring all 3-factor dates are kept
factors_clean <- left_join(ff3_clean, mom_clean, by = "date", relationship = "one-to-one")

saveRDS(
  factors_clean,
  file = file.path(DATA_CLEAN, "factors_clean.rds")
)
log_message("💾 Cleaned 4-factor dataset saved to 'factors_clean.rds'.")

# --- 5. VALIDATION & SUMMARY ---
# ==============================================================================

log_message("📋 Validation checks:")
cat(sprintf("  - Final dimensions: %d rows x %d columns\n", nrow(factors_clean), ncol(factors_clean)))
cat(sprintf("  - Date range: %s to %s\n", min(factors_clean$date), max(factors_clean$date)))
cat(sprintf("  - Missing momentum values: %d (expected, as MOM starts later)\n", sum(is.na(factors_clean$mom))))

log_message("✅ Script 01-4 finished successfully.")
log_message("--------------------------------------------------")
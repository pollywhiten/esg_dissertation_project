# ==============================================================================
# 🧹 01-3: Clean CRSP/Compustat Financial Data
# ==============================================================================
#
# This script loads the raw CRSP/Compustat data, selects essential columns,
# standardizes column names, aligns dates to month-end, and prepares the
# data for merging with the ESG panel.
#
# ==============================================================================


# --- 1. SETUP ---
# ==============================================================================

source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "data_processing", "date_alignment_utils.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 01-3_clean_crsp.R")


# --- 2. LOAD RAW DATA ---
# ==============================================================================

log_message("📊 Loading raw CRSP_Compustat.csv data...")

tryCatch({
  crsp_raw <- read_csv(
    file.path(DATA_RAW_FIN, "CRSP_Compustat.csv"),
    show_col_types = FALSE
  )
  log_message("✅ Raw CRSP/Compustat data loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load 'CRSP_Compustat.csv'.", "ERROR")
  stop(e)
})


# --- 3. CLEAN AND PREPARE DATA ---
# ==============================================================================

log_message("🧹 Cleaning CRSP data...")

crsp_clean <- crsp_raw %>%
  # Select only the columns required for the analysis
  select(
    CUSIP,
    MthCalDt,
    MthRet,
    MthPrevCap,
    state
  ) %>%
  
  # Rename columns for clarity and consistency
  rename(
    cusip = CUSIP,
    date = MthCalDt,
    mth_ret = MthRet,
    mktcap_lag = MthPrevCap,
    state_abbr = state
  ) %>%
  
  # Align the date to the end of the month using our utility function
  mutate(date = ceiling_to_month_end(date)) %>%
  
  # Create the 8-digit CUSIP for merging
  mutate(cusip8 = substr(cusip, 1, 8)) %>%
  
  # Drop rows where essential identifiers or returns are missing
  filter(!is.na(mth_ret), !is.na(cusip8)) %>%
  
  # Ensure one observation per firm-month by dropping duplicates
  distinct(cusip8, date, .keep_all = TRUE)

log_message(paste("📈 CRSP data cleaned. Final dimensions:", nrow(crsp_clean), "rows,", ncol(crsp_clean), "columns."))


# --- 4. SAVE CLEANED DATA ---
# ==============================================================================

saveRDS(
  crsp_clean,
  file = file.path(DATA_CLEAN, "crsp_clean.rds")
)
log_message("💾 Cleaned CRSP data saved to 'crsp_clean.rds'.")

# --- 5. VALIDATION & SUMMARY ---
# ==============================================================================

log_message("📋 Validation checks:")
cat(sprintf("  📅 Date range: %s to %s\n", min(crsp_clean$date), max(crsp_clean$date)))
cat(sprintf("  ❓ Missing monthly returns (mth_ret): %d\n", sum(is.na(crsp_clean$mth_ret))))
cat(sprintf("  🔍 Are firm-month observations unique? %s\n", !any(duplicated(crsp_clean[, c("cusip8", "date")]))))

log_message("✅ Script 01-3 finished successfully.")
log_message("--------------------------------------------------")
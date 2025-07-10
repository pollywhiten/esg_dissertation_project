# ==============================================================================
# 🧹 01-2: Process Reference Data
# ==============================================================================
#
# This script loads the raw Reference_Data.csv file and creates a static,
# unique mapping between a company's EntityId and its key financial
# identifiers (CUSIP, Ticker, etc.). It resolves time-varying identifiers
# by taking the first available non-missing value for each company.
#
# ==============================================================================


# --- 1. SETUP ---
# ==============================================================================

source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("--------------------------------------------------")
log_message("Starting script: 01-2_process_reference_data.R")


# --- 2. LOAD RAW DATA ---
# ==============================================================================

log_message("Loading raw Reference_Data.csv...")

tryCatch({
  reference_raw <- read_csv(
    file.path(DATA_RAW_ESG, "Reference_Data.csv"),
    show_col_types = FALSE
  )
  log_message("✅ Raw Reference_Data loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load 'Reference_Data.csv'.", "ERROR")
  stop(e)
})


# --- 3. CREATE STATIC MAPPING ---
# ==============================================================================

log_message("Creating static one-to-one mapping for identifiers...")

# Use janitor for clean names first
reference_clean <- reference_raw %>%
  janitor::clean_names()

# Group by the main entity ID. For each company, find the first non-NA
# value for each of the key identifier columns. This collapses the panel
# into a static cross-section.
sustainalytics_ref <- reference_clean %>%
  group_by(entity_id) %>%
  summarise(
    cusip = ifelse(any(!is.na(cusip)), first(cusip[!is.na(cusip)]), NA_character_),
    ticker = ifelse(any(!is.na(ticker)), first(ticker[!is.na(ticker)]), NA_character_),
    isin = ifelse(any(!is.na(isin)), first(isin[!is.na(isin)]), NA_character_),
    country = ifelse(any(!is.na(country)), first(country[!is.na(country)]), NA_character_),
    region = ifelse(any(!is.na(region)), first(region[!is.na(region)]), NA_character_),
    .groups = "drop"
  )

log_message("Static mapping created.")


# --- 4. CREATE CUSIP8 MERGE KEY ---
# ==============================================================================

log_message("Creating 8-digit CUSIP for CRSP merging...")

sustainalytics_ref <- sustainalytics_ref %>%
  mutate(
    # Take the first 8 characters of the full CUSIP
    cusip8 = substr(cusip, 1, 8)
  )

# --- 5. SAVE CLEANED DATA ---
# ==============================================================================

saveRDS(
  sustainalytics_ref,
  file = file.path(DATA_CLEAN, "sustainalytics_ref_clean.rds")
)
log_message("💾 Cleaned reference data saved to 'sustainalytics_ref_clean.rds'.")

# --- 6. VALIDATION & SUMMARY ---
# ==============================================================================

log_message("Validation checks:")
n_unique_before <- n_distinct(reference_clean$entity_id)
n_unique_after <- n_distinct(sustainalytics_ref$entity_id)

cat(sprintf("  - Original unique entities: %d\n", n_unique_before))
cat(sprintf("  - Final unique entities:    %d\n", n_unique_after))
cat(sprintf("  - Are entity IDs unique now? %s\n", !any(duplicated(sustainalytics_ref$entity_id))))
cat(sprintf("  - CUSIP8 coverage: %d out of %d firms have a CUSIP8.\n", 
            sum(!is.na(sustainalytics_ref$cusip8)), nrow(sustainalytics_ref)))

log_message("Script 01-2 finished successfully.")
log_message("--------------------------------------------------")
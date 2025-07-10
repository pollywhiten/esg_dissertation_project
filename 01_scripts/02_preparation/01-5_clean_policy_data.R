# ==============================================================================
# 🧹 01-5: Clean and Prepare State Policy Data
# ==============================================================================
#
# This script loads two separate policy datasets:
#   1. ACEEE Scorecard Rankings
#   2. State Renewable Portfolio Standards (RPS) adoption dates
# It then creates a complete annual panel for all states and forward-fills
# the data to handle the biennial nature of the ACEEE reports.
#
# ==============================================================================


# --- 1. SETUP ---
# ==============================================================================

source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "data_processing", "forward_fill_functions.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 01-5_clean_policy_data.R")


# --- 2. LOAD & CLEAN ACEEE RANKING DATA ---
# ==============================================================================

log_message("📊 Processing ACEEE Scorecard data...")

tryCatch({
  aceee_raw <- read_csv(file.path(DATA_RAW_POL, "state_policy_rankings.csv"), show_col_types = FALSE)
  
  # The raw file is already quite clean, we just select necessary columns
  aceee_clean <- aceee_raw %>%
    select(State, Year, Rank, State_Abbrev, Strong_Policy_Top10, Policy_Quartile)
  
  log_message("✅ ACEEE data loaded and columns selected.")
}, error = function(e) {
  log_message("❌ FAILED to load ACEEE data.", "ERROR"); stop(e)
})


# --- 3. LOAD & CLEAN RPS DATA ---
# ==============================================================================

log_message("📊 Processing State RPS data...")

tryCatch({
  rps_raw <- read_csv(file.path(DATA_RAW_POL, "state_rps_panel_1990_2024.csv"), show_col_types = FALSE)
  
  # The raw file is already in a good format
  rps_clean <- rps_raw %>%
    select(state_abbr, year, has_rps) %>%
    rename(State_Abbrev = state_abbr, Year = year)

  log_message("✅ RPS data loaded and columns selected.")
}, error = function(e) {
  log_message("❌ FAILED to load RPS data.", "ERROR"); stop(e)
})


# --- 4. CREATE COMPLETE, FORWARD-FILLED PANEL ---
# ==============================================================================

log_message("🛠️ Creating a complete annual panel and forward-filling...")

# Merge the two policy datasets together first
policy_merged_sparse <- full_join(aceee_clean, rps_clean, by = c("State_Abbrev", "Year"))

# Create the full index of all states and years
all_states <- unique(policy_merged_sparse$State_Abbrev)
# Define a reasonable full range of years for the policy panel
all_years <- min(policy_merged_sparse$Year):max(policy_merged_sparse$Year)

# Use tidyr::expand_grid to create a complete combination of all states and years
complete_grid <- expand_grid(State_Abbrev = all_states, Year = all_years)

# Join the sparse data to the complete grid
policy_panel_final <- complete_grid %>%
  left_join(policy_merged_sparse, by = c("State_Abbrev", "Year")) %>%
  # Use our robust forward-fill function
  ffill_within_group("State_Abbrev", c("State", "Rank", "Strong_Policy_Top10", "Policy_Quartile", "has_rps")) %>%
  # Fill any remaining NAs (e.g., for `has_rps` before its first observation) with 0
  mutate(has_rps = ifelse(is.na(has_rps), 0, has_rps))
  
log_message("✅ Policy panel created and forward-filled.")


# --- 5. SAVE CLEANED DATA ---
# ==============================================================================

saveRDS(
  policy_panel_final,
  file = file.path(DATA_CLEAN, "policy_panel_clean.rds")
)
log_message("💾 Cleaned policy panel data saved to 'policy_panel_clean.rds'.")


# --- 6. VALIDATION & SUMMARY ---
# ==============================================================================

log_message("📋 Validation checks:")
cat(sprintf("  - Final dimensions: %d rows x %d columns\n", nrow(policy_panel_final), ncol(policy_panel_final)))
cat(sprintf("  - Total States/Entities: %d\n", n_distinct(policy_panel_final$State_Abbrev)))
cat(sprintf("  - Time Period: %d to %d\n", min(policy_panel_final$Year), max(policy_panel_final$Year)))
cat(sprintf("  - Any remaining NA values in key columns? %s\n", any(is.na(policy_panel_final$Rank)) || any(is.na(policy_panel_final$has_rps))))

# Show a sample to verify the forward-filling
cat("\nSample of filled data for a state with late RPS adoption (e.g., LA):\n")
print(filter(policy_panel_final, State_Abbrev == "LA", Year %in% 2008:2012))


log_message("✅ Script 01-5 finished successfully.")
log_message("--------------------------------------------------")
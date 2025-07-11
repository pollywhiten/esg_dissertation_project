# ==============================================================================
# 🔗 02-5: Merge All Data Sources into Final Analytical Dataset
# ==============================================================================
# This script performs the final merges to create the analysis-ready dataset:
# 1. ESG data with portfolio flags + Reference data (CUSIP mapping)
# 2. + CRSP financial data (returns, market cap)
# 3. + Fama-French factors
# 4. + State policy data
# Then filters to remove pre-rating history and calculates excess returns.
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("🔗 Starting final data merge process...")

# --- 2. LOAD ALL CLEANED DATASETS ---
# ==============================================================================
log_message("📂 Loading all cleaned datasets...")

# ESG data with portfolio flags
sustainalytics_portfolio <- readRDS(file.path(DATA_INTER_ESG, "sustainalytics_with_portfolios.rds"))
cat(paste("✅ ESG data: ", format(nrow(sustainalytics_portfolio), big.mark = ","), " rows\n", sep = ""))

# Reference data (EntityId to CUSIP mapping)
reference_data <- readRDS(file.path(DATA_CLEAN, "sustainalytics_ref_clean.rds"))
cat(paste("✅ Reference data: ", format(nrow(reference_data), big.mark = ","), " entities\n", sep = ""))

# CRSP financial data
crsp_clean <- readRDS(file.path(DATA_CLEAN, "crsp_clean.rds"))
cat(paste("✅ CRSP data: ", format(nrow(crsp_clean), big.mark = ","), " rows\n", sep = ""))

# Fama-French factors
ff_factors <- readRDS(file.path(DATA_CLEAN, "factors_clean.rds"))
cat(paste("✅ FF factors: ", format(nrow(ff_factors), big.mark = ","), " months\n", sep = ""))

# Policy data
policy_data <- readRDS(file.path(DATA_CLEAN, "policy_panel_clean.rds"))
cat(paste("✅ Policy data: ", format(nrow(policy_data), big.mark = ","), " state-years\n", sep = ""))

# --- 3. MERGE ESG WITH REFERENCE DATA ---
# ==============================================================================
log_message("🔗 Step 1: Merging ESG with reference data...")

# First, ensure dates are aligned to month-end for merging
sustainalytics_portfolio <- sustainalytics_portfolio %>%
  mutate(date = ceiling_date(field_date, "month") - days(1))

# Merge with reference data to get CUSIP
esg_with_cusip <- sustainalytics_portfolio %>%
  left_join(
    reference_data %>% select(entity_id, cusip8, ticker, country),
    by = "entity_id"
  )

# Check merge quality
merge1_stats <- esg_with_cusip %>%
  summarise(
    total_rows = n(),
    matched_cusip = sum(!is.na(cusip8)),
    match_rate = round(100 * matched_cusip / total_rows, 2)
  )

cat("\n📊 ESG-Reference Merge Statistics:\n")
cat("==================================\n")
cat(paste("• Total rows: ", format(merge1_stats$total_rows, big.mark = ","), "\n", sep = ""))
cat(paste("• Matched with CUSIP: ", format(merge1_stats$matched_cusip, big.mark = ","), "\n", sep = ""))
cat(paste("• Match rate: ", merge1_stats$match_rate, "%\n", sep = ""))

# --- 4. MERGE WITH CRSP FINANCIAL DATA ---
# ==============================================================================
log_message("🔗 Step 2: Merging with CRSP financial data...")

# Merge on cusip8 and date
merged_crsp <- crsp_clean %>%
  inner_join(
    esg_with_cusip,
    by = c("cusip8", "date")
  )

# Check merge quality
merge2_stats <- merged_crsp %>%
  summarise(
    total_rows = n(),
    unique_firms = n_distinct(cusip8),
    date_range = paste(min(date), "to", max(date))
  )

cat("\n📊 CRSP Merge Statistics:\n")
cat("========================\n")
cat(paste("• Total observations: ", format(merge2_stats$total_rows, big.mark = ","), "\n", sep = ""))
cat(paste("• Unique firms: ", format(merge2_stats$unique_firms, big.mark = ","), "\n", sep = ""))
cat(paste("• Date range: ", merge2_stats$date_range, "\n", sep = ""))

# --- 5. MERGE WITH FAMA-FRENCH FACTORS ---
# ==============================================================================
log_message("🔗 Step 3: Merging with Fama-French factors...")

# Merge with factors
merged_ff <- merged_crsp %>%
  left_join(
    ff_factors,
    by = "date"
  )

# Verify factor merge
factor_coverage <- merged_ff %>%
  summarise(
    total_rows = n(),
    has_factors = sum(!is.na(mkt_rf)),
    coverage_rate = round(100 * has_factors / total_rows, 2)
  )

cat("\n📊 Factor Merge Statistics:\n")
cat("=========================\n")
cat(paste("• Factor coverage: ", factor_coverage$coverage_rate, "%\n", sep = ""))

# --- 6. MERGE WITH POLICY DATA ---
# ==============================================================================
log_message("🔗 Step 4: Merging with state policy data...")

# Create year variable for merging
merged_ff <- merged_ff %>%
  mutate(year = year(date))

# Merge with policy data
final_merged <- merged_ff %>%
  left_join(
    policy_data %>% 
      rename(
        state_abbr = State_Abbrev,
        year = Year
      ),
    by = c("state_abbr", "year")
  )

# Check policy merge
policy_coverage <- final_merged %>%
  summarise(
    total_rows = n(),
    has_policy = sum(!is.na(Rank)),  # Using the actual column name from policy data
    us_firms = sum(!is.na(state_abbr)),
    policy_coverage = round(100 * has_policy / us_firms, 2)
  )

cat("\n📊 Policy Merge Statistics:\n")
cat("=========================\n")
cat(paste("• US firms: ", format(policy_coverage$us_firms, big.mark = ","), " observations\n", sep = ""))
cat(paste("• Policy coverage for US firms: ", policy_coverage$policy_coverage, "%\n", sep = ""))

# --- 7. FILTER PRE-RATING HISTORY ---
# ==============================================================================
log_message("🔍 Filtering pre-rating history to prevent look-ahead bias...")

# For each firm, find first ESG rating date
first_rating_dates <- final_merged %>%
  filter(!is.na(esg_risk_category)) %>%
  group_by(cusip8) %>%
  summarise(
    first_rating_date = min(date),
    .groups = 'drop'
  )

# Merge and filter
final_df_unfiltered <- final_merged %>%
  left_join(first_rating_dates, by = "cusip8")

rows_before <- nrow(final_df_unfiltered)

final_df <- final_df_unfiltered %>%
  filter(date >= first_rating_date) %>%
  select(-first_rating_date)

rows_after <- nrow(final_df)
rows_removed <- rows_before - rows_after

cat("\n🔍 Pre-Rating History Filter:\n")
cat("=============================\n")
cat(paste("• Rows before filter: ", format(rows_before, big.mark = ","), "\n", sep = ""))
cat(paste("• Rows after filter: ", format(rows_after, big.mark = ","), "\n", sep = ""))
cat(paste("• Rows removed: ", format(rows_removed, big.mark = ","), " (", 
          round(100 * rows_removed / rows_before, 1), "%)\n", sep = ""))

# --- 8. FORWARD FILL ESG DATA ---
# ==============================================================================
log_message("⏩ Forward-filling ESG data within filtered panel...")

# Forward fill ESG columns
esg_cols_to_fill <- c("esg_risk_score", "esg_risk_category", "esg_risk_category_numeric",
                      "score_change", "score_direction", "change_magnitude", "bulk_update",
                      "in_portfolio", "portfolio_direction")

final_df <- final_df %>%
  arrange(cusip8, date) %>%
  group_by(cusip8) %>%
  tidyr::fill(all_of(esg_cols_to_fill), .direction = "down") %>%
  ungroup()

# --- 9. CALCULATE EXCESS RETURNS ---
# ==============================================================================
log_message("📈 Calculating excess returns...")

final_df <- final_df %>%
  mutate(
    ex_ret = mth_ret - rf,
    # Also create log returns for robustness
    log_ret = log(1 + mth_ret),
    log_ex_ret = log_ret - log(1 + rf)
  )

# --- 10. FINAL DATA QUALITY CHECKS ---
# ==============================================================================
log_message("✅ Performing final data quality checks...")

# Missing value analysis
missing_summary <- final_df %>%
  summarise(
    across(c(ex_ret, mkt_rf, smb, hml, esg_risk_category, mktcap_lag),
           ~sum(is.na(.)), .names = "missing_{.col}")
  ) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  mutate(
    variable = str_remove(variable, "missing_"),
    missing_pct = round(100 * missing_count / nrow(final_df), 2)
  )

cat("\n📊 Missing Value Analysis:\n")
cat("=========================\n")
print(missing_summary)

# Summary statistics
cat("\n📊 Final Dataset Summary:\n")
cat("========================\n")
cat(paste("• Total observations: ", format(nrow(final_df), big.mark = ","), "\n", sep = ""))
cat(paste("• Unique firms: ", format(n_distinct(final_df$cusip8), big.mark = ","), "\n", sep = ""))
cat(paste("• Time period: ", min(final_df$date), " to ", max(final_df$date), "\n", sep = ""))
cat(paste("• Firms with rating changes: ", 
          n_distinct(final_df$cusip8[final_df$score_change == 1]), "\n", sep = ""))
cat(paste("• Portfolio observations: ", 
          format(sum(final_df$in_portfolio), big.mark = ","), "\n", sep = ""))

# --- 11. CREATE ANALYSIS SUBSETS ---
# ==============================================================================
log_message("📦 Creating analysis subsets...")

# Portfolio analysis subset (firms in event windows)
portfolio_subset <- final_df %>%
  filter(in_portfolio == TRUE)

# Save portfolio subset
saveRDS(portfolio_subset,
        file.path(DATA_CLEAN, "portfolio_analysis_data.rds"))

cat(paste("\n📦 Portfolio subset created: ", 
          format(nrow(portfolio_subset), big.mark = ","), " observations\n", sep = ""))

# --- 12. SAVE FINAL DATASET ---
# ==============================================================================
log_message("💾 Saving final analytical dataset...")

# Save main analysis dataset
saveRDS(final_df,
        file.path(DATA_CLEAN, "final_analytical_panel.rds"))

# Also save as CSV for external use
write.csv(final_df,
          file.path(DATA_CLEAN, "final_analytical_panel.csv"),
          row.names = FALSE)

# Create data dictionary
data_dict <- tibble(
  variable = names(final_df),
  type = sapply(final_df, class),
  description = c(
    "8-digit CUSIP identifier",
    "Month-end date",
    "Monthly stock return",
    "Lagged market capitalization",
    "State abbreviation",
    "Entity ID from Sustainalytics",
    "Date from ESG data",
    "ESG risk score",
    "ESG risk category",
    "Numeric ESG category (1-5)",
    "Rating change flag",
    "Change direction",
    "Change magnitude",
    "Bulk update flag",
    "Portfolio membership flag",
    "Portfolio direction",
    "Event ID",
    "Stock ticker",
    "Country",
    "Market risk premium",
    "Size factor",
    "Value factor",
    "Risk-free rate",
    "Momentum factor",
    "Year",
    "ACEEE state rank",
    "Strong policy flag",
    "Has RPS flag",
    "Excess return",
    "Log return",
    "Log excess return"
  )[1:length(names(final_df))]
)

write.csv(data_dict,
          file.path(DATA_META, "final_dataset_dictionary.csv"),
          row.names = FALSE)

# --- 13. FINAL SUMMARY ---
# ==============================================================================
cat("\n")
cat("🎉 ============================================ 🎉\n")
cat("   FINAL DATA MERGE COMPLETE!                    \n")
cat("   READY FOR ANALYSIS!                           \n")
cat("============================================== \n")
cat("\n📊 Output Files Created:\n")
cat("------------------------\n")
cat("• final_analytical_panel.rds - Main analysis dataset\n")
cat("• final_analytical_panel.csv - CSV version\n")
cat("• portfolio_analysis_data.rds - Portfolio subset\n")
cat("• final_dataset_dictionary.csv - Variable descriptions\n")
cat("\n🚀 Next Steps:\n")
cat("--------------\n")
cat("1. Run descriptive statistics (03-1_descriptive_stats.R)\n")
cat("2. Construct portfolios (03-2_portfolio_construction.R)\n")
cat("3. Run regressions (03-3_ff3_regressions.R)\n")

log_message("✅ Script 02-5 completed successfully!")
log_message("🎉 PHASE 4 FEATURE ENGINEERING COMPLETE!")

# --- END OF SCRIPT ---
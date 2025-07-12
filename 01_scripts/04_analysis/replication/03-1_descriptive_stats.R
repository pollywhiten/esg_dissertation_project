# ==============================================================================
# 📈 03-1: Descriptive Statistics of the Final Sample
# ==============================================================================
#
# This script loads the final analytical panel and generates the key
# descriptive statistics that will form the basis of the initial tables
# in the dissertation.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
library(stargazer) # For creating publication-quality tables
library(gt)       # For creating beautiful, modern tables

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 03-1_descriptive_stats.R")


# --- 2. LOAD FINAL DATA ---
# ==============================================================================
log_message("📊 Loading final analytical panel...")

final_df <- readRDS(file.path(DATA_CLEAN, "final_analytical_panel.rds"))

log_message(paste("✅ Loaded", nrow(final_df), "firm-month observations."))


# --- 3. TABLE 1: SUMMARY STATISTICS ---
# ==============================================================================
log_message("📝 Generating Table 1: Summary Statistics...")

# Select the key variables for the summary table
summary_vars <- final_df %>%
  select(
    `Excess Return` = ex_ret,
    `Market Cap (Lagged, $M)` = mktcap_lag,
    `ESG Risk Score` = esg_risk_score,
    `Market Factor (Mkt-RF)` = mkt_rf,
    `Size Factor (SMB)` = smb,
    `Value Factor (HML)` = hml,
    `Momentum Factor (Mom)` = mom
  ) %>%
  # Convert market cap to millions for better readability
  mutate(`Market Cap (Lagged, $M)` = `Market Cap (Lagged, $M)` / 1000)

# Use stargazer to create a beautiful summary table
stargazer(
  as.data.frame(summary_vars),
  type = "text", # Use "latex" or "html" for direct inclusion in documents
  title = "Descriptive Statistics of Key Variables",
  summary.stat = c("n", "mean", "sd", "min", "p25", "median", "p75", "max"),
  digits = 3,
  out = file.path(OUTPUT_TABLES, "descriptive", "table1_summary_stats.txt")
)

log_message("✅ Table 1 saved to output/tables/descriptive/")
cat("\n--- Summary Statistics ---\n")
stargazer(as.data.frame(summary_vars), type = "text", digits = 3)


# --- 4. TABLE 2: CORRELATION MATRIX ---
# ==============================================================================
log_message("📝 Generating Table 2: Correlation Matrix...")

# Calculate the correlation matrix
correlation_matrix <- cor(summary_vars, use = "pairwise.complete.obs")

# Use gt to create a visually appealing correlation table
correlation_table_gt <- as.data.frame(correlation_matrix) %>%
  rownames_to_column("Variable") %>%
  gt() %>%
  fmt_number(columns = -1, decimals = 2) %>%
  tab_header(title = "Correlation Matrix of Key Variables") %>%
  data_color(
    columns = -1,
    colors = scales::col_numeric(
      palette = c("darkred", "white", "darkgreen"),
      domain = c(-1, 1)
    )
  )

# Save the gt table as an HTML file
gtsave(correlation_table_gt, file.path(OUTPUT_TABLES, "descriptive", "table2_correlation_matrix.html"))

log_message("✅ Table 2 saved to output/tables/descriptive/")
cat("\n--- Correlation Matrix ---\n")
print(round(correlation_matrix, 3))


# --- 5. TABLE 3: RATING CHANGES OVER TIME ---
# ==============================================================================
log_message("📝 Generating Table 3: ESG Rating Changes by Year...")

changes_by_year <- final_df %>%
  filter(score_change == 1) %>%
  mutate(year = year(date)) %>%
  group_by(year) %>%
  summarise(
    `Total Changes` = n(),
    `Upgrades` = sum(score_direction == "Upgrade"),
    `Downgrades` = sum(score_direction == "Downgrade"),
    .groups = "drop"
  ) %>%
  mutate(`Upgrade %` = round(100 * Upgrades / `Total Changes`, 1))

# Create a gt table for this summary
changes_table_gt <- changes_by_year %>%
  gt() %>%
  fmt_number(columns = -c(1, 5), decimals = 0, use_seps = TRUE) %>%
  fmt_number(columns = `Upgrade %`, decimals = 1) %>%
  tab_header(title = "Distribution of ESG Rating Changes by Year") %>%
  cols_label(year = "Year", `Upgrade %` = "% Upgrades")

# Save the table
gtsave(changes_table_gt, file.path(OUTPUT_TABLES, "descriptive", "table3_changes_by_year.html"))

log_message("✅ Table 3 saved to output/tables/descriptive/")
cat("\n--- ESG Rating Changes by Year ---\n")
print(changes_by_year)


log_message("✅ Script 03-1 finished successfully.")
log_message("--------------------------------------------------")
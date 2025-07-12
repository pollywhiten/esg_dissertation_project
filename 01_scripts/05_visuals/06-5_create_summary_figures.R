# ==============================================================================
# 🎨 06-5: Create Final Summary Figures and Tables
# ==============================================================================
#
# This script creates the final summary outputs for the dissertation. It does
# not run new analyses, but instead loads previously generated plots and model
# results to combine them into publication-quality summary figures and tables.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "visualization", "plotting_themes.R"))
source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))

# Install and load required packages for summary figures
if (!require(patchwork)) install.packages("patchwork")
if (!require(gridExtra)) install.packages("gridExtra")

library(patchwork) # For combining ggplot objects
library(gridExtra) # Alternative for plot combinations

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 06-5_create_summary_figures.R")


# --- 2. CREATE ACTUAL KEY PLOTS FROM SCRATCH ---
# ==============================================================================
log_message("🖼️ Creating key summary plots from actual data...")

# Load the necessary data
downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))
upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
policy_results <- readRDS(file.path(DATA_CLEAN, "panel_regression_results.rds"))

# Plot A: Simple Portfolio Alpha Comparison
log_message("📊 Creating Plot A: Portfolio Alpha Comparison...")

# Run quick regressions to get alphas
ff3_formula <- "port_ret ~ mkt_rf + smb + hml"
model_down <- run_regression_model(downgrade_vw, ff3_formula, se_type = "robust")
model_up <- run_regression_model(upgrade_vw, ff3_formula, se_type = "robust")

alpha_data <- tibble(
  Portfolio = factor(c("Downgrade", "Upgrade"), levels = c("Downgrade", "Upgrade")),
  Alpha = c(model_down[1,1], model_up[1,1]) * 100,  # Convert to percentage
  CI_Lower = c(confint(model_down)[1,1], confint(model_up)[1,1]) * 100,
  CI_Upper = c(confint(model_down)[1,2], confint(model_up)[1,2]) * 100
)

plot_a <- ggplot(alpha_data, aes(x = Portfolio, y = Alpha, fill = Portfolio)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = CI_Lower, ymax = CI_Upper), width = 0.2) +
  geom_text(aes(label = sprintf("%.2f%%", Alpha)), vjust = -0.5, fontface = "bold") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("Downgrade" = "#FF6B6B", "Upgrade" = "#4ECDC4")) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme_esg() +
  theme(legend.position = "none") +
  labs(title = "A: Portfolio Abnormal Returns (Alpha)",
       y = "Monthly Alpha (%)", x = "Portfolio Type")

# Plot B: Policy Interaction Simplified
log_message("📊 Creating Plot B: Policy Effects...")

model_aceee <- policy_results$interaction
model_rps <- policy_results$rps_based

eff_weak_aceee <- model_aceee[2, "Estimate"]
eff_strong_aceee <- model_aceee[2, "Estimate"] + model_aceee[3, "Estimate"]
eff_weak_rps <- model_rps[2, "Estimate"]
eff_strong_rps <- model_rps[2, "Estimate"] + model_rps[3, "Estimate"]

policy_data <- tibble(
  Policy = factor(rep(c("ACEEE", "RPS"), each = 2)),
  Environment = factor(rep(c("Weak", "Strong"), 2)),
  Effect = c(eff_weak_aceee, eff_strong_aceee, eff_weak_rps, eff_strong_rps) * 100
)

plot_b <- ggplot(policy_data, aes(x = Policy, y = Effect, fill = Environment)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7, alpha = 0.8) +
  geom_text(aes(label = sprintf("%.2f%%", Effect)), 
            position = position_dodge(width = 0.8), vjust = -0.3, size = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("Weak" = "lightcoral", "Strong" = "darkred")) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme_esg() +
  labs(title = "B: Policy Environment Effects",
       y = "Downgrade Effect (%)", x = "Policy Measure", fill = "Environment")

# Plot C: Subsample Robustness (recreate from our previous analysis)
log_message("📊 Creating Plot C: Temporal Robustness...")

model_full <- run_regression_model(downgrade_vw, ff3_formula, se_type = "robust")
subsample <- downgrade_vw %>% filter(date >= as.Date("2021-06-01"))
model_late <- run_regression_model(subsample, ff3_formula, se_type = "robust")

temporal_data <- tibble(
  Period = factor(c("Full Sample", "Late Period"), levels = c("Full Sample", "Late Period")),
  Alpha = c(model_full[1,1], model_late[1,1]) * 100,
  CI_Lower = c(confint(model_full)[1,1], confint(model_late)[1,1]) * 100,
  CI_Upper = c(confint(model_full)[1,2], confint(model_late)[1,2]) * 100
)

plot_c <- ggplot(temporal_data, aes(x = Period, y = Alpha, fill = Period)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = CI_Lower, ymax = CI_Upper), width = 0.2) +
  geom_text(aes(label = sprintf("%.2f%%", Alpha)), vjust = -0.5, fontface = "bold") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_fill_manual(values = c("Full Sample" = "#95E1D3", "Late Period" = "#F38BA8")) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme_esg() +
  theme(legend.position = "none") +
  labs(title = "C: Temporal Robustness",
       y = "Downgrade Alpha (%)", x = "Time Period")

# --- 3. COMBINE PLOTS INTO SUMMARY FIGURE ---
# ==============================================================================
log_message("🎨 Combining plots into publication-ready summary figure...")

# Use patchwork to create a professional layout
summary_figure <- (plot_a + plot_b) / plot_c +
  plot_layout(heights = c(1, 1)) +
  plot_annotation(
    title = "Summary of Key Findings: ESG Rating Change Effects on Stock Returns",
    subtitle = "Value-weighted portfolio analysis with Fama-French 3-factor adjustments",
    caption = "Data: Sustainalytics ESG ratings, CRSP returns, Fama-French factors | Analysis by Pollyanna Whitenburgh",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", color = "darkblue"),
      plot.subtitle = element_text(size = 12, color = "darkgray"),
      plot.caption = element_text(size = 10, color = "darkgray")
    )
  )

# Save the combined figure
ggsave(
  filename = file.path(OUTPUT_FIGURES, "main_results", "fig5_summary_panel.png"),
  plot = summary_figure,
  width = 16, height = 12, dpi = 300, bg = "white"
)

log_message("✅ Multi-panel summary figure created and saved.")


# --- 4. CREATE BEAUTIFUL HTML SUMMARY TABLES ---
# ==============================================================================
log_message("📝 Creating publication-quality HTML summary tables...")

# Install gt if needed
if (!require(gt)) install.packages("gt")
library(gt)

# Create a comprehensive results summary from actual data
results_summary <- tibble(
  Analysis = c(
    "Portfolio Performance: Upgrades",
    "Portfolio Performance: Downgrades", 
    "Policy Extension: ACEEE (Weak States)",
    "Policy Extension: ACEEE (Strong States)",
    "Policy Extension: RPS (Weak States)",
    "Policy Extension: RPS (Strong States)",
    "Temporal Robustness: Full Sample",
    "Temporal Robustness: Late Period"
  ),
  Alpha_Monthly_Pct = c(
    model_up[1,1] * 100,
    model_down[1,1] * 100,
    eff_weak_aceee * 100,
    eff_strong_aceee * 100,
    eff_weak_rps * 100,
    eff_strong_rps * 100,
    model_full[1,1] * 100,
    model_late[1,1] * 100
  ),
  P_Value = c(
    model_up[1,4],
    model_down[1,4],
    model_aceee[2,4],  # Main effect p-value
    model_aceee[3,4],  # Interaction p-value
    model_rps[2,4],
    model_rps[3,4],
    model_full[1,4],
    model_late[1,4]
  ),
  Significance = case_when(
    P_Value < 0.01 ~ "***",
    P_Value < 0.05 ~ "**", 
    P_Value < 0.10 ~ "*",
    TRUE ~ ""
  )
)

# Create the main comprehensive results table using gt (similar to descriptive stats style)
summary_gt_table <- results_summary %>%
  gt() %>%
  tab_header(
    title = md("**Summary of Key ESG Rating Change Effects**"),
    subtitle = "Monthly abnormal returns (alpha) from Fama-French factor models"
  ) %>%
  cols_label(
    Analysis = "Analysis Type",
    Alpha_Monthly_Pct = "Monthly Alpha (%)",
    P_Value = "P-Value",
    Significance = "Sig."
  ) %>%
  fmt_number(columns = Alpha_Monthly_Pct, decimals = 3) %>%
  fmt_number(columns = P_Value, decimals = 3) %>%
  # Color-code by significance level (similar to descriptive stats correlation matrix)
  data_color(
    columns = P_Value,
    colors = scales::col_numeric(
      palette = c("darkgreen", "gold", "lightcoral"),
      domain = c(0, 0.15)
    )
  ) %>%
  # Style the significance stars
  data_color(
    columns = Significance,
    colors = scales::col_factor(
      palette = c("darkgreen", "orange", "gold", "lightgray"),
      levels = c("***", "**", "*", "")
    )
  ) %>%
  # Add group separators (similar to descriptive stats style)
  tab_row_group(
    label = "Core Portfolio Analysis",
    rows = 1:2
  ) %>%
  tab_row_group(
    label = "Policy Environment Effects",
    rows = 3:6
  ) %>%
  tab_row_group(
    label = "Temporal Robustness",
    rows = 7:8
  ) %>%
  # Apply styling similar to descriptive stats
  tab_style(
    style = cell_fill(color = "lightgray"),
    locations = cells_column_labels()
  ) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels()
  ) %>%
  tab_options(
    heading.title.font.size = 16,
    heading.subtitle.font.size = 12,
    table.font.size = 11,
    row_group.font.weight = "bold",
    row_group.background.color = "#f0f0f0"
  ) %>%
  # Add footnotes
  tab_footnote(
    footnote = "*** p<0.01, ** p<0.05, * p<0.10",
    locations = cells_column_labels(columns = Significance)
  ) %>%
  tab_footnote(
    footnote = "All models use robust standard errors. Policy effects show marginal effects.",
    locations = cells_title(groups = "title")
  )

# Save the beautiful HTML table
gtsave(summary_gt_table, file.path(OUTPUT_TABLES, "summary", "comprehensive_results_table.html"))

# Create a portfolio comparison table (similar to descriptive stats summary table structure)
portfolio_comparison_data <- tibble(
  Portfolio = c("ESG Upgrades", "ESG Downgrades"),
  N_Obs = c(
    nrow(filter(upgrade_vw, !is.na(port_ret))),
    nrow(filter(downgrade_vw, !is.na(port_ret)))
  ),
  Mean_Return = c(
    mean(upgrade_vw$port_ret, na.rm = TRUE) * 100,
    mean(downgrade_vw$port_ret, na.rm = TRUE) * 100
  ),
  SD_Return = c(
    sd(upgrade_vw$port_ret, na.rm = TRUE) * 100,
    sd(downgrade_vw$port_ret, na.rm = TRUE) * 100
  ),
  Alpha_Pct = c(
    model_up[1,1] * 100,
    model_down[1,1] * 100
  ),
  T_Stat = c(
    model_up[1,3],
    model_down[1,3]
  ),
  P_Value = c(
    model_up[1,4],
    model_down[1,4]
  ),
  Significance = case_when(
    P_Value < 0.01 ~ "***",
    P_Value < 0.05 ~ "**", 
    P_Value < 0.10 ~ "*",
    TRUE ~ ""
  )
)

portfolio_comparison_gt <- portfolio_comparison_data %>%
  gt() %>%
  tab_header(
    title = "Portfolio Performance Comparison",
    subtitle = "Summary statistics and factor model results for ESG rating change portfolios"
  ) %>%
  cols_label(
    Portfolio = "Portfolio",
    N_Obs = "N",
    Mean_Return = "Mean Return (%)",
    SD_Return = "Std Dev (%)",
    Alpha_Pct = "Alpha (%)",
    T_Stat = "t-statistic",
    P_Value = "P-Value",
    Significance = "Sig."
  ) %>%
  fmt_number(columns = c(Mean_Return, SD_Return, Alpha_Pct), decimals = 3) %>%
  fmt_number(columns = c(T_Stat, P_Value), decimals = 3) %>%
  fmt_number(columns = N_Obs, decimals = 0, use_seps = TRUE) %>%
  # Apply similar styling to descriptive stats
  tab_style(
    style = cell_fill(color = "lightgray"),
    locations = cells_column_labels()
  ) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels()
  ) %>%
  # Color-code significance
  data_color(
    columns = P_Value,
    colors = scales::col_numeric(
      palette = c("darkgreen", "gold", "lightcoral"),
      domain = c(0, 0.15)
    )
  )

# Save the portfolio comparison table
gtsave(portfolio_comparison_gt, file.path(OUTPUT_TABLES, "summary", "portfolio_comparison_table.html"))

# Create a second table focusing on key findings (executive summary style)
key_findings_table <- tibble(
  Finding = c(
    "ESG Upgrades Effect",
    "ESG Downgrades Effect",
    "Policy Moderation (ACEEE)",
    "Policy Moderation (RPS)",
    "Temporal Stability"
  ),
  Result = c(
    sprintf("%.3f%% alpha (p=%.3f)", model_up[1,1]*100, model_up[1,4]),
    sprintf("%.3f%% alpha (p=%.3f)", model_down[1,1]*100, model_down[1,4]),
    "Mixed evidence across states",
    "Mixed evidence across states", 
    "Stronger in recent period"
  ),
  Interpretation = c(
    "No significant abnormal returns",
    "Marginally significant negative effect",
    "Policy effects not consistent",
    "Policy effects not consistent",
    "Effect has strengthened over time"
  ),
  Economic_Significance = c(
    "Low",
    "Moderate",
    "Low",
    "Low", 
    "Increasing"
  )
) %>%
  gt() %>%
  tab_header(
    title = md("**Key Research Findings: ESG Rating Changes and Stock Returns**"),
    subtitle = "Executive summary of main results"
  ) %>%
  cols_label(
    Finding = "Research Question",
    Result = "Statistical Result",
    Interpretation = "Interpretation",
    Economic_Significance = "Economic Impact"
  ) %>%
  # Color-code economic significance
  data_color(
    columns = Economic_Significance,
    colors = scales::col_factor(
      palette = c("lightgray", "gold", "lightcoral"),
      levels = c("Low", "Moderate", "Increasing")
    )
  ) %>%
  # Apply consistent styling
  tab_style(
    style = cell_fill(color = "lightgray"),
    locations = cells_column_labels()
  ) %>%
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels()
  ) %>%
  tab_options(
    heading.title.font.size = 16,
    heading.subtitle.font.size = 12,
    table.font.size = 11
  )

# Save the key findings table
gtsave(key_findings_table, file.path(OUTPUT_TABLES, "summary", "key_findings_table.html"))

# Also save CSV for backup/manipulation
write_csv(results_summary, file.path(OUTPUT_TABLES, "summary", "comprehensive_results_summary.csv"))

# Create a simple text summary for quick reference
summary_text <- capture.output({
  cat("COMPREHENSIVE RESULTS SUMMARY\n")
  cat("============================\n\n")
  cat("Key Findings:\n")
  cat("1. ESG Upgrades:", sprintf("%.3f%% monthly alpha (p=%.3f)\n", 
                                 results_summary$Alpha_Monthly_Pct[1], 
                                 results_summary$P_Value[1]))
  cat("2. ESG Downgrades:", sprintf("%.3f%% monthly alpha (p=%.3f)\n", 
                                   results_summary$Alpha_Monthly_Pct[2], 
                                   results_summary$P_Value[2]))
  cat("3. Policy moderation effects: Mixed evidence across measures\n")
  cat("4. Temporal stability: Effect stronger in recent period\n\n")
  cat("Statistical significance: *** p<0.01, ** p<0.05, * p<0.10\n")
  cat("HTML tables available in: output/tables/summary/\n")
})

writeLines(summary_text, file.path(OUTPUT_TABLES, "summary", "key_findings_summary.txt"))

log_message("💾 Beautiful HTML tables and summary files saved.")
log_message("📋 Key outputs:")
log_message("   • comprehensive_results_table.html - Detailed statistical results")
log_message("   • key_findings_table.html - Executive summary table") 
log_message("   • comprehensive_results_summary.csv - Data for further analysis")
log_message("   • key_findings_summary.txt - Quick text reference")
log_message("✅ Script 06-5 finished successfully.")
log_message("🎉🎉🎉 ALL VISUALIZATIONS COMPLETE! 🎉🎉🎉")
log_message("--------------------------------------------------")
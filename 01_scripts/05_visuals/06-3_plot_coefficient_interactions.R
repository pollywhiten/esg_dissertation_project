# ==============================================================================
# 🎨 06-3: Visualize Policy Interaction Effects (Final Polished Version)
# ==============================================================================
#
# This script creates a final, publication-quality coefficient plot to visualize
# the results of the policy interaction panel regressions.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "visualization", "plotting_themes.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 06-3_plot_coefficient_interactions.R")


# --- 2. LOAD REGRESSION RESULTS ---
# ==============================================================================
log_message("📊 Loading final panel regression results...")

tryCatch({
  all_models <- readRDS(file.path(DATA_CLEAN, "panel_regression_results.rds"))
  log_message("✅ Regression model objects loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load 'panel_regression_results.rds'.", "ERROR"); stop(e)
})


# --- 3. EXTRACT COEFFICIENTS FOR PLOTTING ---
# ==============================================================================
log_message("🔍 Extracting coefficients for visualization...")

# Extract the specific models we need by name
model_aceee <- all_models$interaction
model_rps <- all_models$rps_based

# Calculate the marginal effect for each group
eff_weak_aceee <- model_aceee[2, "Estimate"]
eff_strong_aceee <- model_aceee[2, "Estimate"] + model_aceee[3, "Estimate"] # Note: name might differ based on formula

eff_weak_rps <- model_rps[2, "Estimate"]
eff_strong_rps <- model_rps[2, "Estimate"] + model_rps[3, "Estimate"]

# Create a clean dataframe for ggplot2
plot_data <- tibble(
  `Definition of Policy Strength` = factor(
    c("ACEEE Top 10 Rank", "ACEEE Top 10 Rank", "RPS Mandate", "RPS Mandate"),
    levels = c("ACEEE Top 10 Rank", "RPS Mandate")
  ),
  `Firm HQ Environment` = factor(
    c("Weak Policy State", "Strong Policy State", "Weak Policy State", "Strong Policy State"),
    levels = c("Weak Policy State", "Strong Policy State")
  ),
  Effect = c(eff_weak_aceee, eff_strong_aceee, eff_weak_rps, eff_strong_rps)
)

log_message("✅ Data for plotting prepared.")


# --- 4. CREATE AND SAVE THE PLOT ---
# ==============================================================================
log_message("🎨 Creating the final coefficient interaction plot...")

interaction_plot <- ggplot(plot_data, aes(x = `Definition of Policy Strength`, y = Effect, fill = `Firm HQ Environment`)) +
  
  geom_bar(stat = "identity", position = position_dodge(width = 0.9), width = 0.8) +
  
  # --- ADD VALUE LABELS TO BARS ---
  geom_text(
    aes(label = sprintf("%.2f%%", Effect * 100)), 
    position = position_dodge(width = 0.9),
    vjust = 1.2, # Position below the bars
    size = 4,
    fontface = "bold",
    color = "black" # Fixed black color for all labels
  ) +
  
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  
  # --- USE CUSTOM COLORS TO MATCH PYTHON ---
  scale_fill_manual(
    values = c(
      "Weak Policy State" = "lightcoral",
      "Strong Policy State" = "darkred"
    )
  ) +
  
  # Set text color to white for the dark red bars
  scale_color_manual(
    values = c(
      "Weak Policy State" = "black",
      "Strong Policy State" = "white"
    )
  ) +
  
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.01)) +
  
  theme_esg() +
  labs(
    title = "Stock Market Reaction to ESG Downgrades by State Policy Environment",
    subtitle = "Average monthly abnormal return following a downgrade, by policy environment.",
    x = "Definition of Policy Strength",
    y = "Average Monthly Abnormal Return (Alpha %)",
    fill = "Firm HQ Environment", # Legend title
    caption = "Data: Sustainalytics, CRSP, etc. Analysis by Pollyanna Whitenburgh."
  ) +
  
  # Remove the redundant color guide for the text
  guides(color = "none")


# Save the plot
ggsave(
  filename = file.path(OUTPUT_FIGURES, "main_results", "fig3_policy_interaction_plot.png"),
  plot = interaction_plot,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)

log_message("💾 Plot saved to 'output/figures/main_results/fig3_policy_interaction_plot.png'")
log_message("✅ Script 06-3 finished successfully.")
log_message("--------------------------------------------------")
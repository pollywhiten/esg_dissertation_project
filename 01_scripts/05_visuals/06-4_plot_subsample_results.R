# ==============================================================================
# 🎨 06-4: Visualize Subsample Analysis Results
# ==============================================================================
#
# This script creates a comparative visualization for the subsample analysis.
# It plots the alpha of the value-weighted downgrade portfolio for both the
# full sample and the post-2016 subsample to visually assess the stability
# of the main finding over time.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "visualization", "plotting_themes.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 06-4_plot_subsample_results.R")


# --- 2. LOAD DATA AND MODELS ---
# ==============================================================================
log_message("📊 Loading necessary data and models...")

tryCatch({
  # We need the portfolio returns to re-run the regressions and get the models
  downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))
  
  # Also need the regression function
  source(file.path(FUNCTIONS_PATH, "analysis", "regression_functions.R"))
  log_message("✅ Data loaded successfully.")
}, error = function(e) {
  log_message("❌ FAILED to load required files.", "ERROR"); stop(e)
})


# --- 3. RE-RUN REGRESSIONS TO GET MODEL OBJECTS ---
# ==============================================================================
log_message("⚙️ Re-running regressions to get model objects for plotting...")

# Define the regression formula
ff3_formula <- "port_ret ~ mkt_rf + smb + hml"

# Full sample model
model_full_sample <- run_regression_model(downgrade_vw, ff3_formula, se_type = "robust")

# Subsample model - use a date that actually splits our data
subsample_start <- as.Date("2021-06-01")  # Split data roughly in half
downgrade_subsample <- downgrade_vw %>% filter(date >= subsample_start)
model_subsample <- run_regression_model(downgrade_subsample, ff3_formula, se_type = "robust")


# --- 4. PREPARE DATA FOR PLOTTING ---
# ==============================================================================
log_message("🔍 Extracting coefficients and preparing data for plot...")

# Extract alpha and confidence intervals for both models
alpha_full <- model_full_sample[1, "Estimate"]
ci_full <- confint(model_full_sample)[1, ]

alpha_sub <- model_subsample[1, "Estimate"]
ci_sub <- confint(model_subsample)[1, ]

# Create plotting dataframe
plot_data <- tibble(
  Sample = factor(c("Full Sample (2018-2024)", "Late Period (2021-2024)"),
                  levels = c("Full Sample (2018-2024)", "Late Period (2021-2024)")),
  Alpha = c(alpha_full, alpha_sub),
  CI_Lower = c(ci_full[1], ci_sub[1]),
  CI_Upper = c(ci_full[2], ci_sub[2])
)

log_message("✅ Data for plotting prepared.")


# --- 5. CREATE AND SAVE THE PLOT ---
# ==============================================================================
log_message("🎨 Creating the final subsample comparison plot...")

subsample_plot <- ggplot(plot_data, aes(x = Sample, y = Alpha, fill = Sample)) +
  
  # Add gradient bars with borders
  geom_col(width = 0.7, color = "gold", linewidth = 1.5, alpha = 0.9) +
  
  # Add error bars for the 95% confidence interval (thicker and colored)
  geom_errorbar(
    aes(ymin = CI_Lower, ymax = CI_Upper), 
    width = 0.25, 
    color = "darkslategray", 
    linewidth = 1.3,
    alpha = 0.9
  ) +
  
  # Add the main alpha percentage label on the left side of the bar
  geom_text(
    aes(label = sprintf("α = %.2f%%", Alpha * 100)),
    hjust = 1.2, # Position text to the left of the bar
    vjust = 1.5, # Center vertically
    color = "navy",
    fontface = "bold",
    size = 6,
    family = "sans"
  ) +
  
  # Add confidence interval labels above the error bars
  geom_text(
    aes(label = sprintf("95%% CI:\n[%.2f%%, %.2f%%]", CI_Lower * 100, CI_Upper * 100),
        y = CI_Upper),
    vjust = -0.5,
    color = "darkslategray",
    fontface = "bold",
    size = 3.8,
    lineheight = 0.9
  ) +
  
  # Add a stylish zero reference line
  geom_hline(yintercept = 0, linetype = "solid", color = "darkslategray", linewidth = 1.2) +
  
  # Use vibrant, contrasting colors
  scale_fill_manual(
    values = c(
      "Full Sample (2018-2024)" = "#FF6B6B",      # Coral red
      "Late Period (2021-2024)" = "#4ECDC4"      # Turquoise
    )
  ) +
  
  # Enhanced y-axis formatting
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.1),
    expand = expansion(mult = c(0.1, 0.15)) # Add more space at top for CI labels
  ) +
  
  # Enhanced theme with gradient background
  theme_esg() +
  theme(
    legend.position = "none",
    # panel.background = element_rect(fill = "ivory", color = NA),
    plot.background = element_rect(fill = "white", color = NA),
    axis.text.x = element_text(size = 12, face = "bold", color = "darkslategray"),
    axis.text.y = element_text(size = 11, color = "darkslategray"),
    axis.title = element_text(size = 13, face = "bold", color = "darkslategray"),
    plot.title = element_text(size = 16, face = "bold", color = "darkred"),
    plot.subtitle = element_text(size = 12, color = "darkslategray")
  ) +
  
  labs(
    title = "📊 ESG Downgrade Effect: Robust Across Time Periods",
    subtitle = "Monthly abnormal returns (α) of value-weighted downgrade portfolio with 95% confidence intervals",
    x = "Sample Period",
    y = "Monthly Abnormal Return (Alpha %)",
    caption = "Data: Sustainalytics, CRSP, Fama-French factors | Analysis by Pollyanna Whitenburgh"
  )

# Save the plot
ggsave(
  filename = file.path(OUTPUT_FIGURES, "supplementary", "fig4_subsample_comparison.png"),
  plot = subsample_plot,
  width = 10,
  height = 8,
  dpi = FIGURE_DPI,
  bg = "white"
)

log_message("💾 Plot saved to 'output/figures/supplementary/fig4_subsample_comparison.png'")
log_message("✅ Script 06-4 finished successfully.")
log_message("--------------------------------------------------")
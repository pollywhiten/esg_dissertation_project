# ==============================================================================
# 🎨 06-1: Visualize Frequency of ESG Rating Changes
# ==============================================================================
#
# This script creates a time-series plot showing the number of ESG rating
# changes per month, highlighting the "spike" months identified as
# potential bulk update periods.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "visualization", "plotting_themes.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 06-1_plot_change_frequency.R")


# --- 2. LOAD DATA ---
# ==============================================================================
log_message("📊 Loading data with change flags...")
sustainalytics_with_flags <- readRDS(file.path(DATA_INTER_ESG, "sustainalytics_with_bulk_flags.rds"))
log_message("✅ Data loaded.")


# --- 3. PREPARE DATA FOR PLOTTING ---
# ==============================================================================
log_message("🛠️ Preparing data for visualization...")

# Count changes per month
monthly_changes <- sustainalytics_with_flags %>%
  filter(score_change == 1) %>%
  group_by(field_date) %>%
  summarise(n_changes = n(), .groups = "drop")

# Identify the spike months to highlight on the plot
top_spike_months <- monthly_changes %>%
  arrange(desc(n_changes)) %>%
  head(TOP_SPIKE_MONTHS)


# --- 4. CREATE AND SAVE THE PLOT ---
# ==============================================================================
log_message("🎨 Creating the change frequency plot...")

change_frequency_plot <- ggplot(monthly_changes, aes(x = field_date, y = n_changes)) +
  # Main time-series line
  geom_line(color = esg_colors("main_line"), linewidth = 1) +
  
  # Highlight the spike months with red points
  geom_point(
    data = top_spike_months,
    color = esg_colors("downgrade"),
    size = 4,
    shape = 21, # Circle with a border
    fill = "white",
    stroke = 1.5
  ) +
  
  # Add labels to the spike months
  ggrepel::geom_text_repel(
    data = top_spike_months,
    aes(label = format(field_date, "%b %Y")),
    fontface = "bold",
    nudge_y = 50, # Move label above the point
    box.padding = 0.5
  ) +
  
  # Apply our custom theme and labels
  theme_esg() +
  labs(
    title = "Frequency of ESG Rating Changes Shows Significant Clustering",
    subtitle = paste("Monthly count of rating changes. Top", TOP_SPIKE_MONTHS, "months highlighted as potential bulk updates."),
    x = "Month",
    y = "Number of Rating Changes",
    caption = "Data source: Sustainalytics. Analysis by Pollyanna Whitenburgh."
  )

# Save the plot
ggsave(
  filename = file.path(OUTPUT_FIGURES, "diagnostic", "fig1_change_frequency.png"),
  plot = change_frequency_plot,
  width = FIGURE_WIDTH,
  height = FIGURE_HEIGHT,
  dpi = FIGURE_DPI,
  bg = "white"
)

log_message("💾 Plot saved to 'output/figures/diagnostic/fig1_change_frequency.png'")
log_message("✅ Script 06-1 finished successfully.")
log_message("--------------------------------------------------")```
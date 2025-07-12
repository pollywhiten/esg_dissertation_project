# ==============================================================================
# 🎨 06-2: Visualize Calendar-Time Portfolio Performance (Final Polished Version)
# ==============================================================================
#
# This script creates a comprehensive, multi-layered time-series plot of the
# cumulative returns for the value-weighted Upgrade, Downgrade, and a
# "Long-Short" (Upgrade - Downgrade) portfolio, matching the color and
# style of the final Python visualization.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================
source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))
source(file.path(FUNCTIONS_PATH, "visualization", "plotting_themes.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 06-2_plot_portfolio_performance.R")


# --- 2. LOAD & PREPARE DATA ---
# ==============================================================================
log_message("📊 Loading and preparing portfolio return data...")

upgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_upgrade_vw.rds"))
downgrade_vw <- readRDS(file.path(DATA_CLEAN, "port_returns_downgrade_vw.rds"))

returns_combined <- full_join(
  upgrade_vw %>% select(date, port_ret_up = port_ret),
  downgrade_vw %>% select(date, port_ret_down = port_ret),
  by = "date"
) %>%
  mutate(port_ret_ls = port_ret_up - port_ret_down) %>%
  arrange(date)

plot_data <- returns_combined %>%
  mutate(
    Upgrade = cumprod(1 + port_ret_up) - 1,
    Downgrade = cumprod(1 + port_ret_down) - 1,
    `Long-Short` = cumprod(1 + port_ret_ls) - 1
  ) %>%
  pivot_longer(
    cols = c(Upgrade, Downgrade, `Long-Short`),
    names_to = "Portfolio",
    values_to = "cum_ret"
  ) %>%
  mutate(Portfolio = factor(Portfolio, levels = c("Upgrade", "Downgrade", "Long-Short")))

log_message("✅ Data preparation complete.")


# --- 3. CREATE AND SAVE THE FINAL PLOT ---
# ==============================================================================
log_message("🎨 Creating the final, color-coded portfolio performance plot...")

# Define the COVID crash period for shading
covid_start <- as.Date("2020-02-01")
covid_end <- as.Date("2020-04-30")

performance_plot <- ggplot(plot_data, aes(x = date, y = cum_ret, color = Portfolio, linetype = Portfolio, linewidth = Portfolio)) +
  
  # Add the recession shading first so it's in the background
  annotate("rect", xmin = covid_start, xmax = covid_end, ymin = -Inf, ymax = Inf,
           fill = esg_colors("recession_shade"), alpha = 0.6) +
  
  # Add the portfolio return lines
  geom_line() + # Linewidth is now controlled in the aes() mapping
  
  # Add a zero line for reference
  geom_hline(yintercept = 0, linetype = "dotted", color = "black") +
  
  # Manually set the colors
  scale_color_manual(
    name = "Portfolio Strategy",
    values = c(
      "Upgrade" = "mediumseagreen",
      "Downgrade" = "indianred",
      "Long-Short" = "navy"
    )
  ) +
  
  # --- **CHANGE 1: Set linetype to "dotted" for Long-Short** ---
  scale_linetype_manual(
    name = "Portfolio Strategy",
    values = c(
      "Upgrade" = "solid",
      "Downgrade" = "solid",
      "Long-Short" = "dotted" # Changed from "dashed"
    )
  ) +
  
  # --- **CHANGE 2: Set linewidth to be thinner for Long-Short** ---
  scale_linewidth_manual(
    name = "Portfolio Strategy",
    values = c(
      "Upgrade" = 1.2,
      "Downgrade" = 1.2,
      "Long-Short" = 1.0 # Make the dotted line slightly thinner
    )
  ) +

  # Format axes and labels
  scale_y_continuous(labels = scales::percent) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "Cumulative Performance of ESG Rating Change Portfolios",
    subtitle = "Value-weighted portfolios held for 12 months following an event.",
    x = "Year",
    y = "Cumulative Excess Return",
    caption = "Data: Sustainalytics, CRSP, Fama-French. Analysis by Pollyanna Whitenburgh."
  ) +
  
  # Apply our custom theme
  theme_esg() +
  theme(legend.title = element_blank())

# Save the plot
ggsave(
  filename = file.path(OUTPUT_FIGURES, "main_results", "fig2_portfolio_performance.png"),
  plot = performance_plot,
  width = 16,
  height = 8,
  dpi = 300,
  bg = "white"
)

log_message("💾 Plot saved to 'output/figures/main_results/fig2_portfolio_performance.png'")
log_message("✅ Script 06-2 finished successfully.")
log_message("--------------------------------------------------")
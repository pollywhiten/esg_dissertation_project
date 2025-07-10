#!/usr/bin/env Rscript

# Run policy interaction extension analysis

cat("\n--- POLICY EXTENSION ANALYSIS ---\n")

# Load libraries
source("01_scripts/00_setup/load_libraries.R")

# Run extension scripts
source("01_scripts/04_analysis/extension/04-1_merge_policy_data.R")
source("01_scripts/04_analysis/extension/04-2_construct_interactions.R")
source("01_scripts/04_analysis/extension/04-3_panel_regressions.R")
source("01_scripts/04_analysis/extension/04-4_robustness_checks.R")

# Create extension visualizations
source("01_scripts/05_visuals/06-3_plot_coefficient_interactions.R")

cat("\n✓ Extension analysis complete!\n")

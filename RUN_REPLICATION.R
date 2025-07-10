#!/usr/bin/env Rscript

# Run replication of Shanaev & Ghimire (2022)

cat("\n--- REPLICATION ANALYSIS ---\n")

# Load libraries
source("01_scripts/00_setup/load_libraries.R")

# Run replication scripts
source("01_scripts/04_analysis/replication/03-1_descriptive_stats.R")
source("01_scripts/04_analysis/replication/03-2_portfolio_construction.R")
source("01_scripts/04_analysis/replication/03-3_ff3_regressions.R")
source("01_scripts/04_analysis/replication/03-4_carhart4_regressions.R")
source("01_scripts/04_analysis/replication/03-5_subsample_analysis.R")

# Create replication visualizations
source("01_scripts/05_visuals/06-1_plot_change_frequency.R")
source("01_scripts/05_visuals/06-2_plot_portfolio_performance.R")

cat("\n✓ Replication analysis complete!\n")

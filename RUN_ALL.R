#!/usr/bin/env Rscript

# Master script to run entire ESG dissertation analysis

cat("\n========================================\n")
cat("ESG DISSERTATION PROJECT - FULL ANALYSIS\n")
cat("========================================\n\n")

# Load configuration
source("config.R")

# Check environment
cat("Step 1: Checking environment...\n")
source("01_scripts/00_setup/check_environment.R")

# Run data preparation
cat("\nStep 2: Preparing data...\n")
source("01_scripts/02_preparation/01-1_clean_sustainalytics.R")
source("01_scripts/02_preparation/01-2_process_reference_data.R")
source("01_scripts/02_preparation/01-3_clean_crsp.R")
source("01_scripts/02_preparation/01-4_clean_ff_factors.R")
source("01_scripts/02_preparation/01-5_clean_policy_data.R")

# Feature engineering
cat("\nStep 3: Feature engineering...\n")
source("01_scripts/03_feature_engineering/02-1_create_monthly_panels.R")
source("01_scripts/03_feature_engineering/02-2_identify_rating_changes.R")
source("01_scripts/03_feature_engineering/02-3_tag_bulk_updates.R")
source("01_scripts/03_feature_engineering/02-4_create_event_windows.R")
source("01_scripts/03_feature_engineering/02-5_merge_all_data.R")

# Run replication analysis
cat("\nStep 4: Running replication analysis...\n")
source("RUN_REPLICATION.R")

# Run extension analysis
cat("\nStep 5: Running policy extension analysis...\n")
source("RUN_EXTENSION.R")

# Generate final outputs
cat("\nStep 6: Creating visualizations...\n")
source("01_scripts/05_visuals/06-5_create_summary_figures.R")

cat("\n✓ Analysis complete! Check 02_output/ for results.\n")

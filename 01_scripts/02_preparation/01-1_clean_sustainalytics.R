# Clean Sustainalytics ESG Data
# This script processes the raw Sustainalytics data from long to wide format

source("01_scripts/00_setup/load_libraries.R")
source("config.R")

log_message("Starting Sustainalytics data cleaning...")

# Load raw data
sustainalytics <- fread(file.path(DATA_RAW, "esg", "Sustainalytics.csv"))

# [Add your data cleaning code here based on the Python notebook]

# Save cleaned data
saveRDS(sustainalytics_clean, file.path(DATA_CLEAN, "sustainalytics_panel.rds"))
log_message("Sustainalytics data cleaning complete")

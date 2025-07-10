# ==============================================================================
# 🔍 Explore Sustainalytics Data Structure
# ==============================================================================

# Source the configuration file to get project paths
source("config.R")

# Load necessary libraries from the central script
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

cat("\n🔍 Exploring Sustainalytics Data Structure\n")
cat("==========================================\n")

# Load a sample of the raw data
cat("Loading raw Sustainalytics data...\n")
sustainalytics_raw <- data.table::fread(file.path(DATA_RAW_ESG, "Sustainalytics.csv"), nrows = 1000)

cat("Original column names:\n")
print(names(sustainalytics_raw))

cat("\nColumn names after janitor::clean_names():\n")
sustainalytics_clean <- sustainalytics_raw %>% janitor::clean_names()
print(names(sustainalytics_clean))

cat("\nFirst few rows:\n")
print(head(sustainalytics_clean))

cat("\nUnique field names (first 20):\n")
if("fieldname" %in% names(sustainalytics_clean)) {
  print(head(unique(sustainalytics_clean$fieldname), 20))
} else if("field_name" %in% names(sustainalytics_clean)) {
  print(head(unique(sustainalytics_clean$field_name), 20))
} else {
  cat("Need to check column names manually\n")
  print(names(sustainalytics_clean))
}

cat("\nData structure:\n")
str(sustainalytics_clean)

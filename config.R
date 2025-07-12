# ==============================================================================
# 🔧 PROJECT CONFIGURATION FILE
# 🎓 ESG Dissertation Project: Replication and Extension of Shanaev & Ghimire (2022)
# 📊 King's College London - Pollyanna Whitenburgh
# ==============================================================================

# Load necessary packages for configuration
suppressPackageStartupMessages({
  library(here)
  library(lubridate)
})

# ==============================================================================
# 📁 PROJECT PATHS
# ==============================================================================

# Set project root using 'here' package for reproducibility
PROJECT_ROOT <- here::here()

# Data directories
DATA_RAW <- file.path(PROJECT_ROOT, "00_data", "raw")
DATA_RAW_ESG <- file.path(DATA_RAW, "esg")
DATA_RAW_FIN <- file.path(DATA_RAW, "financial")
DATA_RAW_POL <- file.path(DATA_RAW, "policy")

DATA_INTER <- file.path(PROJECT_ROOT, "00_data", "intermediate")
DATA_INTER_ESG <- file.path(DATA_INTER, "esg")
DATA_INTER_FIN <- file.path(DATA_INTER, "financial")
DATA_INTER_POL <- file.path(DATA_INTER, "policy")
DATA_INTER_EVT <- file.path(DATA_INTER, "events")

DATA_CLEAN <- file.path(PROJECT_ROOT, "00_data", "cleaned")
DATA_META <- file.path(PROJECT_ROOT, "00_data", "metadata")

# Output directories
OUTPUT_PATH <- file.path(PROJECT_ROOT, "02_output")
OUTPUT_TABLES <- file.path(OUTPUT_PATH, "tables")
OUTPUT_FIGURES <- file.path(OUTPUT_PATH, "figures")
OUTPUT_LOGS <- file.path(OUTPUT_PATH, "logs")

# Script directories
SCRIPTS_PATH <- file.path(PROJECT_ROOT, "01_scripts")
FUNCTIONS_PATH <- file.path(SCRIPTS_PATH, "01_functions")

# ==============================================================================
# ⚙️ ANALYSIS PARAMETERS
# ==============================================================================

# Portfolio construction parameters
HOLDING_PERIOD_MONTHS <- 12  # Months to hold stock after rating change
MIN_PORTFOLIO_SIZE <- 10     # Minimum firms required for portfolio

# Event study parameters
BULK_UPDATE_THRESHOLD <- 500  # Monthly changes above this = bulk update
TOP_SPIKE_MONTHS <- 6        # Number of spike months to identify

# Policy classification parameters
TOP_POLICY_STATES <- 10      # Top N states for "strong policy" (ACEEE)
POLICY_QUARTILES <- 4        # Number of quartiles for policy strength

# ==============================================================================
# 📅 DATE PARAMETERS
# ==============================================================================

# Full sample period
SAMPLE_START_DATE <- as.Date("2010-01-01")
SAMPLE_END_DATE <- as.Date("2024-12-31")

# Subsample for robustness (post-2016 as per paper)
SUBSAMPLE_START_DATE <- as.Date("2017-01-01")

# Date formatting
DATE_FORMAT <- "%Y-%m-%d"
MONTH_FORMAT <- "%Y-%m"

# ==============================================================================
# 📊 MODEL SPECIFICATIONS
# ==============================================================================

# Factor model definitions
FF3_FACTORS <- c("mkt_rf", "smb", "hml")  # Fama-French 3-factor
CARHART4_FACTORS <- c("mkt_rf", "smb", "hml", "mom")  # Carhart 4-factor

# Regression specifications
CLUSTER_VAR <- "cusip8"  # Variable for clustering standard errors
ROBUST_SE_TYPE <- "HC1"  # Heteroskedasticity-consistent SE type

# Significance levels
SIG_LEVELS <- c(0.01, 0.05, 0.10)
SIG_STARS <- c("***", "**", "*")

# ==============================================================================
# 📋 DATA SPECIFICATIONS
# ==============================================================================

# ESG rating categories and their numeric mapping
ESG_CATEGORIES <- c("Negligible", "Low", "Medium", "High", "Severe")
ESG_NUMERIC_MAP <- c(
  "Negligible" = 1,
  "Low" = 2,
  "Medium" = 3,
  "High" = 4,
  "Severe" = 5
)

# ESG leaders vs laggards threshold
ESG_LEADER_THRESHOLD <- 3  # Numeric score <= 3 is "Leader" (Negligible, Low, or Medium)

# Missing value indicators
MISSING_CODES <- c("", "NA", "N/A", "#N/A", "NULL", "None")

# ==============================================================================
# 🎨 OUTPUT FORMATTING
# ==============================================================================

# Table formatting
TABLE_DIGITS <- 4           # Decimal places in tables
TABLE_FORMAT <- "latex"     # Options: "latex", "html", "text"
TABLE_STAR_LEVELS <- c(0.01, 0.05, 0.10)

# Figure formatting
FIGURE_DPI <- 300          # Resolution for saved figures
FIGURE_WIDTH <- 12         # Default width in inches
FIGURE_HEIGHT <- 8         # Default height in inches
FIGURE_FORMAT <- "png"     # Options: "png", "pdf", "svg"

# Color schemes
COLOR_UPGRADE <- "#2E7D32"    # Green for upgrades
COLOR_DOWNGRADE <- "#C62828"  # Red for downgrades
COLOR_NEUTRAL <- "#757575"    # Grey for unchanged/neutral
COLOR_STRONG_POLICY <- "#1565C0"  # Blue for strong policy states
COLOR_WEAK_POLICY <- "#FF8F00"    # Orange for weak policy states

# ==============================================================================
# 🔍 LOGGING AND DEBUGGING
# ==============================================================================

# Create log file name with timestamp
LOG_TIMESTAMP <- format(Sys.time(), "%Y%m%d_%H%M%S")
LOG_FILE <- file.path(OUTPUT_LOGS, paste0("run_log_", LOG_TIMESTAMP, ".txt"))

# Debugging options
DEBUG_MODE <- FALSE  # Set TRUE for verbose output
SAVE_INTERMEDIATE <- TRUE  # Save intermediate datasets

# ==============================================================================
# 🛠️ UTILITY FUNCTIONS FOR CONFIG
# ==============================================================================

#' Create a timestamped log message
#' @param msg Character string with the message to log
#' @param type Type of message: "INFO", "WARNING", "ERROR"
log_message <- function(msg, type = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  formatted_msg <- sprintf("[%s] %s: %s", timestamp, type, msg)

  # Print to console
  cat(formatted_msg, "\n")

  # Write to log file if it exists
  if (file.exists(dirname(LOG_FILE))) {
    cat(formatted_msg, "\n", file = LOG_FILE, append = TRUE)
  }
}

#' Check if required data files exist
#' @return Logical indicating if all required files are present
check_data_files <- function() {
  required_files <- c(
    file.path(DATA_RAW_ESG, "Sustainalytics.csv"),
    file.path(DATA_RAW_ESG, "Reference_Data.csv"),
    file.path(DATA_RAW_FIN, "CRSP_Compustat.csv"),
    file.path(DATA_RAW_FIN, "F-F_Research_Data_Factors.csv"),
    file.path(DATA_RAW_POL, "state_policy_rankings.csv")
  )

  files_exist <- file.exists(required_files)

  if (!all(files_exist)) {
    missing <- required_files[!files_exist]
    log_message(paste("Missing data files:", paste(missing, collapse = ", ")), "WARNING")
    return(FALSE)
  }

  return(TRUE)
}

#' Create all necessary directories
ensure_directories <- function() {
  dirs <- c(DATA_INTER_ESG, DATA_INTER_FIN, DATA_INTER_POL, DATA_INTER_EVT,
            DATA_CLEAN, DATA_META, OUTPUT_TABLES, OUTPUT_FIGURES, OUTPUT_LOGS)

  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      log_message(paste("Created directory:", dir))
    }
  }
}

# ==============================================================================
# 🚀 INITIALIZE ON LOAD
# ==============================================================================

# Ensure all directories exist
ensure_directories()

# Create initial log entry
log_message("Configuration file loaded successfully")
log_message(paste("Project root:", PROJECT_ROOT))
log_message(paste("R version:", R.version.string))

# Check data files
if (check_data_files()) {
  log_message("All required data files found")
} else {
  log_message("Some data files are missing - see warnings above", "WARNING")
}

# ==============================================================================
# ✅ END OF CONFIGURATION
# ==============================================================================
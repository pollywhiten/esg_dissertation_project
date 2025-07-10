# ==============================================================================
# Load Libraries Script
# ESG Dissertation Project
# ==============================================================================
# This script loads all commonly used libraries and sets global options
# Source this at the beginning of each analysis script
# ==============================================================================

# Suppress startup messages for cleaner output
suppressPackageStartupMessages({
  
  # ==============================================================================
  # CORE DATA MANIPULATION
  # ==============================================================================
  
  # Tidyverse suite (pandas equivalent functionality)
  library(tidyverse)  # Includes: dplyr, tidyr, ggplot2, readr, purrr, tibble, stringr, forcats
  
  # High-performance alternatives
  library(data.table)  # Fast data manipulation for large datasets
  
  # Date and time handling
  library(lubridate)   # Date manipulation (Python datetime equivalent)
  library(zoo)         # For na.locf (forward fill) functionality
  
  # Data cleaning
  library(janitor)     # Clean column names, remove empty rows/cols
  
  # ==============================================================================
  # STATISTICAL AND ECONOMETRIC PACKAGES
  # ==============================================================================
  
  # Core econometrics
  library(plm)         # Panel data models
  library(lmtest)      # Testing linear regression models
  library(sandwich)    # Robust covariance matrix estimators
  library(car)         # Companion to Applied Regression
  
  # Model output handling
  library(broom)       # Convert model objects to tidy data frames
  library(stargazer)   # Regression and summary statistics tables
  
  # ==============================================================================
  # VISUALIZATION
  # ==============================================================================
  
  # Enhanced plotting capabilities (already loaded with tidyverse)
  # library(ggplot2)   
  library(ggthemes)    # Additional themes for ggplot2
  library(scales)      # Scale functions for visualizations
  library(patchwork)   # Combine multiple plots
  library(viridis)     # Color-blind friendly palettes
  
  # ==============================================================================
  # UTILITY PACKAGES
  # ==============================================================================
  
  # Project management
  library(here)        # Relative file paths
  
  # File I/O
  library(readxl)      # Read Excel files
  library(writexl)     # Write Excel files
  library(haven)       # Read/write SPSS, Stata, SAS files
  
  # Table creation
  library(gt)          # Create publication-ready tables
  library(knitr)       # Dynamic report generation
  library(kableExtra)  # Enhance kable tables
  
})

# ==============================================================================
# GLOBAL OPTIONS
# ==============================================================================

# Numeric display options
options(
  scipen = 999,        # Disable scientific notation
  digits = 4,          # Default number of digits to display
  max.print = 1000     # Limit console output
)

# Tidyverse options
options(
  dplyr.summarise.inform = FALSE,  # Suppress grouping messages
  readr.num_columns = 0            # Suppress column specification messages
)

# ==============================================================================
# GGPLOT2 THEME SETUP
# ==============================================================================

# Define custom theme for consistent plotting
theme_esg <- function(base_size = 12, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      # Text elements
      plot.title = element_text(face = "bold", size = rel(1.2), hjust = 0,
                                margin = margin(b = 10)),
      plot.subtitle = element_text(size = rel(1), hjust = 0,
                                   margin = margin(b = 10)),
      plot.caption = element_text(size = rel(0.8), hjust = 1,
                                  margin = margin(t = 10)),
      
      # Axis elements  
      axis.title = element_text(size = rel(1)),
      axis.text = element_text(size = rel(0.9)),
      axis.title.x = element_text(margin = margin(t = 10)),
      axis.title.y = element_text(margin = margin(r = 10)),
      
      # Legend
      legend.title = element_text(face = "bold", size = rel(0.9)),
      legend.text = element_text(size = rel(0.8)),
      legend.position = "bottom",
      
      # Panel
      panel.grid.minor = element_blank(),
      panel.border = element_blank(),
      
      # Strip (facet labels)
      strip.text = element_text(face = "bold", size = rel(1)),
      strip.background = element_rect(fill = "grey90", color = NA)
    )
}

# Set as default theme
theme_set(theme_esg())

# ==============================================================================
# COLOR PALETTES
# ==============================================================================

# Define project-specific color palettes
esg_colors <- list(
  # Main colors for rating changes
  upgrade = "#2E7D32",      # Green
  downgrade = "#C62828",    # Red  
  unchanged = "#757575",    # Grey
  
  # Policy strength colors
  strong_policy = "#1565C0", # Blue
  weak_policy = "#FF8F00",   # Orange
  
  # ESG risk categories
  negligible = "#4CAF50",   # Light green
  low = "#8BC34A",          # Lime
  medium = "#FFC107",       # Amber
  high = "#FF5722",         # Deep orange
  severe = "#B71C1C",       # Dark red
  
  # General purpose
  primary = "#1976D2",      # Blue
  secondary = "#424242",    # Dark grey
  accent = "#7B1FA2"        # Purple
)

# Function to access colors easily
esg_col <- function(name) {
  if (name %in% names(esg_colors)) {
    return(esg_colors[[name]])
  } else {
    warning(paste("Color", name, "not found. Using default."))
    return("#000000")
  }
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

#' Print session information and loaded packages
#' Useful for reproducibility documentation
print_session_info <- function() {
  cat("\n=== SESSION INFORMATION ===\n")
  cat("R Version:", R.version.string, "\n")
  cat("Platform:", R.version$platform, "\n")
  cat("Date:", format(Sys.Date(), "%Y-%m-%d"), "\n\n")
  
  cat("Loaded Packages:\n")
  loaded_pkgs <- (.packages())
  pkg_versions <- sapply(loaded_pkgs, function(x) as.character(packageVersion(x)))
  
  pkg_info <- data.frame(
    Package = loaded_pkgs,
    Version = pkg_versions,
    row.names = NULL
  )
  
  print(pkg_info[order(pkg_info$Package), ], row.names = FALSE)
  cat("\n")
}

#' Check if all required packages are loaded
#' @return Logical indicating if all packages loaded successfully
check_loaded_packages <- function() {
  required <- c("tidyverse", "data.table", "plm", "sandwich", "lubridate")
  loaded <- (.packages())
  
  missing <- setdiff(required, loaded)
  
  if (length(missing) > 0) {
    warning(paste("Missing packages:", paste(missing, collapse = ", ")))
    return(FALSE)
  }
  
  return(TRUE)
}

# ==============================================================================
# DATA.TABLE OPTIMIZATION
# ==============================================================================

# Set data.table threads for parallel processing
# Adjust based on your system (use 1 for reproducibility)
setDTthreads(threads = parallel::detectCores() - 1)

# ==============================================================================
# CUSTOM OPERATORS
# ==============================================================================

# Not in operator (Python-style)
`%nin%` <- function(x, table) {
  !(x %in% table)
}

# ==============================================================================
# DISPLAY MESSAGE
# ==============================================================================

cat("\n✅ Libraries loaded successfully!\n")
cat("📊 Theme 'theme_esg()' set as default\n")
cat("🎨 Color palette available via 'esg_col()' function\n")
cat("💡 Run 'print_session_info()' for full environment details\n\n")

# Check if all core packages loaded
if (!check_loaded_packages()) {
  cat("⚠️  Warning: Some required packages failed to load\n")
  cat("   Run 'install_packages.R' to install missing packages\n\n")
}

# ==============================================================================
# END OF LOAD LIBRARIES SCRIPT
# ==============================================================================
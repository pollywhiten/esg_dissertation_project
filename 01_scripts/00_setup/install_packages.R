# ==============================================================================
# Package Installation Script
# ESG Dissertation Project
# ==============================================================================
# This script installs all required packages for the analysis
# Includes mapping from Python libraries to R equivalents
# ==============================================================================

cat("\n====================================================\n")
cat("     ESG Project - Package Installation Script      \n")
cat("====================================================\n\n")

# ==============================================================================
# PACKAGE LISTS WITH PYTHON EQUIVALENTS
# ==============================================================================

# Core data manipulation packages
# Python: pandas, numpy → R: tidyverse, data.table
data_packages <- c(
  "tidyverse",     # dplyr, tidyr, ggplot2, etc. (pandas equivalent)
  "data.table",    # High-performance data manipulation
  "lubridate",     # Date/time handling (datetime equivalent)
  "zoo",           # Time series, na.locf (fillna equivalent)
  "janitor",       # Data cleaning utilities
  "here"           # Project-relative paths
)

# Statistical and econometric packages
# Python: statsmodels, scipy → R: various specialized packages
stats_packages <- c(
  "lmtest",        # Linear model tests
  "sandwich",      # Robust standard errors (statsmodels cov_type='HC1')
  "plm",           # Panel data models
  "car",           # Regression diagnostics
  "broom",         # Tidy model outputs
  "moments"        # Skewness, kurtosis calculations
)

# Financial analysis packages
# Python: custom functions → R: specialized packages
finance_packages <- c(
  "PerformanceAnalytics",  # Portfolio analytics
  "quantmod",              # Financial data handling
  "tseries",               # Time series analysis
  "xts"                    # Extensible time series
)

# Visualization packages
# Python: matplotlib, seaborn → R: ggplot2 and extensions
viz_packages <- c(
  "ggplot2",       # (Included in tidyverse)
  "ggthemes",      # Additional themes
  "scales",        # Axis formatting
  "patchwork",     # Combine plots (matplotlib subplots)
  "ggrepel",       # Label positioning
  "viridis",       # Color scales
  "plotly"         # Interactive plots (plotly equivalent)
)

# Reporting and table packages
# Python: custom formatting → R: specialized packages
reporting_packages <- c(
  "stargazer",     # Regression tables
  "gt",            # Publication-ready tables
  "knitr",         # Dynamic reporting
  "kableExtra"     # Enhanced tables
)

# Utility packages
utility_packages <- c(
  "haven",         # Read SPSS/Stata/SAS files
  "readxl",        # Read Excel files
  "writexl",       # Write Excel files
  "httr",          # HTTP requests (requests equivalent)
  "jsonlite",      # JSON handling (json equivalent)
  "parallel",      # Parallel processing
  "foreach",       # Parallel loops
  "doParallel"     # Parallel backend
)

# Development and environment packages
dev_packages <- c(
  "devtools",      # Package development tools
  "renv",          # Package management (pip/conda equivalent)
  "testthat",      # Unit testing (pytest equivalent)
  "profvis"        # Performance profiling
)

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

#' Install packages if not already installed
#' @param packages Character vector of package names
#' @param category Name of package category for display
install_if_missing <- function(packages, category = "General") {
  cat("\n📦 Checking", category, "packages...\n")
  cat(paste(rep("-", 50), collapse = ""), "\n")

  installed_count <- 0
  new_install_count <- 0

  for (pkg in packages) {
    # Check if package is installed
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cat("  ⬇️  Installing:", pkg, "...")

      # Try to install
      tryCatch({
        install.packages(pkg, quiet = TRUE, repos = "https://cloud.r-project.org")
        cat(" ✅ Success\n")
        new_install_count <- new_install_count + 1
      }, error = function(e) {
        cat(" ❌ Failed\n")
        cat("     Error:", e$message, "\n")
      })
    } else {
      cat("  ✓ Already installed:", pkg, 
          "(v", as.character(packageVersion(pkg)), ")\n")
      installed_count <- installed_count + 1
    }
  }

  cat("\nSummary:", installed_count, "already installed,", 
      new_install_count, "newly installed\n")

  return(invisible(NULL))
}

#' Check if a package can be loaded
#' @param pkg Package name
#' @return Logical indicating if package loads successfully
check_package_load <- function(pkg) {
  suppressWarnings(suppressMessages(
    require(pkg, character.only = TRUE, quietly = TRUE)
  ))
}

# ==============================================================================
# MAIN INSTALLATION PROCESS
# ==============================================================================

# Record start time
start_time <- Sys.time()

cat("Starting package installation...\n")
cat("This may take several minutes on first run.\n")

# Install packages by category
install_if_missing(data_packages, "Data Manipulation")
install_if_missing(stats_packages, "Statistical/Econometric")
install_if_missing(finance_packages, "Financial Analysis")
install_if_missing(viz_packages, "Visualization")
install_if_missing(reporting_packages, "Reporting/Tables")
install_if_missing(utility_packages, "Utility")
install_if_missing(dev_packages, "Development")

# ==============================================================================
# VERIFICATION
# ==============================================================================

cat("\n\n🔍 Verifying package installation...\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

# Combine all packages
all_packages <- unique(c(
  data_packages, stats_packages, finance_packages,
  viz_packages, reporting_packages, utility_packages, dev_packages
))

# Remove duplicates and sort
all_packages <- sort(unique(all_packages))

# Check each package
failed_packages <- character()
successful_packages <- character()

for (pkg in all_packages) {
  if (check_package_load(pkg)) {
    successful_packages <- c(successful_packages, pkg)
  } else {
    failed_packages <- c(failed_packages, pkg)
  }
}

# Report results
cat("\n📊 Installation Summary:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")
cat("Total packages:", length(all_packages), "\n")
cat("✅ Successfully installed:", length(successful_packages), "\n")
cat("❌ Failed installations:", length(failed_packages), "\n")

if (length(failed_packages) > 0) {
  cat("\n⚠️  Failed packages:\n")
  for (pkg in failed_packages) {
    cat("  -", pkg, "\n")
  }
  cat("\nTry installing failed packages manually with:\n")
  cat("install.packages(c(", paste0('"', failed_packages, '"', collapse = ", "), "))\n")
}

# ==============================================================================
# PYTHON TO R PACKAGE MAPPING REFERENCE
# ==============================================================================

cat("\n\n📘 Python to R Package Reference:\n")
cat(paste(rep("=", 50), collapse = ""), "\n")

mapping <- data.frame(
  Python = c("pandas", "numpy", "matplotlib/seaborn", "statsmodels", 
             "scipy.stats", "requests", "json", "datetime"),
  R = c("dplyr/data.table", "base R", "ggplot2", "plm/sandwich", 
        "stats (base)", "httr", "jsonlite", "lubridate"),
  stringsAsFactors = FALSE
)

print(mapping, row.names = FALSE)

# ==============================================================================
# ENVIRONMENT SETUP RECOMMENDATIONS
# ==============================================================================

cat("\n\n💡 Next Steps:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")
cat("1. Run 'renv::init()' to initialize package management\n")
cat("2. Source 'load_libraries.R' to load common packages\n")
cat("3. Run 'check_environment.R' to verify setup\n")

# Record end time
end_time <- Sys.time()
duration <- round(difftime(end_time, start_time, units = "mins"), 2)

cat("\n⏱️  Total installation time:", duration, "minutes\n")
cat("\n✅ Package installation script completed!\n\n")

# ==============================================================================
# SAVE PACKAGE INFORMATION
# ==============================================================================

# Create a record of installed packages
if (!dir.exists("00_data/metadata")) {
  dir.create("00_data/metadata", recursive = TRUE, showWarnings = FALSE)
}

# Save package info
package_info <- data.frame(
  package = successful_packages,
  version = sapply(successful_packages, function(x) as.character(packageVersion(x))),
  install_date = Sys.Date(),
  row.names = NULL
)

write.csv(package_info, 
          file = "00_data/metadata/installed_packages.csv",
          row.names = FALSE)

cat("📄 Package information saved to: 00_data/metadata/installed_packages.csv\n")

# ==============================================================================
# END OF INSTALLATION SCRIPT
# ==============================================================================
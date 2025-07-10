# ==============================================================================
# Environment Check Script
# ESG Dissertation Project
# ==============================================================================
# This script verifies that the R environment is properly configured
# Checks: R version, packages, data files, directory structure
# ==============================================================================

cat("\n==============================================================\n")
cat("          ESG PROJECT ENVIRONMENT VERIFICATION                \n")
cat("==============================================================\n")

# ==============================================================================
# R VERSION CHECK
# ==============================================================================

cat("\n📊 R Environment:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Get R version info
r_version <- R.version
cat("R Version:", r_version$version.string, "\n")
cat("Platform:", r_version$platform, "\n")
cat("OS:", r_version$os, "\n")
cat("Locale:", Sys.getlocale("LC_COLLATE"), "\n")

# Check R version (recommend 4.0 or higher)
r_version_numeric <- as.numeric(paste0(r_version$major, ".", 
                                       strsplit(r_version$minor, "\\.")[[1]][1]))
if (r_version_numeric < 4.0) {
  cat("\n⚠️  Warning: R version is below 4.0. Consider updating for best compatibility.\n")
} else {
  cat("\n✅ R version is 4.0 or higher - Good!\n")
}

# ==============================================================================
# REQUIRED PACKAGES CHECK
# ==============================================================================

cat("\n\n📦 Required Packages Status:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Define required packages with minimum versions
required_packages <- list(
  # Data manipulation
  tidyverse = "1.3.0",
  data.table = "1.14.0",
  lubridate = "1.8.0",
  zoo = "1.8.0",
  janitor = "2.1.0",
  here = "1.0.0",
  
  # Statistics and econometrics
  plm = "2.6.0",
  lmtest = "0.9.0",
  sandwich = "3.0.0",
  car = "3.0.0",
  broom = "0.7.0",
  
  # Visualization
  ggplot2 = "3.3.0",
  ggthemes = "4.2.0",
  scales = "1.1.0",
  patchwork = "1.1.0",
  
  # Tables and reporting
  stargazer = "5.2.0",
  gt = "0.3.0",
  knitr = "1.30",
  
  # File I/O
  readxl = "1.3.0",
  writexl = "1.3.0",
  haven = "2.4.0"
)

# Check each package
package_status <- data.frame(
  Package = character(),
  Required = character(),
  Installed = character(),
  Status = character(),
  stringsAsFactors = FALSE
)

for (pkg in names(required_packages)) {
  required_version <- required_packages[[pkg]]
  
  if (requireNamespace(pkg, quietly = TRUE)) {
    installed_version <- as.character(packageVersion(pkg))
    version_ok <- compareVersion(installed_version, required_version) >= 0
    
    status <- ifelse(version_ok, "✅ OK", "⚠️  Update needed")
    
    package_status <- rbind(package_status, data.frame(
      Package = pkg,
      Required = paste(">=", required_version),
      Installed = installed_version,
      Status = status,
      stringsAsFactors = FALSE
    ))
  } else {
    package_status <- rbind(package_status, data.frame(
      Package = pkg,
      Required = paste(">=", required_version),
      Installed = "Not installed",
      Status = "❌ Missing",
      stringsAsFactors = FALSE
    ))
  }
}

# Display package status
print(package_status, row.names = FALSE)

# Summary
missing_pkgs <- sum(package_status$Status == "❌ Missing")
update_pkgs <- sum(package_status$Status == "⚠️  Update needed")

cat("\nSummary:\n")
cat("  ✅ OK:", sum(package_status$Status == "✅ OK"), "packages\n")
cat("  ⚠️  Updates needed:", update_pkgs, "packages\n")
cat("  ❌ Missing:", missing_pkgs, "packages\n")

if (missing_pkgs > 0) {
  cat("\nRun 'source(\"01_scripts/00_setup/install_packages.R\")' to install missing packages.\n")
}

# ==============================================================================
# PROJECT STRUCTURE CHECK
# ==============================================================================

cat("\n\n📁 Project Structure:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Define expected directories
expected_dirs <- c(
  "00_data/raw/esg",
  "00_data/raw/financial", 
  "00_data/raw/policy",
  "00_data/intermediate",
  "00_data/cleaned",
  "00_data/metadata",
  "01_scripts/00_setup",
  "01_scripts/01_functions",
  "01_scripts/02_preparation",
  "01_scripts/03_feature_engineering",
  "01_scripts/04_analysis",
  "01_scripts/05_visuals",
  "02_output/tables",
  "02_output/figures",
  "02_output/logs"
)

# Check each directory
dir_check <- sapply(expected_dirs, dir.exists)
existing_dirs <- sum(dir_check)

cat("Directories found:", existing_dirs, "of", length(expected_dirs), "\n")

if (existing_dirs < length(expected_dirs)) {
  cat("\nMissing directories:\n")
  missing_dirs <- expected_dirs[!dir_check]
  for (dir in missing_dirs) {
    cat("  ❌", dir, "\n")
  }
  cat("\nRun the setup script to create missing directories.\n")
} else {
  cat("✅ All expected directories exist\n")
}

# ==============================================================================
# DATA FILES CHECK
# ==============================================================================

cat("\n\n📄 Data Files Status:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Define expected data files
data_files <- list(
  "ESG Data" = c(
    "00_data/raw/esg/Sustainalytics.csv",
    "00_data/raw/esg/Reference_Data.csv"
  ),
  "Financial Data" = c(
    "00_data/raw/financial/CRSP_Compustat.csv",
    "00_data/raw/financial/F-F_Research_Data_Factors.csv",
    "00_data/raw/financial/F-F_Momentum_Factor.csv"
  ),
  "Policy Data" = c(
    "00_data/raw/policy/state_policy_rankings.csv",
    "00_data/raw/policy/state_rps_panel_1990_2024.csv"
  )
)

# Check each category
all_files_present <- TRUE

for (category in names(data_files)) {
  cat("\n", category, ":\n", sep = "")
  files <- data_files[[category]]
  
  for (file in files) {
    if (file.exists(file)) {
      file_size <- file.info(file)$size / 1024^2  # Size in MB
      cat(sprintf("  ✅ %s (%.1f MB)\n", basename(file), file_size))
    } else {
      cat(sprintf("  ❌ %s - NOT FOUND\n", basename(file)))
      all_files_present <- FALSE
    }
  }
}

if (!all_files_present) {
  cat("\n⚠️  Some data files are missing. Please ensure all data files are in place.\n")
}

# ==============================================================================
# MEMORY AND SYSTEM RESOURCES
# ==============================================================================

cat("\n\n💻 System Resources:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Memory info
mem_info <- gc()
cat("Memory Usage:\n")
cat(sprintf("  Used: %.1f MB\n", sum(mem_info[, 2])))
cat(sprintf("  Max used: %.1f MB\n", sum(mem_info[, 6])))

# Check available memory (platform-specific)
if (.Platform$OS.type == "unix") {
  # For Mac/Linux
  total_mem <- as.numeric(system("sysctl -n hw.memsize", intern = TRUE)) / 1024^3
  cat(sprintf("  Total system: %.1f GB\n", total_mem))
} else {
  # For Windows
  mem <- memory.limit()
  cat(sprintf("  Memory limit: %.1f GB\n", mem/1024))
}

# CPU cores
cores <- parallel::detectCores()
cat(sprintf("\nCPU Cores: %d\n", cores))
cat(sprintf("data.table threads: %d\n", data.table::getDTthreads()))

# ==============================================================================
# TEST BASIC OPERATIONS
# ==============================================================================

cat("\n\n🧪 Testing Basic Operations:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Test 1: Create a data.table
test_results <- list()

tryCatch({
  dt <- data.table::data.table(x = 1:1000, y = rnorm(1000))
  test_results$data_table <- "✅ data.table creation works"
}, error = function(e) {
  test_results$data_table <- "❌ data.table creation failed"
})

# Test 2: Create a tibble and use dplyr
tryCatch({
  df <- tibble::tibble(x = 1:100, y = rnorm(100)) %>%
    dplyr::mutate(z = x + y) %>%
    dplyr::filter(z > 0)
  test_results$tidyverse <- "✅ tidyverse operations work"
}, error = function(e) {
  test_results$tidyverse <- "❌ tidyverse operations failed"
})

# Test 3: Date operations
tryCatch({
  dates <- lubridate::ymd("2023-01-01") + months(0:11)
  test_results$dates <- "✅ Date operations work"
}, error = function(e) {
  test_results$dates <- "❌ Date operations failed"
})

# Test 4: Basic plot
tryCatch({
  p <- ggplot2::ggplot(data.frame(x = 1:10, y = 1:10), 
                       ggplot2::aes(x, y)) + 
       ggplot2::geom_point()
  test_results$plotting <- "✅ Plotting works"
}, error = function(e) {
  test_results$plotting <- "❌ Plotting failed"
})

# Display test results
for (test in names(test_results)) {
  cat(" ", test_results[[test]], "\n")
}

# ==============================================================================
# CONFIGURATION CHECK
# ==============================================================================

cat("\n\n⚙️  Configuration:\n")
cat(paste(rep("-", 50), collapse = ""), "\n")

# Check if config.R exists and can be sourced
if (file.exists("config.R")) {
  tryCatch({
    source("config.R", local = TRUE)
    cat("✅ config.R loaded successfully\n")
    cat("  Project root:", PROJECT_ROOT, "\n")
    cat("  Data directory:", DATA_RAW, "\n")
    cat("  Output directory:", OUTPUT_PATH, "\n")
  }, error = function(e) {
    cat("❌ Error loading config.R:", e$message, "\n")
  })
} else {
  cat("❌ config.R not found in project root\n")
}

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

cat("\n\n" , paste(rep("=", 50), collapse = ""), "\n")
cat("                    SUMMARY                    \n")
cat(paste(rep("=", 50), collapse = ""), "\n")

# Collect all checks
checks <- c(
  r_version = r_version_numeric >= 4.0,
  packages = missing_pkgs == 0,
  directories = existing_dirs == length(expected_dirs),
  data_files = all_files_present,
  config = file.exists("config.R")
)

passed <- sum(checks)
total <- length(checks)

if (passed == total) {
  cat("\n✅ ALL CHECKS PASSED! Environment is ready for analysis.\n")
  cat("\nNext steps:\n")
  cat("1. Source specific analysis scripts as needed\n")
  cat("2. Or run 'source(\"RUN_ALL.R\")' to execute full pipeline\n")
} else {
  cat("\n⚠️  Some checks failed (", passed, "/", total, " passed)\n", sep = "")
  cat("\nPlease address the issues above before proceeding.\n")
}

cat("\n📝 For detailed setup instructions, see README.md\n")
cat(paste(rep("=", 50), collapse = ""), "\n\n")

# ==============================================================================
# SAVE ENVIRONMENT REPORT
# ==============================================================================

# Create logs directory if needed
if (!dir.exists("02_output/logs")) {
  dir.create("02_output/logs", recursive = TRUE, showWarnings = FALSE)
}

# Save detailed environment info
sink("02_output/logs/environment_check.txt")
cat("Environment Check Report\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat(paste(rep("=", 50), collapse = ""), "\n\n")

cat("R Version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n\n")

cat("Package Status:\n")
print(package_status, row.names = FALSE)

cat("\n\nSession Info:\n")
print(sessionInfo())
sink()

cat("\n📄 Detailed report saved to: 02_output/logs/environment_check.txt\n")

# ==============================================================================
# END OF ENVIRONMENT CHECK
# ==============================================================================
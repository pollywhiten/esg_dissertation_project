# Check R environment and package versions

cat("R Version:", R.version.string, "\n\n")

# Check required packages
required_packages <- c(
  "tidyverse", "data.table", "plm", "sandwich", "stargazer"
)

cat("Package Status:\n")
for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("✓ %s: %s\n", pkg, packageVersion(pkg)))
  } else {
    cat(sprintf("✗ %s: NOT INSTALLED\n", pkg))
  }
}

# Check data files
cat("\nData Files Status:\n")
data_files <- c(
  "00_data/raw/esg/Sustainalytics.csv",
  "00_data/raw/financial/CRSP_Compustat.csv",
  "00_data/raw/policy/state_policy_rankings.csv"
)

for (file in data_files) {
  if (file.exists(file)) {
    cat(sprintf("✓ %s\n", file))
  } else {
    cat(sprintf("✗ %s NOT FOUND\n", file))
  }
}

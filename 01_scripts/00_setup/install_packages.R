# Install required packages for ESG dissertation project

# Package installation script
packages <- c(
  # Data manipulation
  "tidyverse", "data.table", "lubridate", "zoo",
  
  # Panel data and econometrics
  "plm", "lmtest", "sandwich", "car", "stargazer",
  
  # Additional utilities
  "here", "janitor", "haven", "readxl", "writexl",
  
  # Visualization
  "ggplot2", "ggthemes", "scales", "patchwork", "gt"
)

# Install packages not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
  }
}

lapply(packages, install_if_missing)

# Install development packages if needed
if (!require("devtools")) install.packages("devtools")

cat("All packages installed successfully!\n")

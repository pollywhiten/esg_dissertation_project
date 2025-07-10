# Load all required libraries

# Data manipulation
library(tidyverse)
library(data.table)
library(lubridate)
library(zoo)

# Panel data and econometrics
library(plm)
library(lmtest)
library(sandwich)
library(car)
library(stargazer)

# Utilities
library(here)
library(janitor)

# Set options
options(scipen = 999)  # Disable scientific notation
options(digits = 4)    # Set decimal places

# Set theme for plots
theme_set(theme_minimal())

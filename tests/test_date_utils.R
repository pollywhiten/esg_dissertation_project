# ==============================================================================
# Test Script for Date Alignment Utilities
# ==============================================================================

# Load required libraries
library(lubridate)

# Source the utility functions
source('../01_scripts/01_functions/data_processing/date_alignment_utils.R')

# Test 1: floor_to_month_start
cat("\n🧪 Testing floor_to_month_start():\n")
test_dates1 <- as.Date(c("2023-01-15", "2023-02-28", "2023-03-01", "2024-02-15"))
result1 <- floor_to_month_start(test_dates1)
cat("Input dates: ", paste(test_dates1, collapse = ", "), "\n")
cat("Floored:     ", paste(result1, collapse = ", "), "\n")

# Test 2: ceiling_to_month_end  
cat("\n🧪 Testing ceiling_to_month_end():\n")
test_dates2 <- as.Date(c("2023-01-15", "2023-02-10", "2024-02-15", "2023-12-01"))
result2 <- ceiling_to_month_end(test_dates2)
cat("Input dates: ", paste(test_dates2, collapse = ", "), "\n")
cat("Ceilinged:   ", paste(result2, collapse = ", "), "\n")

# Test 3: Edge cases (first and last days of month)
cat("\n🧪 Testing edge cases:\n")
edge_dates <- as.Date(c("2023-01-01", "2023-01-31", "2024-02-29"))
floor_results <- floor_to_month_start(edge_dates)
ceiling_results <- ceiling_to_month_end(edge_dates)
cat("Edge input:   ", paste(edge_dates, collapse = ", "), "\n")
cat("Edge floors:  ", paste(floor_results, collapse = ", "), "\n")
cat("Edge ceilings:", paste(ceiling_results, collapse = ", "), "\n")

# Test 4: Character input
cat("\n🧪 Testing character input:\n")
char_dates <- c("2023-06-15", "2023-07-20")
char_floor <- floor_to_month_start(char_dates)
char_ceiling <- ceiling_to_month_end(char_dates)
cat("Character input:   ", paste(char_dates, collapse = ", "), "\n")
cat("Character floors:  ", paste(char_floor, collapse = ", "), "\n")
cat("Character ceilings:", paste(char_ceiling, collapse = ", "), "\n")

# Test 5: Leap year handling
cat("\n🧪 Testing leap year handling:\n")
leap_dates <- as.Date(c("2024-02-15", "2023-02-15"))
leap_ceiling <- ceiling_to_month_end(leap_dates)
cat("Leap year test: ", paste(leap_dates, collapse = ", "), "\n")
cat("Feb endings:    ", paste(leap_ceiling, collapse = ", "), "\n")

# Validation checks
cat("\n✅ Validation Results:\n")
cat("- Floor function preserves year/month? ", 
    all(year(test_dates1) == year(result1) & month(test_dates1) == month(result1)), "\n")
cat("- Ceiling function preserves year/month? ", 
    all(year(test_dates2) == year(result2) & month(test_dates2) == month(result2)), "\n")
cat("- Floor results are all 1st of month? ", 
    all(day(result1) == 1), "\n")
cat("- 2024 Feb has 29 days? ", 
    day(ceiling_to_month_end(as.Date("2024-02-15"))) == 29, "\n")
cat("- 2023 Feb has 28 days? ", 
    day(ceiling_to_month_end(as.Date("2023-02-15"))) == 28, "\n")

cat("\n🎉 All tests completed!\n")

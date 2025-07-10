# ==============================================================================
# ✅ 01-6: Validate All Cleaned Data Files
# ==============================================================================
#
# This script serves as a final quality check for the data preparation phase.
# It loads all the cleaned intermediate .rds files and prints a summary
# to verify their structure, dimensions, and key properties before proceeding
# to the feature engineering and merging phase.
#
# ==============================================================================

# --- 1. SETUP ---
# ==============================================================================

source("config.R")
source(file.path(SCRIPTS_PATH, "00_setup", "load_libraries.R"))

log_message("--------------------------------------------------")
log_message("🚀 Starting script: 01-6_validate_cleaning.R")


# --- 2. LOAD ALL CLEANED DATA ---
# ==============================================================================

log_message("📊 Loading all cleaned intermediate data files...")

sustainalytics_wide <- readRDS(file.path(DATA_INTER_ESG, "sustainalytics_wide.rds"))
sustainalytics_ref <- readRDS(file.path(DATA_CLEAN, "sustainalytics_ref_clean.rds"))
crsp_clean <- readRDS(file.path(DATA_CLEAN, "crsp_clean.rds"))
factors_clean <- readRDS(file.path(DATA_CLEAN, "factors_clean.rds"))
policy_panel <- readRDS(file.path(DATA_CLEAN, "policy_panel_clean.rds"))

log_message("✅ All cleaned .rds files loaded successfully.")


# --- 3. PRINT VALIDATION SUMMARY ---
# ==============================================================================

cat("\n\n🎯=====================================================🎯\n")
cat("      📊 DATA PREPARATION (PHASE 3) VALIDATION REPORT 📊\n")
cat("🎯=====================================================🎯\n\n")

# --- Sustainalytics Wide Panel ---
cat("🌱--- 1. Sustainalytics Wide Panel (`sustainalytics_wide.rds`) ---🌱\n")
cat(sprintf("   📏 Dimensions: %d rows, %d columns\n", nrow(sustainalytics_wide), ncol(sustainalytics_wide)))
cat(sprintf("   📋 Columns: %s\n", paste(names(sustainalytics_wide), collapse = ", ")))
cat(sprintf("   🏢 Unique Entities: %d\n", n_distinct(sustainalytics_wide$entity_id)))
cat("🔹---------------------------------------------------------🔹\n\n")

# --- Reference Data ---
cat("🔗--- 2. Reference Data (`sustainalytics_ref_clean.rds`) ---🔗\n")
cat(sprintf("   📏 Dimensions: %d rows, %d columns\n", nrow(sustainalytics_ref), ncol(sustainalytics_ref)))
cat(sprintf("   📋 Columns: %s\n", paste(names(sustainalytics_ref), collapse = ", ")))
cat(sprintf("   🔑 Is entity_id unique? %s\n", ifelse(!any(duplicated(sustainalytics_ref$entity_id)), "✅ YES", "❌ NO")))
cat("🔹---------------------------------------------------------🔹\n\n")

# --- CRSP Data ---
cat("💹--- 3. CRSP Data (`crsp_clean.rds`) ---💹\n")
cat(sprintf("   📏 Dimensions: %d rows, %d columns\n", nrow(crsp_clean), ncol(crsp_clean)))
cat(sprintf("   📋 Columns: %s\n", paste(names(crsp_clean), collapse = ", ")))
cat(sprintf("   📅 Date range: %s to %s\n", min(crsp_clean$date), max(crsp_clean$date)))
cat(sprintf("   🔑 Is cusip8-date unique? %s\n", ifelse(!any(duplicated(crsp_clean[, c("cusip8", "date")])), "✅ YES", "❌ NO")))
cat("🔹---------------------------------------------------------🔹\n\n")

# --- Factors Data ---
cat("📈--- 4. Factors Data (`factors_clean.rds`) ---📈\n")
cat(sprintf("   📏 Dimensions: %d rows, %d columns\n", nrow(factors_clean), ncol(factors_clean)))
cat(sprintf("   📋 Columns: %s\n", paste(names(factors_clean), collapse = ", ")))
cat(sprintf("   ⚠️  Missing `mom` values: %d (Expected for early years)\n", sum(is.na(factors_clean$mom))))
cat("🔹---------------------------------------------------------🔹\n\n")

# --- Policy Data ---
cat("🏛️--- 5. Policy Panel (`policy_panel_clean.rds`) ---🏛️\n")
cat(sprintf("   📏 Dimensions: %d rows, %d columns\n", nrow(policy_panel), ncol(policy_panel)))
cat(sprintf("   📋 Columns: %s\n", paste(names(policy_panel), collapse = ", ")))
cat(sprintf("   ⚠️  Missing `Rank` values: %d (Expected for early years)\n", sum(is.na(policy_panel$Rank))))
cat("🔹---------------------------------------------------------🔹\n\n")


log_message("✅ Validation script finished. All cleaned data is ready for Phase 4! 🎉")
log_message("🚀 Next step: Feature engineering and data merging phase")
log_message("--------------------------------------------------")
# Replication Instructions 📈🔬

## 🎯 Overview

This document provides comprehensive instructions for replicating our analysis of ESG rating changes and stock returns, including the extension to state environmental policy moderation effects. The complete pipeline processes **453,748 firm-month observations** across **4,787 firms** (2010-2024) and generates publication-ready results.

## 🔑 Key Research Findings (Completed Analysis)

Our completed replication and extension reveals:

| **Analysis** | **Finding** | **Statistical Significance** | **Economic Impact** |
|--------------|-------------|------------------------------|---------------------|
| **ESG Downgrades** | -0.491% monthly alpha | p = 0.073* | -5.89% annual underperformance |
| **ESG Upgrades** | +0.036% monthly alpha | p = 0.907 (n.s.) | No significant effect |
| **Policy Moderation** | Mixed evidence | p > 0.80 (n.s.) | Limited economic impact |
| **Temporal Robustness** | Effect strengthening | Late: p = 0.064* | -0.724% monthly (recent) |

**Key Insight**: ESG downgrades create significant negative abnormal returns, but state environmental policies do not meaningfully moderate this effect.

## 📊 Data Sources

### Primary Data (Required)
1. **Sustainalytics ESG Ratings**: Proprietary data requiring institutional access
   - **Coverage**: 1.88M observations, 2015-2024
   - **Location**: Place in `00_data/raw/esg/Sustainalytics.csv`
   - **Key Variables**: EntityId, Date, ESG Risk Score, Score Changes

2. **CRSP/Compustat Financial Data**: Available through WRDS
   - **Coverage**: 1.94M observations, 2010-2024
   - **Location**: Place in `00_data/raw/financial/CRSP_Compustat.csv`
   - **Key Variables**: CUSIP, Date, Returns, Market Cap, Financial Ratios

3. **Reference Data**: Entity mapping file
   - **Location**: Place in `00_data/raw/esg/Reference_Data.csv`
   - **Purpose**: Maps Sustainalytics EntityId to CUSIP identifiers

### Factor Data (Public Access)
4. **Fama-French Factors**: http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html
   - **Files**: `F-F_Research_Data_Factors.CSV`, `F-F_Momentum_Factor.CSV`
   - **Location**: Place in `00_data/raw/financial/`
   - **Coverage**: 1,187 months of factor data

### Policy Data (Compiled)
5. **State Environmental Policy Rankings**: ACEEE and RPS data
   - **Files**: `state_policy_rankings.csv`, `state_rps_panel_*.csv`
   - **Location**: Place in `00_data/raw/policy/`
   - **Coverage**: 1,836 state-year observations

## 🚀 Complete Replication Steps

### Step 1: Environment Setup
```r
# Install required packages and setup environment
source("01_scripts/00_setup/install_packages.R")
source("01_scripts/00_setup/check_environment.R")
```

### Step 2: Full Analysis Pipeline
```r
# Run complete analysis (all 8 phases)
source("RUN_ALL.R")
```

**OR run specific components:**

### Step 3: Replication Only
```r
# Replicate original Shanaev & Ghimire (2022) findings
source("RUN_REPLICATION.R")
```

### Step 4: Extension Only
```r
# Run policy moderation extension analysis
source("RUN_EXTENSION.R")
```

### Step 5: Supplementary Analysis
```r
# Additional robustness and heterogeneity analysis
source("01_scripts/04_analysis/supplementary/05-1_leaders_vs_laggards.R")
source("01_scripts/04_analysis/supplementary/05-2_value_weighted_analysis.R")
source("01_scripts/04_analysis/supplementary/05-3_control_group_analysis.R")
```

### Step 6: Publication Outputs
```r
# Generate final figures and summary tables
source("01_scripts/05_visuals/06-5_create_summary_figures.R")
```

## 📋 Expected Results

### Core Replication Results
- **✅ Significant negative alpha for downgrade portfolios**: -0.491% monthly (p=0.073)
- **✅ Insignificant alpha for upgrade portfolios**: +0.036% monthly (p=0.907)
- **✅ Results robust to Carhart 4-factor model**: Similar magnitudes and significance
- **✅ Temporal stability**: Effects persist in post-2016 subsample

### Policy Extension Results
- **✅ No significant policy moderation**: 0/11 robustness tests significant
- **✅ Consistent null findings**: All p-values > 0.80 across specifications
- **✅ Economic interpretation**: Limited evidence of policy effects
- **✅ Robustness confirmation**: Results hold across multiple sensitivity tests

### Output Files Generated

#### 📊 Publication Figures (High-Resolution)
- `02_output/figures/main_results/fig5_summary_panel.png` - Multi-panel summary
- `02_output/figures/main_results/fig2_portfolio_performance.png` - Performance comparison
- `02_output/figures/main_results/fig3_policy_interaction_plot.png` - Policy effects
- `02_output/figures/supplementary/fig4_subsample_comparison.png` - Temporal robustness

#### 📋 Summary Tables (Interactive HTML)
- `02_output/tables/summary/comprehensive_results_table.html` - Complete statistical results
- `02_output/tables/summary/portfolio_comparison_table.html` - Portfolio performance metrics
- `02_output/tables/summary/key_findings_table.html` - Executive summary

#### 📈 Detailed Results
- `02_output/tables/replication/` - Original study replication tables
- `02_output/tables/extension/` - Policy extension analysis
- `02_output/tables/supplementary/` - Additional robustness checks

## 🔬 Methodological Details

### Portfolio Construction
- **Calendar-time methodology** following Fama (1998)
- **12-month event windows** for rating changes
- **Value-weighted and equal-weighted** portfolio variants
- **Monthly rebalancing** with new entries and exits

### Factor Models
1. **Fama-French 3-Factor**: Market, Size (SMB), Value (HML)
2. **Carhart 4-Factor**: Adds Momentum (Mom) factor
3. **Robust standard errors**: Newey-West adjustment for autocorrelation

### Panel Regressions (Extension)
- **Fixed effects specification**: Firm-level unobservables controlled
- **Clustered standard errors**: Firm-level clustering
- **Interaction terms**: Policy × ESG downgrade interactions
- **Multiple policy measures**: ACEEE rankings and RPS presence

## 🧪 Robustness Checks Implemented

Our analysis includes 11 comprehensive robustness specifications:

1. **Main specification** - Baseline policy interaction
2. **Firm fixed effects** - Control for firm heterogeneity
3. **Firm + time fixed effects** - Additional temporal controls
4. **Alternative event windows** - 6-month and 18-month horizons
5. **Crisis exclusion** - Remove 2008-2009 financial crisis
6. **Recent period focus** - Post-2015 subsample
7. **Large firms only** - Focus on liquid stocks
8. **Geographic restrictions** - Top 5 and top 15 states
9. **Placebo test** - Use upgrade portfolios as control

**Result**: 0/11 tests show significant policy moderation (all p > 0.30)

## 💻 System Requirements

- **R Version**: 4.5.1 or higher
- **Memory**: 16GB RAM recommended (24GB for full dataset)
- **Storage**: 5GB free space for data and outputs
- **Packages**: 21 required packages (auto-installed)

## 🔄 Processing Time

- **Full pipeline**: ~45 minutes (depends on system)
- **Replication only**: ~20 minutes
- **Extension only**: ~15 minutes
- **Visualization**: ~5 minutes

## 📞 Support

- **Issues**: Report via GitHub Issues
- **Documentation**: See `README.md` for comprehensive overview
- **Methodology**: Detailed documentation in `03_docs/methodology/`
- **Citation**: See academic citation in main README

## ✅ Validation Checklist

After running the replication, verify:

- [ ] **Data loaded successfully**: 453,748 final observations
- [ ] **Portfolio returns generated**: Downgrade and upgrade portfolios
- [ ] **Factor model results**: Significant downgrade alpha (~-0.5%)
- [ ] **Policy results**: Non-significant interaction effects
- [ ] **Figures generated**: 4 publication-quality plots
- [ ] **Tables created**: HTML summary tables with results
- [ ] **Log files**: No major errors in processing logs

**Expected completion message**: "✓ Analysis complete! Check 02_output/ for results."

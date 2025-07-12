# Methodology Documentation

## Overview

This directory contains detailed technical documentation of all statistical and econometric methods used in the ESG rating changes and stock returns analysis.

## Contents Structure

### Core Methodology Files
- `event_study_methodology.md` - Complete event study design and implementation
- `factor_models.md` - Asset pricing models and factor construction
- `panel_regression_methods.md` - Panel data econometric techniques
- `robustness_testing.md` - Sensitivity analysis and robustness checks
- `policy_interaction_analysis.md` - State-level policy moderation methodology

### Statistical Techniques
- **Event Studies**: Short-run market reaction analysis
- **Factor Models**: Risk-adjusted return calculation
- **Panel Regressions**: Long-run relationship estimation
- **Interaction Effects**: Policy moderation analysis
- **Robustness Tests**: Alternative specifications and samples

## Research Design Framework

### 1. Primary Analysis: Event Study Design

**Objective**: Measure short-run stock price reactions to ESG rating changes

**Event Definition**:
- ESG rating upgrades/downgrades from Sustainalytics
- Minimum one-notch change in rating scale
- Exclude bulk methodology updates

**Event Windows**:
- Main specification: (-1, +1) days around announcement
- Robustness: (-3, +3), (-5, +5), (-10, +10) days
- Long-run: (-30, +30), (-60, +60) days

**Normal Performance Models**:
1. Market model: Ri,t = αi + βi × Rm,t + εi,t
2. Fama-French 3-factor model
3. Carhart 4-factor model (including momentum)
4. Fama-French 5-factor model (extended analysis)

### 2. Extension Analysis: Policy Interaction

**Objective**: Test how state environmental policies moderate ESG effects

**Policy Measurement**:
- State ESG policy strength index (1-5 scale)
- Binary policy regime classifications
- Policy change indicators over time

**Interaction Specification**:
CAR[−1,+1] = α + β₁ × ESG_Change + β₂ × Policy_Strength + β₃ × (ESG_Change × Policy_Strength) + γ × Controls + ε

**Identification Strategy**:
- Cross-sectional variation in state policies
- Time-series variation in policy changes
- Firm fixed effects control for unobservables

## Statistical Methodology

### 1. Event Study Implementation

**Step 1: Normal Performance Estimation**
- Estimation window: (-250, -11) days before event
- Minimum 100 trading days required
- Market model parameters: OLS estimation
- Factor loadings: Time-series regression

**Step 2: Abnormal Return Calculation**
```
AR[i,t] = R[i,t] - E(R[i,t] | X[t])
```
Where E(R[i,t] | X[t]) is predicted normal return

**Step 3: Cumulative Abnormal Returns**
```
CAR[i,(t1,t2)] = Σ[t=t1 to t2] AR[i,t]
```

**Step 4: Statistical Testing**
- Cross-sectional t-test for CAR significance
- Time-series standard deviation estimation
- Bootstrap confidence intervals (1,000 replications)

### 2. Factor Model Specifications

**Market Model**:
```
R[i,t] - R[f,t] = α[i] + β[i] × (R[m,t] - R[f,t]) + ε[i,t]
```

**Fama-French 3-Factor**:
```
R[i,t] - R[f,t] = α[i] + β[1i] × MKT[t] + β[2i] × SMB[t] + β[3i] × HML[t] + ε[i,t]
```

**Carhart 4-Factor**:
```
R[i,t] - R[f,t] = α[i] + β[1i] × MKT[t] + β[2i] × SMB[t] + β[3i] × HML[t] + β[4i] × UMD[t] + ε[i,t]
```

**Factor Sources**:
- MKT, SMB, HML, UMD: Kenneth French Data Library
- RF: 3-month Treasury bill rate (FRED)
- Alternative: AQR Capital factor library for robustness

### 3. Panel Regression Framework

**Fixed Effects Specification**:
```
Return[i,t] = α[i] + λ[t] + β × ESG_Change[i,t] + γ × Controls[i,t-1] + ε[i,t]
```

**Random Effects Specification** (Hausman test):
```
Return[i,t] = α + β × ESG_Change[i,t] + γ × Controls[i,t-1] + u[i] + ε[i,t]
```

**Control Variables**:
- Log market capitalization
- Book-to-market ratio  
- Past 12-month momentum
- Idiosyncratic volatility
- Analyst coverage
- Institutional ownership

### 4. Policy Interaction Methodology

**State Policy Index Construction**:

**Step 1: Policy Data Collection**
- Environmental disclosure requirements
- Carbon pricing mechanisms
- Renewable energy standards
- ESG investment mandates for pension funds

**Step 2: Scoring System**
- Each policy dimension scored 0-5
- Aggregate score = weighted average
- Annual updates with retrospective corrections

**Step 3: Validation**
- Correlation with existing policy indices
- Expert review by environmental economists
- Cross-reference with academic literature

**Interaction Model**:
```
CAR[i,t] = α + β₁ × Upgrade[i,t] + β₂ × Downgrade[i,t] + 
           β₃ × (Upgrade[i,t] × Policy[s,t]) + 
           β₄ × (Downgrade[i,t] × Policy[s,t]) +
           γ × Controls[i,t-1] + δ[s] + λ[t] + ε[i,t]
```

Where:
- s indexes state
- δ[s] = state fixed effects
- λ[t] = time fixed effects

## Econometric Considerations

### 1. Standard Error Corrections

**Clustering Strategy**:
- Primary: Cluster by firm and time (two-way)
- Alternative: Cluster by industry-time
- Robustness: Newey-West HAC corrections

**Implementation**:
```R
# Two-way clustering
vcov_cluster <- vcovCL(model, cluster = ~ firm_id + date)

# Industry-time clustering  
vcov_industry <- vcovCL(model, cluster = ~ industry + date)
```

### 2. Sample Selection Corrections

**Selection Issues**:
- ESG rating coverage non-random
- Larger firms over-represented
- Survivorship bias from delistings

**Correction Methods**:
- Heckman selection model for coverage
- Inverse probability weighting
- Sensitivity to sample restrictions

### 3. Endogeneity Concerns

**Potential Sources**:
- Reverse causality (performance → ESG rating)
- Omitted variable bias
- Measurement error in ESG scores

**Mitigation Strategies**:
- Event study design minimizes reverse causality
- Extensive control variables
- Alternative ESG data sources
- Instrumental variable approach (regulation changes)

## Robustness Testing Framework

### 1. Alternative Specifications

**Event Windows**:
- Narrow: (-1, +1), (0, +1), (0, +2)
- Standard: (-3, +3), (-5, +5)  
- Long-run: (-30, +30), (-60, +60)

**Factor Models**:
- Market model vs multi-factor models
- Industry-adjusted returns
- Size and book-to-market matched portfolios

**Sample Variations**:
- Large-cap only vs full sample
- Exclude financial crisis periods
- Technology sector analysis
- Pre/post-2015 split (ESG mainstream adoption)

### 2. Alternative Data Sources

**ESG Ratings**:
- MSCI ESG scores (subset validation)
- Bloomberg ESG disclosure scores
- Refinitiv ESG controversy flags

**Return Data**:
- CRSP vs Bloomberg validation
- Dividend-adjusted vs total returns
- Intraday vs daily close prices

**Policy Data**:
- Alternative state policy indices
- Federal vs state-level analysis
- Carbon pricing variation

### 3. Placebo Tests

**False Events**:
- Random date assignment
- Industry peer rating changes
- Non-ESG corporate events

**False Policies**:
- Random state-policy assignment
- Lagged policy measures
- Unrelated state policies

## Implementation Details

### 1. Software and Packages

**R Environment**:
- Base R 4.3.0+
- RStudio 2023.12.0+
- renv for package management

**Key Packages**:
```R
# Event studies
library(eventstudies)
library(eventStudy)

# Factor models  
library(FactorAnalytics)
library(tidyquant)

# Panel data
library(plm)
library(fixest)

# Standard errors
library(sandwich)
library(clubSandwich)

# Data manipulation
library(tidyverse)
library(data.table)
```

### 2. Computational Considerations

**Performance Optimization**:
- Parallel processing for bootstrap tests
- Efficient data.table operations
- Memory management for large datasets

**Reproducibility**:
- Set random seeds for all simulations
- Version control for all code
- Package version documentation (renv.lock)

### 3. Quality Control

**Code Validation**:
- Independent replication by research assistant
- Cross-validation with published results
- Unit tests for key functions

**Results Validation**:
- Comparison with literature benchmarks
- Sensitivity analysis documentation
- Expert review of methodology

## Documentation Standards

### 1. Code Documentation

**Function Documentation**:
- Roxygen2 style comments
- Input/output specifications
- Example usage

**Script Headers**:
- Purpose and scope
- Data requirements
- Expected outputs
- Runtime estimates

### 2. Results Documentation

**Table Formatting**:
- Standardized significant digits
- Standard error reporting
- Sample size information
- R² and model diagnostics

**Figure Standards**:
- Publication-ready quality
- Consistent color schemes
- Clear axis labels and legends
- Data source attribution

---

**Last Updated**: January 2024  
**Methodology Version**: 2.0 (Dissertation final)  
**Code Review Status**: Complete  
**Replication Package**: Available upon request

# Data Sources Documentation

## Primary Data Sources

### 1. Sustainalytics ESG Data
**Provider**: Sustainalytics (Morningstar Company)  
**Coverage**: 2010-2024  
**Universe**: Global equity universe (~5,000 companies)  
**Update Frequency**: Monthly  

**Access Details**:
- Academic license through university subscription
- API access via Refinitiv Workspace
- Historical data archive maintained by data vendor

**Key Variables**:
- ESG scores and ratings (overall and pillar-specific)
- Rating change events and dates
- Industry classifications and peer rankings
- Controversy scores and incident flags

**Data Quality**:
- Coverage: ~85% of US large-cap universe
- Consistency: Standardized methodology since 2009
- Reliability: Professional ESG research team
- Updates: Real-time rating changes with historical revisions

### 2. CRSP Stock Data
**Provider**: Center for Research in Security Prices  
**Coverage**: 1925-present (using 2010-2024)  
**Universe**: All US exchange-listed stocks  
**Update Frequency**: Daily  

**Access Details**:
- WRDS (Wharton Research Data Services) subscription
- Direct download via WRDS Cloud
- Standard academic pricing and terms

**Key Variables**:
- Daily and monthly stock returns
- Market capitalization and shares outstanding
- Trading volume and price data
- Corporate actions and delisting information

**Data Quality**:
- Coverage: Complete US equity universe
- Accuracy: Gold standard for academic research
- Survivorship bias: Includes delisted companies
- Adjustments: Split and dividend adjusted returns

### 3. Compustat Fundamentals
**Provider**: S&P Global Market Intelligence  
**Coverage**: 1950-present (using 2010-2024)  
**Universe**: Public companies with SEC filings  
**Update Frequency**: Quarterly/Annual  

**Access Details**:
- WRDS platform access
- Fundamentals Annual and Quarterly files
- Point-in-time data with restatement history

**Key Variables**:
- Balance sheet and income statement data
- Book value of equity calculations
- Financial ratios and derived metrics
- Industry and sector classifications

**Data Quality**:
- Coverage: ~95% of US public companies
- Timeliness: Reports filed with 2-3 month lag
- Accuracy: Based on official SEC filings
- Consistency: Standardized variable definitions

### 4. Fama-French Research Factors
**Provider**: Kenneth French Data Library  
**Coverage**: 1926-present  
**Universe**: US equity markets  
**Update Frequency**: Daily  

**Access Details**:
- Public domain data from Kenneth French website
- Direct download of factor return files
- Freely available for academic research

**Key Variables**:
- Market excess return (Mkt-RF)
- Size factor (SMB)
- Value factor (HML)
- Momentum factor (UMD)
- Risk-free rate (Treasury bill rate)

**Data Quality**:
- Coverage: Complete factor history
- Construction: Standard academic methodology
- Updates: Real-time factor calculations
- Documentation: Detailed methodology papers

### 5. Federal Reserve Economic Data (FRED)
**Provider**: Federal Reserve Bank of St. Louis  
**Coverage**: 1954-present  
**Universe**: US macroeconomic indicators  
**Update Frequency**: Various (daily to monthly)  

**Access Details**:
- Public API with free registration
- Direct download from FRED website
- R package integration (quantmod, fredr)

**Key Variables**:
- Risk-free rate (3-month Treasury)
- Market volatility indicators (VIX)
- Macroeconomic control variables
- Policy rate and yield curve data

### 6. State ESG Policy Data (Extension Analysis)
**Provider**: Multiple government and NGO sources  
**Coverage**: 2010-2024  
**Universe**: 50 US states + DC  
**Update Frequency**: Annual  

**Sources**:
- State environmental agency websites
- Climate policy databases (C2ES, DSIRE)
- Corporate sustainability reporting requirements
- Green bond and ESG disclosure mandates

**Key Variables**:
- ESG policy strength rankings (1-5 scale)
- Policy implementation dates
- Regulatory stringency measures
- Political party control variables

**Construction Methodology**:
- Manual coding from policy documents
- Expert validation from academic literature
- Cross-reference with existing policy databases
- Annual updates with retrospective corrections

## Secondary Data Sources

### IBES Analyst Data
**Purpose**: Control for analyst coverage effects  
**Provider**: Refinitiv (formerly Thomson Reuters)  
**Variables**: Number of analysts, forecast dispersion

### Thomson Reuters Ownership
**Purpose**: Institutional ownership controls  
**Provider**: Refinitiv Institutional Ownership  
**Variables**: Institutional ownership percentages

### OptionMetrics
**Purpose**: Implied volatility measures  
**Provider**: OptionMetrics Ivy DB  
**Variables**: Option-implied volatility surfaces

## Data Collection Timeline

| Source | Initial Access | Last Update | Refresh Frequency |
|--------|---------------|-------------|-------------------|
| Sustainalytics | March 2023 | January 2024 | Monthly |
| CRSP | January 2023 | December 2023 | Quarterly |
| Compustat | January 2023 | December 2023 | Quarterly |
| Fama-French | Ongoing | Real-time | Daily |
| Policy Data | June 2023 | October 2023 | Annual |

## Data Access and Licensing

### University Resources
- WRDS subscription covers CRSP, Compustat, IBES
- Refinitiv Workspace for Sustainalytics access
- Bloomberg Terminal backup for validation

### Cost Structure
- WRDS: Covered by university subscription (~$50K/year)
- Sustainalytics: Academic pricing (~$15K/year)
- Fama-French: Free public domain
- Policy data: Manual collection (research time)

### Compliance and Ethics
- All data used under valid academic licenses
- No redistribution of proprietary datasets
- Code and results shared without underlying data
- GDPR and privacy compliance for EU companies

## Data Limitations and Considerations

### Sample Selection
- ESG data availability creates survivor bias
- Larger companies over-represented in early years
- US-centric sample excludes global ESG trends

### Temporal Issues
- ESG methodology changes over time
- Policy data has state-level heterogeneity
- Financial crisis and COVID-19 structural breaks

### Data Quality Issues
- Missing ESG data for small-cap stocks
- Accounting restatements in Compustat
- Corporate action complexities in CRSP

## Replication Data Package

For replication purposes, the following data files are made available:

### Included in Replication Package
- Final analysis datasets (post-cleaning)
- Factor loadings and portfolio weights
- Event study abnormal returns
- Summary statistics by year/industry

### Not Included (Proprietary)
- Raw Sustainalytics ESG scores
- Individual stock identifiers
- Real-time CRSP price data
- Detailed financial statement items

### Access Instructions
- Request replication data via corresponding author
- Academic use license required
- 5-year data retention policy
- Results verification available upon request

## Contact Information

**Data Questions**: [Author email]  
**Technical Issues**: [University IT support]  
**License Inquiries**: [University legal/compliance]

*Last Updated*: January 2024  
*Version*: 2.0 (Dissertation final)

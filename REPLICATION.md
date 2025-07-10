# Replication Instructions

## Overview
This document provides detailed instructions for replicating the analysis in Shanaev & Ghimire (2022).

## Data Sources
1. **Sustainalytics ESG Ratings**: Proprietary data requiring institutional access
2. **CRSP/Compustat**: Available through WRDS
3. **Fama-French Factors**: http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html

## Replication Steps
1. Obtain and place raw data files in `00_data/raw/`
2. Run `source("RUN_REPLICATION.R")`
3. Check results in `02_output/tables/replication/`

## Expected Results
- Significant negative alpha for downgrade portfolios
- Insignificant alpha for upgrade portfolios
- Results robust to Carhart 4-factor model

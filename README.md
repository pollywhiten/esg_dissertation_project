# ESG Rating Changes and Stock Returns: A State Policy Analysis

## Project Overview
This dissertation project replicates and extends Shanaev & Ghimire (2022) by examining how state-level environmental policies moderate the stock market reaction to ESG rating changes.

## Structure
- `00_data/`: Raw, intermediate, and cleaned data files
- `01_scripts/`: All R scripts organized by purpose
- `02_output/`: Tables, figures, and logs
- `03_docs/`: Documentation and methodology notes
- `04_reports/`: Written outputs and presentations

## Quick Start
1. Install required packages: `source("01_scripts/00_setup/install_packages.R")`
2. Run full analysis: `source("RUN_ALL.R")`
3. Or run components separately:
   - Replication only: `source("RUN_REPLICATION.R")`
   - Extension only: `source("RUN_EXTENSION.R")`

## Data Requirements
Place the following files in their respective directories:
- ESG data in `00_data/raw/esg/`
- Financial data in `00_data/raw/financial/`
- Policy data in `00_data/raw/policy/`

## Authors
[Your name here]

## Last Updated
$(date)

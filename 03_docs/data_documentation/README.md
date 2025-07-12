# Data Documentation

## Overview
This directory contains comprehensive documentation for all data sources, processing steps, and quality assessments used in the ESG rating changes and stock returns analysis.

## Contents

### Data Dictionary
- **File**: `data_dictionary.md`
- **Purpose**: Complete variable definitions and coding schemes
- **Source**: Extracted from analysis scripts and metadata

### Data Sources  
- **File**: `data_sources.md`
- **Purpose**: Detailed information about data providers and collection
- **Coverage**: Sustainalytics, CRSP, Compustat, Fama-French, Policy data

### Quality Assessment
- **File**: `data_quality_report.md` 
- **Purpose**: Data validation, missing value analysis, consistency checks
- **Methods**: Automated checks from validation scripts

## Key Statistics
- **Final Dataset**: 453,748 firm-month observations
- **Sample Period**: 2010-2024 (extended from original 2009-2020)
- **Unique Firms**: 4,787 companies
- **Data Quality**: >95% completeness for key variables

## Related Files
- See `/00_data/metadata/` for technical metadata
- See `/REPLICATION.md` for data usage instructions
- See `/README.md` for project overview

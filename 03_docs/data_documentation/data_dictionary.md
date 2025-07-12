# Data Dictionary

## Variable Definitions and Coding Schemes

### ESG Rating Variables
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `esg_score` | Overall ESG performance score | Sustainalytics | 0-100 scale (higher = better) |
| `esg_rating` | ESG performance rating category | Sustainalytics | AAA, AA, A, BBB, BB, B, CCC |
| `env_score` | Environmental pillar score | Sustainalytics | 0-100 scale |
| `soc_score` | Social pillar score | Sustainalytics | 0-100 scale |
| `gov_score` | Governance pillar score | Sustainalytics | 0-100 scale |
| `rating_change` | ESG rating change indicator | Derived | 1 = upgrade, -1 = downgrade, 0 = no change |
| `rating_change_magnitude` | Size of rating change | Derived | Numeric scale (-6 to +6) |

### Financial Variables
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `ret` | Monthly stock return | CRSP | Decimal form (0.05 = 5%) |
| `ret_excess` | Excess return over risk-free rate | CRSP/Fed | ret - rf |
| `mktcap` | Market capitalization | CRSP | Millions USD |
| `log_mktcap` | Log market capitalization | Derived | log(mktcap) |
| `book_to_market` | Book-to-market ratio | Compustat/CRSP | Book equity / Market equity |
| `momentum` | Price momentum (11-month) | CRSP | Cumulative return t-11 to t-1 |

### Fama-French Factors
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `mktrf` | Market excess return | Kenneth French | Monthly factor return |
| `smb` | Small-minus-big factor | Kenneth French | Monthly factor return |
| `hml` | High-minus-low factor | Kenneth French | Monthly factor return |
| `umd` | Up-minus-down momentum | Kenneth French | Monthly factor return |

### Policy Variables (Extension)
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `policy_strength` | State ESG policy strength | State Policy Rankings | 1-5 scale (5 = strongest) |
| `policy_change` | Policy regime change | Derived | 1 = strengthening, 0 = no change |
| `blue_state` | Democratic-leaning state | Political classification | 1 = blue, 0 = red/purple |
| `policy_interaction` | ESG rating × Policy strength | Derived | Interaction term |

### Control Variables
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `volume` | Trading volume | CRSP | Shares traded |
| `turnover` | Share turnover ratio | CRSP | Volume / Shares outstanding |
| `volatility` | Return volatility (60-day) | CRSP | Standard deviation |
| `analyst_coverage` | Number of analysts | IBES | Count of active analysts |
| `institutional_ownership` | Institutional ownership % | Thomson Reuters | Percentage 0-100 |

### Event Window Variables
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `event_window` | Days relative to rating change | Derived | -30 to +30 days |
| `pre_event` | Pre-event period indicator | Derived | 1 if t ∈ [-10, -1] |
| `post_event` | Post-event period indicator | Derived | 1 if t ∈ [0, +10] |
| `car_3d` | 3-day cumulative abnormal return | Derived | Sum of abnormal returns |
| `car_10d` | 10-day cumulative abnormal return | Derived | Sum of abnormal returns |

### Portfolio Construction Variables
| Variable | Description | Source | Coding |
|----------|-------------|---------|---------|
| `portfolio` | Portfolio assignment | Derived | upgrade, downgrade, control |
| `weight_ew` | Equal-weight portfolio weight | Derived | 1/N for N stocks |
| `weight_vw` | Value-weight portfolio weight | Derived | Market cap / Sum(market cap) |
| `rebalance_date` | Portfolio rebalancing date | Derived | Monthly rebalancing |

## Missing Value Codes
- `-999`: Data not available from source
- `NA`: Not applicable for this observation
- `NULL`: Missing due to data processing

## Data Quality Flags
- `flag_outlier`: Extreme value flagged for review
- `flag_incomplete`: Incomplete observation
- `flag_estimated`: Value estimated/interpolated

## Sample Restrictions
- Minimum market cap: $10 million
- Minimum trading volume: 100,000 shares/month
- Exclude: REITs, utilities, financials (optional)
- Exclude: IPOs within 12 months
- Exclude: Stocks trading below $1

## Updates from Original Study
- Extended sample period: 2009-2020 → 2010-2024
- Added policy interaction variables
- Enhanced ESG score granularity
- Improved data cleaning procedures

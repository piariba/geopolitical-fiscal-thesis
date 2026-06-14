# geopolitical-fiscal-thesis
This repository contains the replication code for the MSc thesis "Budgeting for Uncertainty in Taxing Times: How Geopolitical Risk Shapes Fiscal Policy Preferences through Economic Anxiety and Political Learning. Survey Evidence from Germany, 2009–2025". The analysis examines the sources and processes through which elevated geopolitical risk shifts German voters' preferences on the tax–social benefit trade-off.

---
## Overview

This repository contains the replication code for the above thesis. The analysis examines the sources and processes through which elevated geopolitical risk shifts German voters' preferences on the tax–social benefit trade-off.

The empirical basis is five cross-sectional waves of the German Longitudinal Election Study (GLES) from 2009 to 2025, merged with the Germany-specific version of Caldara and Iacoviello's (2022) monthly news-based Geopolitical Risk Index (GPR). A robustness check on the tax salience mechanism uses a Google Trends composite index of 20 German tax-related search terms.

The code is organized into four scripts that must be run in the following order:

1. `gt_geopoliticalfiscal_thesis.R` - fetches and processes Google Trends data
2. `dataprep_geopoliticalfiscal_thesis.do` — data preparation and merging
3. `regressions_geopoliticalfiscal_thesis.do` — all regression models
4. `figures_geopoliticalfiscal_thesis.do` — all figures

---
## Requirements

### Stata
Stata 17 or newer is required (the do-files use `frames`, introduced in Stata 17).

The following packages are required and can be installed from SSC:

| Package | Used in |
|---|---|
| `estout` | `regressions` |
| `coefplot` | `regressions`, `figures` |
| `blindschemes` | `figures` |
| `ridgeline` | `figures` |
| `palettes` | `figures` |
| `colrspace` | `figures` |

To install all at once, run:

```stata
ssc install estout
ssc install coefplot
ssc install blindschemes
ssc install ridgeline
ssc install palettes, replace
ssc install colrspace, replace
ssc install heatplot, replace
```
### R
R 4.x is required for the Google Trends script. The following packages are used:

| Package | Purpose |
|---|---|
| `gtrendsR` | Google Trends API wrapper |
| `tidyverse` | Data manipulation and I/O |
| `haven` | Stata `.dta` export |
| `lubridate` | Date handling |
| `zoo` | Moving averages |

To install:

```r
install.packages(c("gtrendsR", "tidyverse", "haven", "lubridate", "zoo"))
```

---
## Data

### Paths
All Stata do-files use a global root path defined at the top of each file. Before running, update both to point to your local working directory:

```stata
global root "/your/path/to/thesis"   // in each .do file
```

```r
setwd("/your/path/to/thesis/data/GT")  // in gt_geopoliticalfiscal_thesis.R
```

Data files should be placed in `$root/data/`. The Google Trends output CSV is written by the R script to `$root/data/GT/` and read from there by `dataprep_geopoliticalfiscal_thesis.do`. Regression tables and figures are written to `$root/output/`.
### Data Sources
**GLES data is not included in this repository.** The German Longitudinal Election Study is distributed under a Scientific Use License by the GESIS Data Archive. Access requires free registration at [gesis.org](https://www.gesis.org/en/home) and acceptance of the data use agreement. Both datasets are freely available after registration.

| File (place in `data/`) | Description | Source |
|---|---|---|
| `ZA6835_v2-0-0.dta` | GLES Cross-Section 2009–2021, Cumulation (v2.0.0) | GESIS, doi:[10.4232/1.14389](https://doi.org/10.4232/1.14389) |
| `ZA10100_v2-0-0.dta` | GLES Cross-Section 2025, Post-Election (v2.0.0) | GESIS, doi:[10.4232/5.ZA10100.2.0.0](https://doi.org/10.4232/5.ZA10100.2.0.0) |

**The GPR data is publicly available** and should be downloaded directly from the authors' website. Download the country-level monthly index and save it to `data/` as `data_gpr_export.dta`:

| File (place in `data/`) | Description | Source |
|---|---|---|
| `data_gpr_export.dta` | Monthly Country-Specific GPR Index | Caldara & Iacoviello (2022), [matteoiacoviello.com/gpr_country.htm](https://www.matteoiacoviello.com/gpr_country.htm) |

**Google Trends data is fetched by the R script** and requires no manual download. Running `gt_geopoliticalfiscal_thesis.R` queries the Google Trends API for 20 German tax-related search terms and writes the processed index to `data/GT/taxation_gt_salience_national.csv`. The script uses a batched anchoring approach to make relative search volumes comparable across batches. Note that Google Trends data is not perfectly reproducible over time as index values are periodically recalibrated by Google; minor numerical differences from the original results are expected.

---
## Repository Contents

```
.
├── README.md
├── gt_geopoliticalfiscal_thesis.R
├── dataprep_geopoliticalfiscal_thesis.do
├── regressions_geopoliticalfiscal_thesis.do
└── figures_geopoliticalfiscal_thesis.do
```

The `data/` and `output/` directories are not included. Data must be obtained from the sources listed above; the `output/` directory is created automatically by the Stata scripts.

---
## References

Caldara, D., & Iacoviello, M. (2022). Country-Specific Geopolitical Risk Index
[Dataset]. https://doi.org/10.1257/aer.20191823

GLES. (2024). GLES Cross-Section 2009–2021, Cumulation (Version 2.0.0)
[Dataset]. GESIS. https://doi.org/10.4232/1.14389

GLES. (2025). GLES Cross-Section 2025, Post-Election (Version 2.0.0) [Dataset].
GESIS Data Archive. https://doi.org/10.4232/5.ZA10100.2.0.0

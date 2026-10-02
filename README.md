
#  Sidewalk Access and Daily Physical Activity  in  Children With Asthma: A Cross-Sectional Analysis



![SAS](https://img.shields.io/badge/SAS-0766D1?style=for-the-badge)
![Data: NSCH 2023](https://img.shields.io/badge/Data-NSCH_2023-555555?style=for-the-badge)
[![ORCID](https://img.shields.io/badge/ORCID-A6CE39?style=for-the-badge&logo=orcid&logoColor=white)](https://orcid.org/0009-0007-5849-1761)

MPH capstone project (PUBH 698), CUNY Graduate School of Public Health and Health Policy, 2026.
[Presented at the 2026 NYC Epidemiology Forum at the Icahn School of Medicine at Mount Sinai](https://www.nyc.gov/site/doh/health/health-topics/nyc-epidemiology-forum.page).

---

## Background

Among children with asthma, obesity is associated with increased disease severity and poorer symptom control. Physical activity is an important preventive strategy for both conditions; however, children with asthma face barriers to engagement. Neighborhood sidewalks may reduce these barriers and promote daily activity.

## Objective

To assess the association between parent-reported neighborhood sidewalk presence and daily physical activity among children with current asthma, and to examine whether neighborhood safety and neighborhood physical disorder modified this association.

## Data

This analysis uses the **2023 National Survey of Children's Health (NSCH) Topical Public Use File**, a nationally representative survey conducted by the U.S. Census Bureau.

The data are not included in this repository. To reproduce the analysis, download the SAS version of the 2023 Topical file (`nsch_2023e_topical.sas7bdat`) from the [U.S. Census Bureau NSCH page](https://www.census.gov/programs-surveys/nsch.html).

**Study population:** Children aged 6–17 years with current asthma (n = 3,640 unique children; n = 21,840 observations across six imputation replicates).

## Methods

| Component | Description |
|---|---|
| Design | Cross-sectional analysis |
| Exposure | Parent-reported neighborhood sidewalk presence vs. no sidewalk access |
| Outcome | Parent-reported daily physical activity |
| Covariates | Age, sex, federal poverty level (FPL), adverse childhood experiences (ACEs) |
| Model | Survey-weighted logistic regression accounting for the NSCH complex sampling design, sequentially adjusted for covariates |
| Missing data | Multiply imputed FPL (six replicates), pooled using Rubin's Rules |
| Effect measure modification | Interaction terms for neighborhood safety and neighborhood detracting elements |
| Additional analyses | Sensitivity analyses and stratified analyses by neighborhood detracting elements |

## Key Results

- Overall, **77.2%** of children reported neighborhood sidewalk access.
- Sidewalk presence was **not significantly associated** with daily physical activity across crude or adjusted models (fully adjusted log-OR: −0.085, 95% CI: −0.311, 0.141).
- Neighborhood safety **did not significantly modify** this association (p = 0.596).
- Neighborhood detracting elements **significantly modified** the association (p = 0.018). Among children in neighborhoods with detracting elements, sidewalk presence was associated with lower odds of daily physical activity (log-OR: −0.442, 95% CI: −0.843, −0.042).

## Conclusions

Neighborhood sidewalk presence alone was not associated with daily physical activity among children with current asthma. The significant interaction with neighborhood detracting elements suggests that the addition of other neighborhood elements may shape this relationship. Findings may reflect a genuine null association, residual confounding, or unmeasured environmental contexts such as rural versus urban classification.

## Repository Contents

| File | Description |
|---|---|
| `murrayeileen_FINALPUBH698_CODE.sas` | Full analysis code, from data cleaning through final output tables |
| `README.md` | Project overview |
| `MurrayEileen_FINALDRAFT_PUBH698.docx` | Full Final Paper |
| `NYCEF26_poster.pptx`| Poster used at NYCEF 2026 |
| `murrayeileen_pubh698presentation_COPY.pptx`| Final Presentation|

The SAS program is organized into the following sections:

1. Library and format definitions
2. Data cleaning and variable construction
3. FPL imputation and dataset stacking
4. Table 1: Descriptive statistics
5. Table 2: Primary logistic regression models
6. Table 3: Sensitivity analyses
7. Table 4: Effect measure modification
8. Table 5: Stratified analyses
9. CI calculations and summary output tables

## How to Run

1. Download the 2023 NSCH Topical Public Use File in SAS format (see [Data](#data)).
2. Open the `.sas` file in SAS (the analysis was developed in SAS Studio OnDemand for Academics).
3. At the top of Section 1, set `%let datapath =` to the folder containing `nsch_2023e_topical.sas7bdat`.
4. Run the program from top to bottom.

## Keywords

Asthma · Physical activity · Sidewalks · Built environment · Children · NSCH · Neighborhood environment

## Author

**Eileen M. Murray, MPH**
Epidemiology & Biostatistics, CUNY Graduate School of Public Health and Health Policy
[ORCID: 0009-0007-5849-1761](https://orcid.org/0009-0007-5849-1761)

---
layout: default
title: Health Economics & HCRU (HEOR / HTA)
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 9
---

# Health Economics & HCRU (HEOR / HTA) Guide

## Introduction & Purpose

Health Economics and Outcomes Research (HEOR) and Healthcare Resource Utilisation (HCRU) studies evaluate the clinical value, resource burden, and economic impact of healthcare interventions in real-world clinical practice. While clinical trials establish efficacy and safety in idealized conditions, health economic evaluations generate evidence needed by Health Technology Assessment (HTA) bodies (e.g., NICE, HAS, G-BA, TLV) and healthcare payers to determine reimbursement, pricing, and cost-effectiveness.

The central questions addressed by HEOR/HCRU studies include:

*   **Healthcare Resource Utilisation (HCRU)**: How often do patients in a target cohort utilize healthcare services (inpatient hospitalizations, emergency visits, outpatient consultations, and pharmacotherapy)?
*   **Direct Medical Costs**: What are the total and category-specific medical expenditures associated with managing a disease or treatment arm?
*   **Comparative Cost-Effectiveness**: Is a new therapy cost-effective compared to the standard of care? What is the **Incremental Cost-Effectiveness Ratio (ICER)** per Quality-Adjusted Life Year (QALY) gained?
*   **Decision Uncertainty**: What is the probability that the intervention is cost-effective at various Willingness-to-Pay (WTP) thresholds?

## Study Design

HEOR studies typically employ a **comparative longitudinal cohort design** combined with **decision-analytic Markov state-transition modeling**. The design links real-world clinical encounters, medication dispenses, and financial cost records to simulate long-term economic trajectories.

### Participants

The study defines two or more cohorts:

*   **Target Cohort**: Patients initiating the intervention of interest (e.g., a novel therapeutic agent).
*   **Comparator Cohort**: Patients initiating an alternative treatment or the standard of care.

Both cohorts require a baseline lookback period (e.g., 365 days of prior observation) to characterize demographic variables, comorbidities, and baseline resource utilization for causal adjustment.

### Exposures & Comparators

*   **Target Exposure**: The intervention or new technology being evaluated.
*   **Comparator Exposure**: The active comparator or routine clinical standard of care.

### Health Economic Endpoints & Resource Domains

Outcomes encompass both clinical events and economic resource consumption:

1.  **HCRU Resource Domains**:
    *   *Inpatient & Critical Care*: Hospital admissions, ICU stays, length of stay (LOS), and 30-/90-day readmissions.
    *   *Outpatient & Ambulatory*: Emergency room encounters, primary care visits, and specialist consultations.
    *   *Pharmacotherapy*: Medication fills, total days supply, and adherence/persistence (e.g., Proportion of Days Covered [PDC]).
    *   *Procedures & Diagnostics*: Surgical interventions, diagnostic imaging, and laboratory testing volumes.
    *   *Post-Acute Care*: Skilled nursing facility (SNF), rehabilitation, and home health services.
2.  **Financial Expenditures**: Direct medical costs extracted directly from the OMOP `cost` and `visit_occurrence` tables (e.g., `total_paid`, `total_charge`).
3.  **Health State Utilities & QALYs**: Health-related quality of life weights mapped to disease states (e.g., progression-free survival vs. post-progression state).

### Follow-up & Time Horizon

*   **Within-Trial / Observation Window**: Empirical follow-up from the index date through available data to calculate observed HCRU rates and direct costs.
*   **Decision-Analytic Time Horizon**: Long-term or lifetime horizon modeled using Markov state-transition simulations, with future costs and benefits discounted (typically 3%–5% annually).

### Analyses

The analytical framework combines causal inference and health economic simulation:

1.  **Baseline Characterisation & HCRU Extraction**: Summarise demographics, clinical history, and baseline utilization across all resource categories.
2.  **Causal Propensity Score Adjustment**: Mitigate confounding by indication between treatment and comparator arms using regularized logistic regression (e.g., via `Cyclops`) and greedy caliper matching or inverse probability of treatment weighting (IPTW).
3.  **State-Transition & Cost Modeling**: Partition patient longitudinal journeys into discrete health state trajectories to estimate transition probability matrices and parametric cost distributions (e.g., Gamma or Log-Normal distributions).
4.  **Probabilistic Sensitivity Analysis (PSA)**: Execute Monte Carlo simulations sampling transition rates, state costs, and utility values to capture parameter uncertainty.
5.  **Decision Analysis (CEA)**: Calculate key HTA metrics:
    *   **Incremental Cost-Effectiveness Ratio (ICER)**: $\Delta \text{Cost} / \Delta \text{QALY}$.
    *   **Net Monetary Benefit (NMB)**: $\text{NMB}(k) = k \cdot \Delta E - \Delta C$ at willingness-to-pay threshold $k$.
    *   **Visualizations**: Cost-Effectiveness Acceptability Curves (CEAC) and Cost-Effectiveness Planes.

## How to Implement This Study

The following complete workflow demonstrates how to implement an end-to-end HEOR and HCRU study using the [`HERMES`](../package_reference/hermes) R package:

```r
library(HERMES)
library(CDMConnector)
library(CohortConstructor)
library(dplyr)

# 1. Connect to OMOP CDM database
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir("GiBleed"))
cdm <- CDMConnector::cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

# 2. Instantiate Target, Comparator, and Outcome Cohorts
cdm$target_cohort <- conceptCohort(cdm, list(target_cohort = 4285898L), "target_cohort")
cdm$comparator_cohort <- conceptCohort(cdm, list(comparator_cohort = 4266809L), "comparator_cohort")
cdm$outcome_cohort <- conceptCohort(cdm, list(outcome_cohort = 192671L), "outcome_cohort")

# 3. Execute 6-Stage HEOR Pipeline
study <- init(
  cdm = cdm,
  target_cohort = "target_cohort",
  comparator_cohort = "comparator_cohort",
  outcome_cohort = "outcome_cohort"
) |>
  summarise_baseline() |>
  extract_hcru(
    baseline_window = c(-365, -1),
    followup_window = c(0, 365),
    cost_field = "total_paid"
  ) |>
  fit_ps() |>
  adjust_ps(caliper = 0.2) |>
  compile_trajectories() |>
  simulate_economics(
    time_horizon = 10,
    discount_rate = 0.03,
    n_samples = 500
  ) |>
  run_cea()

# 4. Generate HTA Visualizations and Summary Tables
plot_ceac(study)
plot_plane(study)
table_summary(study)
```

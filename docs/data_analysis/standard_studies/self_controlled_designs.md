---
layout: default
title: Self-Controlled Designs
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 5
---

# Self-Controlled Designs Guide

## Introduction & Purpose

Self-Controlled Designs are a unique and powerful class of study designs used primarily for safety surveillance. Their key feature is that **individuals serve as their own control**. This elegantly addresses confounding by baseline patient characteristics, as these factors (e.g., genetics, chronic conditions) are inherently constant within the same person over time.

The purpose of these designs is to investigate whether there is an increased risk of an **acute event** immediately following a transient exposure, such as a vaccination or a short course of medication. The central question is: "Is the risk of the outcome higher during the 'exposed' period compared to the 'unexposed' period within the same individual?"

## Study Designs

This category includes two main, closely related designs:

1.  **Self-Controlled Case Series (SCCS)**: This is the classic design. It includes only individuals who have experienced the outcome of interest (i.e., "cases"). It then compares the rate of the outcome during periods of exposure to the rate during all other observed time periods.
2.  **Self-Controlled Case Risk Interval (SCRI)**: This is a variation that defines a specific, pre-specified "control interval" relative to the exposure date. It compares the risk in the exposed window to the risk in this defined control window, rather than all unexposed time.

### Participants

The study population consists of individuals who have experienced the outcome of interest at least once. For this reason, the design is often described as a "case series." Additional eligibility criteria can be applied based on demographics or clinical history.

### Exposures

The exposures in these designs are typically **transient** and have a clearly defined start and end. The classic example is a **vaccination**. The time immediately following the exposure is defined as the "risk window." All other time is considered the "unexposed" or "control" window.

### Outcomes

The outcomes must be **acute events** where the exact date of occurrence can be accurately determined. Chronic conditions with an insidious onset are not suitable for this design. The outcome should also not be something that would alter the probability of future exposure (e.g., an outcome that is a contraindication to receiving the drug again).

### Follow-up

The observation period for each individual is defined based on their exposure history. It is divided into different windows:

*   **Risk Window(s)**: The period(s) immediately following the exposure, where the risk is hypothesised to be elevated.
*   **Control Window(s)**: All other periods of observation for the individual, which serve as the baseline risk period.

### Analyses

The analysis uses conditional regression models (typically conditional Poisson regression) to compare the rate of the outcome in the risk windows to the rate in the control windows. Because the comparison is within-individuals, all time-invariant confounders (like genetics, sex, or chronic disease status) are automatically controlled for.

The primary output is an **Incidence Rate Ratio (IRR)**, which represents the relative risk of the outcome during the exposed period compared to the unexposed period. The analysis must also adjust for time-varying confounders, such as age and seasonality.

## How to Implement This Study

Self-Controlled Case Series (SCCS) and SCRI studies are executed using the [`SelfControlledCaseSeries`](https://ohdsi.github.io/SelfControlledCaseSeries/) HADES R package:

```r
library(CDMConnector)
library(CohortConstructor)
library(SelfControlledCaseSeries)

# 1. Instantiate Exposure and Outcome Cohorts using CohortConstructor
cdm$exposure <- conceptCohort(cdm, list(vaccine = 4285898L), name = "exposure")
cdm$outcome <- conceptCohort(cdm, list(acute_event = 192671L), name = "outcome")

# 2. Configure SCCS Study Data Extraction
# Defines the risk window (e.g. 1 to 28 days post-exposure)
covarSettings <- createEraCovariateSettings(
  label = "Exposure risk window",
  includeEraIds = 1,
  start = 1,
  end = 28,
  endAnchor = "era start"
)

# 3. Fit Conditional Poisson Regression
# Individual-level fixed effects automatically control for time-invariant confounders
# (e.g., genetics, chronic disease history).
```

---
layout: default
title: Impact Evaluation Studies
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 8
---

# Impact Evaluation Studies Guide

## Introduction & Purpose

Impact Evaluation Studies are a category of observational research designed to assess the real-world impact of large-scale "interventions" on population-level health outcomes or behaviours. These interventions are not assigned by a researcher (as in a clinical trial) but are typically external events such as new public health policies, regulatory actions, or changes in clinical guidelines.

The purpose of these studies is to determine whether a specific intervention caused a measurable change in trends. The central question is: **"Did the intervention lead to a change in health outcomes or healthcare utilisation patterns at the population level?"**

This methodology is crucial for evidence-based policymaking, allowing regulators and public health bodies to understand the real-world consequences of their decisions.

## Study Designs

These studies are often called **quasi-experimental** because they aim to estimate a causal effect without the use of randomisation. The two most common designs in this category are:

1.  **Interrupted Time Series (ITS)**: This is the most common design. It involves tracking a population-level outcome over time, both before and after the intervention. The analysis then assesses whether the intervention was associated with a "break" or change in the trend of the outcome.
2.  **Difference-in-Differences (DiD)**: This design is used when the intervention affects one subpopulation but not another. It compares the change in the outcome trend in the "exposed" population to the change in the "unexposed" (control) population over the same period. This helps to control for other external factors that may have changed over time.

### Participants

The study population is typically the **entire source population** or a large, relevant subset. For a DiD study, the population must be divisible into a group that was affected by the intervention and a group that was not.

### Exposures

The "exposure" is the **intervention** itself. This is a discrete event that occurs at a specific, known point in time. Examples include:

*   A new public health campaign (e.g., a smoking cessation campaign).
*   A regulatory action, such as a drug safety warning or a **Risk Minimisation Measure (RMM)**.
*   A change in law or healthcare policy.

The study period is divided into a "pre-intervention" period and a "post-intervention" period.

### Outcomes

The outcomes are **population-level aggregate measures** that are tracked over time. These can include:

*   Incidence or prevalence rates of a disease.
*   Rates of medication use.
*   Hospitalisation rates.
*   Rates of mortality.

### Follow-up

The study involves a long-term follow-up of the population, typically spanning several years both before and after the intervention, to establish stable trends.

### Analyses

The analysis uses statistical models to quantify the impact of the intervention.

*   **For ITS**: A **segmented regression** model is used. This model fits a line to the pre-intervention trend and another line to the post-intervention trend. The analysis then tests for two things:
    1.  A **step change**: An immediate jump or drop in the outcome level right after the intervention.
    2.  A **slope change**: A change in the direction or steepness of the trend after the intervention.
*   **For DiD**: A regression model is used to estimate the "difference in the differences," which is the true causal effect of the intervention, having subtracted the background trend observed in the control group.

## How to Implement This Study

Impact Evaluation studies (ITS and DiD) combine longitudinal incidence/prevalence metrics with segmented regression modeling:

```r
library(CDMConnector)
library(IncidencePrevalence)
library(dplyr)

# 1. Calculate Monthly or Quarterly Rates across the pre- and post-intervention period
rates <- estimateIncidence(
  cdm = cdm,
  denominatorTable = "population_denominator",
  outcomeTable = "outcome_cohort",
  interval = "months"
)

# 2. Fit Segmented Regression (Interrupted Time Series)
# model <- lm(rate ~ time + intervention_indicator + time_after_intervention, data = rates_df)
# Tests for immediate step changes and long-term trajectory/slope shifts post-intervention.
```

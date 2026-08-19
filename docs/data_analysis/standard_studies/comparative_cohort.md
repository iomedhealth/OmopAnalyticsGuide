---
layout: default
title: Comparative Cohort Studies
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 4
---

# Comparative Cohort Studies Guide

## Introduction & Purpose

Comparative Cohort Studies are one of the most common and powerful designs in observational research. Their purpose is to emulate a clinical trial by comparing the risk of health outcomes between two or more groups of patients who have received different medical interventions. This design is the cornerstone of causal inference in real-world evidence, helping us to understand the relative safety and effectiveness of different treatments.

The central question this design answers is: **"Is Treatment A associated with a higher or lower risk of an outcome than Treatment B?"**

To answer this question reliably, the study must be carefully designed to minimise bias, particularly confounding by indication, which occurs when the patient groups receiving different treatments are not comparable at baseline.

## Study Design

The design is a **comparative cohort analysis**. It involves identifying at least two distinct cohorts of patients, a **target cohort** (receiving the treatment of interest) and a **comparator cohort** (receiving an alternative treatment), and following them over time to observe the occurrence of pre-specified outcomes.

Key variations of this design include:

*   **New User Design**: This is the preferred approach. It includes only patients who are newly initiating either the target or comparator treatment. This design avoids many biases associated with prevalent users and provides a clear "time zero" for the start of follow-up.
*   **Prevalent User Design**: This design includes patients who are current users of the treatments. It can be necessary when studying treatments for chronic conditions where new users are rare, but it requires more complex methods to control for biases.

### Participants

The study includes at least two cohorts of patients, defined by their exposure to the treatments being compared. A critical step is to define a set of **inclusion and exclusion criteria** to ensure the study population is appropriate for the research question. This often includes requiring a minimum period of data visibility before treatment initiation.

### Exposures

The exposures are the medical interventions being compared. In a typical study, these are:

*   **Target Exposure**: The drug or treatment of primary interest.
*   **Comparator Exposure**: An alternative drug or treatment, often the standard of care, used as a benchmark for comparison. This is known as an **active comparator** design.

### Outcomes

The study pre-specifies one or more health outcomes of interest. These can be safety outcomes (e.g., adverse events) or effectiveness outcomes (e.g., disease remission). To assess the validity of the study, a set of **negative control outcomes** (outcomes not believed to be caused by either treatment) are often included to detect residual bias.

### Follow-up

For each patient, follow-up begins on the day they initiate their respective treatment (the index date). Follow-up continues until the first occurrence of:

*   The outcome of interest.
*   Switching to or adding the other cohort's treatment.
*   Discontinuation of the treatment (in an "on-treatment" analysis).
*   Loss to follow-up or end of data availability.

### Analyses

The analysis aims to estimate the causal effect of the target exposure relative to the comparator. The key analytical step is to **control for confounding**. This is typically done using **Propensity Scores**, which are the predicted probability of a patient receiving the target treatment given their baseline characteristics.

Common propensity score methods include:

*   **Matching**: Creating pairs of similar patients from the target and comparator groups.
*   **Stratification**: Dividing patients into strata based on their propensity score.
*   **Inverse Probability of Treatment Weighting (IPTW)**: Weighting each patient by the inverse of their propensity score.

After balancing the cohorts, the analysis involves calculating the **relative risk** of the outcome, often expressed as a **Hazard Ratio** from a Cox regression model or a **Rate Ratio** from a Poisson model.

## How to Implement This Study

{% include rmd_output/comparative_cohort.md %}

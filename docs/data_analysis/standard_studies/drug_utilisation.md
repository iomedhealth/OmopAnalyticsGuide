---
layout: default
title: Drug Utilisation
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 3
---

# Drug Utilisation Guide

## Introduction & Purpose

Drug Utilisation Studies (DUS) are designed to investigate how medicines are used in real-world clinical practice. While clinical trials tell us if a drug *can* work in a controlled setting, DUS tells us how it is *actually being used* by the general population. This is crucial for understanding prescribing patterns, patient adherence, and the real-world context of medication use.

The purpose of a DUS can be broad, but it often focuses on answering questions like:

*   How many people are using a specific drug?
*   For what medical reasons (indications) is it being prescribed?
*   What is the typical starting dose?
*   How long do patients typically remain on the treatment (persistence)?
*   Are there specific populations who are more likely to use the drug?

## Study Design

DUS can be conducted at two different levels, and a comprehensive study often includes both:

1.  **Population-Level DUS**: A descriptive analysis of drug use across an entire population.
2.  **Patient-Level DUS**: A cohort study focusing on the characteristics and behaviours of individuals who initiate a specific drug.

### Participants

*   **For Population-Level DUS**: The study includes the **entire source population** available in the database.
*   **For Patient-Level DUS**: The study includes a cohort of **new users** of a specific drug or drug class. A "washout" period (e.g., one year with no prior use) is required to ensure that the individuals are genuinely new users. The cohort can also be restricted to a subpopulation of interest (e.g., only patients with a prior diagnosis of a specific condition).

### Exposures

The primary "exposure" of interest is the medication itself. The analysis can focus on a single drug, a class of drugs, or compare the usage patterns of multiple drugs.

### Outcomes

The outcomes in a DUS are measures of medication usage. These can include:

*   **At the Population Level**:
    *   **Incidence of Use**: The rate of new users of a drug over time.
    *   **Prevalence of Use**: The proportion of the population using a drug at a specific point in time.
*   **At the Patient Level**:
    *   **Initial Dose**: The dose prescribed at the start of treatment.
    *   **Treatment Duration**: The length of time a patient remains on the drug.
    *   **Treatment Discontinuation & Switching**: How often patients stop the drug or switch to another.
    *   **Patient Characteristics**: A baseline characterisation of the new users.

### Follow-up

*   **For Population-Level DUS**: Follow-up is typically over calendar time to assess trends in usage.
*   **For Patient-Level DUS**: Follow-up starts on the date of therapy initiation (the index date) and continues until the end of data availability, loss to follow-up, or a pre-defined study end date.

### Analyses

The analysis is primarily descriptive.

*   **Population-level analyses** mirror those in an epidemiology study: calculating the incidence and prevalence of use, often stratified by age, gender, and calendar year.
*   **Patient-level analyses** involve characterising the new user cohort and summarising the key usage metrics, such as median treatment duration and the distribution of initial doses.

## How to Implement This Study

The following example demonstrates how to implement a Drug Utilisation Study using the [`DrugUtilisation`](../package_reference/drugutilisation) package:

```r
library(CDMConnector)
library(DrugUtilisation)
library(CohortCharacteristics)
library(visOmopResults)
library(dplyr)

# 1. Connect to or simulate an OMOP CDM
cdm <- mockDrugUtilisation(numberIndividuals = 1000)

# 2. Generate an ingredient-based drug user cohort
cdm <- generateIngredientCohortSet(
  cdm = cdm,
  name = "dus_cohort",
  ingredient = "acetaminophen",
  gapEra = 30
)

# 3. Refine cohort to new users with 365 days of prior observation
cdm$dus_cohort <- cdm$dus_cohort |>
  requireIsFirstDrugEntry() |>
  requireObservationBeforeDrug(days = 365)

# 4. Summarise drug utilisation metrics (duration, dose, exposures)
dus_results <- cdm$dus_cohort |>
  summariseDrugUtilisation(
    ingredientConceptId = 1125315
  )

# 5. Display publication-ready results table
tableDrugUtilisation(dus_results)
```

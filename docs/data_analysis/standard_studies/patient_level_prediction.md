---
layout: default
title: Patient-Level Prediction
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 6
---

# Patient-Level Prediction Guide

## Introduction & Purpose

Patient-Level Prediction (PLP) studies are designed to build a "risk calculator" that can predict an individual patient's probability of experiencing a future health outcome. Unlike comparative cohort studies that estimate an *average effect* for a population, PLP models provide a *personalised risk score* for a single patient based on their unique clinical history.

The purpose of PLP is to support proactive clinical decision-making. By identifying high-risk individuals before an event occurs, clinicians can intervene earlier with preventative treatments or increased monitoring. The central question is: **"Based on a patient's baseline characteristics, can we accurately predict who is at highest risk of a future outcome?"**

## Study Design

The design is a **prognostic model development and validation study**. It involves the following key steps:

1.  **Defining the Prediction Problem**: Clearly specifying the target population, the outcome to be predicted, and the time window for the prediction.
2.  **Feature Engineering**: Extracting a large number of potential predictor variables (covariates) from the patient's historical data.
3.  **Model Training**: Applying machine learning algorithms to a "training" dataset to learn the relationship between the baseline features and the future outcome.
4.  **Model Validation**: Evaluating the performance of the trained model on a separate "testing" dataset to ensure it is accurate and generalisable.

### Participants

The study starts with a **target cohort** of individuals for whom we want to make a prediction (e.g., "patients newly diagnosed with diabetes"). Within this cohort, the model will be trained on individuals who have sufficient observation time to determine if they experience the outcome.

### Exposures / Predictors

There is no single "exposure." Instead, the model uses a vast number of **predictor variables** (also called features or covariates) extracted from the patient's history *before* the prediction start date. These can include:

*   Demographics
*   All prior medical diagnoses
*   All prior drug exposures
*   All prior medical procedures
*   Data from lab tests or measurements

### Outcomes

The outcome is the event we are trying to predict. It must be a binary (yes/no) event that occurs within a pre-specified **time-at-risk** window. For example, a prediction problem could be defined as:

*   **Target Cohort**: Patients newly diagnosed with atrial fibrillation.
*   **Outcome**: Ischemic stroke.
*   **Time-at-Risk**: Within 1 year after the diagnosis of atrial fibrillation.

### Follow-up

Each patient in the target cohort is followed from their index date (the start of the prediction window) until either the outcome occurs, or the time-at-risk window ends.

### Analyses

The analysis involves applying various machine learning algorithms to the data. The OHDSI PLP framework is designed to make this a standardised process. Key steps include:

1.  **Data Splitting**: The data is split into a training set (used to build the model) and a testing set (used to evaluate it).
2.  **Model Training**: Common algorithms used include Logistic Regression, Gradient Boosting Machines, and Random Forest. The model learns the optimal weights for each predictor variable.
3.  **Performance Evaluation**: The model's performance is assessed on the testing set using metrics like:
    *   **Discrimination**: How well the model separates those who have the outcome from those who do not (measured by the Area Under the Receiver Operating Characteristic Curve, or AUC).
    *   **Calibration**: How well the model's predicted probabilities match the observed reality.

The final output is a validated prediction model that can be applied to new patients to generate a personalised risk score.

## How to Implement This Study

Patient-Level Prediction studies are implemented using the [`PatientLevelPrediction`](https://ohdsi.github.io/PatientLevelPrediction/) (PLP) framework:

```r
library(CDMConnector)
library(CohortConstructor)
library(PatientLevelPrediction)

# 1. Define Target Cohort (T) and Outcome Cohort (O)
cdm$target <- conceptCohort(cdm, list(new_onset_afib = 313217L), name = "target")
cdm$outcome <- conceptCohort(cdm, list(ischemic_stroke = 443454L), name = "outcome")

# 2. Extract Multivariable Features & Covariates
covariateSettings <- FeatureExtraction::createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAgeGroup = TRUE,
  useConditionGroupEraLongTerm = TRUE,
  useDrugGroupEraLongTerm = TRUE
)

# 3. Configure Time-at-Risk (e.g., 365 days post-index) and Train Model
# Algorithms available: LASSO Logistic Regression, Gradient Boosting, Random Forest
# Evaluates discrimination (ROC AUC) and internal calibration.
```

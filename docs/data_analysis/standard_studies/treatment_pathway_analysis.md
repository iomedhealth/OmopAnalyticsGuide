---
layout: default
title: Pathway Analysis
parent: Standardised Analytics
grand_parent: Data Analysis
nav_order: 7
---

# Pathway Analysis Guide

## Introduction & Purpose

Pathway Analysis is a descriptive study designed to map out the "patient journey" by discovering and visualizing the sequence of clinical events people experience over time. While the most common application is for **Treatment Pathways**, the same methodology can be applied to sequences of **medical procedures** or the progression of **diagnosed conditions**.

While a Drug Utilisation Study might tell you *how many* people used a drug, a pathway analysis tells you the *order, timing, and combination* in which they experienced multiple clinical events. The purpose is to understand real-world clinical practice and patient progression. This can help answer important questions such as:

*   **For Treatments**: What is the most common first-line therapy for a disease, and what is the typical second-line therapy?
*   **For Procedures**: What is the common sequence of surgical interventions for a condition?
*   **For Diseases**: How does a disease typically progress from an initial diagnosis to later-stage complications?

This information is invaluable for understanding adherence to clinical guidelines, identifying common patient trajectories, and contextualising the results of other observational studies.

## Study Design

The design is a **descriptive cohort study** focused on sequencing clinical events over time. It is a data-driven discovery process that does not involve a comparator group or traditional hypothesis testing.

### Participants

The study begins with a **target cohort** of individuals who have a specific characteristic of interest (e.g., a new diagnosis of a disease). The analysis then focuses on tracking the occurrence of a pre-specified list of relevant clinical events (e.g., specific medications, procedures, or related diagnoses) for this cohort.

### Events of Interest (Exposures)

The "exposures" are the clinical events that will be sequenced. The power of this method is its flexibility; these events can be:

*   **Drug Exposures**: To create a treatment pathway.
*   **Procedure Occurrences**: To create a procedural pathway.
*   **Condition Occurrences**: To create a disease progression pathway.

The analysis tracks the initiation and timing of these different events over time.

### Outcomes

The "outcomes" of this study are the discovered pathways themselves. The primary outputs are visualisations, most commonly **Sankey diagrams** or **sunburst plots**, which show the flow of patients from one event to the next. The analysis also produces summary statistics, such as:

*   The proportion of patients who start on each first-line event.
*   The median time between sequential events.
*   The probability of transitioning from one specific event to another.

### Follow-up

Follow-up for each patient begins at their cohort index date and continues until the end of data availability or a pre-defined study end date. The analysis engine tracks all occurrences of the specified clinical events during this period.

### Analyses

The analysis is a descriptive, data-mining process. The key steps are:

1.  **Event Identification**: Identifying all occurrences of the events of interest for each patient in the cohort.
2.  **Era Construction**: Consolidating adjacent or overlapping events into continuous "eras."
3.  **Pathway Construction**: Sequencing these eras chronologically for each patient to construct their individual pathway.
4.  **Pathway Aggregation**: Aggregating the individual pathways to identify the most common sequences across the entire cohort.

The final result is a quantitative and visual summary of the most frequently travelled patient journeys.

## How to Implement This Study

Treatment and clinical pathway analyses are implemented using the [`TreatmentPatterns`](https://darwin-eu.github.io/TreatmentPatterns/) package:

```r
library(CDMConnector)
library(CohortConstructor)
library(TreatmentPatterns)

# 1. Define Target Diagnosis Cohort and Treatment Event Cohorts
# targetCohort: Type 2 Diabetes Mellitus
# eventCohorts: Metformin, Sulfonylureas, SGLT2 inhibitors, GLP-1 agonists

# 2. Configure Pathway Settings
# - minEraDuration: Minimum days of exposure to qualify as a distinct line of therapy
# - eraCollapseSize: Window to bridge adjacent exposures of the same treatment
# - combinationWindow: Window to consider overlapping treatments as combination therapy

# 3. Construct and Aggregate Pathways
# Generates Sunburst and Sankey diagrams showing transitions from 1st-line to 2nd-line therapies.
```

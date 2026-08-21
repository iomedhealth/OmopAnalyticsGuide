---
layout: default
title: omock
parent: Package Reference
grand_parent: Data Analysis
nav_order: 14
---

# [omock](https://ohdsi.github.io/omock/)
{: .no_toc}

1. TOC
{:toc}

The `omock` package enables programmatic creation of synthetic OMOP Common Data Model (CDM) datasets for unit testing, development, and tutorial authoring without requiring access to real patient data.

## Overview

Unlike static synthetic database files, `omock` creates in-memory `<cdm_reference>` objects on the fly using a pipeable builder pattern. You can specify exact sample sizes, date ranges, and domain tables to tailor synthetic test data to specific unit tests or study designs.

### Key Features:
- **Composable Pipe Workflow**: Chain mock table generators (`mockPerson()` $\rightarrow$ `mockObservationPeriod()` $\rightarrow$ `mockConditionOccurrence()`).
- **Standardized OMOP Vocabularies**: Automatically populates standard vocabularies and concept tables.
- **Fast In-Memory Testing**: Integrates with DuckDB and `testthat` for sub-second test execution.
- **Controlled Seed Reproducibility**: Deterministic data simulation via random seed specification.

---

## Installation

Install from CRAN:

```r
install.packages("omock")
```

Or install the development version from GitHub:

```r
# install.packages("pak")
pak::pkg_install("ohdsi/omock")
```

---

## Getting Started

Create a customized mock CDM with 500 patients and simulated clinical records:

```r
library(omock)
library(dplyr)
library(CDMConnector)

# Initialize and chain mock generators
cdm <- mockCdmReference() |>
  mockPerson(nPerson = 500, birthRange = as.Date(c("1950-01-01", "2000-01-01"))) |>
  mockObservationPeriod() |>
  mockConditionOccurrence() |>
  mockDrugExposure() |>
  mockMeasurement()

# Verify table record counts
cdm$person |> count() |> collect()
cdm$condition_occurrence |> count() |> collect()
```

---

## Core API Reference

### Modular Mock Table Builders

| Function | Description |
| :--- | :--- |
| `mockCdmReference()` | Initializes an empty in-memory `<cdm_reference>` container with standard vocabulary tables. |
| `mockPerson(cdm, nPerson, ...)` | Generates synthetic patient demographic records in the `person` table. |
| `mockObservationPeriod(cdm, ...)` | Generates valid continuous observation intervals in the `observation_period` table. |
| `mockConditionOccurrence(cdm, ...)` | Populates the `condition_occurrence` table with synthetic diagnosis events. |
| `mockDrugExposure(cdm, ...)` | Simulates prescription and dispensation records in `drug_exposure`. |
| `mockMeasurement(cdm, ...)` | Generates lab tests and clinical vital sign measurements in `measurement`. |
| `mockProcedureOccurrence(cdm, ...)` | Generates surgical and diagnostic procedures in `procedure_occurrence`. |
| `mockVisitOccurrence(cdm, ...)` | Generates inpatient, outpatient, and emergency room encounters in `visit_occurrence`. |
| `mockDeath(cdm, ...)` | Simulates mortality records in the `death` table. |
| `mockCohort(cdm, ...)` | Creates pre-populated synthetic `<cohort_table>` objects for testing cohort analytics. |

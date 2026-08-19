---
layout: default
title: OmopSketch
parent: Package Reference
grand_parent: Data Analysis
nav_order: 11
---

# [OmopSketch](https://ohdsi.github.io/OmopSketch/)
{: .no_toc}

1. TOC
{:toc}

The `OmopSketch` package provides fast, automated tools for high-level characterization and exploratory data analysis of OMOP Common Data Model (CDM) databases.

## Overview

Before launching an observational study, researchers must understand the shape, size, historical coverage, and data quality of their OMOP database. `OmopSketch` generates rapid summaries ("sketches") of database demographics, table volumes, observation periods, and concept usage patterns.

### Key Features:
- **Instant Snapshot**: Generates an executive summary of vocabulary versions, patient counts, and table sizes.
- **Observation Period Dynamics**: Evaluates longitudinal coverage, continuous observation trends, and seasonal gaps.
- **Clinical Table Profiling**: Analyzes record density, missingness, and mapping proportions across OMOP clinical domains.
- **Interactive Shiny Explorer**: Launches a self-contained Shiny dashboard for visual exploration of database characteristics.

---

## Installation

```r
# Install from CRAN
install.packages("OmopSketch")

# Or development version from GitHub
# pak::pkg_install("ohdsi/OmopSketch")
```

---

## Getting Started

```r
library(OmopSketch)
library(CDMConnector)

# Connect to database
con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir())
cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

# 1. Summarize database snapshot
snapshot <- summariseOmopSnapshot(cdm)
tableOmopSnapshot(snapshot)

# 2. Analyze observation period coverage
obs_summary <- summariseObservationPeriod(cdm$observation_period)
plotObservationPeriod(obs_summary)

# 3. Analyze clinical records in condition_occurrence
condition_profile <- summariseClinicalRecords(
  cdm = cdm,
  omopTableName = "condition_occurrence"
)
```

---

## Core API Reference

### Database Snapshot & Overview

| Function | Description |
| :--- | :--- |
| `summariseOmopSnapshot(cdm)` | Computes database metadata, vocabulary release, total patient counts, and table row counts. |
| `tableOmopSnapshot(result)` | Renders a formatted publication-ready table of the database snapshot. |

### Observation Period & Temporal Coverage

| Function | Description |
| :--- | :--- |
| `summariseObservationPeriod(observationPeriod)` | Analyzes observation duration, gaps, and records per person. |
| `summariseInObservation(observationPeriod, interval)` | Tracks population in-observation trends over years, quarters, or months. |
| `plotObservationPeriod(result)` | Plots distributions of observation time. |
| `plotInObservation(result)` | Generates temporal trend curves of actively observed patients. |

### Clinical Table Quality & Concept Profiling

| Function | Description |
| :--- | :--- |
| `summariseMissingData(cdm, omopTableName)` | Evaluates column completeness and zero/unmapped concept ID frequencies. |
| `summariseClinicalRecords(cdm, omopTableName)` | Computes records per patient, standard vs non-standard concept mappings, and domain alignment. |
| `summariseRecordCount(cdm, omopTableName, interval)` | Tracks longitudinal event recording trends across calendar intervals. |
| `summariseConceptIdCounts(cdm, omopTableName)` | Computes record and patient counts per individual clinical concept ID. |
| `tableTopConceptCounts(result, top)` | Displays the most frequently recorded concept IDs in a clinical table. |

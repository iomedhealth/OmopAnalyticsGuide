---
layout: default
title: OmopConstructor
parent: Package Reference
grand_parent: Data Analysis
nav_order: 15
---

# [OmopConstructor](https://ohdsi.github.io/OmopConstructor/)
{: .no_toc}

1. TOC
{:toc}

The `OmopConstructor` R package provides functionality to construct and standardize derived tables in the Observational Medical Outcomes Partnership (OMOP) Common Data Model (CDM), such as `observation_period`, `drug_era`, and `condition_era`.

---

## Overview

In OMOP CDM architectures, certain derived tables represent consolidated chronological intervals synthesized from raw clinical encounter tables. For instance, the `observation_period` table defines the continuous time span during which a patient's healthcare interactions are reliably captured by the database.

`OmopConstructor` automates the derivation and recalculation of these tables directly against database connections, allowing researchers and data engineers to establish custom observation boundaries, collapse gaps, and enforce study-specific observation rules.

---

## Key Features

- **Automated Observation Period Construction**: Synthesizes observation periods from clinical activity across visits, conditions, drugs, procedures, and measurements.
- **Customizable Persistence & Gaps**: Configurable allowable gap days (`collapseDays`, `persistenceDays`) to bridge intermittent observation breaks.
- **Demographic & Mortality Censoring**: Automatically caps observation periods at recorded death dates, maximum plausible age (e.g., `censorAge = 120`), or extraction date ceilings.
- **Multi-DBMS Compatibility**: Validated across PostgreSQL, Snowflake, Amazon Redshift, Microsoft SQL Server, and DuckDB.
- **Containerized ETL**: Includes Docker and CLI workflows for reproducible, headless batch construction.

---

## Installation

Install `OmopConstructor` from CRAN or GitHub:

```r
# From CRAN
install.packages("OmopConstructor")

# Development version from GitHub
# install.packages("pak")
pak::pkg_install("ohdsi/OmopConstructor")
```

---

## Usage Example

The following example demonstrates constructing a tailored `observation_period` table in an OMOP CDM reference using DuckDB:

```r
library(CDMConnector)
library(OmopConstructor)
library(OmopSketch)
library(dplyr)

# 0. Connect to OMOP CDM database
con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("GiBleed"))
cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")

# 1. Build standardized observation periods
cdm <- buildObservationPeriod(
  cdm = cdm,
  collapseDays = 30,
  persistenceDays = 30,
  dateRange = as.Date(c("1950-01-01", "2025-12-31")),
  censorAge = 120
)

# 2. Inspect generated observation_period table
cdm$observation_period |>
  glimpse()

# 3. Summarise and validate observation periods with OmopSketch
obs_summary <- summariseObservationPeriod(
  observationPeriod = cdm$observation_period
)

tableObservationPeriod(
  result = obs_summary,
  type = "gt"
)
```

---

## Main Functions

| Function | Purpose |
| :--- | :--- |
| `buildObservationPeriod()` | Constructs or recalculates the `observation_period` table from clinical event tables with customizable collapse rules, date ceilings, and censoring criteria. |

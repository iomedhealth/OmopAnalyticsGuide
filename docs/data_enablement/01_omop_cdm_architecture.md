---
layout: default
title: OMOP CDM Architecture & Tables
parent: Data Enablement
nav_order: 1
---

# OMOP CDM Architecture & Domain Models
{: .no_toc }

The Observational Medical Outcomes Partnership (OMOP) Common Data Model (CDM) is an open-community relational database schema designed to standardize both the structure and the semantic content of disparate observational health records.

1. TOC
{:toc}

## 1. Dual Standardization: Structure and Content

Traditional electronic health record (EHR) and claims systems store data in proprietary, departmental formats. The OMOP CDM achieves universal interoperability through two complementary layers:

```mermaid
flowchart LR
    subgraph RawData["Raw Healthcare Data"]
        R1["Disparate Relational Schemas"]
        R2["Local & Non-Standard Codes
        (ICD-10, ICD-9, Local Lab IDs)"]
    end

    subgraph OMOPCDM["OMOP Common Data Model"]
        S1["Structure Standardization
        Unified table schemas, datatypes,
        foreign keys & observation windows"]
        S2["Content Standardization
        Normalizing all clinical terms to
        standard concept_ids via OHDSI vocabularies"]
    end

    R1 --> S1
    R2 --> S2
```

1.  **Structure Standardization:** Enforces uniform table definitions, column names, data types, and entity relationships across all databases.
2.  **Content Standardization:** Represents all clinical entities (diagnoses, medications, lab tests, procedures) using globally unique standard **`concept_id`** integers derived from authoritative reference terminologies (SNOMED CT, RxNorm, LOINC, UCUM).

### OMOP CDM Versions
*   **OMOP CDM v5.4:** The current authoritative global benchmark used across OHDSI and DARWIN EU network studies.
*   **OMOP CDM v5.3:** Widely deployed legacy version; fully forward-compatible with v5.4 tooling.
*   **Specifications:** Complete schema DDLs and data dictionary specifications are maintained on GitHub at [OHDSI/CommonDataModel](https://ohdsi.github.io/CommonDataModel/cdm54.html).

## 2. Relational Database Foundations & SQL/R Synergy

Observational health analytics leverages the complementary strengths of relational Database Management Systems (DBMS) and statistical computing environments:

```mermaid
flowchart TD
    subgraph DatabaseEngine["Database Server (Pushdown Execution)"]
        DB["Relational DBMS
        (PostgreSQL, DuckDB, Snowflake, BigQuery)"]
        SQL["SQL Engine:
        Filtering, Joining, Grouping across
        100M+ Rows behind Hospital Firewall"]
        DB --- SQL
    end

    subgraph ClientEnv["R / HADES Environment (Local / Secure Node)"]
        R["R Analytical Environment
        (CDMConnector, CohortConstructor, HADES)"]
        Stat["Statistical Estimation, Survival Analysis,
        Table 1 Summaries, visOmopResults"]
        R --- Stat
    end

    R -->|"Pushdown SQL Queries (dbplyr / DBI)"| SQL
    SQL -->|"Aggregated Summary Results Only"| R
```

*   **SQL (In-Database Computation):** Executes compute-heavy cohort filtering, temporal joins, and aggregations directly on database engines containing billions of rows without moving patient-level data into client memory.
*   **R (Statistical Analysis & Reporting):** Orchestrates study pipelines, calculates adjusted effect estimates (propensity score matching, Cox regression), and formats publication tables and figures.

## 3. Core CDM v5.4 Clinical Tables

The OMOP CDM is strictly **patient-centric**. All clinical events are linked to a single master record in the `PERSON` table:

```mermaid
erDiagram
    PERSON ||--o{ OBSERVATION_PERIOD : "has observation time"
    PERSON ||--o{ VISIT_OCCURRENCE : "experiences encounters"
    PERSON ||--o{ CONDITION_OCCURRENCE : "diagnosed with"
    PERSON ||--o{ DRUG_EXPOSURE : "administered / prescribed"
    PERSON ||--o{ MEASUREMENT : "tested with"
    PERSON ||--o{ PROCEDURE_OCCURRENCE : "undergoes"
    PERSON ||--o{ OBSERVATION : "recorded with"
    PERSON ||--o| DEATH : "recorded death"

    VISIT_OCCURRENCE ||--o{ CONDITION_OCCURRENCE : "diagnosed during"
    VISIT_OCCURRENCE ||--o{ DRUG_EXPOSURE : "prescribed during"
    VISIT_OCCURRENCE ||--o{ MEASUREMENT : "measured during"
    VISIT_OCCURRENCE ||--o{ PROCEDURE_OCCURRENCE : "performed during"

    PERSON {
        integer person_id PK
        integer gender_concept_id FK
        integer year_of_birth
        integer month_of_birth
        integer day_of_birth
        integer race_concept_id FK
        integer ethnicity_concept_id FK
    }

    OBSERVATION_PERIOD {
        integer observation_period_id PK
        integer person_id FK
        date observation_period_start_date
        date observation_period_end_date
        integer period_type_concept_id FK
    }

    CONDITION_OCCURRENCE {
        integer condition_occurrence_id PK
        integer person_id FK
        integer condition_concept_id FK
        date condition_start_date
        date condition_end_date
        integer condition_type_concept_id FK
        string condition_source_value
    }

    DRUG_EXPOSURE {
        integer drug_exposure_id PK
        integer person_id FK
        integer drug_concept_id FK
        date drug_exposure_start_date
        date drug_exposure_end_date
        integer drug_type_concept_id FK
        numeric quantity
        integer days_supply
    }

    MEASUREMENT {
        integer measurement_id PK
        integer person_id FK
        integer measurement_concept_id FK
        date measurement_date
        numeric value_as_number
        integer unit_concept_id FK
        integer measurement_type_concept_id FK
    }
```

### 3.1 Primary Clinical Domain Tables

| Table | Domain Description | Standard Reference Vocabulary | Key Identifier & Concept Column |
| :--- | :--- | :--- | :--- |
| **`PERSON`** | Unique patient demographics, sex, birth date, race, ethnicity | OMOP Gender / Race | `person_id`, `gender_concept_id` |
| **`OBSERVATION_PERIOD`** | Valid longitudinal time spans with verifiable healthcare recording | OMOP Type Concepts | `observation_period_id`, `person_id` |
| **`VISIT_OCCURRENCE`** | Healthcare encounters (inpatient admission, outpatient clinic, emergency room) | OMOP Visit | `visit_occurrence_id`, `visit_concept_id` |
| **`CONDITION_OCCURRENCE`** | Diagnoses, medical signs, symptoms, and clinical findings | SNOMED CT | `condition_occurrence_id`, `condition_concept_id` |
| **`DRUG_EXPOSURE`** | Inpatient administrations, prescriptions, and pharmacy dispensations | RxNorm / RxNorm Extension | `drug_exposure_id`, `drug_concept_id` |
| **`MEASUREMENT`** | Structured laboratory tests, vital signs, quantitative assays, and histology | LOINC, SNOMED CT, UCUM | `measurement_id`, `measurement_concept_id` |
| **`PROCEDURE_OCCURRENCE`** | Surgical operations, diagnostic procedures, radiology imaging, and therapy | SNOMED CT, CPT-4, ICD-10-PCS | `procedure_occurrence_id`, `procedure_concept_id` |
| **`OBSERVATION`** | Clinical facts not fitting other domains (social history, allergies, lifestyle) | SNOMED CT | `observation_id`, `observation_concept_id` |
| **`DEATH`** | Date and cause of death | SNOMED CT | `person_id`, `cause_concept_id` |

## 4. Standard Column Conventions

Every event table in the OMOP CDM follows a consistent, predictable column naming convention:

```mermaid
flowchart TD
    subgraph ColumnStructure["Standard OMOP Table Column Pattern"]
        C1["1. Primary Key: `<domain>_id` (Unique row identifier)"]
        C2["2. Foreign Key: `person_id` (Links to PERSON table)"]
        C3["3. Standard Concept: `<domain>_concept_id` (Target standard integer)"]
        C4["4. Event Dates: `<domain>_start_date` & `<domain>_end_date`"]
        C5["5. Type Concept: `<domain>_type_concept_id` (Data provenance)"]
        C6["6. Source Provenance: `<domain>_source_value` & `<domain>_source_concept_id`"]
    end
```

### The Role of `_type_concept_id`
The `_type_concept_id` field records the **provenance** (provenance mechanism) of each record:
*   *EHR problem list diagnosis* (`concept_id = 32840`)
*   *Inpatient hospital discharge diagnosis* (`concept_id = 32817`)
*   *Billing claim primary diagnosis* (`concept_id = 32810`)
*   *Physician prescription written* (`concept_id = 38000177`)
*   *Pharmacy dispensation record* (`concept_id = 38000175`)

This allows researchers to differentiate between a confirmed physician discharge diagnosis and an unadjudicated outpatient billing code.

## 5. Domain Routing & Content Normalization Example

In OMOP, the destination table for a clinical event is determined by the **domain** of the standard mapped concept, not the original source table.

```mermaid
flowchart TD
    Source["Hospital Source Record:
    Source Code: ICD-10 'R78.81'
    Description: 'Bacteremia'"]

    Map["Vocabulary Mapping:
    Maps to SNOMED Concept ID: 4135607
    Domain: 'Condition'"]

    Target["Routing Target:
    Loaded into CONDITION_OCCURRENCE table
    condition_concept_id = 4135607
    condition_source_value = 'R78.81'"]

    Source --> Map --> Target
```

### Detailed Example: Laboratory Measurement
Consider a laboratory test result: **Hemoglobin in Blood = 9.0 g/dL**

In the OMOP `MEASUREMENT` table, this event is normalized into standard structural and content fields:

| Column | Value | Semantic Meaning | Reference Standard |
| :--- | :--- | :--- | :--- |
| `measurement_id` | `104859` | Unique record identifier | Primary Key |
| `person_id` | `243` | Patient ID | Foreign Key to `PERSON` |
| `measurement_concept_id` | **`3000963`** | *Hemoglobin [Mass/volume] in Blood* | LOINC (`718-7`) |
| `measurement_date` | `2024-03-15` | Date test specimen was drawn | ISO Date |
| `value_as_number` | `9.0` | Quantitative numeric result | Float |
| `unit_concept_id` | **`8713`** | *gram per deciliter (g/dL)* | UCUM (`g/dL`) |
| `measurement_type_concept_id` | `32856` | *Lab result from Laboratory Information System* | OMOP Type Concept |
| `measurement_source_value` | `"HGB_BLD"` | Original local hospital test code | Local LIS Code |

## References

1. **Overhage JM, Ryan PB, Reich C, Hartzema AG, Stang PE.** (2012). *Validation of a common data model for active safety surveillance research.* Journal of the American Medical Informatics Association, 19(1), 54–60. [doi:10.1136/amiajnl-2011-000376](https://doi.org/10.1136/amiajnl-2011-000376).
2. **OHDSI CDM Working Group.** (2024). *OMOP Common Data Model v5.4 Specifications.* [https://ohdsi.github.io/CommonDataModel/cdm54.html](https://ohdsi.github.io/CommonDataModel/cdm54.html).
3. **Voss EA, Makadia R, Matcho A, et al.** (2015). *Feasibility and utility of mapping heterogeneous electronic health records to the OMOP Common Data Model.* JAMIA, 22(3), 553–561.

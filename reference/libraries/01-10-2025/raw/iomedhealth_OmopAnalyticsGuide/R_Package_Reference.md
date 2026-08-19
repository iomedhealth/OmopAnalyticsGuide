# Page: R Package Reference

# R Package Reference

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/index.md](docs/data_analysis/index.md)
- [docs/data_analysis/package_reference/IncidencePrevalence.md](docs/data_analysis/package_reference/IncidencePrevalence.md)
- [docs/data_analysis/package_reference/index.md](docs/data_analysis/package_reference/index.md)

</details>



This comprehensive reference documents all R packages in the OMOP analytics ecosystem, providing a structured guide to the code entities, classes, and functions that form the foundation of observational health data research. This page serves as the technical specification for the package architecture and dependencies.

For step-by-step implementation guidance, see [Environment Setup and Getting Started](#3.1). For conceptual understanding of study methodologies, see [Study Methodologies](#4).

## Package Ecosystem Architecture

The OMOP analytics framework follows a layered architecture where foundation packages provide core infrastructure, and specialized packages build upon them for domain-specific analyses. Each layer defines specific interfaces and contracts that enable interoperability.

### Dependency Architecture

```mermaid
graph TB
    subgraph "Foundation Layer"
        DBI["DBI<br/>Database Interface"]
        DPLYR["dplyr/dbplyr<br/>Lazy Evaluation"]
        OMOPGEN["omopgenerics<br/>S3 Classes & Methods"]
    end
    
    subgraph "Connection Layer"
        CDMCON["CDMConnector<br/>cdm_reference objects"]
        OMOCK["omock<br/>mockDb() functions"]
    end
    
    subgraph "Cohort Management Layer"
        CODELIST["CodelistGenerator<br/>codelists & code_sets"]
        COHORTCON["CohortConstructor<br/>cohort_table objects"]
        PROFILES["PatientProfiles<br/>addDemographics()"]
    end
    
    subgraph "Analysis Layer"
        CHARS["CohortCharacteristics<br/>summariseCharacteristics()"]
        INCPREV["IncidencePrevalence<br/>estimateIncidence()"]
        DRUGUTIL["DrugUtilisation<br/>generateDrugUtilisationCohortSet()"]
        SURVIVAL["CohortSurvival<br/>estimateSingleEventSurvival()"]
        PHENOTYPE["PhenotypeR<br/>summarisePhenotypes()"]
        SKETCH["OmopSketch<br/>summariseOmopSnapshot()"]
    end
    
    subgraph "Visualization Layer"
        VISOMOP["visOmopResults<br/>plotTable() & formatTable()"]
    end
    
    DBI --> CDMCON
    DPLYR --> CDMCON
    OMOPGEN --> CDMCON
    CDMCON --> OMOCK
    CDMCON --> CODELIST
    CDMCON --> COHORTCON
    CDMCON --> PROFILES
    
    CODELIST --> COHORTCON
    COHORTCON --> CHARS
    COHORTCON --> INCPREV
    COHORTCON --> DRUGUTIL
    COHORTCON --> SURVIVAL
    COHORTCON --> PHENOTYPE
    PROFILES --> CHARS
    
    CHARS --> VISOMOP
    INCPREV --> VISOMOP
    DRUGUTIL --> VISOMOP
    SURVIVAL --> VISOMOP
    PHENOTYPE --> VISOMOP
    SKETCH --> VISOMOP
```

*Sources: [docs/data_analysis/package_reference/index.md:38-66]()*

### Core Data Objects and Interfaces

```mermaid
graph LR
    subgraph "Data Flow"
        CDM_REF["cdm_reference<br/>(omopgenerics)"]
        COHORT_TBL["cohort_table<br/>(CohortConstructor)"]
        SUMM_RES["summarised_result<br/>(omopgenerics)"]
    end
    
    subgraph "Interface Methods"
        CDM_CON["cdm_from_con()"]
        GEN_COHORT["generateCohortSet()"]
        SUMM_FUNC["summarise*() functions"]
        VIS_FUNC["visOmop*() functions"]
    end
    
    CDM_CON --> CDM_REF
    CDM_REF --> GEN_COHORT
    GEN_COHORT --> COHORT_TBL
    COHORT_TBL --> SUMM_FUNC
    SUMM_FUNC --> SUMM_RES
    SUMM_RES --> VIS_FUNC
```

*Sources: [docs/data_analysis/index.md:36-44](), [docs/data_analysis/package_reference/index.md:38-66]()*

## Package Categories by Functional Role

### Foundation Layer Packages

Core infrastructure packages that establish database connections and provide common interfaces.

| Package | Primary Classes/Objects | Key Functions |
|---------|------------------------|---------------|
| **`omopgenerics`** | `cdm_reference`, `summarised_result` | `newCdmReference()`, `emptySummarisedResult()` |
| **`CDMConnector`** | `cdm_reference` | `cdm_from_con()`, `cdm_disconnect()` |
| **`omock`** | Mock `cdm_reference` | `mockDb()`, `mockPerson()` |

*Sources: [docs/data_analysis/index.md:40-43]()*

### Cohort Management Packages

Packages for defining, constructing, and characterizing patient populations.

| Package | Primary Objects | Core Functions |
|---------|----------------|----------------|
| **`CodelistGenerator`** | `codelists`, `code_sets` | `getDrugIngredientCodes()`, `getATCCodes()` |
| **`CohortConstructor`** | `cohort_table` | `generateCohortSet()`, `requirePriorObservation()` |
| **`PatientProfiles`** | Enhanced `cohort_table` | `addDemographics()`, `addTableIntersect()` |

*Sources: [docs/data_analysis/index.md:49-53]()*

### Specialized Analysis Packages

Domain-specific packages for epidemiological and clinical analyses.

| Package | Analysis Type | Primary Functions |
|---------|--------------|------------------|
| **`CohortCharacteristics`** | Baseline characterization | `summariseCharacteristics()`, `summariseLargeScaleCharacteristics()` |
| **`IncidencePrevalence`** | Population epidemiology | `estimateIncidence()`, `estimatePointPrevalence()` |
| **`DrugUtilisation`** | Medication patterns | `generateDrugUtilisationCohortSet()`, `summariseDrugRestart()` |
| **`CohortSurvival`** | Time-to-event analysis | `estimateSingleEventSurvival()`, `estimateCompetingRiskSurvival()` |
| **`PhenotypeR`** | Phenotype validation | `summarisePhenotypes()`, `summarisePhenotypeCodeUse()` |
| **`OmopSketch`** | Database profiling | `summariseOmopSnapshot()`, `summariseObservationPeriod()` |

*Sources: [docs/data_analysis/index.md:58-67](), [docs/data_analysis/package_reference/IncidencePrevalence.md:137-145]()*

### Visualization and Results Packages

Packages for standardized output generation and visualization.

| Package | Output Type | Key Functions |
|---------|------------|---------------|
| **`visOmopResults`** | Tables and plots | `plotTable()`, `formatTable()`, `plotCharacteristics()` |

*Sources: [docs/data_analysis/index.md:80-82]()*

## Analysis Workflow Mapping

### Clinical Question to Code Entity Mapping

```mermaid
graph TD
    subgraph "Clinical Questions"
        Q1["Who are my patients?<br/>(Demographics)"]
        Q2["Define study population<br/>(Inclusion/Exclusion)"]
        Q3["Calculate disease burden<br/>(Incidence/Prevalence)"]
        Q4["Compare treatments<br/>(Comparative Effectiveness)"]
        Q5["Predict outcomes<br/>(Risk Modeling)"]
    end
    
    subgraph "Code Implementation"
        F1["addDemographics()<br/>addAge(), addSex()"]
        F2["generateCohortSet()<br/>requirePriorObservation()"]
        F3["estimateIncidence()<br/>estimatePointPrevalence()"]
        F4["estimateSingleEventSurvival()<br/>cox regression workflow"]
        F5["PatientLevelPrediction<br/>feature engineering"]
    end
    
    subgraph "Output Objects"
        O1["summarised_result<br/>demographics table"]
        O2["cohort_table<br/>study populations"]
        O3["summarised_result<br/>rates with CI"]
        O4["summarised_result<br/>survival curves"]
        O5["model object<br/>prediction scores"]
    end
    
    Q1 --> F1
    Q2 --> F2
    Q3 --> F3
    Q4 --> F4
    Q5 --> F5
    
    F1 --> O1
    F2 --> O2
    F3 --> O3
    F4 --> O4
    F5 --> O5
```

*Sources: [docs/data_analysis/package_reference/index.md:70-196]()*

### Standard Analysis Workflow

```mermaid
graph TD
    START["Start Analysis"] --> CONNECT["cdm_from_con()"]
    CONNECT --> CODES["getDrugIngredientCodes()"]
    CODES --> COHORTS["generateCohortSet()"]
    COHORTS --> CHARS["summariseCharacteristics()"]
    CHARS --> ANALYSIS{Analysis Type}
    
    ANALYSIS --> INCIDENCE["estimateIncidence()"]
    ANALYSIS --> SURVIVAL["estimateSingleEventSurvival()"]
    ANALYSIS --> DRUG["generateDrugUtilisationCohortSet()"]
    
    INCIDENCE --> VIS["plotTable()"]
    SURVIVAL --> VIS
    DRUG --> VIS
    
    VIS --> REPORT["Generate Report"]
```

*Sources: [docs/data_analysis/package_reference/IncidencePrevalence.md:90-105]()*

## Detailed Package References

For comprehensive documentation of specific packages and their functions:

- **Core Infrastructure**: See [Core Infrastructure Packages](#3.3.1) for `CDMConnector`, `omopgenerics`, `omock`, and `OmopSketch`
- **Cohort Management**: See [Cohort Management Packages](#3.3.2) for `CohortConstructor`, `CohortCharacteristics`, and `PatientProfiles`  
- **Specialized Analysis**: See [Specialized Analysis Packages](#3.3.3) for `IncidencePrevalence`, `DrugUtilisation`, `CohortSurvival`, `CodelistGenerator`, and `PhenotypeR`
- **Visualization**: See [Visualization and Results](#3.3.4) for `visOmopResults`

*Sources: [docs/data_analysis/index.md:1-86](), [docs/data_analysis/package_reference/index.md:1-196]()*
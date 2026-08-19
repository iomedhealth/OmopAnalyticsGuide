# Page: OMOP Analytics Framework

# OMOP Analytics Framework

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/index.md](docs/data_analysis/index.md)
- [docs/data_analysis/package_reference/IncidencePrevalence.md](docs/data_analysis/package_reference/IncidencePrevalence.md)
- [docs/data_analysis/package_reference/index.md](docs/data_analysis/package_reference/index.md)

</details>



The OMOP Analytics Framework provides a comprehensive R package ecosystem for conducting observational health data studies using the OMOP Common Data Model (CDM). This framework enables researchers to perform regulatory-grade analyses from clinical question formulation through statistical analysis and visualization, following standardized methodologies promoted by OHDSI and DARWIN-EU initiatives.

This document covers the technical architecture, package dependencies, and integration patterns within the R ecosystem. For step-by-step implementation guidance, see [Environment Setup and Getting Started](#3.1). For detailed package documentation, see [R Package Reference](#3.3).

## Package Ecosystem Architecture

The framework follows a layered architecture where foundation packages provide core infrastructure, and specialized packages build upon them for domain-specific analyses. This design ensures modularity, reusability, and consistent data handling across different study types.

### Core Architecture Layers

```mermaid
graph TB
    subgraph "Foundation Layer"
        omopgenerics["omopgenerics<br/>Common Classes & Methods"]
        CDMConnector["CDMConnector<br/>Database Connection"]
        omock["omock<br/>Mock Data Generation"]
        OmopSketch["OmopSketch<br/>Database Summarization"]
    end

    subgraph "Cohort Generation Layer" 
        CodelistGenerator["CodelistGenerator<br/>Medical Code Lists"]
        CohortConstructor["CohortConstructor<br/>Population Definition"]
    end

    subgraph "Feature Engineering Layer"
        PatientProfiles["PatientProfiles<br/>Patient Characteristics"]
    end

    subgraph "Analysis Layer"
        CohortCharacteristics["CohortCharacteristics<br/>Descriptive Analysis"]
        IncidencePrevalence["IncidencePrevalence<br/>Population Epidemiology"]
        DrugUtilisation["DrugUtilisation<br/>Medication Patterns"]
        CohortSurvival["CohortSurvival<br/>Time-to-Event Analysis"]
        PhenotypeR["PhenotypeR<br/>Phenotype Validation"]
    end

    subgraph "Visualization Layer"
        visOmopResults["visOmopResults<br/>Standardized Output"]
    end

    omopgenerics --> CDMConnector
    omopgenerics --> omock
    CDMConnector --> OmopSketch
    CDMConnector --> CodelistGenerator
    CDMConnector --> CohortConstructor
    
    CodelistGenerator --> CohortConstructor
    CohortConstructor --> PatientProfiles
    CohortConstructor --> CohortCharacteristics
    CohortConstructor --> IncidencePrevalence
    CohortConstructor --> DrugUtilisation
    CohortConstructor --> CohortSurvival
    CohortConstructor --> PhenotypeR
    
    PatientProfiles --> CohortCharacteristics
    
    CohortCharacteristics --> visOmopResults
    IncidencePrevalence --> visOmopResults
    DrugUtilisation --> visOmopResults
    CohortSurvival --> visOmopResults
    PhenotypeR --> visOmopResults
```

Sources: [docs/data_analysis/package_reference/index.md:36-66]()

### Package Categories and Functions

The framework organizes packages into functional categories based on their role in the analysis workflow:

| Layer | Package | Primary Functions | Purpose |
|-------|---------|-------------------|---------|
| **Foundation** | `omopgenerics` | Class definitions, method dispatch | Provides common interface across packages |
| | `CDMConnector` | `cdm_from_con()`, connection management | Establishes database connections |
| | `omock` | `mockCdm()`, test data generation | Creates mock CDM for development |
| **Cohort Generation** | `CodelistGenerator` | `getCandidateCodes()`, codelist creation | Generates medical code sets |
| | `CohortConstructor` | `newCohortTable()`, cohort definition | Defines study populations |
| **Analysis** | `CohortCharacteristics` | `summariseCharacteristics()` | Generates Table 1 summaries |
| | `IncidencePrevalence` | `estimateIncidence()`, `estimatePrevalence()` | Calculates epidemiological measures |
| | `DrugUtilisation` | `summariseDrugUtilisation()` | Analyzes medication patterns |
| **Visualization** | `visOmopResults` | Standardized plotting functions | Creates consistent visualizations |

Sources: [docs/data_analysis/index.md:35-83]()

## Clinical Question to Code Workflow

The framework translates clinical research questions into executable code through a standardized workflow that maps study objectives to specific package functions.

### Study Type Mapping to Package Functions

```mermaid
graph LR
    subgraph "Clinical Questions"
        Q1["Who are my patients?<br/>(Demographics, Comorbidities)"]
        Q2["How common is this disease?<br/>(Incidence, Prevalence)"]
        Q3["How are drugs used?<br/>(Utilization Patterns)"]
        Q4["What is the treatment effect?<br/>(Comparative Effectiveness)"]
        Q5["Can we predict outcomes?<br/>(Risk Prediction)"]
    end

    subgraph "Code Implementation"
        summariseCharacteristics["summariseCharacteristics()<br/>CohortCharacteristics"]
        estimateIncidence["estimateIncidence()<br/>IncidencePrevalence"]
        summariseDrugUtilisation["summariseDrugUtilisation()<br/>DrugUtilisation"]
        estimateSurvival["estimateSurvival()<br/>CohortSurvival"]
        PatientLevelPrediction["PatientLevelPrediction<br/>HADES Package"]
    end

    Q1 --> summariseCharacteristics
    Q2 --> estimateIncidence
    Q3 --> summariseDrugUtilisation
    Q4 --> estimateSurvival
    Q5 --> PatientLevelPrediction
```

Sources: [docs/data_analysis/package_reference/index.md:70-196]()

### Core Workflow Implementation

The standard analysis workflow follows this sequence of operations:

```mermaid
graph TD
    subgraph "1. Environment Setup"
        setup_env["library(CDMConnector)<br/>library(CohortConstructor)<br/>library(dplyr)"]
    end

    subgraph "2. Database Connection" 
        cdm_connection["cdm <- cdm_from_con(<br/>  con = connection,<br/>  cdm_schema = 'cdm',<br/>  write_schema = 'results'<br/>)"]
    end

    subgraph "3. Cohort Definition"
        cohort_def["cdm$cohort <- newCohortTable(<br/>  cdm = cdm,<br/>  cohortSet = cohort_definition<br/>)"]
    end

    subgraph "4. Analysis Execution"
        analysis_func["results <- analysisFunction(<br/>  cdm = cdm,<br/>  cohortTable = 'cohort',<br/>  ageGroup = c(18, 65)<br/>)"]
    end

    subgraph "5. Results Processing"
        visualization["visOmopResults::plotResults(<br/>  results<br/>)"]
    end

    setup_env --> cdm_connection
    cdm_connection --> cohort_def
    cohort_def --> analysis_func
    analysis_func --> visualization
```

Sources: [docs/data_analysis/package_reference/IncidencePrevalence.md:38-84]()

## Package Integration Patterns

The framework uses consistent integration patterns to ensure seamless data flow between packages and maintain reproducibility across different analysis types.

### Standard Data Objects

All packages operate on standardized data objects that ensure consistency and interoperability:

| Object Type | Description | Key Attributes |
|-------------|-------------|----------------|
| `cdm` | CDM reference object | Database connection, table references |
| `cohort_table` | Cohort definitions | `cohort_definition_id`, `subject_id`, `cohort_start_date` |
| `summarised_result` | Analysis outputs | Standardized result format across packages |

### Common Function Patterns

The framework follows consistent function naming and parameter patterns:

```mermaid
graph TB
    subgraph "Function Naming Convention"
        estimate["estimate*()<br/>(IncidencePrevalence)"]
        summarise["summarise*()<br/>(CohortCharacteristics)"]
        generate["generate*()<br/>(CodelistGenerator)"]
        plot_func["plot*()<br/>(visOmopResults)"]
    end

    subgraph "Standard Parameters"
        cdm_param["cdm: CDM reference object"]
        cohort_param["cohortTable: Cohort table name"]
        strata_param["strata: Stratification variables"]
        age_param["ageGroup: Age stratification"]
    end

    estimate --> cdm_param
    summarise --> cohort_param  
    generate --> strata_param
    plot_func --> age_param
```

Sources: [docs/data_analysis/package_reference/IncidencePrevalence.md:137-145]()

## Study Methodology Integration

The framework supports multiple study methodologies through specialized package combinations that address different research objectives.

### Descriptive Studies Implementation

For characterizing populations and describing disease patterns:

| Study Type | Primary Packages | Key Functions |
|------------|------------------|---------------|
| **Cohort Characterization** | `CohortCharacteristics`, `PatientProfiles` | `summariseCharacteristics()`, `addDemographics()` |
| **Incidence/Prevalence** | `IncidencePrevalence` | `estimateIncidence()`, `estimatePrevalence()` |
| **Drug Utilization** | `DrugUtilisation` | `summariseDrugUtilisation()`, `summariseDrugRestart()` |

### Comparative Studies Implementation  

For evaluating treatment effects and causal inference:

```mermaid
graph LR
    subgraph "Comparative Study Workflow"
        cohort_construction["CohortConstructor<br/>Define Treatment/Control"]
        feature_engineering["PatientProfiles<br/>Add Baseline Characteristics"]
        matching_weighting["External R Packages<br/>MatchIt, WeightIt"]
        survival_analysis["CohortSurvival<br/>Time-to-Event Analysis"]
    end

    cohort_construction --> feature_engineering
    feature_engineering --> matching_weighting
    matching_weighting --> survival_analysis
```

Sources: [docs/data_analysis/package_reference/index.md:114-151]()

### Validation Studies Implementation

For ensuring phenotype accuracy and study quality:

| Validation Type | Package | Key Functions |
|-----------------|---------|---------------|
| **Phenotype Validation** | `PhenotypeR` | Diagnostic functions for cohort definitions |
| **Database Quality** | `OmopSketch` | `summariseDataSnapshot()` for CDM profiling |

Sources: [docs/data_analysis/index.md:66-75](), [docs/data_analysis/package_reference/index.md:187-196]()
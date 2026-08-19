# Page: Study Methodologies

# Study Methodologies

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/standard_studies/index.md](docs/data_analysis/standard_studies/index.md)
- [personas/david.md](personas/david.md)
- [personas/martina.md](personas/martina.md)
- [personas/montse.md](personas/montse.md)
- [personas/patrick.md](personas/patrick.md)

</details>



This document provides an overview of standardized study methodologies for observational health data research using the OMOP CDM. It covers the conceptual framework, workflow patterns, and methodological approaches that underpin all analytical studies in this ecosystem. For detailed implementation guides of specific study types, see [Standard Study Types](#4.1). For executable code examples and templates, see [Study Templates and Examples](#4.2).

## Standardized Analytics Framework

The OMOP analytics ecosystem employs a standardized analytics approach based on the DARWIN EU® methodology. This framework emphasizes sending validated analytical code packages rather than study protocols, ensuring that differences in results reflect data characteristics rather than implementation variations.

The standardized approach provides several key benefits:
- **Reproducibility**: Identical analytical code across all data partners
- **Transparency**: Open-source, peer-reviewed methodologies  
- **Speed**: Rapid deployment without site-specific implementation
- **Quality**: Validated statistical methods and data quality checks

```mermaid
graph TB
    subgraph "Clinical Question"
        QUESTION["Research Question"]
        PROTOCOL["Study Protocol"]
    end
    
    subgraph "Standardized Implementation"
        CODE["Validated R Code Package"]
        METHOD["Standard Methodology"]
        QA["Quality Assurance"]
    end
    
    subgraph "Data Partners"
        SITE1["Site 1<br/>OMOP CDM"]
        SITE2["Site 2<br/>OMOP CDM"]  
        SITE3["Site N<br/>OMOP CDM"]
    end
    
    subgraph "Results"
        RESULTS1["Results 1"]
        RESULTS2["Results 2"]
        RESULTS3["Results N"]
        META["Meta-Analysis"]
    end
    
    QUESTION --> PROTOCOL
    PROTOCOL --> METHOD
    METHOD --> CODE
    CODE --> QA
    
    QA --> SITE1
    QA --> SITE2
    QA --> SITE3
    
    SITE1 --> RESULTS1
    SITE2 --> RESULTS2
    SITE3 --> RESULTS3
    
    RESULTS1 --> META
    RESULTS2 --> META
    RESULTS3 --> META
```

Sources: [docs/data_analysis/standard_studies/index.md:9-25]()

## Study Methodology Workflow

All observational studies in the OMOP ecosystem follow a standardized analytical workflow that progresses through distinct phases, each supported by specific R packages and methodological frameworks.

```mermaid
graph TD
    subgraph "Environment Setup"
        RENV["renv<br/>Package Management"]
        CDM_CONN["CDMConnector<br/>Database Connection"]
        OMOCK["omock<br/>Mock Data Testing"]
    end
    
    subgraph "Data Preparation"
        SKETCH["OmopSketch<br/>Database Profiling"]
        DQD["DataQualityDashboard<br/>Quality Assessment"]
        CONCEPTS["CodelistGenerator<br/>Concept Set Definition"]
    end
    
    subgraph "Cohort Definition"
        CONSTRUCTOR["CohortConstructor<br/>Population Definition"]
        PROFILES["PatientProfiles<br/>Feature Engineering"]
        PHENOTYPE["PhenotypeR<br/>Cohort Validation"]
    end
    
    subgraph "Study Execution"
        CHARS["CohortCharacteristics<br/>Table 1 Generation"]
        INCPREV["IncidencePrevalence<br/>Epidemiological Rates"]
        DRUGUTIL["DrugUtilisation<br/>Medication Patterns"]
        SURVIVAL["CohortSurvival<br/>Time-to-Event"]
        PLP["PatientLevelPrediction<br/>Risk Models"]
    end
    
    subgraph "Results & Reporting"
        VISOMOP["visOmopResults<br/>Standardized Visualization"]
        REPORTS["R Markdown Reports"]
        SHARING["Results Sharing"]
    end
    
    RENV --> CDM_CONN
    CDM_CONN --> SKETCH
    OMOCK --> CDM_CONN
    SKETCH --> DQD
    DQD --> CONCEPTS
    CONCEPTS --> CONSTRUCTOR
    CONSTRUCTOR --> PROFILES
    PROFILES --> PHENOTYPE
    
    PHENOTYPE --> CHARS
    PHENOTYPE --> INCPREV
    PHENOTYPE --> DRUGUTIL
    PHENOTYPE --> SURVIVAL
    PHENOTYPE --> PLP
    
    CHARS --> VISOMOP
    INCPREV --> VISOMOP
    DRUGUTIL --> VISOMOP
    SURVIVAL --> VISOMOP
    PLP --> VISOMOP
    
    VISOMOP --> REPORTS
    REPORTS --> SHARING
```

Sources: [docs/data_analysis/standard_studies/index.md:35-51]()

## Study Type Taxonomy

The framework encompasses eight standardized study types, each addressing specific research questions and employing distinct methodological approaches. Each study type is supported by specialized R packages within the OHDSI ecosystem.

| Study Type | Primary Packages | Clinical Questions |
|------------|------------------|-------------------|
| **Population-Level Epidemiology** | `IncidencePrevalence` | Disease frequency, trends over time |
| **Patient-Level Characterisation** | `CohortCharacteristics`, `PatientProfiles` | Baseline demographics, comorbidities |
| **Drug Utilisation Studies** | `DrugUtilisation` | Medication usage patterns, indications |
| **Comparative Cohort Studies** | `CohortConstructor`, `CohortSurvival` | Treatment effectiveness, safety comparison |
| **Self-Controlled Designs** | `SelfControlledCaseSeries` | Acute event risk assessment |
| **Patient-Level Prediction** | `PatientLevelPrediction` | Individual risk stratification |
| **Treatment Pathway Analysis** | `TreatmentPatterns` | Patient journey mapping |
| **Impact Evaluation Studies** | `CohortMethod`, `EvidenceSynthesis` | Policy/intervention impact assessment |

```mermaid
graph LR
    subgraph "Descriptive Studies"
        PLC["Patient-Level<br/>Characterisation<br/><br/>CohortCharacteristics<br/>PatientProfiles"]
        PLE["Population-Level<br/>Epidemiology<br/><br/>IncidencePrevalence"]
        DUS["Drug Utilisation<br/>Studies<br/><br/>DrugUtilisation"]
        PATHWAY["Treatment Pathway<br/>Analysis<br/><br/>TreatmentPatterns"]
    end
    
    subgraph "Analytical Studies"
        COHORT["Comparative Cohort<br/>Studies<br/><br/>CohortConstructor<br/>CohortSurvival"]
        SCCS["Self-Controlled<br/>Designs<br/><br/>SelfControlledCaseSeries"]
        IMPACT["Impact Evaluation<br/>Studies<br/><br/>CohortMethod<br/>EvidenceSynthesis"]
    end
    
    subgraph "Predictive Studies"
        PLP["Patient-Level<br/>Prediction<br/><br/>PatientLevelPrediction"]
    end
    
    subgraph "Supporting Infrastructure"
        CONSTRUCTOR["CohortConstructor<br/>Population Definition"]
        CODELIST["CodelistGenerator<br/>Concept Management"]
        VISOMOP["visOmopResults<br/>Visualization"]
    end
    
    CONSTRUCTOR --> PLC
    CONSTRUCTOR --> PLE
    CONSTRUCTOR --> DUS
    CONSTRUCTOR --> COHORT
    CONSTRUCTOR --> SCCS
    CONSTRUCTOR --> PLP
    CONSTRUCTOR --> PATHWAY
    CONSTRUCTOR --> IMPACT
    
    CODELIST --> CONSTRUCTOR
    
    PLC --> VISOMOP
    PLE --> VISOMOP
    DUS --> VISOMOP
    COHORT --> VISOMOP
    SCCS --> VISOMOP
    PLP --> VISOMOP
    PATHWAY --> VISOMOP
    IMPACT --> VISOMOP
```

Sources: [docs/data_analysis/standard_studies/index.md:41-51]()

## Methodological Considerations

### Cohort Definition Strategy

All study types begin with precise cohort definition using `CohortConstructor`. The package provides a systematic approach to population identification:

- **Index Event**: The qualifying event that marks cohort entry
- **Inclusion Criteria**: Additional requirements for cohort membership  
- **Exclusion Criteria**: Conditions that disqualify individuals
- **Washout Periods**: Time windows to ensure new user status
- **Observation Requirements**: Minimum follow-up time specifications

### Temporal Framework

Studies employ standardized temporal concepts to ensure consistent time-based analyses:

- **Index Date**: The reference date for each individual in the cohort
- **Baseline Period**: Pre-index period for covariate assessment
- **Follow-up Period**: Post-index period for outcome assessment
- **Washout Period**: Gap period to identify treatment-naive individuals
- **Grace Period**: Allowable gaps in continuous exposure

### Statistical Methodology

The framework emphasizes robust statistical practices:

- **Multiple Testing Correction**: Appropriate adjustment for multiple comparisons
- **Confounding Control**: Systematic identification and adjustment for confounders
- **Sensitivity Analyses**: Testing robustness of findings under different assumptions
- **Missing Data Handling**: Explicit strategies for incomplete data
- **Effect Size Interpretation**: Clinical significance alongside statistical significance

## Integration with OMOP Analytics Framework  

Study methodologies are tightly integrated with the broader OMOP analytics ecosystem, leveraging standardized data structures and analytical patterns consistent across all implementations.

```mermaid
graph TB
    subgraph "OMOP CDM Data Layer"
        PERSON["person"]
        OBSERVATION["observation_period"]
        CONDITION["condition_occurrence"]
        DRUG["drug_exposure"]
        MEASUREMENT["measurement"]
        VISIT["visit_occurrence"]
    end
    
    subgraph "Analytical Layer"
        COHORT_TABLE["cohort table"]
        RESULT_TABLE["result table"] 
        SUMMARY_TABLE["summarised_result"]
    end
    
    subgraph "Study Implementation"
        STUDY_FUNC["Study Function<br/>e.g. summariseCharacteristics()"]
        RESULT_OBJ["Result Object<br/>summarised_result class"]
        VIS_FUNC["Visualization Function<br/>e.g. tableCharacteristics()"]
    end
    
    PERSON --> COHORT_TABLE
    OBSERVATION --> COHORT_TABLE
    CONDITION --> COHORT_TABLE
    DRUG --> COHORT_TABLE
    MEASUREMENT --> COHORT_TABLE
    VISIT --> COHORT_TABLE
    
    COHORT_TABLE --> STUDY_FUNC
    STUDY_FUNC --> RESULT_OBJ
    RESULT_OBJ --> RESULT_TABLE
    RESULT_TABLE --> SUMMARY_TABLE
    SUMMARY_TABLE --> VIS_FUNC
```

The standardized result format (`summarised_result`) ensures that all study types produce consistent output structures that can be processed by `visOmopResults` for visualization and reporting.

Sources: [docs/data_analysis/standard_studies/index.md:18-32]()
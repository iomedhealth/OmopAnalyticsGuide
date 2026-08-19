# Page: Standard Study Types

# Standard Study Types

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/standard_studies/comparative_cohort.md](docs/data_analysis/standard_studies/comparative_cohort.md)
- [docs/data_analysis/standard_studies/drug_utilisation.md](docs/data_analysis/standard_studies/drug_utilisation.md)
- [docs/data_analysis/standard_studies/impact_evaluation.md](docs/data_analysis/standard_studies/impact_evaluation.md)
- [docs/data_analysis/standard_studies/patient_level_prediction.md](docs/data_analysis/standard_studies/patient_level_prediction.md)
- [docs/data_analysis/standard_studies/population_level_epidemiology.md](docs/data_analysis/standard_studies/population_level_epidemiology.md)
- [docs/data_analysis/standard_studies/self_controlled_designs.md](docs/data_analysis/standard_studies/self_controlled_designs.md)
- [docs/data_analysis/standard_studies/treatment_pathway_analysis.md](docs/data_analysis/standard_studies/treatment_pathway_analysis.md)

</details>



This document provides a comprehensive catalog of the eight standardized study methodologies supported by the OMOP Analytics Framework. Each study type represents a distinct analytical approach designed to answer specific research questions using observational health data. For detailed implementation guides and code examples, see [Study Templates and Examples](#4.2). For specific methodology deep-dives, see [Patient-Level Characterisation](#4.3) and [Population-Level Epidemiology](#4.4).

## Study Type Taxonomy

The eight standard study types can be classified into four primary analytical categories based on their methodological approach and research objectives:

```mermaid
graph TD
    subgraph "Descriptive Studies"
        PLC["Patient-Level<br/>Characterisation"]
        PLE["Population-Level<br/>Epidemiology"]
        DUS["Drug Utilisation<br/>Studies"]
        TPA["Treatment Pathway<br/>Analysis"]
    end
    
    subgraph "Comparative Studies"
        CCS["Comparative Cohort<br/>Studies"]
        SCD["Self-Controlled<br/>Designs"]
    end
    
    subgraph "Predictive Studies"
        PLP["Patient-Level<br/>Prediction"]
    end
    
    subgraph "Policy Studies"
        IES["Impact Evaluation<br/>Studies"]
    end
    
    PLC -.->|"Baseline for"| CCS
    PLE -.->|"Context for"| DUS
    DUS -.->|"Sequences in"| TPA
    CCS -.->|"Features for"| PLP
    PLE -.->|"Trends for"| IES
```

Sources: [docs/data_analysis/standard_studies/population_level_epidemiology.md:1-52](), [docs/data_analysis/standard_studies/self_controlled_designs.md:1-52](), [docs/data_analysis/standard_studies/patient_level_prediction.md:1-67](), [docs/data_analysis/standard_studies/treatment_pathway_analysis.md:1-67](), [docs/data_analysis/standard_studies/drug_utilisation.md:1-67](), [docs/data_analysis/standard_studies/impact_evaluation.md:1-65](), [docs/data_analysis/standard_studies/comparative_cohort.md:1-67]()

## Complete Study Type Catalog

| Study Type | Primary Question | Design | Key Outputs | Typical Use Cases |
|------------|------------------|--------|-------------|-------------------|
| **Patient-Level Characterisation** | What are the baseline characteristics of this population? | Descriptive cross-sectional | Table 1 demographics, comorbidities | Study population description, feasibility assessment |
| **Population-Level Epidemiology** | How common is this condition in the population? | Population cohort | Incidence rates, prevalence proportions | Disease burden assessment, public health surveillance |
| **Drug Utilisation Studies** | How are medications used in real-world practice? | Descriptive cohort | Usage patterns, persistence, adherence | Real-world prescribing patterns, market research |
| **Treatment Pathway Analysis** | What is the typical sequence of treatments? | Sequential events mapping | Sankey diagrams, transition probabilities | Care pathway optimization, guideline adherence |
| **Comparative Cohort Studies** | Is Treatment A safer/more effective than B? | Comparative cohort with propensity matching | Hazard ratios, risk differences | Comparative effectiveness, safety surveillance |
| **Self-Controlled Designs** | Does exposure increase acute risk within individuals? | Case series with exposure windows | Incidence rate ratios | Vaccine safety, acute drug reactions |
| **Patient-Level Prediction** | Who is at highest risk for this outcome? | Machine learning prognostic model | Risk scores, AUC, calibration plots | Clinical decision support, risk stratification |
| **Impact Evaluation Studies** | Did this policy/intervention change population outcomes? | Quasi-experimental time series | Trend changes, effect sizes | Policy evaluation, regulatory impact assessment |

Sources: [docs/data_analysis/standard_studies/population_level_epidemiology.md:10-18](), [docs/data_analysis/standard_studies/self_controlled_designs.md:10-16](), [docs/data_analysis/standard_studies/patient_level_prediction.md:10-16](), [docs/data_analysis/standard_studies/treatment_pathway_analysis.md:10-22](), [docs/data_analysis/standard_studies/drug_utilisation.md:10-22](), [docs/data_analysis/standard_studies/impact_evaluation.md:10-18](), [docs/data_analysis/standard_studies/comparative_cohort.md:10-17]()

## R Package Implementation Mapping

Each study type is implemented using specific R packages from the OMOP analytics ecosystem:

```mermaid
graph LR
    subgraph "Study Types"
        PLC_STUDY["Patient-Level<br/>Characterisation"]
        PLE_STUDY["Population-Level<br/>Epidemiology"]
        DUS_STUDY["Drug Utilisation<br/>Studies"]
        TPA_STUDY["Treatment Pathway<br/>Analysis"]
        CCS_STUDY["Comparative Cohort<br/>Studies"]
        SCD_STUDY["Self-Controlled<br/>Designs"]
        PLP_STUDY["Patient-Level<br/>Prediction"]
        IES_STUDY["Impact Evaluation<br/>Studies"]
    end
    
    subgraph "R Packages"
        CC["CohortCharacteristics"]
        IP["IncidencePrevalence"]
        DU["DrugUtilisation"]
        TP["TreatmentPatterns"]
        CS["CohortSurvival"]
        SCCS["SelfControlledCaseSeries"]
        PLP_PKG["PatientLevelPrediction"]
        ITS["InterruptedTimeSeries"]
        PP["PatientProfiles"]
        VIS["visOmopResults"]
    end
    
    PLC_STUDY --> CC
    PLC_STUDY --> PP
    PLE_STUDY --> IP
    DUS_STUDY --> DU
    TPA_STUDY --> TP
    CCS_STUDY --> CS
    CCS_STUDY --> PP
    SCD_STUDY --> SCCS
    PLP_STUDY --> PLP_PKG
    IES_STUDY --> ITS
    
    CC --> VIS
    IP --> VIS
    DU --> VIS
    CS --> VIS
    PLP_PKG --> VIS
```

Sources: [docs/data_analysis/standard_studies/population_level_epidemiology.md:51](), [docs/data_analysis/standard_studies/drug_utilisation.md:64-66](), [docs/data_analysis/standard_studies/comparative_cohort.md:64-66](), [docs/data_analysis/standard_studies/patient_level_prediction.md:54-62]()

## Study Design Components

Each study type follows a standardized structure with five core components:

### Methodological Framework

```mermaid
graph TD
    subgraph "Study Design Components"
        PARTICIPANTS["Participants<br/>Target population definition"]
        EXPOSURES["Exposures/Predictors<br/>Variables of interest"]
        OUTCOMES["Outcomes<br/>Events to measure"]
        FOLLOWUP["Follow-up Period<br/>Observation windows"]
        ANALYSES["Analyses<br/>Statistical methods"]
    end
    
    subgraph "Common Patterns"
        NEW_USER["New User Design<br/>washout period required"]
        COHORT_INDEX["Cohort Index Date<br/>time zero definition"]
        BASELINE_CHAR["Baseline Characterisation<br/>confounding control"]
        TIME_TO_EVENT["Time-to-Event<br/>survival analysis"]
    end
    
    PARTICIPANTS --> NEW_USER
    EXPOSURES --> COHORT_INDEX
    OUTCOMES --> TIME_TO_EVENT
    FOLLOWUP --> COHORT_INDEX
    ANALYSES --> BASELINE_CHAR
    
    NEW_USER -.->|"Used in"| CCS_PATTERN["Comparative Cohort"]
    NEW_USER -.->|"Used in"| DUS_PATTERN["Drug Utilisation"]
    COHORT_INDEX -.->|"Required for"| ALL_STUDIES["All Study Types"]
    TIME_TO_EVENT -.->|"Used in"| CCS_PATTERN
    TIME_TO_EVENT -.->|"Used in"| SCD_PATTERN["Self-Controlled"]
```

Sources: [docs/data_analysis/standard_studies/comparative_cohort.md:29-31](), [docs/data_analysis/standard_studies/drug_utilisation.md:30-34](), [docs/data_analysis/standard_studies/self_controlled_designs.md:36-42]()

## Study Selection Decision Framework

The choice of study type depends on the research question structure and available data:

| Research Question Pattern | Recommended Study Type | Key Considerations |
|---------------------------|------------------------|-------------------|
| "What are the characteristics of patients with...?" | Patient-Level Characterisation | Descriptive only, no comparisons |
| "How common is condition X?" | Population-Level Epidemiology | Requires whole population denominator |
| "How do patients use drug Y?" | Drug Utilisation Studies | Focus on medication patterns |
| "What treatments follow drug Z?" | Treatment Pathway Analysis | Sequential event analysis |
| "Is drug A safer than drug B?" | Comparative Cohort Studies | Requires active comparator |
| "Does vaccine C cause event D?" | Self-Controlled Designs | Acute events, individual as own control |
| "Who will develop outcome E?" | Patient-Level Prediction | Requires machine learning infrastructure |
| "Did policy F change outcomes?" | Impact Evaluation Studies | Requires pre/post intervention periods |

### Template File Structure

Study implementations are organized in the codebase as R Markdown templates:

```mermaid
graph TD
    subgraph "StandardStudies Directory"
        RMD_DIR["StandardStudies/rmd/"]
        
        subgraph "Study Templates"
            PLC_RMD["patient_level_characterisation.Rmd"]
            PLE_RMD["population_level_epidemiology.Rmd"]
            DUS_RMD["drug_utilisation.Rmd"]
            TPA_RMD["treatment_pathway_analysis.Rmd"]
            CCS_RMD["comparative_cohort.Rmd"]
            SCD_RMD["self_controlled_designs.Rmd"]
            PLP_RMD["patient_level_prediction.Rmd"]
            IES_RMD["impact_evaluation.Rmd"]
        end
        
        subgraph "Generated Output"
            INCLUDES_DIR["_includes/rmd_output/"]
            MD_FILES["*.md processed files"]
        end
    end
    
    RMD_DIR --> PLC_RMD
    RMD_DIR --> PLE_RMD
    RMD_DIR --> DUS_RMD
    RMD_DIR --> TPA_RMD
    RMD_DIR --> CCS_RMD
    RMD_DIR --> SCD_RMD
    RMD_DIR --> PLP_RMD
    RMD_DIR --> IES_RMD
    
    PLC_RMD --> INCLUDES_DIR
    PLE_RMD --> INCLUDES_DIR
    DUS_RMD --> INCLUDES_DIR
    TPA_RMD --> INCLUDES_DIR
    CCS_RMD --> INCLUDES_DIR
    SCD_RMD --> INCLUDES_DIR
    PLP_RMD --> INCLUDES_DIR
    IES_RMD --> INCLUDES_DIR
    
    INCLUDES_DIR --> MD_FILES
```

Sources: [docs/data_analysis/standard_studies/population_level_epidemiology.md:51]()
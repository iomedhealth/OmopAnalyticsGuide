---

layout: default
title: Data Analysis
nav_order: 3
has_children: true

---

# Executing an Observational Study
{: .no_toc }

Observational studies using real-world data (RWD) are essential for understanding disease, treatment effectiveness, and patient outcomes. The OMOP Common Data Model (CDM) provides a global standard for structuring this data, enabling transparent and reproducible research.

To harness the power of the OMOP CDM, a suite of specialized R packages has been developed. These packages provide a robust, modular framework for every stage of a study. Using this standardized toolkit ensures that research is not only efficient but also adheres to the highest scientific standards, as promoted by regulatory bodies like the European Medicines Agency (EMA) through initiatives such as DARWIN EU.

This section is divided into four key guides to help you navigate this ecosystem:

1.  **The Conceptual Guide (The "Why"):** If you are new to the OMOP CDM or want to understand the core principles of how clinical ideas are translated into computable definitions, start here. This guide is for researchers, epidemiologists, and anyone who wants to understand the methodology before diving into the code.
    -   Start with the: [Introductory Guide to Observational Research](./intro_to_observational_research)

2.  **The Practical Guide (The "How"):** If you are ready to start writing code and want a step-by-step walkthrough of a typical analysis workflow, from connecting to the database to generating final results, this guide is for you. It provides the practical sequence of operations for executing a study.
    -   Follow the guide to: [Performing an Analysis](./performing_analysis)

3.  **The Tool Reference (The "What"):** This guide provides a comprehensive overview of the available R packages, categorized by their purpose. It explains what each tool does and is the perfect place to go when you know the type of analysis you need (e.g., "survival analysis") and want to find the right package for the job.
    -   Explore the: [Package Reference](./package_reference)

4.  **The Study Templates (The "How To"):** This section contains complete, executable examples of different types of observational studies (e.g., a cohort characterization, an incidence/prevalence study). These templates serve as a practical starting point and can be adapted for your own research questions.
    -   Adapt from the: [Catalogue of Standard Studies](./standard_studies)

## Package Categories and Purposes

Below is a categorized list of the core R packages you will use.

### Foundation Layer
These are the core packages that establish the connection to the database and
provide the basic infrastructure for all other operations.

| Library | Purpose |
| :--- | :--- |
| [**`omopgenerics`**](https://darwin-eu.github.io/omopgenerics/) | Provides a common set of classes and methods to ensure interoperability between different OHDSI packages. |
| [**`CDMConnector`**](https://darwin-eu.github.io/CDMConnector/) | Establishes and manages the connection to an OMOP CDM database, creating the `cdm` object. |
| [**`omock`**](https://ohdsi.github.io/omock/) | A utility for creating mock `cdm` objects for testing and development purposes. |

### Cohort Generation & Infrastructure Layer
These packages are used to define, construct, and manage patient populations (cohorts) and CDM tables that form the basis of any study.

| Library | Purpose |
| :--- | :--- |
| [**`CodelistGenerator`**](https://darwin-eu.github.io/CodelistGenerator/) | Creates codelists (sets of medical codes) from OMOP concept sets. |
| [**`CohortConstructor`**](https://ohdsi.github.io/CohortConstructor/) | Builds patient cohorts from codelists and other criteria, such as temporal windows or intersections with other cohorts. |
| [**`OmopConstructor`**](https://ohdsi.github.io/OmopConstructor/) | Constructs and recalculates standardized OMOP CDM tables (e.g. `observation_period`). |

### Analysis Layer
This layer contains packages that perform specific types of epidemiological,
characterization, or health economic analyses on the generated cohorts.

| Library | Purpose |
| :--- | :--- |
| [**`CohortCharacteristics`**](https://darwin-eu.github.io/CohortCharacteristics/) | Summarizes the baseline characteristics of a cohort, including demographics, comorbidities, and other features. |
| [**`IncidencePrevalence`**](https://darwin-eu.github.io/IncidencePrevalence/) | Calculates the incidence and prevalence of health outcomes within a study population. |
| [**`EpiStandard`**](https://oxford-pharmacoepi.github.io/EpiStandard/) | Directly standardizes epidemiological incidence and prevalence rates across age and reference populations. |
| [**`DrugUtilisation`**](https://darwin-eu.github.io/DrugUtilisation/) | Analyzes patterns of drug use, such as treatment pathways and adherence. |
| [**`CohortSurvival`**](https://darwin-eu-dev.github.io/CohortSurvival/) | Performs time-to-event (survival) analysis to estimate the risk of outcomes over time. |
| [**`CohortSymmetry`**](https://ohdsi.github.io/CohortSymmetry/) | Conducts Sequence Symmetry Analysis (SSA) for safety screening and adverse event signal detection. |
| [**`PatientProfiles`**](https://darwin-eu.github.io/PatientProfiles/) | Adds detailed demographic and clinical features to patient cohorts for in-depth characterization. |
| [**`CohortUtilisation`**](https://github.com/iomedhealth/omopHeor/tree/main/packages/CohortUtilisation) | Extracts in-database Healthcare Resource Utilization (HCRU) metrics across inpatient, outpatient, emergency, prescription, and procedure domains. |
| [**`CohortCosts`**](https://github.com/iomedhealth/omopHeor/tree/main/packages/CohortCosts) | Links polymorphic OMOP COST records to clinical events and tracks direct medical expenditures. |
| [**`CohortEconomics`**](https://github.com/iomedhealth/omopHeor/tree/main/packages/CohortEconomics) | Provides an end-to-end framework for causal propensity score adjustment, Markov state-transition modeling, and Cost-Effectiveness Analysis (CEA). |
| [**`OmopSketch`**](https://ohdsi.github.io/OmopSketch/) | Provides a quick summary or "sketch" of the data in an OMOP CDM instance. |

### Validation & Diagnostics Layer
This layer is focused on quality control, measurement consistency, and ensuring the clinical validity of
the cohort definitions.

| Library | Purpose |
| :--- | :--- |
| [**`PhenotypeR`**](https://ohdsi.github.io/PhenotypeR/) | Provides a comprehensive suite of diagnostics to evaluate and validate the quality of clinical phenotype definitions. |
| [**`MeasurementDiagnostics`**](https://ohdsi.github.io/MeasurementDiagnostics/) | Assesses the quality, recording volume, numeric distributions, and categorical encodings of laboratory measurements and vital signs. |

### Visualization & Reporting Layer
These packages are used to generate the final outputs of a study, including
tables, figures, and interactive applications.

| Library | Purpose |
| :--- | :--- |
| [**`visOmopResults`**](https://darwin-eu.github.io/visOmopResults/) | Creates standardized visualizations and tables from the results of other OHDSI packages. |
| [**`OmopViewer`**](https://ohdsi.github.io/OmopViewer/) | Automatically exports interactive Shiny dashboard applications to explore and share `<summarised_result>` study outputs. |
| [**`ggplot2`**](https://ggplot2.tidyverse.org/) | A general-purpose and highly flexible plotting library used for creating custom visualizations. |

For a detailed, step-by-step guide on performing an observational study analysis, see [Performing an Analysis](./performing_analysis).

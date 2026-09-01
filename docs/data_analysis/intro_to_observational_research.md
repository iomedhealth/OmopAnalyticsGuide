---

layout: default
title: Introductory Guide
parent: Data Analysis
nav_order: 2

---

# Introductory Guide
{: .no_toc}


Welcome. If you have years of experience designing and running clinical studies, you are in the right place. Your expertise in protocols, patient populations, and clinical endpoints is the perfect foundation for the world of observational health research.

This guide is designed to bridge the gap between your deep clinical and statistical knowledge and a powerful new toolset for analyzing real-world data: the OMOP Common Data Model and the R programming language. We will introduce new concepts gradually, always connecting them back to the principles of high-quality clinical research you already know.

Think of this as a new, powerful extension of your existing toolkit—one that allows you to ask research questions at a scale and speed previously unimaginable.

1. TOC
{:toc}


## 1. The "Why" - Introducing the OMOP Common Data Model

In your work, you know the immense value of clean, structured, and standardized data, as is typical in clinical trials. However, the data generated during routine healthcare—from Electronic Health Records (EHRs), insurance claims, and patient registries—is often messy and stored in thousands of different formats across the globe. This fragmentation makes it incredibly difficult to conduct large-scale, reproducible research.

**This is the problem the OMOP Common Data Model (CDM) solves.**

OMOP is a universal standard, or a "common language," for structuring healthcare data. By transforming diverse datasets into this single, consistent format, OMOP allows us to:

1.  **Ask the Same Question Everywhere:** Run a single analysis script across multiple databases from different hospitals or countries and get comparable, meaningful results.
2.  **Ensure Transparency:** The entire process, from raw data to final result, is documented and clear.
3.  **Promote Reproducible Science:** Anyone can take the same analysis script and reproduce the results, a cornerstone of good scientific practice.

Regulatory bodies like the European Medicines Agency (EMA) are increasingly promoting the use of standardized, real-world data through initiatives like DARWIN EU. By learning to work with the OMOP CDM, you are aligning with the future of evidence generation.



## 2. The "What" - How OMOP Organizes Information

So, how does OMOP create this "common language"? The core mechanism is simple but powerful: the **`concept_id`**.

In the world of healthcare data, there are many different coding systems (terminologies) for the same clinical idea. A diagnosis of "Type 2 diabetes mellitus" might be coded as:

*   `E11.9` in ICD-10-CM
*   `44054006` in SNOMED-CT
*   `250.00` in ICD-9-CM

This creates a major barrier to analysis. The OMOP solution is to map all of these different codes to a single, standard **`concept_id`**.

| Original Code | Terminology | Clinical Idea | Standard OMOP Concept ID |
| : | : | : | : |
| `E11.9` | ICD-10-CM | Type 2 diabetes | **201826** |
| `44054006` | SNOMED-CT | Type 2 diabetes | **201826** |
| `250.00` | ICD-9-CM | Type 2 diabetes | **201826** |

**Analogy: A Universal Translator**

Think of `concept_ids` as a universal translator for clinical terms. While the source "languages" (SNOMED, ICD-10) are different, OMOP provides a single, standard identifier for every diagnosis, drug, procedure, and lab test. This meta-ontology is the engine that makes large-scale, standardized analysis possible.

### The OMOP Data Model: Clinical "Domains"

Standardizing the terminology is only half the story. OMOP also organizes the data into a logical, consistent structure of tables. This is very similar to the **domain model in CDISC SDTM**, where different types of data are stored in specific datasets (e.g., Demographics in `DM`, Adverse Events in `AE`, Labs in `LB`).

In OMOP, these "domains" are represented by a set of standardized tables. While there are many tables in the full model, the most important ones for clinical analysis are:

*   **`PERSON`**: Contains the core demographic information for each patient. (Analogous to `DM` in SDTM).
*   **`OBSERVATION_PERIOD`**: Defines the time periods for which a patient has observable data in the source. This is a critical table for defining study windows.
*   **`CONDITION_OCCURRENCE`**: Records all patient diagnoses, signs, and symptoms. (Analogous to a combination of `MH` and `AE` in SDTM).
*   **`DRUG_EXPOSURE`**: Records all exposures to medications. (Analogous to `CM` and `EX` in SDTM).
*   **`MEASUREMENT`**: Contains all lab results, vital signs, and other quantitative measurements. (Analogous to `LB` and `VS` in SDTM).
*   **`PROCEDURE_OCCURRENCE`**: Records all medical procedures performed on a patient. (Analogous to `PR` in SDTM).

By combining a standardized terminology (`concept_id`s) with a standardized structure (the table model), the OMOP CDM ensures that you can find the same type of data in the same place, coded in the same way, no matter which hospital or country the data comes from.



## 3. The "Where" - Your Study in the IOMED Data Space Platform

Now, let's ground these abstract concepts in your specific, practical reality. The IOMED Data Space provides a secure, compliant environment for you to conduct your research. Depending on the Data Solution you have requested for your study, your interaction with the data will take one of two primary forms:

1.  **Federated Analysis (for Aggregated Patient Characterisation):** For many studies, you will not receive patient-level data directly. Instead, you will be given access to run a pre-defined, validated R analysis script against the data within the secure environment of each data holder. The script executes locally at each site, and only the final, aggregated results (e.g., summary statistics, counts) are returned to you. This is a high-security model that minimizes data movement.
2.  **Patient-Level Data Analysis:** For studies requiring more complex modeling, you will receive a single, ready-to-analyze **`duckdb` file**. This is a self-contained, high-performance database file containing the fully anonymized, patient-level data for your specific cohort.

In both scenarios, the underlying data has been cleaned and standardized to the OMOP CDM, and you will work with **`concept_sets`** to define your clinical variables.

A **`concept_set`** is simply a pre-packaged, clinically validated list of all the `concept_id`s that represent a single clinical idea. For example, a `concept_set` for "Anticoagulants" would contain the standard `concept_id`s for warfarin, apixaban, rivaroxaban, and all other relevant medications.

This is a critical accelerator for your research. You don't have to become an expert in OMOP terminologies; you can start immediately with clinically meaningful, pre-built variable definitions.

### The Concept Set Lifecycle: From Idea to Reusable Asset

You might be wondering how these `concept_sets` are created and how you can trust them. They are not created in isolation; they go through a rigorous, collaborative lifecycle designed to ensure they are clinically valid, transparent, and reusable.

1.  **Creation in the IOMED Data Space Platform:** A researcher, often a clinician or an epidemiologist, uses tools within the platform to build a new `concept_set`. This involves searching the OMOP vocabulary for relevant terms (e.g., searching for all variations of "Type 2 Diabetes Mellitus," including synonyms and related codes) and compiling them into a list.
2.  **Clinical Review and Validation:** The proposed `concept_set` is then reviewed by a team of clinical experts. They assess the list for completeness and accuracy, ensuring that it correctly captures the intended clinical idea without including irrelevant terms. This is a formal review process, similar to a medical monitor reviewing a list of adverse events of special interest in a clinical trial.
3.  **Approval and Publication:** Once the `concept_set` is approved, it is published to a shared library within the IOMED Data Space Platform. Each `concept_set` is given a unique ID and is version-controlled, meaning any changes are tracked over time.
4.  **Discovery and Reuse:** As a researcher, you can browse this library of validated `concept_sets` by name, clinical domain, or keyword. This creates a living library of clinical knowledge, ensuring that the definition for a complex idea like "immunosuppression" is consistent and validated across all studies on the platform. The `getCodelistFromConceptSet(id = 123, ...)` function in the R script is how you programmatically access these published assets.



## 4. The "Who" - Defining Study Cohorts

In clinical research, your protocol always defines target patient populations using strict inclusion and exclusion criteria. In the OMOP CDM, this population is represented as a **Cohort**.

A **Cohort** is a set of persons who satisfy one or more inclusion criteria for a duration of time. Every record in an OMOP cohort table has four fundamental elements:

*   **`cohort_definition_id`**: An identifier distinguishing which cohort definition this record belongs to.
*   **`subject_id`**: The unique identifier of the patient (`person_id`).
*   **`cohort_start_date`**: The date the patient entered the cohort (often referred to as the **index date** or "time zero").
*   **`cohort_end_date`**: The date the patient ceased to meet the cohort criteria (e.g., treatment discontinuation, outcome occurrence, or loss to follow-up).

Using [`CohortConstructor`](https://ohdsi.github.io/CohortConstructor/), base cohorts are created from concept sets and then refined through inclusion/exclusion criteria such as demographic filters (age, sex), prior observation history, or temporal intersections with other clinical events.



## 5. The "How Well" - Characterising Populations (Table 1)

Once a study cohort is defined, the immediate next step is generating a baseline description of the population—the observational equivalent of **"Table 1"** in a clinical trial.

Baseline characterisation answers fundamental epidemiological questions:
*   What is the distribution of age, sex, and observation time at the index date?
*   What is the prevalence of co-existing medical conditions (comorbidities) during the historical baseline window (e.g., 365 days prior to index)?
*   What concomitant medications were patients taking around the start of therapy?

Packages like [`CohortCharacteristics`](https://darwin-eu.github.io/CohortCharacteristics/) and [`PatientProfiles`](https://darwin-eu.github.io/PatientProfiles/) compute these standardized summaries efficiently directly in the database, producing publication-ready tables via [`visOmopResults`](https://darwin-eu.github.io/visOmopResults/).



## 6. The "So What" - Quality, Attrition, and Validation

High-quality observational research requires absolute transparency about how the final study population was derived and whether the computable definitions truly capture the intended clinical condition.

*   **Attrition Tracking:** Every restriction applied during cohort construction is tracked step-by-step. Attrition tables and flowcharts record exactly how many subjects and records were excluded at each stage (e.g., excluding patients under 18 or those with less than 365 days of prior observation).
*   **Phenotype Diagnostics:** Tools like [`PhenotypeR`](https://ohdsi.github.io/PhenotypeR/) perform systematic clinical checks on the generated cohorts—inspecting concept code usage, temporal distributions, and subgroup characteristics—to confirm that the phenotype definition has high clinical fidelity.



## 7. The Path Forward - Performing Analysis

The steps we have walked through—defining variables, creating cohorts, and generating baseline characteristics—are the foundational activities of any observational study. They ensure you have the right population and have described it accurately.

From here, a whole ecosystem of specialized R packages is available to perform more advanced analyses, including:

*   [**`IncidencePrevalence`**](https://darwin-eu.github.io/IncidencePrevalence/): To calculate how often conditions occur.
*   [**`CohortSurvival`**](https://darwin-eu-dev.github.io/CohortSurvival/): To perform time-to-event (survival) analysis.
*   [**`DrugUtilisation`**](https://darwin-eu.github.io/DrugUtilisation/): To study patterns of medication use.
*   [**`CohortUtilisation`**](https://github.com/iomedhealth/omopHeor/tree/main/packages/CohortUtilisation) & [**`CohortCosts`**](https://github.com/iomedhealth/omopHeor/tree/main/packages/CohortCosts): To extract healthcare resource utilization (HCRU) and direct medical expenditures.
*   [**`CohortEconomics`**](https://github.com/iomedhealth/omopHeor/tree/main/packages/CohortEconomics): To perform causal propensity score modeling and cost-effectiveness analysis.

You now understand the complete workflow: from a clinical idea, to a standardized `concept_set`, to a study `cohort`, and finally to the tables and figures that will form the core of your research findings.

Welcome to the OMOP Community of RWE.

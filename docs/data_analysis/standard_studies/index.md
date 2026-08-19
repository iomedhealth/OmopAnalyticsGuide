---
layout: default
title: Standardised Analytics
parent: Data Analysis
nav_order: 3
has_children: true
---

# Standardised Analytics for RWE

In modern observational research, ensuring that studies are transparent,
reproducible, and rapidly executable is a significant challenge. The core
principle is simple yet powerful: instead of sending a study protocol to each
data partner to be independently implemented, a single, validated analytical
code package is sent. This eliminates variability in implementation, ensuring
that any differences in results are due to the data itself, not the code.

> "Standardised Analytics are needed to speed up evidence generation whilst preserving the quality, reproducibility, and transparency of the proposed research."
>
> — [DARWIN EU® Standardised Analytics][darwin]

This approach not only accelerates research timelines but also enhances the
consistency and reliability of the evidence produced, making it easier for
regulatory bodies and researchers to interpret and trust the findings.

## Our Goal: Democratising Access to Standardised Analytics

While the [DARWIN EU®][darwin] framework was developed for the [EMA], its principles and
tools are invaluable to the entire observational research community. Our goal
is to **democratise access to these powerful methodologies**. We aim to provide
clear, step-by-step guidance on how to execute these same standardised studies
using your own OMOP CDM data.


## Catalogue of Standard Data Analyses

Below, you will find links to detailed tutorials for each study type,
explaining the underlying concepts and providing executable code examples.


| Study Type | Clinical Context & Questions Answered |
| :--- | :--- |
| [**Population-Level Epidemiology**](./population_level_epidemiology) | Answers fundamental public health questions about a disease's frequency. It measures **Incidence** (how many new cases appear over a period) and **Prevalence** (how many people currently have the condition), often tracking these trends over time and across different demographic groups. |
| [**Patient-Level Characterisation**](./patient_level_characterisation) | Creates a detailed clinical profile or "Table 1" for a group of patients (a cohort). It answers: "Who are these patients?" by summarising their demographics, common co-existing diseases (comorbidities), and medication history, providing a crucial baseline understanding. |
| [**Drug Utilisation (DUS)**](./drug_utilisation) | Investigates how medicines are used in a real-world setting. It helps answer questions like: "How many people use a specific drug? For what medical reasons (indications) is it being prescribed? How long do patients typically remain on the treatment?" |
| [**Comparative Cohort Studies**](./comparative_cohort) | Compares the safety or effectiveness of two or more treatments, emulating a clinical trial using real-world data. It answers questions like: "Is Drug A associated with a higher risk of a side effect than Drug B?" |
| [**Self-Controlled Designs**](./self_controlled_designs) | Investigates the risk of an acute event immediately following a specific, short-term exposure (like a vaccination). Each person serves as their own control, comparing their risk during an "exposed" time window to their own risk during an "unexposed" window. |
| [**Patient-Level Prediction**](./patient_level_prediction) | Builds a "risk calculator" to predict an individual patient's probability of experiencing a future health outcome. Using machine learning, it answers: "Based on their clinical history, which patients are at the highest risk of developing a specific disease in the next year?" |
| [**Pathway Analysis**](./treatment_pathway_analysis) | Maps out the "patient journey" by visualizing the sequence of clinical events (treatments, procedures, or diagnoses) people experience over time. It answers questions like: "What is the most common first-line treatment for a disease, and what do patients typically switch to next?" |
| [**Impact Evaluation Studies**](./impact_evaluation) | Evaluates the real-world impact of large-scale interventions, such as new public health policies or regulatory actions. It answers: "Did the intervention cause a change in health outcomes or medication usage patterns at the population level?" using methods like Interrupted Time Series. |
| [**Health Economics & HCRU (HEOR / HTA)**](./heor_hcru_studies) | Evaluates healthcare resource utilisation (HCRU), direct medical expenditures from OMOP cost tables, and comparative cost-effectiveness (CEA/ICER/NMB) to support Health Technology Assessments (HTA) and value-based reimbursement decisions. |


[darwin]: https://www.darwin-eu.org/index.php/methods/standardised-analytics
[EMA]: https://www.ema.europa.eu/en/about-us/how-we-work/data-regulation-big-data-other-sources/real-world-evidence/data-analysis-real-world-interrogation-network-darwin-eu

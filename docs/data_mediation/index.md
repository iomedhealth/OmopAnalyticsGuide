---
layout: default
title: Data Mediation
nav_order: 3
has_children: true
---
# A Governed Process for Data Access

Data Mediation is the formal, governed process for providing researchers with access to standardized, research-ready clinical data. This process begins only after a hospital has completed the **[Data Enablement](./../data_enablement/index.md)** phase, which is a prerequisite for any data request.

The mediation process ensures that data is shared securely, ethically, and in compliance with all relevant regulations. It connects data holders (hospitals) with data users (researchers) through a structured, auditable workflow that should feel familiar to anyone experienced in clinical trial data management.

![](/assets/images/mediation.svg)

## The Mediation Workflow

The process is broken down into five distinct and auditable stages:

### 1. Mediation Request

A researcher initiates a study through the **IOMED Data Space Platform**, a secure graphical user interface (GUI). This platform guides the researcher through the formal request process, which is analogous to defining the data requirements in a clinical study protocol. The request includes:

*   **Protocol Submission:** The researcher uploads a formal study protocol outlining the scientific rationale, objectives, and methodology.
*   **Cohort Definition:** Using the platform's built-in tools, the researcher defines the patient population by specifying precise inclusion and exclusion criteria.
*   **Variable Selection (Concept Sets):** The researcher selects the specific clinical variables required for the analysis. These "concept sets" are created using libraries and facilities within the platform and are equivalent to defining the code lists (e.g., for adverse events or concomitant medications) in a clinical trial.
*   **Data Solution Selection:** The researcher selects the appropriate **[Data Solution](./data_solutions.md)** for their needs. Data Solutions are the different types of datasets that can be delivered, ranging from simple, aggregated patient counts for feasibility assessments to detailed, anonymized patient-level data for complex modeling.

### 2. Mediation Approval

Once submitted, the request enters a formal approval workflow managed within the Data Space Platform.

*   **Hospital-Led Governance:** The data holder (hospital) has full control over the approval process. Their designated approvers, often part of an ethics committee or a data governance board, review the entire request package.
*   **IOMED's Facilitation Role:** IOMED provides active support through the platform to streamline and accelerate the approval process. This includes ensuring the request is complete and clear, answering any technical questions the data holder may have, and facilitating communication between the two parties.

### 3. Data Validation and Quality Assurance

Once a request is approved, the dataset undergoes a rigorous, automated validation process. This is analogous to executing the Data Validation Plan (DVP) specified in a Statistical Analysis Plan (SAP). The goal is to provide a transparent, auditable, and interactive quality assessment before the data is delivered.

*   **Standardized Check Framework:** Our process is built on the industry-standard **OHDSI Data Quality Dashboard (DQD) framework**. This framework applies thousands of pre-defined, validated checks across three key categories:
    *   **Conformance:** Verifying that the data adheres to the OMOP CDM structure (e.g., correct data types, primary and foreign key integrity).
    *   **Completeness:** Checking for missing or null values in critical fields.
    *   **Plausibility:** Running clinical and temporal logic checks (e.g., ensuring a `drug_exposure_start_date` occurs before the `drug_exposure_end_date`, or that all events occur after a patient's birth date).

*   **Transparency and Incident Management:** The results of all QA checks are made fully visible to the researcher within the **IOMED Data Space Platform**. There is no static, black-box report. Instead, you have:
    *   **A Live Quality Dashboard:** Researchers can review the results of every check at the data point, patient, or data holder level.
    *   **Interactive Incident Management:** If the automated checks flag potential issues, or if the researcher discovers a potential issue during their own review, an incident can be raised directly within the platform. This creates a formal, auditable query and resolution process, similar to a data query management system in a clinical trial.

*   **Full Traceability:** While a separate formal report is not generated, the platform provides complete traceability. The results of all validation checks, any incidents raised, and their resolutions are permanently logged as part of the study's auditable record.

### 4. Compliance and Delivery

After the dataset passes the QA checks, a final compliance review is performed before delivery.

*   **Anonymization Verification:** An automated scan is run to confirm that the dataset is fully anonymized and contains no personally identifiable information.
*   **Secure Delivery:** The final dataset is delivered to the researcher through a secure, pre-defined method. Depending on the Data Solution selected, the deliverable is typically one of the following:
    *   **Aggregated Results:** For feasibility counts or characterization studies, the deliverable is often a set of summary tables, listings, and graphs (TLGs), similar to the output of a clinical study report.
    *   **Patient-Level Data:** For in-depth analysis, the deliverable is a database file (e.g., a DuckDB file[^1]) containing the fully anonymized, patient-level data in the OMOP CDM format.

### 5. Audit Trail

Every action taken within the Data Space Platform—from the initial submission of a request to the final delivery of the data—is logged, timestamped, and attributable to a specific user. This creates a comprehensive, immutable audit trail for the entire mediation process, ensuring full transparency and compliance with regulatory standards like GDPR.

---

[^1]: A DuckDB file is a modern, self-contained database file, similar to a portable SAS dataset, that allows for high-speed analysis on a local machine without needing a connection to a central database server.

# Page: Core Infrastructure Packages

# Core Infrastructure Packages

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/package_reference/cdmconnector.md](docs/data_analysis/package_reference/cdmconnector.md)
- [docs/data_analysis/package_reference/cohortconstructor.md](docs/data_analysis/package_reference/cohortconstructor.md)
- [docs/data_analysis/package_reference/omock.md](docs/data_analysis/package_reference/omock.md)
- [docs/data_analysis/package_reference/omopgenerics.md](docs/data_analysis/package_reference/omopgenerics.md)
- [docs/data_analysis/package_reference/omopsketch.md](docs/data_analysis/package_reference/omopsketch.md)

</details>



This document covers the four foundational packages that provide essential infrastructure for OMOP CDM data analysis: `CDMConnector`, `omopgenerics`, `omock`, and `OmopSketch`. These packages establish database connectivity, define core data structures, provide synthetic testing data, and enable database characterization. For cohort-specific operations, see [Cohort Management Packages](#3.3.2). For specialized analytical functions, see [Specialized Analysis Packages](#3.3.3).

## Package Architecture Overview

The core infrastructure packages form the foundation layer of the OMOP analytics ecosystem. Each package serves a distinct role while integrating seamlessly with the others.

**Core Infrastructure Package Relationships**
```mermaid
graph TB
    subgraph "Database Layer"
        DBI["DBI<br/>Database Interface"]
        dbplyr["dbplyr<br/>Remote Data Manipulation"]
    end
    
    subgraph "Core Infrastructure"
        omopgenerics["omopgenerics<br/>Data Structures & Validation"]
        CDMConnector["CDMConnector<br/>Database Connection & CDM Management"]
        omock["omock<br/>Synthetic Data Generation"]
        OmopSketch["OmopSketch<br/>Database Characterization"]
    end
    
    subgraph "Analysis Layer"
        CohortConstructor["CohortConstructor<br/>Cohort Building"]
        IncidencePrevalence["IncidencePrevalence<br/>Epidemiology"]
        DrugUtilisation["DrugUtilisation<br/>Medication Analysis"]
    end
    
    DBI --> CDMConnector
    dbplyr --> CDMConnector
    omopgenerics --> CDMConnector
    omopgenerics --> omock
    omopgenerics --> OmopSketch
    CDMConnector --> omock
    CDMConnector --> OmopSketch
    CDMConnector --> CohortConstructor
    omock --> CohortConstructor
    OmopSketch --> IncidencePrevalence
    CDMConnector --> DrugUtilisation
```

**Sources:** docs/data_analysis/package_reference/cdmconnector.md, docs/data_analysis/package_reference/omopgenerics.md, docs/data_analysis/package_reference/omock.md, docs/data_analysis/package_reference/omopsketch.md

## omopgenerics: Core Data Structures

The `omopgenerics` package defines the fundamental data classes and generic functions that standardize data representation across the entire ecosystem.

**Key Data Classes**
```mermaid
classDiagram
    class cdm_reference {
        +Database connection
        +Schema information
        +Table references
    }
    
    class cdm_table {
        +Table data
        +Metadata
        +Validation rules
    }
    
    class cohort_table {
        +cohort_definition_id: integer
        +subject_id: integer
        +cohort_start_date: date
        +cohort_end_date: date
        +settings(): data.frame
        +attrition(): data.frame
    }
    
    class summarised_result {
        +13 standardized columns
        +Analysis results
        +pivotEstimates()
        +splitGroup()
        +splitStrata()
    }
    
    cdm_reference --> cdm_table
    cdm_table --> cohort_table
    cohort_table --> summarised_result
```

### Generic Functions

The package provides standardized functions that work across all OMOP data objects:

| Function | Purpose | Returns |
|----------|---------|---------|
| `settings()` | Access cohort settings and metadata | `data.frame` |
| `attrition()` | Access cohort attrition information | `data.frame` |
| `cohortCount()` | Get cohort record and subject counts | `data.frame` |
| `splitGroup()`, `splitStrata()`, `splitAdditional()` | Split grouped columns | Modified object |
| `pivotEstimates()` | Pivot estimate columns to wide format | `data.frame` |
| `filterStrata()` | Filter by strata conditions | Filtered object |

**Sources:** [docs/data_analysis/package_reference/omopgenerics.md:10-34]()

## CDMConnector: Database Management

`CDMConnector` provides the essential interface between R and OMOP CDM databases, managing connections and table operations.

**Database Connection Workflow**
```mermaid
flowchart TD
    DBI_con["DBI::dbConnect()<br/>Database Connection"]
    cdmFromCon["cdmFromCon()<br/>con, cdmSchema, writeSchema"]
    cdm_ref["cdm_reference object<br/>Ready for analysis"]
    
    subgraph "Table Operations"
        insertTable["insertTable()<br/>Add local data to CDM"]
        dropSourceTable["dropSourceTable()<br/>Remove tables"]
        compute["compute()<br/>Materialize queries"]
        listSourceTables["listSourceTables()<br/>List available tables"]
    end
    
    DBI_con --> cdmFromCon
    cdmFromCon --> cdm_ref
    cdm_ref --> insertTable
    cdm_ref --> dropSourceTable
    cdm_ref --> compute
    cdm_ref --> listSourceTables
```

### Core Functions

| Function | Parameters | Purpose |
|----------|------------|---------|
| `cdmFromCon()` | `con`, `cdmSchema`, `writeSchema`, `writePrefix` | Create CDM reference from database connection |
| `insertTable()` | `cdm`, `name`, `table` | Insert local tibble into CDM |
| `dropSourceTable()` | `cdm`, `name` | Remove tables from CDM and database |
| `compute()` | `name`, `temporary` | Materialize query results as tables |
| `listSourceTables()` | `cdm` | List all available source tables |

**Sources:** [docs/data_analysis/package_reference/cdmconnector.md:14-31]()

## omock: Synthetic Data Generation

The `omock` package generates realistic synthetic OMOP CDM datasets for development, testing, and demonstration purposes.

**Mock Data Generation Process**
```mermaid
flowchart LR
    availableMockDatasets["availableMockDatasets()<br/>List available datasets"]
    
    subgraph "Available Datasets"
        GiBleed["GiBleed<br/>Gastrointestinal bleeding study"]
        Eunomia["Eunomia<br/>General synthetic dataset"]
        Synthea["Synthea COVID-19<br/>COVID-19 synthetic patients"]
    end
    
    mockCdmFromDataset["mockCdmFromDataset()<br/>datasetName parameter"]
    cdm_local["Local CDM object<br/>Ready for analysis"]
    insertCdmTo["insertCdmTo()<br/>Copy to database"]
    cdm_remote["Remote CDM object<br/>In database"]
    
    availableMockDatasets --> GiBleed
    availableMockDatasets --> Eunomia
    availableMockDatasets --> Synthea
    
    GiBleed --> mockCdmFromDataset
    Eunomia --> mockCdmFromDataset
    Synthea --> mockCdmFromDataset
    
    mockCdmFromDataset --> cdm_local
    cdm_local --> insertCdmTo
    insertCdmTo --> cdm_remote
```

### Available Mock Datasets

| Dataset | Description | Use Case |
|---------|-------------|----------|
| **GiBleed** | Gastrointestinal bleeding study dataset | Clinical study simulation |
| **Eunomia** | General synthetic dataset | General development and testing |
| **Synthea COVID-19** | COVID-19 synthetic patient data | Pandemic-related studies |

**Sources:** [docs/data_analysis/package_reference/omock.md:12-22]()

## OmopSketch: Database Characterization

`OmopSketch` provides comprehensive database profiling and quality assessment capabilities for OMOP CDM databases.

**Database Characterization Workflow**
```mermaid
flowchart TD
    cdm["CDM Database"]
    
    subgraph "Snapshot Analysis"
        summariseOmopSnapshot["summariseOmopSnapshot()<br/>Real-time database overview"]
        tableOmopSnapshot["tableOmopSnapshot()<br/>Format snapshot results"]
    end
    
    subgraph "Observation Period Analysis"
        summariseObservationPeriod["summariseObservationPeriod()<br/>Analyze observation characteristics"]
        summariseInObservation["summariseInObservation()<br/>Track trends over time"]
        plotObservationPeriod["plotObservationPeriod()<br/>Visualize statistics"]
    end
    
    subgraph "Clinical Quality Assessment"
        summariseMissingData["summariseMissingData()<br/>Missing data patterns"]
        summariseClinicalRecords["summariseClinicalRecords()<br/>Comprehensive table characterization"]
        summariseConceptIdCounts["summariseConceptIdCounts()<br/>Concept frequency analysis"]
    end
    
    subgraph "Integrated Analysis"
        databaseCharacteristics["databaseCharacteristics()<br/>Complete database characterization"]
        shinyCharacteristics["shinyCharacteristics()<br/>Interactive exploration"]
    end
    
    cdm --> summariseOmopSnapshot
    cdm --> summariseObservationPeriod
    cdm --> summariseMissingData
    
    summariseOmopSnapshot --> databaseCharacteristics
    summariseObservationPeriod --> databaseCharacteristics
    summariseMissingData --> databaseCharacteristics
    
    databaseCharacteristics --> shinyCharacteristics
```

### Analysis Functions by Category

| Category | Functions | Purpose |
|----------|-----------|---------|
| **Snapshot** | `summariseOmopSnapshot()`, `tableOmopSnapshot()` | Database overview, vocabulary version, table sizes |
| **Temporal** | `summariseObservationPeriod()`, `summariseInObservation()` | Observation period analysis, temporal trends |
| **Quality** | `summariseMissingData()`, `summariseClinicalRecords()` | Missing data patterns, record quality assessment |
| **Concepts** | `summariseConceptIdCounts()`, `tableConceptIdCounts()` | Concept frequency and usage analysis |
| **Integrated** | `databaseCharacteristics()`, `shinyCharacteristics()` | Complete characterization with interactive exploration |

**Sources:** [docs/data_analysis/package_reference/omopsketch.md:14-47]()

## Package Integration Patterns

The core infrastructure packages work together through standardized interfaces and shared data structures.

**Typical Analysis Workflow Integration**
```mermaid
sequenceDiagram
    participant User
    participant CDMConnector
    participant omopgenerics
    participant omock
    participant OmopSketch
    
    User->>+CDMConnector: cdmFromCon(con, schemas)
    CDMConnector->>+omopgenerics: Create cdm_reference
    omopgenerics-->>-CDMConnector: Validated CDM object
    CDMConnector-->>-User: cdm
    
    alt Development/Testing
        User->>+omock: mockCdmFromDataset("Eunomia")
        omock->>+omopgenerics: Create local cdm_reference
        omopgenerics-->>-omock: Validated mock CDM
        omock-->>-User: mock_cdm
    end
    
    User->>+OmopSketch: summariseOmopSnapshot(cdm)
    OmopSketch->>+omopgenerics: Create summarised_result
    omopgenerics-->>-OmopSketch: Standardized result object
    OmopSketch-->>-User: Database characterization
```

This integration ensures that:
- All CDM objects follow consistent validation rules from `omopgenerics`
- Database connections are managed uniformly through `CDMConnector`
- Testing environments are easily created with `omock`
- Database quality is assessed systematically with `OmopSketch`

**Sources:** [docs/data_analysis/package_reference/cdmconnector.md:14-31](), [docs/data_analysis/package_reference/omopgenerics.md:10-34](), [docs/data_analysis/package_reference/omock.md:12-22](), [docs/data_analysis/package_reference/omopsketch.md:14-47]()
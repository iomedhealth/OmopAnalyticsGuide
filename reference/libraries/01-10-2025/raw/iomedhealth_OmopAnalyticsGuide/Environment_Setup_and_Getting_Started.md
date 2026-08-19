# Page: Environment Setup and Getting Started

# Environment Setup and Getting Started

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/intro_to_observational_research.md](docs/data_analysis/intro_to_observational_research.md)
- [docs/data_analysis/package_reference/visomopresults.md](docs/data_analysis/package_reference/visomopresults.md)
- [docs/data_analysis/setup.md](docs/data_analysis/setup.md)

</details>



This document provides step-by-step instructions for configuring a local R development environment for OMOP CDM data analysis. It covers software installation, package management, project configuration, and environment verification to ensure you have all necessary components for running OMOP analytics workflows.

For information about the broader OMOP analytics framework and package ecosystem, see [R Package Reference](#3.3). For guidance on using tidyverse programming patterns with OMOP data, see [Tidyverse Programming with OMOP](#3.2).

## Software Prerequisites

The OMOP analytics environment requires three core software components that work together to provide a complete development environment.

### Required Software Stack

```mermaid
graph TD
    R["R 4.2+<br/>Statistical Computing Engine"] 
    RStudio["RStudio Desktop<br/>IDE Interface"]
    RTools["RTools<br/>Package Compilation"]
    
    R --> RStudio
    R --> RTools
    RStudio -.->|"Uses"| RTools
    
    subgraph "Package Ecosystem"
        CRAN["CRAN Packages<br/>dplyr, DBI, duckdb"]
        GITHUB["GitHub Packages<br/>CDMConnector, omopgenerics"]
    end
    
    R --> CRAN
    R --> GITHUB
    RTools --> GITHUB
```

Sources: [docs/data_analysis/setup.md:12-18]()

- **R**: Core statistical computing language (version 4.2+)
- **RStudio Desktop**: Integrated development environment providing project management, script editing, and console access
- **RTools**: Compilation utilities required for building packages from source code

## Project Configuration

### RStudio Project Structure

The development environment uses RStudio Projects (`.Rproj` files) to manage workspace organization and ensure consistent working directories across sessions.

```mermaid
graph TD
    PROJECT[".Rproj File<br/>Project Configuration"]
    RENV[".Renviron<br/>Environment Variables"]
    FILES["Project Files<br/>Scripts and Data"]
    
    PROJECT --> RENV
    PROJECT --> FILES
    
    subgraph "Environment Variables"
        EUNOMIA["EUNOMIA_DATA_FOLDER<br/>Mock Database Path"]
    end
    
    RENV --> EUNOMIA
    
    subgraph "Verification"
        CODETORUN["CodeToRun.R<br/>Setup Verification Script"]
    end
    
    FILES --> CODETORUN
```

Sources: [docs/data_analysis/setup.md:20-27](), [docs/data_analysis/setup.md:67-80]()

The `.Renviron` file stores environment variables that persist across R sessions, particularly the path to mock database files used for development and testing.

## Package Installation Workflow

### Core Package Dependencies

The OMOP analytics ecosystem is built on a layered architecture of R packages, each serving specific functions in the analysis pipeline.

```mermaid
graph TD
    subgraph "Database Layer"
        DBI["DBI<br/>Database Interface"]
        DUCKDB["duckdb<br/>Database Engine"]
    end
    
    subgraph "Data Manipulation"
        DPLYR["dplyr<br/>Data Grammar"]
        DBPLYR["dbplyr<br/>Database Translation"]
    end
    
    subgraph "OMOP Core"
        CDMCONNECTOR["CDMConnector<br/>OMOP Database Connection"]
        OMOPGENERICS["omopgenerics<br/>Common Classes"]
    end
    
    subgraph "Cohort Management"
        COHORTCONSTRUCTOR["CohortConstructor<br/>Population Definition"]
        PATIENTPROFILES["PatientProfiles<br/>Feature Engineering"]
    end
    
    subgraph "Analysis Packages"
        INCPREV["IncidencePrevalence<br/>Epidemiology"]
        DRUGUTIL["DrugUtilisation<br/>Medication Analysis"]
        COHORTCHAR["CohortCharacteristics<br/>Table 1 Generation"]
    end
    
    subgraph "Visualization"
        VISOMOP["visOmopResults<br/>Standardized Output"]
        OMOPSKETCH["OmopSketch<br/>Database Summary"]
    end
    
    subgraph "Utilities"
        HERE["here<br/>Path Management"]
        USETHIS["usethis<br/>Project Setup"]
    end
    
    DBI --> CDMCONNECTOR
    DUCKDB --> CDMCONNECTOR
    DPLYR --> CDMCONNECTOR
    DBPLYR --> CDMCONNECTOR
    OMOPGENERICS --> CDMCONNECTOR
    
    CDMCONNECTOR --> COHORTCONSTRUCTOR
    CDMCONNECTOR --> PATIENTPROFILES
    
    COHORTCONSTRUCTOR --> INCPREV
    COHORTCONSTRUCTOR --> DRUGUTIL
    COHORTCONSTRUCTOR --> COHORTCHAR
    PATIENTPROFILES --> COHORTCHAR
    
    INCPREV --> VISOMOP
    DRUGUTIL --> VISOMOP
    COHORTCHAR --> VISOMOP
    OMOPSKETCH --> VISOMOP
```

Sources: [docs/data_analysis/setup.md:37-53]()

### Installation Command

All required packages are installed using a single `install.packages()` command that handles dependency resolution automatically:

Sources: [docs/data_analysis/setup.md:37-53]()

## Mock Database Configuration

### Eunomia Setup Process

The development environment uses Eunomia, a synthetic OMOP CDM dataset, for testing and learning. The setup process involves downloading the data and configuring environment variables for consistent access.

```mermaid
graph TD
    DOWNLOAD["CDMConnector::downloadEunomiaData()<br/>Download Mock Data"]
    CONFIGURE["usethis::edit_r_environ()<br/>Configure Environment"]
    RESTART["Session Restart<br/>Apply Configuration"]
    
    DOWNLOAD --> CONFIGURE
    CONFIGURE --> RESTART
    
    subgraph "File System"
        EUNOMIA_ZIP["Eunomia.zip<br/>Mock Database File"]
        RENVIRON[".Renviron<br/>EUNOMIA_DATA_FOLDER"]
    end
    
    DOWNLOAD --> EUNOMIA_ZIP
    CONFIGURE --> RENVIRON
    
    subgraph "Access Pattern"
        HERE_HERE["here::here()<br/>Project Root Path"]
        ENV_VAR["Sys.getenv('EUNOMIA_DATA_FOLDER')<br/>Environment Variable Access"]
    end
    
    EUNOMIA_ZIP --> HERE_HERE
    RENVIRON --> ENV_VAR
```

Sources: [docs/data_analysis/setup.md:56-80]()

The `CDMConnector::downloadEunomiaData()` function retrieves the mock dataset, while `usethis::edit_r_environ()` provides a convenient interface for editing environment variables.

## Environment Verification

### Verification Script Workflow

The setup verification process uses a dedicated script that tests all components of the environment to ensure proper configuration.

```mermaid
graph TD
    SCRIPT["CodeToRun.R<br/>Verification Script"]
    LOAD["Load Packages<br/>Library Imports"]
    CONNECT["Database Connection<br/>CDM Setup"]
    COHORT["Cohort Creation<br/>Test Analysis"]
    OUTPUT["Console Output<br/>Verification Results"]
    
    SCRIPT --> LOAD
    LOAD --> CONNECT
    CONNECT --> COHORT
    COHORT --> OUTPUT
    
    subgraph "Expected Output"
        TIBBLE["# A tibble: 1 × 2<br/>cohort_definition_id cohort_name<br/>1 chronic_sinusitis"]
    end
    
    OUTPUT --> TIBBLE
    
    subgraph "Components Tested"
        PACKAGES["Package Loading<br/>All Dependencies"]
        DATABASE["Database Access<br/>Eunomia Connection"] 
        ANALYSIS["Analysis Functions<br/>Cohort Operations"]
    end
    
    LOAD --> PACKAGES
    CONNECT --> DATABASE
    COHORT --> ANALYSIS
```

Sources: [docs/data_analysis/setup.md:82-105]()

The verification script performs a complete end-to-end test by loading packages, connecting to the mock database, creating a simple cohort, and displaying the results. Successful execution indicates that all environment components are properly configured.

## Integration with Development Workflows

### Connection to Broader Analytics Framework

The environment setup establishes the foundation for the complete OMOP analytics workflow, connecting to downstream analysis and visualization components.

```mermaid
graph TD
    SETUP["Environment Setup<br/>This Section"]
    
    subgraph "Immediate Next Steps"
        EXPLORATION["OmopSketch<br/>Database Exploration"]
        CONCEPTS["CodelistGenerator<br/>Concept Definition"]
        COHORTS["CohortConstructor<br/>Population Definition"]
    end
    
    subgraph "Analysis Workflows"
        CHARACTERISTICS["CohortCharacteristics<br/>Table 1 Generation"]
        SPECIALIZED["Specialized Analysis<br/>IncidencePrevalence, DrugUtilisation"]
    end
    
    subgraph "Output Generation"
        VISUALIZATION["visOmopResults<br/>Publication-Ready Output"]
    end
    
    SETUP --> EXPLORATION
    SETUP --> CONCEPTS
    SETUP --> COHORTS
    
    EXPLORATION --> CHARACTERISTICS
    CONCEPTS --> COHORTS
    COHORTS --> CHARACTERISTICS
    COHORTS --> SPECIALIZED
    
    CHARACTERISTICS --> VISUALIZATION
    SPECIALIZED --> VISUALIZATION
```

Sources: [docs/data_analysis/setup.md:109-115]()

The setup process enables immediate progression to database exploration, concept definition, and cohort building activities that form the core of OMOP analytics workflows.

## Configuration Files and Paths

| Configuration Element | File Path | Purpose |
|----------------------|-----------|---------|
| Project Definition | `.Rproj` | RStudio project configuration |
| Environment Variables | `.Renviron` | Persistent R session settings |
| Mock Database | `Eunomia.zip` | Synthetic OMOP CDM data |
| Verification Script | `docs/data_analysis/CodeToRun.R` | Environment testing |

Sources: [docs/data_analysis/setup.md:1-116]()

This configuration provides a complete, self-contained development environment for OMOP CDM analysis, with all necessary components properly integrated and verified.
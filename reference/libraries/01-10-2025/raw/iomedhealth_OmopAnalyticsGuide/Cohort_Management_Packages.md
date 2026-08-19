# Page: Cohort Management Packages

# Cohort Management Packages

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/package_reference/PatientProfiles.md](docs/data_analysis/package_reference/PatientProfiles.md)
- [docs/data_analysis/package_reference/cdmconnector.md](docs/data_analysis/package_reference/cdmconnector.md)
- [docs/data_analysis/package_reference/cohortcharacteristics.md](docs/data_analysis/package_reference/cohortcharacteristics.md)
- [docs/data_analysis/package_reference/cohortconstructor.md](docs/data_analysis/package_reference/cohortconstructor.md)
- [docs/data_analysis/package_reference/omock.md](docs/data_analysis/package_reference/omock.md)
- [docs/data_analysis/package_reference/omopgenerics.md](docs/data_analysis/package_reference/omopgenerics.md)
- [docs/data_analysis/package_reference/omopsketch.md](docs/data_analysis/package_reference/omopsketch.md)

</details>



This document covers the three core packages responsible for cohort definition, feature engineering, and characterization within the OMOP analytics ecosystem: `CohortConstructor`, `PatientProfiles`, and `CohortCharacteristics`. These packages provide the foundational tools for creating patient cohorts, enriching them with clinical features, and generating comprehensive summaries for analysis.

For foundational database connectivity and CDM management, see [Core Infrastructure Packages](#3.3.1). For analysis-specific packages that consume the output from cohort management, see [Specialized Analysis Packages](#3.3.3).

## Package Architecture and Relationships

The cohort management packages follow a three-stage pipeline architecture where each package has a distinct role in the cohort analysis workflow.

### Cohort Management Pipeline

```mermaid
graph TD
    subgraph "Data Sources"
        CDM["CDMConnector::cdm_reference"]
        OMOP_TABLES["OMOP CDM Tables<br/>person, condition_occurrence<br/>drug_exposure, etc."]
        CONCEPT_SETS["CodelistGenerator::codelist<br/>Medical concept definitions"]
    end

    subgraph "Stage 1: Cohort Definition"
        CC_CONCEPT["CohortConstructor::conceptCohort()"]
        CC_DEMO["CohortConstructor::demographicsCohort()"]
        CC_MEASURE["CohortConstructor::measurementCohort()"]
        CC_DEATH["CohortConstructor::deathCohort()"]
        CC_REQUIRE["CohortConstructor::require*()<br/>requireDemographics, requireAge<br/>requireCohortIntersect, etc."]
        CC_MANIPULATE["CohortConstructor::*Cohorts()<br/>unionCohorts, intersectCohorts<br/>collapseCohorts, sampleCohorts"]
    end

    subgraph "Stage 2: Feature Engineering"
        PP_DEMO["PatientProfiles::addDemographics()"]
        PP_INTERSECT["PatientProfiles::add*Intersect*()<br/>addCohortIntersect*, addConceptIntersect*"]
        PP_OBSERVATION["PatientProfiles::add*Observation()<br/>addPriorObservation, addFutureObservation"]
        PP_DEATH["PatientProfiles::addDeath*()<br/>addDeathDate, addDeathDays, addDeathFlag"]
    end

    subgraph "Stage 3: Characterization"
        CH_SUMMARISE["CohortCharacteristics::summarise*()<br/>summariseCharacteristics<br/>summariseLargeScaleCharacteristics<br/>summariseCohortTiming, summariseCohortOverlap"]
        CH_TABLE["CohortCharacteristics::table*()<br/>tableCharacteristics<br/>tableCohortOverlap, tableCohortTiming"]
        CH_PLOT["CohortCharacteristics::plot*()<br/>plotCharacteristics<br/>plotCohortOverlap, plotCohortTiming"]
    end

    subgraph "Output"
        COHORT_TABLE["omopgenerics::cohort_table<br/>cohort_definition_id, subject_id<br/>cohort_start_date, cohort_end_date"]
        ENRICHED_COHORT["Enriched cohort_table<br/>+ demographics, intersections<br/>+ clinical features"]
        SUMMARISED_RESULT["omopgenerics::summarised_result<br/>Standardized analysis output"]
    end

    CDM --> CC_CONCEPT
    CDM --> CC_DEMO
    CDM --> CC_MEASURE
    CDM --> CC_DEATH
    OMOP_TABLES --> CC_CONCEPT
    CONCEPT_SETS --> CC_CONCEPT

    CC_CONCEPT --> CC_REQUIRE
    CC_DEMO --> CC_REQUIRE
    CC_MEASURE --> CC_REQUIRE
    CC_DEATH --> CC_REQUIRE

    CC_REQUIRE --> CC_MANIPULATE
    CC_MANIPULATE --> COHORT_TABLE

    COHORT_TABLE --> PP_DEMO
    COHORT_TABLE --> PP_INTERSECT
    COHORT_TABLE --> PP_OBSERVATION
    COHORT_TABLE --> PP_DEATH

    PP_DEMO --> ENRICHED_COHORT
    PP_INTERSECT --> ENRICHED_COHORT
    PP_OBSERVATION --> ENRICHED_COHORT
    PP_DEATH --> ENRICHED_COHORT

    ENRICHED_COHORT --> CH_SUMMARISE
    CH_SUMMARISE --> CH_TABLE
    CH_SUMMARISE --> CH_PLOT
    CH_SUMMARISE --> SUMMARISED_RESULT
```

Sources: [docs/data_analysis/package_reference/cohortconstructor.md:19-52](), [docs/data_analysis/package_reference/PatientProfiles.md:20-48](), [docs/data_analysis/package_reference/cohortcharacteristics.md:54-77]()

## CohortConstructor: Cohort Definition and Manipulation

`CohortConstructor` provides the foundational tools for creating patient cohorts from OMOP CDM data. It implements a systematic approach to cohort building through base cohort generation, requirement application, and cohort manipulation operations.

### Core Cohort Building Functions

The package provides four primary methods for creating base cohorts, each targeting different clinical data sources:

| Function | Purpose | Primary Tables |
|----------|---------|----------------|
| `conceptCohort()` | Create cohorts from concept sets | `condition_occurrence`, `drug_exposure`, `procedure_occurrence`, `device_exposure`, `measurement`, `observation`, `visit_occurrence` |
| `demographicsCohort()` | Create cohorts based on patient characteristics | `person`, `observation_period` |
| `measurementCohort()` | Create cohorts with value-based measurement filtering | `measurement` |
| `deathCohort()` | Create cohorts based on death records | `death` |

### Requirement System Architecture

```mermaid
graph TD
    subgraph "Base Cohort Creation"
        BASE_COHORT["cohort_table<br/>Initial patient population"]
    end

    subgraph "Demographic Requirements"
        REQ_DEMO["requireDemographics()<br/>age, sex, observation time"]
        REQ_AGE["requireAge()"]
        REQ_SEX["requireSex()"]
        REQ_PRIOR["requirePriorObservation()"]
        REQ_FUTURE["requireFutureObservation()"]
    end

    subgraph "Date Requirements"
        REQ_DATE_RANGE["requireInDateRange()<br/>Filter by date windows"]
        TRIM_DATE["trimToDateRange()<br/>Adjust cohort boundaries"]
    end

    subgraph "Intersection Requirements"
        REQ_COHORT_INT["requireCohortIntersect()<br/>Overlap with other cohorts"]
        REQ_CONCEPT_INT["requireConceptIntersect()<br/>Overlap with concept events"]
        REQ_TABLE_INT["requireTableIntersect()<br/>Overlap with any OMOP table"]
    end

    subgraph "Cohort Manipulation"
        UNION["unionCohorts()<br/>Combine multiple cohorts"]
        INTERSECT["intersectCohorts()<br/>Find common patients"]
        COLLAPSE["collapseCohorts()<br/>Merge overlapping entries"]
        SAMPLE["sampleCohorts()<br/>Random sampling"]
        STRATIFY["stratifyCohorts()<br/>Split by variables"]
        YEAR_SPLIT["yearCohorts()<br/>Split by calendar year"]
    end

    subgraph "Date Operations"
        EXIT_FIRST["exitAtFirstDate()"]
        EXIT_LAST["exitAtLastDate()"]
        ENTRY_FIRST["entryAtFirstDate()"]
        ENTRY_LAST["entryAtLastDate()"]
        EXIT_OBS["exitAtObservationEnd()"]
        EXIT_DEATH["exitAtDeath()"]
    end

    BASE_COHORT --> REQ_DEMO
    BASE_COHORT --> REQ_DATE_RANGE
    BASE_COHORT --> REQ_COHORT_INT

    REQ_DEMO --> UNION
    REQ_DATE_RANGE --> INTERSECT
    REQ_COHORT_INT --> COLLAPSE

    UNION --> EXIT_FIRST
    INTERSECT --> EXIT_LAST
    COLLAPSE --> ENTRY_FIRST
```

Sources: [docs/data_analysis/package_reference/cohortconstructor.md:113-202](), [docs/data_analysis/package_reference/cohortconstructor.md:220-235]()

### Advanced Features

The package includes specialized functionality for complex cohort scenarios:

- **`matchCohorts()`**: Generates matched control cohorts based on demographic characteristics like sex and year of birth
- **`benchmarkCohortConstructor()`**: Performance comparison against traditional CIRCE/ATLAS cohort generation
- **Attrition tracking**: All operations automatically track patient attrition with `attrition()` function
- **Settings management**: Cohort metadata preserved through `settings()` function

Sources: [docs/data_analysis/package_reference/cohortconstructor.md:237-252]()

## PatientProfiles: Feature Engineering and Enrichment

`PatientProfiles` specializes in adding clinical features and characteristics to existing cohort tables. It implements a unified intersection system for analyzing temporal relationships between different clinical data sources.

### Core Intersection Engine

The package's core functionality revolves around the `addIntersect()` engine, which provides temporal filtering and value calculation across OMOP tables:

```mermaid
graph TD
    subgraph "Input Processing"
        COHORT_IN["cohort_table input"]
        VALIDATION["checkX(), checkCdm()<br/>checkVariableInX()"]
        FILTERS["checkFilter(), checkValue()<br/>checkSnakeCase()"]
    end

    subgraph "Core Engine: addIntersect()"
        TEMPORAL["Window Filtering<br/>c(-Inf, 0), c(0, Inf)<br/>c(-365, 0), etc."]
        VALUE_CALC["Value Calculation<br/>count, flag, date, days"]
        PIVOT["tidyr::pivot_wider()<br/>Result Reshaping"]
    end

    subgraph "Specialized Functions"
        ADD_DEMO["addDemographics()<br/>addAge(), addSex()"]
        ADD_COHORT["addCohortIntersect*()<br/>Flag, Count, Date, Days"]
        ADD_CONCEPT["addConceptIntersect*()<br/>Flag, Count, Field"]
        ADD_TABLE["addTableIntersect*()<br/>Any OMOP table intersection"]
        ADD_OBS["add*Observation()<br/>Prior, Future, InObservation"]
        ADD_DEATH["addDeath*()<br/>Date, Days, Flag"]
    end

    subgraph "Output Processing"
        JOIN["dplyr::left_join()<br/>Back to Original Table"]
        COMPUTE["dplyr::compute()<br/>Database Materialization"]
        ENRICHED_OUT["Enriched cohort_table<br/>+ new feature columns"]
    end

    COHORT_IN --> VALIDATION
    VALIDATION --> FILTERS
    FILTERS --> TEMPORAL
    TEMPORAL --> VALUE_CALC
    VALUE_CALC --> PIVOT

    PIVOT --> ADD_DEMO
    PIVOT --> ADD_COHORT
    PIVOT --> ADD_CONCEPT
    PIVOT --> ADD_TABLE
    PIVOT --> ADD_OBS
    PIVOT --> ADD_DEATH

    ADD_DEMO --> JOIN
    ADD_COHORT --> JOIN
    ADD_CONCEPT --> JOIN
    ADD_TABLE --> JOIN
    ADD_OBS --> JOIN
    ADD_DEATH --> JOIN

    JOIN --> COMPUTE
    COMPUTE --> ENRICHED_OUT
```

Sources: [docs/data_analysis/package_reference/PatientProfiles.md:96-149]()

### Function Categories and APIs

| Category | Functions | Purpose |
|----------|-----------|---------|
| Demographics | `addDemographics()`, `addAge()`, `addSex()` | Add age, sex, observation period information |
| Cohort Intersections | `addCohortIntersectFlag()`, `addCohortIntersectCount()`, `addCohortIntersectDate()`, `addCohortIntersectDays()` | Analyze overlaps with other cohorts |
| Concept Intersections | `addConceptIntersectFlag()`, `addConceptIntersectCount()`, `addConceptIntersectField()` | Find intersections with OMOP concept sets |
| Observation Periods | `addInObservation()`, `addPriorObservation()`, `addFutureObservation()`, `addObservationPeriodId()` | Handle temporal constraints |
| Mortality | `addDeathDate()`, `addDeathDays()`, `addDeathFlag()` | Incorporate death data |

### Statistical Summarization

The `summariseResult()` function provides comprehensive statistical analysis with support for grouping, stratification, and various statistical estimates.

Sources: [docs/data_analysis/package_reference/PatientProfiles.md:188-321]()

## CohortCharacteristics: Summarization and Visualization

`CohortCharacteristics` implements a standardized three-tier analysis pattern: `summarise*()` → `plot*()` → `table*()` for consistent cohort analysis and reporting.

### Analysis Pipeline Architecture

```mermaid
graph TD
    subgraph "Input Sources"
        CDM_REF["CDMConnector::cdm_reference"]
        COHORT_TABLES["omopgenerics::cohort_table objects"]
    end

    subgraph "Summarization Layer"
        SUM_CHAR["summariseCharacteristics()<br/>strata, cohortId, ageGroup<br/>tableIntersect, cohortIntersect<br/>conceptIntersect"]
        SUM_LARGE["summariseLargeScaleCharacteristics()<br/>window, eventInWindow<br/>minimumFrequency"]
        SUM_TIMING["summariseCohortTiming()<br/>restrictToFirstEntry"]
        SUM_OVERLAP["summariseCohortOverlap()"]
        SUM_ATTRITION["summariseCohortAttrition()"]
    end

    subgraph "Standardized Output"
        SUMMARISED["omopgenerics::summarised_result<br/>13-column standard format"]
    end

    subgraph "Visualization Layer"
        PLOT_CHAR["plotCharacteristics()<br/>plotStyle, facet, colour"]
        PLOT_OVERLAP["plotCohortOverlap()<br/>uniqueCombinations"]
        PLOT_TIMING["plotCohortTiming()<br/>plotType, timeScale"]
        PLOT_ATTRITION["plotCohortAttrition()<br/>type"]
        PLOT_LARGE["plotComparedLargeScaleCharacteristics()<br/>colour, reference"]
    end

    subgraph "Table Layer"
        TABLE_CHAR["tableCharacteristics()<br/>result, header"]
        TABLE_LARGE["tableLargeScaleCharacteristics()"]
        TABLE_TOP["tableTopLargeScaleCharacteristics()<br/>topConcepts"]
        TABLE_OVERLAP["tableCohortOverlap()"]
        TABLE_TIMING["tableCohortTiming()<br/>timeScale, uniqueCombinations"]
        TABLE_ATTRITION["tableCohortAttrition()"]
    end

    subgraph "Output Formats"
        INTERACTIVE_VIZ["Interactive Visualizations<br/>ggplot2 objects"]
        FORMATTED_TABLES["Formatted Tables<br/>gt, flextable objects"]
    end

    CDM_REF --> SUM_CHAR
    CDM_REF --> SUM_LARGE
    COHORT_TABLES --> SUM_CHAR
    COHORT_TABLES --> SUM_TIMING
    COHORT_TABLES --> SUM_OVERLAP
    COHORT_TABLES --> SUM_ATTRITION

    SUM_CHAR --> SUMMARISED
    SUM_LARGE --> SUMMARISED
    SUM_TIMING --> SUMMARISED
    SUM_OVERLAP --> SUMMARISED
    SUM_ATTRITION --> SUMMARISED

    SUMMARISED --> PLOT_CHAR
    SUMMARISED --> PLOT_OVERLAP
    SUMMARISED --> PLOT_TIMING
    SUMMARISED --> PLOT_ATTRITION
    SUMMARISED --> PLOT_LARGE

    SUMMARISED --> TABLE_CHAR
    SUMMARISED --> TABLE_LARGE
    SUMMARISED --> TABLE_TOP
    SUMMARISED --> TABLE_OVERLAP
    SUMMARISED --> TABLE_TIMING
    SUMMARISED --> TABLE_ATTRITION

    PLOT_CHAR --> INTERACTIVE_VIZ
    PLOT_OVERLAP --> INTERACTIVE_VIZ
    PLOT_TIMING --> INTERACTIVE_VIZ

    TABLE_CHAR --> FORMATTED_TABLES
    TABLE_OVERLAP --> FORMATTED_TABLES
    TABLE_TIMING --> FORMATTED_TABLES
```

Sources: [docs/data_analysis/package_reference/cohortcharacteristics.md:54-109]()

### Function Categories

| Analysis Type | Summarization | Visualization | Tables |
|---------------|---------------|---------------|---------|
| Core Characteristics | `summariseCharacteristics()` | `plotCharacteristics()` | `tableCharacteristics()` |
| Large-Scale Analysis | `summariseLargeScaleCharacteristics()` | `plotComparedLargeScaleCharacteristics()` | `tableLargeScaleCharacteristics()`, `tableTopLargeScaleCharacteristics()` |
| Temporal Analysis | `summariseCohortTiming()` | `plotCohortTiming()` | `tableCohortTiming()` |
| Cohort Overlap | `summariseCohortOverlap()` | `plotCohortOverlap()` | `tableCohortOverlap()` |
| Attrition Analysis | `summariseCohortAttrition()` | `plotCohortAttrition()` | `tableCohortAttrition()` |

Sources: [docs/data_analysis/package_reference/cohortcharacteristics.md:80-109]()

## Integration with OMOP Ecosystem

### Data Class Dependencies

The cohort management packages rely heavily on standardized data classes from `omopgenerics`:

- **`cdm_reference`**: Database connection and table references from `CDMConnector`
- **`cohort_table`**: Core cohort structure with required columns (`cohort_definition_id`, `subject_id`, `cohort_start_date`, `cohort_end_date`)
- **`summarised_result`**: Standardized 13-column output format for all analysis results

### Mock Data Integration

All packages provide mock data functionality for testing and development:

- `CohortConstructor::mockCohortConstructor()`
- `PatientProfiles::mockPatientProfiles()`
- `CohortCharacteristics::mockCohortCharacteristics()`

These functions create synthetic CDM instances with realistic patient data for package development and user testing.

Sources: [docs/data_analysis/package_reference/cohortconstructor.md:87-88](), [docs/data_analysis/package_reference/PatientProfiles.md:72-74](), [docs/data_analysis/package_reference/cohortcharacteristics.md:41-43](), [docs/data_analysis/package_reference/omopgenerics.md:12-33]()
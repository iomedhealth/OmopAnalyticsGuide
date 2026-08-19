# Page: Population-Level Epidemiology

# Population-Level Epidemiology

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [StandardStudies/rmd/population_level_epidemiology.Rmd](StandardStudies/rmd/population_level_epidemiology.Rmd)
- [_includes/rmd_output/population_level_epidemiology.md](_includes/rmd_output/population_level_epidemiology.md)
- [assets/images/rmd_output/estimate_incidence-1.png](assets/images/rmd_output/estimate_incidence-1.png)
- [assets/images/rmd_output/estimate_prevalence-1.png](assets/images/rmd_output/estimate_prevalence-1.png)

</details>



Population-Level Epidemiology studies focus on calculating incidence and prevalence rates across defined populations over time. This guide demonstrates how to conduct these studies using the OHDSI `IncidencePrevalence` R package with OMOP CDM data, following standardized analytical workflows that produce stratified summaries of disease occurrence patterns.

For patient-level summary statistics and cohort characterization, see [Patient-Level Characterisation](#4.3). For other study methodologies, see [Standard Study Types](#4.1).

## Core Methodology

Population-level epidemiology analysis transforms OMOP CDM cohorts into time-stratified incidence and prevalence estimates through three fundamental operations:

**Conceptual Analysis Workflow**
```mermaid
flowchart TD
    CDM["OMOP CDM Database"] --> DENOM["generateDenominatorCohortSet()"]
    CDM --> OUTCOME["Outcome Cohort Table"]
    
    DENOM --> DENOMTIME["Denominator Time<br/>At-risk periods per person"]
    OUTCOME --> OVERLAP["Outcome Overlap<br/>Event occurrence detection"]
    
    DENOMTIME --> SLICE["Interval Slicing<br/>Calendar period stratification"]
    OVERLAP --> SLICE
    
    SLICE --> EST_INC["estimateIncidence()"]
    SLICE --> EST_PREV_POINT["estimatePointPrevalence()"]
    SLICE --> EST_PREV_PERIOD["estimatePeriodPrevalence()"]
    
    EST_INC --> RESULTS["Summarised Results"]
    EST_PREV_POINT --> RESULTS
    EST_PREV_PERIOD --> RESULTS
    
    RESULTS --> PLOT_INC["plotIncidence()"]
    RESULTS --> PLOT_PREV["plotPrevalence()"]
    RESULTS --> TABLE_INC["tableIncidence()"]
    RESULTS --> TABLE_PREV["tablePrevalence()"]
```

Sources: [_includes/rmd_output/population_level_epidemiology.md:10-24](), [StandardStudies/rmd/population_level_epidemiology.Rmd:17-21]()

### Denominator Time Computation

The `generateDenominatorCohortSet()` function establishes person-time contribution rules where individuals contribute at-risk time only during periods meeting study criteria. Entry time is determined as the latest of: study start date, prior observation requirement met, and minimum age reached. Exit time is the earliest of: study end date, observation period end, and maximum age limit.

### Outcome Overlap Detection

Outcome events are read from separate cohort tables created through standard OMOP cohort building processes. Prevalence calculations check whether persons are present in outcome cohorts at specified time points or intervals. Incidence calculations count qualifying first onsets while respecting washout periods and repeated event rules.

### Interval Slicing Strategy

Study periods are partitioned into calendar intervals (years, quarters, months) with each interval receiving independent denominator calculations, outcome counts, and derived rate estimates.

## Function Reference and Parameters

**Core IncidencePrevalence Functions**
```mermaid
flowchart LR
    subgraph "Denominator Setup"
        GDCS["generateDenominatorCohortSet()"]
        GTDCS["generateTargetDenominatorCohortSet()"]
    end
    
    subgraph "Rate Estimation"
        EI["estimateIncidence()"]
        EPP["estimatePointPrevalence()"]
        EPRD["estimatePeriodPrevalence()"]
    end
    
    subgraph "Key Parameters"
        INTERVAL["interval: 'years'|'quarters'|'months'"]
        WASHOUT["outcomeWashout: days|Inf"]
        REPEATED["repeatedEvents: TRUE|FALSE"]
        TIMEPOINT["timePoint: 'start'|'middle'|'end'"]
        FULLCONTRIB["fullContribution: TRUE|FALSE"]
    end
    
    subgraph "Visualization"
        PLINC["plotIncidence()"]
        PLPREV["plotPrevalence()"]
        TBINC["tableIncidence()"]
        TBPREV["tablePrevalence()"]
    end
    
    GDCS --> EI
    GDCS --> EPP
    GDCS --> EPRD
    GTDCS --> EI
    GTDCS --> EPP
    GTDCS --> EPRD
    
    INTERVAL --> EI
    INTERVAL --> EPP
    INTERVAL --> EPRD
    WASHOUT --> EI
    REPEATED --> EI
    TIMEPOINT --> EPP
    FULLCONTRIB --> EPRD
    
    EI --> PLINC
    EPP --> PLPREV
    EPRD --> PLPREV
    EI --> TBINC
    EPP --> TBPREV
    EPRD --> TBPREV
```

Sources: [_includes/rmd_output/population_level_epidemiology.md:25-57](), [StandardStudies/rmd/population_level_epidemiology.Rmd:25-42]()

### Incidence Estimation Parameters

The `estimateIncidence()` function requires specific parameter configuration:

| Parameter | Description | Common Values |
|-----------|-------------|---------------|
| `outcomeWashout` | Days without prior outcome required | `Inf` (first-ever), `365` (annual episodes) |
| `repeatedEvents` | Allow multiple events per person | `FALSE` (single event), `TRUE` (recurring) |
| `completeDatabaseIntervals` | Exclude partial observation periods | `TRUE` (recommended for edge bias reduction) |
| `interval` | Calendar stratification unit | `"years"`, `"quarters"`, `"months"` |

### Prevalence Estimation Types

**Point Prevalence**: Proportion with outcome at specific time point within each interval using `estimatePointPrevalence()`. The `timePoint` parameter ("start"/"middle"/"end") determines the assessment anchor within intervals.

**Period Prevalence**: Proportion with outcome at any time during the interval using `estimatePeriodPrevalence()`. The `fullContribution` parameter controls denominator inclusion - `TRUE` requires complete interval observation, `FALSE` allows partial observation.

Sources: [_includes/rmd_output/population_level_epidemiology.md:28-57](), [StandardStudies/rmd/population_level_epidemiology.Rmd:25-41]()

## Implementation Workflow

The analysis follows the standardized OHDSI pattern of **`summarise -> table/plot`** implemented across the package ecosystem.

**Data Flow Implementation**
```mermaid
flowchart TD
    subgraph "Step 1: Environment Setup"
        LIBS["CDMConnector<br/>IncidencePrevalence<br/>visOmopResults"]
        MOCK["mockIncidencePrevalence()"]
    end
    
    subgraph "Step 2: Denominator Definition"
        COHORT_RANGE["cohortDateRange"]
        AGE_GROUP["ageGroup: list(c(0,64), c(65,100))"]
        SEX["sex: c('Male', 'Female', 'Both')"]
        GDCS_CALL["generateDenominatorCohortSet()"]
    end
    
    subgraph "Step 3: Rate Calculation"
        CALC_INC["estimateIncidence()<br/>outcomeWashout = Inf<br/>repeatedEvents = FALSE"]
        CALC_PREV["estimatePointPrevalence()<br/>timePoint = 'start'"]
    end
    
    subgraph "Step 4: Results Visualization"
        PLOT_FACET["plotIncidence(facet =<br/>c('denominator_age_group',<br/>'denominator_sex'))"]
        PLOT_PREV_FACET["plotPrevalence(facet =<br/>c('denominator_age_group',<br/>'denominator_sex'))"]
    end
    
    LIBS --> MOCK
    MOCK --> COHORT_RANGE
    COHORT_RANGE --> GDCS_CALL
    AGE_GROUP --> GDCS_CALL
    SEX --> GDCS_CALL
    GDCS_CALL --> CALC_INC
    GDCS_CALL --> CALC_PREV
    CALC_INC --> PLOT_FACET
    CALC_PREV --> PLOT_PREV_FACET
```

Sources: [_includes/rmd_output/population_level_epidemiology.md:92-143](), [StandardStudies/rmd/population_level_epidemiology.Rmd:75-103](), [StandardStudies/rmd/population_level_epidemiology.Rmd:115-142]()

### Mock Database Setup

For development and testing purposes, `mockIncidencePrevalence()` creates a self-contained CDM object containing person table, observation_period table, and outcome cohort table meeting minimum package requirements.

Sources: [_includes/rmd_output/population_level_epidemiology.md:100-105](), [StandardStudies/rmd/population_level_epidemiology.Rmd:73-84]()

### Denominator Cohort Configuration

The `generateDenominatorCohortSet()` function accepts multiple stratification parameters simultaneously. Each combination of `ageGroup`, `sex`, and date range creates distinct `cohort_definition_id` values in the resulting denominator table.

Sources: [_includes/rmd_output/population_level_epidemiology.md:119-139](), [StandardStudies/rmd/population_level_epidemiology.Rmd:89-102]()

### Rate Calculation Execution

Incidence estimation with `outcomeWashout = Inf` ensures only first-ever occurrences are counted. The `interval = "quarters"` parameter produces quarterly stratified results. Prevalence estimation with `timePoint = "start"` calculates proportions at quarter start dates.

Sources: [_includes/rmd_output/population_level_epidemiology.md:153-175](), [StandardStudies/rmd/population_level_epidemiology.Rmd:115-126](), [_includes/rmd_output/population_level_epidemiology.md:179-200](), [StandardStudies/rmd/population_level_epidemiology.Rmd:133-142]()

## Output Format and Visualization

Functions return `summarised_result` objects with standardized `estimate_name`/`value` pairs plus metadata including start/end dates and interval types. These objects integrate directly with `visOmopResults` functions.

### Stratification Variables

Results can be stratified and visualized using variables such as:
- `denominator_age_group`
- `denominator_sex` 
- `denominator_cohort_definition_id`

The `plotIncidence()` and `plotPrevalence()` functions accept `facet` parameters for stratified visualization. Use `available...Grouping()` functions to identify valid aesthetic mappings.

Sources: [_includes/rmd_output/population_level_epidemiology.md:59-75](), [StandardStudies/rmd/population_level_epidemiology.Rmd:44-50]()

## Best Practices

- **Interval Selection**: Align intervals to research questions and data density patterns (years for long-term trends, months for seasonality detection)
- **Washout Configuration**: Use `outcomeWashout` and `repeatedEvents` parameters to encode "first-ever" versus "episode-based" incidence definitions
- **Edge Bias Management**: Enable `completeDatabaseIntervals` for incidence and consider `fullContribution` for period prevalence when partial observation periods could bias estimates
- **Exclusion Logic**: Define population restrictions through denominator cohort parameters rather than outcome cohort exclusions

Sources: [_includes/rmd_output/population_level_epidemiology.md:77-87](), [StandardStudies/rmd/population_level_epidemiology.Rmd:52-57]()
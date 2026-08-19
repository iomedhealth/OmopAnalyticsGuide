
# Using OMOP with R

This guide demonstrates how to apply R programming fundamentals to work
with OMOP CDM data. Assuming you have basic R knowledge, we’ll focus on
OMOP-specific concepts, packages, and workflows.

## 1. Creating a CDM Reference

To work with OMOP CDM data in R, we use the `CDMConnector` package to
establish a connection and create a `cdm` reference object.

``` r
library(CDMConnector)
library(omock)
library(lubridate)
library(dplyr)
```

### Connecting to a Local OMOP Database

For a local DuckDB file:

``` r
cdm <- cdmFromCon(
  con = dbConnect(duckdb::duckdb(), "path/to/omop.db"),
  cdmSchema = "main",
  writeSchema = "main"
)
```

### Using Mock Data for Learning

For practice and self-contained tutorials, `omock` provides synthetic
CDM references:

``` r
cdm <- mockCdmReference()
```

This creates a `cdm` object with sample OMOP data.

### Exploring the CDM Object

``` r
# List available tables
names(cdm)
```

    ## [1] "person"               "observation_period"   "cdm_source"          
    ## [4] "concept"              "vocabulary"           "concept_relationship"
    ## [7] "concept_synonym"      "concept_ancestor"     "drug_strength"

``` r
# Access specific tables
cdm$person
```

    ## # A tibble: 0 × 18
    ## # ℹ 18 variables: person_id <int>, gender_concept_id <int>,
    ## #   year_of_birth <int>, month_of_birth <int>, day_of_birth <int>,
    ## #   birth_datetime <date>, race_concept_id <int>, ethnicity_concept_id <int>,
    ## #   location_id <int>, provider_id <int>, care_site_id <int>,
    ## #   person_source_value <chr>, gender_source_value <chr>,
    ## #   gender_source_concept_id <int>, race_source_value <chr>,
    ## #   race_source_concept_id <int>, ethnicity_source_value <chr>, …

### Understanding the CDM Structure

The `cdm` object knows the relationships between tables:

- `cdm$person`: Patient demographics
- `cdm$observation_period`: Observation spans
- `cdm$condition_occurrence`: Diagnoses
- `cdm$drug_exposure`: Medications
- `cdm$visit_occurrence`: Healthcare visits

### Verifying Connection

``` r
# Count patients
cdm$person |> count() |> collect()
```

    ## # A tibble: 1 × 1
    ##       n
    ##   <int>
    ## 1     0

``` r
# Check table structure
cdm$person |> glimpse()
```

    ## Rows: 0
    ## Columns: 18
    ## $ person_id                   <int> 
    ## $ gender_concept_id           <int> 
    ## $ year_of_birth               <int> 
    ## $ month_of_birth              <int> 
    ## $ day_of_birth                <int> 
    ## $ birth_datetime              <date> 
    ## $ race_concept_id             <int> 
    ## $ ethnicity_concept_id        <int> 
    ## $ location_id                 <int> 
    ## $ provider_id                 <int> 
    ## $ care_site_id                <int> 
    ## $ person_source_value         <chr> 
    ## $ gender_source_value         <chr> 
    ## $ gender_source_concept_id    <int> 
    ## $ race_source_value           <chr> 
    ## $ race_source_concept_id      <int> 
    ## $ ethnicity_source_value      <chr> 
    ## $ ethnicity_source_concept_id <int>

The `cdm` object simplifies OMOP analysis by providing a consistent
interface to the complex CDM structure.

## 2. Exploring the OMOP CDM

### Basic Counts and Summaries

Start with overall statistics:

``` r
# Total number of patients
cdm$person |> count() |> collect()
```

    ## # A tibble: 1 × 1
    ##       n
    ##   <int>
    ## 1     0

``` r
# Number of observation periods
cdm$observation_period |> count() |> collect()
```

    ## # A tibble: 1 × 1
    ##       n
    ##   <int>
    ## 1     0

### Demographic Summary

Analyze patient demographics:

``` r
demographics <- cdm$person |>
  summarise(
    total_patients = n(),
    avg_age = mean(year_of_birth, na.rm = TRUE),
    distinct_genders = n_distinct(gender_concept_id)
  ) |>
  collect()
```

### Exploring Clinical Events

Examine observation periods or clinical tables:

``` r
observation_summary <- cdm$observation_period |>
  group_by(person_id) |>
  summarise(
    count = n(),
    avg_duration = mean(observation_period_end_date - observation_period_start_date, na.rm = TRUE)
  ) |>
  arrange(desc(count)) |>
  collect()
```

For a full OMOP CDM, you would examine condition occurrences and drug
exposures similarly.

### Temporal Patterns

Analyze observation periods over time:

``` r
monthly_observations <- cdm$observation_period |>
  mutate(month = floor_date(observation_period_start_date, "month")) |>
  group_by(month) |>
  summarise(observation_count = n()) |>
  collect()
```

This exploratory data analysis provides insights into data quality,
completeness, and patterns in your OMOP database.

## 3. Identifying Patient Characteristics

> **Why Patient Characteristics Matter:** In observational research,
> understanding patient characteristics (demographics, comorbidities,
> medication history) is crucial for confounding control and
> generalizability. These features help ensure study groups are
> comparable and results are interpretable.

### Calculating Age at Observation Start

Join person and observation_period tables to find when patients were
first observed:

``` r
age_at_observation <- cdm$observation_period |>
  inner_join(cdm$person, by = "person_id") |>
  group_by(person_id) |>
  summarise(
    first_observation = min(observation_period_start_date),
    birth_year = first(year_of_birth)
  ) |>
  mutate(age_at_observation = year(first_observation) - birth_year) |>
  collect()
```

    ## Warning: There was 1 warning in `dplyr::summarise()`.
    ## ℹ In argument: `first_observation = min(observation_period_start_date)`.
    ## Caused by warning in `min.default()`:
    ## ! no non-missing arguments to min; returning Inf

> **Clinical Insight:** Calculating age at first observation helps
> understand the age distribution of patients in your database, which is
> important for study design and generalizability.

### Identifying Comorbidities & Observation History

Find patients with observation periods (as a proxy for clinical
activity):

``` r
observation_activity <- cdm$observation_period |>
  group_by(person_id) |>
  summarise(
    observation_count = n(),
    total_observation_days = sum(observation_period_end_date - observation_period_start_date)
  ) |>
  collect()
```

> **Clinical Insight:** Observation periods indicate the time patients
> are actively followed in the database, which affects the completeness
> of their clinical history.

### Using CohortCharacteristics for Standardized Summaries

Instead of manual joins, use the `CohortCharacteristics` package for
standardized, reproducible summaries.

``` r
library(CohortCharacteristics)

# First create a cohort
cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "diabetes",
  conceptSet = list("type_2_diabetes" = 201826),
  end = "observation_period_end_date",
  limit = "first"
)

# Summarize characteristics of the diabetes cohort
characteristics <- cdm$diabetes |>
  summariseCharacteristics(
    ageGroup = list(c(0, 17), c(18, 64), c(65, 999)),
    gender = TRUE,
    priorObservation = TRUE
  ) |>
  collect()
```

> **Why CohortCharacteristics?** This package provides standardized
> summaries that are consistent across studies, making results more
> comparable and reducing errors.

### Creating a Patient Feature Dataset

Combine multiple characteristics:

``` r
patient_features <- cdm$person |>
  left_join(
    cdm$observation_period |>
      group_by(person_id) |>
      summarise(observation_count = n()),
    by = "person_id"
  ) |>
  mutate(
    age = 2023 - year_of_birth,  # Assuming current year
    has_observations = observation_count > 0
  ) |>
  collect()
```

These techniques allow you to create rich feature sets for analysis or
modeling.

## 4. Adding Cohorts to the CDM

``` r
library(CodelistGenerator)
library(CohortConstructor)
```

### Creating Codelists with CodelistGenerator

Define clinical concepts:

``` r
# Get concepts for Gender
gender_codes <- getDescendants(cdm, 8507)  # MALE concept

# Note: In a full OMOP CDM, you would use concept names or IDs for clinical conditions
```

### Generating Cohorts with CohortConstructor

Create cohorts using concept sets:

``` r
cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "diabetes",
  conceptSet = list("type_2_diabetes" = diabetes_codes),
  end = "observation_period_end_date",
  limit = "first"
)
```

Create a medication user cohort:

``` r
cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "metformin_users",
  conceptSet = list("metformin" = metformin_codes),
  end = "observation_period_end_date",
  limit = "first"
)
```

### Advanced Cohort Definitions

Combine multiple criteria:

``` r
# Patients with diabetes who started metformin within 1 year of diagnosis
cdm <- generateCohortSet(
  cdm = cdm,
  name = "diabetes_metformin",
  cohortSet = data.frame(
    cohort_definition_id = 1,
    cohort_name = "Diabetes with Metformin",
    # Define cohort entry criteria here
  )
)
```

### Validating Cohorts

Check cohort characteristics:

``` r
cohort_summary <- cdm$diabetes |>
  summarise(
    cohort_size = n(),
    avg_index_age = mean(year(cohort_start_date) - year_of_birth, na.rm = TRUE)
  ) |>
  collect()
```

These tools automate complex cohort creation, ensuring reproducibility
and accuracy.

## 5. Working with Cohorts

### Characterizing Cohort Members

Join cohort with person data:

``` r
cohort_characteristics <- cdm$diabetes |>
  inner_join(cdm$person, by = c("subject_id" = "person_id")) |>
  summarise(
    total_patients = n(),
    avg_age = mean(2023 - year_of_birth, na.rm = TRUE),
    distinct_genders = n_distinct(gender_concept_id)
  ) |>
  collect()
```

### Comparing Cohorts

Compare diabetes cohort to general population:

``` r
diabetes_vs_general <- bind_rows(
  cdm$diabetes |>
    inner_join(cdm$person, by = c("subject_id" = "person_id")) |>
    mutate(group = "diabetes"),
  cdm$person |>
    anti_join(cdm$diabetes, by = c("person_id" = "subject_id")) |>
    mutate(group = "general")
) |>
  group_by(group) |>
  summarise(avg_age = mean(2023 - year_of_birth, na.rm = TRUE)) |>
  collect()
```

### Analyzing Outcomes Over Time

Track outcomes after cohort entry:

``` r
post_cohort_outcomes <- cdm$diabetes |>
  left_join(cdm$condition_occurrence, by = c("subject_id" = "person_id")) |>
  filter(condition_start_date >= cohort_start_date) |>
  group_by(subject_id) |>
  summarise(
    follow_up_conditions = n(),
    time_to_first_condition = min(condition_start_date - cohort_start_date, na.rm = TRUE)
  ) |>
  collect()
```

### Building Study Datasets

Create analysis-ready datasets:

``` r
study_dataset <- cdm$diabetes |>
  left_join(cdm$person, by = c("subject_id" = "person_id")) |>
  left_join(
    cdm$condition_occurrence |>
      filter(condition_start_date <= cohort_start_date) |>
      group_by(person_id) |>
      summarise(pre_cohort_conditions = n()),
    by = c("subject_id" = "person_id")
  ) |>
  mutate(
    age_at_entry = year(cohort_start_date) - year_of_birth,
    has_comorbidities = pre_cohort_conditions > 0
  ) |>
  select(subject_id, cohort_start_date, age_at_entry, gender_concept_id, has_comorbidities) |>
  collect()
```

This workflow forms the foundation for comparative effectiveness
research, population-level epidemiology, and patient-level prediction
studies.

## 6. Applying Tidyverse Principles to the OMOP CDM

While the principles of `dbplyr` and `dplyr` are powerful for any
database, the OHDSI and DARWIN EU communities have developed a suite of
R packages that build on this foundation to provide a seamless
experience for working with the OMOP CDM.

### `compute()` vs. `collect()`: Working in the Database

A key concept when working with database-backed data is the difference
between `collect()` and `compute()`.

- `collect()`: This function pulls data **out of the database** and into
  an R data frame in your computer’s memory. You should only use this on
  small, aggregated result sets that you need for visualization or local
  modeling.
- `compute()`: This function executes the query steps you’ve defined and
  saves the result as a **new table in the database**. This is essential
  for multi-step analyses, allowing you to build intermediate datasets
  without ever leaving the database, which is far more efficient.

### End-to-End Workflow Example

``` r
# 1. Connect to CDM
cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "scratch")

# 2. Extract codelist
diabetes_codes <- getDescendants(cdm, "Type 2 diabetes mellitus")

# 3. Generate cohort
cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "diabetes",
  conceptSet = list("type_2_diabetes" = diabetes_codes),
  end = "observation_period_end_date",
  limit = "first"
)

# 4. Characterize and collect summary
cohort_demographics <- cdm$diabetes |>
  inner_join(cdm$person, by = c("subject_id" = "person_id")) |>
  select("subject_id", "cohort_start_date", "gender_concept_id", "year_of_birth") |>
  mutate(age_at_diagnosis = year(cohort_start_date) - year_of_birth) |>
  collect()
```

## 7. Glossary of Key Terms

- **Cohort:** A defined group of patients who meet specific
  inclusion/exclusion criteria for a study.
- **Concept ID:** A standardized numeric identifier for medical terms in
  the OMOP vocabulary.
- **Domain:** The category of a concept (e.g., Condition, Drug,
  Measurement).
- **Index Date:** The date that defines cohort entry (e.g., first
  diagnosis date).
- **Incidence:** The rate of new cases of a condition in a population
  over time.
- **Prevalence:** The proportion of a population with a condition at a
  specific point in time.
- **Washout Period:** A time period before cohort entry to ensure
  patients are “new” to treatment or condition.
- **Vocabulary:** A controlled set of terms used to standardize medical
  concepts across different data sources.

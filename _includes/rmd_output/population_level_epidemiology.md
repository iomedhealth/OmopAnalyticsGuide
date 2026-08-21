
The OHDSI
[`IncidencePrevalence`](/docs/data_analysis/package_reference/IncidencePrevalence)
R package is designed to calculate population-level incidence and
prevalence rates from OMOP CDM data, directly addressing the core
analytical requirements of this study design.

At a high level, IncidencePrevalence turns OMOP CDM cohorts into tidy,
stratified summaries by repeatedly applying three ideas:

- **Denominator time:** People contribute at-risk time only when they
  meet the study rules you set with
  `generateDenominatorCohortSet()`/`generateTargetDenominatorCohortSet()`.
  Entry is the latest of study start, prior observation met, and minimum
  age; exit is the earliest of study end, observation end, and age upper
  limit.
- **Outcome overlap:** Outcomes are read from a separate cohort table
  you prepare (here provided by `mockIncidencePrevalence()`). Prevalence
  checks whether a person is in the outcome cohort at a time point/over
  an interval; incidence counts first qualifying onsets, respecting
  washout and repeated event rules.
- **Interval slicing:** The study time is cut into calendar intervals
  (years, quarters, months). Each interval gets its own denominator,
  outcome counts, and derived measures.

### Key computations and arguments

- **Point prevalence (`estimatePointPrevalence`):**
  - **What:** proportion with the outcome at a time point inside each
    interval.
  - **How:** outcome presence on the chosen `timePoint`
    (“start”/“middle”/“end”) among those in the denominator at that
    date.
  - **Tip:** Use when you want a snapshot at a consistent anchor within
    each interval.
- **Period prevalence (`estimatePeriodPrevalence`):**
  - **What:** proportion with the outcome at any time during the
    interval.
  - **How:** outcome occurs at any day overlapping the interval;
    denominator includes those present during the interval.
  - `fullContribution`: if `TRUE`, only people observed for the entire
    interval count in the denominator; if `FALSE`, anyone observed for
    ≥1 day counts.
  - **Tip:** Choose `fullContribution` based on whether incomplete
    observation could bias proportions for long intervals.
- **Incidence (`estimateIncidence`):**
  - **What:** new-onset rates per person-time in each interval.
  - **How:** counts qualifying outcome onsets and divides by person-time
    contributed in the denominator.
  - `outcomeWashout`: requires no outcome in the prior N days; use `Inf`
    to ensure first-ever incidence.
  - `repeatedEvents`: if `TRUE`, allows multiple incident events per
    person separated by washout; if `FALSE`, at most one incident event
    per person.
  - `completeDatabaseIntervals`: if `TRUE`, drops intervals where the
    database cannot establish full observation coverage (e.g.,
    first/last years with partial data), reducing edge bias.

### Stratification and groups

- **Groups:** Each combination of denominator settings (age group, sex,
  prior history, time-at-risk windows, target-based subsets) becomes a
  separate `cohort_definition_id` and produces separate rows.
- **Strata:** You can facet/colour or summarize by variables such as
  `denominator_age_group`, `denominator_sex`, etc. Use
  `plotIncidence()`/`plotPrevalence()` helpers and
  `available...Grouping()` to see valid aesthetics.

### Outputs

- **Summarised results:** Functions return a “summarised_result” tables
  with `estimate_name`/`value` pairs, plus additional metadata
  (start/end dates, interval type). These are directly consumable by
  `visOmopResults` to `tableIncidence`/`tablePrevalence` and plot
  functions.

## Practical guidance

- Pick intervals aligned to your question and data density (years for
  long-term trends, months for seasonality).
- Use `outcomeWashout` and `repeatedEvents` to encode “first-ever”
  vs. “episode-based” incidence.
- Prefer `completeDatabaseIntervals` (incidence) and consider
  `fullContribution` (period prevalence) when edge effects or
  intermittent observation could bias estimates.
- Keep exclusion logic out of outcome cohorts; define restrictions on
  the denominator instead.

Our workflow will follow a simple, powerful pattern common across OHDSI
packages: **`summarise -> table/plot`**.

### Step 1: Load Libraries & Connect to the GiBleed Database

First, we load the necessary libraries. `CDMConnector` provides the
connection to the OMOP CDM database, `CohortConstructor` builds clinical
cohorts from standard OMOP concepts, `IncidencePrevalence` calculates
population-level epidemiology rates, and `visOmopResults` formats the
results into publication-ready tables and plots.

We connect to the standardized Eunomia **GiBleed** dataset using DuckDB:

``` r
library(CDMConnector)
library(CohortConstructor)
library(IncidencePrevalence)
library(visOmopResults)
library(dplyr)
```

``` r
# Ensure GiBleed dataset is available and connect via DuckDB
Sys.setenv(EUNOMIA_DATA_FOLDER = Sys.getenv("EUNOMIA_DATA_FOLDER", tempdir()))
if (!eunomiaIsAvailable("GiBleed")) {
  downloadEunomiaData("GiBleed")
}

con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("GiBleed"))
cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")
```

### Step 2: Define Outcome and Denominator Cohorts

In this study, our outcome of interest is **Gastrointestinal
Hemorrhage** (`concept_id = 192671`). We instantiate the outcome cohort
directly from the OMOP CDM condition table:

``` r
# Create the gastrointestinal hemorrhage outcome cohort
cdm$outcome <- conceptCohort(
  cdm = cdm,
  conceptSet = list(gi_bleed = 192671L),
  name = "outcome"
)
```

Next, we define our source study population (the denominator). We will
study the population observed between 2010 and 2019, stratifying by age
groups (0–49 and 50–100) and by sex:

``` r
# Define the denominator cohort for the study period
cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = "denominator",
  cohortDateRange = as.Date(c("2010-01-01", "2019-01-01")),
  ageGroup = list(
    c(0, 49),
    c(50, 100)
  ),
  sex = c("Male", "Female")
)
```

### Step 3: Calculate Incidence & Prevalence (The `summarise` Step)

This step calculates incidence and prevalence rates across the defined
strata.

#### 3.1: Estimate Incidence

We calculate annual incidence rates for gastrointestinal hemorrhage. We
set `outcomeWashout = Inf` to include only first-ever occurrences and
`repeatedEvents = FALSE`. We then visualize the results with
`plotIncidence()` and generate a structured table with
`tableIncidence()`:

``` r
# Calculate annual incidence rates
inc <- estimateIncidence(
  cdm = cdm,
  denominatorTable = "denominator",
  outcomeTable = "outcome",
  interval = "years",
  outcomeWashout = Inf,
  repeatedEvents = FALSE
)

# Plot incidence rates faceted by age group and colored by sex
plotIncidence(inc, facet = "denominator_age_group", colour = "denominator_sex")
```

![](/assets/images/rmd_output/calculate_incidence_and_plot-1.png)<!-- -->

``` r
# Display concise 5-year recent trend table
inc |>
  filterAdditional(incidence_start_date >= as.Date("2014-01-01")) |>
  tableIncidence()
```

<div id="swfdptqwfw" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#swfdptqwfw table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#swfdptqwfw thead, #swfdptqwfw tbody, #swfdptqwfw tfoot, #swfdptqwfw tr, #swfdptqwfw td, #swfdptqwfw th {
  border-style: none;
}
&#10;#swfdptqwfw p {
  margin: 0;
  padding: 0;
}
&#10;#swfdptqwfw .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-right-style: solid;
  border-right-width: 3px;
  border-right-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 3px;
  border-bottom-color: #D9D9D9;
  border-left-style: solid;
  border-left-width: 3px;
  border-left-color: #D9D9D9;
}
&#10;#swfdptqwfw .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#swfdptqwfw .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#swfdptqwfw .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#swfdptqwfw .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#swfdptqwfw .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#swfdptqwfw .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#swfdptqwfw .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#swfdptqwfw .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#swfdptqwfw .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#swfdptqwfw .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#swfdptqwfw .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#swfdptqwfw .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#swfdptqwfw .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#swfdptqwfw .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#swfdptqwfw .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#swfdptqwfw .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#swfdptqwfw .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#swfdptqwfw .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#swfdptqwfw .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#swfdptqwfw .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#swfdptqwfw .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#swfdptqwfw .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#swfdptqwfw .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#swfdptqwfw .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#swfdptqwfw .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#swfdptqwfw .gt_left {
  text-align: left;
}
&#10;#swfdptqwfw .gt_center {
  text-align: center;
}
&#10;#swfdptqwfw .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#swfdptqwfw .gt_font_normal {
  font-weight: normal;
}
&#10;#swfdptqwfw .gt_font_bold {
  font-weight: bold;
}
&#10;#swfdptqwfw .gt_font_italic {
  font-style: italic;
}
&#10;#swfdptqwfw .gt_super {
  font-size: 65%;
}
&#10;#swfdptqwfw .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#swfdptqwfw .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#swfdptqwfw .gt_indent_1 {
  text-indent: 5px;
}
&#10;#swfdptqwfw .gt_indent_2 {
  text-indent: 10px;
}
&#10;#swfdptqwfw .gt_indent_3 {
  text-indent: 15px;
}
&#10;#swfdptqwfw .gt_indent_4 {
  text-indent: 20px;
}
&#10;#swfdptqwfw .gt_indent_5 {
  text-indent: 25px;
}
&#10;#swfdptqwfw .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#swfdptqwfw div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Incidence-start-date">Incidence start date</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Incidence-end-date">Incidence end date</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Denominator-age-group">Denominator age group</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Denominator-sex">Denominator sex</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="4" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]Estimate name&#10;[header_level]Denominator (N)">
        <div class="gt_column_spanner">Estimate name</div>
      </th>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Denominator-(N)">Denominator (N)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Person-years">Person-years</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Outcome-(N)">Outcome (N)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Incidence-100,000-person-years-[95%-CI]">Incidence 100,000 person-years [95% CI]</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr class="gt_group_heading_row">
      <th colspan="8" class="gt_group_heading" style="background-color: #E9E9E9; font-family: Arial; font-size: 10; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="Synthea; gi_bleed">Synthea; gi_bleed</th>
    </tr>
    <tr class="gt_row_group_first"><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">510</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">498.47</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">6</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1,203.68 (441.73 -
      2,619.90)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">487</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">469.42</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">4</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">852.12 (232.17 -
      2,181.76)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">450</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">433.06</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">5</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1,154.57 (374.88 -
      2,694.38)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">413</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">375.99</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">8</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">2,127.72 (918.60 -
      4,192.46)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">324</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">237.49</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">5</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">2,105.38 (683.61 -
      4,913.25)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">477</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">459.10</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">3</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">653.45 (134.76 -
      1,909.66)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">441</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">425.36</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">8</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1,880.75 (811.97 -
      3,705.82)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">410</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">390.78</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">4</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1,023.59 (278.89 -
      2,620.79)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">371</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">334.98</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">9</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">2,686.76 (1,228.56 -
      5,100.31)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">280</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">190.53</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">5</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">2,624.26 (852.09 -
      6,124.14)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">583</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">573.66</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      643.04)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">614</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">595.25</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      619.72)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">635</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">622.14</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      592.94)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">658</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">643.15</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      573.56)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">674</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">591.38</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      623.78)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">598</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">575.42</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      641.07)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">610</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">595.87</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      619.08)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">634</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">619.35</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      595.61)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">656</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">638.86</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      577.41)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Incidence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Incidence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-12-31</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">683</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Person-years" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">593.91</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Incidence 100,000 person-years [95% CI]" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 -
      621.12)</td></tr>
  </tbody>
  &#10;</table>
</div>

#### 3.2: Estimate Point Prevalence

Next, we estimate annual point prevalence at the start of each year
(`timePoint = "start"`):

``` r
# Calculate annual point prevalence
prev_point <- estimatePointPrevalence(
  cdm = cdm,
  denominatorTable = "denominator",
  outcomeTable = "outcome",
  interval = "years",
  timePoint = "start"
)

# Plot point prevalence faceted by age group and colored by sex
plotPrevalence(prev_point, facet = "denominator_age_group", colour = "denominator_sex")
```

![](/assets/images/rmd_output/calculate_prevalence_and_plot-1.png)<!-- -->

``` r
# Display concise 5-year recent trend table
prev_point |>
  filterAdditional(prevalence_start_date >= as.Date("2014-01-01")) |>
  tablePrevalence()
```

<div id="ofqmfzughe" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#ofqmfzughe table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#ofqmfzughe thead, #ofqmfzughe tbody, #ofqmfzughe tfoot, #ofqmfzughe tr, #ofqmfzughe td, #ofqmfzughe th {
  border-style: none;
}
&#10;#ofqmfzughe p {
  margin: 0;
  padding: 0;
}
&#10;#ofqmfzughe .gt_table {
  display: table;
  border-collapse: collapse;
  line-height: normal;
  margin-left: auto;
  margin-right: auto;
  color: #333333;
  font-size: 16px;
  font-weight: normal;
  font-style: normal;
  background-color: #FFFFFF;
  width: auto;
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-right-style: solid;
  border-right-width: 3px;
  border-right-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 3px;
  border-bottom-color: #D9D9D9;
  border-left-style: solid;
  border-left-width: 3px;
  border-left-color: #D9D9D9;
}
&#10;#ofqmfzughe .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#ofqmfzughe .gt_title {
  color: #333333;
  font-size: 125%;
  font-weight: initial;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-color: #FFFFFF;
  border-bottom-width: 0;
}
&#10;#ofqmfzughe .gt_subtitle {
  color: #333333;
  font-size: 85%;
  font-weight: initial;
  padding-top: 3px;
  padding-bottom: 5px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-color: #FFFFFF;
  border-top-width: 0;
}
&#10;#ofqmfzughe .gt_heading {
  background-color: #FFFFFF;
  text-align: center;
  border-bottom-color: #FFFFFF;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_col_headings {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_col_heading {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 6px;
  padding-left: 5px;
  padding-right: 5px;
  overflow-x: hidden;
}
&#10;#ofqmfzughe .gt_column_spanner_outer {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: normal;
  text-transform: inherit;
  padding-top: 0;
  padding-bottom: 0;
  padding-left: 4px;
  padding-right: 4px;
}
&#10;#ofqmfzughe .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#ofqmfzughe .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#ofqmfzughe .gt_column_spanner {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: bottom;
  padding-top: 5px;
  padding-bottom: 5px;
  overflow-x: hidden;
  display: inline-block;
  width: 100%;
}
&#10;#ofqmfzughe .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#ofqmfzughe .gt_group_heading {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  text-align: left;
}
&#10;#ofqmfzughe .gt_empty_group_heading {
  padding: 0.5px;
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  vertical-align: middle;
}
&#10;#ofqmfzughe .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#ofqmfzughe .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#ofqmfzughe .gt_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  margin: 10px;
  border-top-style: solid;
  border-top-width: 1px;
  border-top-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 1px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 1px;
  border-right-color: #D3D3D3;
  vertical-align: middle;
  overflow-x: hidden;
}
&#10;#ofqmfzughe .gt_stub {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ofqmfzughe .gt_stub_row_group {
  color: #333333;
  background-color: #FFFFFF;
  font-size: 100%;
  font-weight: initial;
  text-transform: inherit;
  border-right-style: solid;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  padding-left: 5px;
  padding-right: 5px;
  vertical-align: top;
}
&#10;#ofqmfzughe .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#ofqmfzughe .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#ofqmfzughe .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ofqmfzughe .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#ofqmfzughe .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ofqmfzughe .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#ofqmfzughe .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_footnotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ofqmfzughe .gt_sourcenotes {
  color: #333333;
  background-color: #FFFFFF;
  border-bottom-style: none;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
}
&#10;#ofqmfzughe .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ofqmfzughe .gt_left {
  text-align: left;
}
&#10;#ofqmfzughe .gt_center {
  text-align: center;
}
&#10;#ofqmfzughe .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#ofqmfzughe .gt_font_normal {
  font-weight: normal;
}
&#10;#ofqmfzughe .gt_font_bold {
  font-weight: bold;
}
&#10;#ofqmfzughe .gt_font_italic {
  font-style: italic;
}
&#10;#ofqmfzughe .gt_super {
  font-size: 65%;
}
&#10;#ofqmfzughe .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#ofqmfzughe .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#ofqmfzughe .gt_indent_1 {
  text-indent: 5px;
}
&#10;#ofqmfzughe .gt_indent_2 {
  text-indent: 10px;
}
&#10;#ofqmfzughe .gt_indent_3 {
  text-indent: 15px;
}
&#10;#ofqmfzughe .gt_indent_4 {
  text-indent: 20px;
}
&#10;#ofqmfzughe .gt_indent_5 {
  text-indent: 25px;
}
&#10;#ofqmfzughe .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#ofqmfzughe div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Prevalence-start-date">Prevalence start date</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Prevalence-end-date">Prevalence end date</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Denominator-age-group">Denominator age group</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Denominator-sex">Denominator sex</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="3" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]Estimate name&#10;[header_level]Denominator (N)">
        <div class="gt_column_spanner">Estimate name</div>
      </th>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Denominator-(N)">Denominator (N)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Outcome-(N)">Outcome (N)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Estimate-name-[header_level]Prevalence-[95%-CI]">Prevalence [95% CI]</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr class="gt_group_heading_row">
      <th colspan="7" class="gt_group_heading" style="background-color: #E9E9E9; font-family: Arial; font-size: 10; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="Synthea; gi_bleed">Synthea; gi_bleed</th>
    </tr>
    <tr class="gt_row_group_first"><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">581</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">554</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">516</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">475</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">377</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">156</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.02)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">549</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">510</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">480</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">442</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">338</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 to 49</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">127</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.03)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">683</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">708</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">739</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">770</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.00)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">798</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.00)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">482</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2014-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">681</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2015-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">707</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2016-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">730</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2017-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">756</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2018-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">783</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.00)</td></tr>
    <tr><td headers="Synthea; gi_bleed  Prevalence start date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Prevalence end date" class="gt_row gt_right" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2019-01-01</td>
<td headers="Synthea; gi_bleed  Denominator age group" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">50 to 100</td>
<td headers="Synthea; gi_bleed  Denominator sex" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Denominator (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">456</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Outcome (N)" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; gi_bleed  [header_name]Estimate name
[header_level]Prevalence [95% CI]" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0.00 (0.00 - 0.01)</td></tr>
  </tbody>
  &#10;</table>
</div>


The
[`CohortEconomics`](/docs/data_analysis/package_reference/CohortEconomics),
[`CohortUtilisation`](/docs/data_analysis/package_reference/CohortUtilisation),
and [`CohortCosts`](/docs/data_analysis/package_reference/CohortCosts)
packages provide an end-to-end analytical framework for Health Economics
and Outcomes Research (HEOR), Healthcare Resource Utilisation (HCRU)
evaluation, and Health Technology Assessment (HTA) decision-analytic
modeling directly from OMOP CDM databases.

## How the 6-Stage HEOR Pipeline Works

1.  **Study Initialisation & Baseline Characterisation**: Defines
    comparative intervention arms and extracts demographic profiles.
2.  **HCRU Extraction**: Measures encounter rates and lengths of stay
    across inpatient admissions, emergency visits, outpatient
    consultations, pharmacotherapy, and procedures.
3.  **Causal Propensity Score Adjustment**: Adjusts for confounding by
    indication via regularized logistic regression and greedy caliper
    matching.
4.  **Trajectory Compilation**: Translates longitudinal patient clinical
    journeys into discrete Markov state-transition matrices.
5.  **Economic Simulation (Markov PSA)**: Executes probabilistic
    sensitivity analysis sampling Gamma cost distributions and Beta
    health state utility weights over a defined time horizon.
6.  **Decision Analysis (CEA)**: Estimates the Incremental
    Cost-Effectiveness Ratio (ICER), Net Monetary Benefit (NMB),
    Cost-Effectiveness Acceptability Curves (CEAC), and
    Cost-Effectiveness Planes.

## Step 1: Setup & Connect to GiBleed

Load the necessary libraries and establish a connection to the Eunomia
**GiBleed** dataset using DuckDB:

``` r
library(CohortEconomics)
library(CohortUtilisation)
library(CohortCosts)
library(CDMConnector)
library(CohortConstructor)
library(dplyr)
library(gt)
library(ggplot2)
```

``` r
# Connect to Eunomia GiBleed dataset
Sys.setenv(EUNOMIA_DATA_FOLDER = Sys.getenv("EUNOMIA_DATA_FOLDER", tempdir()))
if (!eunomiaIsAvailable("GiBleed")) {
  downloadEunomiaData("GiBleed")
}
```

    ## 
    ## Download completed!

``` r
con <- DBI::dbConnect(duckdb::duckdb(), eunomiaDir("GiBleed"))
cdm <- cdmFromCon(con, cdmSchema = "main", writeSchema = "main")
```

## Step 2: Define Target, Comparator, and Safety Outcome Cohorts

We instantiate new users of **Celecoxib** (`concept_id = 1118084`) as
the target intervention, new users of **Diclofenac**
(`concept_id = 1124300`) as the active comparator, and incident
**Gastrointestinal Hemorrhage** (`concept_id = 192671`) as the primary
health economic outcome:

``` r
# Target Cohort: Celecoxib new users
cdm$target_cohort <- conceptCohort(
  cdm = cdm,
  conceptSet = list(celecoxib = 1118084L),
  name = "target_cohort"
) |>
  requireIsFirstEntry()

# Comparator Cohort: Diclofenac new users
cdm$comparator_cohort <- conceptCohort(
  cdm = cdm,
  conceptSet = list(diclofenac = 1124300L),
  name = "comparator_cohort"
) |>
  requireIsFirstEntry()

# Outcome Cohort: Gastrointestinal Hemorrhage
cdm$outcome_cohort <- conceptCohort(
  cdm = cdm,
  conceptSet = list(gi_bleed = 192671L),
  name = "outcome_cohort"
)
```

## Step 3: Baseline Characterisation & HCRU Extraction

We initialize the study, characterize baseline demographics, and extract
longitudinal healthcare resource utilization across baseline
($[-365, -1]$ days) and follow-up ($[0, 365]$ days) windows:

``` r
# Initialize HEOR study and extract HCRU
study <- init(
  cdm = cdm,
  target_cohort = "target_cohort",
  comparator_cohort = "comparator_cohort",
  outcome_cohort = "outcome_cohort"
) |>
  summarise_baseline() |>
  extract_hcru(
    baseline_window = c(-365, -1),
    followup_window = c(0, 365)
  )

# Summarise per-patient resource utilization rates
hcru_summary <- study$hcru$patient_summary |>
  group_by(window) |>
  summarise(
    Mean_Inpatient_Admissions = round(mean(inpatient_admissions), 2),
    Mean_Inpatient_LOS_Days = round(mean(inpatient_los_days), 2),
    Mean_Prescription_Fills = round(mean(prescription_fills), 2),
    Mean_Procedure_Count = round(mean(procedure_count), 2),
    .groups = "drop"
  )

hcru_summary |>
  gt() |>
  tab_header(
    title = "Healthcare Resource Utilisation (HCRU) Summary",
    subtitle = "Resource Consumption Across Baseline vs Follow-up Windows"
  ) |>
  cols_label(
    window = "Observation Window",
    Mean_Inpatient_Admissions = "Inpatient Admissions (Mean)",
    Mean_Inpatient_LOS_Days = "Length of Stay Days (Mean)",
    Mean_Prescription_Fills = "Prescription Fills (Mean)",
    Mean_Procedure_Count = "Procedures & Tests (Mean)"
  )
```

<div id="sawgovdpen" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#sawgovdpen table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#sawgovdpen thead, #sawgovdpen tbody, #sawgovdpen tfoot, #sawgovdpen tr, #sawgovdpen td, #sawgovdpen th {
  border-style: none;
}
&#10;#sawgovdpen p {
  margin: 0;
  padding: 0;
}
&#10;#sawgovdpen .gt_table {
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
  border-top-width: 2px;
  border-top-color: #A8A8A8;
  border-right-style: none;
  border-right-width: 2px;
  border-right-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #A8A8A8;
  border-left-style: none;
  border-left-width: 2px;
  border-left-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#sawgovdpen .gt_title {
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
&#10;#sawgovdpen .gt_subtitle {
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
&#10;#sawgovdpen .gt_heading {
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
&#10;#sawgovdpen .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_col_headings {
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
&#10;#sawgovdpen .gt_col_heading {
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
&#10;#sawgovdpen .gt_column_spanner_outer {
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
&#10;#sawgovdpen .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#sawgovdpen .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#sawgovdpen .gt_column_spanner {
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
&#10;#sawgovdpen .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#sawgovdpen .gt_group_heading {
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
&#10;#sawgovdpen .gt_empty_group_heading {
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
&#10;#sawgovdpen .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#sawgovdpen .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#sawgovdpen .gt_row {
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
&#10;#sawgovdpen .gt_stub {
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
&#10;#sawgovdpen .gt_stub_row_group {
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
&#10;#sawgovdpen .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#sawgovdpen .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#sawgovdpen .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sawgovdpen .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#sawgovdpen .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sawgovdpen .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#sawgovdpen .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#sawgovdpen .gt_footnotes {
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
&#10;#sawgovdpen .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sawgovdpen .gt_sourcenotes {
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
&#10;#sawgovdpen .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#sawgovdpen .gt_left {
  text-align: left;
}
&#10;#sawgovdpen .gt_center {
  text-align: center;
}
&#10;#sawgovdpen .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#sawgovdpen .gt_font_normal {
  font-weight: normal;
}
&#10;#sawgovdpen .gt_font_bold {
  font-weight: bold;
}
&#10;#sawgovdpen .gt_font_italic {
  font-style: italic;
}
&#10;#sawgovdpen .gt_super {
  font-size: 65%;
}
&#10;#sawgovdpen .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#sawgovdpen .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#sawgovdpen .gt_indent_1 {
  text-indent: 5px;
}
&#10;#sawgovdpen .gt_indent_2 {
  text-indent: 10px;
}
&#10;#sawgovdpen .gt_indent_3 {
  text-indent: 15px;
}
&#10;#sawgovdpen .gt_indent_4 {
  text-indent: 20px;
}
&#10;#sawgovdpen .gt_indent_5 {
  text-indent: 25px;
}
&#10;#sawgovdpen .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#sawgovdpen div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_title gt_font_normal" style>Healthcare Resource Utilisation (HCRU) Summary</td>
    </tr>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Resource Consumption Across Baseline vs Follow-up Windows</td>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="window">Observation Window</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Mean_Inpatient_Admissions">Inpatient Admissions (Mean)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Mean_Inpatient_LOS_Days">Length of Stay Days (Mean)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Mean_Prescription_Fills">Prescription Fills (Mean)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Mean_Procedure_Count">Procedures &amp; Tests (Mean)</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="window" class="gt_row gt_left">baseline</td>
<td headers="Mean_Inpatient_Admissions" class="gt_row gt_right">0.00</td>
<td headers="Mean_Inpatient_LOS_Days" class="gt_row gt_right">0.00</td>
<td headers="Mean_Prescription_Fills" class="gt_row gt_right">0.33</td>
<td headers="Mean_Procedure_Count" class="gt_row gt_right">0.21</td></tr>
    <tr><td headers="window" class="gt_row gt_left">followup</td>
<td headers="Mean_Inpatient_Admissions" class="gt_row gt_right">0.19</td>
<td headers="Mean_Inpatient_LOS_Days" class="gt_row gt_right">0.19</td>
<td headers="Mean_Prescription_Fills" class="gt_row gt_right">1.35</td>
<td headers="Mean_Procedure_Count" class="gt_row gt_right">0.21</td></tr>
  </tbody>
  &#10;</table>
</div>

## Step 4: Causal Propensity Score Matching & Trajectory Compilation

We fit a regularized logistic regression propensity score model, perform
1:1 nearest-neighbor matching, and compile Markov state-transition
probability matrices:

``` r
# Causal propensity score adjustment and discrete trajectory modeling
study <- study |>
  fit_ps() |>
  adjust_ps(caliper = 0.2) |>
  compile_trajectories()

# Assign parametric state-specific unit costs (Baseline maintenance vs GI Bleed event)
study$costs <- data.frame(
  health_state = c("State_Baseline", "State_Outcome"),
  mean_cost = c(450, 4800),
  se_cost = c(40, 350)
)
```

## Step 5: Economic Simulation (Markov PSA) & Cost-Effectiveness Analysis

We execute a 10-year Monte Carlo Probabilistic Sensitivity Analysis
(PSA) with 3% annual discounting, followed by decision analysis:

``` r
# Execute Probabilistic Sensitivity Analysis simulation
sim <- simulate_economics(
  traj_obj = study,
  time_horizon = 10,
  discount_rate = 0.03,
  n_samples = 250
)

# Run Cost-Effectiveness Decision Analysis
cea <- run_cea(sim)
```

## Step 6: HTA Decision Plots (CEAC & Cost-Effectiveness Plane)

We generate the Cost-Effectiveness Acceptability Curve (CEAC) showing
the probability of cost-effectiveness across Willingness-to-Pay
thresholds, and the Cost-Effectiveness Plane:

``` r
# Plot Cost-Effectiveness Acceptability Curve (CEAC)
plot_ceac(cea)
```

![](/assets/images/rmd_output/plot-ceac-1.png)<!-- -->

``` r
# Plot Cost-Effectiveness Plane
plot_plane(cea)
```

![](/assets/images/rmd_output/plot-plane-1.png)<!-- -->

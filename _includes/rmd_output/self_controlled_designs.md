
Self-Controlled Designs—including the **Self-Controlled Case Series
(SCCS)** and the **Self-Controlled Case Risk Interval (SCRI)**—are a
class of observational study designs where individuals serve as their
own control. By comparing risk within the same person across exposed and
unexposed time windows, all time-invariant confounders (e.g. genetics,
chronic comorbidities, and socioeconomic factors) are implicitly
controlled.

## How Self-Controlled Designs Work

- **Case-Only Population**: Analysis is restricted to patients who
  experienced the acute outcome of interest.
- **Risk vs. Control Intervals**: Follow-up time for each individual is
  partitioned into pre-specified risk windows (e.g., 1–30 days
  post-exposure) and unexposed control windows (e.g., pre-exposure or
  distal post-exposure periods).
- **Conditional Poisson / Risk Comparison**: Within-individual
  regression models compare the event rate during the risk window to
  that during the control window to derive the **Incidence Rate Ratio
  (IRR)**.

## Step 1: Setup & Connect to GiBleed

Load the necessary libraries and establish a connection to the Eunomia
**GiBleed** dataset using DuckDB:

``` r
library(CDMConnector)
library(CohortConstructor)
library(dplyr)
library(ggplot2)
library(gt)
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

## Step 2: Define Exposure and Acute Outcome Cohorts

We define exposure to **Celecoxib** (`concept_id = 1118084`) and the
acute outcome of **Gastrointestinal Hemorrhage**
(`concept_id = 192671`):

``` r
# 1. Instantiate Exposure Cohort
cdm$exposure <- conceptCohort(
  cdm = cdm,
  conceptSet = list(celecoxib = 1118084L),
  name = "exposure"
)

# 2. Instantiate Outcome Cohort
cdm$outcome <- conceptCohort(
  cdm = cdm,
  conceptSet = list(gi_bleed = 192671L),
  name = "outcome"
)
```

## Step 3: Extract Case Series & Calculate Relative Event Timing

We extract all cases (patients who experienced the outcome and received
the exposure) and compute the relative day of the outcome relative to
treatment initiation ($T_{\text{outcome}} - T_{\text{exposure}}$):

``` r
# Extract cases with both exposure and outcome
cases <- cdm$outcome |>
  select(person_id = subject_id, outcome_date = cohort_start_date) |>
  inner_join(
    cdm$exposure |> select(person_id = subject_id, exposure_date = cohort_start_date),
    by = "person_id"
  ) |>
  collect() |>
  mutate(rel_day = as.numeric(outcome_date - exposure_date))

head(cases)
```

    ## # A tibble: 6 × 4
    ##   person_id outcome_date exposure_date rel_day
    ##       <int> <date>       <date>          <dbl>
    ## 1       304 1998-05-03   1998-03-18         46
    ## 2       757 1950-01-22   1949-11-14         69
    ## 3       962 1995-07-09   1995-04-18         82
    ## 4      1674 2012-04-27   2012-04-20          7
    ## 5      1967 1994-05-17   1994-02-20         86
    ## 6      1758 2002-11-07   2002-09-28         40

## Step 4: Diagnostic Event Distribution Plot

A fundamental diagnostic step in SCCS studies is plotting the
distribution of events relative to the index exposure date to evaluate
whether outcomes cluster within the hypothesized acute risk window:

``` r
# Plot event distribution relative to exposure initiation (Day 0)
ggplot(cases |> filter(abs(rel_day) <= 90), aes(x = rel_day)) +
  geom_histogram(binwidth = 5, fill = "#3182ce", color = "white") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#e53e3e", linewidth = 0.8) +
  annotate("rect", xmin = 1, xmax = 30, ymin = 0, ymax = Inf, alpha = 0.2, fill = "#e53e3e") +
  labs(
    title = "Self-Controlled Case Series: Event Distribution Around Exposure",
    subtitle = "Red shaded area indicates the 30-day post-exposure risk window",
    x = "Days Relative to Drug Initiation (Day 0)",
    y = "Incident GI Bleed Cases"
  ) +
  theme_minimal()
```

![](/assets/images/rmd_output/plot-sccs-1.png)<!-- -->

## Step 5: Risk Window vs. Control Window Comparison

We partition the case follow-up into a 30-day post-exposure risk window
($[+1, +30]$ days) and balanced 30-day pre-exposure ($[-60, -31]$ days)
and post-risk ($[+31, +60]$ days) control windows:

``` r
n_cases <- length(unique(cases$person_id))
n_risk <- sum(cases$rel_day >= 1 & cases$rel_day <= 30)
n_control_pre <- sum(cases$rel_day >= -60 & cases$rel_day <= -31)
n_control_post <- sum(cases$rel_day >= 31 & cases$rel_day <= 60)

comparison_df <- data.frame(
  Window = c(
    "Pre-exposure Control (-60 to -31 days)",
    "Acute Risk Window (+1 to +30 days)",
    "Post-exposure Control (+31 to +60 days)"
  ),
  Duration_Days = c(30, 30, 30),
  Events_N = c(n_control_pre, n_risk, n_control_post),
  Person_Days = c(n_cases * 30, n_cases * 30, n_cases * 30),
  Rate_Per_1000_Days = c(
    (n_control_pre / (n_cases * 30)) * 1000,
    (n_risk / (n_cases * 30)) * 1000,
    (n_control_post / (n_cases * 30)) * 1000
  )
)

comparison_df |>
  gt() |>
  tab_header(
    title = "Self-Controlled Case Risk Interval Comparison",
    subtitle = "Celecoxib Exposure vs Acute GI Bleeding"
  ) |>
  cols_label(
    Window = "Analysis Window",
    Duration_Days = "Duration (Days)",
    Events_N = "Observed Events (N)",
    Person_Days = "Person-Days at Risk",
    Rate_Per_1000_Days = "Event Rate (per 1,000 Person-Days)"
  ) |>
  fmt_number(columns = "Rate_Per_1000_Days", decimals = 2)
```

<div id="hfygmczlpz" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#hfygmczlpz table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#hfygmczlpz thead, #hfygmczlpz tbody, #hfygmczlpz tfoot, #hfygmczlpz tr, #hfygmczlpz td, #hfygmczlpz th {
  border-style: none;
}
&#10;#hfygmczlpz p {
  margin: 0;
  padding: 0;
}
&#10;#hfygmczlpz .gt_table {
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
&#10;#hfygmczlpz .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#hfygmczlpz .gt_title {
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
&#10;#hfygmczlpz .gt_subtitle {
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
&#10;#hfygmczlpz .gt_heading {
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
&#10;#hfygmczlpz .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hfygmczlpz .gt_col_headings {
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
&#10;#hfygmczlpz .gt_col_heading {
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
&#10;#hfygmczlpz .gt_column_spanner_outer {
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
&#10;#hfygmczlpz .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#hfygmczlpz .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#hfygmczlpz .gt_column_spanner {
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
&#10;#hfygmczlpz .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#hfygmczlpz .gt_group_heading {
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
&#10;#hfygmczlpz .gt_empty_group_heading {
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
&#10;#hfygmczlpz .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#hfygmczlpz .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#hfygmczlpz .gt_row {
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
&#10;#hfygmczlpz .gt_stub {
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
&#10;#hfygmczlpz .gt_stub_row_group {
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
&#10;#hfygmczlpz .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#hfygmczlpz .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#hfygmczlpz .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hfygmczlpz .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#hfygmczlpz .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#hfygmczlpz .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hfygmczlpz .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hfygmczlpz .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#hfygmczlpz .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#hfygmczlpz .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#hfygmczlpz .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#hfygmczlpz .gt_footnotes {
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
&#10;#hfygmczlpz .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hfygmczlpz .gt_sourcenotes {
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
&#10;#hfygmczlpz .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#hfygmczlpz .gt_left {
  text-align: left;
}
&#10;#hfygmczlpz .gt_center {
  text-align: center;
}
&#10;#hfygmczlpz .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#hfygmczlpz .gt_font_normal {
  font-weight: normal;
}
&#10;#hfygmczlpz .gt_font_bold {
  font-weight: bold;
}
&#10;#hfygmczlpz .gt_font_italic {
  font-style: italic;
}
&#10;#hfygmczlpz .gt_super {
  font-size: 65%;
}
&#10;#hfygmczlpz .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#hfygmczlpz .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#hfygmczlpz .gt_indent_1 {
  text-indent: 5px;
}
&#10;#hfygmczlpz .gt_indent_2 {
  text-indent: 10px;
}
&#10;#hfygmczlpz .gt_indent_3 {
  text-indent: 15px;
}
&#10;#hfygmczlpz .gt_indent_4 {
  text-indent: 20px;
}
&#10;#hfygmczlpz .gt_indent_5 {
  text-indent: 25px;
}
&#10;#hfygmczlpz .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#hfygmczlpz div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_title gt_font_normal" style>Self-Controlled Case Risk Interval Comparison</td>
    </tr>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Celecoxib Exposure vs Acute GI Bleeding</td>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Window">Analysis Window</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Duration_Days">Duration (Days)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Events_N">Observed Events (N)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Person_Days">Person-Days at Risk</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Rate_Per_1000_Days">Event Rate (per 1,000 Person-Days)</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Window" class="gt_row gt_left">Pre-exposure Control (-60 to -31 days)</td>
<td headers="Duration_Days" class="gt_row gt_right">30</td>
<td headers="Events_N" class="gt_row gt_right">0</td>
<td headers="Person_Days" class="gt_row gt_right">10650</td>
<td headers="Rate_Per_1000_Days" class="gt_row gt_right">0.00</td></tr>
    <tr><td headers="Window" class="gt_row gt_left">Acute Risk Window (+1 to +30 days)</td>
<td headers="Duration_Days" class="gt_row gt_right">30</td>
<td headers="Events_N" class="gt_row gt_right">113</td>
<td headers="Person_Days" class="gt_row gt_right">10650</td>
<td headers="Rate_Per_1000_Days" class="gt_row gt_right">10.61</td></tr>
    <tr><td headers="Window" class="gt_row gt_left">Post-exposure Control (+31 to +60 days)</td>
<td headers="Duration_Days" class="gt_row gt_right">30</td>
<td headers="Events_N" class="gt_row gt_right">112</td>
<td headers="Person_Days" class="gt_row gt_right">10650</td>
<td headers="Rate_Per_1000_Days" class="gt_row gt_right">10.52</td></tr>
  </tbody>
  &#10;</table>
</div>

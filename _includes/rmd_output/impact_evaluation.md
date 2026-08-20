
Impact Evaluation Studies utilize quasi-experimental designs—such as
**Interrupted Time Series (ITS)** and **Difference-in-Differences
(DiD)**—to evaluate the causal impact of population-level health
policies, regulatory safety warnings, or clinical guideline shifts on
longitudinal disease rates or medication usage.

## How Interrupted Time Series Works

- **Longitudinal Rate Series**: Tracking population-level incidence or
  prevalence rates over time across pre- and post-intervention periods.
- **Intervention Threshold**: A known calendar cutoff date (e.g. year of
  a regulatory risk minimization measure).
- **Segmented Regression**: Modeling the time series piecewise to test
  for:
  - **Step Change ($\beta_2$)**: Immediate level jump or drop in outcome
    rate following the intervention.
  - **Slope Change ($\beta_3$)**: Change in the long-term rate
    trajectory or gradient post-intervention.

## Step 1: Setup & Connect to GiBleed

Load the required libraries and connect to the Eunomia **GiBleed**
dataset using DuckDB:

``` r
library(CDMConnector)
library(CohortConstructor)
library(IncidencePrevalence)
library(visOmopResults)
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

## Step 2: Define Outcome and Longitudinal Denominator

We track annual incidence rates of **Gastrointestinal Hemorrhage**
(`concept_id = 192671`) across the source population observed from 1980
through 2019:

``` r
# 1. Instantiate Outcome Cohort
cdm$outcome <- conceptCohort(
  cdm = cdm,
  conceptSet = list(gi_bleed = 192671L),
  name = "outcome"
)

# 2. Instantiate Longitudinal Study Denominator
cdm <- generateDenominatorCohortSet(
  cdm = cdm,
  name = "denominator",
  cohortDateRange = as.Date(c("1980-01-01", "2019-01-01"))
)
```

## Step 3: Estimate Longitudinal Incidence Rates

We calculate annual incidence rates per 100,000 person-years:

``` r
# Estimate annual incidence rates
inc <- estimateIncidence(
  cdm = cdm,
  denominatorTable = "denominator",
  outcomeTable = "outcome",
  interval = "years",
  outcomeWashout = Inf,
  repeatedEvents = FALSE
)

# Extract tidy rate table
rates_df <- visOmopResults::tidy(inc) |>
  filter(!is.na(incidence_100000_pys)) |>
  mutate(
    year = as.numeric(substr(incidence_start_date, 1, 4)),
    rate = as.numeric(incidence_100000_pys)
  ) |>
  arrange(year)
```

## Step 4: Fit Segmented Regression (ITS Model)

We define a policy intervention threshold in the calendar year **2000**
and construct the segmented time series variables:

``` r
# Set policy intervention year
intervention_year <- 2000

# Prepare segmented regression design matrix
its_df <- rates_df |>
  mutate(
    time = row_number(),
    post_int = ifelse(year >= intervention_year, 1, 0),
    time_after = ifelse(year >= intervention_year, year - intervention_year, 0)
  )

# Fit Segmented Linear Regression
its_model <- lm(rate ~ time + post_int + time_after, data = its_df)
its_df$fitted <- predict(its_model)

# Format regression coefficients
coefs <- summary(its_model)$coefficients
res_df <- data.frame(
  Parameter = c(
    "Baseline Intercept (Beta 0)",
    "Pre-intervention Slope (Beta 1)",
    "Immediate Step Change (Beta 2)",
    "Slope Change Post-intervention (Beta 3)"
  ),
  Estimate = round(coefs[, 1], 2),
  Std_Error = round(coefs[, 2], 2),
  t_value = round(coefs[, 3], 2),
  p_value = round(coefs[, 4], 4)
)

res_df |>
  gt() |>
  tab_header(
    title = "Segmented Regression Model Results",
    subtitle = "Impact Evaluation of Regulatory Warning (Year 2000)"
  ) |>
  cols_label(
    Parameter = "Model Parameter",
    Estimate = "Estimate",
    Std_Error = "Std. Error",
    t_value = "t-statistic",
    p_value = "p-value"
  )
```

<div id="ukxosyxnyf" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#ukxosyxnyf table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#ukxosyxnyf thead, #ukxosyxnyf tbody, #ukxosyxnyf tfoot, #ukxosyxnyf tr, #ukxosyxnyf td, #ukxosyxnyf th {
  border-style: none;
}
&#10;#ukxosyxnyf p {
  margin: 0;
  padding: 0;
}
&#10;#ukxosyxnyf .gt_table {
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
&#10;#ukxosyxnyf .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#ukxosyxnyf .gt_title {
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
&#10;#ukxosyxnyf .gt_subtitle {
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
&#10;#ukxosyxnyf .gt_heading {
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
&#10;#ukxosyxnyf .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ukxosyxnyf .gt_col_headings {
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
&#10;#ukxosyxnyf .gt_col_heading {
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
&#10;#ukxosyxnyf .gt_column_spanner_outer {
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
&#10;#ukxosyxnyf .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#ukxosyxnyf .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#ukxosyxnyf .gt_column_spanner {
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
&#10;#ukxosyxnyf .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#ukxosyxnyf .gt_group_heading {
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
&#10;#ukxosyxnyf .gt_empty_group_heading {
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
&#10;#ukxosyxnyf .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#ukxosyxnyf .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#ukxosyxnyf .gt_row {
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
&#10;#ukxosyxnyf .gt_stub {
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
&#10;#ukxosyxnyf .gt_stub_row_group {
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
&#10;#ukxosyxnyf .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#ukxosyxnyf .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#ukxosyxnyf .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ukxosyxnyf .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#ukxosyxnyf .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#ukxosyxnyf .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ukxosyxnyf .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ukxosyxnyf .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#ukxosyxnyf .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#ukxosyxnyf .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#ukxosyxnyf .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#ukxosyxnyf .gt_footnotes {
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
&#10;#ukxosyxnyf .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ukxosyxnyf .gt_sourcenotes {
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
&#10;#ukxosyxnyf .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#ukxosyxnyf .gt_left {
  text-align: left;
}
&#10;#ukxosyxnyf .gt_center {
  text-align: center;
}
&#10;#ukxosyxnyf .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#ukxosyxnyf .gt_font_normal {
  font-weight: normal;
}
&#10;#ukxosyxnyf .gt_font_bold {
  font-weight: bold;
}
&#10;#ukxosyxnyf .gt_font_italic {
  font-style: italic;
}
&#10;#ukxosyxnyf .gt_super {
  font-size: 65%;
}
&#10;#ukxosyxnyf .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#ukxosyxnyf .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#ukxosyxnyf .gt_indent_1 {
  text-indent: 5px;
}
&#10;#ukxosyxnyf .gt_indent_2 {
  text-indent: 10px;
}
&#10;#ukxosyxnyf .gt_indent_3 {
  text-indent: 15px;
}
&#10;#ukxosyxnyf .gt_indent_4 {
  text-indent: 20px;
}
&#10;#ukxosyxnyf .gt_indent_5 {
  text-indent: 25px;
}
&#10;#ukxosyxnyf .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#ukxosyxnyf div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_title gt_font_normal" style>Segmented Regression Model Results</td>
    </tr>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Impact Evaluation of Regulatory Warning (Year 2000)</td>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Parameter">Model Parameter</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Estimate">Estimate</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Std_Error">Std. Error</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="t_value">t-statistic</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="p_value">p-value</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Parameter" class="gt_row gt_left">Baseline Intercept (Beta 0)</td>
<td headers="Estimate" class="gt_row gt_right">172.50</td>
<td headers="Std_Error" class="gt_row gt_right">61.00</td>
<td headers="t_value" class="gt_row gt_right">2.83</td>
<td headers="p_value" class="gt_row gt_right">0.0077</td></tr>
    <tr><td headers="Parameter" class="gt_row gt_left">Pre-intervention Slope (Beta 1)</td>
<td headers="Estimate" class="gt_row gt_right">15.00</td>
<td headers="Std_Error" class="gt_row gt_right">5.09</td>
<td headers="t_value" class="gt_row gt_right">2.95</td>
<td headers="p_value" class="gt_row gt_right">0.0057</td></tr>
    <tr><td headers="Parameter" class="gt_row gt_left">Immediate Step Change (Beta 2)</td>
<td headers="Estimate" class="gt_row gt_right">77.34</td>
<td headers="Std_Error" class="gt_row gt_right">84.13</td>
<td headers="t_value" class="gt_row gt_right">0.92</td>
<td headers="p_value" class="gt_row gt_right">0.3642</td></tr>
    <tr><td headers="Parameter" class="gt_row gt_left">Slope Change Post-intervention (Beta 3)</td>
<td headers="Estimate" class="gt_row gt_right">-13.17</td>
<td headers="Std_Error" class="gt_row gt_right">7.50</td>
<td headers="t_value" class="gt_row gt_right">-1.76</td>
<td headers="p_value" class="gt_row gt_right">0.0876</td></tr>
  </tbody>
  &#10;</table>
</div>

## Step 5: Plot Interrupted Time Series Trends

We plot the empirical annual rate estimates along with the segmented
regression trajectories before and after the intervention:

``` r
ggplot(its_df, aes(x = year)) +
  geom_point(aes(y = rate), color = "#2b6cb0", size = 2.5) +
  geom_line(aes(y = fitted, group = post_int), color = "#e53e3e", linewidth = 1.2) +
  geom_vline(xintercept = intervention_year - 0.5, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  annotate(
    "text",
    x = intervention_year - 1,
    y = max(its_df$rate) * 0.95,
    label = "Policy Action (2000)",
    hjust = 1,
    fontface = "bold",
    color = "grey30"
  ) +
  labs(
    title = "Interrupted Time Series: Impact Evaluation Analysis",
    subtitle = "Segmented regression of annual GI hemorrhage incidence before vs after regulatory action (2000)",
    x = "Calendar Year",
    y = "Incidence Rate (per 100,000 Person-Years)"
  ) +
  theme_minimal()
```

![](/assets/images/rmd_output/plot-its-1.png)<!-- -->

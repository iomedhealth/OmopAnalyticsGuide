
Patient-Level Prediction (PLP) aims to develop and validate prognostic
models that estimate an individual patient’s probability of experiencing
a future clinical outcome within a defined time-at-risk (TAR) window
based on baseline health history.

## How Patient-Level Prediction Works

- **Target Cohort ($T$)**: Patients at the moment of prediction (e.g. at
  treatment initiation).
- **Outcome Cohort ($O$)**: The incident binary event to predict within
  the Time-at-Risk (e.g. Day 1 to 365 post-index).
- **Feature Engineering**: Demographics and historical diagnoses
  extracted using `PatientProfiles`.
- **Validation**: Independent train/test splitting (`rsample`), model
  training, discrimination assessment (ROC AUC via `yardstick`), and
  calibration evaluation.

## Step 1: Setup & Connect to GiBleed

Load the necessary libraries and connect to the Eunomia **GiBleed**
dataset using DuckDB:

``` r
library(CDMConnector)
library(CohortConstructor)
library(PatientProfiles)
library(rsample)
library(yardstick)
library(ggplot2)
library(gt)
library(dplyr)
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

## Step 2: Define Target and Outcome Cohorts

We define the target population as new users of NSAIDs (**Celecoxib**
`1118084` or **Diclofenac** `1124300`) with at least 365 days of prior
observation, and the prediction outcome as incident **Gastrointestinal
Hemorrhage** (`192671`):

``` r
# 1. Target Cohort (T): Incident NSAID users
cdm$target <- conceptCohort(
  cdm = cdm,
  conceptSet = list(nsaid_users = c(1118084L, 1124300L)),
  name = "target"
) |>
  requireIsFirstEntry() |>
  requirePriorObservation(minPriorObservation = 365)

# 2. Outcome Cohort (O): Gastrointestinal Hemorrhage
cdm$outcome <- conceptCohort(
  cdm = cdm,
  conceptSet = list(gi_bleed = 192671L),
  name = "outcome"
)
```

## Step 3: Feature Extraction & Outcome Flagging

We extract demographic variables, baseline comorbidities in the 365-day
lookback window ($[-365, 0]$ days), and label whether the outcome
occurred during the Time-at-Risk ($[+1, +365]$ days post-index):

``` r
# Extract baseline predictors and outcome status in Time-at-Risk (1-365 days)
features_df <- cdm$target |>
  addAge() |>
  addSex() |>
  addPriorObservation() |>
  addConceptIntersectFlag(
    conceptSet = list(
      sinusitis = 4283893L,
      uti = 4116491L,
      asthma = 4051466L
    ),
    window = c(-365, 0)
  ) |>
  addCohortIntersectFlag(
    targetCohortTable = "outcome",
    window = c(1, 365),
    nameStyle = "outcome"
  ) |>
  collect()
```

## Step 4: Model Training and Testing

We partition the dataset into a 75% training set and a 25% testing set
using stratified sampling, train a logistic regression risk model, and
evaluate test-set performance:

``` r
# Prepare data for modeling
set.seed(42)
features_df$outcome_fac <- factor(
  ifelse(features_df$outcome == 1, "Event", "NoEvent"),
  levels = c("Event", "NoEvent")
)

# 75/25 Train-Test Split
split <- initial_split(features_df, prop = 0.75, strata = outcome_fac)
train_df <- training(split)
test_df <- testing(split)

# Fit prognostic risk model
model <- glm(
  outcome ~ age + sex + prior_observation + sinusitis_m365_to_0 + uti_m365_to_0 + asthma_m365_to_0,
  data = train_df,
  family = binomial()
)

# Generate test set predictions
test_df$pred_prob <- predict(model, newdata = test_df, type = "response")
test_df$pred_class <- factor(
  ifelse(test_df$pred_prob >= 0.18, "Event", "NoEvent"),
  levels = c("Event", "NoEvent")
)

# Compute ROC AUC
auc_val <- roc_auc(test_df, truth = outcome_fac, pred_prob, event_level = "first")
```

## Step 5: Discrimination ROC Curve & Performance Summary

We plot the Receiver Operating Characteristic (ROC) curve and generate a
publication-ready performance table:

``` r
# Generate ROC Curve
roc_df <- roc_curve(test_df, truth = outcome_fac, pred_prob, event_level = "first")

ggplot(roc_df, aes(x = 1 - specificity, y = sensitivity)) +
  geom_path(color = "#2b6cb0", linewidth = 1.2) +
  geom_abline(lty = 3, color = "grey50") +
  coord_equal() +
  labs(
    title = "Patient-Level Prediction: ROC Curve",
    subtitle = paste0("Model: Logistic Regression | Discrimination AUC = ", round(auc_val$.estimate, 3)),
    x = "1 - Specificity (False Positive Rate)",
    y = "Sensitivity (True Positive Rate)"
  ) +
  theme_minimal()
```

![](/assets/images/rmd_output/plot-roc-1.png)<!-- -->

``` r
# Performance metric summary table
perf_df <- data.frame(
  Metric = c("ROC AUC (Discrimination)", "Accuracy", "Sensitivity", "Specificity"),
  Estimate = c(
    round(auc_val$.estimate, 3),
    round(accuracy(test_df, truth = outcome_fac, estimate = pred_class)$.estimate, 3),
    round(sens(test_df, truth = outcome_fac, estimate = pred_class, event_level = "first")$.estimate, 3),
    round(spec(test_df, truth = outcome_fac, estimate = pred_class, event_level = "first")$.estimate, 3)
  )
)

perf_df |>
  gt() |>
  tab_header(
    title = "Model Performance Metrics",
    subtitle = "Internal Validation on 25% Holdout Test Set"
  ) |>
  cols_label(
    Metric = "Performance Metric",
    Estimate = "Test Estimate"
  )
```

<div id="flmedldwmk" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#flmedldwmk table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#flmedldwmk thead, #flmedldwmk tbody, #flmedldwmk tfoot, #flmedldwmk tr, #flmedldwmk td, #flmedldwmk th {
  border-style: none;
}
&#10;#flmedldwmk p {
  margin: 0;
  padding: 0;
}
&#10;#flmedldwmk .gt_table {
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
&#10;#flmedldwmk .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#flmedldwmk .gt_title {
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
&#10;#flmedldwmk .gt_subtitle {
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
&#10;#flmedldwmk .gt_heading {
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
&#10;#flmedldwmk .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#flmedldwmk .gt_col_headings {
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
&#10;#flmedldwmk .gt_col_heading {
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
&#10;#flmedldwmk .gt_column_spanner_outer {
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
&#10;#flmedldwmk .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#flmedldwmk .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#flmedldwmk .gt_column_spanner {
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
&#10;#flmedldwmk .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#flmedldwmk .gt_group_heading {
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
&#10;#flmedldwmk .gt_empty_group_heading {
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
&#10;#flmedldwmk .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#flmedldwmk .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#flmedldwmk .gt_row {
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
&#10;#flmedldwmk .gt_stub {
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
&#10;#flmedldwmk .gt_stub_row_group {
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
&#10;#flmedldwmk .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#flmedldwmk .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#flmedldwmk .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#flmedldwmk .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#flmedldwmk .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#flmedldwmk .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#flmedldwmk .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#flmedldwmk .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#flmedldwmk .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#flmedldwmk .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#flmedldwmk .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#flmedldwmk .gt_footnotes {
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
&#10;#flmedldwmk .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#flmedldwmk .gt_sourcenotes {
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
&#10;#flmedldwmk .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#flmedldwmk .gt_left {
  text-align: left;
}
&#10;#flmedldwmk .gt_center {
  text-align: center;
}
&#10;#flmedldwmk .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#flmedldwmk .gt_font_normal {
  font-weight: normal;
}
&#10;#flmedldwmk .gt_font_bold {
  font-weight: bold;
}
&#10;#flmedldwmk .gt_font_italic {
  font-style: italic;
}
&#10;#flmedldwmk .gt_super {
  font-size: 65%;
}
&#10;#flmedldwmk .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#flmedldwmk .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#flmedldwmk .gt_indent_1 {
  text-indent: 5px;
}
&#10;#flmedldwmk .gt_indent_2 {
  text-indent: 10px;
}
&#10;#flmedldwmk .gt_indent_3 {
  text-indent: 15px;
}
&#10;#flmedldwmk .gt_indent_4 {
  text-indent: 20px;
}
&#10;#flmedldwmk .gt_indent_5 {
  text-indent: 25px;
}
&#10;#flmedldwmk .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#flmedldwmk div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_heading">
      <td colspan="2" class="gt_heading gt_title gt_font_normal" style>Model Performance Metrics</td>
    </tr>
    <tr class="gt_heading">
      <td colspan="2" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Internal Validation on 25% Holdout Test Set</td>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Metric">Performance Metric</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Estimate">Test Estimate</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Metric" class="gt_row gt_left">ROC AUC (Discrimination)</td>
<td headers="Estimate" class="gt_row gt_right">0.510</td></tr>
    <tr><td headers="Metric" class="gt_row gt_left">Accuracy</td>
<td headers="Estimate" class="gt_row gt_right">0.503</td></tr>
    <tr><td headers="Metric" class="gt_row gt_left">Sensitivity</td>
<td headers="Estimate" class="gt_row gt_right">0.542</td></tr>
    <tr><td headers="Metric" class="gt_row gt_left">Specificity</td>
<td headers="Estimate" class="gt_row gt_right">0.494</td></tr>
  </tbody>
  &#10;</table>
</div>

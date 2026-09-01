
Pathway Analysis maps out the real-world sequence, combination, and
transition of therapies or clinical events experienced by patients over
time following an initial disease diagnosis.

## How Pathway Analysis Works

- **Target Cohort**: Patients diagnosed with a condition of interest
  establishing index “time zero”.
- **Event Extraction & Era Building**: Extracting subsequent drug
  exposures, collapsing adjacent records into treatment eras.
- **Line of Therapy Assignment**: Chronologically ordering treatment
  eras into Line 1 (L1), Line 2 (L2), and Line 3 (L3).
- **Pathway Aggregation & Visualisation**: Quantifying the most frequent
  therapeutic sequences and visualizing patient journey flows.

## Step 1: Setup & Connect to GiBleed

Load the necessary libraries and establish a connection to the Eunomia
**GiBleed** dataset using DuckDB:

``` r
library(CDMConnector)
library(CohortConstructor)
library(dplyr)
library(tidyr)
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

## Step 2: Define Index Diagnosis Cohort

We define our target cohort as incident patients diagnosed with
**Sinusitis** (`concept_id = 4283893, 4294548`):

``` r
# Target Cohort: Incident Sinusitis Patients
cdm$sinusitis <- conceptCohort(
  cdm = cdm,
  conceptSet = list(sinusitis = c(4283893L, 4294548L)),
  name = "sinusitis"
) |>
  requireIsFirstEntry()
```

## Step 3: Extract Longitudinal Medications & Construct Lines of Therapy

We extract all subsequent drug exposures following the diagnosis date,
consolidate consecutive exposures into treatment eras, and classify each
patient’s journey into sequential lines of therapy:

``` r
# Extract post-diagnosis drug exposures
drugs <- cdm$sinusitis |>
  select(person_id = subject_id, diag_date = cohort_start_date) |>
  inner_join(
    cdm$drug_exposure |> select(person_id, drug_concept_id, drug_exposure_start_date),
    by = "person_id"
  ) |>
  filter(drug_exposure_start_date >= diag_date) |>
  left_join(cdm$concept |> select(concept_id, concept_name), by = c("drug_concept_id" = "concept_id")) |>
  collect() |>
  mutate(
    treatment = case_when(
      grepl("Ampicillin", concept_name, ignore.case = TRUE) ~ "Ampicillin",
      grepl("celecoxib", concept_name, ignore.case = TRUE) ~ "Celecoxib",
      grepl("Diclofenac", concept_name, ignore.case = TRUE) ~ "Diclofenac",
      grepl("vaccine|toxoid", concept_name, ignore.case = TRUE) ~ "Vaccines",
      TRUE ~ "Other"
    )
  ) |>
  arrange(person_id, drug_exposure_start_date) |>
  group_by(person_id) |>
  mutate(prev_treatment = lag(treatment)) |>
  filter(is.na(prev_treatment) | treatment != prev_treatment) |>
  mutate(line_num = row_number()) |>
  filter(line_num <= 3) |>
  mutate(line = paste0("Line_", line_num)) |>
  ungroup()

# Pivot to patient-level pathways
pathways <- drugs |>
  pivot_wider(id_cols = person_id, names_from = line, values_from = treatment) |>
  mutate(
    Line_1 = ifelse(is.na(Line_1), "None", Line_1),
    Line_2 = ifelse(is.na(Line_2), "Discontinued", Line_2),
    Line_3 = ifelse(is.na(Line_3), "Discontinued", Line_3)
  )
```

## Step 4: Top Treatment Pathways Summary Table

We aggregate the individual patient journeys into top treatment
pathways:

``` r
# Summarise most common treatment pathways
pathway_summary <- pathways |>
  group_by(Line_1, Line_2, Line_3) |>
  summarise(Patients_N = n(), .groups = "drop") |>
  mutate(Percentage = round((Patients_N / sum(Patients_N)) * 100, 1)) |>
  arrange(desc(Patients_N)) |>
  head(10)

pathway_summary |>
  gt() |>
  tab_header(
    title = "Top Treatment Pathways Following Sinusitis Diagnosis",
    subtitle = "Sequence Progression across Lines 1, 2, and 3"
  ) |>
  cols_label(
    Line_1 = "1st Line Therapy",
    Line_2 = "2nd Line Therapy",
    Line_3 = "3rd Line Therapy",
    Patients_N = "Patients (N)",
    Percentage = "Proportion (%)"
  )
```

<div id="spqulyhlpb" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#spqulyhlpb table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#spqulyhlpb thead, #spqulyhlpb tbody, #spqulyhlpb tfoot, #spqulyhlpb tr, #spqulyhlpb td, #spqulyhlpb th {
  border-style: none;
}
&#10;#spqulyhlpb p {
  margin: 0;
  padding: 0;
}
&#10;#spqulyhlpb .gt_table {
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
&#10;#spqulyhlpb .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#spqulyhlpb .gt_title {
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
&#10;#spqulyhlpb .gt_subtitle {
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
&#10;#spqulyhlpb .gt_heading {
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
&#10;#spqulyhlpb .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#spqulyhlpb .gt_col_headings {
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
&#10;#spqulyhlpb .gt_col_heading {
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
&#10;#spqulyhlpb .gt_column_spanner_outer {
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
&#10;#spqulyhlpb .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#spqulyhlpb .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#spqulyhlpb .gt_column_spanner {
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
&#10;#spqulyhlpb .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#spqulyhlpb .gt_group_heading {
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
&#10;#spqulyhlpb .gt_empty_group_heading {
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
&#10;#spqulyhlpb .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#spqulyhlpb .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#spqulyhlpb .gt_row {
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
&#10;#spqulyhlpb .gt_stub {
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
&#10;#spqulyhlpb .gt_stub_row_group {
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
&#10;#spqulyhlpb .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#spqulyhlpb .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#spqulyhlpb .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#spqulyhlpb .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#spqulyhlpb .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#spqulyhlpb .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#spqulyhlpb .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#spqulyhlpb .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#spqulyhlpb .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#spqulyhlpb .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#spqulyhlpb .gt_table_body {
  border-top-style: solid;
  border-top-width: 2px;
  border-top-color: #D3D3D3;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#spqulyhlpb .gt_footnotes {
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
&#10;#spqulyhlpb .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#spqulyhlpb .gt_sourcenotes {
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
&#10;#spqulyhlpb .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#spqulyhlpb .gt_left {
  text-align: left;
}
&#10;#spqulyhlpb .gt_center {
  text-align: center;
}
&#10;#spqulyhlpb .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#spqulyhlpb .gt_font_normal {
  font-weight: normal;
}
&#10;#spqulyhlpb .gt_font_bold {
  font-weight: bold;
}
&#10;#spqulyhlpb .gt_font_italic {
  font-style: italic;
}
&#10;#spqulyhlpb .gt_super {
  font-size: 65%;
}
&#10;#spqulyhlpb .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#spqulyhlpb .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#spqulyhlpb .gt_indent_1 {
  text-indent: 5px;
}
&#10;#spqulyhlpb .gt_indent_2 {
  text-indent: 10px;
}
&#10;#spqulyhlpb .gt_indent_3 {
  text-indent: 15px;
}
&#10;#spqulyhlpb .gt_indent_4 {
  text-indent: 20px;
}
&#10;#spqulyhlpb .gt_indent_5 {
  text-indent: 25px;
}
&#10;#spqulyhlpb .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#spqulyhlpb div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_title gt_font_normal" style>Top Treatment Pathways Following Sinusitis Diagnosis</td>
    </tr>
    <tr class="gt_heading">
      <td colspan="5" class="gt_heading gt_subtitle gt_font_normal gt_bottom_border" style>Sequence Progression across Lines 1, 2, and 3</td>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Line_1">1st Line Therapy</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Line_2">2nd Line Therapy</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Line_3">3rd Line Therapy</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Patients_N">Patients (N)</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Percentage">Proportion (%)</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Vaccines</td>
<td headers="Line_3" class="gt_row gt_left">Other</td>
<td headers="Patients_N" class="gt_row gt_right">478</td>
<td headers="Percentage" class="gt_row gt_right">35.9</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Vaccines</td>
<td headers="Line_2" class="gt_row gt_left">Other</td>
<td headers="Line_3" class="gt_row gt_left">Vaccines</td>
<td headers="Patients_N" class="gt_row gt_right">169</td>
<td headers="Percentage" class="gt_row gt_right">12.7</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Celecoxib</td>
<td headers="Line_3" class="gt_row gt_left">Other</td>
<td headers="Patients_N" class="gt_row gt_right">139</td>
<td headers="Percentage" class="gt_row gt_right">10.4</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Celecoxib</td>
<td headers="Line_3" class="gt_row gt_left">Vaccines</td>
<td headers="Patients_N" class="gt_row gt_right">74</td>
<td headers="Percentage" class="gt_row gt_right">5.6</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Vaccines</td>
<td headers="Line_3" class="gt_row gt_left">Celecoxib</td>
<td headers="Patients_N" class="gt_row gt_right">72</td>
<td headers="Percentage" class="gt_row gt_right">5.4</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Diclofenac</td>
<td headers="Line_3" class="gt_row gt_left">Other</td>
<td headers="Patients_N" class="gt_row gt_right">62</td>
<td headers="Percentage" class="gt_row gt_right">4.7</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Discontinued</td>
<td headers="Line_3" class="gt_row gt_left">Discontinued</td>
<td headers="Patients_N" class="gt_row gt_right">37</td>
<td headers="Percentage" class="gt_row gt_right">2.8</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Vaccines</td>
<td headers="Line_2" class="gt_row gt_left">Discontinued</td>
<td headers="Line_3" class="gt_row gt_left">Discontinued</td>
<td headers="Patients_N" class="gt_row gt_right">32</td>
<td headers="Percentage" class="gt_row gt_right">2.4</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Other</td>
<td headers="Line_2" class="gt_row gt_left">Vaccines</td>
<td headers="Line_3" class="gt_row gt_left">Discontinued</td>
<td headers="Patients_N" class="gt_row gt_right">31</td>
<td headers="Percentage" class="gt_row gt_right">2.3</td></tr>
    <tr><td headers="Line_1" class="gt_row gt_left">Celecoxib</td>
<td headers="Line_2" class="gt_row gt_left">Other</td>
<td headers="Line_3" class="gt_row gt_left">Vaccines</td>
<td headers="Patients_N" class="gt_row gt_right">26</td>
<td headers="Percentage" class="gt_row gt_right">2.0</td></tr>
  </tbody>
  &#10;</table>
</div>

## Step 5: Visualizing Treatment Flow across Lines

We plot the distribution of therapeutic modalities across successive
lines of therapy:

``` r
# Aggregate by line and treatment
plot_df <- drugs |>
  group_by(line, treatment) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(line) |>
  mutate(pct = (n / sum(n)) * 100)

ggplot(plot_df, aes(x = line, y = pct, fill = treatment)) +
  geom_col(position = "stack", width = 0.6, color = "white") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Treatment Pathway Distribution Across Lines of Therapy",
    subtitle = "Longitudinal pharmacotherapy progression following initial sinusitis diagnosis",
    x = "Line of Therapy",
    y = "Proportion of Patients (%)",
    fill = "Treatment"
  ) +
  theme_minimal()
```

![](/assets/images/rmd_output/plot-pathway-1.png)<!-- -->

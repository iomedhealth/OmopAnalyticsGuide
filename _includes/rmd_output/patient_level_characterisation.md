
Let’s implement the study using the OHDSI CohortCharacteristics and
PatientProfiles packages to generate baseline profiles (“Table 1”) of
one or more cohorts in the OMOP CDM, directly addressing the guide’s
descriptive design.

## How CohortCharacteristics works

- **Summarise -\> table/plot**:
  `summariseCohortCount`/`summariseCharacteristics` produce tidy
  `summarised_result` outputs consumed by `table…`/`plot…` helpers in
  `visOmopResults`.
- **Cohorts in, summaries out**: You provide one or more cohort tables
  (OMOP CDM structure). Functions compute counts, attrition,
  demographics, and clinical features at/before index.
- **Windows**: For granular baselines, large-scale summaries can use
  windows (e.g., -365:-1, 0:0, 1:365) around index.
- **Groups/strata**: Each cohort produces groups; you can stratify or
  facet by `cohort_name` and other variables in plots/tables.

## Practical guidance

- Connect to standard benchmark datasets (such as Eunomia GiBleed) for
  reproducible evaluation.
- Keep cohort inclusion/exclusion logic in cohort construction; keep
  `summarise` functions descriptive.
- Save the `summarised_result` object and then render tables/plots.

## Step 1: Setup

This initial step focuses on preparing the R environment for the
analysis. It involves loading libraries like `CDMConnector`,
`CohortConstructor`, `CohortCharacteristics`, and `PatientProfiles`.

``` r
library(CDMConnector)
library(CohortConstructor)
library(CohortCharacteristics)
library(PatientProfiles)
library(visOmopResults)
library(dplyr)
```

## Step 2: Connect to the GiBleed CDM and Create Cohorts

We connect to the standardized Eunomia **GiBleed** dataset using DuckDB.
We define two comparative cohorts of interest—individuals exposed to
**Celecoxib** (`concept_id = 1118084`) and **Diclofenac**
(`concept_id = 1124300`).

``` r
# Ensure GiBleed dataset is available and connect via DuckDB
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

# Generate cohorts for Celecoxib and Diclofenac
cdm$nsaids <- conceptCohort(
  cdm = cdm,
  conceptSet = list(
    celecoxib = 1118084L,
    diclofenac = 1124300L
  ),
  name = "nsaids"
)
```

## Step 3: Cohort counts and attrition

Before diving into detailed characterization, it’s important to
understand the size and composition of each cohort. This step calculates
the number of subjects and records in each cohort and inspects the
attrition process.

``` r
# Summarize the number of subjects and records in each cohort
counts <- summariseCohortCount(cdm$nsaids)
# Display the cohort counts in a table
tableCohortCount(counts)
```

<div id="cyeubzzjxg" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#cyeubzzjxg table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#cyeubzzjxg thead, #cyeubzzjxg tbody, #cyeubzzjxg tfoot, #cyeubzzjxg tr, #cyeubzzjxg td, #cyeubzzjxg th {
  border-style: none;
}
&#10;#cyeubzzjxg p {
  margin: 0;
  padding: 0;
}
&#10;#cyeubzzjxg .gt_table {
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
&#10;#cyeubzzjxg .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#cyeubzzjxg .gt_title {
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
&#10;#cyeubzzjxg .gt_subtitle {
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
&#10;#cyeubzzjxg .gt_heading {
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
&#10;#cyeubzzjxg .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#cyeubzzjxg .gt_col_headings {
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
&#10;#cyeubzzjxg .gt_col_heading {
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
&#10;#cyeubzzjxg .gt_column_spanner_outer {
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
&#10;#cyeubzzjxg .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#cyeubzzjxg .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#cyeubzzjxg .gt_column_spanner {
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
&#10;#cyeubzzjxg .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#cyeubzzjxg .gt_group_heading {
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
&#10;#cyeubzzjxg .gt_empty_group_heading {
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
&#10;#cyeubzzjxg .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#cyeubzzjxg .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#cyeubzzjxg .gt_row {
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
&#10;#cyeubzzjxg .gt_stub {
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
&#10;#cyeubzzjxg .gt_stub_row_group {
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
&#10;#cyeubzzjxg .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#cyeubzzjxg .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#cyeubzzjxg .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cyeubzzjxg .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#cyeubzzjxg .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#cyeubzzjxg .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#cyeubzzjxg .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cyeubzzjxg .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#cyeubzzjxg .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#cyeubzzjxg .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#cyeubzzjxg .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#cyeubzzjxg .gt_footnotes {
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
&#10;#cyeubzzjxg .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cyeubzzjxg .gt_sourcenotes {
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
&#10;#cyeubzzjxg .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#cyeubzzjxg .gt_left {
  text-align: left;
}
&#10;#cyeubzzjxg .gt_center {
  text-align: center;
}
&#10;#cyeubzzjxg .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#cyeubzzjxg .gt_font_normal {
  font-weight: normal;
}
&#10;#cyeubzzjxg .gt_font_bold {
  font-weight: bold;
}
&#10;#cyeubzzjxg .gt_font_italic {
  font-style: italic;
}
&#10;#cyeubzzjxg .gt_super {
  font-size: 65%;
}
&#10;#cyeubzzjxg .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#cyeubzzjxg .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#cyeubzzjxg .gt_indent_1 {
  text-indent: 5px;
}
&#10;#cyeubzzjxg .gt_indent_2 {
  text-indent: 10px;
}
&#10;#cyeubzzjxg .gt_indent_3 {
  text-indent: 15px;
}
&#10;#cyeubzzjxg .gt_indent_4 {
  text-indent: 20px;
}
&#10;#cyeubzzjxg .gt_indent_5 {
  text-indent: 25px;
}
&#10;#cyeubzzjxg .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#cyeubzzjxg div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="CDM-name">CDM name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Variable-name">Variable name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Estimate-name">Estimate name</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">Cohort name</div>
      </th>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Cohort-name-[header_level]celecoxib">celecoxib</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Cohort-name-[header_level]diclofenac">diclofenac</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="CDM name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Synthea</td>
<td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Number records</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="CDM name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Number subjects</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
  </tbody>
  &#10;</table>
</div>

``` r
# Summarize the attrition of the cohorts
attr <- summariseCohortAttrition(cdm$nsaids)
# Display the cohort attrition in a table
tableCohortAttrition(attr)
```

<div id="fxqgtemzkc" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#fxqgtemzkc table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#fxqgtemzkc thead, #fxqgtemzkc tbody, #fxqgtemzkc tfoot, #fxqgtemzkc tr, #fxqgtemzkc td, #fxqgtemzkc th {
  border-style: none;
}
&#10;#fxqgtemzkc p {
  margin: 0;
  padding: 0;
}
&#10;#fxqgtemzkc .gt_table {
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
&#10;#fxqgtemzkc .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#fxqgtemzkc .gt_title {
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
&#10;#fxqgtemzkc .gt_subtitle {
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
&#10;#fxqgtemzkc .gt_heading {
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
&#10;#fxqgtemzkc .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#fxqgtemzkc .gt_col_headings {
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
&#10;#fxqgtemzkc .gt_col_heading {
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
&#10;#fxqgtemzkc .gt_column_spanner_outer {
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
&#10;#fxqgtemzkc .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#fxqgtemzkc .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#fxqgtemzkc .gt_column_spanner {
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
&#10;#fxqgtemzkc .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#fxqgtemzkc .gt_group_heading {
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
&#10;#fxqgtemzkc .gt_empty_group_heading {
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
&#10;#fxqgtemzkc .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#fxqgtemzkc .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#fxqgtemzkc .gt_row {
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
&#10;#fxqgtemzkc .gt_stub {
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
&#10;#fxqgtemzkc .gt_stub_row_group {
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
&#10;#fxqgtemzkc .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#fxqgtemzkc .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#fxqgtemzkc .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fxqgtemzkc .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#fxqgtemzkc .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#fxqgtemzkc .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#fxqgtemzkc .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fxqgtemzkc .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#fxqgtemzkc .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#fxqgtemzkc .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#fxqgtemzkc .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#fxqgtemzkc .gt_footnotes {
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
&#10;#fxqgtemzkc .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fxqgtemzkc .gt_sourcenotes {
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
&#10;#fxqgtemzkc .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#fxqgtemzkc .gt_left {
  text-align: left;
}
&#10;#fxqgtemzkc .gt_center {
  text-align: center;
}
&#10;#fxqgtemzkc .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#fxqgtemzkc .gt_font_normal {
  font-weight: normal;
}
&#10;#fxqgtemzkc .gt_font_bold {
  font-weight: bold;
}
&#10;#fxqgtemzkc .gt_font_italic {
  font-style: italic;
}
&#10;#fxqgtemzkc .gt_super {
  font-size: 65%;
}
&#10;#fxqgtemzkc .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#fxqgtemzkc .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#fxqgtemzkc .gt_indent_1 {
  text-indent: 5px;
}
&#10;#fxqgtemzkc .gt_indent_2 {
  text-indent: 10px;
}
&#10;#fxqgtemzkc .gt_indent_3 {
  text-indent: 15px;
}
&#10;#fxqgtemzkc .gt_indent_4 {
  text-indent: 20px;
}
&#10;#fxqgtemzkc .gt_indent_5 {
  text-indent: 25px;
}
&#10;#fxqgtemzkc .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#fxqgtemzkc div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Reason">Reason</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="4" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]Variable name&#10;[header_level]number_records">
        <div class="gt_column_spanner">Variable name</div>
      </th>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Variable-name-[header_level]number_records">number_records</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Variable-name-[header_level]number_subjects">number_subjects</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Variable-name-[header_level]excluded_records">excluded_records</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]Variable-name-[header_level]excluded_subjects">excluded_subjects</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr class="gt_group_heading_row">
      <th colspan="5" class="gt_group_heading" style="background-color: #E9E9E9; font-family: Arial; font-size: 10; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="Synthea; celecoxib">Synthea; celecoxib</th>
    </tr>
    <tr class="gt_row_group_first"><td headers="Synthea; celecoxib  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Initial qualifying events</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,844</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,844</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0</td></tr>
    <tr><td headers="Synthea; celecoxib  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Record in observation</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">44</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">44</td></tr>
    <tr><td headers="Synthea; celecoxib  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Not missing record date</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0</td></tr>
    <tr><td headers="Synthea; celecoxib  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Merge overlapping records</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; celecoxib  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0</td></tr>
    <tr class="gt_group_heading_row">
      <th colspan="5" class="gt_group_heading" style="background-color: #E9E9E9; font-family: Arial; font-size: 10; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="Synthea; diclofenac">Synthea; diclofenac</th>
    </tr>
    <tr class="gt_row_group_first"><td headers="Synthea; diclofenac  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Initial qualifying events</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">850</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">850</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0</td></tr>
    <tr><td headers="Synthea; diclofenac  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Record in observation</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">830</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">830</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">20</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">20</td></tr>
    <tr><td headers="Synthea; diclofenac  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Not missing record date</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">830</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">830</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0</td></tr>
    <tr><td headers="Synthea; diclofenac  Reason" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Merge overlapping records</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">830</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]number_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">830</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_records" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0</td>
<td headers="Synthea; diclofenac  [header_name]Variable name
[header_level]excluded_subjects" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0</td></tr>
  </tbody>
  &#10;</table>
</div>

## Step 4: Baseline characteristics (“Table 1”) and plots

This is the core of the patient-level characterization analysis. We
generate a comprehensive summary of baseline characteristics, often
referred to as “Table 1,” describing age, sex, and prior observation
time at cohort entry.

``` r
# Summarize baseline characteristics (demographics)
chars <- summariseCharacteristics(cdm$nsaids)
# Display baseline characteristics table
tableCharacteristics(chars)
```

<div id="lcoicaukrw" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#lcoicaukrw table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#lcoicaukrw thead, #lcoicaukrw tbody, #lcoicaukrw tfoot, #lcoicaukrw tr, #lcoicaukrw td, #lcoicaukrw th {
  border-style: none;
}
&#10;#lcoicaukrw p {
  margin: 0;
  padding: 0;
}
&#10;#lcoicaukrw .gt_table {
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
&#10;#lcoicaukrw .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#lcoicaukrw .gt_title {
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
&#10;#lcoicaukrw .gt_subtitle {
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
&#10;#lcoicaukrw .gt_heading {
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
&#10;#lcoicaukrw .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lcoicaukrw .gt_col_headings {
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
&#10;#lcoicaukrw .gt_col_heading {
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
&#10;#lcoicaukrw .gt_column_spanner_outer {
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
&#10;#lcoicaukrw .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#lcoicaukrw .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#lcoicaukrw .gt_column_spanner {
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
&#10;#lcoicaukrw .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#lcoicaukrw .gt_group_heading {
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
&#10;#lcoicaukrw .gt_empty_group_heading {
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
&#10;#lcoicaukrw .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#lcoicaukrw .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#lcoicaukrw .gt_row {
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
&#10;#lcoicaukrw .gt_stub {
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
&#10;#lcoicaukrw .gt_stub_row_group {
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
&#10;#lcoicaukrw .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#lcoicaukrw .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#lcoicaukrw .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lcoicaukrw .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#lcoicaukrw .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#lcoicaukrw .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lcoicaukrw .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lcoicaukrw .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#lcoicaukrw .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#lcoicaukrw .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#lcoicaukrw .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#lcoicaukrw .gt_footnotes {
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
&#10;#lcoicaukrw .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lcoicaukrw .gt_sourcenotes {
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
&#10;#lcoicaukrw .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#lcoicaukrw .gt_left {
  text-align: left;
}
&#10;#lcoicaukrw .gt_center {
  text-align: center;
}
&#10;#lcoicaukrw .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#lcoicaukrw .gt_font_normal {
  font-weight: normal;
}
&#10;#lcoicaukrw .gt_font_bold {
  font-weight: bold;
}
&#10;#lcoicaukrw .gt_font_italic {
  font-style: italic;
}
&#10;#lcoicaukrw .gt_super {
  font-size: 65%;
}
&#10;#lcoicaukrw .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#lcoicaukrw .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#lcoicaukrw .gt_indent_1 {
  text-indent: 5px;
}
&#10;#lcoicaukrw .gt_indent_2 {
  text-indent: 10px;
}
&#10;#lcoicaukrw .gt_indent_3 {
  text-indent: 15px;
}
&#10;#lcoicaukrw .gt_indent_4 {
  text-indent: 20px;
}
&#10;#lcoicaukrw .gt_indent_5 {
  text-indent: 25px;
}
&#10;#lcoicaukrw .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#lcoicaukrw div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="3" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup"></th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]CDM name&#10;[header_level]Synthea&#10;[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">CDM name</div>
      </th>
    </tr>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="3" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup"></th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_level]Synthea&#10;[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">Synthea</div>
      </th>
    </tr>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Variable-name">Variable name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Variable-level">Variable level</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Estimate-name">Estimate name</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">Cohort name</div>
      </th>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]CDM-name-[header_level]Synthea-[header_name]Cohort-name-[header_level]celecoxib">celecoxib</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]CDM-name-[header_level]Synthea-[header_name]Cohort-name-[header_level]diclofenac">diclofenac</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Number records</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Number subjects</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Cohort start date</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2000-03-02 [1988-06-22 - 2008-11-23]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1999-04-21 [1987-11-05 - 2007-11-13]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1941-12-05 to 2019-04-14</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1943-07-03 to 2019-03-15</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Cohort end date</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2000-03-02 [1988-06-22 - 2008-11-23]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1999-04-21 [1987-11-05 - 2007-11-13]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1941-12-05 to 2019-04-14</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1943-07-03 to 2019-03-15</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Age</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">38.00 [36.00 - 41.00]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">38.00 [36.00 - 41.00]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">38.17 (3.28)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">38.10 (3.26)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">31.00 to 46.00</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">31.00 to 46.00</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Sex</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">906 (50.33%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">435 (52.41%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">894 (49.67%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">395 (47.59%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Prior observation</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">14,100.00 [13,160.00 - 15,040.00]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">14,040.00 [13,185.00 - 15,037.75]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">14,114.68 (1,195.71)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">14,087.07 (1,188.03)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">11,369.00 to 17,044.00</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">11,340.00 to 16,805.00</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Future observation</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">6,679.00 [3,445.00 - 10,650.00]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">7,024.00 [3,831.00 - 11,013.25]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">7,588.08 (5,352.39)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">7,900.78 (5,387.34)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">10.00 to 28,328.00</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">23.00 to 27,108.00</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Days in cohort</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1 [1 - 1]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1 [1 - 1]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1.00 (0.00)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1.00 (0.00)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1 to 1</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1 to 1</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Days to next record</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">–</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">–</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">–</td></tr>
  </tbody>
  &#10;</table>
</div>

``` r
# Create a comparative boxplot of the age distribution across cohorts
plot_data <- dplyr::filter(chars, variable_name == "Age")
plotCharacteristics(plot_data, plotType = "boxplot", colour = "cohort_name")
```

![](/assets/images/rmd_output/plot-age-distribution-1.png)<!-- -->

## Step 5: Advanced Characterization with Comorbidity Flags

The `summariseCharacteristics` function allows creating custom clinical
flags with `conceptIntersectFlag` to assess pre-existing conditions in
the baseline lookback window ($[-365, 0]$ days prior to cohort entry).

``` r
# Summarize baseline comorbidity flags in the 365 days prior to index
flags_summary <- cdm$nsaids |>
  summariseCharacteristics(
    demographics = TRUE,
    conceptIntersectFlag = list(
      "Baseline Comorbidities" = list(
        conceptSet = list(
          sinusitis = 4283893L,
          gi_bleed = 192671L,
          uti = 4116491L,
          asthma = 4051466L
        ),
        window = c(-365, 0)
      )
    )
  )

# Display the enriched characteristics table
tableCharacteristics(flags_summary)
```

<div id="efemltykge" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#efemltykge table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#efemltykge thead, #efemltykge tbody, #efemltykge tfoot, #efemltykge tr, #efemltykge td, #efemltykge th {
  border-style: none;
}
&#10;#efemltykge p {
  margin: 0;
  padding: 0;
}
&#10;#efemltykge .gt_table {
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
&#10;#efemltykge .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#efemltykge .gt_title {
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
&#10;#efemltykge .gt_subtitle {
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
&#10;#efemltykge .gt_heading {
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
&#10;#efemltykge .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efemltykge .gt_col_headings {
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
&#10;#efemltykge .gt_col_heading {
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
&#10;#efemltykge .gt_column_spanner_outer {
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
&#10;#efemltykge .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#efemltykge .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#efemltykge .gt_column_spanner {
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
&#10;#efemltykge .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#efemltykge .gt_group_heading {
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
&#10;#efemltykge .gt_empty_group_heading {
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
&#10;#efemltykge .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#efemltykge .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#efemltykge .gt_row {
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
&#10;#efemltykge .gt_stub {
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
&#10;#efemltykge .gt_stub_row_group {
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
&#10;#efemltykge .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#efemltykge .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#efemltykge .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efemltykge .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#efemltykge .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#efemltykge .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efemltykge .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efemltykge .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#efemltykge .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#efemltykge .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#efemltykge .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#efemltykge .gt_footnotes {
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
&#10;#efemltykge .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efemltykge .gt_sourcenotes {
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
&#10;#efemltykge .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#efemltykge .gt_left {
  text-align: left;
}
&#10;#efemltykge .gt_center {
  text-align: center;
}
&#10;#efemltykge .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#efemltykge .gt_font_normal {
  font-weight: normal;
}
&#10;#efemltykge .gt_font_bold {
  font-weight: bold;
}
&#10;#efemltykge .gt_font_italic {
  font-style: italic;
}
&#10;#efemltykge .gt_super {
  font-size: 65%;
}
&#10;#efemltykge .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#efemltykge .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#efemltykge .gt_indent_1 {
  text-indent: 5px;
}
&#10;#efemltykge .gt_indent_2 {
  text-indent: 10px;
}
&#10;#efemltykge .gt_indent_3 {
  text-indent: 15px;
}
&#10;#efemltykge .gt_indent_4 {
  text-indent: 20px;
}
&#10;#efemltykge .gt_indent_5 {
  text-indent: 25px;
}
&#10;#efemltykge .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#efemltykge div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
  height: 0px !important;
}
</style>
<table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
  <thead>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="3" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup"></th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]CDM name&#10;[header_level]Synthea&#10;[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">CDM name</div>
      </th>
    </tr>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="3" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup"></th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_level]Synthea&#10;[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">Synthea</div>
      </th>
    </tr>
    <tr class="gt_col_headings gt_spanner_row">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Variable-name">Variable name</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Variable-level">Variable level</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="2" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="Estimate-name">Estimate name</th>
      <th class="gt_center gt_columns_top_border gt_column_spanner_outer" rowspan="1" colspan="2" style="background-color: #D9D9D9; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="colgroup" id="spanner-[header_name]Cohort name&#10;[header_level]celecoxib">
        <div class="gt_column_spanner">Cohort name</div>
      </th>
    </tr>
    <tr class="gt_col_headings">
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]CDM-name-[header_level]Synthea-[header_name]Cohort-name-[header_level]celecoxib">celecoxib</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]CDM-name-[header_level]Synthea-[header_name]Cohort-name-[header_level]diclofenac">diclofenac</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Number records</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Number subjects</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Cohort start date</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2000-03-02 [1988-06-22 - 2008-11-23]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1999-04-21 [1987-11-05 - 2007-11-13]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1941-12-05 to 2019-04-14</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1943-07-03 to 2019-03-15</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Cohort end date</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">2000-03-02 [1988-06-22 - 2008-11-23]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1999-04-21 [1987-11-05 - 2007-11-13]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1941-12-05 to 2019-04-14</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1943-07-03 to 2019-03-15</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Age</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">38.00 [36.00 - 41.00]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">38.00 [36.00 - 41.00]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">38.17 (3.28)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">38.10 (3.26)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">31.00 to 46.00</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">31.00 to 46.00</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Sex</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Female</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">906 (50.33%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">435 (52.41%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Male</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">894 (49.67%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">395 (47.59%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Prior observation</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">14,100.00 [13,160.00 - 15,040.00]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">14,040.00 [13,185.00 - 15,037.75]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">14,114.68 (1,195.71)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">14,087.07 (1,188.03)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">11,369.00 to 17,044.00</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">11,340.00 to 16,805.00</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Future observation</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">6,679.00 [3,445.00 - 10,650.00]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">7,024.00 [3,831.00 - 11,013.25]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">7,588.08 (5,352.39)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">7,900.78 (5,387.34)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">10.00 to 28,328.00</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">23.00 to 27,108.00</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Days in cohort</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1 [1 - 1]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1 [1 - 1]</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1.00 (0.00)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1.00 (0.00)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1 to 1</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">1 to 1</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Days to next record</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Median [Q25 - Q75]</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">–</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Mean (SD)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">–</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);"></td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Range</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">–</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Baseline comorbidities</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Uti</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">7 (0.39%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">4 (0.48%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Sinusitis</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">19 (1.06%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">4 (0.48%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Asthma</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 (0.00%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0 (0.00%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Gi bleed</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 (0.00%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_left" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0 (0.00%)</td></tr>
  </tbody>
  &#10;</table>
</div>


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

<div id="qfxbyluvgy" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#qfxbyluvgy table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#qfxbyluvgy thead, #qfxbyluvgy tbody, #qfxbyluvgy tfoot, #qfxbyluvgy tr, #qfxbyluvgy td, #qfxbyluvgy th {
  border-style: none;
}
&#10;#qfxbyluvgy p {
  margin: 0;
  padding: 0;
}
&#10;#qfxbyluvgy .gt_table {
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
&#10;#qfxbyluvgy .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#qfxbyluvgy .gt_title {
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
&#10;#qfxbyluvgy .gt_subtitle {
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
&#10;#qfxbyluvgy .gt_heading {
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
&#10;#qfxbyluvgy .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#qfxbyluvgy .gt_col_headings {
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
&#10;#qfxbyluvgy .gt_col_heading {
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
&#10;#qfxbyluvgy .gt_column_spanner_outer {
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
&#10;#qfxbyluvgy .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#qfxbyluvgy .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#qfxbyluvgy .gt_column_spanner {
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
&#10;#qfxbyluvgy .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#qfxbyluvgy .gt_group_heading {
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
&#10;#qfxbyluvgy .gt_empty_group_heading {
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
&#10;#qfxbyluvgy .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#qfxbyluvgy .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#qfxbyluvgy .gt_row {
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
&#10;#qfxbyluvgy .gt_stub {
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
&#10;#qfxbyluvgy .gt_stub_row_group {
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
&#10;#qfxbyluvgy .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#qfxbyluvgy .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#qfxbyluvgy .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qfxbyluvgy .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#qfxbyluvgy .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#qfxbyluvgy .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#qfxbyluvgy .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qfxbyluvgy .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#qfxbyluvgy .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#qfxbyluvgy .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#qfxbyluvgy .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#qfxbyluvgy .gt_footnotes {
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
&#10;#qfxbyluvgy .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qfxbyluvgy .gt_sourcenotes {
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
&#10;#qfxbyluvgy .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#qfxbyluvgy .gt_left {
  text-align: left;
}
&#10;#qfxbyluvgy .gt_center {
  text-align: center;
}
&#10;#qfxbyluvgy .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#qfxbyluvgy .gt_font_normal {
  font-weight: normal;
}
&#10;#qfxbyluvgy .gt_font_bold {
  font-weight: bold;
}
&#10;#qfxbyluvgy .gt_font_italic {
  font-style: italic;
}
&#10;#qfxbyluvgy .gt_super {
  font-size: 65%;
}
&#10;#qfxbyluvgy .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#qfxbyluvgy .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#qfxbyluvgy .gt_indent_1 {
  text-indent: 5px;
}
&#10;#qfxbyluvgy .gt_indent_2 {
  text-indent: 10px;
}
&#10;#qfxbyluvgy .gt_indent_3 {
  text-indent: 15px;
}
&#10;#qfxbyluvgy .gt_indent_4 {
  text-indent: 20px;
}
&#10;#qfxbyluvgy .gt_indent_5 {
  text-indent: 25px;
}
&#10;#qfxbyluvgy .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#qfxbyluvgy div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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

<div id="dvvflgpzxo" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#dvvflgpzxo table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#dvvflgpzxo thead, #dvvflgpzxo tbody, #dvvflgpzxo tfoot, #dvvflgpzxo tr, #dvvflgpzxo td, #dvvflgpzxo th {
  border-style: none;
}
&#10;#dvvflgpzxo p {
  margin: 0;
  padding: 0;
}
&#10;#dvvflgpzxo .gt_table {
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
&#10;#dvvflgpzxo .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#dvvflgpzxo .gt_title {
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
&#10;#dvvflgpzxo .gt_subtitle {
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
&#10;#dvvflgpzxo .gt_heading {
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
&#10;#dvvflgpzxo .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#dvvflgpzxo .gt_col_headings {
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
&#10;#dvvflgpzxo .gt_col_heading {
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
&#10;#dvvflgpzxo .gt_column_spanner_outer {
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
&#10;#dvvflgpzxo .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#dvvflgpzxo .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#dvvflgpzxo .gt_column_spanner {
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
&#10;#dvvflgpzxo .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#dvvflgpzxo .gt_group_heading {
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
&#10;#dvvflgpzxo .gt_empty_group_heading {
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
&#10;#dvvflgpzxo .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#dvvflgpzxo .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#dvvflgpzxo .gt_row {
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
&#10;#dvvflgpzxo .gt_stub {
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
&#10;#dvvflgpzxo .gt_stub_row_group {
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
&#10;#dvvflgpzxo .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#dvvflgpzxo .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#dvvflgpzxo .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#dvvflgpzxo .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#dvvflgpzxo .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#dvvflgpzxo .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#dvvflgpzxo .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#dvvflgpzxo .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#dvvflgpzxo .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#dvvflgpzxo .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#dvvflgpzxo .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#dvvflgpzxo .gt_footnotes {
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
&#10;#dvvflgpzxo .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#dvvflgpzxo .gt_sourcenotes {
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
&#10;#dvvflgpzxo .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#dvvflgpzxo .gt_left {
  text-align: left;
}
&#10;#dvvflgpzxo .gt_center {
  text-align: center;
}
&#10;#dvvflgpzxo .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#dvvflgpzxo .gt_font_normal {
  font-weight: normal;
}
&#10;#dvvflgpzxo .gt_font_bold {
  font-weight: bold;
}
&#10;#dvvflgpzxo .gt_font_italic {
  font-style: italic;
}
&#10;#dvvflgpzxo .gt_super {
  font-size: 65%;
}
&#10;#dvvflgpzxo .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#dvvflgpzxo .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#dvvflgpzxo .gt_indent_1 {
  text-indent: 5px;
}
&#10;#dvvflgpzxo .gt_indent_2 {
  text-indent: 10px;
}
&#10;#dvvflgpzxo .gt_indent_3 {
  text-indent: 15px;
}
&#10;#dvvflgpzxo .gt_indent_4 {
  text-indent: 20px;
}
&#10;#dvvflgpzxo .gt_indent_5 {
  text-indent: 25px;
}
&#10;#dvvflgpzxo .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#dvvflgpzxo div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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
# Display concise baseline characteristics table
chars |>
  dplyr::filter(variable_name %in% c("Number subjects", "Age", "Sex", "Prior observation")) |>
  tableCharacteristics()
```

<div id="orioosaovj" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#orioosaovj table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#orioosaovj thead, #orioosaovj tbody, #orioosaovj tfoot, #orioosaovj tr, #orioosaovj td, #orioosaovj th {
  border-style: none;
}
&#10;#orioosaovj p {
  margin: 0;
  padding: 0;
}
&#10;#orioosaovj .gt_table {
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
&#10;#orioosaovj .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#orioosaovj .gt_title {
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
&#10;#orioosaovj .gt_subtitle {
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
&#10;#orioosaovj .gt_heading {
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
&#10;#orioosaovj .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#orioosaovj .gt_col_headings {
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
&#10;#orioosaovj .gt_col_heading {
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
&#10;#orioosaovj .gt_column_spanner_outer {
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
&#10;#orioosaovj .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#orioosaovj .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#orioosaovj .gt_column_spanner {
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
&#10;#orioosaovj .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#orioosaovj .gt_group_heading {
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
&#10;#orioosaovj .gt_empty_group_heading {
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
&#10;#orioosaovj .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#orioosaovj .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#orioosaovj .gt_row {
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
&#10;#orioosaovj .gt_stub {
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
&#10;#orioosaovj .gt_stub_row_group {
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
&#10;#orioosaovj .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#orioosaovj .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#orioosaovj .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#orioosaovj .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#orioosaovj .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#orioosaovj .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#orioosaovj .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#orioosaovj .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#orioosaovj .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#orioosaovj .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#orioosaovj .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#orioosaovj .gt_footnotes {
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
&#10;#orioosaovj .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#orioosaovj .gt_sourcenotes {
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
&#10;#orioosaovj .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#orioosaovj .gt_left {
  text-align: left;
}
&#10;#orioosaovj .gt_center {
  text-align: center;
}
&#10;#orioosaovj .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#orioosaovj .gt_font_normal {
  font-weight: normal;
}
&#10;#orioosaovj .gt_font_bold {
  font-weight: bold;
}
&#10;#orioosaovj .gt_font_italic {
  font-style: italic;
}
&#10;#orioosaovj .gt_super {
  font-size: 65%;
}
&#10;#orioosaovj .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#orioosaovj .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#orioosaovj .gt_indent_1 {
  text-indent: 5px;
}
&#10;#orioosaovj .gt_indent_2 {
  text-indent: 10px;
}
&#10;#orioosaovj .gt_indent_3 {
  text-indent: 15px;
}
&#10;#orioosaovj .gt_indent_4 {
  text-indent: 20px;
}
&#10;#orioosaovj .gt_indent_5 {
  text-indent: 25px;
}
&#10;#orioosaovj .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#orioosaovj div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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
    demographics = FALSE,
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

<div id="envtouvjnq" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
<style>#envtouvjnq table {
  font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
&#10;#envtouvjnq thead, #envtouvjnq tbody, #envtouvjnq tfoot, #envtouvjnq tr, #envtouvjnq td, #envtouvjnq th {
  border-style: none;
}
&#10;#envtouvjnq p {
  margin: 0;
  padding: 0;
}
&#10;#envtouvjnq .gt_table {
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
&#10;#envtouvjnq .gt_caption {
  padding-top: 4px;
  padding-bottom: 4px;
}
&#10;#envtouvjnq .gt_title {
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
&#10;#envtouvjnq .gt_subtitle {
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
&#10;#envtouvjnq .gt_heading {
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
&#10;#envtouvjnq .gt_bottom_border {
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#envtouvjnq .gt_col_headings {
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
&#10;#envtouvjnq .gt_col_heading {
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
&#10;#envtouvjnq .gt_column_spanner_outer {
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
&#10;#envtouvjnq .gt_column_spanner_outer:first-child {
  padding-left: 0;
}
&#10;#envtouvjnq .gt_column_spanner_outer:last-child {
  padding-right: 0;
}
&#10;#envtouvjnq .gt_column_spanner {
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
&#10;#envtouvjnq .gt_spanner_row {
  border-bottom-style: hidden;
}
&#10;#envtouvjnq .gt_group_heading {
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
&#10;#envtouvjnq .gt_empty_group_heading {
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
&#10;#envtouvjnq .gt_from_md > :first-child {
  margin-top: 0;
}
&#10;#envtouvjnq .gt_from_md > :last-child {
  margin-bottom: 0;
}
&#10;#envtouvjnq .gt_row {
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
&#10;#envtouvjnq .gt_stub {
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
&#10;#envtouvjnq .gt_stub_row_group {
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
&#10;#envtouvjnq .gt_row_group_first td {
  border-top-width: 2px;
}
&#10;#envtouvjnq .gt_row_group_first th {
  border-top-width: 2px;
}
&#10;#envtouvjnq .gt_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#envtouvjnq .gt_first_summary_row {
  border-top-style: solid;
  border-top-color: #D3D3D3;
}
&#10;#envtouvjnq .gt_first_summary_row.thick {
  border-top-width: 2px;
}
&#10;#envtouvjnq .gt_last_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#envtouvjnq .gt_grand_summary_row {
  color: #333333;
  background-color: #FFFFFF;
  text-transform: inherit;
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#envtouvjnq .gt_first_grand_summary_row {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-top-style: double;
  border-top-width: 6px;
  border-top-color: #D3D3D3;
}
&#10;#envtouvjnq .gt_last_grand_summary_row_top {
  padding-top: 8px;
  padding-bottom: 8px;
  padding-left: 5px;
  padding-right: 5px;
  border-bottom-style: double;
  border-bottom-width: 6px;
  border-bottom-color: #D3D3D3;
}
&#10;#envtouvjnq .gt_striped {
  background-color: rgba(128, 128, 128, 0.05);
}
&#10;#envtouvjnq .gt_table_body {
  border-top-style: solid;
  border-top-width: 3px;
  border-top-color: #D9D9D9;
  border-bottom-style: solid;
  border-bottom-width: 2px;
  border-bottom-color: #D3D3D3;
}
&#10;#envtouvjnq .gt_footnotes {
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
&#10;#envtouvjnq .gt_footnote {
  margin: 0px;
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#envtouvjnq .gt_sourcenotes {
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
&#10;#envtouvjnq .gt_sourcenote {
  font-size: 90%;
  padding-top: 4px;
  padding-bottom: 4px;
  padding-left: 5px;
  padding-right: 5px;
}
&#10;#envtouvjnq .gt_left {
  text-align: left;
}
&#10;#envtouvjnq .gt_center {
  text-align: center;
}
&#10;#envtouvjnq .gt_right {
  text-align: right;
  font-variant-numeric: tabular-nums;
}
&#10;#envtouvjnq .gt_font_normal {
  font-weight: normal;
}
&#10;#envtouvjnq .gt_font_bold {
  font-weight: bold;
}
&#10;#envtouvjnq .gt_font_italic {
  font-style: italic;
}
&#10;#envtouvjnq .gt_super {
  font-size: 65%;
}
&#10;#envtouvjnq .gt_footnote_marks {
  font-size: 75%;
  vertical-align: 0.4em;
  position: initial;
}
&#10;#envtouvjnq .gt_asterisk {
  font-size: 100%;
  vertical-align: 0;
}
&#10;#envtouvjnq .gt_indent_1 {
  text-indent: 5px;
}
&#10;#envtouvjnq .gt_indent_2 {
  text-indent: 10px;
}
&#10;#envtouvjnq .gt_indent_3 {
  text-indent: 15px;
}
&#10;#envtouvjnq .gt_indent_4 {
  text-indent: 20px;
}
&#10;#envtouvjnq .gt_indent_5 {
  text-indent: 25px;
}
&#10;#envtouvjnq .katex-display {
  display: inline-flex !important;
  margin-bottom: 0.75em !important;
}
&#10;#envtouvjnq div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
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
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]CDM-name-[header_level]Synthea-[header_name]Cohort-name-[header_level]celecoxib">celecoxib</th>
      <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" style="background-color: #E1E1E1; font-family: Arial; font-size: 10; text-align: center; font-weight: bold; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;" scope="col" id="[header_name]CDM-name-[header_level]Synthea-[header_name]Cohort-name-[header_level]diclofenac">diclofenac</th>
    </tr>
  </thead>
  <tbody class="gt_table_body">
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Number records</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Number subjects</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">–</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">1,800</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">830</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">Baseline comorbidities</td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Sinusitis</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">19 (1.06%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">4 (0.48%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Uti</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">7 (0.39%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">4 (0.48%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Asthma</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 (0.00%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0 (0.00%)</td></tr>
    <tr><td headers="Variable name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: hidden; border-top-color: #000000; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;"></td>
<td headers="Variable level" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">Gi bleed</td>
<td headers="Estimate name" class="gt_row gt_left" style="text-align: left; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">N (%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]celecoxib" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8; background-color: rgba(255,255,255,0);">0 (0.00%)</td>
<td headers="[header_name]CDM name
[header_level]Synthea
[header_name]Cohort name
[header_level]diclofenac" class="gt_row gt_right" style="text-align: right; font-family: Arial; font-size: 10; background-color: rgba(255,255,255,0); border-left-width: 1px; border-left-style: solid; border-left-color: #c8c8c8; border-right-width: 1px; border-right-style: solid; border-right-color: #c8c8c8; border-top-width: 1px; border-top-style: solid; border-top-color: #c8c8c8; border-bottom-width: 1px; border-bottom-style: solid; border-bottom-color: #c8c8c8;">0 (0.00%)</td></tr>
  </tbody>
  &#10;</table>
</div>

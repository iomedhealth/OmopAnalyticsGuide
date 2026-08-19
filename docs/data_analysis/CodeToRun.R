# Setup Verification Script for OMOP Data Analysis
# Run this script to verify that your R environment is correctly configured.

library(DBI)
library(duckdb)
library(dplyr)
library(omopgenerics)
library(CDMConnector)
library(CohortConstructor)
library(CohortCharacteristics)
library(PatientProfiles)
library(visOmopResults)

message("1. Checking connection to synthetic OMOP database...")
con <- DBI::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir())
cdm <- CDMConnector::cdmFromCon(con = con, cdmSchema = "main", writeSchema = "main")

message("2. Generating test cohort (chronic_sinusitis)...")
cdm$my_cohort <- cdm |>
  CohortConstructor::conceptCohort(
    conceptSet = list(chronic_sinusitis = 4294548L),
    name = "my_cohort"
  )

message("3. Cohort settings:")
print(omopgenerics::settings(cdm$my_cohort))

message("4. Cohort counts:")
print(omopgenerics::cohortCount(cdm$my_cohort))

# Clean up connection
DBI::dbDisconnect(con, shutdown = TRUE)

message("Environment verification successful! You are ready to analyze OMOP CDM data.")

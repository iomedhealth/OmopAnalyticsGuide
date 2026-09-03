# OMOP Analytics Workflow Documentation

A comprehensive documentation site introducing the analytics workflow for the
Observational Medical Outcomes Partnership (OMOP) Common Data Model.

## Overview

This repository contains educational materials and documentation for conducting
real-world evidence studies using the OMOP CDM format. The site introduces a
complete analytics ecosystem of R packages designed for observational health
data analysis.

## Libraries

| Library | URL |
|---------|-----|
| CDMConnector | https://darwin-eu.github.io/CDMConnector/ |
| CodelistGenerator | https://darwin-eu.github.io/CodelistGenerator/ |
| CohortCharacteristics | https://darwin-eu.github.io/CohortCharacteristics/ |
| CohortConstructor | https://ohdsi.github.io/CohortConstructor/ |
| CohortCosts | https://iomedhealth.github.io/omopHeor/ |
| CohortEconomics | https://iomedhealth.github.io/omopHeor/ |
| CohortSurvival | https://darwin-eu.github.io/CohortSurvival/ |
| CohortSymmetry | https://ohdsi.github.io/CohortSymmetry/ |
| CohortUtilisation | https://iomedhealth.github.io/omopHeor/ |
| DrugUtilisation | https://darwin-eu.github.io/DrugUtilisation/ |
| EpiStandard | https://oxford-pharmacoepi.github.io/EpiStandard/ |
| IncidencePrevalence | https://darwin-eu.github.io/IncidencePrevalence/ |
| MeasurementDiagnostics | https://ohdsi.github.io/MeasurementDiagnostics/ |
| omock | https://ohdsi.github.io/omock/ |
| OmopConstructor | https://ohdsi.github.io/OmopConstructor/ |
| OmopHelpers | https://github.com/iomedhealth/OmopHelpers |
| omopgenerics | https://darwin-eu.github.io/omopgenerics/ |
| OmopSketch | https://ohdsi.github.io/OmopSketch/ |
| OmopStudyBuilder | https://oxford-pharmacoepi.github.io/OmopStudyBuilder/ |
| OmopViewer | https://ohdsi.github.io/OmopViewer/ |
| PatientProfiles | https://darwin-eu.github.io/PatientProfiles/ |
| PhenotypeR | https://ohdsi.github.io/PhenotypeR/ |
| visOmopResults | https://darwin-eu.github.io/visOmopResults/ |

## Publishing the Site

This Jekyll site is automatically built and deployed using GitHub Pages. To run the site locally for development:

1. **Install dependencies**: `bundle install`
2. **Build the site**: `bundle exec jekyll build`
3. **Run locally**: `bundle exec jekyll serve`

Changes pushed to the `main` branch will trigger a GitHub Actions workflow to publish the site.

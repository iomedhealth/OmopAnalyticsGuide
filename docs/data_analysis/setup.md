---
layout: default
title: Setup
parent: Performing an Analysis
grand_parent: Data Analysis
nav_order: 1
---

# Environment Setup Guide

This document provides step-by-step instructions for setting up your local R environment to analyze OMOP CDM data. Following these steps will ensure you have the necessary software, packages, and mock data to run the tutorials in this guide.

## 1. Prerequisite Software Installation

Before you begin, you must install three key pieces of software:

*   **R:** The core programming language for statistical computing that will run our analysis. You will need version 4.2 or higher, available from the [Comprehensive R Archive Network (CRAN)](https://cran.r-project.org/).
*   **RStudio:** An Integrated Development Environment (IDE) that provides a user-friendly interface for writing and running R code. We will be working within RStudio for this guide. Download the free RStudio Desktop version from [Posit's website](https://posit.co/download/rstudio-desktop/).
*   **RTools:** A set of background utilities required for installing some advanced R packages. Some packages need to be compiled specifically for your computer, and RTools handles this complex process for you automatically. You will not need to use it directly. You can download it from [CRAN's RTools page](https://cran.r-project.org/bin/windows/Rtools/).

## 2. Project Setup

This guide is structured as an RStudio Project, which helps keep all files organized and ensures that code runs in the correct directory.

1.  **Get the project files:** If you have received the project as a `.zip` file, please uncompress it first. If you are viewing this guide online, there will be a button to download the entire project as a `.zip` file.
2.  Navigate to the project's root directory on your computer.
3.  Double-click the `.Rproj` file to open the project in RStudio.
4.  Verify that the project name appears in the top-right corner of the RStudio window.

## 3. R Package Installation

The analytical workflows in this guide depend on a rich ecosystem of R **packages**. Packages are collections of functions and code that extend R's capabilities, similar to add-ins in other software. The packages we will install provide tools for connecting to databases, manipulating data, and running specific OMOP analyses.

In the **R Console** (the window in RStudio where you type commands), run the following command to install all required packages. This may take several minutes.

> **Note:** You will see a lot of text printed to the console during this process, which is normal. As long as you do not see a final message that explicitly says 'Error:', the installation was likely successful.

```r
install.packages(c(
  "DBI",
  "duckdb",
  "here",
  "usethis",
  "dplyr",
  "dbplyr",
  "CDMConnector",
  "PatientProfiles",
  "IncidencePrevalence",
  "CohortConstructor",
  "DrugUtilisation",
  "OmopSketch",
  "visOmopResults",
  "CohortCharacteristics",
  "OmopStudyBuilder"
))
```

## 4. Mock Database Configuration (Eunomia)

For the tutorials, we will use Eunomia, a mock dataset that is synthetically generated and mapped to the OMOP CDM.

1.  **Download the Eunomia Data:** In the RStudio console, run the following command. This will download the dataset into your project's root directory. The `::` syntax is R's way of specifying that the `downloadEunomiaData` function is from the `CDMConnector` package, and `here::here()` is a helper function that provides the path to your project's home directory.
    ```r
    CDMConnector::downloadEunomiaData(
      pathToData = here::here(),
      overwrite = TRUE
    )
    ```
2.  **Set an Environment Variable:** To ensure R can always find the mock data, we will store its location in a central configuration file called `.Renviron`. An **environment variable** is a standard way to store configuration settings outside of the analysis code itself.

    Run this command in the R console to open the file for editing:
    ```r
    usethis::edit_r_environ()
    ```
3.  **Add the File Path:** A new script window will open. In this window, add the following line, replacing `"full/path/to/your/project/Eunomia.zip"` with the actual, full path to the `Eunomia.zip` file that was downloaded in step 1.

    > **Pro Tip:** An easy way to get the full file path is to find the `Eunomia.zip` file in the **Files pane** in RStudio (bottom-right), right-click on it, and select "Copy Path".

    ```
    EUNOMIA_DATA_FOLDER = "full/path/to/your/project/Eunomia.zip"
    ```
4.  **Restart R:** For the changes to take effect, you must restart your R session. You can do this by going to `Session > Restart R` in the RStudio menu.

## 5. Setup Verification

After completing all the previous steps, you can verify that your environment is correctly configured by running a test **script**. A script is a text file containing a set of commands for R to execute sequentially.

The verification script will perform the following actions:
1.  Load all the installed packages.
2.  Connect to the mock Eunomia database.
3.  Define and create a simple patient cohort.
4.  Print the settings of the created cohort to the console.

**To run the verification:**

1.  In the RStudio **Files pane** (typically in the bottom-right), navigate to the `docs/data_analysis/` folder.
2.  Click on the `CodeToRun.R` file to open it in the script editor.
3.  Run the entire script by clicking the **Run** button at the top of the script editor, or by using the keyboard shortcut `Ctrl+Alt+R` (Windows) or `Cmd+Option+R` (Mac).

If the script runs without any error messages in the console and you see a table output with the settings of "my_cohort," your setup is correct and you are ready to proceed. The output in your console should look similar to this:

```
# A tibble: 1 × 2
  cohort_definition_id cohort_name
                 <int> <chr>
1                    1 chronic_sinusitis
```

## Next Steps

Once the environment is configured and verified, you are ready to begin your analysis. The typical workflow is as follows:

1.  **Database Exploration**: Use [`OmopSketch`](https://darwin-eu.github.io/OmopSketch/) to characterize your database structure.
2.  **Concept Definition**: Create medical concept lists with [`CodelistGenerator`](https://darwin-eu.github.io/CodelistGenerator/).
3.  **Cohort Building**: Define patient populations using [`CohortConstructor`](https://ohdsi.github.io/CohortConstructor/).
4.  **Population Analysis**: Characterize cohorts with [`CohortCharacteristics`](https://darwin-eu.github.io/CohortCharacteristics/).
5.  **Specialized Studies**: Conduct domain-specific analyses with [`DrugUtilisation`](https://darwin-eu.github.io/DrugUtilisation/), [`IncidencePrevalence`](https://darwin-eu.github.io/IncidencePrevalence/), or [`CohortSurvival`](https://darwin-eu-dev.github.io/CohortSurvival/).

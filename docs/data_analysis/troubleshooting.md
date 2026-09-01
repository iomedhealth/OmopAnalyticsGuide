---
layout: default
title: Troubleshooting
parent: Data Analysis
nav_order: 6
---

# Troubleshooting Guide
{: .no_toc}

1. TOC
{:toc}

This guide provides fast solutions to common issues encountered during environment setup, package installation, database connection, and OMOP analysis execution.

---

## 1. Never-Ending Package Installation (DuckDB & C++ Packages)

### Symptom
When installing packages (particularly `duckdb` or packages that depend on it), R freezes or hangs for 15–30+ minutes at messages such as:
```
* installing *source* package 'duckdb' ...
** package 'duckdb' successfully unpacked and MD5 sums checked
** using staged installation
** libs
clang++ -arch arm64 -std=gnu++17 -I"/Library/Frameworks/R.framework/Resources/include" ...
```
CPU utilization spikes to 100%, cooling fans spin up, or the R session crashes due to out-of-memory errors.

### Root Cause
DuckDB is a complete, high-performance analytical database engine written in C++. When installed from **source**, R must compile millions of lines of C++ code locally. If R prompts:
> *"There is a binary version available but the source version is later: Do you want to install from sources the package which needs compilation? (Yes/no/cancel)"*

and you answer **Yes** (or if running on Linux where CRAN defaults to source packages), R will compile DuckDB from scratch rather than downloading a ready-to-use binary.

### Solution: Force Precompiled Binary Installation

Always install precompiled binaries for DuckDB. Choose the method matching your environment:

#### Option A: DuckDB Official R-Universe (Recommended for all platforms)
DuckDB maintains continuously updated binary builds for macOS and Windows on R-Universe. Installation takes ~3 seconds:

```r
install.packages(
  "duckdb",
  repos = c("https://duckdb.r-universe.dev", "https://cloud.r-project.org")
)
```

#### Option B: Force Binary on macOS & Windows
Force CRAN to supply the precompiled binary and skip source compilation:

```r
install.packages("duckdb", type = "binary")
```

> **Rule of Thumb:** If R asks whether to install from sources because a newer version exists, always select **`No`**.

#### Option C: Linux Distributions (Ubuntu, Debian, RHEL)
Standard CRAN does not distribute Linux binaries. Configure [Posit Public Package Manager (P3M)](https://packagemanager.posit.co/) to automatically download precompiled Linux binaries:

```r
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))
install.packages("duckdb")
```

#### Option D: Use the `pak` Package Manager
The `pak` package manager automatically discovers and installs pre-built binaries across all platforms:

```r
install.packages("pak")
pak::pkg_install("duckdb")
```

---

## 2. DuckDB Database File Locking (`Could not set lock on file`)

### Symptom
```
Error: rapi_execute: Failed to run query
IO Error: Could not set lock on file "/path/to/database.duckdb": Resource temporarily unavailable
```

### Root Cause
DuckDB restricts multiple simultaneous write processes to a single database file. If an RStudio session, another R process, or a background worker has an active write lock on the `.duckdb` file, subsequent connection attempts fail.

### Solution
1. **Explicitly Disconnect Inactive Sessions**:
   ```r
   DBI::dbDisconnect(con, shutdown = TRUE)
   ```
2. **Open in Read-Only Mode**: If multiple processes need to query the database simultaneously, open the connection in read-only mode:
   ```r
   con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "path/to/database.duckdb", read_only = TRUE)
   ```
3. **Restart R Session**: If an orphaned background lock persists, restart your R session via `Session > Restart R` in RStudio (`Ctrl+Shift+F10` / `Cmd+Shift+0`).

---

## 3. Mock Dataset Not Found (`Eunomia data not found`)

### Symptom
```
Error in downloadEunomiaData: Eunomia dataset not found or corrupted.
```
or `eunomiaDir()` returns an empty string or error when running examples.

### Solution
1. **Re-download the Eunomia Dataset**:
   ```r
   CDMConnector::downloadEunomiaData(
     pathToData = here::here(),
     overwrite = TRUE
   )
   ```
2. **Configure `.Renviron`**:
   Open `.Renviron` in RStudio:
   ```r
   usethis::edit_r_environ()
   ```
   Add the absolute path to your `Eunomia.zip` dataset:
   ```
   EUNOMIA_DATA_FOLDER = "/absolute/path/to/project/Eunomia.zip"
   ```
3. **Restart R** to reload environment variables.

---

## 4. Out of Memory Errors During Cohort Operations

### Symptom
RStudio aborts with *"R session aborted"* or system memory usage grows unbounded when manipulating large cohorts or executing joins.

### Root Cause
Calling `collect()` or `as.data.frame()` pulls full database tables into local R RAM instead of letting DuckDB execute queries inside the database engine.

### Solution
- Keep operations lazy inside DuckDB and materialize intermediate tables using `compute()`:
  ```r
  # Efficient: Computes inside DuckDB without pulling data into local RAM
  cdm$my_cohort <- cdm$my_cohort |>
    requireDemographics(ageRange = list(c(18, 65))) |>
    compute(name = "my_cohort", temporary = FALSE)
  ```
- Only call `collect()` on final, aggregated summary tables (e.g. results from `summariseCharacteristics()` or `summariseCohortAttrition()`).

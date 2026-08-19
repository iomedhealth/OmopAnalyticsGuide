# Page: Development Environment

# Development Environment

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [.gitignore](.gitignore)
- [Makefile](Makefile)
- [StandardStudies/.Rhistory](StandardStudies/.Rhistory)
- [assets/images/android-chrome-192x192.png](assets/images/android-chrome-192x192.png)
- [assets/images/android-chrome-512x512.png](assets/images/android-chrome-512x512.png)
- [assets/images/apple-touch-icon.png](assets/images/apple-touch-icon.png)
- [docs/data_analysis/performing_analysis.md](docs/data_analysis/performing_analysis.md)

</details>



This document provides a comprehensive guide for setting up the local development environment needed to contribute to the OMOP Analytics Guide repository. It covers the Jekyll documentation system, R analytics environment, build automation tools, and local development workflows.

For information about the automated content generation system, see [Content Scraping and Generation](#5.1). For details on Jekyll site configuration and deployment, see [Jekyll Site Configuration](#5.2).

## Environment Components

The development environment consists of multiple interconnected systems that support both documentation generation and analytics development.

### Core Development Stack

```mermaid
graph TB
    subgraph "Local Development Environment"
        RUBY["Ruby Runtime<br/>(/opt/homebrew/opt/ruby/bin)"]
        BUNDLER["Bundler<br/>(Gem Management)"]
        JEKYLL["Jekyll<br/>(Static Site Generator)"]
        MAKE["Makefile<br/>(Build Automation)"]
    end
    
    subgraph "R Analytics Environment" 
        R_RUNTIME["R Runtime"]
        RENV["renv<br/>(Package Management)"]
        PACKAGES["OMOP Packages<br/>(CDMConnector, etc.)"]
        RSTUDIO["RStudio/IDE<br/>(Optional)"]
    end
    
    subgraph "Content Generation Tools"
        PYTHON["Python<br/>(Scraping Scripts)"]
        BASH["Bash Scripts<br/>(Content Processing)"]
        UTILS["utils/ Directory<br/>(Automation)"]
    end
    
    RUBY --> BUNDLER
    BUNDLER --> JEKYLL
    MAKE --> JEKYLL
    MAKE --> UTILS
    
    R_RUNTIME --> RENV
    RENV --> PACKAGES
    PACKAGES --> RSTUDIO
    
    PYTHON --> UTILS
    BASH --> UTILS
    
    JEKYLL -.->|"Renders"| PACKAGES
```

Sources: [Makefile:1-66](), [.gitignore:1-25]()

### Ruby and Jekyll Setup

The documentation system requires Ruby and Jekyll for static site generation. The Makefile configures specific Ruby paths and gem management.

```mermaid
graph LR
    subgraph "Ruby Configuration"
        RUBY_PATH["RUBY_PATH<br/>(/opt/homebrew/opt/ruby/bin)"]
        GEM_HOME["GEM_HOME<br/>(Gem Installation Path)"]
        GEM_PATH["GEM_PATH<br/>(Gem Search Path)"]
    end
    
    subgraph "Jekyll Dependencies"
        GEMFILE["Gemfile<br/>(Dependency Definition)"]
        BUNDLER_INSTALL["bundle install<br/>(Dependency Resolution)"]
        JEKYLL_SERVE["jekyll serve<br/>(Development Server)"]
        JEKYLL_BUILD["jekyll build<br/>(Production Build)"]
    end
    
    RUBY_PATH --> GEM_HOME
    RUBY_PATH --> GEM_PATH
    GEMFILE --> BUNDLER_INSTALL
    BUNDLER_INSTALL --> JEKYLL_SERVE
    BUNDLER_INSTALL --> JEKYLL_BUILD
```

Sources: [Makefile:8-13](), [Makefile:31-46]()

## Makefile-Based Build System

The repository uses a comprehensive Makefile to automate common development tasks and provide a consistent interface for build operations.

### Available Make Targets

| Target | Description | Command |
|--------|-------------|---------|
| `install` | Install Ruby dependencies | `bundle install` |
| `serve` | Start Jekyll development server | `jekyll serve` |
| `build` | Build static site for production | `jekyll build` |
| `clean` | Clean Jekyll build artifacts | `jekyll clean` |
| `scrape_all` | Execute content scraping workflow | `bash scrape_all.sh` |
| `merge_interim` | Merge interim markdown files | `bash merge_interim.sh` |
| `merge_md` | Merge raw markdown files | `bash merge_md.sh` |
| `debug` | Display bundle executable path | `which bundle` |

Sources: [Makefile:17-62]()

### Build Workflow Architecture

```mermaid
flowchart TD
    DEV_START["Developer Starts Work"]
    
    subgraph "Initial Setup"
        MAKE_INSTALL["make install<br/>(Install Dependencies)"]
        CHECK_RUBY["Verify Ruby Environment<br/>(RUBY_PATH Configuration)"]
    end
    
    subgraph "Development Workflow"
        MAKE_SERVE["make serve<br/>(Start Dev Server)"]
        LOCAL_DEV["Local Development<br/>(Edit Files)"]
        AUTO_RELOAD["Auto-reload<br/>(Jekyll Watch)"]
    end
    
    subgraph "Content Generation" 
        SCRAPE["make scrape_all<br/>(Generate Content)"]
        MERGE["make merge_*<br/>(Process Content)"]
    end
    
    subgraph "Production Build"
        MAKE_BUILD["make build<br/>(Production Assets)"]
        MAKE_CLEAN["make clean<br/>(Cleanup)"]
    end
    
    DEV_START --> MAKE_INSTALL
    MAKE_INSTALL --> CHECK_RUBY
    CHECK_RUBY --> MAKE_SERVE
    MAKE_SERVE --> LOCAL_DEV
    LOCAL_DEV --> AUTO_RELOAD
    AUTO_RELOAD --> LOCAL_DEV
    
    LOCAL_DEV -.->|"Update Content"| SCRAPE
    SCRAPE --> MERGE
    MERGE --> LOCAL_DEV
    
    LOCAL_DEV -.->|"Deploy"| MAKE_BUILD
    MAKE_BUILD --> MAKE_CLEAN
```

Sources: [Makefile:35-62]()

## R Environment Setup

The analytics components require a properly configured R environment with specific packages for OMOP CDM analysis.

### R Package Management

The R environment uses `renv` for reproducible package management and includes specialized OMOP analytics packages.

```mermaid
graph TB
    subgraph "R Environment Structure"
        R_BASE["R Base Installation"]
        RENV_SYSTEM["renv System<br/>(.Rprofile, renv.lock)"]
        RENV_CACHE["renv Cache<br/>(R/renv/)"]
    end
    
    subgraph "OMOP Package Ecosystem"
        CORE_PKG["Core Packages<br/>(CDMConnector, omopgenerics)"]
        COHORT_PKG["Cohort Packages<br/>(CohortConstructor, CohortCharacteristics)"]
        ANALYSIS_PKG["Analysis Packages<br/>(IncidencePrevalence, DrugUtilisation)"]
        VIS_PKG["Visualization Packages<br/>(visOmopResults)"]
    end
    
    subgraph "Development Dependencies"
        TIDYVERSE["Tidyverse<br/>(dplyr, dbplyr)"]
        KNITR["knitr<br/>(R Markdown Processing)"]
        DBI["DBI<br/>(Database Interface)"]
    end
    
    R_BASE --> RENV_SYSTEM
    RENV_SYSTEM --> RENV_CACHE
    RENV_CACHE --> CORE_PKG
    RENV_CACHE --> COHORT_PKG
    RENV_CACHE --> ANALYSIS_PKG
    RENV_CACHE --> VIS_PKG
    RENV_CACHE --> TIDYVERSE
    RENV_CACHE --> KNITR
    RENV_CACHE --> DBI
```

Sources: [.gitignore:19-24](), [StandardStudies/.Rhistory:1-23]()

### Package Loading Pattern

The typical R environment setup follows a consistent pattern for loading OMOP analytics packages:

```r
# Load necessary libraries from the renv library
library(CDMConnector)
library(CohortCharacteristics) 
library(IncidencePrevalence)
library(PatientProfiles)
library(visOmopResults)
library(DrugUtilisation)
```

Sources: [StandardStudies/.Rhistory:1-6](), [docs/data_analysis/performing_analysis.md:60-82]()

## Local Development Workflow

### Development Environment Setup

The following sequence describes the complete setup process for new developers:

```mermaid
sequenceDiagram
    participant DEV as "Developer"
    participant REPO as "Repository"
    participant RUBY as "Ruby Environment"
    participant R_ENV as "R Environment"
    participant JEKYLL as "Jekyll Server"
    
    DEV->>REPO: "git clone repository"
    DEV->>RUBY: "make install"
    RUBY->>RUBY: "bundle install"
    DEV->>R_ENV: "Setup R + renv"
    R_ENV->>R_ENV: "Install OMOP packages"
    DEV->>JEKYLL: "make serve"
    JEKYLL->>DEV: "http://localhost:4000"
    DEV->>DEV: "Edit files"
    JEKYLL->>DEV: "Auto-reload changes"
```

Sources: [Makefile:31-37]()

### File Structure for Development

The repository structure supports both documentation development and R analytics work:

```mermaid
graph TB
    subgraph "Repository Root"
        MAKEFILE["Makefile<br/>(Build Automation)"]
        CONFIG["_config.yml<br/>(Jekyll Configuration)"]
        GEMFILE["Gemfile<br/>(Ruby Dependencies)"]
        GITIGNORE[".gitignore<br/>(Version Control)"]
    end
    
    subgraph "Documentation System"
        DOCS_DIR["docs/<br/>(Content Pages)"]
        INCLUDES["_includes/<br/>(Jekyll Partials)"]
        SITE_DIR["_site/<br/>(Generated Site)"]
        ASSETS["assets/<br/>(Static Resources)"]
    end
    
    subgraph "R Analytics Environment"
        STD_STUDIES["StandardStudies/<br/>(R Markdown Studies)"]
        R_DIR["R/<br/>(R Environment)"]
        RMD_OUTPUT["_includes/rmd_output/<br/>(Processed R Content)"]
    end
    
    subgraph "Content Generation"
        UTILS_DIR["utils/<br/>(Scraping Scripts)"]
        SCRAPE_ALL["utils/scrape_all.sh<br/>(Main Orchestrator)"]
        MERGE_SCRIPTS["utils/merge_*.sh<br/>(Content Processing)"]
    end
    
    MAKEFILE --> DOCS_DIR
    MAKEFILE --> UTILS_DIR
    CONFIG --> SITE_DIR
    STD_STUDIES --> RMD_OUTPUT
    UTILS_DIR --> INCLUDES
```

Sources: [.gitignore:8-17](), [Makefile:52-61]()

### Ignored Files and Build Artifacts

The development environment produces various temporary and generated files that are excluded from version control:

| File Pattern | Purpose | Source |
|-------------|---------|---------|
| `_site/` | Jekyll generated site | Jekyll build process |
| `.sass-cache/` | Sass compilation cache | Jekyll preprocessing |
| `.jekyll-cache/` | Jekyll build cache | Jekyll optimization |
| `.jekyll-metadata` | Jekyll metadata | Jekyll internal |
| `R/renv/` | R package cache | renv package management |
| `.Rproj.user` | RStudio workspace | RStudio IDE |
| `StandardStudies/.RData` | R workspace data | R session state |
| `StandardStudies/.Rhistory` | R command history | R session logging |

Sources: [.gitignore:8-25]()

## Environment Variables and Configuration

### Ruby Path Configuration

The Makefile defines specific Ruby environment variables for consistent builds:

```bash
RUBY_PATH ?= /opt/homebrew/opt/ruby/bin
export PATH := $(RUBY_PATH):$(PATH)
export GEM_HOME := $(shell dirname $(shell dirname $(RUBY_PATH)))/lib/ruby/gems/$(shell $(RUBY_PATH)/ruby -e 'print RUBY_VERSION.split(".")[0..1].join(".")')
export GEM_PATH := $(GEM_HOME)
```

Sources: [Makefile:8-13]()

### Development Server Configuration

The Jekyll development server can be started with automatic reloading for efficient development:

```bash
make serve  # Starts Jekyll server on http://localhost:4000
```

This command executes `$(RUBY_PATH)/ruby -S bundle exec jekyll serve` with the configured Ruby environment.

Sources: [Makefile:35-37]()
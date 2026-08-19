# Page: Visualization and Results

# Visualization and Results

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [docs/data_analysis/intro_to_observational_research.md](docs/data_analysis/intro_to_observational_research.md)
- [docs/data_analysis/package_reference/visomopresults.md](docs/data_analysis/package_reference/visomopresults.md)
- [docs/data_analysis/setup.md](docs/data_analysis/setup.md)

</details>



This document covers the `visOmopResults` package, which serves as the visualization and output formatting layer for OMOP CDM analytics. The package transforms analysis results from specialized OMOP packages into publication-ready tables and plots. For information about the underlying analysis packages that generate the data being visualized, see [Specialized Analysis Packages](#3.3.3). For details on setting up the R environment to use these visualization tools, see [Environment Setup and Getting Started](#3.1).

## Overview and Purpose

The `visOmopResults` package fills a critical role in the OMOP analytics ecosystem by providing standardized visualization and formatting capabilities. It serves as the final stage in the analysis pipeline, converting raw analysis outputs into presentation-ready materials for research publications, reports, and regulatory submissions.

### Integration with OMOP Workflow

```mermaid
graph TD
    subgraph "Data Preparation"
        CDM["CDMConnector<br/>Database Connection"]
        COHORTS["CohortConstructor<br/>Population Definition"]
    end
    
    subgraph "Analysis Layer"
        CHARS["CohortCharacteristics<br/>summariseCharacteristics()"]
        INCPREV["IncidencePrevalence<br/>estimateIncidence()"]
        DRUGUTIL["DrugUtilisation<br/>summariseCharacteristics()"]
        SURVIVAL["CohortSurvival<br/>estimateSingleEventSurvival()"]
    end
    
    subgraph "Result Object"
        SUMRES["summarised_result<br/>Standardized Output Format"]
    end
    
    subgraph "visOmopResults Package"
        TABLE["visOmopTable()<br/>Publication Tables"]
        PLOTS["barPlot(), scatterPlot(), boxPlot()<br/>ggplot2 Visualizations"]
    end
    
    subgraph "Output Formats"
        BACKENDS["gt, flextable, DT<br/>reactable, tinytable"]
        GGPLOT["ggplot2 Objects<br/>Publication Graphics"]
    end
    
    CDM --> COHORTS
    COHORTS --> CHARS
    COHORTS --> INCPREV
    COHORTS --> DRUGUTIL
    COHORTS --> SURVIVAL
    
    CHARS --> SUMRES
    INCPREV --> SUMRES
    DRUGUTIL --> SUMRES
    SURVIVAL --> SUMRES
    
    SUMRES --> TABLE
    SUMRES --> PLOTS
    
    TABLE --> BACKENDS
    PLOTS --> GGPLOT
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:1-171](), [docs/data_analysis/setup.md:109-116]()

## Core Data Format: summarised_result Objects

The `visOmopResults` package operates exclusively on `summarised_result` objects, which provide a standardized format for analysis results across the OMOP ecosystem. These objects contain structured metadata and estimates that enable consistent visualization regardless of the originating analysis package.

### summarised_result Structure

```mermaid
graph TB
    subgraph "summarised_result Object"
        META["Metadata Columns<br/>result_id, cdm_name, group_name<br/>strata_name, variable_name"]
        SETTINGS["Settings<br/>result_type, package_name<br/>package_version"]
        ESTIMATES["Estimate Columns<br/>estimate_name, estimate_type<br/>estimate_value"]
    end
    
    subgraph "Analysis Packages"
        CHARS_PKG["CohortCharacteristics<br/>summariseCharacteristics()"]
        INCPREV_PKG["IncidencePrevalence<br/>estimateIncidence()"]
        DRUG_PKG["DrugUtilisation<br/>summariseCharacteristics()"]
    end
    
    subgraph "visOmopResults Functions"
        VIS_TABLE["visOmopTable()<br/>Processes all columns"]
        VIS_PLOT["Plotting functions<br/>Extract estimate_value"]
    end
    
    CHARS_PKG --> META
    INCPREV_PKG --> META
    DRUG_PKG --> META
    
    META --> VIS_TABLE
    ESTIMATES --> VIS_TABLE
    ESTIMATES --> VIS_PLOT
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:67-68](), [docs/data_analysis/package_reference/visomopresults.md:12-18]()

## Table Generation System

The table generation system in `visOmopResults` processes data through a sequential formatting pipeline, allowing detailed customization before rendering to various backend formats.

### Table Pipeline Architecture

```mermaid
graph TD
    subgraph "Input Processing"
        SUMRES_IN["summarised_result<br/>Raw Analysis Output"]
        VALIDATION["Data Validation<br/>Column Structure Check"]
    end
    
    subgraph "Formatting Pipeline"
        MIN_CELL["formatMinCellCount()<br/>Privacy Protection"]
        EST_VALUE["formatEstimateValue()<br/>Decimal Places, Big Mark"]
        EST_NAME["formatEstimateName()<br/>Estimate Templates"]
        HEADER_FORMAT["formatHeader()<br/>Multi-level Headers"]
    end
    
    subgraph "Backend Rendering"
        GT["gt<br/>HTML/RTF Output"]
        FLEX["flextable<br/>Word Documents"]
        DT_BACKEND["DT<br/>Interactive Tables"]
        REACT["reactable<br/>Interactive HTML"]
        TINY["tinytable<br/>LaTeX/PDF"]
    end
    
    subgraph "visOmopTable Function"
        MAIN_FUNC["visOmopTable()<br/>Main Entry Point"]
        OPTIONS[".options Parameter<br/>decimals, bigMark, na"]
    end
    
    SUMRES_IN --> VALIDATION
    VALIDATION --> MIN_CELL
    MIN_CELL --> EST_VALUE
    EST_VALUE --> EST_NAME
    EST_NAME --> HEADER_FORMAT
    
    MAIN_FUNC --> MIN_CELL
    OPTIONS --> EST_VALUE
    
    HEADER_FORMAT --> GT
    HEADER_FORMAT --> FLEX
    HEADER_FORMAT --> DT_BACKEND
    HEADER_FORMAT --> REACT
    HEADER_FORMAT --> TINY
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:72-80](), [docs/data_analysis/package_reference/visomopresults.md:96-111]()

### Table Function Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `visOmopTable()` | Main table creation function | `header`, `estimateName`, `type`, `.options` |
| `visTable()` | Generic table function for data frames | `columns`, `type`, `style` |
| `formatEstimateValue()` | Format numeric estimates | `decimals`, `bigMark`, `keepTrailingZeros` |
| `formatEstimateName()` | Apply estimate templates | Template patterns like `"<count> (<percentage>%)"` |
| `formatHeader()` | Create multi-level headers | `header` column specifications |

Sources: [docs/data_analysis/package_reference/visomopresults.md:128-135]()

## Plot Generation System

The plotting system transforms `summarised_result` objects into `ggplot2` visualizations through data validation, aesthetic mapping, and theme application.

### Plot Generation Pipeline

```mermaid
graph TD
    subgraph "Plot Input"
        RESULT_OBJ["summarised_result<br/>Analysis Results"]
        PLOT_PARAMS["Plot Parameters<br/>x, y, facet, colour"]
    end
    
    subgraph "Plot Functions"
        BAR_PLOT["barPlot()<br/>Categorical Comparisons"]
        SCATTER_PLOT["scatterPlot()<br/>Continuous Relationships"]
        BOX_PLOT["boxPlot()<br/>Distribution Visualization"]
    end
    
    subgraph "Processing Steps"
        DATA_VALID["Data Validation<br/>Required Columns Check"]
        AESTHETIC_MAP["Aesthetic Mapping<br/>Map Parameters to ggplot2"]
        THEME_APP["Theme Application<br/>themeVisOmop(), themeDarwin()"]
    end
    
    subgraph "Output"
        GGPLOT_OBJ["ggplot2 Object<br/>Customizable Plot"]
    end
    
    RESULT_OBJ --> BAR_PLOT
    RESULT_OBJ --> SCATTER_PLOT
    RESULT_OBJ --> BOX_PLOT
    PLOT_PARAMS --> BAR_PLOT
    PLOT_PARAMS --> SCATTER_PLOT
    PLOT_PARAMS --> BOX_PLOT
    
    BAR_PLOT --> DATA_VALID
    SCATTER_PLOT --> DATA_VALID
    BOX_PLOT --> DATA_VALID
    
    DATA_VALID --> AESTHETIC_MAP
    AESTHETIC_MAP --> THEME_APP
    THEME_APP --> GGPLOT_OBJ
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:82-92](), [docs/data_analysis/package_reference/visomopresults.md:131-135]()

### Plot Function Specifications

```mermaid
graph LR
    subgraph "barPlot Function"
        BAR_X["x parameter<br/>Categorical Variable"]
        BAR_Y["y parameter<br/>estimate_value"]
        BAR_FACET["facet parameter<br/>Stratification Variables"]
        BAR_COLOUR["colour parameter<br/>Group Distinction"]
    end
    
    subgraph "scatterPlot Function"
        SCATTER_X["x parameter<br/>Continuous/Categorical"]
        SCATTER_Y["y parameter<br/>estimate_value"]
        SCATTER_RIBBON["ribbon parameter<br/>Confidence Intervals"]
        SCATTER_POINT["point parameter<br/>Data Points"]
    end
    
    subgraph "boxPlot Function"
        BOX_X["x parameter<br/>Group Variable"]
        BOX_DISTRIB["Distribution Stats<br/>min, q25, median, q75, max"]
    end
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:114-124](), [docs/data_analysis/package_reference/visomopresults.md:156-170]()

## Backend Integration and Output Formats

The `visOmopResults` package supports multiple output backends to accommodate different publication and reporting requirements.

### Backend Capabilities Matrix

| Backend | Interactive | Word Export | HTML Export | PDF Export | Use Case |
|---------|-------------|-------------|-------------|------------|----------|
| `gt` | No | Via RTF | Yes | Via HTML | High-quality static tables |
| `flextable` | No | Yes | Yes | Yes | Word document integration |
| `DT` | Yes | No | Yes | No | Interactive web applications |
| `reactable` | Yes | No | Yes | No | Modern interactive tables |
| `tinytable` | No | No | Yes | Yes | LaTeX/academic papers |

Sources: [docs/data_analysis/package_reference/visomopresults.md:14-16]()

### Integration with Analysis Workflow

```mermaid
graph TB
    subgraph "Analysis Results"
        CHARS_RESULT["CohortCharacteristics<br/>Patient Demographics"]
        INCPREV_RESULT["IncidencePrevalence<br/>Epidemiologic Rates"]
        DRUG_RESULT["DrugUtilisation<br/>Medication Patterns"]
    end
    
    subgraph "visOmopResults Processing"
        MOCK_FUNC["mockSummarisedResult()<br/>Testing Function"]
        VIS_TABLE_FUNC["visOmopTable()<br/>header, estimateName"]
        PLOT_FUNCS["barPlot(), scatterPlot(), boxPlot()"]
    end
    
    subgraph "Publication Outputs"
        TABLE_ONE["Table 1<br/>Baseline Characteristics"]
        INCIDENCE_PLOT["Incidence Rates Plot<br/>Time Series"]
        DRUG_USAGE["Drug Usage Table<br/>Stratified Results"]
    end
    
    CHARS_RESULT --> VIS_TABLE_FUNC
    INCPREV_RESULT --> PLOT_FUNCS
    DRUG_RESULT --> VIS_TABLE_FUNC
    
    MOCK_FUNC --> VIS_TABLE_FUNC
    
    VIS_TABLE_FUNC --> TABLE_ONE
    PLOT_FUNCS --> INCIDENCE_PLOT
    VIS_TABLE_FUNC --> DRUG_USAGE
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:34-63](), [docs/data_analysis/intro_to_observational_research.md:252-287]()

## Advanced Configuration and Customization

The package provides extensive customization options through the `.options` parameter system and theme functions.

### Estimate Name Templates

The `estimateName` parameter uses template syntax to format complex estimates:

| Template Pattern | Output Example | Use Case |
|------------------|----------------|----------|
| `"<count> (<percentage>%)"` | `"150 (25.3%)"` | Categorical summaries |
| `"<mean> (<sd>)"` | `"45.2 (12.8)"` | Continuous variables |
| `"<median> [<q25>; <q75>]"` | `"42.0 [35.0; 55.0]"` | Non-parametric summaries |
| `"<count>"` | `"150"` | Simple counts |

Sources: [docs/data_analysis/package_reference/visomopresults.md:44-50](), [docs/data_analysis/package_reference/visomopresults.md:100-111]()

### Theme System Architecture

```mermaid
graph LR
    subgraph "Base ggplot2"
        BASE_THEME["Default ggplot2<br/>theme_gray()"]
    end
    
    subgraph "visOmopResults Themes"
        VIS_THEME["themeVisOmop()<br/>Package Default Theme"]
        DARWIN_THEME["themeDarwin()<br/>DARWIN EU Theme"]
    end
    
    subgraph "Customization"
        USER_THEME["User Modifications<br/>+ theme() additions"]
    end
    
    BASE_THEME --> VIS_THEME
    BASE_THEME --> DARWIN_THEME
    VIS_THEME --> USER_THEME
    DARWIN_THEME --> USER_THEME
```

Sources: [docs/data_analysis/package_reference/visomopresults.md:134-136](), [docs/data_analysis/package_reference/visomopresults.md:18-20]()
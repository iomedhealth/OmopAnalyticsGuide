# Page: Content Scraping and Generation

# Content Scraping and Generation

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [utils/libraries.csv](utils/libraries.csv)
- [utils/scrape_all.sh](utils/scrape_all.sh)
- [utils/scrape_and_md.py](utils/scrape_and_md.py)
- [utils/scrape_deepwiki.py](utils/scrape_deepwiki.py)

</details>



This document describes the automated content scraping system that collects documentation from external R package websites and generates standardized content for the OMOP Analytics Guide. The system orchestrates parallel scraping operations to gather both traditional HTML documentation and enriched content from the deepwiki service.

For information about how this scraped content integrates with the Jekyll site build process, see [Jekyll Site Configuration](#5.2).

## System Architecture

The content scraping system consists of three main components orchestrated by a shell script that processes a CSV configuration file:

```mermaid
graph TB
    subgraph "Configuration"
        CSV[libraries.csv]
    end
    
    subgraph "Orchestration"
        SCRAPE_ALL[scrape_all.sh]
    end
    
    subgraph "Scraping Components"
        SCRAPE_MD[scrape_and_md.py]
        SCRAPE_DEEP[scrape_deepwiki.py]
    end
    
    subgraph "External Sources"
        PKG_SITES["Package Documentation Sites<br/>(pkgdown websites)"]
        DEEPWIKI_SVC["Deepwiki MCP Service<br/>(mcp.deepwiki.com)"]
    end
    
    subgraph "Output Structure"
        RAW_DIR["../reference/libraries/{date}/raw/"]
        PKG_DIRS["{package_name}/"]
        MD_FILES["*.md files"]
    end
    
    CSV --> SCRAPE_ALL
    SCRAPE_ALL --> SCRAPE_MD
    SCRAPE_ALL --> SCRAPE_DEEP
    
    SCRAPE_MD --> PKG_SITES
    SCRAPE_DEEP --> DEEPWIKI_SVC
    
    SCRAPE_MD --> RAW_DIR
    SCRAPE_DEEP --> RAW_DIR
    RAW_DIR --> PKG_DIRS
    PKG_DIRS --> MD_FILES
```

Sources: [utils/scrape_all.sh:1-36](), [utils/libraries.csv:1-15](), [utils/scrape_deepwiki.py:1-122](), [utils/scrape_and_md.py:1-129]()

## Library Configuration

The system uses a CSV configuration file to define which R packages to scrape:

| Field | Description | Example |
|-------|-------------|---------|
| `repo` | GitHub repository path | `darwin-eu/CohortSurvival` |
| `url` | Package documentation website | `https://darwin-eu-dev.github.io/CohortSurvival/` |
| `name` | Package directory name | `CohortSurvival` |

The configuration covers all major OMOP analytics packages including core infrastructure (CDMConnector, omopgenerics), cohort management (CohortConstructor, CohortCharacteristics), and specialized analysis packages (IncidencePrevalence, DrugUtilisation, CohortSurvival).

Sources: [utils/libraries.csv:1-15]()

## Orchestration Workflow

The `scrape_all.sh` script implements the main workflow:

```mermaid
graph TD
    START[Start scrape_all.sh]
    DATE[Generate today date<br/>DD-MM-YYYY format]
    READ_CSV[Read libraries.csv<br/>into array]
    
    subgraph "Parallel Processing"
        PARALLEL_LOOP[For each library]
        CREATE_DIR[mkdir base_dir]
        LAUNCH_MD[Launch scrape_and_md.py]
        LAUNCH_DEEP[Launch scrape_deepwiki.py]
        WAIT_PROCS[wait pid1 pid2]
    end
    
    WAIT_ALL[wait for all libraries]
    DONE[Complete]
    
    START --> DATE
    DATE --> READ_CSV
    READ_CSV --> PARALLEL_LOOP
    PARALLEL_LOOP --> CREATE_DIR
    CREATE_DIR --> LAUNCH_MD
    CREATE_DIR --> LAUNCH_DEEP
    LAUNCH_MD --> WAIT_PROCS
    LAUNCH_DEEP --> WAIT_PROCS
    WAIT_PROCS --> WAIT_ALL
    WAIT_ALL --> DONE
```

The script processes each library by:
1. Creating a date-stamped directory structure: `../reference/libraries/{today}/raw/{name}/`
2. Launching both scrapers in parallel as background processes
3. Using process IDs (`pid1`, `pid2`) to synchronize completion
4. Waiting for all library processing to complete

Sources: [utils/scrape_all.sh:5-36]()

## HTML to Markdown Conversion

The `scrape_and_md.py` component performs recursive website crawling and HTML-to-Markdown conversion:

### Core Functions

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `crawl_and_convert_to_markdown()` | Main crawling logic | `base_url`, `output_dir` |
| `sanitize_filename()` | Clean titles for filesystem | Uses regex `r'[^\w\s-]'` |

### Crawling Strategy

```mermaid
graph TD
    INIT[Initialize with base_url]
    PARSE_DOMAIN[Extract base_domain<br/>and base_path]
    
    subgraph "URL Processing Loop"
        POP_URL[Pop URL from queue]
        CHECK_PROCESSED[Check if in collected_urls]
        FETCH[HTTP GET request]
        PARSE_HTML[BeautifulSoup parsing]
        EXTRACT_LINKS[Find all <a href> tags]
        FILTER_LINKS[Filter by domain/path/<br/>no query/no file extensions]
        ADD_QUEUE[Add new URLs to queue]
    end
    
    CONVERT[html2text conversion]
    SAVE_MD[Save as {title}.md]
    DELAY[time.sleep(1)]
    
    INIT --> PARSE_DOMAIN
    PARSE_DOMAIN --> POP_URL
    POP_URL --> CHECK_PROCESSED
    CHECK_PROCESSED --> FETCH
    FETCH --> PARSE_HTML
    PARSE_HTML --> EXTRACT_LINKS
    EXTRACT_LINKS --> FILTER_LINKS
    FILTER_LINKS --> ADD_QUEUE
    ADD_QUEUE --> CONVERT
    CONVERT --> SAVE_MD
    SAVE_MD --> DELAY
    DELAY --> POP_URL
```

The crawler implements several filtering mechanisms:
- Domain restriction: `parsed_url.netloc == base_domain`
- Path restriction: `parsed_url.path.startswith(base_path)`
- File type exclusion: `.pdf`, `.jpg`, `.png`, `.zip`, `.tar`
- Duplicate prevention using `collected_urls` set

Sources: [utils/scrape_and_md.py:17-113]()

## Deepwiki Content Extraction

The `scrape_deepwiki.py` component uses Model Context Protocol (MCP) to fetch enriched documentation:

### MCP Integration

```mermaid
graph LR
    CLIENT[scrape_deepwiki.py]
    MCP_URL["mcp.deepwiki.com/mcp"]
    TOOL_CALL[read_wiki_contents tool]
    CONTENT_BLOCKS[Structured content blocks]
    
    CLIENT --> MCP_URL
    MCP_URL --> TOOL_CALL
    TOOL_CALL --> CONTENT_BLOCKS
    CONTENT_BLOCKS --> CLIENT
```

### Async Processing Flow

The script implements asynchronous MCP communication:

| Component | Function | Implementation |
|-----------|----------|---------------|
| `fetch_deepwiki_content_async()` | MCP client session | `streamablehttp_client()`, `ClientSession()` |
| `process_and_save_content()` | Content parsing | Split on `"
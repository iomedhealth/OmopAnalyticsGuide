# Page: Development and Documentation System

# Development and Documentation System

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [utils/libraries.csv](utils/libraries.csv)
- [utils/scrape_all.sh](utils/scrape_all.sh)
- [utils/scrape_and_md.py](utils/scrape_and_md.py)
- [utils/scrape_deepwiki.py](utils/scrape_deepwiki.py)

</details>



This section covers the automated documentation generation and site building infrastructure that powers the OMOP Analytics Guide. The system handles content scraping from external sources, site generation using Jekyll, and deployment workflows.

For information about the specific study templates and R Markdown processing, see [Study Templates and Examples](#4.2). For Jekyll site configuration details, see [Jekyll Site Configuration](#5.2).

## System Architecture

The development and documentation system operates through three main components: content acquisition from external sources, processing and consolidation, and static site generation. The system is designed to automatically update documentation from multiple R package websites and generate a unified documentation site.

### Content Acquisition and Processing Workflow

```mermaid
graph TD
    subgraph "Configuration"
        CSV["libraries.csv<br/>Repo definitions"]
    end
    
    subgraph "Orchestration Layer"
        SCRAPE_ALL["scrape_all.sh<br/>Main orchestrator"]
    end
    
    subgraph "Content Scrapers"
        SCRAPE_MD["scrape_and_md.py<br/>crawl_and_convert_to_markdown()"]
        SCRAPE_DEEP["scrape_deepwiki.py<br/>fetch_deepwiki_content()"]
    end
    
    subgraph "External Sources"
        GITHUB_SITES["GitHub Pages<br/>Package websites"]
        DEEPWIKI_API["Deepwiki MCP Service<br/>mcp.deepwiki.com/mcp"]
    end
    
    subgraph "Processing Functions"
        SANITIZE_MD["sanitize_filename()<br/>in scrape_and_md.py"]
        SANITIZE_DEEP["sanitize_filename()<br/>in scrape_deepwiki.py"]
        HTML2TEXT["html2text.HTML2Text()<br/>Conversion engine"]
    end
    
    subgraph "Output Storage"
        RAW_DIR["../reference/libraries/{date}/raw/<br/>Timestamped storage"]
    end
    
    CSV --> SCRAPE_ALL
    SCRAPE_ALL --> SCRAPE_MD
    SCRAPE_ALL --> SCRAPE_DEEP
    
    SCRAPE_MD --> GITHUB_SITES
    SCRAPE_DEEP --> DEEPWIKI_API
    
    SCRAPE_MD --> SANITIZE_MD
    SCRAPE_MD --> HTML2TEXT
    SCRAPE_DEEP --> SANITIZE_DEEP
    
    SANITIZE_MD --> RAW_DIR
    SANITIZE_DEEP --> RAW_DIR
    HTML2TEXT --> RAW_DIR
```

Sources: [utils/scrape_all.sh:1-36](), [utils/scrape_and_md.py:17-125](), [utils/scrape_deepwiki.py:25-122]()

## Content Scraping Infrastructure

The content scraping system operates through a coordinated set of scripts that extract documentation from external R package websites and API services. The system is designed for parallel processing and handles multiple content sources simultaneously.

### Main Orchestration Process

The primary entry point is `scrape_all.sh`, which coordinates the entire scraping operation:

| Component | Function | Implementation |
|-----------|----------|----------------|
| Date Management | Generate timestamp for content versioning | `today=$(date +%d-%m-%Y)` |
| Library Loading | Read package definitions from CSV | `while IFS=',' read -r repo url name` |
| Parallel Processing | Execute scrapers concurrently | Background processes with `&` |
| Process Synchronization | Wait for completion | `wait $pid1 $pid2` |

The script processes each library entry from `libraries.csv` in parallel, spawning both web scraping and API scraping processes simultaneously for each package.

Sources: [utils/scrape_all.sh:5-33](), [utils/libraries.csv:1-15]()

### Web Content Extraction

The `scrape_and_md.py` module implements recursive web crawling with HTML-to-Markdown conversion:

```mermaid
graph TD
    subgraph "URL Processing Pipeline"
        INIT["crawl_and_convert_to_markdown()<br/>Entry point"]
        URL_QUEUE["urls_to_visit[]<br/>Processing queue"]
        URL_SET["collected_urls set<br/>Deduplication"]
    end
    
    subgraph "Content Processing"
        REQUEST["requests.get()<br/>HTTP client"]
        SOUP["BeautifulSoup()<br/>HTML parser"]
        LINK_EXTRACT["find_all('a')<br/>Link extraction"]
        HTML2MD["html2text.HTML2Text()<br/>Conversion"]
    end
    
    subgraph "Output Generation"
        SANITIZE["sanitize_filename()<br/>File naming"]
        WRITE["File I/O<br/>Markdown output"]
    end
    
    subgraph "URL Filtering"
        DOMAIN_CHECK["parsed_url.netloc == base_domain"]
        PATH_CHECK["parsed_url.path.startswith(base_path)"]
        EXTENSION_CHECK["not endswith('.pdf', '.jpg', ...)"]
    end
    
    INIT --> URL_QUEUE
    URL_QUEUE --> REQUEST
    REQUEST --> SOUP
    SOUP --> LINK_EXTRACT
    LINK_EXTRACT --> DOMAIN_CHECK
    DOMAIN_CHECK --> PATH_CHECK
    PATH_CHECK --> EXTENSION_CHECK
    EXTENSION_CHECK --> URL_SET
    SOUP --> HTML2MD
    HTML2MD --> SANITIZE
    SANITIZE --> WRITE
    URL_SET --> URL_QUEUE
```

Sources: [utils/scrape_and_md.py:17-112]()

### API Content Acquisition

The `scrape_deepwiki.py` module interfaces with the Deepwiki MCP service for enhanced documentation content:

| Function | Purpose | Implementation Details |
|----------|---------|----------------------|
| `fetch_deepwiki_content_async()` | Async MCP client interaction | Uses `streamablehttp_client` and `ClientSession` |
| `fetch_deepwiki_content()` | Synchronous wrapper | `asyncio.run()` execution |
| `process_and_save_content()` | Content processing and storage | Page splitting on `"
# Page: "` delimiter |
| `sanitize_filename()` | Filename cleaning | Regex `r'[^\w\s-]'` and `r'[-\s]+', '_'` |

The content processing splits the deepwiki response into individual pages and saves each as a separate markdown file with sanitized filenames.

Sources: [utils/scrape_deepwiki.py:25-122]()

## Output Structure

The scraping system generates a standardized directory structure:

```
../reference/libraries/{DD-MM-YYYY}/raw/
├── CohortSurvival/
│   ├── {sanitized_title_1}.md
│   ├── {sanitized_title_2}.md
│   └── ...
├── CDMConnector/
├── CodelistGenerator/
└── ...
```

Each package directory contains:
- HTML-to-Markdown converted documentation pages from `scrape_and_md.py`
- Deepwiki-generated content pages from `scrape_deepwiki.py`
- Files named using `sanitize_filename()` function output

The date-based directory structure enables version tracking and allows for content comparison across different scraping runs.

Sources: [utils/scrape_all.sh:23-24](), [utils/scrape_deepwiki.py:63-89](), [utils/scrape_and_md.py:94-102]()
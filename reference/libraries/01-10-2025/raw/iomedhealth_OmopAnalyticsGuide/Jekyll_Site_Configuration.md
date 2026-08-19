# Page: Jekyll Site Configuration

# Jekyll Site Configuration

<details>
<summary>Relevant source files</summary>

The following files were used as context for generating this wiki page:

- [Gemfile](Gemfile)
- [_config.yml](_config.yml)
- [_includes/head_custom.html](_includes/head_custom.html)

</details>



This document explains the Jekyll static site generator configuration used to build and deploy the OMOP Analytics Guide documentation website. It covers the site configuration, theme customization, plugin setup, and build dependencies that transform the repository's markdown content into a navigable documentation site.

For information about the content generation and scraping processes that populate this site, see [Content Scraping and Generation](#5.1). For details about the development environment and build tools, see [Development Environment](#5.3).

## Jekyll Configuration Overview

The Jekyll site is configured through the main configuration file [_config.yml:1-31]() which defines the site metadata, theme, and core functionality. The site uses the `just-the-docs` theme to provide a clean, searchable documentation layout optimized for technical reference materials.

```mermaid
graph TB
    subgraph "Site Configuration"
        CONFIG["_config.yml<br/>Main Configuration"]
        GEMFILE["Gemfile<br/>Dependencies"]
        CUSTOM["_includes/head_custom.html<br/>Custom HTML"]
    end
    
    subgraph "Jekyll Components"
        THEME["just-the-docs<br/>Documentation Theme"]
        SEARCH["Built-in Search<br/>heading_level: 6"]
        PLUGINS["jekyll-seo-tag<br/>jekyll-sitemap"]
    end
    
    subgraph "Site Features"
        LOGO["logo.png<br/>IOMED Branding"]
        MERMAID["mermaid 11.12.0<br/>Diagram Rendering"]
        COPY_CODE["enable_copy_code_button<br/>Code Snippets"]
        BACK_TOP["back_to_top<br/>Navigation"]
    end
    
    CONFIG --> THEME
    CONFIG --> SEARCH
    CONFIG --> PLUGINS
    GEMFILE --> THEME
    GEMFILE --> PLUGINS
    CUSTOM --> LOGO
    CONFIG --> MERMAID
    CONFIG --> COPY_CODE
    CONFIG --> BACK_TOP
```

**Sources:** [_config.yml:1-31](), [Gemfile:1-11](), [_includes/head_custom.html:1-2]()

## Theme and Visual Configuration

The site uses the `just-the-docs` theme version 0.10.1 with custom branding and color scheme configuration. The visual identity is established through logo placement and custom styling.

| Configuration | Value | Purpose |
|---------------|-------|---------|
| `theme` | `just-the-docs` | Clean documentation theme |
| `color_scheme` | `custom` | IOMED brand colors |
| `logo` | `/assets/images/logo.png` | IOMED branding |
| `favicon_ico` | `/assets/images/favicon.ico` | Browser tab icon |

The theme configuration includes navigation enhancements and user experience features:

```mermaid
graph LR
    subgraph "Visual Configuration"
        THEME_CONFIG["just-the-docs 0.10.1"]
        COLOR["color_scheme: custom"]
        LOGO_CONFIG["logo: /assets/images/logo.png"]
        FAVICON["favicon_ico: /assets/images/favicon.ico"]
    end
    
    subgraph "Navigation Features"
        BACK_TOP_ENABLED["back_to_top: true"]
        BACK_TOP_TEXT["back_to_top_text: Back to top"]
        AUX_LINKS["aux_links: Main Site"]
    end
    
    subgraph "Code Features"
        COPY_BUTTON["enable_copy_code_button: true"]
        FOOTER["footer_content: Copyright IOMED"]
    end
    
    THEME_CONFIG --> COLOR
    THEME_CONFIG --> LOGO_CONFIG
    THEME_CONFIG --> FAVICON
    THEME_CONFIG --> BACK_TOP_ENABLED
    THEME_CONFIG --> BACK_TOP_TEXT
    THEME_CONFIG --> AUX_LINKS
    THEME_CONFIG --> COPY_BUTTON
    THEME_CONFIG --> FOOTER
```

**Sources:** [_config.yml:3-21](), [Gemfile:6]()

## Search Configuration

The built-in search functionality is configured to provide comprehensive content discovery across the documentation. The search system indexes content at multiple heading levels and provides contextual previews.

| Setting | Value | Function |
|---------|--------|----------|
| `heading_level` | `6` | Index headings up to h6 |
| `previews` | `4` | Show 4 preview results |
| `preview_words_before` | `4` | Context words before match |
| `focus_shortcut_key` | `'k'` | Keyboard shortcut for search |

The search configuration is optimized for technical documentation where users need to quickly locate specific functions, concepts, or code examples.

**Sources:** [_config.yml:11-15]()

## Plugin Configuration

The site uses essential Jekyll plugins to enhance SEO, navigation, and site functionality:

```mermaid
graph TB
    subgraph "Jekyll Plugins"
        SEO["jekyll-seo-tag<br/>Meta tags & structured data"]
        SITEMAP["jekyll-sitemap<br/>XML sitemap generation"]
        FEED["jekyll-feed<br/>RSS/Atom feeds"]
    end
    
    subgraph "Plugin Functions"
        SEO_META["<meta> tags<br/>Open Graph<br/>Twitter Cards"]
        SEARCH_ENGINE["search.xml<br/>Google indexing"]
        RSS_FEED["feed.xml<br/>Content syndication"]
    end
    
    subgraph "Site Metadata"
        TITLE["title: IOMED Data Space Platform"]
        DESC["description: IOMED Data Space Platform documentation"]
        URL["url: https://docs.iomed.health"]
        GOOGLE_VERIFY["google-site-verification"]
    end
    
    SEO --> SEO_META
    SITEMAP --> SEARCH_ENGINE
    FEED --> RSS_FEED
    
    TITLE --> SEO_META
    DESC --> SEO_META
    URL --> SEARCH_ENGINE
    GOOGLE_VERIFY --> SEO_META
```

**Sources:** [_config.yml:28-30](), [Gemfile:9-10](), [_includes/head_custom.html:1]()

## Mermaid Diagram Integration

Mermaid diagram rendering is configured to support the extensive use of diagrams throughout the documentation. The configuration specifies the CDN version and ensures compatibility with the site's content.

```yaml
mermaid:
  version: "11.12.0"
```

This configuration enables the rendering of system architecture diagrams, workflow visualizations, and dependency graphs that are essential for explaining the OMOP analytics ecosystem.

**Sources:** [_config.yml:23-26]()

## Build Dependencies and Gemfile

The Ruby gem dependencies are managed through the `Gemfile` which specifies the exact versions of Jekyll and required plugins:

| Gem | Version | Purpose |
|-----|---------|---------|
| `jekyll` | `~> 4.4.1` | Static site generator |
| `just-the-docs` | `0.10.1` | Documentation theme |
| `jekyll-sitemap` | Latest | XML sitemap generation |
| `jekyll-feed` | Latest | RSS feed generation |

The pinned version of `just-the-docs` ensures consistent theme behavior across deployments, while Jekyll is constrained to the 4.4.x series for stability.

**Sources:** [Gemfile:1-11]()

## Custom HTML Integration

The site includes custom HTML head content through [_includes/head_custom.html:1]() which adds Google site verification for search console integration. This file demonstrates the extensibility of the Jekyll configuration for adding custom meta tags and tracking codes.

**Sources:** [_includes/head_custom.html:1-2]()
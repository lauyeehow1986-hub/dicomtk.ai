# Build `ellmer` Tool Definitions for the `dicomtk.ai` MCP Server

Constructs a named list of
[`ellmer::tool()`](https://ellmer.tidyverse.org/reference/tool.html)
definitions exposing header inspection, automated QC, guardrailed
de-identification dry-runs, residual-PHI verification, protocol
harmonisation, and AI segmentation.

## Usage

``` r
dicomtk_mcp_tools()
```

## Value

A named list of `ellmer` `ToolDef` objects.

## Examples

``` r
tools <- dicomtk_mcp_tools()
names(tools)
#> [1] "inspect_headers"    "image_qc"           "deid_dry_run"      
#> [4] "deid_verify"        "harmonize_protocol" "ai_segment"        
#> [7] "search_similar"    
```

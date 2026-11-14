# Start the `dicomtk.ai` Model Context Protocol (MCP) Server

Launches an MCP server via
[`mcptools::mcp_server()`](https://posit-dev.github.io/mcptools/reference/server.html)
exposing
[`dicomtk_mcp_tools()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/dicomtk_mcp_tools.md)
over `"stdio"` or `"http"`.

## Usage

``` r
start_mcp_server(
  type = c("stdio", "http"),
  host = "127.0.0.1",
  port = 8080L,
  tools = dicomtk_mcp_tools()
)
```

## Arguments

- type:

  Transport type: `"stdio"` or `"http"`.

- host:

  Host interface for HTTP transport (default `"127.0.0.1"`).

- port:

  Port for HTTP transport (default `8080L`).

- tools:

  List of
  [`ellmer::ToolDef`](https://ellmer.tidyverse.org/reference/tool.html)
  objects (default
  [`dicomtk_mcp_tools()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/dicomtk_mcp_tools.md)).

## Value

Called for its side effect (runs the MCP server loop).

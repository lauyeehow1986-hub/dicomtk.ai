# Configure an `ellmer`-Backed Chat Session for `dicomtk.ai`

Creates a `"dicom_ai_chat"` object wrapping an `ellmer` chat client (or
a deterministic `"offline"` rule-based planner for CI and air-gapped
testing).

## Usage

``` r
ai_chat(
  provider = c("offline", "ollama", "openai", "anthropic", "gemini", "openai_compatible"),
  model = NULL,
  base_url = NULL,
  api_key = NULL,
  system_prompt = NULL,
  ...
)
```

## Arguments

- provider:

  Chat provider: `"offline"`, `"ollama"`, `"openai"`, `"anthropic"`,
  `"gemini"`, or `"openai_compatible"`.

- model:

  Optional model identifier.

- base_url:

  Optional API base URL (used for `"ollama"` and `"openai_compatible"`).

- api_key:

  Optional API key (defaults to standard provider environment
  variables).

- system_prompt:

  Optional system prompt string.

- ...:

  Additional arguments passed to the underlying `ellmer` chat
  constructor.

## Value

An object of class `"dicom_ai_chat"`.

## Examples

``` r
chat <- ai_chat("offline")
```

# Register a Pluggable AI Backend

Registers or updates an AI model backend (segmentation, NLP
de-identification, OCR, or embedding extraction) in the session
registry.

## Usage

``` r
register_ai_backend(
  name,
  task = c("segmentation", "nlp_deid", "ocr", "embedding"),
  mode = c("offline", "rest"),
  endpoint = NULL,
  predict_fn = NULL,
  headers = character(0)
)
```

## Arguments

- name:

  Unique backend identifier (e.g., `"totalsegmentator"`, `"medsam2"`,
  `"presidio"`).

- task:

  Task category: `"segmentation"`, `"nlp_deid"`, `"ocr"`, or
  `"embedding"`.

- mode:

  Execution mode: `"offline"` (deterministic local engine) or `"rest"`
  (HTTP endpoint via `httr2`).

- endpoint:

  Base URL or local URI for the backend.

- predict_fn:

  Optional custom `function(input, backend, ...)` override.

- headers:

  Optional named character vector of HTTP headers.

## Value

Invisibly returns the registered `dicom_ai_backend` object.

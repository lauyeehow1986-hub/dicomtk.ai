# De-Identify Free-Text Radiology Reports or Structured Reports

Redacts or pseudonymizes protected health information (PHI) in free-text
radiology reports or `dicom_sr` objects using a registered NLP backend
(`"presidio"` REST or built-in deterministic HIPAA/GDPR/SG pattern NER).
Enforces a monotonic union invariant: optional LLM audit passes can only
add missed spans, never remove deterministic detections.

## Usage

``` r
ai_deid_report(
  x,
  backend = "presidio",
  chat = NULL,
  mode = c("redact", "pseudonymize")
)
```

## Arguments

- x:

  Character report text or a `dicom_sr` object from
  [`dicomtk::read_dicom_sr()`](https://lauyeehow1986-hub.github.io/dicomtk/reference/read_dicom_sr.html).

- backend:

  Registered NLP de-id backend name (default `"presidio"`).

- chat:

  Optional `dicom_ai_chat` object for contextual review.

- mode:

  `"redact"` (default) or `"pseudonymize"`.

## Value

A list with `text` (de-identified string), `spans` (tibble of detected
PHI spans), and `mode`.

## Examples

``` r
ai_deid_report("Patient John Tan (MRN: MRN-12345) scanned on 2026-03-14.")
#> $text
#> [1] "[REDACTED_PERSON] ([REDACTED_MRN]) scanned on [REDACTED_DATE]."
#> 
#> $spans
#> # A tibble: 3 × 4
#>   entity_type start   end text            
#>   <chr>       <int> <int> <chr>           
#> 1 PERSON          1    16 Patient John Tan
#> 2 MRN            19    32 MRN: MRN-12345  
#> 3 DATE           46    55 2026-03-14      
#> 
#> $mode
#> [1] "redact"
#> 
```

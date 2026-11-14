# Extract Weak Clinical Labels From Radiology Report Text

Extracts structured pathology findings with assertion polarity
(`"present"`, `"absent"`, or `"uncertain"`) using deterministic ConText
negation/uncertainty rules (when `"offline"`) or an `ellmer`
structured-output chat session.

## Usage

``` r
ai_extract_labels(text, findings = NULL, chat = ai_chat("offline"))
```

## Arguments

- text:

  Character vector of report text.

- findings:

  Optional character vector of extra finding terms to track.

- chat:

  A `dicom_ai_chat` object from
  [`ai_chat()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_chat.md).

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `finding`, `anatomy`, `polarity`, `confidence`, and
`sentence`.

## Examples

``` r
ai_extract_labels("No evidence of pneumothorax. Moderate pleural effusion.")
#> # A tibble: 2 × 5
#>   finding          anatomy polarity confidence sentence                   
#>   <chr>            <chr>   <chr>         <dbl> <chr>                      
#> 1 pneumothorax     pleura  absent          0.9 No evidence of pneumothorax
#> 2 pleural effusion pleura  present         0.9 Moderate pleural effusion  
```

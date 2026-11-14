# Harmonise Messy DICOM Series Descriptions to RadLex and LOINC-RSNA Playbook

Maps heterogeneous `SeriesDescription`, `Modality`, and
`BodyPartExamined` headers onto standardized LOINC-RSNA Radiology
Playbook IDs (`rpid`) and `RadLex` anatomical identifiers (`radlex_id`).

## Usage

``` r
ai_harmonize_protocol(headers, chat = NULL)
```

## Arguments

- headers:

  A data frame / tibble with `SeriesDescription` (and optional
  `Modality`, `BodyPartExamined` columns).

- chat:

  Optional `dicom_ai_chat` object for semantic tie-breaking on
  low-confidence headers.

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with columns `SeriesDescription`, `Modality`, `rpid`,
`long_common_name`, `short_name`, `body_region`, `radlex_id`,
`contrast`, and `confidence`.

## Examples

``` r
df <- data.frame(SeriesDescription = "CHEST WO CON 3.0mm", Modality = "CT")
ai_harmonize_protocol(df)
#> # A tibble: 1 × 9
#>   SeriesDescription  Modality rpid   long_common_name     short_name body_region
#>   <chr>              <chr>    <chr>  <chr>                <chr>      <chr>      
#> 1 CHEST WO CON 3.0mm CT       RPID29 CT Chest WO contrast CT Chest … CHEST      
#> # ℹ 3 more variables: radlex_id <chr>, contrast <lgl>, confidence <dbl>
```

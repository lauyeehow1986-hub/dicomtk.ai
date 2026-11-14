# List Registered AI Backends

List Registered AI Backends

## Usage

``` r
list_ai_backends(task = NULL)
```

## Arguments

- task:

  Optional task filter (`"segmentation"`, `"nlp_deid"`, `"ocr"`, or
  `"embedding"`).

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
summarizing registered backends.

## Examples

``` r
list_ai_backends()
#> # A tibble: 7 × 4
#>   name             task         mode    endpoint             
#>   <chr>            <chr>        <chr>   <chr>                
#> 1 embeddings       embedding    offline http://127.0.0.1:8005
#> 2 medsam2          segmentation offline http://127.0.0.1:8004
#> 3 nnunet           segmentation offline http://127.0.0.1:8002
#> 4 ocr              ocr          offline local://tesseract    
#> 5 presidio         nlp_deid     offline http://127.0.0.1:5002
#> 6 totalsegmentator segmentation offline http://127.0.0.1:8001
#> 7 vista3d          segmentation offline http://127.0.0.1:8003
```

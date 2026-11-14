# Retrieve Top-K Similar Studies From a DuckDB Embedding Index

Uses DuckDB `vss` cosine similarity when installed, falling back
seamlessly to vectorized cosine scoring for air-gapped environments.

## Usage

``` r
ai_search_similar(index, query_vol, k = 5L, backend = "embeddings")
```

## Arguments

- index:

  A `"dicom_ai_index"` object.

- query_vol:

  Query `dicom_volume` object.

- k:

  Integer number of nearest neighbors to return (default `5L`).

- backend:

  Registered embedding backend name (default `"embeddings"`).

## Value

A [tibble::tibble](https://tibble.tidyverse.org/reference/tibble.html)
with `study_id`, `modality`, `similarity`, and `metadata_json`, sorted
by descending cosine similarity.

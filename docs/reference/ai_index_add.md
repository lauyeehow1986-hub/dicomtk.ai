# Add a Study Volume to a DuckDB Embedding Index

Add a Study Volume to a DuckDB Embedding Index

## Usage

``` r
ai_index_add(index, study_id, vol, metadata = list(), backend = "embeddings")
```

## Arguments

- index:

  A `"dicom_ai_index"` from
  [`ai_embedding_index()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_embedding_index.md).

- study_id:

  Unique study identifier string.

- vol:

  A `dicom_volume` object.

- metadata:

  Optional named list of study metadata.

- backend:

  Registered embedding backend name (default `"embeddings"`).

## Value

Invisibly returns `study_id`.

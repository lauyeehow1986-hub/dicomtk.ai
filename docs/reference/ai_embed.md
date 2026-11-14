# Extract a Normalized Study Embedding Vector

Computes an L2-normalized feature embedding from a `dicom_volume` using
a registered embedding backend (`"offline"` deterministic
intensity/spatial/modality signature, or a REST foundation-model
endpoint such as RAD-DINO / BiomedCLIP).

## Usage

``` r
ai_embed(vol, backend = "embeddings", dim_out = 32L)
```

## Arguments

- vol:

  A `dicom_volume` object or DICOM path.

- backend:

  Registered embedding backend name (default `"embeddings"`).

- dim_out:

  Target embedding dimension for the offline extractor (default `32L`).

## Value

A numeric L2-normalized embedding vector.

# Generate MONAI MAISI 3D Synthetic CT and Multi-Organ Label Masks

Generates paired 3D synthetic CT DICOM slices
(`ImageType = "DERIVED\\SECONDARY\\SYNTHETIC"`) and multi-organ integer
segmentation masks along with a provenance manifest
(`maisi_manifest.json`). Supports local deterministic `"phantom"`
synthesis or an external MONAI MAISI `"http"` inference endpoint.

## Usage

``` r
ai_generate_maisi(
  out_dir = tempfile("maisi_"),
  anatomy_list = c("liver", "spleen", "left_kidney", "right_kidney"),
  dims = c(32L, 32L, 16L),
  spacing = c(1.5, 1.5, 2),
  mode = c("phantom", "http"),
  endpoint = NULL
)
```

## Arguments

- out_dir:

  Output directory for synthetic DICOM series and manifest.

- anatomy_list:

  Character vector of target organ names (e.g.
  `c("liver", "spleen", "left_kidney", "right_kidney")`).

- dims:

  Integer vector `c(rows, cols, slices)` (default `c(32L, 32L, 16L)`).

- spacing:

  Numeric vector `c(dx, dy, dz)` in mm.

- mode:

  Synthesis mode: `"phantom"` (pure-R offline) or `"http"` (MAISI REST
  service).

- endpoint:

  Optional MAISI HTTP endpoint URL when `mode = "http"`.

## Value

An S3 `"dicom_maisi_result"` object with `dicom_dir`, `mask`,
`anatomy_map`, `manifest_path`, and `synthetic = TRUE`.

## Examples

``` r
out <- tempfile("maisi_ex_")
res <- ai_generate_maisi(out, dims = c(16L, 16L, 4L))
dim(res$mask)
#> [1] 16 16  4
unlink(out, recursive = TRUE)
```

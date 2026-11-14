# Extract IBSI-Standardized 3D Radiomics Features

Computes morphology, first-order intensity, 3D GLCM, 3D GLRLM, and 3D
GLSZM features compliant with the Image Biomarker Standardisation
Initiative (IBSI) Phase-1 specification.

## Usage

``` r
ai_extract_radiomics(
  volume,
  mask = NULL,
  discretization = c("none", "fbn", "fbw"),
  n_bins = 16L,
  bin_width = 25,
  backend = c("native", "pyradiomics")
)
```

## Arguments

- volume:

  A 3D numeric array or a `dicom_volume` / list with `$voxels` and
  `$spacing`.

- mask:

  Optional 3D binary/integer mask array (same dimensions as `volume`).
  If `NULL`, all non-NA voxels are included.

- discretization:

  Intensity discretization: `"none"` (for integer phantoms), `"fbn"`
  (fixed bin number), or `"fbw"` (fixed bin width).

- n_bins:

  Number of bins when `discretization = "fbn"` (default `16L`).

- bin_width:

  Bin width when `discretization = "fbw"` (default `25`).

- backend:

  Either `"native"` (pure R IBSI engine) or `"pyradiomics"`.

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `family`, `feature`, and `value`.

## Examples

``` r
ph <- ibsi_digital_phantom()
rad <- ai_extract_radiomics(ph$volume, ph$mask, discretization = "none")
head(rad)
#> # A tibble: 6 × 3
#>   family      feature                value
#>   <chr>       <chr>                  <dbl>
#> 1 morphology  morph_voxel_volume  592     
#> 2 morphology  morph_surface_area  496     
#> 3 morphology  morph_sphericity      0.687 
#> 4 morphology  morph_compactness_1   0.0302
#> 5 first_order stat_mean             2.15  
#> 6 first_order stat_var              3.05  
```

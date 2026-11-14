# Construct the Canonical IBSI Phase-1 Digital Phantom

Returns the 4 x 5 x 4 (74-voxel ROI, 2 x 2 x 2 mm voxel spacing) IBSI
Phase-1 digital phantom for standardized radiomics verification.

## Usage

``` r
ibsi_digital_phantom()
```

## Value

A list with `voxels` (4x5x4 array), `mask` (4x5x4 integer array),
`spacing` (`c(2, 2, 2)`), and `volume`
(`list(voxels = ..., spacing = ...)`).

## Examples

``` r
ph <- ibsi_digital_phantom()
sum(ph$mask)
#> [1] 74
```
